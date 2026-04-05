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
  if [ -d "$dir" ]; then
    info "Plugin $name already installed"
    return
  fi

  rm -rf "$dir"
  info "Installing plugin $name ..."
  git clone --quiet "https://github.com/$repo" "$dir"
  if [ -n "$ref" ]; then
    git -C "$dir" checkout "$ref" --quiet
  fi
  # Drop the .git dir — we only need the files, not the git history.
  rm -rf "$dir/.git"
}

install_plugins() {
  mkdir -p "$SCRIPT_DIR/plugins"
  for spec in "${PLUGINS[@]}"; do
    install_plugin "$spec"
  done
  info "All plugins installed"
}

# -- Install Nerd Font -----------------------------------------------------

NERD_FONT_URL="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.4.0/UbuntuSans.zip"
NERD_FONT_DIR="$HOME/.local/share/fonts/NerdFonts"

install_nerd_font() {
  if fc-list | grep -qi "UbuntuSans Nerd Font"; then
    info "UbuntuSans Nerd Font already installed"
    return
  fi

  info "Installing UbuntuSans Nerd Font ..."
  local tmp
  tmp=$(mktemp -d)
  curl -fsSL "$NERD_FONT_URL" -o "$tmp/UbuntuSans.zip"
  mkdir -p "$NERD_FONT_DIR"
  unzip -q "$tmp/UbuntuSans.zip" -d "$NERD_FONT_DIR"
  rm -rf "$tmp"
  fc-cache -f "$NERD_FONT_DIR"
  info "UbuntuSans Nerd Font installed"
}

# -- Configure terminal font -----------------------------------------------

configure_terminal_font() {
  if ! gsettings list-schemas 2>/dev/null | grep -q "org.gnome.Ptyxis"; then
    info "Ptyxis not found; skipping terminal font configuration"
    return
  fi
  info "Configuring Ptyxis font ..."
  gsettings set org.gnome.Ptyxis use-system-font false
  gsettings set org.gnome.Ptyxis font-name "UbuntuSansMono Nerd Font Mono 13"
  info "Ptyxis font set to 'UbuntuSansMono Nerd Font Mono 13'"
}

# -- Reload tmux config ----------------------------------------------------
# Sources tmux.conf into the running server to flush stale hooks.

reload_tmux_config() {
  if [ -z "${TMUX-}" ]; then
    info "Not inside a tmux session; skipping config reload"
    return
  fi
  info "Reloading tmux config ..."
  tmux source-file "$SCRIPT_DIR/tmux.conf"
  info "tmux config reloaded"
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
  install_nerd_font
  configure_terminal_font
  configure_shell
  reload_tmux_config
  echo
  info "=== Setup complete ==="
  info "Restart your shell or run:  source $BASHRC"
}

main "$@"
