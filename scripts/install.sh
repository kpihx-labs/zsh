#!/usr/bin/env bash
set -e

# Usage: ./install.sh [TARGET_USER] [ZSHRC_TEMPLATE_PATH]
TARGET_USER="${1:-$USER}"
TEMPLATE_PATH="${2:-$(dirname "$0")/../assets/zshrc.template}"

if [ "$TARGET_USER" = "root" ]; then
    HOME_DIR="/root"
else
    HOME_DIR="/home/$TARGET_USER"
fi

echo "Setting up ZSH for user: $TARGET_USER"

# 1. Install dependencies (requires sudo or root)
sudo apt-get update
sudo apt-get install -y zsh git curl fzf bc trash-cli micro make

# 2. Install Oh-My-Zsh unattended
if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
    echo "Installing Oh-My-Zsh..."
    sudo -u "$TARGET_USER" sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

# 3. Install Plugins
ZSH_CUSTOM="$HOME_DIR/.oh-my-zsh/custom"

install_plugin() {
    local name=$1
    local repo=$2
    if [ ! -d "$ZSH_CUSTOM/plugins/$name" ]; then
        echo "Installing $name..."
        sudo -u "$TARGET_USER" git clone "$repo" "$ZSH_CUSTOM/plugins/$name"
    fi
}

install_plugin "zsh-autosuggestions" "https://github.com/zsh-users/zsh-autosuggestions"
install_plugin "zsh-syntax-highlighting" "https://github.com/zsh-users/zsh-syntax-highlighting.git"
install_plugin "zsh-history-substring-search" "https://github.com/zsh-users/zsh-history-substring-search"

# 4. Copy template
# If local template not found, attempt to download from GitHub (Self-Contained mode)
if [ ! -f "$TEMPLATE_PATH" ]; then
    echo "Local template not found at $TEMPLATE_PATH. Attempting remote fetch..."
    REMOTE_TEMPLATE_URL="https://raw.githubusercontent.com/kpihx-labs/zsh/master/assets/zshrc.template"
    TMP_TEMPLATE=$(mktemp)
    if curl -fsSL "$REMOTE_TEMPLATE_URL" -o "$TMP_TEMPLATE"; then
        TEMPLATE_PATH="$TMP_TEMPLATE"
        echo "Remote template successfully fetched."
    else
        echo "Warning: Could not fetch remote template. Skipping."
    fi
fi

if [ -f "$TEMPLATE_PATH" ]; then
    echo "Applying zshrc template..."
    sudo cp "$TEMPLATE_PATH" "$HOME_DIR/.zshrc"
    sudo chown "$TARGET_USER:$TARGET_USER" "$HOME_DIR/.zshrc"
    [ -n "${TMP_TEMPLATE:-}" ] && rm -f "$TMP_TEMPLATE"
else
    echo "Warning: No zshrc template available. Skipping."
fi

# 5. Change default shell
ZSH_PATH=$(command -v zsh)
if [ -n "$ZSH_PATH" ] && ! getent passwd "$TARGET_USER" | grep -q "$ZSH_PATH$"; then
    echo "Changing default shell to ZSH..."
    sudo chsh -s "$ZSH_PATH" "$TARGET_USER"
fi

echo "ZSH setup complete for $TARGET_USER!"
