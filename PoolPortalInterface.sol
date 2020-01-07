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
}
