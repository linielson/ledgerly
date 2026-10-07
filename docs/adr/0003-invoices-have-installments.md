# 0003. Every invoice has one or more installments

- **Status:** Accepted
- **Date:** 2026-09-30
- **Ticket:** T-004; implemented in E4

## Context

Freelancers and small agencies often split an invoice into installments. The common shortcut, an
`installments_count` on the invoice, creates two code paths (single payment vs. split) and spreads conditionals
through payments, reminders and status logic.

## Decision

- Every invoice has **one or more installments**. A single-payment invoice is an invoice with one installment.
- **Payments belong to installments**, not to the invoice. Reminders and payment links also work per installment.
- The **invoice status is derived from its installments**: it becomes `paid` when all of them are paid. A partially
  paid invoice stays `open`, with progress visible.
- Invoice states are `draft`, `open`, `paid` and `void`. **"Overdue" is derived** (open with a past due date), never
  stored: storing it would need a job racing the clock.
- **Refunds are records attached to payments**, not an invoice state: an invoice can have several partial refunds.
- An invoice with a paid installment **cannot be voided**: refund first, then void.
- Installment amounts come from `Money` allocation (ADR-0002), so they always sum to the invoice total.

## Consequences

- One code path for single and split invoices.
- An extra table and join even for the simple case, which is cheap compared to two code paths.
- Listing overdue invoices is a query (`open` and `due_on < today`), and it needs a suitable index.
