#!/usr/bin/env bash
# shell-init.bash - sourced from ~/.bashrc
# Exports environment variables and auto-starts tmux.

export TMUX_CONFIG_DIR="$HOME/.config/tmux"
export TMUX_PLUGIN_MANAGER_PATH="$TMUX_CONFIG_DIR/plugins"

# Auto-start tmux if not already inside a session
if command -v tmux &>/dev/null && [ -z "${TMUX-}" ]; then
  exec tmux new-session
fi
