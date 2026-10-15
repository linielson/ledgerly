# 0012. Allocation takes positive integer ratios and mirrors negative amounts

- **Status:** Accepted
- **Date:** 2026-10-15
- **Ticket:** T-103 (#25)

## Context

[ADR-0002](0002-money-as-integer-minor-units.md) says splitting money uses allocation: the parts sum to the total, and
the remainder cents go to the first parts deterministically. Implementing `Money#allocate` raised three questions it
leaves open.

**Zero ratios.** With ratios `[0, 1, 1]`, R$ 1,01 floors to 0, 50 and 50, leaving 1 cent. "Remainder to the first
parts" gives that cent to the part whose ratio is zero, so a party that should get nothing gets money.

**Negative amounts.** Ruby's integer division rounds toward negative infinity: `-10000 / 3` is `-3334`, not `-3333`.
Allocating a negative amount directly gives `[-3333, -3333, -3334]`, which is a valid split but not the mirror of the
positive one, `[3334, 3333, 3333]`. A refund of an installment plan should line up with the charge, installment by
installment.

**Which remainder method.** "Remainder to the first parts" can leave a part a full cent above its exact share: 9 cents
by `[4, 1, 1]` gives `[7, 1, 1]`, against exact shares of 6, 1.5 and 1.5. The largest-remainder method (Hamilton)
would give the cent to the part with the largest fraction instead.

## Decision

- `allocate(n)` takes a positive Integer number of parts. `allocate(ratios)` takes a non-empty Array of positive
  Integers. Anything else raises `ArgumentError`, with the value received in the message. A party that gets nothing
  stays out of the list.
- A negative amount is allocated as its absolute value, and each part's sign is flipped, so the split mirrors the
  positive one.
- The remainder goes to the first parts, one cent each, as ADR-0002 states, even when a later part has a larger
  fraction. Every part stays within one cent of its exact share.
- Fractional percentages are out of scope here. They belong to the percentages and rounding policy (T-105).

## Consequences

- Splits are predictable: the same amount and ratios always give the same parts, and installment 1 carries the extra
  cent, both for a charge and for its refund.
- Callers with percentages such as 33.5% need to scale them to integers (`[335, 665]`) or wait for T-105.
- Property tests check the rules on random amounts and ratios with RSpec's seed: the sum, the number of parts, the
  currency, the one-cent bound and the order of the parts.
- Revisit if the remainder rule is ever perceived as unfair. Switching to largest remainder would change existing
  splits, so it needs a new ADR.
