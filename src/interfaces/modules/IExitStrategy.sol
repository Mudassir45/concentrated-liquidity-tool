// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.19;

import "../ICLTBase.sol";

interface IExitStrategy {
    error InvalidCaller();

    function checkInputData(ICLTBase.StrategyDetail memory data) external returns (bool);
}
