pragma solidity ^0.4.24;

import "./zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract PoolPortalInterface {
  function buyPool
  (
    uint256 _amount,
    uint _type,
    ERC20 _poolToken,
    ERC20[] _reserveTokens,
    bytes32[] _additionalArgs
  )
  external
  payable;

  function sellPool
  (
    uint256 _amount,
    uint _type,
    ERC20 _poolToken,
    ERC20[] _reserveTokens,
    bytes32[] _additionalArgs
  )
  external
  payable;

  function getRatio(address _from, address _to, uint256 _amount) public view returns(uint256);
  function getTotalValue(address[] _fromAddresses, uint256[] _amounts, address _to) public view returns (uint256);
}
