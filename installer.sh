#!/bin/bash

# Update system
sudo apt update
sudo apt upgrade -y

# Install essential tools
sudo apt install -y build-essential htop curl git

# Ensure .config directory exists
mkdir -p ~/.config

# 1. Install zsh and shell dependencies
if ! command -v zsh &> /dev/null; then
    sudo apt install -y zsh
else
    echo "zsh is already installed"
fi

sudo apt install -y fzf zoxide ripgrep fd direnv eza nnn zsh-syntax-highlighting zsh-autosuggestions

# Copy .zshrc if it doesn't already exist
if [ ! -f ~/.zshrc ]; then
    cp ./.zshrc ~
else
    echo ".zshrc already exists, skipping copy"
fi

# 2. Starship prompt
if ! command -v starship &> /dev/null; then
    sudo apt install -y starship
else
    echo "starship is already installed"
fi
cp ./starship.toml ~/.config/starship.toml

# 3. Tmux
if ! command -v tmux &> /dev/null; then
    sudo apt install -y tmux
else
    echo "tmux is already installed"
fi
cp tmux ~/.config/tmux

# 4. Neovim
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz # OS dependent, TODO add a mac macro
mkdir -p ~/opt
tar -xzvf nvim-linux-x86_64.tar.gz -C ~/opt
rm nvim-linux-x86_64.tar.gz

#5. git
cp git ~/.config/

# change shell to zsh
chsh -s $(which zsh) $(whoami)
