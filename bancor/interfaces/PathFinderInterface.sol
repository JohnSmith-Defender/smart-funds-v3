pragma solidity ^0.4.24;

contract PathFinderInterface {
 function generatePath(address _sourceToken, address _targetToken) public view returns (address[] memory);
}
