# Engineering progress

[Back to Ledgerly](../README.md)

One product. Four engineering dimensions. This document tracks evidence of the project's engineering outcomes, not
personal proficiency. The [product roadmap](https://github.com/users/linielson/projects/2) remains authoritative for
issue scope and delivery status.

Each dimension has five milestones. A milestone counts only when its stated completion criteria are satisfied and
supporting evidence is linked. Partial work does not increase the count. Milestones can be refined deliberately as the
project evolves; technologies listed as explorations are not automatic production requirements.

Baseline evidence reviewed on 2026-11-26, against
[`a0dca10`](https://github.com/linielson/ledgerly/commit/a0dca105938f2de69f04ac472c43a996558d5fe2) and associated PRs.
The maintainer accepted the baseline counts in the pull request that published this document; the AI-assisted workflow
milestone includes publication of the workflow in the README. Subsequent milestone updates require explicit acceptance
and dated evidence. Application changes must meet the existing CI and merge requirements. Reproducible experiments,
published libraries and articles may provide evidence outside the application repository where appropriate.

## Software Engineering — 1/5

| Milestone                   | Completion criteria                                                                                                     | Status and evidence                                                                                                                                                                                                                                                                                                                                                                                              |
| --------------------------- | ----------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Monetary domain             | Immutable money and currency, exact arithmetic, allocation, formatting, rounding and persistence integration with tests | Complete — 2026-10-21 (implementation evidence) — [Money](https://github.com/linielson/ledgerly/pull/41), [allocation](https://github.com/linielson/ledgerly/pull/43), [formatting](https://github.com/linielson/ledgerly/pull/44), [percentages and rounding](https://github.com/linielson/ledgerly/pull/45), [Active Record integration](https://github.com/linielson/ledgerly/pull/47), [ADRs](adr/README.md) |
| Authentication and tenancy  | Authentication, sign-up, tenant isolation and authorization tested                                                      | In progress — [authentication](https://github.com/linielson/ledgerly/pull/57), [T-202](https://github.com/linielson/ledgerly/issues/49), [T-203](https://github.com/linielson/ledgerly/issues/50), [T-204](https://github.com/linielson/ledgerly/issues/51), [rate-limit follow-up](https://github.com/linielson/ledgerly/pull/78)                                                                               |
| Financial core              | Customer, invoice, installment and ledger flows with database invariants and reproducible tests                         | Planned                                                                                                                                                                                                                                                                                                                                                                                                          |
| Payment integrations        | Gateway adapter, sandbox or fake gateway demonstration, idempotency, refunds and failure-path tests                     | Planned                                                                                                                                                                                                                                                                                                                                                                                                          |
| Reliability and performance | Measured query and job behavior, concurrency checks and documented failure/recovery scenarios                           | Planned                                                                                                                                                                                                                                                                                                                                                                                                          |

## AI Engineering — 0/5

| Milestone                | Completion criteria                                                                                                                                                 | Status  |
| ------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------- |
| LLM integration          | Reproducible direct API experiment and RubyLLM integration covering structured responses, streaming and error handling                                              | Planned |
| Tools and MCP            | Authorized tools with argument validation, an implemented Ruby MCP server and a working client, with isolation tests                                                | Planned |
| Retrieval and memory     | Retrieval and memory experiments with datasets, relevance/grounding checks and access-control evidence                                                              | Planned |
| Agents and orchestration | Reproducible agent, multi-agent and configurable agent-factory experiments with a comparison to a simpler baseline                                                  | Planned |
| Production AI            | Useful integrated capability with reproducible evaluations, prompt-injection and PII controls, error handling, cost/latency measurements and documented limitations | Planned |

The completion criteria permit isolated reproducible experiments where production integration is not warranted. Financial
mutations require deterministic authorization, confirmation, idempotency and audit. Tests and evaluations support bounded
claims; they do not prove complete safety.

## AI-Assisted Engineering — 1/5

| Milestone                      | Completion criteria                                                                                                                                       | Status and evidence                                                                                                                                                                                                        |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Issue-driven assisted workflow | Publicly documented human-led workflow, issue-linked PRs, factual AI-assistance disclosure in an actual PR and automated verification                     | Complete — 2026-11-26 — [workflow](../README.md#how-this-project-is-built), [template PR #77](https://github.com/linielson/ledgerly/pull/77), [example PR #78](https://github.com/linielson/ledgerly/pull/78), [CI](ci.md) |
| Context and specifications     | A documented, repeatable context and specification workflow applied to an actual change                                                                   | Planned                                                                                                                                                                                                                    |
| Agentic tooling                | A scoped trial of community tooling (skills, hooks, planning or coding harness) with a documented baseline and an explicit adoption or rejection decision | Planned                                                                                                                                                                                                                    |
| Multi-agent development        | A reproducible orchestration or agent-factory development experiment with defined roles and verification                                                  | Planned                                                                                                                                                                                                                    |
| Measured workflow improvement  | A documented comparison of time, cost, rework and quality, with limitations and retained workflow                                                         | Planned                                                                                                                                                                                                                    |

## Engineering Maturity — 2/5

| Milestone                      | Completion criteria                                                                                                                                      | Status and evidence                                                                                                                                                                                           |
| ------------------------------ | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Architecture and standards     | Documented architectural decisions, trade-offs and repository conventions                                                                                | Complete — evidence reviewed 2026-11-26 — [ADRs](adr/README.md), [conventions](conventions.md)                                                                                                                |
| Automated quality and delivery | Versioned CI, security checks, reviewed changes and continuous deployment configuration with successful runs                                             | Complete — 2026-11-26 — [CI](ci.md), [deployment](deploy.md), [baseline CI run](https://github.com/linielson/ledgerly/actions/runs/45860609056)                                                               |
| Authorization and recovery     | Tenant-aware permissions, backup and verified restore, with documented failure handling                                                                  | Planned; release gate recorded — [T-012](https://github.com/linielson/ledgerly/issues/34), [T-203](https://github.com/linielson/ledgerly/issues/50), [T-204](https://github.com/linielson/ledgerly/issues/51) |
| Operational and AI reliability | Documented operational checks and reproducible reliability, safety and evaluation results                                                                | Planned                                                                                                                                                                                                       |
| Technical communication        | Published technical articles and a portfolio case study linked to working demonstrations, decisions and results; articles may be published incrementally | Planned                                                                                                                                                                                                       |

## Updating progress

Update this document, the README count and that dimension's bar in `assets/` together when a milestone is completed or
its criteria change. Link the PR, test, experiment, evaluation report or published artifact that supports the change.
Record evidence and the maintainer's acceptance date in the corresponding PR or versioned report. Keep planned work
distinguishable from implemented and verified work.
