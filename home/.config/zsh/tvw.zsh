# Find worktrees here and below first, then stop at the nearest parent with matches.
tvw() {
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
        local selection tree_path tree_action tree_token
        selection=$(command tv --source-command "$tree_source" \
            --source-display '{split:\t:0}' --source-output '{split:\t:1}' \
            --no-remote --keybindings "$tree_keys" --expect 'enter;ctrl-d;ctrl-g') || return
        [[ -n "$selection" ]] || return 0
        tree_action="${selection%%$'\n'*}"
        tree_token="${selection#*$'\n'}"
        case "$tree_action" in
            enter) tree_path=$(python3 "$HOME/.config/television/cable/worktrees.py" path "$tree_token") || return ;;
            ctrl-g) tree_path=$(python3 "$HOME/.config/television/cable/worktrees.py" create "$tree_token") || return ;;
            ctrl-d) python3 "$HOME/.config/television/cable/worktrees.py" delete "$tree_token"; return $? ;;
        esac
        [[ -n "$tree_path" ]] || return 0
        builtin cd -- "$tree_path"
    fi
}
