# Ledgerly

Invoicing app for freelancers and small agencies: issue invoices (split into installments),
collect payment through a gateway, handle refunds, and keep every cent in an immutable
double-entry ledger. Open-source portfolio project.

## Stack

- Rails 8, PostgreSQL, Hotwire (Turbo + Stimulus), Tailwind, esbuild
- RSpec for tests (Minitest is not installed)
- Solid Queue for background jobs
- React + TypeScript only for state-heavy islands (the installment editor); everything else is Hotwire

## Commands

- `bin/setup` — install dependencies and prepare the database
- `bin/dev` — run the app (server + JS and CSS watchers via `Procfile.dev`)
- `docker compose up -d` — start the local PostgreSQL
- `bundle exec rspec` — run the test suite
- `bin/rubocop` and `bin/brakeman` — lint and security scan (both must be clean)

## Domain rules (do not break these)

### Money

- Amounts are integer minor units plus an ISO currency code. Never use Float for money, not even for display.
- Use the `Money` value object; it is immutable and raises on currency mismatch.
- Splitting money uses allocation: the parts always sum to the original total.
- Percentages use `BigDecimal`/`Rational` with the rounding mode documented in the ADRs.

### Invoices and installments

- Invoice states: `draft`, `open`, `paid`, `void`. "Overdue" is derived (open + past due date), never stored.
- Refunds are records attached to payments, not an invoice state.
- Every invoice has one or more installments. Payments belong to installments.
- An invoice with a paid installment cannot be voided; refund first.

### Ledger

- Double-entry: each ledger transaction has two or more entries with signed cents that sum to zero.
- Append-only: entries are never updated or deleted (enforced by a database trigger). Corrections are reversing entries.
- Every entry has `occurred_at` (when it happened) and `posted_at` (when it was recorded).
- A daily job closes day D-1 in the tenant timezone (default `America/Sao_Paulo`) and stores per-account balances.
  Closed periods reject new postings; late events are posted to the open day.

### Tenancy

- All data is scoped to a tenant. Never query tenant-owned records without the tenant scope.

## Conventions

- Code, comments, commit messages, issues and docs are in English.
- Architecture decisions live in `docs/adr/`. Read the relevant ADR before changing an area; add or update one when a change carries a decision.
- Every change goes through a pull request linked to an issue, with the DoD checklist from the PR template filled in.
