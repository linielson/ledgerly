# CI and code review checks

What runs on every pull request, what blocks a merge, and where each piece is configured.
Some controls live in GitHub settings rather than in this repository; they are listed here so that a reviewer,
human or AI, can see them.

## The rule for `main`

Nothing reaches `main` without a pull request whose required checks passed. The ruleset `main` has no bypass, not even
for admins:

- pull request required (0 approvals: a solo maintainer can't approve their own PR)
- required status checks, sourced from GitHub Actions; the branch must be up to date with `main` before merging
- CodeQL results: no new alert at `error` level, no new security alert of `high` severity or above
- linear history (rebase merges only), no force pushes, no deletion

## Checks

| Check | What it does | Blocks merge | Configured in |
| --- | --- | --- | --- |
| `test` | RSpec against PostgreSQL 18 (service container, same image as `compose.yaml`); then `undercover` fails if code changed in the PR isn't executed by any test | Yes | `.github/workflows/ci.yml`, `spec/spec_helper.rb` |
| `lint` | RuboCop (Rails omakase) | Yes | `.github/workflows/ci.yml`, `.rubocop.yml` |
| `scan_ruby` | Brakeman (Rails security patterns) and bundler-audit (known vulnerable gems) | Yes | `.github/workflows/ci.yml` |
| `scan_js` | `yarn install --frozen-lockfile`: fails if `package.json` and `yarn.lock` disagree | Yes | `.github/workflows/ci.yml` |
| `dependency_review` | Fails if the PR introduces a dependency with a known vulnerability of moderate severity or above (pull requests only) | Yes | `.github/workflows/ci.yml` |
| CodeQL | Data-flow security analysis for Ruby, JavaScript/TypeScript and GitHub Actions; annotates the PR | Yes, through the ruleset thresholds above | GitHub: Settings → Code security (default setup, query suite Default) |
| CodeRabbit | AI review: summary, security notes, line comments; reads `CLAUDE.md` as guidelines | No, advisory only | `.coderabbit.yaml`, GitHub App installed on this repository |

The ruleset itself, CodeQL default setup, Dependabot alerts and security updates, and the CodeRabbit installation are
GitHub settings: they don't appear in any diff.

## Coverage: the diff, not a percentage

SimpleCov records which lines and branches the suite executed (`spec/spec_helper.rb`), and `undercover` compares that
with the changes since `origin/main`. Every changed method needs a test that runs it; there is no global percentage
target, because a global target rewards testing easy code.

- Branch coverage is on: `return x if condition` counts as covered only when both paths run.
- Files never loaded by the suite still appear in the report (`cover "{app,lib}/**/*.rb"`), so a new untested file can't
  hide.
- Local coverage looks lower than CI: the test environment eager loads the app only when `CI` is set.

## Dependency vulnerabilities

Two models, on purpose.

**JavaScript: judge the pull request, track the rest.**

| Role | Mechanism | Where |
| --- | --- | --- |
| Gate | `dependency_review` blocks vulnerabilities a PR introduces | `.github/workflows/ci.yml` |
| Inventory | Dependabot alerts list vulnerabilities in dependencies already installed | GitHub: Security tab |
| Fix | Dependabot security updates open a PR when a patched version exists | GitHub settings |
| Accepted risk | An alert with no fix is dismissed as "Risk is tolerable" with a written justification and a revisit condition | GitHub: the alert's history |

Yarn 1's `yarn audit` was dropped because it can't accept a single advisory: an unfixable, unreachable vulnerability
either breaks every build or gets hidden with a severity-wide filter. Example: GHSA-vfj7-8cjw-p6xm (`braces`, no patch)
is reached only through the Tailwind CLI file watcher at build time with our own glob patterns, and `node_modules` is
removed before the production image; it is dismissed with that justification and will be revisited when a fix ships.

**Ruby: any known vulnerability breaks the build.** `bundler-audit` stays blocking. Gems usually ship fixes quickly, and
an exception can be recorded per advisory in versioned config if one is ever needed.

Dependabot version updates (weekly PRs for bundler, npm and GitHub Actions) are separate from security updates; see
`.github/dependabot.yml`.

## Supply chain

- Every action is pinned to a full commit SHA with its version in a comment; Dependabot updates both.
  Tags can be moved by an action's owner, as in the 2025 tj-actions/changed-files incident.
- The runner is pinned (`ubuntu-24.04`) and upgraded deliberately by PR.
- The workflow token is `contents: read`; a job that needs more declares its own `permissions`.
- Superseded runs are cancelled on pull requests only; runs on `main` always finish.

## Running checks locally

```sh
bin/ci                                        # setup, RuboCop, bundler-audit, Brakeman, RSpec
bundle exec undercover --compare origin/main  # after `bundle exec rspec`
open coverage/index.html                      # coverage report
```

`bin/ci` doesn't cover everything: dependency review, CodeQL and CodeRabbit need GitHub, so they only run on pull
requests. The lockfile check (`scan_js`) also runs only in GitHub Actions; `bin/setup` installs with
`yarn install --check-files`, which verifies installed files but doesn't fail on a stale `yarn.lock`.
