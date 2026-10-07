# 0002. Money as integer minor units with an in-house value object

- **Status:** Accepted
- **Date:** 2026-09-30
- **Ticket:** T-004; implemented in E1 (T-101 to T-106)

## Context

Every amount in Ledgerly is money: invoice totals, installments, payments, refunds, fees and ledger entries. Floats
can't represent most decimal fractions exactly (`0.1 + 0.2 != 0.3`), and the error compounds across sums, splits and
refunds. Payment gateways also work in minor units (cents), so any other representation needs conversion at the edges.

Options considered:

- **`money-rails`**: mature, already uses integer cents, and it's what a production team would usually pick.
- **An in-house value object**: more code to write, but full control over allocation and rounding semantics, which
  installments, late fees and the ledger depend on.

## Decision

- Amounts are **integer minor units plus an ISO 4217 currency code**. No `Float` anywhere money is involved, including
  display.
- A **`Currency`** value object holds the code, the exponent (number of minor-unit digits) and the symbol. The exponent
  belongs to the currency: JPY has 0, BRL and USD have 2, BHD has 3.
- A **`Money`** value object is immutable, compares by value, works as a hash key, and **raises on currency mismatch**,
  including in comparisons.
- **Splitting uses allocation**: the parts always sum to the original total, with remainder cents going to the first
  parts deterministically (R$ 100,00 in three parts is 33,34 + 33,33 + 33,33).
- **Formatting uses integer arithmetic only** (division and remainder by 10 to the exponent).
- **Percentages use `BigDecimal` or `Rational`** with one explicit rounding mode. A `Float` multiplier raises.
- **Invalid input raises**; nothing fails silently.
- Persisted as `amount_cents bigint NOT NULL` plus a currency column with a format check constraint.

Two details are decided by the tickets that implement them, and recorded here when they are:

- the rounding mode, half-up or half-even (T-105);
- `composed_of` or a small macro of our own to map the two columns (T-106).

## Consequences

- Money bugs become type errors or exceptions instead of silently wrong amounts.
- Allocation and rounding are tested as properties (the sum of the parts equals the total) rather than by example only.
- About 150 to 200 lines to own and test that a gem would provide. In a team product, `money-rails` would be the
  default choice; this project implements it to control the semantics and to show the design.
- Multi-currency is out of scope (one currency per tenant), but the type already prevents mixing currencies.
