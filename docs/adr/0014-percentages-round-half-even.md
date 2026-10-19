# 0014. Percentages multiply Money by exact numbers and round half to even

- **Status:** Accepted
- **Date:** 2026-10-19
- **Ticket:** T-105 (#27)

## Context

Late fees, interest, discounts and gateway fees are percentages of an amount, and the result rarely lands on a whole
cent: 2% of R$ 100,01 is R$ 2,0002. [ADR-0002](0002-money-as-integer-minor-units.md) requires `BigDecimal` or
`Rational` with one explicit rounding mode, and leaves the mode to this ticket.

The mode only matters when a result is exactly halfway between two cents, such as 12.5 cents:

| Mode      | 12.5 | 13.5 | −12.5 | Over many operations                           |
| --------- | ---- | ---- | ----- | ---------------------------------------------- |
| Half up   | 13   | 14   | −13   | Ties always move away from zero, so sums drift |
| Half even | 12   | 14   | −12   | Ties go to the even neighbour and cancel out   |

Ruby rounds half up by default in `Integer#round`, `Rational#round` and `BigDecimal#round`, so whichever mode is
chosen has to be stated in the code.

## Decision

- `Money#*` takes an `Integer`, a `BigDecimal` or a `Rational`, the exact numeric types. A `Float` raises
  `ArgumentError`, with a hint to build a `BigDecimal` from a String. So does anything else, including another
  `Money`.
- The exact product of the cents and the multiplier is rounded to a whole minor unit with **half even**. Integer
  multipliers need no rounding.
- Each multiplication rounds once. Callers combine rates before multiplying: interest of 0,033% a day over 17 days is
  `amount * (daily_rate * 17)`, not seventeen rounded steps. On R$ 100,01 the two give R$ 0,56 and R$ 0,51.
- Only `money * rate` is supported. `rate * money` would need Ruby's `coerce` protocol, and there is no `percent`
  helper: callers pass `BigDecimal("0.02")` or `Rational(2, 100)`.

## Consequences

- Sums of many fees and interest charges, which the ledger adds up, carry no rounding bias. Half even is also the rule
  of the Brazilian rounding standard (ABNT NBR 5891).
- A customer checking a single tie by hand may expect half up (12.5 → 13). That surprise only happens on exact ties
  and is explained by this ADR.
- Specs cover ties, non-ties, negative amounts, both exact types, a currency without decimals and an amount beyond Float
  precision. A half-up, truncating or Float-based implementation each turns at least one spec red.
- Compound interest, interest tables and percentages stored per tenant belong to E4. Revisit the mode only with a new
  ADR, because changing it changes existing amounts.
