pragma solidity ^0.4.24;

import "./zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract ExchangePortalInterface {

  event Trade(address src, uint256 srcAmount, address dest, uint256 destReceived);

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
    returns (uint256);

  function getValue(address _from, address _to, uint256 _amount) public view returns (uint256);
  function getTotalValue(address[] _fromAddresses, uint256[] _amounts, address _to) public view returns (uint256);
}
