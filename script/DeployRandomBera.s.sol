// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {RandomBera} from "../src/RandomBera.sol";

import {Script} from "forge-std/Script.sol";
import "forge-std/console.sol";

// ---- Usage ----

// deploy:
// forge script script/DeployRandomBera.s.sol:DeployRandomBera --verify --chain-id 80084 --slow --legacy --etherscan-api-key $KEY --rpc-url https://bartio.rpc.berachain.com/ --broadcast

// verify:
// --constructor-args $(cast abi-encode "constructor(address)" 0x5C1E6bA712e9FC3399Ee7d5824B6Ec68A0363C02)
// forge verify-contract --etherscan-api-key $KEY --watch --chain-id $CHAIN_ID --compiler-version $FULL_COMPILER_VER --verifier-url $VERIFIER_URL $ADDRESS $PATH:$FILE_NAME

contract DeployRandomBera is Script {

    function run() public {
        vm.startBroadcast(vm.envUint("DEPLOYER_PRIVATE_KEY"));

        RandomBera randomBera = new RandomBera();

        vm.stopBroadcast();

        console.log("=====================================");
        console.log("randomBera: ", address(randomBera));
        console.log("=====================================");
    }
}