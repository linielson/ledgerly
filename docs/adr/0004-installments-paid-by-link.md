# 0004. Installments are paid by link; automatic charging is deferred

- **Status:** Accepted
- **Date:** 2026-09-30
- **Ticket:** T-004; payments in Phase 2, automatic charging as a later optional epic

## Context

Installments can be paid in two ways:

- **A) A payment link per installment**: the customer pays each one when reminded. It reuses the single-payment flow.
- **B) Automatic charging of a saved card**: a scheduled job charges each installment on its due date. This is much
  richer for payments work, but it roughly doubles the payments module.

## Decision

The MVP implements **A**. **B** is deferred to a later epic, and the data model must accept it without a destructive
migration.

Failure scenarios B must handle, recorded so they aren't rediscovered:

- Off-session charges where the bank requires authentication (3DS) mid-recurrence.
- Expired or declined cards, with retry and customer notification.
- A scheduled job running twice and charging twice: an idempotency key per installment attempt, sent to the gateway,
  plus a row lock on the installment before charging.
- An installment paid manually while the automatic charge is running.

## Consequences

- Value ships earlier on a flow that is already needed.
- Collection depends on the customer acting, so late payment is more likely than with automatic charging.
- When B is picked up, the failure catalog above is the starting set of tests, driven by the fake gateway.
