#!/usr/bin/env bash
# Emit entries for the tmux-knowledge tv channel.
# Usage: tmux-knowledge.sh [all|designs|mcm|memory|memories|onepagers|reviews|specs]
# Format per line: <display>\t<path>\t<session-name>
set -uo pipefail

K=$HOME/knowledge
CAT=${1:-all}

emit() {
  printf '%s\t%s\t%s\n' "$1" "$2" "$3"
}

cat_designs() {
  [ -d "$K/designs" ] || return 0
  emit "[des] designs" "$K/designs" "des-designs"
  fd -t d --exact-depth 3 . "$K/designs" --format '{}' 2>/dev/null | while read -r p; do
    p=${p%/}
    rel=${p#"$K/designs/"}
    yy=${rel%%/*}; rest=${rel#*/}; mm=${rest%%/*}; leaf=${rest#*/}
    emit "[des ${yy}-${mm}] ${leaf}" "$p" "des-${leaf}"
  done
}

cat_mcm() {
  [ -d "$K/mcm" ] || return 0
  emit "[mcm] mcm" "$K/mcm" "mcm-mcm"
  fd -t d --exact-depth 2 . "$K/mcm" --format '{}' 2>/dev/null | while read -r p; do
    p=${p%/}
    rel=${p#"$K/mcm/"}
    yy=${rel%%/*}; mm=${rel#*/}
    emit "[mcm ${yy}] ${mm}" "$p" "mcm-${yy}-${mm}"
  done
}

cat_memory() {
  [ -d "$K/memory" ] || return 0
  emit "[mem] memory" "$K/memory" "mem-memory"
  fd -t d --exact-depth 1 . "$K/memory" --format '{}' 2>/dev/null | while read -r p; do
    p=${p%/}
    leaf=$(basename "$p")
    emit "[mem] ${leaf}" "$p" "mem-${leaf}"
  done
}

cat_memories() {
  [ -d "$K/memories" ] || return 0
  emit "[clamem] memories" "$K/memories" "clamem-memories"
  fd -t d --exact-depth 1 . "$K/memories" --format '{}' 2>/dev/null | while read -r p; do
    p=${p%/}
    leaf=$(basename "$p")
    emit "[clamem] ${leaf}" "$p" "clamem-${leaf}"
  done
}

cat_onepagers() {
  [ -d "$K/onepagers" ] || return 0
  emit "[one] onepagers" "$K/onepagers" "one-onepagers"
  fd -t d --exact-depth 3 . "$K/onepagers" --format '{}' 2>/dev/null | while read -r p; do
    p=${p%/}
    rel=${p#"$K/onepagers/"}
    yy=${rel%%/*}; rest=${rel#*/}; mm=${rest%%/*}; leaf=${rest#*/}
    emit "[one ${yy}-${mm}] ${leaf}" "$p" "one-${leaf}"
  done
}

cat_reviews() {
  [ -d "$K/reviews" ] || return 0
  emit "[rev] reviews" "$K/reviews" "rev-reviews"
}

cat_specs() {
  [ -d "$K/specs" ] || return 0
  emit "[spec] specs" "$K/specs" "spec-specs"
  fd -t d --exact-depth 3 . "$K/specs" --format '{}' 2>/dev/null | while read -r p; do
    p=${p%/}
    rel=${p#"$K/specs/"}
    yy=${rel%%/*}; rest=${rel#*/}; mm=${rest%%/*}; leaf=${rest#*/}
    emit "[spec ${yy}-${mm}] ${leaf}" "$p" "spec-${leaf}"
  done
}

cat_projects() {
  [ -d "$K/projects" ] || return 0
  emit "[proj] projects" "$K/projects" "proj-projects"
  fd -t d --exact-depth 3 . "$K/projects" --format '{}' 2>/dev/null | while read -r p; do
    p=${p%/}
    rel=${p#"$K/projects/"}
    yy=${rel%%/*}; rest=${rel#*/}; mm=${rest%%/*}; leaf=${rest#*/}
    emit "[proj ${yy}-${mm}] ${leaf}" "$p" "proj-${leaf}"
  done
}

cat_sessions() {
  [ -d "$K/sessions" ] || return 0
  emit "[ses] sessions" "$K/sessions" "ses-sessions"
  fd -t d --exact-depth 1 . "$K/sessions" --format '{}' 2>/dev/null | sort -r | while read -r p; do
    p=${p%/}
    leaf=$(basename "$p")
    emit "[ses ${leaf}]" "$p" "ses-${leaf}"
  done
}

cat_ops() {
  [ -d "$K/ops" ] || return 0
  emit "[ops] ops" "$K/ops" "ops-ops"
  fd -t d --exact-depth 2 . "$K/ops" --format '{}' 2>/dev/null | sort -r | while read -r p; do
    p=${p%/}
    rel=${p#"$K/ops/"}
    grp=${rel%%/*}; leaf=${rel#*/}
    emit "[ops ${grp}] ${leaf}" "$p" "ops-${leaf}"
  done
}

cat_others() { cat_mcm; cat_onepagers; cat_reviews; }

case "$CAT" in
  all)       cat_designs; cat_mcm; cat_memory; cat_memories; cat_onepagers; cat_ops; cat_projects; cat_reviews; cat_specs ;;
  designs)   cat_designs ;;
  mcm)       cat_mcm ;;
  memory)    cat_memory ;;
  memories)  cat_memories ;;
  onepagers) cat_onepagers ;;
  ops)       cat_ops ;;
  others)    cat_others ;;
  projects)  cat_projects ;;
  reviews)   cat_reviews ;;
  sessions)  cat_sessions ;;
  specs)     cat_specs ;;
  *)         echo "unknown category: $CAT" >&2; exit 2 ;;
esac
