#!/usr/bin/env bash
# ==============================================================================
# KpihX ZSH Environment TOTAL PURGE Utility
# ==============================================================================
# Safely reverts shell to bash and removes ALL Zsh/Oh-My-Zsh artifacts.
# Includes ALL dependencies installed during setup.
# WARNING: This script is 100% INTERACTIVE for safety.
# ==============================================================================

set -euo pipefail

# --- Configuration ------------------------------------------------------------
TARGET_USER="${1:-${SUDO_USER:-$USER}}"
HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6)

if [[ -z "$HOME_DIR" ]]; then
    echo "Error: Could not resolve home directory for user $TARGET_USER"
    exit 1
fi

echo "--- STARTING TOTAL PURGE OF ZSH ENVIRONMENT FOR $TARGET_USER ---"

confirm() {
    local msg=$1
    read -p "$msg [y/N]: " resp
    if [[ "$resp" =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# --- 1. Shell Reversion -------------------------------------------------------
BASH_PATH=$(command -v bash || echo "/bin/bash")
CURRENT_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7)

if [[ "$CURRENT_SHELL" =~ "zsh" ]]; then
    if confirm "Revert default shell to bash for $TARGET_USER?"; then
        sudo chsh -s "$BASH_PATH" "$TARGET_USER"
    fi
fi

# --- 2. Comprehensive Artifact Cleanup ----------------------------------------
echo "Checking for configuration debris in $HOME_DIR..."

if [ -d "$HOME_DIR/.oh-my-zsh" ]; then
    if confirm "Remove Oh-My-Zsh directory?"; then sudo rm -rf "$HOME_DIR/.oh-my-zsh"; fi
fi

if [ -f "$HOME_DIR/.zshrc" ]; then
    if confirm "Remove .zshrc?"; then sudo rm -f "$HOME_DIR/.zshrc"; fi
fi

if [ -f "$HOME_DIR/.zsh_history" ]; then
    if confirm "Remove .zsh_history?"; then sudo rm -f "$HOME_DIR/.zsh_history"; fi
fi

# Wildcard cleanup for completion and backups
sudo -u "$TARGET_USER" bash -c "rm -f ${HOME_DIR}/.zcompdump* ${HOME_DIR}/.zshrc.pre-oh-my-zsh*" || true

# --- 3. Package Purge ---------------------------------------------------------
purge_package() {
    local pkg=$1
    if confirm "Uninstall/PURGE package '$pkg'?"; then
        sudo apt-get purge -y "$pkg" 2>/dev/null || echo "Package $pkg not found or could not be purged."
    fi
}

echo "Starting system package purge check..."
purge_package "micro"
purge_package "make"
purge_package "curl"
purge_package "fzf"
purge_package "bc"
purge_package "trash-cli"
purge_package "git"
purge_package "zsh"

# --- 4. Final Cleanup ---------------------------------------------------------
if confirm "Run apt-get autoremove?"; then
    sudo apt-get autoremove -y
fi

echo "=============================================================================="
echo " TOTAL PURGE CYCLE COMPLETE FOR $TARGET_USER."
echo " All selected debris and packages have been removed."
echo "=============================================================================="
