# ds-prism
approval voting to select a set of addresses

Approval voting system
---

Any ethereum address can be a `voter`. Each voter's weight is proportional to MKR held. **Approval voting** is when every candidate is "approved" independently. The top N candidates are elected into the set of active oracles. Each voter can cast up to N+k votes; this extra buffer gives some breathing room for transitioning oracle sets safely, at the cost of slightly lowering the total attack cost.

```
N=3
k=1

ali: 30 MKR
    approves A, D, F, G
bob: 35 MKR
    approves A, B, D
cat: 20 MKR
    approves A, B, E, G

  ali bob cat
A *   *    *   = 85
B     *    *   = 55
C              = 00
D *   *        = 65
E          *   = 20
F *            = 30
G *        *   = 50

A > D > B > G > F > E > C

A, D, B are active oracles
```

### "at least half votes" rule
???


