// TODO write docs for methods
pragma solidity ^0.4.24;

import "./bancor/BancorConverterInterface.sol";
import "./bancor/IGetRatioForBancorAssets.sol";
import "./bancor/SmartTokenInterface.sol";
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
    bytes32[] _additionalArgs // Some addition data for another pools like Uniswap
  )
  external
  payable
  {
    if(_type == uint(PortalType.Bancor)){
      // get Bancor converter
      address converterAddress = SmartTokenInterface(_poolToken).owner();

      // calculate connectors amount for fet after liquidate
      (uint256 bancorAmount,
       uint256 connectorAmount) = getBancorConnectorsAmountByRelayAmount(_amount, _poolToken);

      // get converter as contract
      BancorConverterInterface converter = BancorConverterInterface(converterAddress);

      // approve bancor and coonector amount to converter
      ERC20 bancorConnector = converter.connectorTokens(0);
      ERC20 ercConnector = converter.connectorTokens(1);

      _transferFromSenderAndApproveTo(bancorConnector, bancorAmount, converter);
      _transferFromSenderAndApproveTo(ercConnector, connectorAmount, converter);

      // buy relay from converter
      converter.fund(_amount);

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
    bytes32[] _additionalArgs // Some addition data for another pools like Uniswap
  )
  external
  payable
  {
    if(_type == uint(PortalType.Bancor)){
      // get Bancor Converter address
      address converterAddress = SmartTokenInterface(_poolToken).owner();

      // calculate connectors amount for fet after liquidate
      (uint256 bancorAmount,
       uint256 connectorAmount) = getBancorConnectorsAmountByRelayAmount(_amount, _poolToken);

      // get converter as contract
      BancorConverterInterface converter = BancorConverterInterface(converterAddress);

      // liquidate relay
      converter.liquidate(_amount);

      // transfer assets back to smart fund
      ERC20 bancorConnector = converter.connectorTokens(0);
      ERC20 ercConnector = converter.connectorTokens(1);

      bancorConnector.transfer(msg.sender, bancorAmount);
      ercConnector.transfer(msg.sender, connectorAmount);
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
    ERC20 _relay
  )
  public view returns(uint256 bancorAmount, uint256 connectorAmount) {
    // get converter
    address converterAddress = SmartTokenInterface(_relay).owner();
    // get relay supply
    uint256 supply = _relay.totalSupply();
    // get converter as contract
    BancorConverterInterface converter = BancorConverterInterface(converterAddress);
    // calculate BNT and second connector amount

    // get connectors
    ERC20 bancorConnector = converter.connectorTokens(0);
    ERC20 ercConnector = converter.connectorTokens(1);

    // get connectors balance
    uint256 bntBalance = converter.getConnectorBalance(bancorConnector);
    uint256 ercBalance = converter.getConnectorBalance(ercConnector);

    // calculate according this formula input * connector balance / smart token supply
    bancorAmount = _amount.mul(bntBalance).div(supply);
    connectorAmount = _amount.mul(ercBalance).div(supply);
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
