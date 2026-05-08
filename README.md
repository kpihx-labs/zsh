# KpihX-Labs ZSH Configuration

This directory contains the unified and agnostic ZSH configuration for the KpihX-Labs ecosystem. The goal is to deploy a complete, minimalist, and functional ZSH experience on any Linux node (Debian, Ubuntu, etc.) without OS-specific dependencies.

## Structure

- **`assets/zshrc.template`**: The `.zshrc` configuration template. It has been refined to be 100% independent. Calls to specific paths (like Linuxbrew, pyenv, or waydroid) are conditioned to only activate if they actually exist on the target machine.
- **`scripts/install.sh`**: Automated installation script. It installs ZSH, Oh-My-Zsh (non-interactive), necessary plugins, and essential tools like `curl`, `micro`, and `make`.
- **`scripts/purge.sh`**: Interactive purge utility. Reverts the shell to bash, removes Oh-My-Zsh, and uninstalls associated tools. Supports `-y` for non-interactive cleanup.

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
To purge the ZSH environment (interactive by default):
```bash
bash scripts/purge.sh [-y] [TARGET_USER]
```

**Remote Purge (One-Liner):**
```bash
sudo bash -c "$(curl -sSL https://raw.githubusercontent.com/kpihx-labs/zsh/master/scripts/purge.sh)"
```
The purge cycle will ask for confirmation before removing intermediate tools (`make`, `curl`, `micro`, etc.) and finish with `zsh` itself. Use `-y` to skip confirmations.
