# Conventions

Working rules for this repository: how we work day to day. Architecture decisions go in `docs/adr/`.

## Generated code

`rails new` generates more than an app needs. The rule: **delete dead code, but keep files that track
Rails templates close to the generated version.**

### What gets pruned

Anything the app doesn't use, together with whatever it brought along. Removed so far:

| Removed | Why |
| --- | --- |
| `jbuilder` | No JSON API planned |
| `image_processing` (with `mini_magick`, `ruby-vips`, `ffi`) | No Active Storage image variants |
| `libvips` in the `Dockerfile` | Only needed by `image_processing`; the production image no longer ships an unused native library |
| PWA scaffolding (`app/views/pwa/`, routes, manifest tag, `*-web-app-capable` meta tags) | The app isn't meant to be installed |
| Generated comments in `config/database.yml` and `config/routes.rb` | These files are ours now; generic instructions live in the Rails guides |

Dead code means commented-out code and unused files. Git keeps the history; the codebase doesn't need to.

### What stays on purpose

- **Template-tracked files**: `config/environments/*.rb`, `config/puma.rb`, `config/application.rb`.
  On every Rails upgrade, `bin/rails app:update` diffs them against the new templates. Heavily edited files turn
  that diff into noise, and real upgrade changes get missed. Real configuration changes are welcome
  (for example `force_ssl` when we deploy); stripping their comments and commented-out options is not.
- **Active Storage**: unused today and kept for now. The invoice PDF (Phase 2) may need to store files.
  Disabling it means editing `config/application.rb`, so the call is made when the PDF ticket starts.

### Adding and removing gems

- **A gem enters only when a ticket needs it**, in that ticket's PR, with the reason in the PR description.
  Nothing is added because it might be useful later.
- **When a gem leaves, so does what it brought outside Ruby.** Read its README for system requirements and follow the
  chain in `Gemfile.lock`. A gem named after a C library (`ruby-vips`, `pg`) or depending on `ffi` usually needs a
  system package. Then search the repo for its name (`git grep -n <name>`): the `Dockerfile`, initializers, environment
  variables and CI.
- **When removing a feature, read the surrounding file, not just the search results.** A keyword search finds what has
  the name, not what has the purpose: the PWA meta tags never mentioned "pwa".

## Comments

A comment earns its place by saying something the code can't:

- **Why a decision was made.** Example: why the local database port is 5434 and not 5432.
- **A trap for the next reader.** Example: exporting `DATABASE_URL` can point the test suite at the development
  database.
- **A pointer to the full story.** A link to the official guide for a DSL or option, or a reference to the ADR
  behind the code (for example `# See ADR-0006` next to the daily close). The comment stays one line;
  the guide or ADR holds the explanation.

Comments that restate what the code does, or copy framework documentation into the file, get deleted.
A link to that documentation is fine.
