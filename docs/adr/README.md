# Architecture decision records

An ADR records one decision that shapes the code: the context, what was decided, and what it costs. Read the ADRs for
an area before changing it; when a change carries a new decision, add an ADR in the same pull request.

## How to write one

1. Copy [`template.md`](template.md) to `NNNN-short-title.md`, using the next number.
2. Keep it short: context, decision, consequences. Link the ticket or PR that made the decision.
3. ADRs are not edited after they are accepted, except to fix typos or set the status. A changed decision gets a new
   ADR whose status says `Supersedes ADR-NNNN`, and the old one becomes `Superseded by ADR-NNNN`.

## Index

| ADR                                                   | Decision                                                           | Status   |
| ----------------------------------------------------- | ------------------------------------------------------------------ | -------- |
| [0001](0001-record-architecture-decisions.md)         | Record architecture decisions                                      | Accepted |
| [0002](0002-money-as-integer-minor-units.md)          | Money as integer minor units with an in-house value object         | Accepted |
| [0003](0003-invoices-have-installments.md)            | Every invoice has one or more installments                         | Accepted |
| [0004](0004-installments-paid-by-link.md)             | Installments are paid by link; automatic charging is deferred      | Accepted |
| [0005](0005-double-entry-ledger.md)                   | Double-entry ledger with five accounts                             | Accepted |
| [0006](0006-daily-ledger-consolidation.md)            | Daily consolidation, posting date vs. occurrence date              | Accepted |
| [0007](0007-crud-monolith-with-append-only-ledger.md) | CRUD monolith plus an append-only ledger instead of event sourcing | Accepted |
| [0008](0008-hotwire-by-default-react-islands.md)      | Hotwire by default; React only for state-heavy islands             | Accepted |
| [0009](0009-explicit-rspec-spec-types.md)             | RSpec with explicit spec types                                     | Accepted |
