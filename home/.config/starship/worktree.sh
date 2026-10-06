#!/bin/sh

# Brazil worktree roots and src/ are outside the package Git repositories.
tree_dir=$(pwd -P) || exit 0
while [ "$tree_dir" != / ]; do
    if [ -f "$tree_dir/packageInfo" ]; then
        if grep -Eq '^[[:space:]]*worktree[[:space:]]*=[[:space:]]*"?true"?[[:space:]]*;' "$tree_dir/packageInfo"; then
            printf '%s\n' "${tree_dir##*/}"
            exit 0
        fi
        break
    fi
    tree_dir=${tree_dir%/*}
    [ -n "$tree_dir" ] || break
done

# Linked Git worktrees have a commondir file; primary checkouts do not.
git_dir=$(git rev-parse --absolute-git-dir 2>/dev/null) || exit 0
[ -f "$git_dir/commondir" ] || exit 0
tree_dir=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
printf '%s\n' "${tree_dir##*/}"
