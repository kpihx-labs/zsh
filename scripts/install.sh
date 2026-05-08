#!/usr/bin/env bash
# ==============================================================================
# KpihX ZSH Environment Installer
# ==============================================================================
# Automated, non-interactive Zsh + Oh-My-Zsh + Plugins installation.
# Handles targeted user home detection and permission alignment.
# ==============================================================================

set -euo pipefail

# --- Configuration ------------------------------------------------------------
# Resolve target user: 
# 1. Argument $1
# 2. $SUDO_USER (if running via sudo)
# 3. Current $USER
TARGET_USER="${1:-${SUDO_USER:-$USER}}"
# Resolve home directory safely without assuming /home/
HOME_DIR=$(getent passwd "$TARGET_USER" | cut -d: -f6)
TEMPLATE_PATH="${2:-$(dirname "$0")/../assets/zshrc.template}"

if [[ -z "$HOME_DIR" ]]; then
    echo "Error: Could not resolve home directory for user $TARGET_USER"
    exit 1
fi

echo "--- Setting up ZSH for $TARGET_USER (Home: $HOME_DIR) ---"

# --- 1. Dependencies ----------------------------------------------------------
echo "Checking dependencies..."
# Use a silent update to keep logs clean
sudo apt-get update -qq
sudo apt-get install -y -qq zsh git curl fzf bc trash-cli micro make

# --- 2. Kill Interactivity ----------------------------------------------------
# Create a dummy .zshrc if it doesn't exist to prevent zsh-newuser-install menu
if [[ ! -f "$HOME_DIR/.zshrc" ]]; then
    sudo -u "$TARGET_USER" touch "$HOME_DIR/.zshrc"
fi

# --- 3. Oh-My-Zsh (Unattended) ------------------------------------------------
if [[ ! -d "$HOME_DIR/.oh-my-zsh" ]]; then
    echo "Installing Oh-My-Zsh..."
    # Force RUNZSH=no and CHSH=no to prevent shell hijacking during install
    sudo -u "$TARGET_USER" env RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# --- 4. Plugins ---------------------------------------------------------------
ZSH_CUSTOM="$HOME_DIR/.oh-my-zsh/custom"

install_plugin() {
    local name=$1
    local repo=$2
    if [[ ! -d "$ZSH_CUSTOM/plugins/$name" ]]; then
        echo "Installing plugin: $name..."
        sudo -u "$TARGET_USER" git clone -q "$repo" "$ZSH_CUSTOM/plugins/$name"
    fi
}

install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
install_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search"

# --- 5. Template Application --------------------------------------------------
# Handle remote fallback if local template is missing
if [[ ! -f "$TEMPLATE_PATH" ]]; then
    echo "Local template missing at $TEMPLATE_PATH. Fetching from GitHub..."
    REMOTE_URL="https://raw.githubusercontent.com/kpihx-labs/zsh/master/assets/zshrc.template"
    TMP_FILE=$(mktemp)
    if curl -fsSL "$REMOTE_URL" -o "$TMP_FILE"; then
        TEMPLATE_PATH="$TMP_FILE"
    else
        echo "Warning: Could not fetch template. Using default .zshrc"
    fi
fi

if [[ -f "$TEMPLATE_PATH" ]]; then
    echo "Applying .zshrc template..."
    sudo cp "$TEMPLATE_PATH" "$HOME_DIR/.zshrc"
    sudo chown "$TARGET_USER:$(id -gn "$TARGET_USER")" "$HOME_DIR/.zshrc"
    [[ "${TMP_FILE:-}" && -f "$TMP_FILE" ]] && rm -f "$TMP_FILE"
fi

# --- 6. Shell Activation ------------------------------------------------------
ZSH_PATH=$(command -v zsh)
CURRENT_SHELL=$(getent passwd "$TARGET_USER" | cut -d: -f7)

if [[ "$CURRENT_SHELL" != "$ZSH_PATH" ]]; then
    echo "Changing default shell to $ZSH_PATH..."
    sudo chsh -s "$ZSH_PATH" "$TARGET_USER"
fi

# --- 7. Permissions Audit -----------------------------------------------------
# Ensure the user owns their .oh-my-zsh directory to prevent 'broken' themes/plugins
echo "Finalizing permissions..."
sudo chown -R "$TARGET_USER:$(id -gn "$TARGET_USER")" "$HOME_DIR/.oh-my-zsh"

echo "=============================================================================="
echo " SUCCESS: ZSH environment is ready for $TARGET_USER."
echo " Please restart your terminal or run: exec zsh"
echo "=============================================================================="
