# dotfiles

> ⚠️ **Warning: This branch is no longer actively maintained.**
>
> The existing configuration of yabai & sketchybar should still work, but please note:
>
> - Since macOS 15.2, using Yabai for critical features I needed requires disabling SIP (System Integrity Protection).
> - For a more secure and up-to-date setup, I have migrated to [Aerospace](https://github.com/nikitabobko/Aerospace).
> - You can find the latest Aerospace configuration and a walkthrough video on the [`main` branch](https://github.com/mehd-io/dotfiles/tree/main).
>
> [![Aerospace Window Manager Deep Dive](https://img.youtube.com/vi/gjR2eiomRwo/0.jpg)](https://www.youtube.com/watch?v=gjR2eiomRwo)


## Getting Started

### Prerequisite
The install script backup the existing configuration file, but read below before running it ! 
Requirements : 
* git
* brew (on MacOs)
* zsh 5.0.5 minum (otherwise space-ship theme will not recognize some colors)
** tested on MacOs/Ubuntu/Debian/Centos

### Install
```
git clone https://github.com/mehd-io/dotfiles ~/.dotfiles
cd ~/.dotfiles
./install.sh
./install_sketchybar.sh
```
Update the spark-shell path in dotfiles/vim/ftplugin/python.vim.symlink & dotfiles/vim/ftplugin/scala.vim.symlink

### Terminal configuration : color & fonts
* Fonts used "DejaVu Sans Mono for Powerline.ttf" and  "Inconsolata for Powerline.otf" are in terminal/fonts folder
* colors used "FrontEndDelight" are in terminal/colors folder (iterm2) for more colors or other terminal support, check : https://github.com/mbadolato/iTerm2-Color-Schemes

## About install.sh
The repo contains all configuration I use with tmux, zsh, and vim.

The install script does the following  :
* Install required package depending on OS (tmux/zsh/oh-my-zsh/vim)
* Install vim plugins
* Symlink tmux.conf, .zshrc, .vimrc, and a theme of oh-my-zsh (spaceship)

## Oh-my-zsh theme : spaceship
Spaceship is a highly flexible theme of oh my zsh, for more info : https://github.com/denysdovhan/spaceship-zsh-theme

## Tmux
command key remapped from ctrl+b to ctrl+a
Using theme from : https://github.com/gpakosz/.tmux

## To do
* add screenshots


