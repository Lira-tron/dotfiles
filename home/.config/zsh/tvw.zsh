# Select a checkout of the current repository.
tvw() {
    command git rev-parse --git-dir >/dev/null 2>&1 || {
        print -u2 "Run tvw from a Git checkout."
        return 1
    }
    local tree_source='python3 "$HOME/.config/television/cable/worktrees.py" current'
    local tree_keys='tab="select_next_entry";backtab="select_prev_entry"'
    if [[ "${HERDR_ENV:-}" == 1 ]]; then
        # Distinguish Enter from the channel's Ctrl+M previous-pane shortcut.
        printf '\033[?1049h\033[>1u'
        command tv herdr-workspaces --source-command "$tree_source" --no-remote --keybindings "$tree_keys"
        local tree_result=$?
        printf '\033[<u\033[?1049l'
        return "$tree_result"
    else
        local selection tree_path
        selection=$(command tv --source-command "$tree_source" \
            --source-display '{split:\t:0}' --source-output '{split:\t:1}' \
            --no-remote --keybindings "$tree_keys") || return
        [[ -n "$selection" ]] || return 0
        tree_path=$(python3 "$HOME/.config/television/cable/worktrees.py" path "$selection") || return
        builtin cd -- "$tree_path"
    fi
}
