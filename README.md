# ds-prism


## Summary

This contract provides a way to elect a set of addresses via approval voting.


## Approval Voting System

**Approval voting** is when each voter selects which candidates they approve of,
with the top `n` "most approved" candidates being elected. Each voter can cast
up to `n + k` votes, where `k` is some non-zero positive integer. This allows
voters to move their approval from one candidate to another without needing to
first withdraw support from the candidate being replaced. Without this, moving
approval to a new candidate could result in a less-approved candidate moving
momentarily into the set of elected candidates.

In addition, `ds-prism`...
- ...weights votes according to the quantity of a voting token they've chosen to
  lock up in the `DSPrism` contract.
- ...issues IOU tokens representing locked funds, which can be redeemed for
  locked funds only by those who have funds locked, and only up to the amount
  they have locked.
- ...requires each elected candidate to have at least half the votes of the most
  popular candidate. This prevents unqualified candidates from being elected in
  the event there are not enough qualified candidates to fill the elected set.

It's important to note that the voting token used in a `DSPrism` deployment
must be specified at the time of deployment and cannot be changed afterward.

It's also important to note that `ds-prism` generally takes a "batteries not
included" approach. Sorting is expected to mostly be done off-chain, and
candidates are expected to watch this contract and call the `swap`, `drop`, and
`snap` functions as they gain votes in order to keep the elected set up to date.
If a candidate is voted in but nobody bothers to call these functions to update
the elected set, then the elected set will not change. As `ds-prism` was written
specifically for electing oracles in Maker DAO, this may be considered a feature
rather than a shortcoming: candidates that are too inattentive to realize their
own election don't belong in the elected set anyway. This feature may or may not
also be helpful in your own projects.


## Why an IOU Token?

The IOU token allows for chaining governance contracts. An arbitrary number of
`DSChief`, `DSPrism`, or other contracts of that kind may essentially use the
same governance token by accepting the IOU token of the `DSPrism` contract
before it as a governance token. E.g., given three `DSPrism` contracts,
`prismA`, `prismB`, and `prismC`, with `prismA.GOV` being the `MKR` token,
setting `prismB.GOV` to `prismA.IOU` and `prismC.GOV` to `prismB.IOU` allows all
three contracts to essentially run using a common pool of `MKR`.


### Example

Given that:

- `n = 5` and `k = 1`
- Alice, Bob, and Cat are voters.
- A, B, C, D, E, F, and G are candidates.

If:

- Alice has 30 MKR and approves A, D, F, G.
- Bob has 35 MKR and approves A, B, D.
- Cat has 20 MKR and approves A, B, E, G.

Then the candidate scores are calculated according to the table below:

|   | Alice | Bob | Cat |    |
|:-:|:-----:|:---:|:---:|----|
| A |   *   |  *  |  *  | 85 |
| B |       |  *  |  *  | 55 |
| C |       |     |     | 00 |
| D |   *   |  *  |     | 65 |
| E |       |     |  *  | 20 |
| F |   *   |     |     | 30 |
| G |   *   |     |  *  | 50 |

And the ranking of candidates is:

```
A > D > B > G > F > E > C
```

Which results in A, B, D, and G becoming active oracles, with C, E, and F
failing due to having fewer than half the votes of A and, in the cases of C and
E, not having enough space left in the elected set anyway.


## API

Below we refer to the internal, not-necessarily-sorted list of top candidates as
"finalists." The "elected" set is always a snapshot of the finalists after
verifying that they've been sorted and without any finalists with fewer than
half the votes of the most popular finalist.

### DSPrism(DSToken token, uint electionSize)

The constructor. Takes the address of the voting token contract and the number
of candidates to elect.


### electedLength() returns (uint)

Returns the length of the `elected` and `finalists` sets.


### elected(uint i) returns (address)

Returns the address of the elected candidate at index `i`.


### electedID() returns (bytes32)

Returns a SHA3 hash of the current elected set.


### isElected(address guy) returns (bool)

Returns a boolean indicating whether the given address is in the set of elected
candidates.


### finalists(uint i) returns (address)

Returns the address of the finalist at index `i`.


### isFinalist(address guy) returns (bool)

Returns a boolean indicating whether the given address is in the set of elected
finalists.


### swap(uint i, uint j)

Swaps candidates `i` and `j` in the vote-ordered "finalists" set. The
transaction will fail if `i` is greater than `j`, if candidate `i` has a higher
score than candidate `j`, or if the candidate one slot below the slot candidate
`j` is moving to has more votes than candidate `j`.

This function is meant to be called repeatedly until the list of finalists has
been ordered in descending order by weighted votes. The winning finalists will
end up at the beginning of the list.


### drop(uint i, address b)

Replace candidate at index `i` in the set of finalists with the candidate at
address `b`. This transaction will fail if candidate `i` has more votes than the
candidate at the given address, or if the candidate is already a finalist.


### snap()

Elect the current set of finalists. The current set of finalists must be sorted
or the transaction will fail.


### etch(address[] guys) returns (bytes32)

Save a ordered addresses set and return a unique identifier for it.


### vote(address[] guys) returns (bytes32)

Vote for candidates `guys`. This transaction will fail if the set of candidates
is not ordered according the their numerical values (e.g., `[0x1, 0x2, 0x3...]`)
or if it contains duplicates. Returns a unique ID for the set of candidates
chosen.


### vote(bytes32 which)

Vote for the set of candidates with ID `which`, where `which` is a `bytes32`
value returned by `vote(address[] guys)` or `etch(address[] guys)`.


### votes(address guy) returns (uint)

Returns the number of votes currently allocated to the given address.


### lock(uint128 amt)

Lock up `amt` wei voting tokens and increase your vote weight by the same amount.


### free(uint128 amt)

Retrieve `amt` wei of your locked voting tokens and decrease your vote weight by
the same amount.
