// SPDX-License-Identifier: GPL-3.0

pragma solidity >=0.6.0;
pragma abicoder v2;

import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";

struct StrategyKey {
    IUniswapV3Pool pool;
    int24 tickLower;
    int24 tickUpper;
}

struct DepositParams {
    bytes32 strategyId;
    uint256 amount0Desired;
    uint256 amount1Desired;
    uint256 amount0Min;
    uint256 amount1Min;
    address recipient;
}

struct UpdatePositionParams {
    uint256 tokenId;
    uint256 amount0Desired;
    uint256 amount1Desired;
}

struct WithdrawParams {
    uint256 tokenId;
    uint256 liquidity;
    address recipient;
    bool refundAsETH;
}

struct ShiftLiquidityParams {
    StrategyKey key; // new ticks will be given this time
    bytes32 strategyId;
    bool shouldMint;
    bool zeroForOne;
    int256 swapAmount;
    bytes moduleStatus;
}

struct ClaimFeesParams {
    address recipient;
    uint256 tokenId;
    bool refundAsETH;
}

struct ModePackage {
    uint256[] modeIDs;
    address modesVault;
}

struct PositionActions {
    uint256 mode;
    uint256[] exitStrategy;
    uint256[] rebaseStrategy;
    uint256[] liquidityDistribution;
}

struct ActionsData {
    bytes[] exitStrategyData;
    bytes[] rebaseStrategyData;
    bytes[] liquidityDistributionData;
}

struct StrategyData {
    StrategyKey key;
    bytes actions;
    bytes actionsData; // assembly operations needed to merge actions & data into single byte32 word { figure out }
    bytes actionStatus;
    bool isCompound;
    uint256 rebaseCount; // default value (0) to keep track of the number of rebases
    uint256 balance0;
    uint256 balance1;
    uint256 totalShares;
    uint128 uniswapLiquidity;
    uint256 feeGrowthInside0LastX128;
    uint256 feeGrowthInside1LastX128;
}
