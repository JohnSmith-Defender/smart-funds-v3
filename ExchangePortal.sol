pragma solidity ^0.4.24;

import "./ExchangePortalInterface.sol";
import "./zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
import "./zeppelin-solidity/contracts/token/ERC20/DetailedERC20.sol";
import "./paraswap/ParaswapInterface.sol";
import "./paraswap/IPriceFeed.sol";
import "./paraswap/IParaswapParams.sol";
import "./bancor/interfaces/IGetBancorAddressFromRegistry.sol";
import "./bancor/interfaces/BancorNetworkInterface.sol";
import "./bancor/interfaces/PathFinderInterface.sol";

/*
* The ExchangePortal contract is an implementation of ExchangePortalInterface that allows
* SmartFunds to exchange and calculate their value via Paraswap
*/
contract ExchangePortal is ExchangePortalInterface, Ownable {
  using SafeMath for uint256;

  address public paraswap;
  ParaswapInterface public paraswapInterface;
  IPriceFeed public priceFeedInterface;
  IParaswapParams public paraswapParams;
  address public paraswapSpender;

  IGetBancorAddressFromRegistry public bancorRegistry;

  enum ExchangeType { Paraswap, Bancor }

  // Paraswap recognizes ETH by this address
  ERC20 constant private ETH_TOKEN_ADDRESS = ERC20(0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE);

  mapping (address => bool) disabledTokens;

  event Trade(address trader, address src, uint256 srcAmount, address dest, uint256 destReceived, uint8 exchangeType);

  // Modifier to check that trading this token is not disabled
  modifier tokenEnabled(ERC20 _token) {
    require(!disabledTokens[address(_token)]);
    _;
  }

  /**
  * @dev contructor
  *
  * @param _paraswap        paraswap main address
  * @param _paraswapPrice   paraswap price feed address
  * @param _paraswapParams  helper contract for convert params from bytes32
  */
  constructor(
    address _paraswap,
    address _paraswapPrice,
    address _paraswapParams,
    address _bancorRegistry
    )
    public
    {
    paraswap = _paraswap;
    paraswapInterface = ParaswapInterface(_paraswap);
    priceFeedInterface = IPriceFeed(_paraswapPrice);
    paraswapParams = IParaswapParams(_paraswapParams);
    paraswapSpender = paraswapInterface.getTokenTransferProxy();
    bancorRegistry = IGetBancorAddressFromRegistry(_bancorRegistry);
  }


  /**
  * @dev Facilitates a trade for a SmartFund
  *
  * @param _source            ERC20 token to convert from
  * @param _sourceAmount      Amount to convert from (in _source token)
  * @param _destination       ERC20 token to convert to
  * @param _type              The type of exchange to trade with (For now 0 - because only paraswap)
  * @param _additionalArgs    Array of bytes32 additional arguments (For fixed size items and for different types items in array )
  * @param _additionalData    For any size data (if not used set just 0x0)
  *
  * @return The amount of _destination received from the trade
  */
  function trade(
    ERC20 _source,
    uint256 _sourceAmount,
    ERC20 _destination,
    uint256 _type,
    bytes32[] _additionalArgs,
    bytes _additionalData
  )
    external
    payable
    tokenEnabled(_destination)
    returns (uint256)
  {

    require(_source != _destination);

    uint256 receivedAmount;

    if (_source == ETH_TOKEN_ADDRESS) {
      require(msg.value == _sourceAmount);
    } else {
      require(msg.value == 0);
    }

    // SHOULD TRADE PARASWAP HERE
    if (_type == uint(ExchangeType.Paraswap)) {
      // call paraswap
      receivedAmount = _tradeViaParaswap(
          _source,
          _destination,
          _sourceAmount,
          _additionalData,
          _additionalArgs
      );
    }
    // SHOULD TRADE BANCOR HERE
    else if (_type == uint(ExchangeType.Bancor)){
      receivedAmount = _tradeViaBancorNewtork(
          _source,
          _destination,
          _sourceAmount
      );
    }

    else {
      // unknown exchange type
      revert();
    }

    // Check if Ether was received
    if (_destination == ETH_TOKEN_ADDRESS) {
      (msg.sender).transfer(receivedAmount);
    } else {
      // transfer tokens received to sender
      _destination.transfer(msg.sender, receivedAmount);
    }

    // After the trade, any _source that exchangePortal holds will be sent back to msg.sender
    uint256 endAmount = (_source == ETH_TOKEN_ADDRESS) ? address(this).balance : _source.balanceOf(address(this));

    // Check if we hold a positive amount of _source
    if (endAmount > 0) {
      if (_source == ETH_TOKEN_ADDRESS) {
        (msg.sender).transfer(endAmount);
      } else {
        _source.transfer(msg.sender, endAmount);
      }
    }

    emit Trade(msg.sender, _source, _sourceAmount, _destination, receivedAmount, uint8(_type));

    return receivedAmount;
  }


  // Facilitates trade with Paraswap
  function _tradeViaParaswap(
    address sourceToken,
    address destinationToken,
    uint256 sourceAmount,
    bytes   exchangeData,
    bytes32[] _additionalArgs
 )
   private
   returns (uint256 destinationReceived)
 {
   (uint256 minDestinationAmount,
    address[] memory callees,
    uint256[] memory startIndexes,
    uint256[] memory values,
    uint256 mintPrice) = paraswapParams.getParaswapParamsFromBytes32Array(_additionalArgs);

   if (ERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
     paraswapInterface.swap.value(sourceAmount)(
       sourceToken,
       destinationToken,
       sourceAmount,
       minDestinationAmount,
       callees,
       exchangeData,
       startIndexes,
       values,
       "CoTrader", // referrer
       mintPrice
     );
   } else {
     _transferFromSenderAndApproveTo(ERC20(sourceToken), sourceAmount, paraswapSpender);
     paraswapInterface.swap(
       sourceToken,
       destinationToken,
       sourceAmount,
       minDestinationAmount,
       callees,
       exchangeData,
       startIndexes,
       values,
       "CoTrader", // referrer
       mintPrice
     );
   }

   destinationReceived = tokenBalance(ERC20(destinationToken));
 }


 // Facilitates trade with Bancor
 function _tradeViaBancorNewtork(
   address sourceToken,
   address destinationToken,
   uint256 sourceAmount
   )
   private
   returns(uint256 returnAmount)
 {
    BancorNetworkInterface bancorNetwork = BancorNetworkInterface(
      bancorRegistry.getBancorContractAddresByName("BancorNetwork")
    );

    PathFinderInterface pathFinder = PathFinderInterface(
      bancorRegistry.getBancorContractAddresByName("BancorNetworkPathFinder")
    );

    address[] memory path = pathFinder.generatePath(_from, _to);

    if (ERC20(sourceToken) == ETH_TOKEN_ADDRESS) {
      returnAmount = bancorNetwork.convert(path, sourceAmount, 1).value(sourceAmount);
    }
    else {
      _transferFromSenderAndApproveTo(ERC20(sourceToken), sourceAmount, paraswapSpender);
      returnAmount = bancorNetwork.claimAndConvert(path, sourceAmount, 1);
    }
 }
 

 function tokenBalance(ERC20 _token) private view returns (uint256) {
   if (_token == ETH_TOKEN_ADDRESS)
     return address(this).balance;
   return _token.balanceOf(address(this));
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


  /**
  * @dev Gets the value of a given amount of some token
  *
  * @param _from      Address of token we're converting from
  * @param _to        Address of token we're getting the value in
  * @param _amount    The amount of _from
  *
  * @return best price from paraswap
  */
  function getValue(address _from, address _to, uint256 _amount) public view returns (uint256 value) {
     if(_amount > 0){
       value = priceFeedInterface.getBestPriceSimple(_from, _to, _amount);
     }else{
       value = 0;
     }
     return value;
  }

  /**
  * @dev Gets the total value of array of tokens and amounts
  *
  * @param _fromAddresses    Addresses of all the tokens we're converting from
  * @param _amounts          The amounts of all the tokens
  * @param _to               The token who's value we're converting to
  *
  * @return The total value of _fromAddresses and _amounts in terms of _to
  */
  function getTotalValue(address[] _fromAddresses, uint256[] _amounts, address _to) public view returns (uint256) {
    uint256 sum = 0;

    for (uint256 i = 0; i < _fromAddresses.length; i++) {
      sum = sum.add(getValue(_fromAddresses[i], _to, _amounts[i]));
    }

    return sum;
  }

  /**
  * @dev Allows the owner to disable/enable the buying of a token
  *
  * @param _token      Token address whos trading permission is to be set
  * @param _enabled    New token permission
  */
  function setToken(address _token, bool _enabled) external onlyOwner {
    disabledTokens[_token] = _enabled;
  }

  // owner can change IFeed
  function setNewIFeed(address _paraswapPrice) external onlyOwner {
    priceFeedInterface = IPriceFeed(_paraswapPrice);
  }

  // owner can change paraswap spender address
  function setNewParaswapSpender(address _paraswapSpender) external onlyOwner {
    paraswapSpender = _paraswapSpender;
  }

  // owner can change paraswap Augustus
  function setNewParaswapMain(address _paraswap) external onlyOwner {
    paraswapInterface = ParaswapInterface(_paraswap);
  }

  // fallback payable function to receive ether from other contract addresses
  function() public payable {}

}
