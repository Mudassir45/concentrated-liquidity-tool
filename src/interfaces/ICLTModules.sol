//SPDX-License-Identifier: MIT
pragma solidity =0.8.15;

import { ICLTBase } from "./ICLTBase.sol";

interface ICLTModules {
    error InvalidMode();
    error InvalidStrategy();
    error InvalidStrategyAction();

    function validateModes(
        ICLTBase.PositionActions calldata actions,
        uint256 managementFee,
        uint256 performanceFee
    )
        external;
}