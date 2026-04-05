#!/usr/bin/env bash
set -euo pipefail

TMUX_CONFIG_DIR="$HOME/.config/tmux"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
INIT_LINE="source \"$TMUX_CONFIG_DIR/shell-init.bash\""
BASHRC="$HOME/.bashrc"

info() { printf '\033[1;34m::\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m::\033[0m %s\n' "$*"; }
ok() { printf '\033[1;32m::\033[0m %s\n' "$*"; }
err() { printf '\033[1;31m::\033[0m %s\n' "$*" >&2; }

# -----------------------------------------------------------
# 1. Install tmux if missing
# -----------------------------------------------------------
if command -v tmux &>/dev/null; then
  ok "tmux already installed ($(tmux -V))"
else
  info "Installing tmux ..."
  if command -v apt-get &>/dev/null; then
    sudo apt-get update -qq && sudo apt-get install -y -qq tmux
  elif command -v dnf &>/dev/null; then
    sudo dnf install -y tmux
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm tmux
  elif command -v brew &>/dev/null; then
    brew install tmux
  else
    err "Could not detect a supported package manager (apt, dnf, pacman, brew)."
    err "Please install tmux manually and re-run this script."
    exit 1
  fi
  ok "tmux installed ($(tmux -V))"
fi

# -----------------------------------------------------------
# 2. Ensure config dir is in place
# -----------------------------------------------------------
if [ "$SCRIPT_DIR" != "$TMUX_CONFIG_DIR" ]; then
  info "Linking config from $SCRIPT_DIR -> $TMUX_CONFIG_DIR"
  mkdir -p "$(dirname "$TMUX_CONFIG_DIR")"
  ln -sfn "$SCRIPT_DIR" "$TMUX_CONFIG_DIR"
  ok "Config directory linked"
else
  ok "Config already at $TMUX_CONFIG_DIR"
fi

# -----------------------------------------------------------
# 3. Install TPM if missing
# -----------------------------------------------------------
TPM_DIR="$TMUX_CONFIG_DIR/plugins/tpm"
if [ -d "$TPM_DIR" ]; then
  ok "TPM already installed"
else
  info "Installing TPM ..."
  git clone https://github.com/tmux-plugins/tpm "$TPM_DIR"
  ok "TPM installed"
fi

# -----------------------------------------------------------
# 4. Add shell-init.bash to ~/.bashrc if not already there
# -----------------------------------------------------------
if [ ! -f "$BASHRC" ]; then
  warn "$BASHRC does not exist, creating it"
  touch "$BASHRC"
fi

if grep -qF "shell-init.bash" "$BASHRC"; then
  ok "shell-init.bash already sourced in $BASHRC"
else
  info "Adding shell-init.bash to $BASHRC"
  {
    echo ""
    echo "# tmux config"
    echo "$INIT_LINE"
  } >>"$BASHRC"
  ok "Added to $BASHRC"
fi

# -----------------------------------------------------------
# 5. Remove legacy ~/.tmux.conf if it exists
# -----------------------------------------------------------
if [ -e "$HOME/.tmux.conf" ] || [ -L "$HOME/.tmux.conf" ]; then
  warn "Removing legacy ~/.tmux.conf (config now at $TMUX_CONFIG_DIR/tmux.conf)"
  rm -f "$HOME/.tmux.conf"
fi

# -----------------------------------------------------------
# Done
# -----------------------------------------------------------
echo ""
ok "Setup complete!"
info "Restart your shell or run:  source $BASHRC"
info "Then inside tmux press prefix + I to install plugins via TPM."
