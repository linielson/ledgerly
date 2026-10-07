# 0008. Hotwire by default; React only for state-heavy islands

- **Status:** Accepted
- **Date:** 2026-09-30
- **Ticket:** T-004; first island in E4

## Context

Most screens are CRUD and server-rendered state, where Hotwire (Turbo + Stimulus) delivers the most with the least code.
A full React front end would add an API layer, token authentication, serialization and duplicated client state,
roughly doubling the project. One screen has real client-side state: the installment editor, where the number of
installments, dates and amounts are recalculated live and must always sum to the invoice total.

## Decision

- The app is **Hotwire**.
- **React with TypeScript** is used only for **islands**: components with real, fast-changing client state. The first
  and only one planned is the installment editor.
- JavaScript is bundled with **esbuild** (`jsbundling-rails`), not importmap, because importmap can't compile JSX or
  TypeScript.

## Consequences

- Two ways to build UI in one app, and a build step instead of importmap.
- Each new island needs a justification: client state that the server round-trip can't serve well.
- Formatting and linting for TypeScript arrive with the first island (Prettier is already in place).
