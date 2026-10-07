# 0009. RSpec with explicit spec types

- **Status:** Accepted
- **Date:** 2026-10-01
- **Ticket:** T-001 (PR #5), recorded in T-004

## Context

Rails 8 generates Minitest; most Rails teams use RSpec. `rspec-rails` gives each spec type its own helpers
(`type: :request` gives `get` and `response`; `type: :system` gives Capybara). The type can be declared on each
`describe` or inferred from the folder (`infer_spec_type_from_file_location!`), which the RSpec team removed from the
defaults because it is hidden behavior: moving a file changes how it runs.

## Decision

- **RSpec** (`rspec-rails`) is the test framework; Minitest is not installed.
- Spec types are **declared explicitly**: `RSpec.describe "Health check", type: :request do`. Inference from the file
  location stays off.
- Plain Ruby objects (such as `Money` and `Currency`) require `spec_helper` only, without loading Rails; everything
  else requires `rails_helper`.
- Tests run in transactions rolled back after each example. Concurrency tests (invoice numbering, pessimistic locks)
  turn that off for themselves, because two connections can't see each other's uncommitted data.

## Consequences

- Each spec states what it is; moving files doesn't change behavior.
- One extra argument per `describe`.
- Fast specs for the domain core, since Rails isn't loaded for plain objects.
