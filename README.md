# ds-prism

Approval voting to select a set of addresses.

## Approval Voting System

**Approval voting** is when each voter selects which candidates they approve of,
with the top `n` "most approved" candidates winning the election. Each voter can
cast up to `n + k` votes. In `ds-prism`, a voter's weight is proportional to the
quantity they hold of a `DSToken` instance specified at the time of `DSPrism`
deployment.

This system is used in Maker DAO to elect oracles. The top `n` candidates are
elected into the set of active oracles.

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


### "at least half votes" rule
???


