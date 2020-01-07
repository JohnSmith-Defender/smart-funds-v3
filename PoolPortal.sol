// TODO docs for methods
pragma solidity ^0.4.24;

import "./bancor/BancorConverterInterface.sol";
import "./zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
import "./helpers/addressFromBytes32.sol";

contract PoolPortal {
  using SafeMath for uint256;
  using addressFromBytes32 for bytes32;

  enum PortalType { Bancor }

  function buyPool
  (
    uint256 _amount,
    uint _type,
    ERC20 _poolToken,
    ERC20[] _reserveTokens,
    bytes32[] _additionalArgs
  )
  external
  payable
  {
    if(_type == uint(PortalType.Bancor)){
      // get Bancor converter
      address converter = addressFromBytes32.bytesToAddress(_additionalArgs[0]);

      // get connectors amount
      uint256 bancorAmount = uint256(_additionalArgs[1]);
      uint256 connectorAmount = uint256(_additionalArgs[2]);

      // make sure Bancor connector not approved before
      // because Bancor token throw new approve if alredy approved
      uint256 approvedBancor = _reserveTokens[0].allowance(converter, msg.sender);

      // reset approve
      if(approvedBancor > 0)
          _transferFromSenderAndApproveTo(_reserveTokens[0], 0, address(this));

      // approve bancor and coonector
      _transferFromSenderAndApproveTo(_reserveTokens[0], bancorAmount, address(this));
      _transferFromSenderAndApproveTo(_reserveTokens[1], connectorAmount, address(this));

      // buy relay
      BancorConverterInterface converterContract = BancorConverterInterface(converter);
      converterContract.fund(_amount);

      // transfer relay back to smart fund
      _poolToken.transfer(msg.sender, _amount);
    }else{
      // unknown portal type
      revert();
    }
  }

  function sellPool
  (
    uint256 _amount,
    uint _type,
    ERC20 _poolToken,
    ERC20[] _reserveTokens,
    bytes32[] _additionalArgs
  )
  external
  payable
  {
    if(_type == uint(PortalType.Bancor)){
      // get Bancor Converter address
      address converter = addressFromBytes32.bytesToAddress(_additionalArgs[0]);
      // calculate returns for fund
      uint256 bancorAmount = GetBancorConnectorsAmountByRelayAmount(_amount, _reserveTokens[0], converter, _poolToken);
      uint256 connectorAmount = GetBancorConnectorsAmountByRelayAmount(_amount, _reserveTokens[1], converter, _poolToken);

      // liquidate relay
      BancorConverterInterface converterContract = BancorConverterInterface(converter);
      converterContract.liquidate(_amount);

      // transfer assets back to smart fund
      _reserveTokens[0].transfer(msg.sender, bancorAmount);
      _reserveTokens[1].transfer(msg.sender, connectorAmount);

    }else{
      // unknown portal type
      revert();
    }
  }

  function GetBancorConnectorsAmountByRelayAmount
  (
    uint256 _amount,
    ERC20 _token,
    address _converter,
    ERC20 _relay
  )
  public view returns(uint256) {
    uint256 supply = _relay.totalSupply();
    uint256 reserveBalance = _token.balanceOf(_converter);
    return _amount.mul(reserveBalance).div(supply);
  }


  /**
  * @dev Transfers tokens to this contract and approves them to another address
  *
  * @param _source          Token to transfer and approve
  * @param _sourceAmount    The amount to transfer and approve (in _source token)
  * @param _to              Address to approve to
  */
  function _transferFromSenderAndApproveTo(ERC20 _source, uint256 _sourceAmount, address _to) private {
    require(_source.transferFrom(msg.sender, this, _sourceAmount));

    _source.approve(_to, _sourceAmount);
  }

  // fallback payable function to receive ether from other contract addresses
  function() public payable {}
}
