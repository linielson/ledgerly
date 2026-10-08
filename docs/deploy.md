# Deployment

Ledgerly deploys with [Kamal](https://kamal-deploy.org) to a single server. Kamal builds a Docker image, pushes it to a
registry, and on the server starts the new container behind `kamal-proxy`, which switches traffic only after the new
container passes its health check (`GET /up`). The decision and its trade-offs are in
[ADR-0010](adr/0010-deploy-with-kamal-to-oracle-always-free.md).

## How the pieces fit

```
your Mac / CI runner (arm64)                    Oracle Cloud A1 server (arm64, Ubuntu 24.04, user `ubuntu`)
┌──────────────────────────┐   docker push    ┌──────────────────────────────────────────────────────────┐
│ bin/kamal deploy         │ ───────────────► │ ghcr.io/linielson/ledgerly:<git sha>   (pulled)          │
│  - docker build (arm64)  │      ghcr.io     │                                                          │
│  - ssh ubuntu@server     │ ───────────────► │ kamal-proxy :80/:443  ── TLS (Let's Encrypt) ──┐         │
└──────────────────────────┘                  │                                                ▼         │
                                              │ ledgerly-web container (Puma + Solid Queue) ── DB_HOST ─┐ │
                                              │                                                         ▼ │
                                              │ ledgerly-db container (postgres:18, data in ~/ledgerly-db) │
                                              └──────────────────────────────────────────────────────────┘
```

| Piece                                                                    | Where it's configured                                       |
| ------------------------------------------------------------------------ | ----------------------------------------------------------- |
| Server, SSH user, proxy, registry, builder arch, env, Postgres accessory | `config/deploy.yml`                                         |
| Which secrets exist (names only, never values)                           | `.kamal/secrets`                                            |
| HTTPS, `Host` header check and their `/up` exceptions                    | `config/environments/production.rb`                         |
| The image                                                                | `Dockerfile`                                                |
| Server firewall                                                          | Oracle Security List (cloud) and `iptables` (inside the VM) |

### Why each setting exists

- **arm64 everywhere.** The server is an Ampere A1 (arm64). Apple Silicon Macs build arm64 natively, and the CI deploy
  job runs on GitHub's free `ubuntu-24.04-arm` runners, so no emulation is involved.
- **`ssh.user: ubuntu`.** Oracle's Ubuntu image has no root login. Kamal only installs Docker itself when it connects as
  root, so Docker was installed once by hand and `ubuntu` was added to the `docker` group.
- **`proxy.ssl: true` + `host`.** `kamal-proxy` gets and renews a Let's Encrypt certificate for the host. Until the app
  has a domain, the host is `ledgerly.<ip-with-dashes>.sslip.io`, which sslip.io resolves to that IP.
- **`assume_ssl` + `force_ssl`.** TLS ends at `kamal-proxy`, which forwards plain HTTP to the container; `assume_ssl`
  tells Rails the original request was HTTPS, and `force_ssl` redirects HTTP, sets HSTS and marks cookies secure.
- **The `/up` exceptions.** `kamal-proxy` health-checks the container directly over HTTP and by IP. Without the
  exceptions, `force_ssl` would answer the health check with a redirect and `config.hosts` with a 403, and the new
  container would never receive traffic.
- **`APP_HOST`.** One value, used by both `kamal-proxy` (routing, certificate) and `config.hosts`. The Docker build
  precompiles assets without the app's env, so `config.hosts` is skipped when `SECRET_KEY_BASE_DUMMY` is set; a server
  started without `APP_HOST` fails at boot instead of running without host protection.
- **Postgres as an accessory.** It runs next to the app on the same server, with no published port: only containers on
  Kamal's Docker network reach it, by the name `ledgerly-db`. Data lives in `~/ledgerly-db/data` on the server.
  The image's entrypoint runs `bin/rails db:prepare` on boot, which creates the primary, cache, queue and cable
  databases on the first deploy and runs pending migrations afterwards.
- **One password, two names.** The app reads `LEDGERLY_DATABASE_PASSWORD` (`config/database.yml`); the Postgres image
  expects `POSTGRES_PASSWORD`. Kamal's aliased secret (`POSTGRES_PASSWORD:LEDGERLY_DATABASE_PASSWORD`) feeds both from
  one value.

## Secrets

| Secret                       | What it is                                                                                                                                                                                                          | Local source                         | CI source             |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------ | --------------------- |
| `KAMAL_REGISTRY_PASSWORD`    | GitHub **classic** personal access token with only `write:packages`, 90-day expiry (the container registry doesn't accept fine-grained tokens). Kamal also logs in with it on the server, so keep its scope minimal | `.env`                               | GitHub Actions secret |
| `RAILS_MASTER_KEY`           | Decrypts `config/credentials.yml.enc`                                                                                                                                                                               | `.env` (copy of `config/master.key`) | GitHub Actions secret |
| `LEDGERLY_DATABASE_PASSWORD` | Postgres password, generated with `openssl rand -hex 32`                                                                                                                                                            | `.env`                               | GitHub Actions secret |

`.kamal/secrets` is committed and only maps names to environment variables. Kamal doesn't read `.env` by itself, so
locally every Kamal command runs through dotenv:

```sh
bundle exec dotenv bin/kamal <command>
```

## Preparing the server (once)

These steps happen in the Oracle Cloud console and over SSH; they are recorded here so the server can be rebuilt.

1. **Account:** MFA on; upgraded to Pay As You Go (Always Free resources stay free, and idle instances are not
   reclaimed); a US$1 budget alert.
2. **Network:** a VCN created with the "internet connectivity" wizard; ingress rules for TCP 80 and 443 in its Security
   List (22 is open by default). Postgres is not exposed.
3. **Instance:** `VM.Standard.A1.Flex`, 2 OCPU, 12 GB, Canonical Ubuntu 24.04 aarch64, public IPv4, our SSH key.
4. **Docker, as `ubuntu`:**
   ```sh
   curl -fsSL https://get.docker.com | sudo sh
   sudo usermod -aG docker ubuntu        # log out and back in afterwards
   docker run --rm hello-world           # must work without sudo
   ```
5. **Firewall inside the VM: leave it alone.** Oracle's Ubuntu image ships `iptables` rules that reject everything but
   SSH in the `INPUT` chain, and the usual advice is to open 80 and 443 there. With Kamal that isn't needed: the proxy's
   ports are published by Docker, so incoming traffic is DNAT'ed to the container and goes through the `FORWARD` chain,
   where Docker inserts its own rules (`DOCKER-USER`, `DOCKER-FORWARD`) ahead of Oracle's `REJECT`. Verified on this
   server with a test container on port 80, before and after a reboot.
   Don't run `netfilter-persistent save` while Docker is running: it would persist Docker's dynamic rules into
   `/etc/iptables/rules.v4`, and they'd conflict with the ones Docker recreates on boot.

## Server log

Everything done on the server by hand, in order, so it can be rebuilt or audited. Kamal-managed state (containers,
proxy, accessory data) is not listed: `bin/kamal setup` recreates it.

| Date       | Command (as `ubuntu`, over SSH)                                                                                            | Why                                                                         |
| ---------- | -------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------- |
| 2026-10-08 | `curl -fsSL https://get.docker.com -o /tmp/get-docker.sh && sudo sh /tmp/get-docker.sh`                                    | Install Docker (29.8.2); Kamal only installs it when connecting as root     |
| 2026-10-08 | `sudo usermod -aG docker ubuntu`                                                                                           | Run Docker without `sudo`, which Kamal requires for a non-root user         |
| 2026-10-08 | `docker run --rm hello-world`                                                                                              | Check Docker works for `ubuntu`                                             |
| 2026-10-08 | `docker run -d --rm --name porttest -p 80:80 nginx:alpine`, `curl http://<ip>/` from outside (200), `docker stop porttest` | Prove Docker-published ports pass Oracle's `iptables` without changes       |
| 2026-10-08 | `sudo systemctl reboot`, then the same port test (200)                                                                     | Prove it survives a reboot (Docker re-inserts its `FORWARD` rules on start) |
| 2026-10-08 | `docker rmi nginx:alpine hello-world`                                                                                      | Remove the test images                                                      |
| 2026-10-08 | Appended the `ledgerly-ci-deploy` public key to `~/.ssh/authorized_keys`, then logged in with it                           | Dedicated key for the CI deploy job (see Continuous deployment)             |

No `iptables` rule was added and `netfilter-persistent save` was never run. Oracle's own rules in
`/etc/iptables/rules.v4` are untouched.

## Deploying

First time (boots the proxy and the Postgres accessory, then the app):

```sh
bundle exec dotenv bin/kamal setup
```

Every deploy after that:

```sh
bundle exec dotenv bin/kamal deploy
```

Check it:

```sh
curl -sS -o /dev/null -w "%{http_code}\n" https://<APP_HOST>/up     # 200
bundle exec dotenv bin/kamal app logs
bundle exec dotenv bin/kamal console                                  # Rails console on the server
```

## Continuous deployment

Every push to `main` that passes `scan_ruby`, `lint`, `format` and `test` runs the `deploy` job in
`.github/workflows/ci.yml`, which runs `bin/kamal deploy` on a GitHub `ubuntu-24.04-arm` runner. Deploys show up on the
repository's **Environments → production** page.

| Piece          | How it's set up                                                                                                                                                                                                                                            |
| -------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Registry login | `GITHUB_TOKEN` with `packages: write`, only in this job. The image is linked to the repo by the `org.opencontainers.image.source` label in the `Dockerfile`, and the package grants the repository write access (package settings → Manage Actions access) |
| SSH            | A dedicated deploy key (`ledgerly-ci-deploy`, ed25519), not a personal key. Its public half is in the server's `~/.ssh/authorized_keys`; the private half exists only as the `SSH_PRIVATE_KEY` secret                                                      |
| Host key       | Pinned: `SSH_KNOWN_HOSTS` holds the server's ed25519 key (fingerprint `SHA256:syVSQUpruRNfoQbdPRyfi4I+ffYyzVc8eX3vRyeJV74`), so a different server is rejected instead of trusted on first use                                                             |
| App secrets    | `RAILS_MASTER_KEY` and `LEDGERLY_DATABASE_PASSWORD` as secrets of the `production` environment                                                                                                                                                             |
| Concurrency    | One deploy at a time (`deploy-production`), and a running deploy is never cancelled                                                                                                                                                                        |

To revoke CI access, remove the `ledgerly-ci-deploy` line from `~/.ssh/authorized_keys` on the server and delete the
`SSH_PRIVATE_KEY` secret.

## Changing the host (when the domain arrives)

1. Point an `A` record for `ledgerly.<domain>` at the server's IP (with Cloudflare, "DNS only" first: the proxied mode
   breaks the Let's Encrypt challenge).
2. Change `proxy.host` and `env.clear.APP_HOST` in `config/deploy.yml`, then deploy.
