// SPDX-License-Identifier: MIT

/**
 *
 *  @title: DataFeed
 *  @date: 17-June-2025
 *  @version: 1.0
 *  @author: IPMB Dev Team
 */

import "./Ownable.sol";
import "./Strings.sol";

pragma solidity ^0.8.19;

contract DataFeedContract is Ownable {

    // struct

    struct Data {
        int256 answer;
        uint256 startedAt;
        uint256 updatedAt;
        uint80 answeredInRound;
    }

    // mappings declaration

    mapping (address => bool) public admin;
    mapping (uint256 => Data) public DataFeed;

    // variables declaration

    using Strings for uint256;
    uint80 public nextEpoch;
    uint256 public latestTS;
    uint256 public epochInterval;
    uint8 public decimals;

    // modifiers
    
    modifier onlyAdmin() {
        require(admin[msg.sender] == true, "Not allowed");
        _;
    }
    // constructor

    constructor(int256 _answer, uint256 _updatedAt, uint256 _epochInterval, uint8 _decimals) {
        admin[msg.sender] = true;
        DataFeed[0].answer = _answer;
        DataFeed[0].startedAt  = block.timestamp;
        DataFeed[0].updatedAt  = _updatedAt;
        DataFeed[0].answeredInRound = 0;
        latestTS = block.timestamp;
        epochInterval = _epochInterval;
        nextEpoch = nextEpoch + 1;
        decimals = _decimals;
    }

    // set epoch data

    function setData(int256 _answer, uint256 _updatedAt) public onlyAdmin {
        require (block.timestamp >= latestTS + epochInterval, "1 epoch per interval");
        uint80 curEpoch = nextEpoch;
        DataFeed[curEpoch].answer = _answer;
        DataFeed[curEpoch].startedAt  = block.timestamp;
        DataFeed[curEpoch].updatedAt  = _updatedAt;
        DataFeed[curEpoch].answeredInRound = curEpoch;
        latestTS = block.timestamp;
        nextEpoch = nextEpoch + 1;
    }

    // retrieve data for latest epoch

    function latestRoundData() public view returns (uint80, int256, uint256, uint256, uint80) {
        uint80 latest = nextEpoch - 1;
        return (latest, DataFeed[latest].answer, DataFeed[latest].startedAt, DataFeed[latest].updatedAt, DataFeed[latest].answeredInRound);
    }

    // retrieve data for specific epoch

    function getRoundData(uint80 _roundId) public view returns (uint80, int256, uint256, uint256, uint80) {
        return (_roundId, DataFeed[_roundId].answer, DataFeed[_roundId].startedAt, DataFeed[_roundId].updatedAt, DataFeed[_roundId].answeredInRound);
    }

    // update admin status

    function updateAdminStatus(address _address, bool _st) public onlyOwner() {
        admin[_address] = _st;
    }

    // update epoch interval

    function updateEpochInterval(uint256 _epochInterval) public onlyOwner() {
        epochInterval = _epochInterval;
    }

}