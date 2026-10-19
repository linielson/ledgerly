# 0011. Money equality returns false across currencies, and Money takes a Currency object

- **Status:** Accepted
- **Date:** 2026-10-15
- **Ticket:** T-102 (#24)

## Context

[ADR-0002](0002-money-as-integer-minor-units.md) says `Money` "raises on currency mismatch, including in comparisons".
Building it raised two questions that ADR leaves open.

**Equality vs. ordering.** Ruby's `Comparable` gives `<`, `<=`, `>`, `>=`, `between?` and `clamp` from one `<=>`, and
also replaces `==` with one built on `<=>`. If `<=>` raises on a currency mismatch, so does `==`. But `==` is called
by code that only asks "is this the same value?": `Array#include?`, `uniq`, `delete`, and test matchers. A mixed list
of amounts would blow up there instead of answering "no".

**What the currency is.** `Money.new(1000, "BRL")` reads well, but then `Money` has to look codes up, and equality and
the mismatch check depend on comparing strings (case, whitespace, symbols vs. strings). A lookalike object with the
same fields could also carry a wrong exponent.

## Decision

- `==` and `eql?` compare by value and return `false` for different currencies. They never raise. `hash` is consistent
  with `eql?`, so `Money` works as a hash key.
- `<=>` raises `Money::CurrencyMismatchError` for different currencies, and so do the `Comparable` operators, `+` and
  `-`. "Which is larger, R$ 10 or US$ 10?" has no answer, so asking it is a bug.
- `<=>` returns `nil` for something that is not a `Money`, as Ruby's protocol expects; `Comparable` then raises its
  own `ArgumentError`.
- `Money` takes a `Currency` object, never a code: anything else raises `ArgumentError`. Code that has only a code
  (form params, a database column) calls `Currency.fetch` at that boundary. The ActiveRecord mapping in T-106 is one
  such boundary.

The "including in comparisons" in ADR-0002 means ordering comparisons, as stated here.

## Consequences

- Mixed-currency collections can be searched and deduplicated safely. Ordering or summing them fails loudly.
- `Money` redefines `==` after including `Comparable`. One spec in `#==` guards it; removing that method would break no
  other test.
- Callers write `Money.new(1000, Currency.fetch("BRL"))`, which is longer. Factory helpers or the T-106 mapping can
  shorten it where it repeats.
- Revisit if the app ever converts between currencies: conversion would get its own method with an explicit rate, not
  a looser `==`.
