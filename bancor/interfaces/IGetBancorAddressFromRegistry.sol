pragma solidity ^0.4.24;

contract IGetBancorAddressFromRegistry{
  function getBancorContractAddresByName(string _name) public view returns (address result);
}
