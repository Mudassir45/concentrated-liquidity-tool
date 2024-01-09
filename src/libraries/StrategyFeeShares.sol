// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.5.0;

import { ICLTBase } from "../interfaces/ICLTBase.sol";

import { Constants } from "../libraries/Constants.sol";
import { PoolActions } from "../libraries/PoolActions.sol";
import { FixedPoint128 } from "../libraries/FixedPoint128.sol";

import { SafeMath } from "@openzeppelin/contracts/utils/math/SafeMath.sol";
import { FullMath } from "@uniswap/v3-core/contracts/libraries/FullMath.sol";

library StrategyFeeShares {
    struct GlobalAccount {
        uint256 positionFee0;
        uint256 positionFee1;
        uint256 totalLiquidity;
        uint256 feeGrowthInside0LastX128;
        uint256 feeGrowthInside1LastX128;
    }

    function updateGlobalStrategyFees(
        mapping(bytes32 => GlobalAccount) storage self,
        ICLTBase.StrategyKey memory key
    )
        external
        returns (GlobalAccount storage account)
    {
        account = self[keccak256(abi.encodePacked(key.pool, key.tickLower, key.tickUpper))];

        PoolActions.updatePosition(key);

        if (account.totalLiquidity > 0) {
            (uint256 fees0, uint256 fees1) =
                PoolActions.collectPendingFees(key, Constants.MAX_UINT128, Constants.MAX_UINT128, address(this));

            account.positionFee0 += fees0;
            account.positionFee1 += fees1;

            account.feeGrowthInside0LastX128 += FullMath.mulDiv(fees0, FixedPoint128.Q128, account.totalLiquidity);
            account.feeGrowthInside1LastX128 += FullMath.mulDiv(fees1, FixedPoint128.Q128, account.totalLiquidity);
        }
    }

    function updateStrategyFees(
        ICLTBase.StrategyData storage self,
        GlobalAccount storage global
    )
        external
        returns (uint256 total0, uint256 total1)
    {
        (uint256 feeGrowthInside0LastX128, uint256 feeGrowthInside1LastX128) =
            (global.feeGrowthInside0LastX128, global.feeGrowthInside1LastX128);

        bool isExit;

        if (self.actionStatus.length > 0) {
            (, isExit) = abi.decode(self.actionStatus, (uint256, bool));
        }

        if (isExit == false) {
            total0 = uint128(
                FullMath.mulDiv(
                    feeGrowthInside0LastX128 - self.account.feeGrowthInside0LastX128,
                    self.account.totalShares,
                    FixedPoint128.Q128
                )
            );

            total1 = uint128(
                FullMath.mulDiv(
                    feeGrowthInside1LastX128 - self.account.feeGrowthInside1LastX128,
                    self.account.totalShares,
                    FixedPoint128.Q128
                )
            );
        }

        // precesion loss expected here so rounding the value to zero to prevent overflow
        (, global.positionFee0) = SafeMath.trySub(global.positionFee0, total0);
        (, global.positionFee1) = SafeMath.trySub(global.positionFee1, total1);

        self.account.fee0 += total0;
        self.account.fee1 += total1;

        self.account.feeGrowthInside0LastX128 = feeGrowthInside0LastX128;
        self.account.feeGrowthInside1LastX128 = feeGrowthInside1LastX128;
    }
}