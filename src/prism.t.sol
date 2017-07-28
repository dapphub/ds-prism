pragma solidity ^0.4.8;

import "ds-test/test.sol";
import "ds-token/token.sol";

import "./prism.sol";


contract PrismUser {
    DSToken token;
    DSPrism prism;

    function PrismUser(DSToken token_, DSPrism prism_) {
        token = token_;
        prism = prism_;
    }

    function doTransferFrom(address from, address to, uint amount)
        returns (bool)
    {
        return token.transferFrom(from, to, amount);
    }

    function doTransfer(address to, uint amount)
        returns (bool)
    {
        return token.transfer(to, amount);
    }

    function doApprove(address recipient, uint amount)
        returns (bool)
    {
        return token.approve(recipient, amount);
    }

    function doAllowance(address owner, address spender)
        constant returns (uint)
    {
        return token.allowance(owner, spender);
    }

    function doBalanceOf(address who) constant returns (uint) {
        return token.balanceOf(who);
    }

    function doSwap(uint i, uint j) {
        prism.swap(i, j);
    }

    function doDrop(uint i, address b) {
        prism.drop(i, b);
    }

    function doEtch(address[] guys) returns (bytes32) {
        return prism.etch(guys);
    }

    function doVote(address[] guys) returns (bytes32) {
        return prism.vote(guys);
    }

    function doVote(bytes32 id) {
        prism.vote(id);
    }

    function doLock(uint128 amt) {
        prism.lock(amt);
    }

    function doFree(uint128 amt) {
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
    uint128 constant initialBalance = 1000 ether;
    uint128 constant uLargeInitialBalance = initialBalance / 3;
    uint128 constant uMediumInitialBalance = initialBalance / 4;
    uint128 constant uSmallInitialBalance = initialBalance / 5;

    DSPrism prism;
    DSToken token;

    // u prefix: user
    PrismUser uLarge;
    PrismUser uMedium;
    PrismUser uSmall;

    function setUp() {
        token = new DSToken("TST");
        token.mint(initialBalance);

        prism = new DSPrism(token, electionSize);

        uLarge = new PrismUser(token, prism);
        uMedium = new PrismUser(token, prism);
        uSmall = new PrismUser(token, prism);

        assert(initialBalance > uLargeInitialBalance + uMediumInitialBalance +
               uSmallInitialBalance);
        assert(uLargeInitialBalance < uMediumInitialBalance + uSmallInitialBalance);

        token.transfer(uLarge, uLargeInitialBalance);
        token.transfer(uMedium, uMediumInitialBalance);
        token.transfer(uSmall, uSmallInitialBalance);
    }

    function test_basic_sanity() {
        assert(true);
    }

    function testFail_basic_sanity() {
        assert(false);
    }

    function test_etch_returns_same_id_for_same_sets() {
        var candidates = new address[](3);
        candidates[0] = c1;
        candidates[1] = c2;
        candidates[2] = c3;

        var id = uSmall.doEtch(candidates);
        assert(id != 0x0);
        assertEq32(id, uMedium.doEtch(candidates));
    }

    function test_size_zero_slate() {
        var candidates = new address[](0);
        var id = uSmall.doEtch(candidates);
        uSmall.doVote(id);
    }
    function test_size_one_slate() {
        var candidates = new address[](1);
        candidates[0] = c1;
        var id = uSmall.doEtch(candidates);
        uSmall.doVote(id);
    }

    function testFail_etch_requires_ordered_sets() {
        var candidates = new address[](3);
        candidates[0] = c2;
        candidates[1] = c1;
        candidates[2] = c3;

        uSmall.doEtch(candidates);
    }

    function test_lock_debits_user() {
        assert(token.balanceOf(uLarge) == uLargeInitialBalance);

        var lockedAmt = uLargeInitialBalance / 10;
        uLarge.doApprove(prism, lockedAmt);
        uLarge.doLock(lockedAmt);

        assert(token.balanceOf(uLarge) == uLargeInitialBalance -
               lockedAmt);
    }

    function test_changing_weight_after_voting() {
        var uLargeLockedAmt = uLargeInitialBalance / 2;
        uLarge.doApprove(prism, uLargeLockedAmt);
        uLarge.doLock(uLargeLockedAmt);

        var uLargeSlate = new address[](1);
        uLargeSlate[0] = c1;
        uLarge.doVote(uLargeSlate);

        assert(prism.votes(c1) == uLargeLockedAmt);

        // Changing weight should update the weight of our candidate.
        uLarge.doFree(uLargeLockedAmt);
        assert(prism.votes(c1) == 0);

        uLargeLockedAmt = uLargeInitialBalance / 4;
        uLarge.doApprove(prism, uLargeLockedAmt);
        uLarge.doLock(uLargeLockedAmt);

        assert(prism.votes(c1) == uLargeLockedAmt);
    }

    function test_voting_and_reordering() {
        assert(token.balanceOf(uLarge) == uLargeInitialBalance);

        initial_vote();

        // Upset the order.
        var uLargeLockedAmt = uLargeInitialBalance;
        uLarge.doApprove(prism, uLargeLockedAmt);
        uLarge.doLock(uLargeLockedAmt);

        var uLargeSlate = new address[](1);
        uLargeSlate[0] = c3;
        uLarge.doVote(uLargeSlate);

        // Update the elected set to reflect the new order.
        prism.swap(0, 2);
    }

    /*
    function test_drop_half_votes() {
        initial_vote();

        assert(prism.elected(0) == c1);
        assert(prism.elected(1) == c2);
        assert(prism.elected(2) == c3);

        // Upset the order.
        uSmall.doApprove(prism, uSmallInitialBalance);
        uSmall.doLock(uSmallInitialBalance);

        var uSmallSlate = new address[](1);
        uSmallSlate[0] = c3;
        uSmall.doVote(uSmallSlate);

        uMedium.doFree(uMediumInitialBalance);
        assert(prism.votes(c1) == 0);
        assert(prism.votes(c2) == 0);
        assert(prism.votes(c3) == uSmallInitialBalance);

        prism.drop(0);
        assert(prism.elected(0) == 0x0);

        prism.drop(1);
        assert(prism.elected(1) == 0x0);

        prism.swap(0, 2);
        assert(prism.elected(0) == c3);
        assert(prism.elected(2) == 0x0);
    }

    function testFail_drop_half_votes() {
        initial_vote();
        prism.drop(0); // Can't be dropped, too many votes.
    }
    */

    function testFail_snap_while_out_of_order() {
        initial_vote();

        // Upset the order.
        uSmall.doApprove(prism, uSmallInitialBalance);
        uSmall.doLock(uSmallInitialBalance);

        var uSmallSlate = new address[](1);
        uSmallSlate[0] = c3;
        uSmall.doVote(uSmallSlate);

        uMedium.doFree(uMediumInitialBalance);

        prism.snap();
    }

    function test_swap_half_votes() {
        initial_vote();

        // Upset the order.
        uSmall.doApprove(prism, uSmallInitialBalance);
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

    function testFail_drop_past_end_of_elected() {
        assert(token.balanceOf(uLarge) == uLargeInitialBalance);

        var slateID = initial_vote();

        // Upset the order.
        uLarge.doApprove(prism, uLargeInitialBalance);
        uLarge.doLock(uLargeInitialBalance);

        var uLargeSlate = new address[](1);
        uLargeSlate[0] = c4;
        uLarge.doVote(uLargeSlate);

        // Update the elected set to reflect the new order.
        prism.drop(3, c4);
    }

    function testFail_voting_and_reordering_without_weight() {
        assert(token.balanceOf(uLarge) == uLargeInitialBalance);

        initial_vote();

        // Vote without weight.
        var uLargeSlate = new address[](1);
        uLargeSlate[0] = c3;
        uLarge.doVote(uLargeSlate);

        // Attempt to update the elected set.
        prism.swap(0, 2);
    }

    function test_voting_by_slate_id() {
        assert(token.balanceOf(uLarge) == uLargeInitialBalance);

        var slateID = initial_vote();

        // Upset the order.
        uLarge.doApprove(prism, uLargeInitialBalance);
        uLarge.doLock(uLargeInitialBalance);

        var uLargeSlate = new address[](1);
        uLargeSlate[0] = c4;
        uLarge.doVote(uLargeSlate);

        // Update the elected set to reflect the new order.
        prism.drop(2, c4);
        prism.swap(0, 2);

        // Now restore the old order using a slate ID.
        uSmall.doApprove(prism, uSmallInitialBalance);
        uSmall.doLock(uSmallInitialBalance);
        uSmall.doVote(slateID);

        // Update the elected set to reflect the restored order.
        prism.drop(0, c3);
    }

    function initial_vote() internal returns (bytes32 slateID) {
        var uMediumLockedAmt = uMediumInitialBalance;
        uMedium.doApprove(prism, uMediumLockedAmt);
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
