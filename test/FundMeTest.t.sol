// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../src/FundMe.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {DeployFundMe} from "../script/DeployFundMe.s.sol";

contract FundMeTest is StdAssertions {
    FundMe fundMe;

    /**
     * @dev first thing that happens in the test suite
     * @dev deploys the Smart Contract
     */
    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
    }

    function testMinimumDollarsIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function testOwnerIsMsgSender() public view {
        // the test contract is the one deploying the FundMe contract
        assertEq(fundMe.i_owner(), msg.sender);
    }

    function testPriceFeedVersion() public view {
        assertEq(fundMe.getVersion(), 4);
    }
}
