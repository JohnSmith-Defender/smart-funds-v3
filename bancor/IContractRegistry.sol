contract IContractRegistry {
    function addressOf(bytes32 _contractName) public view returns (address);
    // deprecated, backward compatibility
    function getAddress(bytes32 _contractName) public view returns (address);
}
