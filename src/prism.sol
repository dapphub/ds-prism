/// prism.sol -- token based approval voting

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

pragma solidity^0.4.17;

import 'ds-token/token.sol';
import 'ds-thing/thing.sol';

contract DSPrism is DSThing {
    DSToken       public  GOV;
    DSToken       public  IOU;

    // top candidates in "lazy decreasing" order by vote
    address[]                   public  finalists;
    mapping (address => bool)   public  isFinalist;

    // elected set
    address[]                   public  elected;
    mapping (address=>bool)     public  isElected;

    uint256                     public  electedLength;
    bytes32                     public  electedID;
    uint256[]                   public  electedVotes;

    mapping (address=>bytes32)  public  votes;
    mapping (address=>uint256)  public  approvals;
    mapping (address=>uint256)  public  deposits;
    mapping (bytes32=>address[])        slates;


    /**
    @notice Create a DSPrism instance.

    @param electionSize The number of candidates to elect.
    @param gov The address of the DSToken instance to use for governance.
    @param iou The address of the DSToken instance to use for IOUs.
    */
    function DSPrism(DSToken gov, DSToken iou, uint electionSize) public
    {
        electedLength = electionSize;
        elected.length = electionSize;
        electedVotes.length = electionSize;
        finalists.length = electionSize;
        GOV = gov;
        IOU = iou;
    }

    /**
    @notice Swap candidates `i` and `j` in the vote-ordered list. This
    transaction will fail if `i` is greater than `j`, if candidate `i` has a
    higher score than candidate `j`, if the candidate one slot below the slot
    candidate `j` is moving to has more approvals than candidate `j`, or if
    candidate `j` has fewer than half the approvals of the most popular
    candidate.  This transaction will always succeed if candidate `j` has at
    least half the approvals of the most popular candidate and if candidate `i`
    either also has less than half the approvals of the most popular candidate
    or is `0x0`.

    @dev This function is meant to be called repeatedly until the list of
    candidates, `elected`, has been ordered in descending order by weighted
    approvals. The winning candidates will end up at the front of the list.

    @param i The index of the candidate in the `elected` list to move down.
    @param j The index of the candidate in the `elected` list to move up.
    */
    function swap(uint i, uint j) public {
        require(i < j && j < finalists.length);
        var a = finalists[i];
        var b = finalists[j];
        finalists[i] = b;
        finalists[j] = a;
        assert( approvals[a] < approvals[b]);
        assert( approvals[finalists[i+1]] < approvals[b] ||
                finalists[i+1] == 0x0 );
    }


    /**
    @notice Replace candidate at index `i` in the set of elected candidates with
    the candidate at address `b`. This transaction will fail if candidate `i`
    has more approvals than the candidate at the given address, or if the
    candidate is already a finalist.

    @param i The index of the candidate to replace.
    @param b The address of the candidate to insert.
    */
    function drop(uint i, address b) public {
        require(i < finalists.length);
        require(!isFinalist[b]);
        isFinalist[b] = true;

        var a = finalists[i];
        finalists[i] = b;
        isFinalist[a] = false;

        assert(approvals[a] < approvals[b]);
    }


    /**
    @notice Save an ordered addresses set and return a unique identifier for it.
    */
    function etch(address[] guys) public returns (bytes32) {
        requireByteOrderedSet(guys);
        var key = keccak256(guys);
        slates[key] = guys;
        return key;
    }


    /**
    @notice Vote for candidates `guys`. This transaction will fail if the set of
    candidates is not ordered according the their numerical values or if it
    contains duplicates. Returns a unique ID for the set of candidates chosen.

    @param guys The ordered set of candidate addresses to vote for.
    */
    function vote(address[] guys) public returns (bytes32) {
        var slate = etch(guys);
        vote(slate);

        return slate;
    }


    /**
    @notice Vote for the set of candidates with ID `which`.

    @param which An identifier returned by "etch" or "vote."
    */
    function vote(bytes32 which) public {
        var weight = deposits[msg.sender];
        subWeight(weight, slates[votes[msg.sender]]);
        addWeight(weight, slates[which]);
        votes[msg.sender] = which;
    }

    /**
    @notice Elect the current set of finalists. The current set of finalists
    must be sorted or the transaction will fail.
    */
    function snap() public {
        // Either finalists[0] has the most approvals, or there will be someone
        // in the list out-of-order with more than half of finalists[0]'s
        // approvals.
        uint requiredApprovals = approvals[finalists[0]] / 2;

        for( uint i = 0; i < finalists.length - 1; i++ ) {
            isElected[elected[i]] = false;

            // All finalists with at least `requiredVotes` approvals are sorted.
            require(approvals[finalists[i+1]] <= approvals[finalists[i]] ||
                    approvals[finalists[i+1]] < requiredApprovals);

            if (approvals[finalists[i]] >= requiredApprovals) {
                electedVotes[i] = approvals[finalists[i]];
                elected[i] = finalists[i];
                isElected[elected[i]] = true;
            } else {
                elected[i] = 0x0;
                electedVotes[i] = 0;
            }
        }
        electedID = keccak256(elected);
    }


    /**
    @notice Lock up `wad` wei voting tokens and increase your vote weight
    by the same amount.

    @param wad Number of tokens (in the token's smallest denomination) to lock.
    */
    function lock(uint wad) public {
        GOV.pull(msg.sender, wad);
        IOU.mint(wad);
        IOU.push(msg.sender, wad);
        addWeight(wad, slates[votes[msg.sender]]);
        deposits[msg.sender] = add(deposits[msg.sender], wad);
    }


    /**
    @notice Retrieve `wad` wei of your locked voting tokens and decrease your
    vote weight by the same amount.

    @param wad Number of tokens (in the token's smallest denomination) to free.
    */
    function free(uint wad) public {
        subWeight(wad, slates[votes[msg.sender]]);
        deposits[msg.sender] = sub(deposits[msg.sender], wad);
        IOU.pull(msg.sender, wad);
        IOU.burn(wad);
        GOV.push(msg.sender, wad);
    }

    // Throws unless the array of addresses is a ordered set.
    function requireByteOrderedSet(address[] guys) pure internal {
        if( guys.length == 0 || guys.length == 1 ) {
            return;
        }
        for( uint i = 0; i < guys.length - 1; i++ ) {
            // strict inequality ensures both ordering and uniqueness
            require(uint256(bytes32(guys[i])) < uint256(bytes32(guys[i+1])));
        }
    }

    // Remove weight from slate.
    function subWeight(uint weight, address[] slate) internal {
        for( uint i = 0; i < slate.length; i++) {
            approvals[slate[i]] = sub(approvals[slate[i]], weight);
        }
    }

    // Add weight to slate.
    function addWeight(uint weight, address[] slate) internal {
        for( uint i = 0; i < slate.length; i++) {
            approvals[slate[i]] = add(approvals[slate[i]], weight);
        }
    }
}
