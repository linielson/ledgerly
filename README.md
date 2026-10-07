# Ledgerly

[![CI](https://github.com/linielson/ledgerly/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/linielson/ledgerly/actions/workflows/ci.yml)

Invoicing for freelancers and small agencies: issue invoices split into installments, collect payment
through a gateway, handle refunds, and keep every cent in an immutable double-entry ledger.

Open-source portfolio project. Work in progress.

## Stack

- Ruby 4.0.5, Rails 8.1, PostgreSQL
- Hotwire (Turbo + Stimulus), Tailwind CSS, esbuild
- Solid Queue for background jobs
- RSpec for tests

## Requirements

- Ruby 4.0.5 (see `.ruby-version`)
- Node.js 20 (see `.node-version`) and Yarn
- Docker, for the local PostgreSQL and the EditorConfig check
- CMake, to build the `rugged` gem that `undercover` uses in the test suite (`brew install cmake` on macOS)

## Getting started

```sh
docker compose up -d   # start PostgreSQL on port 5434
bin/setup              # first run: set everything up and start the app at http://localhost:3000
```

`bin/setup` creates `.env` from `.env.example` when it is missing, installs gems and JS packages,
prepares the database and then starts `bin/dev`. It is safe to run again: an existing `.env` is kept.
Use `bin/setup --skip-server` to prepare without starting the app.

After the first setup, start the app with:

```sh
bin/dev
```

`bin/dev` runs three processes from `Procfile.dev`: the Rails server and the JS and CSS watchers.
If the app loads without styles or JavaScript, check that both watchers are running.

The defaults in `.env.example` match `compose.yaml`. If port 5434 is taken on your machine,
change `DB_PORT` in `.env`; Docker Compose and Rails both read it.

## Running the tests

```sh
bundle exec rspec
```

## Linting and security

```sh
bin/rubocop
bin/brakeman
```

## Conventions

- [docs/conventions.md](docs/conventions.md): how we work day to day
- [docs/ci.md](docs/ci.md): what runs on every pull request and what blocks a merge

## License

[MIT](LICENSE)
