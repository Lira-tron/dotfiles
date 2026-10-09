#!/bin/sh

# Brazil worktree roots and src/ are outside the package Git repositories.
tree_dir=$(pwd -P) || exit 0
git_dir=
while [ "$tree_dir" != / ]; do
    if [ -z "$git_dir" ] && [ -e "$tree_dir/.git" ]; then
        git_dir=$tree_dir/.git
    fi
    if [ -f "$tree_dir/packageInfo" ]; then
        if grep -Eq '^[[:space:]]*worktree[[:space:]]*=[[:space:]]*"?true"?[[:space:]]*;' "$tree_dir/packageInfo"; then
            printf 'w:%s\n' "${tree_dir##*/}"
            exit 0
        fi
        break
    fi
    tree_dir=${tree_dir%/*}
    [ -n "$tree_dir" ] || break
done

# Linked Git worktrees have a commondir file; primary checkouts do not.
if [ ! -d "$git_dir" ] || [ -n "${GIT_DIR-}" ]; then
    git_dir=$(git rev-parse --absolute-git-dir 2>/dev/null) || exit 0
fi
if [ -f "$git_dir/commondir" ]; then
    tree_dir=$(git rev-parse --show-toplevel 2>/dev/null) || exit 0
    printf 'w:%s\n' "${tree_dir##*/}"
else
    branch_name=$(git symbolic-ref --quiet --short HEAD 2>/dev/null) || exit 0
    printf 'b:%s\n' "$branch_name"
fi
