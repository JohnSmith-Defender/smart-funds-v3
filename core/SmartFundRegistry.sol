pragma solidity ^0.4.24;

import "./SmartFund.sol";
import "../interfaces/PermittedExchangesInterface.sol";
import "../interfaces/PermittedPoolsInterface.sol";
import "../zeppelin-solidity/contracts/ownership/Ownable.sol";

/*
* The SmartFundRegistry is used to manage the creation and permissions of SmartFund contracts
*/
contract SmartFundRegistry is Ownable {
  SmartFund[] public smartFunds;

  // The Smart Contract which stores the addresses of all the authorized Exchange Portals
  PermittedExchangesInterface public permittedExchanges;
  // The Smart Contract which stores the addresses of all the authorized Pool Portals
  PermittedPoolsInterface public permittedPools;

  // Addresses of portals
  address public poolPortalAddress;
  address public exchangePortalAddress;

  // platForm fee is out of 10,000, e.g 2500 is 25%
  uint256 public platformFee;

  // Default maximum success fee is 3000/30%
  uint256 public maximumSuccessFee = 3000;

  event SmartFundAdded(address indexed smartFundAddress, address indexed owner);

  /**
  * @dev contructor
  *
  * @param _platformFee                  Initial platform fee
  * @param _exchangePortalAddress        Address of the initial ExchangePortal contract
  * @param _permittedExchangesAddress    Address of the permittedExchanges contract
  * @param _permittedPoolAddress         Address of the permittedPool contract
  * @param _poolPortalAddress            Address of the initial PoolPortal contract
  */
  constructor(
    uint256 _platformFee,
    address _exchangePortalAddress,
    address _permittedExchangesAddress,
    address _permittedPoolAddress,
    address _poolPortalAddress
  ) public {
    platformFee = _platformFee;
    exchangePortalAddress = _exchangePortalAddress;
    permittedExchanges = PermittedExchangesInterface(_permittedExchangesAddress);
    permittedPools = PermittedPoolsInterface(_permittedPoolAddress);
    poolPortalAddress = _poolPortalAddress;
  }

  /**
  * @dev Creates a new SmartFund
  *
  * @param _name          The name of the new fund
  * @param _successFee    The fund managers success fee
  */
  function createSmartFund(string _name, uint256 _successFee) public {

    // Require that the funds success fee be less than the maximum allowed amount
    require(_successFee <= maximumSuccessFee);

    address owner = msg.sender;

    SmartFund smartFund = new SmartFund(
      owner,
      _name,
      _successFee,
      platformFee,
      this,
      exchangePortalAddress,
      address(permittedExchanges),
      address(permittedPools),
      poolPortalAddress
    );

    smartFunds.push(smartFund);

    emit SmartFundAdded(address(smartFund), owner);
  }

  function totalSmartFunds() public view returns (uint256) {
    return smartFunds.length;
  }

  function getAllSmartFundAddresses() public view returns(address[]) {
    address[] memory addresses = new address[](smartFunds.length);

    for (uint i; i < smartFunds.length; i++) {
      addresses[i] = address(smartFunds[i]);
    }

    return addresses;
  }

  /**
  * @dev Sets a new default ExchangePortal address
  *
  * @param _newExchangePortalAddress    Address of the new exchange portal to be set
  */
  function setExchangePortalAddress(address _newExchangePortalAddress) public onlyOwner {
    // Require that the new exchange portal is permitted by permittedExchanges
    require(permittedExchanges.permittedAddresses(_newExchangePortalAddress));
    exchangePortalAddress = _newExchangePortalAddress;
  }

  /**
  * @dev Sets a new default Portal Portal address
  *
  * @param _poolPortalAddress    Address of the new pool portal to be set
  */
  function setPoolPortalAddress (address _poolPortalAddress) external onlyOwner {
    // Require that the new pool portal is permitted by permittedPools
    require(permittedPools.permittedAddresses(_poolPortalAddress));

    poolPortalAddress = _poolPortalAddress;
  }

  /**
  * @dev Sets maximum success fee for all newly created SmartFunds
  *
  * @param _maximumSuccessFee    New maximum success fee
  */
  function setMaximumSuccessFee(uint256 _maximumSuccessFee) external onlyOwner {
    maximumSuccessFee = _maximumSuccessFee;
  }

  /**
  * @dev Sets platform fee for all newly created SmartFunds
  *
  * @param _platformFee    New platform fee
  */
  function setPlatformFee(uint256 _platformFee) external onlyOwner {
    platformFee = _platformFee;
  }

  /**
  * @dev Allows platform to withdraw tokens received as part of the platform fee
  *
  * @param _tokenAddress    Address of the token to be withdrawn
  */
  function withdrawTokens(address _tokenAddress) external onlyOwner {
    ERC20 token = ERC20(_tokenAddress);

    token.transfer(owner, token.balanceOf(this));
  }

  /**
  * @dev Allows platform to withdraw ether received as part of the platform fee
  */
  function withdrawEther() external onlyOwner {
    owner.transfer(address(this).balance);
  }

  // Fallback payable function in order to receive ether when fund manager withdraws their cut
  function() public payable {}

}
