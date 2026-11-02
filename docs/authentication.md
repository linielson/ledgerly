# Authentication

How signing in works in Ledgerly, and why each piece is the way it is. The code comes from the Rails 8 authentication
generator (`bin/rails generate authentication`, T-201), reviewed and trimmed. Tenants, roles and invitations build on
it in the rest of E2.

## The pieces

| File                                           | Role                                                                             |
| ---------------------------------------------- | -------------------------------------------------------------------------------- |
| `app/models/user.rb`                           | An account: `email_address` and `password_digest`, with `has_secure_password`    |
| `app/models/session.rb`                        | One row per sign-in: which user, from which IP and browser                       |
| `app/models/current.rb`                        | Per-request state (`Current.session`, `Current.user`), reset after every request |
| `app/controllers/concerns/authentication.rb`   | Requires a signed-in user on every action unless a controller opts out           |
| `app/controllers/sessions_controller.rb`       | Sign in (`create`) and sign out (`destroy`)                                      |
| `app/controllers/passwords_controller.rb`      | Password reset: request a link, then set a new password                          |
| `app/mailers/passwords_mailer.rb`              | The reset email                                                                  |
| `app/channels/application_cable/connection.rb` | The same check for WebSocket connections (Action Cable)                          |

## Signing in

1. `GET /session/new` shows the form. `POST /session` calls `User.authenticate_by(email_address:, password:)`.
2. On success, `start_new_session_for(user)` creates a `Session` row and stores its id in a cookie.
3. On every later request, `require_authentication` reads the cookie, finds the `Session` and puts it in
   `Current.session`. With no valid session, it remembers the URL and redirects to the sign-in page.
4. `DELETE /session` destroys the row and deletes the cookie.

## Why these choices

### Server-side sessions in the database, not JWTs

The cookie holds only a session id. Everything else lives in the `sessions` table.

- **Revocable:** deleting the row signs the browser out at once. A password reset destroys all of a user's sessions.
  A JWT stays valid until it expires, unless you build a deny-list, which is a sessions table again.
- **Visible:** each session records its IP and user agent, so a "your devices" page or an audit is one query away.
- The cost is one indexed lookup per request, which this app already pays for its data.

### The cookie: signed, `httponly`, `same_site: :lax`, permanent

- **Signed** with the app's `secret_key_base`, so a user can't change the id to someone else's. Signed, not
  encrypted: the id isn't secret, it only must not be forged.
- **`httponly`:** JavaScript can't read it, so a cross-site scripting bug can't steal the session.
- **`same_site: :lax`:** the browser doesn't send it on cross-site form posts or background requests, which blocks most
  cross-site request forgery. It is still sent when the user follows a link from another site, so links into the app
  keep working.
- **`secure`:** with `force_ssl` in production, Rails marks cookies as HTTPS-only.
- **Permanent:** about 20 years. The session row, not the cookie, decides whether the session is valid.

### Sessions expire

A session that never ends is a risk in a financial app: a forgotten signed-in laptop would keep access to every
invoice. So a session expires:

- after **14 days without activity**, so someone who uses the app daily never notices, but an abandoned browser loses
  access;
- **30 days after sign-in**, even if it is used every day, which caps how long a stolen session is useful.

An expired session is deleted when it is next presented, and the browser is sent to sign in. A daily job
(`PurgeExpiredSessionsJob`, scheduled in `config/recurring.yml`) deletes the ones that are never presented again, so
the table doesn't grow forever. Recording activity writes to the database, so it is done at most about once an hour
per session rather than on every request.

### Passwords: bcrypt through `has_secure_password`

- **bcrypt** is a slow, salted, adaptive hash. The salt is random per password and stored inside the digest, so equal
  passwords get different digests and precomputed tables don't help an attacker. The **cost** (12 by default, about
  220 ms per hash on a laptop) makes guessing millions of passwords from a leaked table expensive, and it can be raised
  as hardware gets faster.
- In tests, Rails sets the minimum cost (4, about 1 ms), so specs that create users stay fast.
- bcrypt only reads the first **72 bytes**. `has_secure_password` rejects longer passwords instead of silently
  ignoring the rest, and the form limits the field to 72.
- Argon2 is the newer recommendation for new systems, but bcrypt is Rails' default and still sound. Changing it isn't
  worth a gem and custom code here.

### `authenticate_by` resists timing attacks and user enumeration

If the email doesn't exist, `User.authenticate_by` still hashes the password against a blank record before returning
`nil`. Both cases take about the same time, so response times don't reveal which emails have accounts. The error
message is the same too: "Try another email address or password." The password reset form answers "instructions sent
(if user with that email address exists)" for the same reason.

### Password reset tokens: signed, short-lived, single-use in effect

`has_secure_password` adds `password_reset_token` and `find_by_password_reset_token!` (through `generates_token_for`).

- The token is signed by the app, so it can't be forged. Nothing is stored in the database.
- It expires after **15 minutes**.
- It embeds part of the password's salt. Once the password changes, the salt changes and every old token stops
  working, which makes a used link useless without a `used_at` column.
- After a reset, all of the user's sessions are destroyed, so a stolen session dies with the old password.

### Rate limiting

`rate_limit to: 10, within: 3.minutes` on sign-in and on reset requests slows down password guessing and email
flooding. The counts live in the controllers' cache store, which is Solid Cache in production. The store is captured
when the controller class loads, and the test environment's `:null_store` stores nothing, so the limit could never
trigger in specs. The test environment gives controllers a memory store instead
(`config.action_controller.cache_store`), and `rails_helper` clears it before every example.

### CSRF and CORS

- **CSRF (cross-site request forgery):** another site tricks a signed-in browser into submitting a form to Ledgerly.
  Rails blocks it with an authenticity token in every form (`csrf_meta_tags` in the layout, `protect_from_forgery`
  on by default) and the `same_site: :lax` cookie adds a second layer.
- **CORS (cross-origin resource sharing)** is the opposite direction: it lets JavaScript on another origin read
  responses from this app. Ledgerly serves its own pages and has no public JSON API, so CORS stays off (no
  `rack-cors`). Turning it on would only widen what other sites can do.

### `Current` attributes

`Current` is an `ActiveSupport::CurrentAttributes`: values that belong to the request being served, reset
automatically when it ends. It saves passing the user through every method. In T-203 it also gets `Current.tenant`,
the base of tenant scoping. Use it at the edges (controllers, jobs that set it explicitly), not as a hidden global
deep in models.

### WebSockets

Turbo Streams broadcasts travel over Action Cable (Solid Cable in production). `ApplicationCable::Connection` reads
the same signed `session_id` cookie and rejects the connection without a valid session, so live updates follow the
same rule as pages.

## Known gaps, tracked

- **Email delivery in production** isn't configured yet. The reset email is queued but has nowhere to go until
  T-205 (#52) picks a provider.
- **Sign-up** arrives with tenants in T-202 (#49). Until then, users are created from the console or seeds.
