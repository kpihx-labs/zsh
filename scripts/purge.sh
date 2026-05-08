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
ARTIFACTS=(
    ".oh-my-zsh"
    ".zshrc"
    ".zshrc.pre-oh-my-zsh"
    ".zshrc.pre-oh-my-zsh-*"
    ".zsh_history"
    ".zsh_sessions"
    ".zcompdump*"
)

echo "Checking for configuration debris in $HOME_DIR..."
for item in "${ARTIFACTS[@]}"; do
    # Check if anything matches the pattern
    # We use sudo -u to perform the check as the user to handle wildcards correctly
    MATCHES=$(sudo -u "$TARGET_USER" bash -c "ls -d ${HOME_DIR}/${item} 2>/dev/null || true")
    if [[ -n "$MATCHES" ]]; then
        for match in $MATCHES; do
            if confirm "Remove debris: $match?"; then
                sudo rm -rf "$match"
            fi
        done
    fi
done

# --- 3. Package Purge ---------------------------------------------------------
purge_package() {
    local pkg=$1
    # Check if command exists OR if package is explicitly listed as installed/config-present in dpkg
    if command -v "$pkg" >/dev/null 2>&1 || dpkg -l "$pkg" 2>/dev/null | grep -qE "^ii|^rc"; then
        if confirm "Uninstall/PURGE package '$pkg' and its system-wide configs?"; then
            sudo apt-get purge -y "$pkg"
        fi
    fi
}

echo "Starting system package purge check..."
# Order: tools first, core shell last
purge_package "micro"
purge_package "make"
purge_package "curl"
purge_package "fzf"
purge_package "bc"
purge_package "trash-cli"
purge_package "git"
purge_package "zsh"

# --- 4. Final Cleanup ---------------------------------------------------------
if confirm "Run apt-get autoremove to clean up orphaned dependencies?"; then
    sudo apt-get autoremove -y
fi

echo "=============================================================================="
echo " TOTAL PURGE CYCLE COMPLETE FOR $TARGET_USER."
echo " All selected debris and packages have been removed."
echo " Please log out and back in to finalize the environment transition."
echo "=============================================================================="
