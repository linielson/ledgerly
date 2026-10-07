# 0006. Daily consolidation, posting date vs. occurrence date

- **Status:** Accepted
- **Date:** 2026-09-30
- **Ticket:** T-004; implemented in E5

## Context

A cash book must be closed: once a period is consolidated, its balances can't change, or yesterday's report stops
matching today's. Gateways settle daily, so a daily close lines up with reconciliation. A monthly view for the business
is just the sum of closed days.

Events don't respect the close, though: the webhook for a payment at 23:58 can arrive at 00:03, and a chargeback for
yesterday's payment arrives tomorrow.

## Decision

- A **Solid Queue job closes day D-1** early in the morning: it computes each account's closing balance, stores a
  snapshot (`ledger_period_balances`) and marks the period (`ledger_periods`) closed.
- "Day" means the day **in the tenant's timezone**. The default is **`America/Sao_Paulo`**; the evolution is a per-tenant
  timezone setting. In UTC, a São Paulo day would end at 21:00.
- Every entry has **`occurred_at`** (when it happened, per the gateway) and **`posted_at`** (when it was recorded).
- A **closed period rejects new postings**. A late event is posted to the open day and keeps its original
  `occurred_at`.
- The current balance is the last closed snapshot plus the entries posted since then; the full history is never summed.

## Consequences

- Closed days never change, and no information is lost.
- Reports must say which date they use: posting date for the books, occurrence date for business analysis.
- The close job becomes a health signal: a day that wasn't closed means the job failed (see T-601).
