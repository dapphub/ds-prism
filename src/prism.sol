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

import 'ds-token/token.sol';
import 'ds-thing/thing.sol';

contract DSPrism is DSThing {
    struct Slate {
        address[] guys; // Ordered set of candidates
    }

    struct Voter {
        uint256 weight;
        bytes32 slate;  // pointer to slate for reusability
    }

    DSToken       public  token;

    // top candidates in "lazy decreasing" order by vote
    address[]     public  finalists;
    bool[256**24] public  isFinalist; // for address uniqueness checking

    // "elected" properties
    uint256       public  electedLength;
    bytes32       public  electedID;
    address[]     public  elected;
    uint[]        public  electedVotes;
    bool[256**24] public  isElected;    // cheap membership checks

    mapping(address=>Voter) public  voters;
    mapping(address=>uint)  public  votes;
    mapping(bytes32=>Slate)         slates;


    /**
    @notice Create a DSPrism instance.

    @param electionSize The number of candidates to elect.
    @param token_ The address of a DSToken instance.
    */
    function DSPrism(DSToken token_, uint electionSize) DSThing()
    {
        electedLength = electionSize;
        elected.length = electionSize;
        electedVotes.length = electionSize;
        finalists.length = electionSize;
        token = token_;
    }


    /**
    @notice Takes an address and returns true if the address has been elected.
    */
    function isElected(address guy) returns (bool) {
        return isElected[uint(guy)];
    }


    /**
    @notice Swap candidates `i` and `j` in the vote-ordered list. This
    transaction will fail if `i` is greater than `j`, if candidate `i` has a
    higher score than candidate `j`, if the candidate one slot below the slot
    candidate `j` is moving to has more votes than candidate `j`, or if
    candidate `j` has fewer than half the votes of the most popular candidate.
    This transaction will always succeed if candidate `j` has at least half the
    votes of the most popular candidate and if candidate `i` either also has
    less than half the votes of the most popular candidate or is `0x0`.

    @dev This function is meant to be called repeatedly until the list of
    candidates, `elected`, has been ordered in descending order by weighted
    votes. The winning candidates will end up at the front of the list.

    @param i The index of the candidate in the `elected` list to move down.
    @param j The index of the candidate in the `elected` list to move up.
    */
    function swap(uint i, uint j) {
        require(i < j && j < finalists.length);
        var a = finalists[i];
        var b = finalists[j];
        finalists[i] = b;
        finalists[j] = a;
        assert( votes[a] < votes[b]);
        assert( votes[finalists[i+1]] < votes[b] || finalists[i+1] == 0x0 );
    }


    /**
    @notice Replace candidate at index `i` in the set of elected candidates with
    the candidate at address `b`. This transaction will fail if candidate `i`
    has more votes than the candidate at the given address, or if the candidate
    is already a finalist.

    @param i The index of the candidate to replace.
    @param b The address of the candidate to insert.
    */
    function drop(uint i, address b) {
        require(i < finalists.length);
        require(!isFinalist[uint(b)]);
        isFinalist[uint(b)] = true;

        var a = finalists[i];
        finalists[i] = b;
        isFinalist[uint(a)] = false;

        assert(votes[a] < votes[b]);
    }


    /**
    @notice Save an ordered addresses set and return a unique identifier for it.
    */
    function etch(address[] guys) returns (bytes32) {
        requireByteOrderedSet(guys);
        var key = sha3(guys);
        slates[key] = Slate({ guys: guys });

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
        var voter = voters[msg.sender];
        subWeight(voter.weight, slates[voter.slate]);

        voter.slate = which;
        addWeight(voter.weight, slates[voter.slate]);
    }


    /**
    @notice Returns the number of tokens allocated to voting for `guy`.

    @param guy The address of the candidate whose votes we want to lookup.
    */
    function votes(address guy) constant returns (uint) {
        return votes[guy];
    }


    /**
    @notice Elect the current set of finalists. The current set of finalists
    must be sorted or the transaction will fail.
    */
    function snap() {
        // Either finalists[0] has the most votes, or there will be someone in
        // the list out-of-order with more than half of finalists[0]'s votes.
        uint requiredVotes = votes[finalists[0]] / 2;

        for( uint i = 0; i < finalists.length - 1; i++ ) {
            isElected[uint(elected[i])] = false;

            // All finalists with at least `requiredVotes` votes are sorted.
            require(votes[finalists[i+1]] <= votes[finalists[i]] ||
                    votes[finalists[i+1]] < requiredVotes);

            if (votes[finalists[i]] >= requiredVotes) {
                electedVotes[i] = votes[finalists[i]];
                elected[i] = finalists[i];
                isElected[uint(elected[i])] = true;
            } else {
                elected[i] = 0x0;
                electedVotes[i] = 0;
            }
        }
        electedID = sha3(elected);
    }


    /**
    @notice Lock up `amt` wei voting tokens and increase your vote weight
    by the same amount.

    @param amt Number of tokens (in the token's smallest denomination) to lock.
    */
    function lock(uint128 amt) {
        var voter = voters[msg.sender];
        addWeight(amt, slates[voter.slate]);

        voters[msg.sender].weight += amt;

        token.transferFrom(msg.sender, this, amt);
    }


    /**
    @notice Retrieve `amt` wei of your locked voting tokens and decrease your
    vote weight by the same amount.

    @param amt Number of tokens (in the token's smallest denomination) to free.
    */
    function free(uint128 amt) {
        var voter = voters[msg.sender];
        subWeight(amt, slates[voter.slate]);

        voter.weight -= amt;

        token.transfer(msg.sender, amt);
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
    function subWeight(uint weight, Slate slate) internal {
        for( uint i = 0; i < slate.guys.length; i++) {
            votes[slate.guys[i]] -= weight;
        }
    }

    // Add weight to slate.
    function addWeight(uint weight, Slate slate) internal {
        for( uint i = 0; i < slate.guys.length; i++) {
            votes[slate.guys[i]] += weight;
        }
    }
}
