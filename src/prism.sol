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

import 'erc20/erc20.sol';
import 'ds-thing/thing.sol';

contract DSPrism is DSThing {
    // top candidates in "lazy decreasing" order by vote
    address[] elected;

    // asserts swapped values are in order, and the greater
    // value is also greater than its direct neighbor
    function swap(uint i, uint j) {
        assert( i < j && j < elected.length);
        var a = elected[i];
        var b = elected[j];
        elected[i] = b;
        elected[j] = a;
        assert( _votes[a] < _votes[b] );
        assert( _votes[elected[i+1]] < _votes[b] );
    }
    // alternative to `swap` when `j` is not in the elected set at all
    function drop(uint i, address b) {
        assert( i < elected.length);
        var a = elected[i];
        elected[i] = b;
        assert( _votes[a] < _votes[b] );
    }

    struct Slate {
        address[] guys; // Ordered set of candidates. Length is part of list encoding.
    }
    mapping(bytes32=>Slate) _slates;
    struct Voter {
        uint    weight;
        bytes32 slate; // pointer to slate for reusability
    }

    ERC20 _token;
    mapping(address=>Voter) _voters;
    mapping(address=>uint) _votes;

    function isOrderedSet(address[] guys) internal returns (bool) {
        for( var i = 0; i < guys.length - 1; i++ ) {
            // strict inequality ensures both ordering and uniqueness
            assert(uint256(bytes32(guys[i])) < uint256(bytes32(guys[i+1])));
        }
    }

    function etch(address[] guys) returns (bytes32) {
        assert( isOrderedSet(guys) );
        var key = sha3(guys);
        _slates[key] = Slate({ guys: guys });
    }
    function vote(address[] guys) returns (bytes32) {
        var slate = etch(guys);
        vote(slate);
        return slate;
    }
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
    function lock(uint128 amt) {
        assert( _token.transferFrom(msg.sender, this, amt) );
        _voters[msg.sender].weight += amt;
        vote(_voters[msg.sender].slate);
    }
    function free(uint128 amt) {
        _voters[msg.sender].weight -= amt;
        vote(_voters[msg.sender].slate);
        assert( _token.transferFrom(msg.sender, this, amt) );
    }
}
