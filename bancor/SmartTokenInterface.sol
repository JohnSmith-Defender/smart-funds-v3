pragma solidity ^0.4.24;

import "../zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract SmartTokenInterface is ERC20 {
  function disableTransfers(bool _disable) public;
  function issue(address _to, uint256 _amount) public;
  function destroy(address _from, uint256 _amount) public;
  function owner() public view returns (address);
}
