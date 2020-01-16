// TODO write docs for methods
pragma solidity ^0.4.24;

import "./zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";

import "./bancor/interfaces/BancorConverterInterface.sol";
import "./bancor/interfaces/IGetRatioForBancorAssets.sol";
import "./bancor/interfaces/SmartTokenInterface.sol";
import "./bancor/interfaces/IGetBancorAddressFromRegistry.sol";
import "./bancor/interfaces/IBancorFormula.sol";


contract PoolPortal {
  using SafeMath for uint256;

  IGetRatioForBancorAssets public bancorRatio;
  IGetBancorAddressFromRegistry public bancorRegistry;
  address public BancorEtherToken;

  enum PortalType { Bancor }

  constructor(address _bancorRegistry, address _bancorRatio, address _BancorEtherToken) public {
    bancorRatio = IGetRatioForBancorAssets(_bancorRatio);
    bancorRegistry = IGetBancorAddressFromRegistrybancorRegistry.(_bancorRegistry);
    BancorEtherToken = _BancorEtherToken;
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
      address converterAddress = getBacorConverterAddressByRelay(address(_poolToken));

      // calculate connectors amount for buy certain pool amount
      (uint256 bancorAmount,
       uint256 connectorAmount) = getBancorConnectorsAmountByRelayAmount(_amount, _poolToken);

      // get converter as contract
      BancorConverterInterface converter = BancorConverterInterface(converterAddress);

      // approve bancor and coonector amount to converter

      // get connectors
      (ERC20 bancorConnector,
      ERC20 ercConnector) = getBancorConnectorsByRelay(address(_poolToken));

      // reset approve (some ERC20 not allow do new approve if already approved)
      bancorConnector.approve(converterAddress, 0);
      ercConnector.approve(converterAddress, 0);

      // transfer from fund and approve to converter
      _transferFromSenderAndApproveTo(bancorConnector, bancorAmount, converterAddress);
      _transferFromSenderAndApproveTo(ercConnector, connectorAmount, converterAddress);

      // buy relay from converter
      converter.fund(_amount);

      // transfer relay back to smart fund
      _poolToken.transfer(msg.sender, _amount);

      // transfer connectors back if a small amount remains
      uint256 bancorRemains = bancorConnector.balanceOf(address(this));
      if(bancorRemains > 0)
         bancorConnector.transfer(msg.sender, bancorRemains);

      uint256 ercRemains = ercConnector.balanceOf(address(this));
      if(ercRemains > 0)
          ercConnector.transfer(msg.sender, ercRemains);

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
      // transfer pool from fund
      _poolToken.transferFrom(msg.sender, address(this), _amount);

      // get Bancor Converter address
      address converterAddress = getBacorConverterAddressByRelay(address(_poolToken));

      // liquidate relay
      BancorConverterInterface(converterAddress).liquidate(_amount);

      // get connectors
      (ERC20 bancorConnector,
      ERC20 ercConnector) = getBancorConnectorsByRelay(address(_poolToken));

      // transfer connectors back to fund
      bancorConnector.transfer(msg.sender, bancorConnector.balanceOf(this));
      ercConnector.transfer(msg.sender, ercConnector.balanceOf(this));
    }else{
      // unknown portal type
      revert();
    }
  }

  function getBacorConverterAddressByRelay(address relay) public view returns(address converter){
    converter = SmartTokenInterface(relay).owner();
  }

  function getBancorConnectorsByRelay(address relay)
  public
  view
  returns(
    ERC20 BNTConnector,
    ERC20 ERCConnector
  )
  {
    address converterAddress = getBacorConverterAddressByRelay(relay);
    BancorConverterInterface converter = BancorConverterInterface(converterAddress);
    BNTConnector = converter.connectorTokens(0);
    ERCConnector = converter.connectorTokens(1);
  }


  function getRatio(address _from, address _to, uint256 _amount) public view returns(uint256 result){
    result = bancorRatio.getRatio(_from, _to, _amount);
    return result;
  }


  // Calculate value for assets array in ration of some one assets (like ETH or DAI)
  function getTotalValue(address[] _fromAddresses, uint256[] _amounts, address _to) public view returns (uint256) {
    // replace ETH with Bancor ETH wrapper
    if(_to == address(0x00eeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeeee))
      _to == BancorEtherToken;

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
    // get converter contract
    BancorConverterInterface converter = BancorConverterInterface(SmartTokenInterface(_relay).owner());

    // calculate BNT and second connector amount

    // get connectors
    ERC20 bancorConnector = converter.connectorTokens(0);
    ERC20 ercConnector = converter.connectorTokens(1);

    // get connectors balance
    uint256 bntBalance = converter.getConnectorBalance(bancorConnector);
    uint256 ercBalance = converter.getConnectorBalance(ercConnector);

    // get bancor formula contract
    IBancorFormula bancorFormula = IBancorFormula(bancorRegistry.getBancorContractAddresByName("BancorFormula"));

    // calculate input
    bancorAmount = bancorFormula.calculateFundCost(_relay.totalSupply(), bntBalance, 100, _amount);
    connectorAmount = bancorFormula.calculateFundCost(_relay.totalSupply(), ercBalance, 100, _amount);
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
