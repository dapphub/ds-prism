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

    function doLock(uint128 amt) {
        prism.lock(amt);
    }

    function test_free(uint128 amt) {
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

        token.transfer(uLarge, 400 ether);
        token.transfer(uMedium, 350 ether);
        token.transfer(uSmall, 250 ether);
    }

    function test_basic_sanity() {
        assert(true);
    }

    function testFail_basic_sanity() {
        assert(false);
    }

    function test_etch_id() {
        var candidates = new address[](3);
        candidates[0] = c1;
        candidates[1] = c2;
        candidates[2] = c3;

        var id = uSmall.doEtch(candidates);
        assert(id != 0x0);
        assertEq32(id, uMedium.doEtch(candidates));
    }
}
