pragma solidity ^0.4.24;

contract PermittedPoolsInterface {
  mapping (address => bool) public permittedAddresses;
}
