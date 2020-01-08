pragma solidity ^0.4.24;

import "./PathFinderInterface.sol";
import "./BancorNetworkInterface";

contract GetRatioForBancorAssets {
  BancorNetworkInterface public bancorNetwork;
  PathFinderInterface public pathFinder;

  constructor(address _bancorNetwork, _pathFinder) public{
    bancorNetwork = BancorNetworkInterface(_bancorNetwork);
    pathFinder = PathFinderInterface(_pathFinder);
  }

  // Get Ration between Bancor assets
  function getRatio(address _from, address _to, uint256 _amount) public view return(uint256 result){
    if(_amount > 0){
      // get Bancor path array
      address[] path = pathFinder.generatePath(_from, _to);
      // get Ratio
      result = bancorNetwork.getReturnByPath(path, _amount);
    }else{
      result = 0;
    }
  }
}
