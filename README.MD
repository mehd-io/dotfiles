# dotfiles : tmux, zsh, aerospace, sketchybar

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
./install_aerospace.sh
```
Update the spark-shell path in dotfiles/vim/ftplugin/python.vim.symlink & dotfiles/vim/ftplugin/scala.vim.symlink

### Terminal configuration : color & fonts
* Fonts used "DejaVu Sans Mono for Powerline.ttf" and  "Inconsolata for Powerline.otf" are in terminal/fonts folder
* colors used "FrontEndDelight" are in terminal/colors folder (iterm2) for more colors or other terminal support, check : https://github.com/mbadolato/iTerm2-Color-Schemes

## About install.sh
The repo contains all configuration I use with tmux, zsh, and vim.

The install script does the following  :
* Install required package depending on OS (tmux/zsh/oh-my-zsh/vim)
* Symlink tmux.conf, .zshrc, .vimrc, and a theme of oh-my-zsh (spaceship)

## Oh-my-zsh theme : spaceship
Spaceship is a highly flexible theme of oh my zsh, for more info : https://github.com/denysdovhan/spaceship-zsh-theme

## Tmux
command key remapped from ctrl+b to ctrl+a
Using theme from : https://github.com/gpakosz/.tmux


