import 'ds-heap/heap.sol';

contract DSPrism {
    // Slates are "memory managed" by their owner. If you need to do this automatically, wrap this
    // with something that uses an ordered set.
    struct Slate {
        uint      num;
        address[] guys;
    }
    struct Voter {
        uint weight;
        uint slate;
    }

    struct Candidate {
        address who;
    }
    ERC20 _token;
    mapping(address=>Voter) _voters;
    mapping(address=>uint) _votes;
    mapping(uint256=>Slate) _slates;

    function isElected(address who) returns (bool);
    function newSlate(address[] guys) returns (uint256);
    function setSlate(uint256 which) {
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
