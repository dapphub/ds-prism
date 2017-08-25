/*
   Copyright 2017 DappHub, LLC

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
pragma solidity^0.4.15;

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
    mapping (address=>uint128)  public  approvals;
    mapping (address=>uint128)  public  deposits;
    mapping (bytes32=>address[])            slates;


    /**
    @notice Create a DSPrism instance.

    @param electionSize The number of candidates to elect.
    @param gov The address of the DSToken instance to use for governance.
    @param iou The address of the DSToken instance to use for IOUs.
    */
    function DSPrism(DSToken gov, DSToken iou, uint electionSize)
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
    function swap(uint i, uint j) {
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
    function drop(uint i, address b) {
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
    function etch(address[] guys) returns (bytes32) {
        requireByteOrderedSet(guys);
        var key = sha3(guys);
        slates[key] = guys;
        return key;
    }


    /**
    @notice Vote for candidates `guys`. This transaction will fail if the set of
    candidates is not ordered according the their numerical values or if it
    contains duplicates. Returns a unique ID for the set of candidates chosen.

    @param guys The ordered set of candidate addresses to vote for.
    */
    function vote(address[] guys) returns (bytes32) {
        var slate = etch(guys);
        vote(slate);

        return slate;
    }


    /**
    @notice Vote for the set of candidates with ID `which`.

    @param which An identifier returned by "etch" or "vote."
    */
    function vote(bytes32 which) {
        var weight = deposits[msg.sender];
        subWeight(weight, slates[votes[msg.sender]]);
        addWeight(weight, slates[which]);
        votes[msg.sender] = which;
    }

    /**
    @notice Elect the current set of finalists. The current set of finalists
    must be sorted or the transaction will fail.
    */
    function snap() {
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
        electedID = sha3(elected);
    }


    /**
    @notice Lock up `wad` wei voting tokens and increase your vote weight
    by the same amount.

    @param wad Number of tokens (in the token's smallest denomination) to lock.
    */
    function lock(uint128 wad) {
        GOV.pull(msg.sender, wad);
        IOU.mint(wad);
        IOU.push(msg.sender, wad);
        addWeight(wad, slates[votes[msg.sender]]);
        deposits[msg.sender] = wadd(deposits[msg.sender], wad);
    }


    /**
    @notice Retrieve `wad` wei of your locked voting tokens and decrease your
    vote weight by the same amount.

    @param wad Number of tokens (in the token's smallest denomination) to free.
    */
    function free(uint128 wad) {
        subWeight(wad, slates[votes[msg.sender]]);
        deposits[msg.sender] = wsub(deposits[msg.sender], wad);
        IOU.pull(msg.sender, wad);
        IOU.burn(wad);
        GOV.push(msg.sender, wad);
    }

    // Throws unless the array of addresses is a ordered set.
    function requireByteOrderedSet(address[] guys) internal {
        if( guys.length == 0 || guys.length == 1 ) {
            return;
        }
        for( uint i = 0; i < guys.length - 1; i++ ) {
            // strict inequality ensures both ordering and uniqueness
            require(uint256(bytes32(guys[i])) < uint256(bytes32(guys[i+1])));
        }
    }

    // Remove weight from slate.
    function subWeight(uint128 weight, address[] slate) internal {
        for( uint i = 0; i < slate.length; i++) {
            approvals[slate[i]] = wsub(approvals[slate[i]], weight);
        }
    }

    // Add weight to slate.
    function addWeight(uint128 weight, address[] slate) internal {
        for( uint i = 0; i < slate.length; i++) {
            approvals[slate[i]] = wadd(approvals[slate[i]], weight);
        }
    }
}
