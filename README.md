# KpihX-Labs ZSH Configuration

This directory contains the unified and agnostic ZSH configuration for the KpihX-Labs ecosystem. The goal is to deploy a complete, minimalist, and functional ZSH experience on any Linux node (Debian, Ubuntu, etc.) without OS-specific dependencies.

## Structure

- **`assets/zshrc.template`**: The `.zshrc` configuration template. It has been refined to be 100% independent. Calls to specific paths (like Linuxbrew, pyenv, or waydroid) are conditioned to only activate if they actually exist on the target machine.
- **`scripts/install.sh`**: Automated installation script. It installs ZSH, Oh-My-Zsh (non-interactive), necessary plugins, and essential tools like `curl`, `micro`, and `make`.
- **`scripts/purge.sh`**: TOTAL purge utility. Reverts the shell to bash, removes Oh-My-Zsh (and all debris like history/backups), and uninstalls associated tools. **100% interactive for safety.**

## Usage

### Install
To deploy ZSH on a new machine or node:
```bash
bash scripts/install.sh [TARGET_USER]
```

**Remote Execution (One-Liner):**
```bash
sudo bash -c "$(curl -sSL https://raw.githubusercontent.com/kpihx-labs/zsh/master/scripts/install.sh)"
```

### Purge
To purge the ZSH environment (TOTAL cleanup):
```bash
bash scripts/purge.sh [TARGET_USER]
```

**Remote Purge (One-Liner):**
```bash
sudo bash -c "$(curl -sSL https://raw.githubusercontent.com/kpihx-labs/zsh/master/scripts/purge.sh)"
```

> [!IMPORTANT]
> The purge script is **100% interactive**. It will explicitly ask for confirmation before removing each package (zsh, micro, git, etc.) and each debris item (.oh-my-zsh, .zshrc, etc.).
