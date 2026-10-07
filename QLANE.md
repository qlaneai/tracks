# qlane test fork

This fork of [TracksApp/tracks](https://github.com/TracksApp/tracks) exists only as a test target for
qlane. It is a server-rendered Rails app that qlane boots with Docker Compose in an ephemeral sandbox.
Nothing here is meant to go upstream.

## What it adds

- `docker-compose.qlane.yml`: builds the `production` image target with a MariaDB `db`. It mounts
  `config/site.docker.yml` from a literal path, with no whole-repo mount over `/app`. It creates the
  schema with `bin/rails db:prepare` before the server starts, and serves on port 3000.
- `script/qlane_seed.rb`: run by the `ai.qlane.postdeploy` label after boot. It creates the users
  below and is safe to run more than once.
- `.env.example`: the variables the test target must set, all empty.
- This file.

The app's own settings are unchanged. In particular, `open_signups` stays `false`, as committed in
`config/site.docker.yml`.

## Variables to register on the test target

No secret or password is committed. Register these on the qlane test target. The stack refuses to
start while any of them is unset or empty.

| Variable          | What it is                                  |
| ----------------- | ------------------------------------------- |
| `SECRET_KEY_BASE` | Rails' `secret_key_base`, 64+ characters    |
| `QA_PASSWORD`     | Password of `qatester`, 5 to 72 characters  |
| `ADMIN_PASSWORD`  | Password of `admin`, 5 to 72 characters     |

## Logins

| Login      | Password         | Admin |
| ---------- | ---------------- | ----- |
| `qatester` | `QA_PASSWORD`    | no    |
| `admin`    | `ADMIN_PASSWORD` | yes   |

Use `qatester` for testing. It is not an admin, so `/signup` shows the "no signups" page. The admin is
created first, so `qatester` is never the first user.

## Run it locally

Export the three variables above in your shell, then:

```sh
docker compose -f docker-compose.qlane.yml up -d --build
docker compose -f docker-compose.qlane.yml exec -T web sh -c './docker-entrypoint.sh bin/rails runner script/qlane_seed.rb'
```

Then open <http://localhost:3000/login>.
