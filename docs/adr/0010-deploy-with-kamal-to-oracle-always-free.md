# 0010. Deploy with Kamal to an Oracle Cloud Always Free server

- **Status:** Accepted
- **Date:** 2026-10-08
- **Ticket:** T-007 (#18)

## Context

The app needs to be live early: deploying an almost empty app is the cheapest deploy there is, it surfaces production
problems (TLS, host checks, secrets, assets, migrations) while they're small, and interviewers can open it. Rails 8
ships Kamal, which deploys Docker images to any Linux server over SSH.

Cost matters: this is a portfolio project, and fees in euros or dollars weigh more for a Brazilian developer.
Options considered (prices as of October 2026):

| Option                                  | Monthly cost | Notes                                                                |
| --------------------------------------- | ------------ | -------------------------------------------------------------------- |
| Hetzner CX23 (4 GB)                     | ~€6          | Europe only; signup required €25 of prepaid credit                   |
| AWS Lightsail (2 GB)                    | US$12        | No free credits for an existing AWS account                          |
| Hostinger KVM 1 (4 GB)                  | ~R$28–30     | BRL, but a 24-month prepaid contract                                 |
| **Oracle Cloud Always Free, Ampere A1** | **US$0**     | arm64; capacity shortages; idle instances reclaimed on free accounts |

## Decision

- **Host:** Oracle Cloud Always Free, home region **US East (Ashburn)**, the closest to the US and European
  interviewers the app is for. Instance `VM.Standard.A1.Flex` with 2 OCPU and 12 GB (half the free allowance), Ubuntu
  24.04 aarch64.
- **Account upgraded to Pay As You Go** with a US$1 budget alert: free accounts reclaim idle instances, and a portfolio
  app is idle most of the time. Always Free resources stay free.
- **Kamal** with **GitHub Container Registry**, **arm64** builds (native on Apple Silicon and on GitHub's free arm64
  runners), **Postgres 18 as a Kamal accessory** on the same server with no published port, and **kamal-proxy** for
  TLS (Let's Encrypt) and zero-downtime deploys gated by `GET /up`.
- **Hostname via sslip.io** until a domain (`ledgerly.lini.dev`) is bought; switching is a one-line change.
- `force_ssl`, `assume_ssl` and `config.hosts` are on, with `/up` excluded from both checks.

## Consequences

- Production costs nothing, and the app runs close to the people evaluating it.
- arm64 is a constraint to keep in mind (images, native gems), handled by building natively.
- One server holds the app, the jobs and the database: no redundancy, and backups must be added before real data
  exists. Capacity on Oracle's free tier can run out, and its terms can change; Hostinger or Hetzner are the fallbacks,
  and the Kamal setup moves with only `config/deploy.yml` changes.
- Oracle-specific setup (non-root `ubuntu` user, Docker installed by hand, in-VM `iptables`) is documented in
  `docs/deploy.md` so the server can be rebuilt.
