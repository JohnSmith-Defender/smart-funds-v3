pragma solidity ^0.4.24;

import "../zeppelin-solidity/contracts/token/ERC20/ERC20.sol";
/*
    Bancor Network interface
*/
contract BancorNetworkInterface {
   function getReturnByPath(ERC20[] _path, uint256 _amount) public view returns (uint256, uint256);

    function convert(
        ERC20[] _path,
        uint256 _amount,
        uint256 _minReturn
    ) public payable returns (uint256);

    function claimAndConvert(
        ERC20[] _path,
        uint256 _amount,
        uint256 _minReturn
    ) public returns (uint256);

    function convertFor(
        ERC20[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) public payable returns (uint256);

    function claimAndConvertFor(
        ERC20[] _path,
        uint256 _amount,
        uint256 _minReturn,
        address _for
    ) public returns (uint256);

}
