#!/bin/bash
# Update tmux window name based on first pane's directory.
# Called by tmux hooks via run-shell.
# Shows git root name if inside a repo, otherwise current dir name.

window_id=$(tmux display-message -p -F "#{window_id}" 2>/dev/null) || exit 0
path=$(tmux display-message -p -t "${window_id}.0" -F "#{pane_current_path}" 2>/dev/null) || exit 0
[ -n "$path" ] || exit 0

dir="$path"
while [ "$dir" != "/" ]; do
  if [ -d "$dir/.git" ]; then
    tmux rename-window "$(basename "$dir")" 2>/dev/null
    exit 0
  fi
  dir=$(dirname "$dir")
done

tmux rename-window "$(basename "$path")" 2>/dev/null
