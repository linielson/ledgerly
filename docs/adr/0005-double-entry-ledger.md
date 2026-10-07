# 0005. Double-entry ledger with five accounts

- **Status:** Accepted
- **Date:** 2026-09-30
- **Ticket:** T-004; implemented in E5

## Context

Ledgerly must be able to say, at any time, how much customers owe, how much the gateway holds, and what was refunded,
and those numbers must reconcile with the gateway. A mutable `balance` column can drift and can't explain itself.
Single-entry records (a list of ins and outs) show a net amount but not where the money is, and they hide errors: a
duplicated webhook simply shows up as more money.

Double-entry bookkeeping is the standard for financial systems (Stripe's Ledger, Modern Treasury, TigerBeetle): every
movement records both where the value came from and where it went.

## Decision

- Each **ledger transaction** has two or more **entries** with **signed integer cents that sum to zero**. Debits and
  credits are represented as signs.
- The MVP has five **accounts**: Revenue, Accounts receivable, Gateway cash (a clearing account), Fees, and Refunds.
- Entries are **append-only**: no `UPDATE` or `DELETE`, enforced by a **database trigger**, not only by the model.
  Corrections are reversing entries.
- Balances are **derived from entries**, never stored as a mutable value.

Simplifications accepted for the MVP: global accounts instead of sub-accounts per customer (the invoice and
installment on each entry give that view by query); no pending entries (holds) before settlement; balances computed by
`SUM`, with the daily snapshot of ADR-0006 keeping that cheap.

## Consequences

- The ledger checks itself: the sum of all entries is zero, so a bug shows up as a broken invariant, not as silently
  wrong money.
- Business questions become account balances, and reconciliation becomes comparing Gateway cash with the gateway's
  report.
- Each event writes at least two rows, and the vocabulary takes some learning.
- Sub-accounts, holds and cached balances are natural extensions if volume or features require them.
