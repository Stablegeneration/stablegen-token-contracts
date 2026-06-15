// SPDX-License-Identifier: MIT

// Chainlink Proof-Of-Reserves Aggregator contract for simulation purposes only

pragma solidity >=0.8.30;

contract reservesAggregator {

  uint80 roundId;
  int256 answer;
  uint256 startedAt;
  uint256 updatedAt;
  uint80 answeredInRound;
  address owner;

  modifier onlyAdmin() {
    require(msg.sender == owner);
    _;
  }

  constructor() {
    owner = msg.sender;
  }

  // getRoundData and latestRoundData should both raise "No data present"
  // if they do not have data to report, instead of returning unset values
  // which could be misinterpreted as actual reported values.
  function getRoundData()
    public
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    ) {
      return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }
    
  function latestRoundData()
    public
    view
    returns (
      uint80,
      int256,
      uint256,
      uint256,
      uint80
    ) {
      return (roundId, answer, startedAt, updatedAt, answeredInRound);
    }

    function setData(uint80 _roundId, int256 _answer, uint256 _startedAt, uint256 _updatedAt, uint80 _answeredInRound) public onlyAdmin {
      roundId = _roundId;
      answer = _answer;
      startedAt = _startedAt;
      updatedAt = _updatedAt;
      answeredInRound = _answeredInRound;
    }

}