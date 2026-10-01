# Ledgerly

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
- Docker, for the local PostgreSQL

## Getting started

```sh
cp .env.example .env   # optional: the defaults already match compose.yaml
docker compose up -d   # start PostgreSQL on port 5434
bin/setup              # install dependencies and prepare the database
bin/dev                # run the app at http://localhost:3000
```

`bin/dev` runs three processes from `Procfile.dev`: the Rails server and the JS and CSS watchers.
If the app loads without styles or JavaScript, check that both watchers are running.

## Running the tests

```sh
bundle exec rspec
```

## Linting and security

```sh
bin/rubocop
bin/brakeman
```

## License

MIT
