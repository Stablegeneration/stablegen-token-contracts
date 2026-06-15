// SPDX-License-Identifier: MIT

/**
 *
 * @title Data Feed Interface
 */

pragma solidity ^0.8.5;

interface IDataFeed {

    function latestRoundData() external view returns (uint80, int256, uint256, uint256, uint80);

    function getRoundData(uint80 _roundId) external view returns (uint80, int256, uint256, uint256, uint80);

    function decimals() external view returns (uint8);
}