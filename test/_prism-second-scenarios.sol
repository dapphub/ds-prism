// Copyright (C) 2017  DappHub, LLC

// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.

// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
// GNU General Public License for more details.

// You should have received a copy of the GNU General Public License
// along with this program.  If not, see <http://www.gnu.org/licenses/>.

pragma solidity ^0.8.0;

//import "ds-test/test.sol";
import "../contracts/ERC20Token.sol";
// import "../contracts/iou.sol";
import "../contracts/Prism.sol";
import "../contracts/PrismUser.sol";

contract DSPrismTestOne {
    uint constant electionSize = 3;

    // c prefix: candidate
    address constant c1 = address(0x1);
    address constant c2 = address(0x2);
    address constant c3 = address(0x3);
    address constant c4 = address(0x4);
    address constant c5 = address(0x5);
    address constant c6 = address(0x6);
    address constant c7 = address(0x7);
    address constant c8 = address(0x8);
    address constant c9 = address(0x9);
    uint256 constant initialBalance = 1000 ether;
    uint256 constant uLargeInitialBalance = initialBalance / 3;
    uint256 constant uMediumInitialBalance = initialBalance / 4;
    uint256 constant uSmallInitialBalance = initialBalance / 5;

    Prism prism;
    ERC20Token gov;
    ERC20Token iou;

    // u prefix: user
    PrismUser uLarge;
    PrismUser uMedium;
    PrismUser uSmall;

    function setUp() public {
        gov = new ERC20Token("GOV","GOV");
        gov.mint(msg.sender, initialBalance);

        iou = new ERC20Token("IOU", "IOU");
        prism = new Prism(gov, iou, electionSize);
       
        uLarge = new PrismUser(gov, prism);
        uMedium = new PrismUser(gov, prism);
        uSmall = new PrismUser(gov, prism);

        assert(initialBalance > uLargeInitialBalance + uMediumInitialBalance +
               uSmallInitialBalance);
        assert(uLargeInitialBalance < uMediumInitialBalance + uSmallInitialBalance);

        gov.transfer(uLarge.getWalletAddress(), uLargeInitialBalance);
        gov.transfer(uMedium.getWalletAddress(), uMediumInitialBalance);
        gov.transfer(uSmall.getWalletAddress(), uSmallInitialBalance);
    }

    function test_voting_and_reordering() public {
        assert(gov.balanceOf(uLarge.getWalletAddress()) == gov.balanceOf(uLarge.getWalletAddress()));
        
        initial_vote();

        // Upset the order.
        uint uLargeLockedAmt = uLargeInitialBalance;
        uLarge.doApprove(gov, prism, uLargeLockedAmt);
        uLarge.doLock(uLargeLockedAmt);

        address[] memory uLargeSlate = new address[](1);
        uLargeSlate[0] = c3;
        uLarge.doVote(uLargeSlate);

        // Update the elected set to reflect the new order.
        prism.swap(0, 2);
    }

    function testFail_snap_while_out_of_order() public {
        initial_vote();

        // Upset the order.
        uSmall.doApprove(gov, prism, uSmallInitialBalance);
        uSmall.doApprove(iou, prism, uSmallInitialBalance);
        uSmall.doLock(uSmallInitialBalance);

        address[] memory uSmallSlate = new address[](1);
        uSmallSlate[0] = c3;
        uSmall.doVote(uSmallSlate);

        uMedium.doFree(uMediumInitialBalance);

        prism.snap();
    }

    function test_swap_half_votes() public {
        initial_vote();

        // Upset the order.
        uSmall.doApprove(gov, prism, uSmallInitialBalance);
        uSmall.doLock(uSmallInitialBalance);

        address[] memory uSmallSlate = new address[](1);
        uSmallSlate[0] = c3;
        uSmall.doVote(uSmallSlate);

        uMedium.doFree(uMediumInitialBalance);

        prism.swap(0, 2);
        prism.snap();

        assert(!prism.isElected(c1));
        assert(!prism.isElected(c2));
        assert(prism.isElected(c3));
    }

    function testFail_drop_past_end_of_elected() public {
        assert(gov.balanceOf(uLarge.getWalletAddress()) == uLargeInitialBalance);

        initial_vote();

        // Upset the order.
        uLarge.doApprove(gov, prism, uLargeInitialBalance);
        uLarge.doLock(uLargeInitialBalance);

        address[] memory uLargeSlate = new address[](1);
        uLargeSlate[0] = c4;
        uLarge.doVote(uLargeSlate);

        // Update the elected set to reflect the new order.
        prism.drop(3, c4);
    }

    function testFail_voting_and_reordering_without_weight() public {
        assert(gov.balanceOf(uLarge.getWalletAddress()) == uLargeInitialBalance);

        initial_vote();

        // Vote without weight.
        address[] memory uLargeSlate = new address[](1);
        uLargeSlate[0] = c3;
        uLarge.doVote(uLargeSlate);

        // Attempt to update the elected set.
        prism.swap(0, 2);
    }

    function test_voting_by_slate_id() public {
        assert(gov.balanceOf(uLarge.getWalletAddress()) == uLargeInitialBalance);

        bytes32 slateID = initial_vote();

        // Upset the order.
        uLarge.doApprove(gov, prism, uLargeInitialBalance);
        uLarge.doLock(uLargeInitialBalance);

        address[] memory uLargeSlate = new address[](1);
        uLargeSlate[0] = c4;
        uLarge.doVote(uLargeSlate);

        // Update the elected set to reflect the new order.
        prism.drop(2, c4);
        prism.swap(0, 2);

        // Now restore the old order using a slate ID.
        uSmall.doApprove(gov, prism, uSmallInitialBalance);
        uSmall.doLock(uSmallInitialBalance);
        uSmall.doVote(uLargeSlate);

        // Update the elected set to reflect the restored order.
        prism.drop(0, c3);
    }

    function initial_vote() internal returns (bytes32 slateID) {
        uint uMediumLockedAmt = uMediumInitialBalance;
        uMedium.doApprove(gov, prism, uMediumLockedAmt);
        uMedium.doApprove(iou, prism, uMediumLockedAmt);
        uMedium.doLock(uMediumLockedAmt);

        address[] memory uMediumSlate = new address[](3);
        uMediumSlate[0] = c1;
        uMediumSlate[1] = c2;
        uMediumSlate[2] = c3;
        slateID = uMedium.doVote(uMediumSlate);

        // Populate the elected set.
        prism.drop(0, c1);
        prism.drop(1, c2);
        prism.drop(2, c3);
    }
}
