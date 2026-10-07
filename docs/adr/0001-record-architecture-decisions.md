# 0001. Record architecture decisions

- **Status:** Accepted
- **Date:** 2026-10-07
- **Ticket:** T-003

## Context

Ledgerly's main decisions (how money is represented, the ledger design, what was deliberately left out) were made in
conversation before any code existed. Code shows what was built, not why, nor which alternatives were rejected. Without
a record, the reasoning is lost, and later changes either repeat old debates or undo decisions without knowing their cost.

## Decision

Record each decision that shapes the code as an Architecture Decision Record in `docs/adr/`, following Michael
Nygard's format: context, decision, consequences. ADRs are numbered, never edited after acceptance (only superseded),
and added in the same pull request as the change that carries the decision.

Working rules that apply day to day (formatting, gem policy, comments) live in `docs/conventions.md` instead; CI and
review checks are described in `docs/ci.md`.

## Consequences

- Reviewers and newcomers can find why the code is the way it is.
- Each pull request that makes a decision costs a short document.
- Superseding instead of editing keeps the history of how thinking changed.
