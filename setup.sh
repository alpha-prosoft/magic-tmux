#!/usr/bin/env bash
set -euo pipefail

# tmux install script
# Installs tmux and wires shell config into ~/.bashrc.
# Re-runnable: shell config block is replaced in-place via markers.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BASHRC="$HOME/.bashrc"
MARKER="# >>> tmux >>>"
SOURCE_LINE="source ~/.config/tmux/shell-init.bash $MARKER"

# -- Helpers ---------------------------------------------------------------

info()  { printf '\033[1;34m[INFO]\033[0m  %s\n' "$*"; }
error() { printf '\033[1;31m[ERROR]\033[0m %s\n' "$*"; exit 1; }

# -- Install tmux ----------------------------------------------------------

install_tmux() {
  if command -v tmux &>/dev/null; then
    info "tmux already installed ($(tmux -V))"
    return
  fi
  info "Installing tmux ..."
  sudo apt-get update -qq
  sudo apt-get install -y -qq tmux
  info "tmux installed ($(tmux -V))"
}

# -- Fix script permissions ------------------------------------------------

fix_permissions() {
  info "Fixing script permissions ..."
  chmod +x "$SCRIPT_DIR/scripts/"*.sh
  chmod +x "$SCRIPT_DIR/shell-init.bash"
  info "Permissions fixed"
}

# -- Install TPM and plugins -----------------------------------------------

PLUGINS=(
  "tmux-plugins/tpm"
  "tmux-plugins/tmux-sensible"
  "christoomey/vim-tmux-navigator"
  "catppuccin/tmux#v2.1.1"
)

install_plugin() {
  local spec="$1"
  local repo="${spec%%#*}"
  local ref="${spec#*#}"
  [ "$ref" = "$spec" ] && ref=""
  local name="${repo##*/}"
  local dir="$SCRIPT_DIR/plugins/$name"

  # Skip if already populated
  if [ -d "$dir/.git" ]; then
    info "Plugin $name already installed"
    return
  fi

  rm -rf "$dir"
  info "Installing plugin $name ..."
  git clone "https://github.com/$repo" "$dir"
  if [ -n "$ref" ]; then
    git -C "$dir" checkout "$ref" --quiet
  fi
}

install_plugins() {
  mkdir -p "$SCRIPT_DIR/plugins"
  for spec in "${PLUGINS[@]}"; do
    install_plugin "$spec"
  done
  info "All plugins installed"
}

# -- Shell config ----------------------------------------------------------
# Single source line in .bashrc tagged with a marker comment.
# Re-runs replace it in-place via sed; first run appends.

configure_shell() {
  local init_file="$SCRIPT_DIR/shell-init.bash"
  [[ -f "$init_file" ]] || error "shell-init.bash not found at $init_file"

  touch "$BASHRC"

  if grep -qF "$MARKER" "$BASHRC"; then
    info "Replacing tmux line in $BASHRC"
    sed -i "s|.*${MARKER}.*|${SOURCE_LINE}|" "$BASHRC"
  else
    info "Appending tmux line to $BASHRC"
    printf '\n%s\n' "$SOURCE_LINE" >> "$BASHRC"
  fi

  info "Shell configured"
}

# -- Main ------------------------------------------------------------------

main() {
  info "=== tmux setup ==="
  echo
  install_tmux
  fix_permissions
  install_plugins
  configure_shell
  echo
  info "=== Setup complete ==="
  info "Restart your shell or run:  source $BASHRC"
}

main "$@"
