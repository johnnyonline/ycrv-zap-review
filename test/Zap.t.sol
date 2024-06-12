// SPDX-License-Identifier: MIT
pragma solidity 0.8.25;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";

import "forge-std/Test.sol";

interface IZapYCRV {
    function zap(address _input_token, address _output_token, uint256 _amount_in, uint256 _min_out, address _recipient) external returns (uint256);
    function relative_price(address _input_token, address _output_token, uint256 _amount_in) external view returns (uint256);
    function calc_expected_out(address _input_token, address _output_token, uint256 _amount_in) external view returns (uint256);
    function sweep(address _token, uint256 _amount) external;
    function set_mint_buffer(uint256 _new_buffer) external;
    function set_sweep_recipient(address _proposed_sweep_recipient) external;
}

interface IYBS {
    
    enum ApprovalStatus {
        None,               // 0. Default value, indicating no approval
        StakeOnly,          // 1. Approved for stake only
        UnstakeOnly,        // 2. Approved for unstake only
        StakeAndUnstake     // 3. Approved for both stake and unstake
    }

    function setApprovedCaller(address _caller, ApprovalStatus _status) external;
}


// NOTE: run with `--evm-version cancun` flag
contract ZapTest is Test {

    address public user;

    IZapYCRV public zap;

    address public constant YVECRV = address(0xc5bDdf9843308380375a611c18B50Fb9341f502A);
    address public constant CRV = address(0xD533a949740bb3306d119CC777fa900bA034cd52);
    address public constant YVBOOST = address(0x9d409a0A012CFbA9B15F6D4B36Ac57A46966Ab9a);
    address public constant YCRV = address(0xFCc5c47bE19d06BF83eB04298b026F81069ff65b);
    address public constant STYCRV = address(0x27B5739e22ad9033bcBf192059122d163b60349D);
    address public constant LPYCRV_V1 = address(0xc97232527B62eFb0D8ed38CF3EA103A6CcA4037e);
    address public constant LPYCRV_V2 = address(0x6E9455D109202b426169F0d8f01A3332DAE160f3);
    address public constant POOL_V1 = address(0x453D92C7d4263201C69aACfaf589Ed14202d83a4);
    address public constant POOL_V2 = address(0x99f5aCc8EC2Da2BC0771c32814EFF52b712de1E5);
    address public constant CVXCRV = address(0x62B9c7356A2Dc64a1969e19C23e4f579F9810Aa7);
    address public constant CVXCRVPOOL = address(0x9D0464996170c6B9e75eED71c68B99dDEDf279e8);
    address public constant YBS = address(0xE9A115b77A1057C918F997c32663FdcE24FB873f);

    // ============================================================================================
    // Setup
    // ============================================================================================

    function setUp() public {
        vm.selectFork(vm.createFork(vm.envString("ETHEREUM_RPC_URL")));

        zap = IZapYCRV(deployCode("ZapYCRV.vy"));

        // initialize user
        user = _createUser();

        // approve YBS
        vm.prank(user);
        IYBS(YBS).setApprovedCaller(address(zap), IYBS.ApprovalStatus.StakeAndUnstake);
    }

    // ============================================================================================
    // Tests
    // ============================================================================================

    function testYcrvToYbs() public {
        uint256 _ybsBalanceBefore = IERC20(YBS).balanceOf(user);
        assertEq(_ybsBalanceBefore, 0, "testYcrvToYbs: E0");

        uint256 _ycrvAmount = IERC20(YCRV).balanceOf(user);
        assertTrue(_ycrvAmount > 0, "testYcrvToYbs: E1");

        uint256 _min_out = zap.calc_expected_out(YCRV, YBS, _ycrvAmount);
        assertEq(_min_out, _ycrvAmount, "testYcrvToYbs: E2");

        vm.startPrank(user);
        IYBS(YBS).setApprovedCaller(address(zap), IYBS.ApprovalStatus.StakeAndUnstake);
        IERC20(YCRV).approve(address(zap), _ycrvAmount);
        uint256 _amountOut = zap.zap(YCRV, YBS, _ycrvAmount, _min_out, user);
        vm.stopPrank();

        assertApproxEqAbs(_amountOut, _ycrvAmount, 2, "testYcrvToYbs: E3");
        assertEq(IERC20(YBS).balanceOf(user), _ybsBalanceBefore + _amountOut, "testYcrvToYbs: E4");
    }

    function testYbsToYcrv() public {
        testYcrvToYbs();

        uint256 _ycrvBalanceBefore = IERC20(YCRV).balanceOf(user);
        assertEq(_ycrvBalanceBefore, 0, "testYbsToYcrv: E0");

        uint256 _ybsAmount = IERC20(YBS).balanceOf(user);
        assertTrue(_ybsAmount > 0, "testYbsToYcrv: E1");

        uint256 _min_out = zap.calc_expected_out(YBS, YCRV, _ybsAmount);
        assertEq(_min_out, _ybsAmount, "testYbsToYcrv: E2");

        vm.startPrank(user);
        uint256 _amountOut = zap.zap(YBS, YCRV, _ybsAmount, _min_out, user);
        vm.stopPrank();

        assertEq(_amountOut, _ybsAmount, "testYbsToYcrv: E3");
        assertEq(IERC20(YCRV).balanceOf(user), _ycrvBalanceBefore + _amountOut, "testYbsToYcrv: E4");
    }

    function testCrvToYbs() public {
        uint256 _ybsBalanceBefore = IERC20(YBS).balanceOf(user);
        assertEq(_ybsBalanceBefore, 0, "testCrvToYbs: E0");

        uint256 _crvAmount = IERC20(CRV).balanceOf(user);
        assertTrue(_crvAmount > 0, "testCrvToYbs: E1");

        uint256 _min_out = zap.calc_expected_out(CRV, YBS, _crvAmount);
        vm.startPrank(user);
        IERC20(CRV).approve(address(zap), _crvAmount);
        uint256 _amountOut = zap.zap(CRV, YBS, _crvAmount, _min_out, user);
        vm.stopPrank();

        assertEq(IERC20(YBS).balanceOf(user), _ybsBalanceBefore + _amountOut, "testCrvToYbs: E2");
    }

    function testStycrvToYbs() public {
        uint256 _ybsBalanceBefore = IERC20(YBS).balanceOf(user);
        assertEq(_ybsBalanceBefore, 0, "testStycrvToYbs: E0");

        uint256 _stycrvAmount = IERC20(STYCRV).balanceOf(user);
        assertTrue(_stycrvAmount > 0, "testStycrvToYbs: E1");

        uint256 _min_out = zap.calc_expected_out(STYCRV, YBS, _stycrvAmount);
        vm.startPrank(user);
        IERC20(STYCRV).approve(address(zap), _stycrvAmount);
        uint256 _amountOut = zap.zap(STYCRV, YBS, _stycrvAmount, _min_out, user);
        vm.stopPrank();

        assertEq(IERC20(YBS).balanceOf(user), _ybsBalanceBefore + _amountOut, "testStycrvToYbs: E2");
    }

    function testYbsToStycrv() public {
        testStycrvToYbs();

        uint256 _stycrvBalanceBefore = IERC20(STYCRV).balanceOf(user);
        assertEq(_stycrvBalanceBefore, 0, "testYbsToStycrv: E0");

        uint256 _ybsAmount = IERC20(YBS).balanceOf(user);
        assertTrue(_ybsAmount > 0, "testYbsToStycrv: E1");

        uint256 _min_out = zap.calc_expected_out(YBS, STYCRV, _ybsAmount) * 99 / 100;
        vm.startPrank(user);
        uint256 _amountOut = zap.zap(YBS, STYCRV, _ybsAmount, _min_out, user);
        vm.stopPrank();

        assertTrue(_amountOut > 0, "testYbsToStycrv: E2");
        assertEq(IERC20(STYCRV).balanceOf(user), _stycrvBalanceBefore + _amountOut, "testYbsToStycrv: E3");
    }

    function testStycrvToYcrv() public {
        uint256 _ycrvBalanceBefore = IERC20(YCRV).balanceOf(user);
        uint256 _stycrvAmount = IERC20(STYCRV).balanceOf(user);
        assertTrue(_stycrvAmount > 0, "testStycrvToYcrv: E1");

        uint256 _min_out = zap.calc_expected_out(STYCRV, YCRV, _stycrvAmount);
        vm.startPrank(user);
        IERC20(STYCRV).approve(address(zap), _stycrvAmount);
        uint256 _amountOut = zap.zap(STYCRV, YCRV, _stycrvAmount, _min_out, user);
        vm.stopPrank();

        assertTrue(_amountOut > 0, "testStycrvToYcrv: E2");
        assertEq(IERC20(YCRV).balanceOf(user), _ycrvBalanceBefore + _amountOut, "testStycrvToYcrv: E3");
    }

    function testYcrvToStycrv() public {
        uint256 _stycrvBalanceBefore = IERC20(STYCRV).balanceOf(user);
        uint256 _ycrvAmount = IERC20(YCRV).balanceOf(user);
        assertTrue(_ycrvAmount > 0, "testYcrvToStycrv: E1");

        uint256 _min_out = zap.calc_expected_out(YCRV, STYCRV, _ycrvAmount) * 99 / 100;
        vm.startPrank(user);
        IERC20(YCRV).approve(address(zap), _ycrvAmount);
        uint256 _amountOut = zap.zap(YCRV, STYCRV, _ycrvAmount, _min_out, user);
        vm.stopPrank();

        assertTrue(_amountOut > 0, "testYcrvToStycrv: E2");
        assertEq(IERC20(STYCRV).balanceOf(user), _stycrvBalanceBefore + _amountOut, "testYcrvToStycrv: E3");
    }

    function testLpycrvV2ToYbs() public {
        uint256 _ybsBalanceBefore = IERC20(YBS).balanceOf(user);
        assertEq(_ybsBalanceBefore, 0, "testLpycrvV2ToYbs: E0");

        uint256 _lpycrvV2Amount = IERC20(LPYCRV_V2).balanceOf(user);
        assertTrue(_lpycrvV2Amount > 0, "testLpycrvV2ToYbs: E1");

        uint256 _min_out = zap.calc_expected_out(LPYCRV_V2, YBS, _lpycrvV2Amount);
        vm.startPrank(user);
        IERC20(LPYCRV_V2).approve(address(zap), _lpycrvV2Amount);
        uint256 _amountOut = zap.zap(LPYCRV_V2, YBS, _lpycrvV2Amount, _min_out, user);
        vm.stopPrank();

        assertEq(IERC20(YBS).balanceOf(user), _ybsBalanceBefore + _amountOut, "testLpycrvV2ToYbs: E2");
    }

    function testLpycrvV2ToYcrv() public {
        uint256 _ycrvBalanceBefore = IERC20(YCRV).balanceOf(user);
        uint256 _lpycrvV2Amount = IERC20(LPYCRV_V2).balanceOf(user);
        assertTrue(_lpycrvV2Amount > 0, "testLpycrvV2ToYcrv: E1");

        uint256 _min_out = zap.calc_expected_out(LPYCRV_V2, YCRV, _lpycrvV2Amount);
        vm.startPrank(user);
        IERC20(LPYCRV_V2).approve(address(zap), _lpycrvV2Amount);
        uint256 _amountOut = zap.zap(LPYCRV_V2, YCRV, _lpycrvV2Amount, _min_out, user);
        vm.stopPrank();

        assertTrue(_amountOut > 0, "testLpycrvV2ToYcrv: E2");
        assertEq(IERC20(YCRV).balanceOf(user), _ycrvBalanceBefore + _amountOut, "testLpycrvV2ToYcrv: E3");
    }

    function testLpycrvV2ToStycrv() public {
        uint256 _stycrvBalanceBefore = IERC20(STYCRV).balanceOf(user);
        uint256 _lpycrvV2Amount = IERC20(LPYCRV_V2).balanceOf(user);
        assertTrue(_lpycrvV2Amount > 0, "testLpycrvV2ToStycrv: E1");

        uint256 _min_out = zap.calc_expected_out(LPYCRV_V2, STYCRV, _lpycrvV2Amount);
        vm.startPrank(user);
        IERC20(LPYCRV_V2).approve(address(zap), _lpycrvV2Amount);
        uint256 _amountOut = zap.zap(LPYCRV_V2, STYCRV, _lpycrvV2Amount, _min_out, user);
        vm.stopPrank();

        assertTrue(_amountOut > 0, "testLpycrvV2ToStycrv: E2");
        assertEq(IERC20(STYCRV).balanceOf(user), _stycrvBalanceBefore + _amountOut, "testLpycrvV2ToStycrv: E3");
    }

    function testYbsToLpycrvV2() public {
        testLpycrvV2ToYbs();

        uint256 _lpycrvV2BalanceBefore = IERC20(LPYCRV_V2).balanceOf(user);
        assertEq(_lpycrvV2BalanceBefore, 0, "testYbsToLpycrvV2: E0");

        uint256 _ybsAmount = IERC20(YBS).balanceOf(user);
        assertTrue(_ybsAmount > 0, "testYbsToLpycrvV2: E1");

        uint256 _min_out = zap.calc_expected_out(YBS, LPYCRV_V2, _ybsAmount) * 99 / 100;
        vm.startPrank(user);
        uint256 _amountOut = zap.zap(YBS, LPYCRV_V2, _ybsAmount, _min_out, user);

        assertTrue(_amountOut > 0, "testYbsToLpycrvV2: E2");
        assertEq(IERC20(LPYCRV_V2).balanceOf(user), _lpycrvV2BalanceBefore + _amountOut, "testYbsToLpycrvV2: E3");
    }

    function testCvxcrvToYbs() public {
        uint256 _ybsBalanceBefore = IERC20(YBS).balanceOf(user);
        assertEq(_ybsBalanceBefore, 0, "testCvxcrvToYbs: E0");

        uint256 _cvxcrvAmount = IERC20(CVXCRV).balanceOf(user);
        assertTrue(_cvxcrvAmount > 0, "testCvxcrvToYbs: E1");

        uint256 _min_out = zap.calc_expected_out(CVXCRV, YBS, _cvxcrvAmount);
        vm.startPrank(user);
        IERC20(CVXCRV).approve(address(zap), _cvxcrvAmount);
        uint256 _amountOut = zap.zap(CVXCRV, YBS, _cvxcrvAmount, _min_out, user);
        vm.stopPrank();

        assertEq(IERC20(YBS).balanceOf(user), _ybsBalanceBefore + _amountOut, "testCvxcrvToYbs: E2");
    }

    function testCvxcrvToYcrv() public {
        uint256 _ycrvBalanceBefore = IERC20(YCRV).balanceOf(user);
        uint256 _cvxcrvAmount = IERC20(CVXCRV).balanceOf(user);
        assertTrue(_cvxcrvAmount > 0, "testCvxcrvToYcrv: E1");

        uint256 _min_out = zap.calc_expected_out(CVXCRV, YCRV, _cvxcrvAmount);
        vm.startPrank(user);
        IERC20(CVXCRV).approve(address(zap), _cvxcrvAmount);
        uint256 _amountOut = zap.zap(CVXCRV, YCRV, _cvxcrvAmount, _min_out, user);
        vm.stopPrank();

        assertTrue(_amountOut > 0, "testCvxcrvToYcrv: E2");
        assertEq(IERC20(YCRV).balanceOf(user), _ycrvBalanceBefore + _amountOut, "testCvxcrvToYcrv: E3");
    }

    function testCvxcrvToStycrv() public {
        uint256 _stycrvBalanceBefore = IERC20(STYCRV).balanceOf(user);
        uint256 _cvxcrvAmount = IERC20(CVXCRV).balanceOf(user);
        assertTrue(_cvxcrvAmount > 0, "testCvxcrvToStycrv: E1");

        uint256 _min_out = zap.calc_expected_out(CVXCRV, STYCRV, _cvxcrvAmount) * 99 / 100;
        vm.startPrank(user);
        IERC20(CVXCRV).approve(address(zap), _cvxcrvAmount);
        uint256 _amountOut = zap.zap(CVXCRV, STYCRV, _cvxcrvAmount, _min_out, user);
        vm.stopPrank();

        assertTrue(_amountOut > 0, "testCvxcrvToStycrv: E2");
        assertEq(IERC20(STYCRV).balanceOf(user), _stycrvBalanceBefore + _amountOut, "testCvxcrvToStycrv: E3");
    }

    // ============================================================================================
    // Internal helpers
    // ============================================================================================

    function _createUser() internal returns (address payable _user) {
        _user = payable(makeAddr("user"));
        vm.deal({ account: user, newBalance: 100 ether });
        deal({ token: address(YVECRV), to: _user, give: 1_000_000 * 10 ** 18 });
        deal({ token: address(CRV), to: _user, give: 1_000_000 * 10 ** 18 });
        deal({ token: address(YVBOOST), to: _user, give: 1_000_000 * 10 ** 18 });
        deal({ token: address(YCRV), to: _user, give: 1_000_000 * 10 ** 18 });
        deal({ token: address(STYCRV), to: _user, give: 1_000_000 * 10 ** 18 });
        deal({ token: address(LPYCRV_V1), to: _user, give: 1_000_000 * 10 ** 18 });
        deal({ token: address(LPYCRV_V2), to: _user, give: 1_000_000 * 10 ** 18 });
        deal({ token: address(POOL_V1), to: _user, give: 1_000_000 * 10 ** 18 });
        deal({ token: address(POOL_V2), to: _user, give: 1_000_000 * 10 ** 18 });
        deal({ token: address(CVXCRV), to: _user, give: 1_000_000 * 10 ** 18 });
        deal({ token: address(CVXCRVPOOL), to: _user, give: 1_000_000 * 10 ** 18 });
    }
}
