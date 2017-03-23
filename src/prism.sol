/*
   Copyright 2017 Nexus Development, LLC

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


contract DSPrism {
    // top candidates in "lazy decreasing" order
    address[] elected;
    function distinctElected() returns (address[]);
    function swap(uint i, uint j) {
        assert( i < j );
        var a = elected[i];
        var b = elected[j];
        assert( a < b );
        elected[i] = b;
        elected[j] = a;
    }

    struct Slate {
        address[] guys; // Ordered list of candidates. Length is part of list encoding.
    }
    mapping(bytes32=>Slate) _slates;
    struct Voter {
        uint    weight;
        bytes32 slate;
    }

    ERC20 _token;
    mapping(address=>Voter) _voters;
    mapping(address=>uint) _votes;

    function addSlate(address[] guys) returns (bytes32) {
        assert( inOrder(guys) );
        var key = sha3(guys);
        _slates[key] = Slate({ guys: guys });
    }
    function setSlate(bytes32 which) {
        var voter = _voters[msg.sender];
        var slate = _slates[voter.slate];
        for(guy in slate.guys) {
            _votes[guy] -= voter.weight;
        }
        voter.slate = which;
        slate = _slates[which];
        for(guy in slate.guys) {
            _votes[guy] += voter.weight;
        }
    }
    function deposit() {
        adjust votes
        ...
    }
    function withdraw() {
        adjust votes
        ...
    }
}
