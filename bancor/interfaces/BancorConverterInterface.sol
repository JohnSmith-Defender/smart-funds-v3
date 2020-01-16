pragma solidity ^0.4.24;
import "../zeppelin-solidity/contracts/token/ERC20/ERC20.sol";

contract BancorConverterInterface {
  ERC20[] public connectorTokens;
  function fund(uint256 _amount) public;
  function liquidate(uint256 _amount) public;
  function getConnectorBalance(ERC20 _connectorToken) public view returns (uint256);
}
