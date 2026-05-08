#!/usr/bin/env bash
set -e

# Usage: ./purge.sh [-y] [TARGET_USER]
YES_TO_ALL=false
TARGET_USER=""

for arg in "$@"; do
    if [ "$arg" == "-y" ]; then
        YES_TO_ALL=true
    else
        TARGET_USER="$arg"
    fi
done

TARGET_USER="${TARGET_USER:-$USER}"

if [ "$TARGET_USER" = "root" ]; then
    HOME_DIR="/root"
else
    HOME_DIR="/home/$TARGET_USER"
fi

confirm() {
    local msg=$1
    if [ "$YES_TO_ALL" = true ]; then
        return 0
    fi
    read -p "$msg [y/N]: " resp
    if [[ "$resp" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

echo "Purging ZSH and environment for user: $TARGET_USER"

# 1. Change shell back to bash
if getent passwd "$TARGET_USER" | grep -q "/zsh$"; then
    if confirm "Revert default shell to bash?"; then
        sudo chsh -s "$(which bash)" "$TARGET_USER"
    fi
fi

# 2. Remove Oh-My-Zsh directory
if [ -d "$HOME_DIR/.oh-my-zsh" ]; then
    if confirm "Remove Oh-My-Zsh?"; then
        sudo rm -rf "$HOME_DIR/.oh-my-zsh"
    fi
fi

# 3. Remove configs
if [ -f "$HOME_DIR/.zshrc" ]; then
    if confirm "Remove .zshrc?"; then
        sudo rm -f "$HOME_DIR/.zshrc"
    fi
fi

# 4. Uninstall packages
purge_package() {
    local pkg=$1
    # Check if command exists OR package is installed (ii)
    if command -v "$pkg" >/dev/null || dpkg -l | grep -qw "$pkg"; then
        if confirm "Uninstall/Purge package '$pkg'?"; then
            sudo apt-get purge -y "$pkg"
        fi
    fi
}

# Intermediate tools
purge_package "micro"
purge_package "make"
purge_package "curl"
purge_package "fzf"
purge_package "bc"
purge_package "trash-cli"

# ZSH as the final step
purge_package "zsh"

if confirm "Run autoremove?"; then
    sudo apt-get autoremove -y
fi

echo "ZSH purge cycle complete for $TARGET_USER! Please log out and back in to see the bash shell."
