#!/bin/bash
# Update tmux window name based on first pane's directory.
# Called by tmux hooks in .tmux.conf.
[ -n "$TMUX" ] || exit 0
window_id=$(tmux display-message -p -F "#{window_id}" 2>/dev/null) || exit 0
path=$(tmux display-message -p -t "${window_id}.0" -F "#{pane_current_path}" 2>/dev/null) || exit 0
[ -n "$path" ] && tmux rename-window "$(basename "$path")" 2>/dev/null
