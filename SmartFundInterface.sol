pragma solidity ^0.4.24;

import "./ExchangePortalInterface.sol";
import "./PoolPortalInterface.sol";
import "./PermittedExchangesInterface.sol";
import "./zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
import "./zeppelin-solidity/contracts/ownership/Ownable.sol";
import "./zeppelin-solidity/contracts/math/SafeMath.sol";
import "./zeppelin-solidity/contracts/token/ERC20/SafeERC20.sol";

contract SmartFundInterface {
  // the total number of shares in the fund
  uint256 totalShares;

  // how many shares belong to each address
  mapping (address => uint256) public addressToShares;

  // deposit `amount` of tokens.
  // returns number of shares the user receives
  function deposit() external payable returns (uint256);

  // sends percentage of fund tokens to the user
  // function withdraw() external;
  function withdraw(uint256 _percentageWithdraw) external;

  // for smart fund owner to trade tokens
  function trade(
    ERC20 _source,
    uint256 _sourceAmount,
    ERC20 _destination,
    uint256 _type,
    bytes32[] additionalArgs,
    bytes _additionalData
  )
    external;

  function buyPool(
    uint256 _amount,
    uint _type,
    ERC20 _poolToken,
    bytes32[] _additionalArgs
  )
    external;

  function sellPool(
    uint256 _amount,
    uint _type,
    ERC20 _poolToken,
    bytes32[] _additionalArgs
  )
    external;

  // calculates the number of shares a buyer will receive for depositing `amount` of ether
  function calculateDepositToShares(uint256 _amount) public view returns (uint256);
}
