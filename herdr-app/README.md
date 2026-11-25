# herdr-app

My Herdr App setup: everything under `~/.config/herdr-app` that Herdr
doesn't ship. The `mehdi` layout, keys, settings, programs, icons, a theme,
and two small helper mods (`popup-terminal`, `yazi-popup`).

Edit here, then install. Never edit the installed copies:
`herdr-sync` flags it when that happens.

```sh
./install.sh --herdr-app     # from the dotfiles root: copy + check, link herdr-sync
herdr-app/install.sh --mods  # only the mods
herdr-sync                   # who owns each personal mod/file, and any drift
herdr-sync -d NAME           # diff one mod, repo vs installed
```

Files that `install.sh` replaces are backed up first to
`~/.config/herdr-app/.herdr-setup-backup/<timestamp>/`.

The layout and keys also use mods that live in their own `herdr-<name>`
repos (each with an `install-mods.sh`). Without those installed, Herdr shows
an empty block where they would be.

## Where mods live

| Tier | Where |
|---|---|
| 0 personal | here |
| 1 companion | the repo of the tool the mod fronts, under `mods/` |
| 2 open-source candidate | its own private `herdr-<name>` repo |
| 3 published | public repo with the `herdr-mod` topic, listed on herdr.dev |

Going from tier 2 to 3: no hardcoded `~/repos/...` paths (find tools on PATH),
no hard dependency on other private tools, a `RECIPE.md` and `preview.png`,
a secret scan, and a reviewed diff.

`herdr-app` needs to reach its socket: in Claude Code, run these with the
sandbox off.
