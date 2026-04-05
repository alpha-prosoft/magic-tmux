#!/bin/bash
# Tmux shell integration for automatic window naming.
# Sourced from shell-init.bash.

# Find the nearest parent dir containing .git, or fall back to current dir name.
_tmux_window_label() {
  local dir="$1"
  while [ "$dir" != "/" ]; do
    if [ -d "$dir/.git" ]; then
      basename "$dir"
      return
    fi
    dir=$(dirname "$dir")
  done
  basename "$1"
}

update_tmux_window_name() {
  [ -n "$TMUX" ] || return
  local window_id path
  window_id=$(tmux display-message -p -F "#{window_id}" 2>/dev/null) || return
  path=$(tmux display-message -p -t "${window_id}.0" -F "#{pane_current_path}" 2>/dev/null) || return
  [ -n "$path" ] && tmux rename-window "$(_tmux_window_label "$path")" 2>/dev/null
}

# Bash: hook into PROMPT_COMMAND
if [ -n "$BASH_VERSION" ]; then
  PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}update_tmux_window_name"
fi
