<div align="center">

# Ledgerly

### One Product. Four Engineering Dimensions.

Financial software. Applied intelligence. Engineering excellence.

[![CI](https://github.com/linielson/ledgerly/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/linielson/ledgerly/actions/workflows/ci.yml)

**Ruby 4 · Rails 8.1 · PostgreSQL · RSpec · MIT**

[Live application](https://ledgerly.linirosa.com) · [Roadmap](https://github.com/users/linielson/projects/2) ·
[Architecture](docs/adr/README.md) · [Engineering progress](docs/engineering-progress.md)

</div>

## About

Ledgerly is an open-source invoicing and financial management application for freelancers and small agencies, designed
to evolve into a reference project for applied AI engineering with Ruby on Rails.

The product is designed around installment-based invoicing, payment gateways, refunds and an immutable double-entry
ledger. Its long-term direction is to integrate AI into financial workflows without compromising correctness, security
or accountability.

**Work in progress.** The monetary foundation and authentication are implemented. Multi-tenancy, invoicing, payments,
the ledger and AI capabilities are roadmap items, not yet available product features.

## Engineering progress

Ledgerly brings four complementary engineering dimensions together in a single evolving product. Each advances through
implementation, documented decisions, automated verification and measurable outcomes.

### Software Engineering — 1/5

![Software Engineering: 1 of 5 milestones complete](docs/assets/software-engineering.svg)

Ruby, Rails, PostgreSQL, financial correctness and reliable integrations.

### AI Engineering — 0/5

![AI Engineering: 0 of 5 milestones complete](docs/assets/ai-engineering.svg)

LLM APIs, RubyLLM, tools, RAG, memory, agents, MCP and production AI.

### AI-Assisted Engineering — 1/5

![AI-Assisted Engineering: 1 of 5 milestones complete](docs/assets/ai-assisted-engineering.svg)

Context engineering, specifications, agentic coding and orchestration.

### Engineering Maturity — 2/5

![Engineering Maturity: 2 of 5 milestones complete](docs/assets/engineering-maturity.svg)

Architecture, quality gates, security, operations and technical communication.

Each filled segment represents one completed milestone, not a percentage of personal proficiency or estimated feature
completion. See [engineering progress](docs/engineering-progress.md) for acceptance criteria, dated evidence and
remaining work.

## Current capabilities

- **Money and currency:** immutable value objects using integer minor units, deterministic allocation, locale-aware
  formatting and explicit rounding rules, with property-based tests.
- **Persistence:** Active Record integration for monetary values through the `money_attribute` macro.
- **Authentication:** database-backed sessions, expiry, rate limiting and password-reset flows. Production email delivery
  and public sign-up remain pending. The two password-controller rate limits have distinct names and specs that
  exercise each limit separately ([PR #78](https://github.com/linielson/ledgerly/pull/78)). The cookie lifetime adjustment remains
  open in [T-207](https://github.com/linielson/ledgerly/issues/76).
- **Delivery and quality:** automated tests, diff coverage, static analysis, security checks and continuous deployment
  with Kamal.

Explore the [monetary domain](app/models/money.rb), [money specs](spec/models/money_spec.rb),
[authentication design](docs/authentication.md) and [architecture decisions](docs/adr/README.md).

## Product and engineering roadmap

These delivery milestones summarize the direction of the project; the existing
[GitHub roadmap](https://github.com/users/linielson/projects/2) remains the source of truth for product tickets.

| Delivery milestone         | Intended outcome                                                                                    | Status      |
| -------------------------- | --------------------------------------------------------------------------------------------------- | ----------- |
| Engineering Foundation     | Secure tenant-aware application, monetary domain and operational foundation                         | In progress |
| Financial Core             | Customers, installments, invoices, double-entry ledger, payments and reproducible failure scenarios | Planned     |
| Intelligent Application    | Evaluated AI assistant with authorized tools, retrieval, memory and agentic workflows               | Planned     |
| Reusable AI Infrastructure | Reusable Ruby components for AI security, orchestration and supporting infrastructure               | Planned     |
| Portfolio Release          | Working demonstrations, technical articles and reproducible engineering evidence                    | Planned     |

The roadmap includes audit trails, business entities, invoice imports, outbound webhooks and vector synchronization.
Experiments may run before their integration milestone; they do not automatically become product requirements.

Public sign-up is gated by verified backup and restore, tenant isolation and the required authorization controls
([T-202](https://github.com/linielson/ledgerly/issues/49), [T-012](https://github.com/linielson/ledgerly/issues/34),
[T-203](https://github.com/linielson/ledgerly/issues/50), [T-204](https://github.com/linielson/ledgerly/issues/51)).

## Applied AI direction

The planned AI layer will use RubyLLM to connect model capabilities to real financial workflows. Exploration includes:

- Direct LLM APIs, structured outputs, streaming and provider integration.
- Tool calling, server-side authorization and controlled actions.
- Retrieval-augmented generation (RAG), embeddings, memory and context engineering.
- Agent engineering, multi-agent orchestration and configurable agent factories.
- Model Context Protocol (MCP) client/server integration and reusable Ruby components.
- Reproducible evaluations, prompt-injection defenses, PII protection, observability, latency and cost measurement.

Business rules, monetary calculations and authorization remain deterministic application responsibilities. AI may interpret
intent and coordinate tools, but it must not be the authority for financial correctness or access control.

These capabilities are planned explorations, not current features. Integration depends on demonstrated value, domain
readiness and verification. Planned reusable gems address tool authorization and PII sanitization. They will be
extracted only after a real application need is demonstrated. Additional libraries are subject to the same standard.

## How this project is built

Ledgerly follows a **human-led, AI-assisted engineering workflow**. I own the product direction, architectural decisions,
domain correctness and final approval. AI tools support research, specifications, implementation, testing, documentation
and review depending on the work. I review and verify generated output rather than accepting it on trust.

The workflow is deliberately proportionate to the task:

1. Define the problem, constraints and acceptance criteria in an issue.
2. Research and plan when the complexity warrants it; review the proposed approach before implementation.
3. Implement and verify the change against its acceptance criteria, using tests and security checks.
4. Open an issue-linked pull request, document relevant architectural decisions and review the evidence before merging.
5. Record useful findings in the appropriate documentation, experiment report or technical article.

The [AI Assistance section](.github/pull_request_template.md) records actual contributions and human verification in new
PRs. For a concrete example, see [PR #78](https://github.com/linielson/ledgerly/pull/78), which documents the maintainer's
controller change, AI-assisted test improvements and verification. Automated checks gate merges; AI review (CodeRabbit)
is advisory.

Planned experiments cover application AI and development workflows, including context engineering,
specification-driven development, agentic coding and orchestration. Each community tool will be evaluated on its own
against a baseline before adoption. Exploratory code is not automatically integrated into the product. Findings, reusable
libraries and articles will be linked as they become available.

See [repository conventions](docs/conventions.md) and [CI and code review](docs/ci.md).

## Architecture and stack

The architectural direction is a Rails monolith with CRUD for operational data and an append-only double-entry ledger for
financial records. The accepted decisions are documented as [ADRs](docs/adr/README.md); planned components should not be
confused with implemented functionality.

| Layer                | Current stack                                               |
| -------------------- | ----------------------------------------------------------- |
| Application          | Ruby 4.0.10, Rails 8.1                                      |
| Database             | PostgreSQL                                                  |
| UI                   | Hotwire (Turbo + Stimulus), Tailwind CSS, esbuild           |
| Background jobs      | Solid Queue                                                 |
| Tests                | RSpec, SimpleCov, Undercover                                |
| Quality and security | RuboCop, Brakeman, bundler-audit, CodeQL, dependency review |
| Delivery             | GitHub Actions, Docker, Kamal, Oracle Cloud                 |

## Getting started

### Requirements

- Ruby 4.0.10 (see `.ruby-version`).
- Node.js 24 (see `.node-version`) and Yarn 1, pinned in `package.json` (`packageManager`); run `corepack enable` once.
- Docker, for local PostgreSQL and the EditorConfig check.
- CMake, to build the `rugged` gem used by `undercover` (`brew install cmake` on macOS).

### Setup

```sh
docker compose up -d   # Start PostgreSQL on port 5434
bin/setup              # Install dependencies, prepare the database and start the app
```

Open <http://localhost:3000>.

`bin/setup` creates `.env` from `.env.example` when missing, installs Ruby and JavaScript dependencies, prepares the
database and starts `bin/dev`. It is safe to run again: an existing `.env` is preserved. Use `bin/setup --skip-server`
to prepare without starting the app.

After the first setup:

```sh
bin/dev
```

`bin/dev` runs the Rails server plus the JavaScript and CSS watchers defined in `Procfile.dev`. If styles or JavaScript
are missing, check that both watchers are running.

The defaults in `.env.example` match `compose.yaml`. If port 5434 is taken, change `DB_PORT` in `.env`; Docker Compose
and Rails both read it.

After switching Ruby versions, run `bundle install` and clear the Bootsnap cache with `rm -rf tmp/cache/bootsnap`.
A cache created under the previous Ruby version can cause a `LoadError` for a standard library file such as `uri.rb`.

Public sign-up is not yet implemented. See [authentication](docs/authentication.md) for current behavior and limitations.

## Testing and quality

```sh
bundle exec rspec
bin/rubocop
bin/brakeman
```

The project also provides `bin/ci` for local checks. See [CI and code review](docs/ci.md) for the complete set of checks,
including those that run only on GitHub.

## Deployment

The application is deployed at [ledgerly.linirosa.com](https://ledgerly.linirosa.com). CI deploys with Kamal to an Oracle
Cloud Always Free server on pushes to `main` after the applicable checks pass. See [deployment documentation](docs/deploy.md).

The deployed application reflects the current implementation, not the complete roadmap.

## Documentation and evidence

| Resource                                                         | Description                                        |
| ---------------------------------------------------------------- | -------------------------------------------------- |
| [Engineering progress](docs/engineering-progress.md)             | Milestones and evidence across the four dimensions |
| [Architecture decision records](docs/adr/README.md)              | Decisions, alternatives and trade-offs             |
| [Authentication](docs/authentication.md)                         | Session design, security and current limitations   |
| [Conventions](docs/conventions.md)                               | Repository working standards                       |
| [CI and code review](docs/ci.md)                                 | Automated verification and merge gates             |
| [Deployment](docs/deploy.md)                                     | Infrastructure and delivery process                |
| [Product roadmap](https://github.com/users/linielson/projects/2) | Issues, priorities and implementation progress     |

Technical articles, reusable libraries, engineering experiments and AI evaluation reports will be linked here when
published. The planned portfolio release brings these artifacts together with a working demonstration; articles may
be published incrementally as evidence becomes available.

## License

[MIT](LICENSE)
