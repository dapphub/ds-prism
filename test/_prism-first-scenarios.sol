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

// contract PrismUser {
//     ERC20Token gov;
//     Prism prism;
//     address public userwallet;

//     constructor(ERC20Token GOV_, Prism prism_) public {
//         gov = GOV_;
//         prism = prism_;
//         userwallet = msg.sender;
//     }

//     function doTransferFrom(address from, address to, uint amount)
//         public
//         returns (bool)
//     {
//         return gov.transferFrom(from, to, amount);
//     }

//     function doTransfer(address to, uint amount)
//         public
//         returns (bool)
//     {
//         return gov.transfer(to, amount);
//     }

//     function doApprove(ERC20Token token, Prism recipient, uint amount)
//         public
//         returns (bool)
//     {
//         return token.approve(address(recipient), amount);
//     }

//     function getWalletAddress()
//         public
//         view
//         returns (address)
//     {
//         return userwallet;
//     }

//     function doAllowance(address owner, address spender)
//         public
//         view
//         returns (uint)
//     {
//         return gov.allowance(owner, spender);
//     }

//     function doBalanceOf(address who)
//         public
//         view
//         returns (uint)
//     {
//         return gov.balanceOf(who);
//     }

//     function doSwap(uint i, uint j) public {
//         prism.swap(i, j);
//     }

//     function doDrop(uint i, address b) public {
//         prism.drop(i, b);
//     }

//     function doEtch(address[] memory guys) public returns (bytes32) {
//         return prism.etch(guys);
//     }

//     function doVote(address[] memory guys) public returns (bytes32) {
//         return prism.vote(guys);
//     }

//     // function doVote(address[] memory id) public {
//     //     prism.vote(id);
//     // }

//     function doLock(uint amt) public {
//         prism.lock(amt);
//     }

//     function doFree(uint amt) public {
//         prism.free(amt);
//     }
// }

contract DSPrismTest {
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
        //gov.mint(initialBalance);

        iou = new ERC20Token("IOU", "IOU");
        prism = new Prism(gov, iou, electionSize);
        //iou.setOwner(prism);

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

    function test_etch_returns_same_id_for_same_sets() public {
        address[] memory candidates = new address[](3);
        candidates[0] = c1;
        candidates[1] = c2;
        candidates[2] = c3;

        bytes32 id = uSmall.doEtch(candidates);
        assert(id != 0x0);
        // assertEq32(id, uMedium.doEtch(candidates));
    }

    function test_size_zero_slate() public {
        address[] memory candidates = new address[](0);
        bytes32 id = uSmall.doEtch(candidates);
        uSmall.doVote(candidates);
    }

    function test_size_one_slate() public {
        address[] memory candidates = new address[](1);
        candidates[0] = c1;
        bytes32 id = uSmall.doEtch(candidates);
        uSmall.doVote(candidates);
    }

    function testFail_etch_requires_ordered_sets() public {
        address[] memory candidates = new address[](3);
        candidates[0] = c2;
        candidates[1] = c1;
        candidates[2] = c3;

        uSmall.doEtch(candidates);
    }

    function test_lock_debits_user() public {
        assert(gov.balanceOf(uLarge.getWalletAddress()) == uLargeInitialBalance);

        uint lockedAmt = uLargeInitialBalance / 10;
        uLarge.doApprove(gov, prism, lockedAmt);
        uLarge.doLock(lockedAmt);

        assert(gov.balanceOf(uLarge.getWalletAddress()) == uLargeInitialBalance -
               lockedAmt);
    }

    function test_changing_weight_after_voting() public {
        uint uLargeLockedAmt = uLargeInitialBalance / 2;
        uLarge.doApprove(gov, prism, uLargeLockedAmt);
        uLarge.doApprove(iou, prism, uLargeLockedAmt);
        uLarge.doLock(uLargeLockedAmt);

        address[] memory uLargeSlate = new address[](1);
        uLargeSlate[0] = c1;
        //uLarge.doVote(uLargeSlate);

        assert(prism.approvals(c1) == uLargeLockedAmt);

        // Changing weight should update the weight of our candidate.
        uLarge.doFree(uLargeLockedAmt);
        assert(prism.votes(c1) == 0);

        uLargeLockedAmt = uLargeInitialBalance / 4;
        uLarge.doApprove(gov, prism, uLargeLockedAmt);
        uLarge.doLock(uLargeLockedAmt);

        assert(prism.approvals(c1) == uLargeLockedAmt);
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
