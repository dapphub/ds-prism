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
        address[] guys; // Ordered set of candidates. Length is part of list encoding.
    }

    struct Voter {
        uint    weight;
        bytes32 slate; // pointer to slate for reusability
    }

    // top candidates in "lazy decreasing" order by vote
    address[] elected;
    DSToken _token;
    mapping(address=>Voter) _voters;
    mapping(address=>uint) _votes;
    mapping(bytes32=>Slate) _slates;


    /**
    @notice Create a DSPrism instance.

    @param electionSize The number of candidates to elect.
    @param token The address of a DSToken instance.
    */
    function DSPrism(DSToken token, uint electionSize) DSThing()
    {
        elected.length = electionSize;
        _token = token;
    }


    /**
    @notice Swap candidates `i` and `j` in the vote-ordered list. This
    transaction will fail if `i` is greater than `j`, if candidate `i` has a
    higher score than candidate `j`, or if the candidate one slot below
    the slot candidate `j` is moving to has more votes than candidate `j`.

    @dev This function is meant to be called repeatedly until the list of
    candidates, `elected`, has been ordered in descending order by weighted
    votes. The winning candidates will end up at the front of the list.

    @param i The index of the candidate in the `elected` list to move up.
    @param j The index of the candidate in the `elected` list to move down.
    */
    function swap(uint i, uint j) {
        assert( i < j && j < elected.length);
        var a = elected[i];
        var b = elected[j];
        elected[i] = b;
        elected[j] = a;
        assert( _votes[a] < _votes[b] );
        assert( _votes[elected[i+1]] < _votes[b] );
    }


    /**
    @notice Replace candidate at index `i` in the set of elected candidates with
    the candidate at address `b`. This transaction will fail if candidate `i`
    has more votes than the candidate at the given address.


    @param i The index of the candidate to replace.
    @param b The address of the candidate to insert.
    */
    function drop(uint i, address b) {
        assert( i < elected.length);
        var a = elected[i];
        elected[i] = b;
        assert( _votes[a] < _votes[b] );
    }


    /**
    @notice Save a ordered addresses set and return a unique identifier for it.
    */
    function etch(address[] guys) returns (bytes32) {
        assert( isOrderedSet(guys) );
        var key = sha3(guys);
        _slates[key] = Slate({ guys: guys });
    }


    /**
    @notice Approve candidates `guys`. This transaction will fail if the set of
    candidates is not ordered according the their numerical values or if it
    contains duplicates. Returns a unique ID for the set of candidates chosen.

    @param guys The ordered set of candidate addresses to approve.
    */
    function vote(address[] guys) returns (bytes32) {
        var slate = etch(guys);
        vote(slate);
        return slate;
    }


    /**
    @notice Approve the set of candidates with ID `which`.

    @param which An identifier returned by "etch" or "vote."
    */
    function vote(bytes32 which) {
        var voter = _voters[msg.sender];
        var slate = _slates[voter.slate];
        for(var i = 0; i < slate.guys.length; i++) {
            _votes[slate.guys[i]] -= voter.weight;
        }
        voter.slate = which;
        slate = _slates[which];
        for(i = 0; i < slate.guys.length; i++) {
            _votes[slate.guys[i]] += voter.weight;
        }
    }


    /**
    @notice Lock up `amt` wei voting tokens and increase your vote weight
    by the same amount.

    @param amt Number of tokens (in the token's smallest denomination) to lock.
    */
    function lock(uint128 amt) {
        _token.pull(msg.sender, amt);
        _voters[msg.sender].weight += amt;
        vote(_voters[msg.sender].slate);
    }


    /**
    @notice Retrieve `amt` wei of your locked voting tokens and decrease your
    vote weight by the same amount.

    @param amt Number of tokens (in the token's smallest denomination) to free.
    */
    function free(uint128 amt) {
        _voters[msg.sender].weight -= amt;
        vote(_voters[msg.sender].slate);
        _token.push(msg.sender, amt);
    }


    // Returns true if the array of addresses is a ordered set.
    function isOrderedSet(address[] guys) internal returns (bool) {
        for( var i = 0; i < guys.length - 1; i++ ) {
            // strict inequality ensures both ordering and uniqueness
            assert(uint256(bytes32(guys[i])) < uint256(bytes32(guys[i+1])));
        }
    }
}
