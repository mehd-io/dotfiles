---
name: mdorg
description: Run commands against a specific MotherDuck organization with the `mdorg` command. Use when the user asks to switch MotherDuck org, query or test against another org or environment, or when a task needs a MotherDuck token for a particular org.
---

# mdorg: target a MotherDuck organization

`mdorg` picks which MotherDuck organization a command talks to. Orgs are declared in a
private config (`~/.config/dotfiles/mdorg.conf`); tokens are resolved from 1Password on
demand.

## How to use it as an agent

Environment variables do not survive between your shell calls, so do not rely on
`mdorg use`. Wrap every command instead:

```sh
mdorg ls                                              # discover the configured orgs
mdorg run <org> -- duckdb md: -c "select current_user"
mdorg run <org> -- <any command that reads motherduck_token>
```

`mdorg run` sets, for that one command only:

- `motherduck_token` and `MOTHERDUCK_TOKEN`
- `MD_ORG`: the org name
- `motherduck_host`: only for orgs whose config sets a non-default API `host`
- `MOTHERDUCK_APP_URL`: the org's web UI

## Rules

- Run `mdorg ls` to learn the org names. Do not guess them and do not hard-code hosts or
  URLs; they come from the config.
- If the request does not say which org, ask. Do not fall back to production silently.
- Never print, log, or write a token. That rules out `mdorg env`, `env`, `printenv`, and
  `echo $motherduck_token` in your shell calls. Do not read the resolved cache file or
  `mdorg.conf` either.
- Before a write against production (`CREATE`, `INSERT`, `UPDATE`, `DELETE`, `DROP`,
  `ATTACH` changes, share changes), confirm with the user.
- MotherDuck MCP servers keep their own sign-in. `mdorg` does not change which org they
  use; check with their `get_connection_info` tool.

## For the human

In an interactive shell, `mdorg use <org>` switches the current shell and bare `mdorg`
opens a picker. `mdorg open [org]` opens the web UI and `mdorg refresh` re-reads tokens
from 1Password.

## Troubleshooting

- `could not resolve tokens from 1Password`: the 1Password CLI is locked or signed out.
  Ask the user to unlock it; do not look for the token elsewhere.
- `unknown org`: run `mdorg ls`.
- `token ... is still a placeholder`: the user has not filled in `mdorg.conf`.
