// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";

interface ICryptoFromPoolsRate {
    function price_w() external returns (uint256);
    function price() external returns (uint256);
    function POOLS(uint256) external view returns (address);
    function BORROWED_IX(uint256) external view returns (uint256);
    function COLLATERAL_IX(uint256) external view returns (uint256);
    function AGG() external view returns (address);
}


// NOTE: run with `--evm-version shanghai` flag
contract CryptoFromPoolsRateTests is Test {

    ICryptoFromPoolsRate public oracle;

    // ============================================================================================
    // Setup
    // ============================================================================================

    function setUp() public {
        vm.selectFork(vm.createFork(vm.envString("ETHEREUM_RPC_URL")));

        address[] memory pools = new address[](2);
        pools[0] = address(0x19B8524665aBAC613D82eCE5D8347BA44C714bDd); // ynETH/wstETH
        pools[1] = address(0x2889302a794dA87fBF1D6Db415C1492194663D13); // TricryptoLLAMA
        uint256[] memory borrowed_ixs = new uint256[](2);
        borrowed_ixs[0] = 1; // wstETH
        borrowed_ixs[1] = 0; // crvUSD
        uint256[] memory collateral_ixs = new uint256[](2);
        collateral_ixs[0] = 0; // ynETH
        collateral_ixs[1] = 2; // wstETH
        address agg = address(0x18672b1b0c623a30089A280Ed9256379fb0E4E62);
        oracle = ICryptoFromPoolsRate(deployCode("CryptoFromPoolsRateWAgg.vy", abi.encode(
            pools,
            borrowed_ixs,
            collateral_ixs,
            agg
        )));
    }

    // ============================================================================================
    // Tests
    // ============================================================================================

    function testPrice() public {
        assertTrue(true);
        console.log("price_w", oracle.price_w());
        console.log("price", oracle.price());
    }
}