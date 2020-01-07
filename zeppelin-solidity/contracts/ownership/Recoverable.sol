pragma solidity ^0.4.24;

import "./Ownable.sol";

/**
* @title Recoverable
* @dev This contract is an extension of Ownable, with additional security features that allow
* predetermined recovery addresses to transfer ownership in case of a compromised private key.
* Two out of five recovery addresses are required in order to transfer ownership, and as an extra
* layer of security, three out of five recovery addresses are required in order to replace a
* recovery address
*/
contract Recoverable is Ownable {

  // Array of 5 recovery addresses, used in case of emergency to transfer contract ownership
  address[5] recoveryAddresses;

  // Maps recovery address to address that they permit to take contract ownership
  mapping (address => address) approvedNewOwner;

  // Maps recovery address to new address that they permit to replace any existing recovery address.
  // This is a second layer of security in case two of the recovery addresses are compromised
  mapping (address => address) approvedNewRecoveryAddress;

  bool private notCalled = true;

  // modifier that allows a function to be called only once
  modifier onlyOnce() {
    require(notCalled);
    notCalled = false;
    _;
  }

  function getRecoveryAddresses() external view returns(address[5]) {
    return recoveryAddresses;
  }

  /**
  * @dev Initializes the 5 recovery addresses, may only be called once
  *
  * @param _recoveryAddresses    The initial 5 recovery addresses
  */
  function initializeRecoveryAddresses(address[5] _recoveryAddresses) external onlyOwner onlyOnce {
    recoveryAddresses = _recoveryAddresses;    
  }

  /**
  * @dev allows any address to set their approval for a new owner
  *
  * @param _newOwner    The address of the new owner msg.sender is permitting
  * @notice Although anyone can call this function, it is only relevant if an address from
  * recoveryAddresses calls it 
  */
  function approveNewOwner(address _newOwner) external {
    approvedNewOwner[msg.sender] = _newOwner;
  }

  /**
  * @dev Allows any address to set their approval for a new recovery address
  *
  * @param _newRecoveryAddress    The address of the new recoverer msg.sender is permitting
  * @notice Although anyone can call this function, it is only relevant if an address from
  * recoveryAddresses calls it 
  */
  function approveNewRecoveryAddress(address _newRecoveryAddress) external {
    approvedNewRecoveryAddress[msg.sender] = _newRecoveryAddress;
  }

  /**
  * @dev Allows the caller to claim ownership of the contract if they are approved by two recovery addresses
  *
  * @param indexOne    Index of the first recovery address that permits this new owner
  * @param indexTwo    Index of the second recovery address that permits this new owner
  */
  function claimOwnership(uint8 indexOne, uint8 indexTwo) external {
    address recoveryAddressOne = recoveryAddresses[indexOne];
    address recoveryAddressTwo = recoveryAddresses[indexTwo];    
    require(approvedNewOwner[recoveryAddressOne] == msg.sender);
    require(approvedNewOwner[recoveryAddressTwo] == msg.sender);
    _transferOwnership(msg.sender);    
  }

  /**
  * @dev Allows the caller to claim a position as a recovery address of the contract if they are
  * approved by three recovery addresses
  *
  * @param indexOne        Index of the first recovery address that permits msg.sender
  * @param indexTwo        Index of the second recovery address that permits msg.sender
  * @param indexThree      Index of the third recovery address that permits msg.sender 
  * @param indexClaimed    Index of the recovery address to be replaced by msg.sender 
  */
  function claimRecoveryAddress(
    uint8 indexOne,
    uint8 indexTwo,
    uint8 indexThree,
    uint8 indexClaimed
    ) external {

    address recoveryAddressOne = recoveryAddresses[indexOne];
    address recoveryAddressTwo = recoveryAddresses[indexTwo];
    address recoveryAddressThree = recoveryAddresses[indexThree];
    require(approvedNewRecoveryAddress[recoveryAddressOne] == msg.sender);
    require(approvedNewRecoveryAddress[recoveryAddressTwo] == msg.sender);
    require(approvedNewRecoveryAddress[recoveryAddressThree] == msg.sender);
    recoveryAddresses[indexClaimed] = msg.sender;

    // The approvedNewRecoveryAddress is reset to 0 in order to prevent the new recovery
    // address from claiming all 5 recovery address places
    approvedNewRecoveryAddress[recoveryAddressOne] = address(0);
    approvedNewRecoveryAddress[recoveryAddressTwo] = address(0);
    approvedNewRecoveryAddress[recoveryAddressThree] = address(0);
    
  }

}