#!/usr/bin/env bash
# Claude Code status line: branch +/- · model · effort · cwd · ctx bar %
#
# Reads stdin JSON from Claude Code, parses the transcript to find the
# most recent assistant message's token usage, and renders a percentage
# against the full 1M context window.

set -euo pipefail

input=$(cat)

model_raw=$(jq -r '.model.display_name // .model.id // "?"' <<<"$input")
model_id=$(jq -r '.model.id // ""' <<<"$input")
# Strip trailing "(...)" from display name (e.g. "Opus 4.7 (1M)" → "Opus 4.7").
model=$(sed -E 's/ *\([^)]*\)$//' <<<"$model_raw")
# Detect 1M context tier from either display name or model id.
model_tier=""
if [[ "$model_raw" == *"1M"* || "$model_raw" == *"1m"* || "$model_id" == *"[1m]"* ]]; then
  model_tier="1M"
fi
cwd=$(jq -r '.workspace.current_dir // .cwd // ""' <<<"$input")
transcript=$(jq -r '.transcript_path // ""' <<<"$input")
exceeds_200k=$(jq -r '.exceeds_200k_tokens // false' <<<"$input")
effort=$(jq -r '.effort.level // empty' <<<"$input")
agent=$(jq -r '.agent.name // empty' <<<"$input")

# Pretty-print: low → Low, xhigh → xHigh, max → Max.
case "$effort" in
  "")    effort_label="" ;;
  xhigh) effort_label="xHigh" ;;
  *)     effort_label="$(tr '[:lower:]' '[:upper:]' <<<"${effort:0:1}")${effort:1}" ;;
esac

cwd_short="${cwd/#$HOME/~}"
# Keep only the last 4 path segments (prefix with … if truncated).
IFS='/' read -ra _parts <<<"$cwd_short"
if [ "${#_parts[@]}" -gt 4 ]; then
  cwd_short="…/${_parts[-4]}/${_parts[-3]}/${_parts[-2]}/${_parts[-1]}"
fi

# Full model context window (matches /context denominator).
window=1000000

used=0
pretty=""
ctx_known=0

if [[ -n "$transcript" && -f "$transcript" ]]; then
  # Walk the transcript backwards for the most recent usage block.
  usage=$(tac "$transcript" | jq -r '
    (.message.usage // .usage // empty)
    | select(. != null)
    | (.input_tokens // 0)
      + (.cache_read_input_tokens // 0)
      + (.cache_creation_input_tokens // 0)
  ' 2>/dev/null | head -n1)

  if [[ -n "$usage" && "$usage" =~ ^[0-9]+$ ]]; then
    used=$(awk -v t="$usage" -v w="$window" 'BEGIN{ printf "%.0f", (t/w)*100 }')
    pretty=$(awk -v t="$usage" 'BEGIN{
      if (t >= 1000) printf "%.1fk", t/1000;
      else printf "%d", t;
    }')
    ctx_known=1
  fi
fi

# 5-char progress bar with 4 shades, 20 visual steps.
bar=""
for i in 0 1 2 3 4; do
  slot_start=$((i * 20))
  remainder=$((used - slot_start))
  if   [ "$remainder" -ge 20 ]; then bar="${bar}█"
  elif [ "$remainder" -ge 13 ]; then bar="${bar}▓"
  elif [ "$remainder" -ge 7  ]; then bar="${bar}▒"
  else                                bar="${bar}░"
  fi
done

# Context color gradient (relative to 1M window).
if   [ "$used" -ge 90 ]; then ctx_color=$'\e[91m'        # red
elif [ "$used" -ge 75 ]; then ctx_color=$'\e[38;5;208m'  # orange
elif [ "$used" -ge 50 ]; then ctx_color=$'\e[93m'        # yellow
elif [ "$used" -ge 35 ]; then ctx_color=$'\e[38;5;148m'  # yellow-green
else                          ctx_color=$'\e[38;5;247m'  # dim
fi

dim=$'\e[38;5;247m'
cyan=$'\e[36m'
green=$'\e[92m'
red=$'\e[91m'
model_color=$'\e[38;5;252m'
reset=$'\e[0m'
sep="  "

# Git branch + uncommitted diff stats (tracked text changes).
branch=""
diff_stat=""
if [[ -n "$cwd" ]]; then
  branch=$(git --no-optional-locks -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null || true)
  [ "$branch" = "HEAD" ] && branch=$(git --no-optional-locks -C "$cwd" rev-parse --short HEAD 2>/dev/null || true)
  if [[ -n "$branch" ]] && git --no-optional-locks -C "$cwd" rev-parse HEAD >/dev/null 2>&1; then
    # Count files by lifecycle state: ?untracked ~modified ●staged ↑ahead -deleted
    counts=$(git --no-optional-locks -C "$cwd" status --porcelain 2>/dev/null \
      | awk '
        {
          x = substr($0, 1, 1); y = substr($0, 2, 1)
          if (x == "?" && y == "?") { unt++; next }
          if (x == "D" || y == "D") { del++; next }
          if (x == "M" || x == "A" || x == "R" || x == "C" || x == "T") staged++
          if (y == "M" || y == "T") mod++
        }
        END { printf "%d %d %d %d", unt+0, mod+0, staged+0, del+0 }
      ')
    read -r unt mod staged del <<<"$counts"
    ahead=$(git --no-optional-locks -C "$cwd" rev-list --count '@{u}..HEAD' 2>/dev/null || true)
    case "${ahead:-}" in ""|*[!0-9]*) ahead=0 ;; esac
    if [ "$unt" -gt 0 ] || [ "$mod" -gt 0 ] || [ "$staged" -gt 0 ] || [ "$ahead" -gt 0 ] || [ "$del" -gt 0 ]; then
      diff_stat="${sep}"
      parts=()
      [ "$unt"    -gt 0 ] && parts+=($'\e[93m'"?${unt}${reset}")
      [ "$mod"    -gt 0 ] && parts+=("${dim}~${mod}${reset}")
      [ "$staged" -gt 0 ] && parts+=("${green}●${staged}${reset}")
      [ "$ahead"  -gt 0 ] && parts+=("${cyan}↑${ahead}${reset}")
      [ "$del"    -gt 0 ] && parts+=("${red}-${del}${reset}")
      diff_stat="${diff_stat}$(IFS=' '; echo "${parts[*]}")"
    fi
  fi
fi

# Render: agent · model · effort · path · ctx · git
out=""
[ -n "$agent" ] && out+="${dim}${agent} · ${reset}"
out+="${model_color}✦ ${model}${reset}"
[ -n "$model_tier" ] && out+="${dim} ${model_tier}${reset}"
[ -n "$effort_label" ] && out+="${dim} · ${effort_label}${reset}"
out+="${sep}${dim}${cwd_short}${reset}"
if [ "$ctx_known" -eq 1 ]; then
  out+="${sep}${ctx_color}${bar} ${used}%${reset}${dim} · ${pretty}${reset}"
fi
[ "$exceeds_200k" = "true" ] && out+=" ⚠"
[ -n "$branch" ] && out+="${sep}${cyan}⌥ ${branch}${reset}${diff_stat}"

printf '%s' "$out"
