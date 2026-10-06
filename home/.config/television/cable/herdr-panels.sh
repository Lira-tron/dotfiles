#!/usr/bin/env bash
# Emit workspace, directory, pane, agent, and worktree rows for the Herdr picker.
# Format per line: <display>\t<path-or-id>\t<target>\t<context>
# Context is the preview pane for workspaces and the tab ID for panes/agents.
set -uo pipefail

MODE=${1:-all}

if [[ -n ${TELEVISION_DATA:-} ]]; then
  TV_DATA_DIR=$TELEVISION_DATA
elif [[ ${XDG_DATA_HOME:-} == /* ]]; then
  TV_DATA_DIR=$XDG_DATA_HOME/television
elif [[ $OSTYPE == darwin* ]]; then
  TV_DATA_DIR="$HOME/Library/Application Support/com.television"
else
  TV_DATA_DIR=$HOME/.local/share/television
fi
FRECENCY_FILE=$TV_DATA_DIR/frecency.json
[[ -r $FRECENCY_FILE ]] || FRECENCY_FILE=/dev/null

DIRECTORY_ROWS=''
if [[ $MODE == all ]]; then
  DIRECTORY_ROWS=$(fd -t d -d 1 . "$HOME/workplace" --format '[dir] {/}	{}	{/}')
fi

herdr api snapshot 2>/dev/null |
  jq -r --arg mode "$MODE" --arg directories "$DIRECTORY_ROWS" --slurpfile history "$FRECENCY_FILE" '
    .result.snapshot as $snapshot |

    # Count selections by pane ID, independent of changing agent status or labels.
    (reduce (
      ($history[0].channels["herdr-workspaces"] // {})[]
      | select(.raw | startswith("[agent] "))
    ) as $record ({};
      ($record.raw | split("\t")[2]) as $pane_id |
      .[$pane_id] = ((.[$pane_id] // 0) + $record.access_count)
    )) as $frequency |

    def status_icon:
      {
        blocked: "×",
        working: "◐",
        # Television 0.15.9 filters U+2713; its Nerd Font checkmark renders correctly.
        done: "\uf00c",
        idle: "○"
      }[. // "unknown"] // "·";

    def workspace_rows:
      $snapshot.workspaces[] as $workspace |
      (first(
        $snapshot.layouts[]
        | select(.tab_id == $workspace.active_tab_id)
        | .focused_pane_id
      )) as $preview_pane |
      "[workspace] \($workspace.label)\t\($workspace.workspace_id)\t\($workspace.workspace_id)\t\($preview_pane)";

    def pane_rows:
      [
        $snapshot.panes[] as $pane |
        (first($snapshot.tabs[] | select(.tab_id == $pane.tab_id))) as $tab |
        (first($snapshot.workspaces[] | select(.workspace_id == $pane.workspace_id))) as $workspace |
        { pane: $pane, tab: $tab, workspace: $workspace }
      ]
      | sort_by([-.tab.pane_count, .workspace.number, .tab.number, .pane.pane_id])
      | .[]
      | "[pane] \(.workspace.label) │ \(.tab.label) │ \(.pane.pane_id) · \(.pane.agent // .pane.terminal_title_stripped // "shell")  (\(.tab.pane_count)p)\t\(.pane.foreground_cwd // .pane.cwd)\t\(.pane.pane_id)\t\(.tab.tab_id)";

    def agent_rows:
      [
        $snapshot.agents[] as $agent |
        (first($snapshot.tabs[] | select(.tab_id == $agent.tab_id))) as $tab |
        (first($snapshot.workspaces[] | select(.workspace_id == $agent.workspace_id))) as $workspace |
        { agent: $agent, tab: $tab, workspace: $workspace }
      ]
      | sort_by([-($frequency[.agent.pane_id] // 0), .workspace.number, .tab.number, .agent.pane_id])
      | .[]
      | "[agent] \(.agent.agent_status | status_icon) \(.workspace.label) · \(.tab.label) · \(.agent.pane_id) · \(.agent.agent) · \(.agent.agent_status)\t\(.agent.foreground_cwd // .agent.cwd)\t\(.agent.pane_id)\t\(.tab.tab_id)";

    if $mode == "all" then
      workspace_rows,
      ($directories | split("\n")[] | select(length > 0)),
      pane_rows,
      agent_rows
    elif $mode == "workspaces" then
      workspace_rows
    elif $mode == "panes" then
      pane_rows
    elif $mode == "agents" then
      agent_rows
    else
      error("unknown mode: \($mode)")
    end
  '

if [[ $MODE == all ]]; then
  python3 "$HOME/.config/television/cable/worktrees.py" current
fi
