// SPDX-License-Identifier: UNLICENSED
pragma solidity =0.8.15;

import { Vm } from "forge-std/Vm.sol";
import { Test } from "forge-std/Test.sol";
import { CLTBase } from "../src/CLTBase.sol";
import { WETH } from "@solmate/tokens/WETH.sol";
import { ERC20Mock } from "./mocks/ERC20Mock.sol";
import { UniswapDeployer } from "./lib/UniswapDeployer.sol";

import { SwapRouter } from "@uniswap/v3-periphery/contracts/SwapRouter.sol";
import { ISwapRouter } from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import { TickMath } from "@uniswap/v3-core/contracts/libraries/TickMath.sol";
import { IUniswapV3Pool } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Pool.sol";
import { IUniswapV3Factory } from "@uniswap/v3-core/contracts/interfaces/IUniswapV3Factory.sol";

contract CLTBaseTest is Test, UniswapDeployer {
    IUniswapV3Factory factory;
    IUniswapV3Pool pool;
    SwapRouter router;
    ERC20Mock token0;
    ERC20Mock token1;
    CLTBase base;
    WETH weth;

    function setUp() public {
        token0 = new ERC20Mock();
        token1 = new ERC20Mock();

        if (address(token0) >= address(token1)) {
            (token0, token1) = (token1, token0);
        }

        // intialize uniswap contracts
        weth = new WETH();
        factory = IUniswapV3Factory(deployUniswapV3Factory());
        pool = IUniswapV3Pool(factory.createPool(address(token0), address(token1), 500));
        pool.initialize(TickMath.getSqrtRatioAtTick(0));
        router = new SwapRouter(address(factory), address(weth));

        // initialize base contract
        base = new CLTBase("ALP Base", "ALP", msg.sender, address(0), 1000000000000000, factory);

        // base.createStrategy();

        // approve tokens
        token0.approve(address(base), type(uint256).max);
        token0.approve(address(router), type(uint256).max);
        token1.approve(address(base), type(uint256).max);
        token1.approve(address(router), type(uint256).max);
    }
}
