// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.15;

import "../libraries/TransferHelper.sol";

import "../interfaces/ICLTPayments.sol";
import "../interfaces/external/IWETH9.sol";
import { ICLTBase } from "../interfaces/ICLTBase.sol";
import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

abstract contract CLTPayments is ICLTPayments {
    uint256 private constant WAD = 1e18;

    address private immutable WETH9;
    IUniswapV3Factory private immutable factory;

    constructor(IUniswapV3Factory _factory, address _WETH9) {
        factory = _factory;
        WETH9 = _WETH9;
    }

    receive() external payable { }

    function uniswapV3MintCallback(uint256 amount0Owed, uint256 amount1Owed, bytes calldata data) external override {
        MintCallbackData memory decodedData = abi.decode(data, (MintCallbackData));

        // verify caller
        address computedPool = factory.getPool(decodedData.token0, decodedData.token1, decodedData.fee);
        require(msg.sender == computedPool, "WHO");

        if (amount0Owed > 0) {
            TransferHelper.safeTransfer(decodedData.token0, msg.sender, amount0Owed);
        }
        if (amount1Owed > 0) {
            TransferHelper.safeTransfer(decodedData.token1, msg.sender, amount1Owed);
        }
    }

    /// @param token The token to pay
    /// @param payer The entity that must pay
    /// @param recipient The entity that will receive payment
    /// @param value The amount to pay
    function pay(address token, address payer, address recipient, uint256 value) internal {
        if (token == WETH9 && address(this).balance >= value) {
            // pay with WETH9
            IWETH9(WETH9).deposit{ value: value }(); // wrap only what is needed to pay
            IWETH9(WETH9).transfer(recipient, value);
        } else if (payer == address(this)) {
            // pay with tokens already in the contract (for the exact input multihop case)
            TransferHelper.safeTransfer(token, recipient, value);
        } else {
            // pull payment
            TransferHelper.safeTransferFrom(token, payer, recipient, value);
        }
    }

    function transferFunds(bool refundAsETH, address recipient, address token, uint256 amount) internal {
        if (refundAsETH && token == WETH9) {
            IWETH9(WETH9).withdraw(amount);
            TransferHelper.safeTransferETH(recipient, amount);
        } else {
            TransferHelper.safeTransfer(token, recipient, amount);
        }
    }

    function transferFee(
        ICLTBase.StrategyFees storage self,
        ICLTBase.StrategyKey memory key,
        uint256 amount0,
        uint256 amount1,
        address governance,
        address strategtOwner
    )
        internal
        returns (uint256 fee0, uint256 fee1)
    {
        if (self.protocolFee > 0) {
            if (amount0 > 0) {
                TransferHelper.safeTransfer(key.pool.token0(), governance, (amount0 * self.protocolFee) / WAD);
            }

            if (amount1 > 0) {
                TransferHelper.safeTransfer(key.pool.token1(), governance, (amount1 * self.protocolFee) / WAD);
            }
        }

        if (self.strategistFee > 0) {
            if (amount0 > 0) {
                TransferHelper.safeTransfer(key.pool.token0(), strategtOwner, (amount0 * self.strategistFee) / WAD);
            }

            if (amount1 > 0) {
                TransferHelper.safeTransfer(key.pool.token1(), strategtOwner, (amount1 * self.strategistFee) / WAD);
            }
        }

        fee0 = ((amount0 * self.protocolFee) / WAD) + ((amount0 * self.protocolFee) / WAD);
        fee1 = ((amount1 * self.protocolFee) / WAD) + ((amount1 * self.protocolFee) / WAD);
    }
}
