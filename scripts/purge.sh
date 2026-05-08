#!/usr/bin/env bash
# ==============================================================================
# KpihX ZSH Environment Purge Utility
# ==============================================================================
# Safely reverts shell to bash and removes all Zsh/Oh-My-Zsh artifacts.
# Usage: sudo ./purge.sh [-y] [TARGET_USER]
# ==============================================================================

set -euo pipefail

# --- Configuration ------------------------------------------------------------
YES_TO_ALL=false
USER_ARG=""

for arg in "$@"; do
    if [[ "$arg" == "-y" ]]; then
        YES_TO_ALL=true
    else
        USER_ARG="$arg"
    fi
done

TARGET_USER="${USER_ARG:-${SUDO_USER:-$USER}}"
HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6)

if [[ -z "$HOME_DIR" ]]; then
    echo "Error: Could not resolve home directory for user $TARGET_USER"
    exit 1
fi

echo "--- Starting deep purge of ZSH for $TARGET_USER ---"

confirm() {
    if [[ "$YES_TO_ALL" == "true" ]]; then return 0; fi
    read -p "$1 (y/N): " response
    [[ "$response" =~ ^[Yy]$ ]]
}

# --- 1. Revert Shell to Bash --------------------------------------------------
BASH_PATH=$(command -v bash)
CURRENT_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7)

if [[ "$CURRENT_SHELL" != "$BASH_PATH" ]]; then
    if confirm "Revert default shell to bash for $TARGET_USER?"; then
        sudo chsh -s "$BASH_PATH" "$TARGET_USER"
    fi
fi

# --- 2. Remove Config Files & Folders -----------------------------------------
ARTIFACTS=(
    ".zshrc"
    ".zshrc.pre-oh-my-zsh"
    ".oh-my-zsh"
    ".zcompdump*"
    ".zsh_history"
    ".zsh_sessions"
)

if confirm "Delete ZSH configuration files and Oh-My-Zsh folder in $HOME_DIR?"; then
    for item in "${ARTIFACTS[@]}"; do
        # Use a subshell to expand wildcards correctly in user home
        sudo -u "$TARGET_USER" bash -c "rm -rf ${HOME_DIR}/${item}"
    done
fi

# --- 3. Uninstall Zsh Package -------------------------------------------------
if command -v zsh >/dev/null || dpkg -l | grep -qw zsh; then
    if confirm "Uninstall/Purge 'zsh' package from system?"; then
        sudo apt-get purge -y zsh
    fi
fi

# --- 4. Cleanup ---------------------------------------------------------------
if confirm "Run apt-get autoremove to clean dependencies?"; then
    sudo apt-get autoremove -y
fi

echo "=============================================================================="
echo " SUCCESS: ZSH purge complete for $TARGET_USER."
echo " IMPORTANT: Please log out and back in to finalize the shell transition."
echo "=============================================================================="
