# ds-prism

Approval voting to select a set of addresses.

## Approval Voting System

**Approval voting** is when each voter selects which candidates they approve of,
with the top `n` "most approved" candidates being elected. Each voter can cast
up to `n + k` votes, where `k` is some non-zero positive integer. This allows
voters to move their approval from one candidate to another without needing to
first withdraw support from the candidate being replaced. Without this, moving
approval to a new candidate could result in a less-approved candidate moving
momentarily into the set of elected candidates.

It is important to note that election in `ds-prism` is a continuous process.
There is no discrete "election" event, and the "polls" never close. Candidates
simply move into and out of the "elected" set.

It's also important to note that a voter's weight is proportional to the
quantity they have locked of a `DSToken` instance's tokens. The `DSToken`
instance must be specified at the time of `DSPrism` deployment and cannot be
changed afterward.

This system is used in Maker DAO to elect oracles.

**Example:**

Given that:

- `n = 3` and `k = 1`
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

Which results in A, D, and B becoming active oracles.


## API

### DSPrism(DSToken token, uint electionSize)

The constructor. Takes the address of the voting token contract and the number
of candidates to elect.


### swap(uint i, uint j) {

Swaps candidates `i` and `j` in the vote-ordered list. The transaction will fail
if `i` is greater than `j`, if candidate `i` has a higher score than candidate
`j`, or if the candidate one slot below the slot candidate `j` is moving to has
more votes than candidate `j`.

This function is meant to be called repeatedly until the list of candidates,
`elected`, has been ordered in descending order by weighted votes. The winning
candidates will end up at the front of the list.


### drop(uint i, address b)

Replace candidate at index `i` in the set of elected candidates with the
candidate at address `b`. This transaction will fail if candidate `i` has more
votes than the candidate at the given address.


### isOrderedSet(address[] guys) internal returns (bool)

Returns true if the array of addresses is a ordered set.


### etch(address[] guys) returns (bytes32)

Save a ordered addresses set and return a unique identifier for it.


### vote(address[] guys) returns (bytes32)

Approve candidates `guys`. This transaction will fail if the set of candidates
is not ordered according the their numerical values or if it contains
duplicates. Returns a unique ID for the set of candidates chosen.


### vote(bytes32 which)

Approve the set of candidates with ID `which`, where `which` is a `bytes32`
value returned by `vote(address[] guys)` or `etch(address[] guys)`.


### lock(uint128 amt)

Lock up `amt` wei voting tokens and increase your vote weight by the same amount.


### free(uint128 amt)

Retrieve `amt` wei of your locked voting tokens and decrease your vote weight by
the same amount.
