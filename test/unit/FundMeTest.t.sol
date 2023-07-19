//SPDX-License-Identifier: MIT
pragma solidity ^0.8.18;

import {Test, console} from "forge-std/Test.sol";
import {FundMe} from "../../src/FundMe.sol";
import {Deploy} from "../../script/Deploy.s.sol";

contract FundMeTest is Test {
    FundMe fundMe;
    uint256 constant SEND_VALUE = 1 ether;
    address USER = makeAddr("user");
    uint256 constant STARTING_BALANCE = 10 ether;

    function setUp() external {
        Deploy deploy = new Deploy();
        fundMe = deploy.run();
        vm.deal(USER, STARTING_BALANCE);
    }

    function testVersion() public {
        uint256 version = fundMe.getVersion();
        assertEq(version, 4);
    }

    function testIsOwner() public {
        assertEq(fundMe.getOwner(), msg.sender);
    }

    function testMinAmountisFiveUSD() public {
        assertEq(fundMe.MINIMUM_USD(), 5e18);
    }

    function testFundUnderspend() public {
        vm.expectRevert();
        fundMe.fund{value: 1000 wei}();
    }

    function testFundersMappingUpdated() public funded {
        assertEq(fundMe.getAddressToAmountFunded(USER), SEND_VALUE);
    }

    function testFundersArrayUpdated() public funded {
        assertEq(USER, fundMe.getAddressFromArray(0));
    }

    function testOnlyOwnerCanWithdraw() public funded {
        vm.expectRevert();
        vm.startPrank(USER);
        fundMe.withdraw();
    }

    function testWithdrawWithSingleFunder() public funded {
        //Arrange
        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        //Act
        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        //Assert
        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assertEq(
            (startingOwnerBalance + startingContractBalance),
            endingOwnerBalance
        );
        assertEq(endingContractBalance, 0);
    }

    function testWithdrawWithMultipleFunders() public funded {
        for (uint160 i = 1; i <= 10; i++) {
            hoax(address(i));
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.withdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assertEq(
            (startingOwnerBalance + startingContractBalance),
            endingOwnerBalance
        );
        assertEq(endingContractBalance, 0);
    }

    function testWithdrawWithMultipleFundersCheaper() public funded {
        for (uint160 i = 1; i <= 10; i++) {
            hoax(address(i));
            fundMe.fund{value: SEND_VALUE}();
        }

        uint256 startingOwnerBalance = fundMe.getOwner().balance;
        uint256 startingContractBalance = address(fundMe).balance;

        vm.prank(fundMe.getOwner());
        fundMe.cheaperWithdraw();

        uint256 endingOwnerBalance = fundMe.getOwner().balance;
        uint256 endingContractBalance = address(fundMe).balance;

        assertEq(
            (startingOwnerBalance + startingContractBalance),
            endingOwnerBalance
        );
        assertEq(endingContractBalance, 0);
    }

    modifier funded() {
        vm.startPrank(USER);
        fundMe.fund{value: SEND_VALUE}();
        vm.stopPrank();
        _;
    }
}
