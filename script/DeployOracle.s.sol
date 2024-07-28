// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

// ---- Usage ----

// deploy:
// forge script script/DeployOracle.s.sol:DeployOracle --verify --slow --legacy --etherscan-api-key $KEY --rpc-url $RPC_URL --broadcast

// verify:
// --constructor-args $(cast abi-encode "constructor(address)" 0x5C1E6bA712e9FC3399Ee7d5824B6Ec68A0363C02)
// forge verify-contract --etherscan-api-key $KEY --watch --chain-id $CHAIN_ID --compiler-version $FULL_COMPILER_VER --verifier-url $VERIFIER_URL $ADDRESS $PATH:$FILE_NAME

contract DeployOracle is Script {

    function run() public {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));
        
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
        address oracle = deployCode("CryptoFromPoolsRateWAgg.vy", abi.encode(
            pools,
            borrowed_ixs,
            collateral_ixs,
            agg
        ));

        vm.stopBroadcast();

        console.log("=====================================");
        console.log("oracle: ", oracle);
        console.log("=====================================");
    }
}

// 0x63f01b695c67B764e823F972bc61fcAFbac5102b