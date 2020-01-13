// TODO write docs for methods
pragma solidity ^0.4.24;

import "./bancor/BancorConverterInterface.sol";
import "./bancor/IGetRatioForBancorAssets.sol";
import "./zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
import "./helpers/addressFromBytes32.sol";


contract PoolPortal {
  using SafeMath for uint256;
  using addressFromBytes32 for bytes32;
  IGetRatioForBancorAssets public bancorRatio;

  enum PortalType { Bancor }

  constructor(address _bancorRatio) public {
    bancorRatio = IGetRatioForBancorAssets(_bancorRatio);
  }

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

      // get connectors amount for buy relay by relay amount
      uint256 bancorAmount = getBancorConnectorsAmountByRelayAmount(_amount, _reserveTokens[0], converter, _poolToken);
      uint256 connectorAmount = getBancorConnectorsAmountByRelayAmount(_amount, _reserveTokens[1], converter, _poolToken);

      // approve bancor and coonector amount to converter
      _transferFromSenderAndApproveTo(_reserveTokens[0], bancorAmount, converter);
      _transferFromSenderAndApproveTo(_reserveTokens[1], connectorAmount, converter);

      // buy relay from converter
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
      uint256 bancorAmount = getBancorConnectorsAmountByRelayAmount(_amount, _reserveTokens[0], converter, _poolToken);
      uint256 connectorAmount = getBancorConnectorsAmountByRelayAmount(_amount, _reserveTokens[1], converter, _poolToken);

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


  function getRatio(address _from, address _to, uint256 _amount) public view returns(uint256 result){
    result = bancorRatio.getRatio(_from, _to, _amount);
    return result;
  }


  // Calculate value for assets array in ration of some one assets (like ETH or DAI)
  function getTotalValue(address[] _fromAddresses, uint256[] _amounts, address _to) public view returns (uint256) {
    uint256 sum = 0;

    for (uint256 i = 0; i < _fromAddresses.length; i++) {
      sum = sum.add(getRatio(_fromAddresses[i], _to, _amounts[i]));
    }

    return sum;
  }


  // This function calculate amount of both reserve for buy and sell by pool amount
  function getBancorConnectorsAmountByRelayAmount
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
    require(_source.transferFrom(msg.sender, address(this), _sourceAmount));

    _source.approve(_to, _sourceAmount);
  }

  // fallback payable function to receive ether from other contract addresses
  function() public payable {}
}
