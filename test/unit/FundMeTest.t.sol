// SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {StdAssertions} from "forge-std/StdAssertions.sol";
import {DeployFundMe} from "../../script/DeployFundMe.s.sol";
import {Script} from "forge-std/Script.sol";

contract FundMeTest is StdAssertions, Test {
    FundMe fundMe;
    address USER = makeAddr("user"); // address of the fake user
    uint256 constant SEND_VALUE = 0.1 ether;
    uint256 constant STARTING_BALANCE = 10 ether;
    uint256 constant GAS_PRICE = 1;

    modifier funded() {
        vm.prank(USER); // the next tx will be sent by the user
        fundMe.fund{value: SEND_VALUE}();

        _;
    }

    /**
     * @dev first thing that happens in the test suite
     * @dev deploys the Smart Contract
     */
    function setUp() external {
        // fundMe = new FundMe(0x694AA1769357215DE4FAC081bf1f309aDC325306);
        DeployFundMe deployFundMe = new DeployFundMe();
        fundMe = deployFundMe.run();
        vm.deal(USER, STARTING_BALANCE); // give the user some ether
    }

    function testMinimumDollarsIsFive() public view {
        assertEq(fundMe.MINIMUM_USD(), 5 * 10 ** 18);
    }

    function testOwnerIsMsgSender() public view {
        // the test contract is the one deploying the FundMe contract
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testPriceFeedVersion() public view {
        assertEq(fundMe.getVersion(), 4);
    }

    function testFundFailsWithoutEnoughEth() public {
        vm.expectRevert(); // next line should revert
        fundMe.fund(); // expecting 5$ but not receiving any eth
    }

    function testFundUpdatesFundedDataStructure() public funded {
        uint256 amountFunded = fundMe.getAddressToAmountFunded(USER);
        assertEq(amountFunded, SEND_VALUE);
    }

    function testAddsFunderToArrayOfFunders() public funded {
        address funder = fundMe.getFunder(0);
        assertEq(funder, USER);
    }

    function testOnlyOwnerWithdraw() public funded {
        vm.expectRevert(); // next tx should revert
        vm.prank(USER); // USER is not the owner of the contract
        fundMe.withdraw(); // only the owner can withdraw (should fail)
    }

    function testWithdrawWithASingleFunder() public funded {
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        uint256 gasStart = gasleft(); // gas before the transaction call (1000 gas)
        vm.txGasPrice(GAS_PRICE); // set gas price to 0
        vm.prank(fundMe.getOwner()); // cost: 200 gas
        fundMe.withdraw();

        uint256 gasEnd = gasleft(); // gas used after the transaction call (should left 800 gas)
        uint256 gasUsed = (gasStart - gasEnd) * tx.gasprice; // gas used in the transaction
        console.log("Gas used: ", gasUsed);

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingFundMeBalance = address(fundMe).balance;
        assertEq(endingFundMeBalance, 0); // contract balance should be 0
        assertEq(
            startingFundMeBalance + startingOwnerBalance,
            endingOwnerBalance
        );
    }

    function testWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // avoid address 0

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank(USER); // the next tx will be sent by the user
            // vm.deal(USER, SEND_VALUE);
            hoax(address(i), SEND_VALUE); // create an address and add ETH
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner()); // the owner is the next tx sender
        fundMe.withdraw();

        assert(address(fundMe).balance == 0); // contract balance should be 0
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }

    function testCheaperWithdrawFromMultipleFunders() public funded {
        uint160 numberOfFunders = 10;
        uint160 startingFunderIndex = 1; // avoid address 0

        for (uint160 i = startingFunderIndex; i < numberOfFunders; i++) {
            // vm.prank(USER); // the next tx will be sent by the user
            // vm.deal(USER, SEND_VALUE);
            hoax(address(i), SEND_VALUE); // create an address and add ETH
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingFundMeBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner()); // the owner is the next tx sender
        fundMe.cheaperWithdraw();

        assert(address(fundMe).balance == 0); // contract balance should be 0
        assert(
            startingFundMeBalance + startingOwnerBalance ==
                fundMe.getOwner().balance
        );
    }
}
