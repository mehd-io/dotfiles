#!/bin/sh
# Script install packages requirements, config files (with symlinks), font and Colors

DOTFILES=$HOME/.dotfiles
BACKUP_DIR=$HOME/dotfiles-backup

echo "=============================="
echo -e "\n\nBackup existing config ..."
echo "=============================="
echo "Creating backup directory at $BACKUP_DIR"
mkdir -p $BACKUP_DIR

linkables=$( find -H "$DOTFILES" -maxdepth 3 -name '*.symlink' )

# backup up any existing dotfiles in ~ and symlink new ones from .dotfiles
for file in $linkables; do
    filename=".$( basename $file '.symlink' )"
    target="$HOME/$filename"
    if [ -f $target ]; then
        echo "backing up $filename"
        cp $target $BACKUP_DIR
    else
        echo -e "$filename does not exist at this location or is a symlink"
    fi
done

# backup from .config
folders_to_backup=("borders" "alacritty")

# Loop through each folder and back it up
for folder in "${folders_to_backup[@]}"; do
    original_folder="$HOME/.config/$folder"
    backup_folder="${original_folder}_backup"

    if [ -d "$original_folder" ]; then
        mv "$original_folder" "$backup_folder"
        echo "Backed up $folder to ${folder}_backup"
    else
        echo "Folder $folder does not exist, skipping..."
    fi
done


echo "=============================="
echo -e "\n\nInstalling packages ..."
echo "=============================="

package_to_install="neovim
    tmux
    tree
    wget
    zsh
    curl
    starship
"
 if cat /etc/*release | grep ^NAME | grep CentOS; then
    echo "==============================================="
    echo "Installing packages $package_to_install on CentOS"
    echo "==============================================="
    yum install -y $package_to_install
 elif cat /etc/*release | grep ^NAME | grep Red; then
    echo "==============================================="
    echo "Installing packages $package_to_install on RedHat"
    echo "==============================================="
    yum install -y $package_to_install
 elif cat /etc/*release | grep ^NAME | grep Fedora; then
    echo "================================================"
    echo "Installing packages $package_to_install on Fedorea"
    echo "================================================"
    yum install -y $package_to_install
 elif cat /etc/*release | grep ^NAME | grep Ubuntu; then
    echo "==============================================="
    echo "Installing packages $package_to_install on Ubuntu"
    echo "==============================================="
    apt-get update
    apt-get install -y $package_to_install
 elif cat /etc/*release | grep ^NAME | grep Debian ; then
    echo "==============================================="
    echo "Installing packages $package_to_install on Debian"
    echo "==============================================="
    apt-get update
    apt-get install -y $package_to_install
 elif cat /etc/*release | grep ^NAME | grep Mint ; then
    echo "============================================="
    echo "Installing packages $package_to_install on Mint"
    echo "============================================="
    apt-get update
    apt-get install -y $package_to_install
 elif cat /etc/*release | grep ^NAME | grep Knoppix ; then
    echo "================================================="
    echo "Installing packages $package_to_install on Kanoppix"
    echo "================================================="
    apt-get update
    apt-get install -y $package_to_install
 elif uname -s | grep Darwin ; then
    echo "================================================="
    echo "Installing packages $package_to_install on Mac OS"
    echo "================================================="
    brew update
    brew install $package_to_install
 else
    echo "OS NOT DETECTED, couldn't install package $package_to_install"
    exit 1;
 fi

echo "================================================="
echo "Symlink zsh theme, tmux.conf, zshrc"
echo "================================================="
echo "Symlinking dotfiles"
ln -s -f $DOTFILES/zsh/zshrc.symlink $HOME/.zshrc
ln -s -f $DOTFILES/zsh/zprofile.symlink $HOME/.zprofile
ln -s $DOTFILES/tmux/tmux.conf.symlink $HOME/.tmux.conf
ln -s $DOTFILES/tmux/tmux.conf.local.symlink $HOME/.tmux.conf.local
mkdir -p $HOME/.config/borders
ln -s $DOTFILES/borders/bordersrc.symlink $HOME/.config/borders/bordersrc

# Symlink Ghostty config
mkdir -p $HOME/.config/ghostty
ln -s -f $DOTFILES/ghostty/config $HOME/.config/ghostty/config

# Symlink Starship config
ln -s -f $DOTFILES/starship/starship.toml $HOME/.config/starship.toml

#default bash is zsh
chsh -s /bin/zsh

echo "================================================="
echo "Install & configure terminal"
echo "=================================================" 
brew install --cask ghostty

echo "================================================="
echo "Install hiddenbar & stats"
echo "================================================="
brew install --cask hiddenbar
brew install --cask stats

echo "================================================="
echo "Install LazyVim (Neovim config)"
echo "================================================="
git clone https://github.com/LazyVim/starter ~/.config/nvim
rm -rf ~/.config/nvim/.git
echo "LazyVim installed! Start Neovim with 'nvim' and refer to the comments in the files to customize."
