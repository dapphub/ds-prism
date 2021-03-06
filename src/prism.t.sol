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

pragma solidity ^0.4.17;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "./prism.sol";


contract PrismUser {
    DSToken GOV;
    DSPrism prism;

    function PrismUser(DSToken GOV_, DSPrism prism_) public {
        GOV = GOV_;
        prism = prism_;
    }

    function doTransferFrom(address from, address to, uint amount)
        public
        returns (bool)
    {
        return GOV.transferFrom(from, to, amount);
    }

    function doTransfer(address to, uint amount)
        public
        returns (bool)
    {
        return GOV.transfer(to, amount);
    }

    function doApprove(DSToken token, address recipient, uint amount)
        public
        returns (bool)
    {
        return token.approve(recipient, amount);
    }

    function doAllowance(address owner, address spender)
        public
        view
        returns (uint)
    {
        return GOV.allowance(owner, spender);
    }

    function doBalanceOf(address who)
        public
        view
        returns (uint)
    {
        return GOV.balanceOf(who);
    }

    function doSwap(uint i, uint j) public {
        prism.swap(i, j);
    }

    function doDrop(uint i, address b) public {
        prism.drop(i, b);
    }

    function doEtch(address[] guys) public returns (bytes32) {
        return prism.etch(guys);
    }

    function doVote(address[] guys) public returns (bytes32) {
        return prism.vote(guys);
    }

    function doVote(bytes32 id) public {
        prism.vote(id);
    }

    function doLock(uint amt) public {
        prism.lock(amt);
    }

    function doFree(uint amt) public {
        prism.free(amt);
    }
}

contract DSPrismTest is DSTest {
    uint constant electionSize = 3;

    // c prefix: candidate
    address constant c1 = 0x1;
    address constant c2 = 0x2;
    address constant c3 = 0x3;
    address constant c4 = 0x4;
    address constant c5 = 0x5;
    address constant c6 = 0x6;
    address constant c7 = 0x7;
    address constant c8 = 0x8;
    address constant c9 = 0x9;
    uint256 constant initialBalance = 1000 ether;
    uint256 constant uLargeInitialBalance = initialBalance / 3;
    uint256 constant uMediumInitialBalance = initialBalance / 4;
    uint256 constant uSmallInitialBalance = initialBalance / 5;

    DSPrism prism;
    DSToken GOV;
    DSToken IOU;

    // u prefix: user
    PrismUser uLarge;
    PrismUser uMedium;
    PrismUser uSmall;

    function setUp() public {
        GOV = new DSToken("GOV");
        GOV.mint(initialBalance);

        IOU = new DSToken("IOU");
        prism = new DSPrism(GOV, IOU, electionSize);
        IOU.setOwner(prism);

        uLarge = new PrismUser(GOV, prism);
        uMedium = new PrismUser(GOV, prism);
        uSmall = new PrismUser(GOV, prism);

        assert(initialBalance > uLargeInitialBalance + uMediumInitialBalance +
               uSmallInitialBalance);
        assert(uLargeInitialBalance < uMediumInitialBalance + uSmallInitialBalance);

        GOV.transfer(uLarge, uLargeInitialBalance);
        GOV.transfer(uMedium, uMediumInitialBalance);
        GOV.transfer(uSmall, uSmallInitialBalance);
    }

    function test_etch_returns_same_id_for_same_sets() public {
        var candidates = new address[](3);
        candidates[0] = c1;
        candidates[1] = c2;
        candidates[2] = c3;

        var id = uSmall.doEtch(candidates);
        assert(id != 0x0);
        assertEq32(id, uMedium.doEtch(candidates));
    }

    function test_size_zero_slate() public {
        var candidates = new address[](0);
        var id = uSmall.doEtch(candidates);
        uSmall.doVote(id);
    }
    function test_size_one_slate() public {
        var candidates = new address[](1);
        candidates[0] = c1;
        var id = uSmall.doEtch(candidates);
        uSmall.doVote(id);
    }

    function testFail_etch_requires_ordered_sets() public {
        var candidates = new address[](3);
        candidates[0] = c2;
        candidates[1] = c1;
        candidates[2] = c3;

        uSmall.doEtch(candidates);
    }

    function test_lock_debits_user() public {
        assert(GOV.balanceOf(uLarge) == uLargeInitialBalance);

        var lockedAmt = uLargeInitialBalance / 10;
        uLarge.doApprove(GOV, prism, lockedAmt);
        uLarge.doLock(lockedAmt);

        assert(GOV.balanceOf(uLarge) == uLargeInitialBalance -
               lockedAmt);
    }

    function test_changing_weight_after_voting() public {
        var uLargeLockedAmt = uLargeInitialBalance / 2;
        uLarge.doApprove(GOV, prism, uLargeLockedAmt);
        uLarge.doApprove(IOU, prism, uLargeLockedAmt);
        uLarge.doLock(uLargeLockedAmt);

        var uLargeSlate = new address[](1);
        uLargeSlate[0] = c1;
        uLarge.doVote(uLargeSlate);

        assert(prism.approvals(c1) == uLargeLockedAmt);

        // Changing weight should update the weight of our candidate.
        uLarge.doFree(uLargeLockedAmt);
        assert(prism.votes(c1) == 0);

        uLargeLockedAmt = uLargeInitialBalance / 4;
        uLarge.doApprove(GOV, prism, uLargeLockedAmt);
        uLarge.doLock(uLargeLockedAmt);

        assert(prism.approvals(c1) == uLargeLockedAmt);
    }

    function test_voting_and_reordering() public {
        assert(GOV.balanceOf(uLarge) == uLargeInitialBalance);

        initial_vote();

        // Upset the order.
        var uLargeLockedAmt = uLargeInitialBalance;
        uLarge.doApprove(GOV, prism, uLargeLockedAmt);
        uLarge.doLock(uLargeLockedAmt);

        var uLargeSlate = new address[](1);
        uLargeSlate[0] = c3;
        uLarge.doVote(uLargeSlate);

        // Update the elected set to reflect the new order.
        prism.swap(0, 2);
    }

    function testFail_snap_while_out_of_order() public {
        initial_vote();

        // Upset the order.
        uSmall.doApprove(GOV, prism, uSmallInitialBalance);
        uSmall.doApprove(IOU, prism, uSmallInitialBalance);
        uSmall.doLock(uSmallInitialBalance);

        var uSmallSlate = new address[](1);
        uSmallSlate[0] = c3;
        uSmall.doVote(uSmallSlate);

        uMedium.doFree(uMediumInitialBalance);

        prism.snap();
    }

    function test_swap_half_votes() public {
        initial_vote();

        // Upset the order.
        uSmall.doApprove(GOV, prism, uSmallInitialBalance);
        uSmall.doLock(uSmallInitialBalance);

        var uSmallSlate = new address[](1);
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
        assert(GOV.balanceOf(uLarge) == uLargeInitialBalance);

        initial_vote();

        // Upset the order.
        uLarge.doApprove(GOV, prism, uLargeInitialBalance);
        uLarge.doLock(uLargeInitialBalance);

        var uLargeSlate = new address[](1);
        uLargeSlate[0] = c4;
        uLarge.doVote(uLargeSlate);

        // Update the elected set to reflect the new order.
        prism.drop(3, c4);
    }

    function testFail_voting_and_reordering_without_weight() public {
        assert(GOV.balanceOf(uLarge) == uLargeInitialBalance);

        initial_vote();

        // Vote without weight.
        var uLargeSlate = new address[](1);
        uLargeSlate[0] = c3;
        uLarge.doVote(uLargeSlate);

        // Attempt to update the elected set.
        prism.swap(0, 2);
    }

    function test_voting_by_slate_id() public {
        assert(GOV.balanceOf(uLarge) == uLargeInitialBalance);

        var slateID = initial_vote();

        // Upset the order.
        uLarge.doApprove(GOV, prism, uLargeInitialBalance);
        uLarge.doLock(uLargeInitialBalance);

        var uLargeSlate = new address[](1);
        uLargeSlate[0] = c4;
        uLarge.doVote(uLargeSlate);

        // Update the elected set to reflect the new order.
        prism.drop(2, c4);
        prism.swap(0, 2);

        // Now restore the old order using a slate ID.
        uSmall.doApprove(GOV, prism, uSmallInitialBalance);
        uSmall.doLock(uSmallInitialBalance);
        uSmall.doVote(slateID);

        // Update the elected set to reflect the restored order.
        prism.drop(0, c3);
    }

    function initial_vote() internal returns (bytes32 slateID) {
        var uMediumLockedAmt = uMediumInitialBalance;
        uMedium.doApprove(GOV, prism, uMediumLockedAmt);
        uMedium.doApprove(IOU, prism, uMediumLockedAmt);
        uMedium.doLock(uMediumLockedAmt);

        var uMediumSlate = new address[](3);
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
