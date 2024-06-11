// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import "forge-std/Test.sol";

interface IZapYCRV {
    function zap(address _input_token, address _output_token, uint256 _amount_in, uint256 _min_out, address _recipient) external returns (uint256);
    function relative_price(address _input_token, address _output_token, uint256 _amount_in) external view returns (uint256);
    function calc_expected_out(address _input_token, address _output_token, uint256 _amount_in) external view returns (uint256);
    function sweep(address _token, uint256 _amount) external;
    function set_mint_buffer(uint256 _new_buffer) external;
    function set_sweep_recipient(address _proposed_sweep_recipient) external;
}

contract ZapTest is Test {

    IZapYCRV public zap;

    function setUp() public {
        vm.selectFork(vm.createFork(vm.envString("ETHEREUM_RPC_URL")));

        zap = IZapYCRV(deployCode("ZapYCRV.vy"));
    }

    function testSanity() public {
        assertTrue(true);
    }
}
