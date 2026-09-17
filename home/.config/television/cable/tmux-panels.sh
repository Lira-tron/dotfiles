#!/usr/bin/env bash
# Emit one row per tmux pane across all sessions for the tmux-workspaces tv channel.
# Multi-pane windows sort first, so agent-team windows float to the top.
# Claude Code and Codex panes show Herdr-style status icons from their titles.
# Title signals cannot distinguish a completed turn from idle.
# Other panes show their current command.
# Format per line: <display>\t<pane-path>\t<pane-target>
#   display: <[panels] or [agent] icon> <session> │ <window-name> │ <win>.<pane> · <agent-or-cmd>  (<n>p)
#   target:  <session>:<window>.<pane>
# pane_title is emitted last so a stray '|' inside it can't shift earlier fields.
set -uo pipefail

tmux list-panes -a \
  -F '#{window_panes}|#{session_name}|#{window_name}|#{window_index}|#{pane_index}|#{pane_current_command}|#{pane_current_path}|#{session_name}:#{window_index}.#{pane_index}|#{pane_title}' \
  2>/dev/null \
| awk -F'|' '{
    npanes=$1; sess=$2; wname=$3; win=$4; pane=$5; cmd=$6; path=$7; target=$8;
    title=$9; for (i=10; i<=NF; i++) title=title "|" $i;
    label=cmd; prefix="[panels]";
    if (cmd == "claude" || cmd == "codex") {
      icon="·";
      if (title != "") label=title;
      if (cmd == "claude") {
        if (title ~ /^[⠀-⣿◐-◓] /) icon="◐";
        else if (title ~ /^✳ /) icon="○";
      } else {
        if (index(title, "Action Required")) icon="×";
        else if (title ~ /(^| )(⠋|⠙|⠹|⠸|⠼|⠴|⠦|⠧|⠇|⠏)( |$)/) icon="◐";
        else if (title ~ /[^[:space:]]/) icon="○";
      }
      prefix="[agent] " icon;
    }
    printf "%s\t%s %s │ %s │ %s.%s · %s  (%sp)\t%s\t%s\n", \
      npanes, prefix, sess, wname, win, pane, label, npanes, path, target
  }' \
| sort -t"$(printf '\t')" -k1,1 -rn \
| cut -f2-
