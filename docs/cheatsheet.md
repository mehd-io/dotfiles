# Cheatsheet

## tmux (prefix = `` ` ``)

### Windows & Panes
| Key | Action |
|-----|--------|
| `` ` c `` | New window (at $HOME) |
| `` ` N `` | New window (current path) |
| `` ` - `` | Split horizontal |
| `` ` | `` | Split vertical |
| `` ` q `` | Kill window (confirm) |

### Navigation (vim-style)
| Key | Action |
|-----|--------|
| `` ` h/j/k/l `` | Navigate panes |
| `` ` H/J/K/L `` | Resize panes (repeatable) |

### Claude Code
| Key | Action |
|-----|--------|
| `` ` C `` | New window with Claude |
| `` ` V `` | Vertical split with Claude |

### Editor & Tools
| Key | Action |
|-----|--------|
| `` ` n `` | Toggle nvim + Neotree (open/close) |
| `` ` U `` | Open URLs from pane (devcontainer/ports) |
| `` ` L `` | Toggle log pane |
| `` ` e `` | Edit tmux.conf.local |
| `` ` r `` | Reload tmux config |

### Pane Borders
Each pane border shows: `branch | process:port | dc http://localhost:PORT`

---

## Neovim (LazyVim)

### Core
| Key | Action |
|-----|--------|
| `<Space>` | Leader key |
| `<Space>e` | Toggle Neo-tree explorer |
| `<Space>E` | Neo-tree in root dir |

### Find & Search
| Key | Action |
|-----|--------|
| `<Space><Space>` | Find files |
| `<Space>ff` | Find files |
| `<Space>fg` | Find files (git) |
| `<Space>fr` | Recent files |
| `<Space>/` | Grep in project |
| `<Space>sg` | Grep (Telescope) |
| `<Space>sw` | Search word under cursor |

### Code
| Key | Action |
|-----|--------|
| `gd` | Go to definition |
| `gr` | References |
| `K` | Hover documentation |
| `<Space>ca` | Code action |
| `<Space>cr` | Rename symbol |
| `<Space>cf` | Format |

### Git
| Key | Action |
|-----|--------|
| `<Space>gg` | LazyGit |
| `<Space>gf` | Git file history |
| `]h` / `[h` | Next/prev hunk |

### Buffers & Tabs
| Key | Action |
|-----|--------|
| `<S-h>` / `<S-l>` | Prev/next buffer |
| `<Space>bd` | Delete buffer |
| `<Space>,` | Switch buffer (picker) |

### Diagnostics
| Key | Action |
|-----|--------|
| `<Space>xx` | Diagnostics (Trouble) |
| `]d` / `[d` | Next/prev diagnostic |

---

## zsh

| Key | Action |
|-----|--------|
| `Ctrl+G` | Fuzzy repo picker (fzf) |
| `Ctrl+R` | History search (atuin) |
| `z <dir>` | Smart cd (zoxide) |
| `zi` | Interactive zoxide |

---

## Claude Code

| Key | Action |
|-----|--------|
| `Esc` | Interrupt Claude |
| `!<cmd>` | Run shell command in session |
| `/plan` | Enter plan mode |
| `/compact` | Compact context |
| `/model` | Switch model |
| `/clear` | Clear conversation |

### Process Guard (auto)
A PreToolUse hook blocks `pnpm dev`, `next dev`, etc. when the port is already in use. Claude is told what's running and must use the existing server or kill it first.

---

## Config Locations

| What | Source (dotfiles) | Symlinked to |
|------|-------------------|-------------|
| tmux config | `~/.dotfiles/tmux/tmux.conf.symlink` | `~/.tmux.conf` |
| tmux local | `~/.dotfiles/tmux/tmux.conf.local.symlink` | `~/.tmux.conf.local` |
| tmux scripts | `~/.dotfiles/tmux/*.sh` | `~/.tmux/*.sh` |
| Claude settings | `~/.dotfiles/claude/settings.json` | `~/.claude/settings.json` |
| zsh | `~/.dotfiles/zsh/zshrc.symlink` | `~/.zshrc` |
| ghostty | `~/.dotfiles/ghostty/config` | `~/.config/ghostty/config` |
| starship | `~/.dotfiles/starship/starship.toml` | `~/.config/starship.toml` |
| neovim | `~/.config/nvim/` | (LazyVim, not in dotfiles) |
