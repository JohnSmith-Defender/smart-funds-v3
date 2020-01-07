contract IPriceFeed{
  function getBestPriceSimple(address _from, address _to, uint256 _amount) public view returns (uint256 result);
}
