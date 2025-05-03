# dotfiles

This dotfiles repository provides a modern, productive, and visually appealing development environment for macOS. It brings together:

- [**aerospace**](https://github.com/nikitabobko/AeroSpace) an i3-like tiling window manager for macOS
- **Sketchybar** (macOS) for a highly customizable status bar, and **Aerospace** for advanced window management.
- **Zsh** as the main shell, with [Starship](https://starship.rs/) prompt using the [Pastel Powerline preset](https://starship.rs/presets/#pastel-powerline) for a fast, informative, and beautiful command line experience.
- **Tmux** for terminal multiplexing, session management, and efficient workflows.
- **Neovim & LazyVim** as a pre-configured, extensible Neovim setup for powerful code editing.
- **Ghostty** as the terminal emulator (macOS), with custom themes and settings.
- **Hiddenbar** and **Stats** (macOS) for menu bar and system monitoring enhancements.
- Sensible defaults, backup and symlink management, and easy setup for new machines.

![Terminal and status bar setup](docs/screenshot.png)
*Example: Starship prompt (Pastel Powerline), Ghostty terminal, and Sketchybar on macOS.*

## Getting Started

### Prerequisite
The install script backs up existing configuration files, but read below before running it!
Requirements:
* git
* brew (on MacOS)
* zsh 5.0.5 minimum (otherwise spaceship/starship themes may not recognize some colors)

### Install
```
git clone https://github.com/mehd-io/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install.sh         # Installs core tools, symlinks configs, sets up Ghostty & Starship, Hiddenbar, Stats, and LazyVim
./install_sketchybar.sh   # Installs Sketchybar and dependencies, sets up config
./install_aerospace.sh    # Installs Aerospace and sets up config
```
Update the spark-shell path in dotfiles/vim/ftplugin/python.vim.symlink & dotfiles/vim/ftplugin/scala.vim.symlink if needed.

### Terminal configuration: color & fonts
* Fonts used: "DejaVu Sans Mono for Powerline.ttf" and  "Inconsolata for Powerline.otf" are in terminal/fonts folder
* Colors used: "FrontEndDelight" are in terminal/colors folder (iterm2). For more colors or other terminal support, check: https://github.com/mbadolato/iTerm2-Color-Schemes

## What each install script does

### install.sh
- Installs required packages depending on OS (neovim, tmux, tree, wget, zsh, curl, starship, etc.)
- Symlinks tmux.conf, .zshrc, .zprofile, and other dotfiles
- Symlinks Ghostty config to ~/.config/ghostty/config
- Symlinks Starship config (Pastel Powerline preset) to ~/.config/starship.toml
- Installs Ghostty terminal (MacOS)
- Installs Hiddenbar and Stats (MacOS)
- Installs LazyVim (clones https://github.com/LazyVim/starter to ~/.config/nvim, removes .git folder)
- Sets default shell to zsh

After running install.sh, start Neovim with:
```
nvim
```
Refer to the comments in the LazyVim config files for customization instructions.

### install_sketchybar.sh
- Installs Sketchybar and its dependencies (sf-symbols, jq, gh)
- Downloads and installs the Sketchybar app font
- Backs up existing Sketchybar config and moves new config into place
- Restarts Sketchybar service

### install_aerospace.sh
- Installs Aerospace (MacOS window manager)
- Backs up existing Aerospace config and moves new config into place

## About Aerospace 

I did a video for a deep dive on this tiling window manager, check this here : 
[![Aerospace Window Manager Deep Dive](https://img.youtube.com/vi/gjR2eiomRwo/0.jpg)](https://www.youtube.com/watch?v=gjR2eiomRwo)

## Starship prompt : Pastel Powerline
This setup uses [Starship](https://starship.rs/) with the [Pastel Powerline preset](https://starship.rs/presets/#pastel-powerline) for a modern, colorful, and informative shell prompt.

## Tmux
command key remapped from ctrl+b to ctrl+a
Using theme from : https://github.com/gpakosz/.tmux
