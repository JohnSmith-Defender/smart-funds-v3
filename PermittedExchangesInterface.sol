pragma solidity ^0.4.23;

contract PermittedExchangesInterface {
  mapping (address => bool) public permittedAddresses;
}
