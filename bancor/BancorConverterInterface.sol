pragma solidity ^0.4.24;

contract BancorConverterInterface {
  function fund(uint256 _amount) public;
  function liquidate(uint256 _amount) public;
}
