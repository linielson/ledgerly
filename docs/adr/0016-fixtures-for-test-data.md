# 0016. Test data comes from fixtures

- **Status:** Accepted
- **Date:** 2026-10-23
- **Ticket:** T-201 (#48)

## Context

T-201 adds the first models with persistent data that many specs need: users, and soon tenants, memberships and
customers. Specs need a way to create that data. The two common options in Rails are:

- **Fixtures:** YAML files of named records (`users(:one)`), Rails' default. They are inserted once before the suite
  and each example runs in a transaction that is rolled back.
- **FactoryBot:** a gem of Ruby builders (`create(:user)`) that insert records inside each example.

## Decision

- Specs use **fixtures** in `spec/fixtures/`, loaded for every spec (`config.global_fixtures = :all`).
- Fixtures are named after what they represent in the story a spec tells: in E2, two tenants such as `acme` and
  `globex` with their own users and records. Isolation specs then read as "acting as `acme`, `globex`'s customer is
  not found".
- A spec that needs a variation the fixtures don't have builds that record inline with `create!`. When the same
  variation shows up in several specs, it becomes a fixture.
- Fixture passwords are `"password"`, hashed in the YAML with ERB. Tests run bcrypt at its minimum cost, which Rails
  sets for the test environment.

## Consequences

- No gem, and fast: the data is inserted once in bulk instead of once per example.
- The shared data set has to stay small and meaningful, or every change ripples through many specs. Adding a fixture
  is a reviewed change like any other.
- Data built per example (`create!`) is more verbose than a factory with traits. Revisit if specs keep building the
  same complex graphs by hand.
