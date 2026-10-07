# 0007. CRUD monolith plus an append-only ledger instead of event sourcing

- **Status:** Accepted
- **Date:** 2026-09-30
- **Ticket:** T-004

## Context

Event sourcing gives an immutable history and derived state, which is valuable for money. It also brings projections,
read models, sagas and eventual consistency, which pay off when many consumers need the same facts or full replay is a
requirement. Ledgerly is a single Rails monolith with one database.

## Decision

Use a **CRUD monolith** for operational data (tenants, customers, invoices, installments) and an **append-only ledger**
(ADR-0005) for everything that is money. No full event sourcing.

Inside the monolith, projections become queries, sagas become a database transaction plus a job, and consistency is
transactional. What event sourcing would have given for free is kept explicitly:

- **Idempotency at the edges**: gateway calls, inbound webhooks and jobs.
- **An audit trail** of who did what and when (member, AI assistant or gateway), per invoice (E6).
- **Correct balances under concurrency**: locks and constraints, not application checks alone.

## Consequences

- Far less infrastructure and fewer moving parts, with the property that matters for money (an immutable, derived
  ledger) preserved.
- No full replay of the domain: past states of operational data are only as complete as the audit trail.
- The decision changes if several services need to consume the same facts or a full replay becomes a requirement.
