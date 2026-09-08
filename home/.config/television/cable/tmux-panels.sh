#!/usr/bin/env bash
# Emit one row per tmux pane across all sessions for the tmux-workspaces tv channel.
# Multi-pane windows sort first, so agent-team windows float to the top.
# For panes running Claude Code, the agent name / task is shown from the pane title
# (which carries a live status glyph: ◑/◐ = working, ✳ = idle); other panes show
# their current command.
# Format per line: <display>\t<pane-path>\t<pane-target>
#   display: [panels] <session> │ <window-name> │ <win>.<pane> · <agent-or-cmd>  (<n>p)
#   target:  <session>:<window>.<pane>
# pane_title is emitted last so a stray '|' inside it can't shift earlier fields.
set -uo pipefail

tmux list-panes -a \
  -F '#{window_panes}|#{session_name}|#{window_name}|#{window_index}|#{pane_index}|#{pane_current_command}|#{pane_current_path}|#{session_name}:#{window_index}.#{pane_index}|#{pane_title}' \
  2>/dev/null \
| awk -F'|' '{
    npanes=$1; sess=$2; wname=$3; win=$4; pane=$5; cmd=$6; path=$7; target=$8;
    title=$9; for (i=10; i<=NF; i++) title=title "|" $i;
    label=cmd;
    if (cmd == "claude" && title != "") label=title;
    printf "%s\t[panels] %s │ %s │ %s.%s · %s  (%sp)\t%s\t%s\n", \
      npanes, sess, wname, win, pane, label, npanes, path, target
  }' \
| sort -t"$(printf '\t')" -k1,1 -rn \
| cut -f2-
