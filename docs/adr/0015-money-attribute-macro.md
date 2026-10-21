# 0015. Models map Money to two columns with a `money_attribute` macro

- **Status:** Accepted
- **Date:** 2026-10-19
- **Ticket:** T-106 (#28)

## Context

[ADR-0002](0002-money-as-integer-minor-units.md) persists an amount as `amount_cents bigint NOT NULL` plus a currency
column with a format check, and leaves open how models turn those two columns into one `Money`. Rails' Attributes API
maps one column per attribute, so the options are:

- **`composed_of`**, Rails' built-in aggregation. It writes each mapped value object method straight into a column.
  Here that would put a `Currency` object, not its code, into `amount_currency`, so `Money` would need an extra
  method just for persistence. Its `nil` and conversion behaviour lives in `allow_nil`, `converter` and
  `constructor`, options few developers know. In exchange it supports `where(amount: money)`.
- **A macro of our own**, about twenty lines: a reader that builds `Money` with `Currency.fetch`, and a writer that
  stores the cents and the code.

## Decision

- An `ActiveSupport::Concern`, `MoneyAttribute`, is included in `ApplicationRecord`. A model declares
  `money_attribute :amount` to read and write `amount` as `Money` over `amount_cents` and `amount_currency`.
- **Reading** builds `Money.new(cents, Currency.fetch(code))`, or returns `nil` when either column is empty. A
  well-formed code that isn't a known currency raises `Currency::UnknownCurrencyError`.
- **Writing** a `Money` stores its cents and currency code. Writing `nil` clears both columns. Anything else raises
  `ArgumentError` at assignment (`amount must be a Money, got 10.5 (Float)`), because a bare number would hide the
  currency. Parsing what a user types into a form is a separate concern, for the screens that need it.
- The macro adds a **presence validation**, so a missing amount is a validation error, not a database exception.
  `NOT NULL` and the format check (`amount_currency ~ '^[A-Z]{3}$'`, `char(3)`) stay in the database as the second
  line of defence.

## Consequences

- The `nil`, error and currency rules are explicit, tested and readable in the repo.
- The column names are a convention, as with `belongs_to :invoice` and `invoice_id`: `money_attribute :fee` expects
  `fee_cents` and `fee_currency`, and a model can declare several attributes. The macro doesn't check the columns when
  the class loads, because the database may be unavailable then (the Docker build precompiles assets without one).
  Three cases differ:
  - **Column absent from the table** (a wrong name): writing raises `ActiveModel::MissingAttributeError`, reading
    returns `nil`, and the presence validation stops the save.
  - **Column present but not loaded** (a query with `select(:id)`): reading raises `ActiveModel::MissingAttributeError`.
  - **Column present and `NULL`**: reading returns `nil`, and the presence validation reports it.

  Each model's round-trip spec is what catches a wrong name.

- Queries go through the columns: `where(amount_cents: 1000, amount_currency: "BRL")`. A scope can wrap that when
  E4 needs it.
- Specs create their own table inside the example, because PostgreSQL rolls DDL back with the transaction. No domain
  table is created ahead of E4.
- Every money table repeats the two columns and the check constraint by hand. Add a migration helper (`t.money`) once
  E4 and E5 have several such tables, and add the column rules to the CodeRabbit instructions for `db/migrate/**`
  with the first real money migration.
