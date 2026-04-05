#!/bin/bash
# Tmux shell integration for automatic window naming.
# Sourced by .bashrc/.zshrc via setup.sh.

update_tmux_window_name() {
  [ -n "$TMUX" ] || return
  local window_id path name
  window_id=$(tmux display-message -p -F "#{window_id}" 2>/dev/null) || return
  path=$(tmux display-message -p -t "${window_id}.0" -F "#{pane_current_path}" 2>/dev/null) || return
  name=$(basename "$path")
  tmux rename-window "$name" 2>/dev/null
}

# Bash: hook into PROMPT_COMMAND
if [ -n "$BASH_VERSION" ]; then
  PROMPT_COMMAND="${PROMPT_COMMAND:+$PROMPT_COMMAND;}update_tmux_window_name"
fi

# Zsh: hook into precmd
if [ -n "$ZSH_VERSION" ]; then
  precmd() { update_tmux_window_name; }
fi
