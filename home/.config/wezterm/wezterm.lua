-- Pull in the wezterm API
local os = require 'os'
local wezterm = require 'wezterm'
local act = wezterm.action
local mux = wezterm.mux
local resurrect = wezterm.plugin.require 'https://github.com/MLFlexer/resurrect.wezterm'
local workspace_switcher = wezterm.plugin.require 'https://github.com/MLFlexer/smart_workspace_switcher.wezterm'

-- --------------------------------------------------------------------
-- FUNCTIONS AND EVENT BINDINGS
-- --------------------------------------------------------------------

local function basename(s)
  return string.gsub(s, '(.*[/\\])(.*)', '%2')
end

-- Session Manager event bindings

-- --------------------------------------------------------------------
-- CONFIGURATION
-- --------------------------------------------------------------------

-- This table will hold the configuration.
local config = {}

-- In newer versions of wezterm, use the config_builder which will
-- help provide clearer error messages
if wezterm.config_builder then
  config = wezterm.config_builder()
end

config.adjust_window_size_when_changing_font_size = false
config.automatically_reload_config = true
config.color_scheme = 'Gruvbox Material (Gogh)'
config.enable_scroll_bar = true
config.enable_wayland = true
config.font = wezterm.font 'MesloLGS Nerd Font Mono'
config.font_size = 16.0
-- The leader is similar to how tmux defines a set of keys to hit in order to
-- invoke tmux bindings. Binding to ctrl-a here to mimic tmux
config.leader = { key = 'a', mods = 'CTRL', timeout_milliseconds = 2000 }

config.mouse_bindings = {
  -- Open URLs with Ctrl+Click
  {
    event = { Up = { streak = 1, button = 'Left' } },
    mods = 'CTRL',
    action = act.OpenLinkAtMouseCursor,
  },
}
config.pane_focus_follows_mouse = true
config.scrollback_lines = 5000
config.use_dead_keys = false
config.warn_about_missing_glyphs = false

config.window_decorations = 'RESIZE'
config.window_background_opacity = 0.94
config.macos_window_background_blur = 10
config.window_padding = {
  left = 0,
  right = 0,
  top = 10,
  bottom = 0,
}

config.initial_cols = 150
config.initial_rows = 50
-- Tab bar
config.enable_tab_bar = true
config.hide_tab_bar_if_only_one_tab = false
config.use_fancy_tab_bar = false
config.tab_bar_at_bottom = true
config.switch_to_last_active_tab_when_closing_tab = true
-- config.tab_max_width = 32
config.colors = {
  tab_bar = {
    active_tab = {
      fg_color = '#073642',
      bg_color = '#2aa198',
    },
  },
}

-- Setup muxing by default
-- config.unix_domains = {
--   {
--     name = 'unix',
--   },
-- }
-- config.default_gui_startup_args = { 'connect', 'unix' }

-- resurrect.wezterm periodic save every 5 minutes
resurrect.periodic_save {
  interval_seconds = 300,
  save_tabs = true,
  save_windows = true,
  save_workspaces = true,
}

resurrect.set_max_nlines(5000)

local function get_current_working_dir(tab)
  local current_dir = tab.active_pane and tab.active_pane.current_working_dir or { file_path = '' }
  local HOME_DIR = string.format('file://%s', os.getenv 'HOME')

  return current_dir == HOME_DIR and '.' or string.gsub(current_dir.file_path, '(.*[/\\])(.*)', '%2')
end

wezterm.on('update-right-status', function(window, pane)
  window:set_right_status(wezterm.format {
    { Attribute = { Intensity = 'Bold' } },
    { Foreground = { Color = '#2aa198' } },
    { Text = basename(window:active_workspace()) .. '  ' },
  })
end)

-- tab title
wezterm.on('format-tab-title', function(tab, tabs, panes, config, hover, max_width)
  local has_unseen_output = false
  if not tab.is_active then
    for _, pane in ipairs(tab.panes) do
      if pane.has_unseen_output then
        has_unseen_output = true
        break
      end
    end
  end

  local cwd = wezterm.format {
    { Attribute = { Intensity = 'Bold' } },
    { Text = get_current_working_dir(tab) },
  }

  local title = string.format(' [%s] %s', tab.tab_index + 1, cwd)

  if has_unseen_output then
    return {
      { Foreground = { Color = '#8866bb' } },
      { Text = title },
    }
  end

  return {
    { Text = title },
  }
end)

workspace_switcher.workspace_formatter = function(label)
  return wezterm.format {
    { Attribute = { Italic = true } },
    { Text = '󱂬 : ' .. label },
  }
end

wezterm.on('smart_workspace_switcher.workspace_switcher.created', function(window, path, label)
  -- window:gui_window():set_right_status(wezterm.format {
  --   { Attribute = { Intensity = 'Bold' } },
  --   { Foreground = { Color = '#2aa198' } },
  --   { Text = basename(path) .. '  ' },
  -- })
  local workspace_state = resurrect.workspace_state

  workspace_state.restore_workspace(resurrect.load_state(label, 'workspace'), {
    window = window,
    relative = true,
    restore_text = true,
    on_pane_restore = resurrect.tab_state.default_on_pane_restore,
  })
end)

-- wezterm.on('smart_workspace_switcher.workspace_switcher.chosen', function(window, path, label)
--   window:gui_window():set_right_status(wezterm.format {
--     { Attribute = { Intensity = 'Bold' } },
--     { Foreground = { Color = '#2aa198' } },
--     { Text = basename(path) .. '  ' },
--   })
-- end)

wezterm.on('smart_workspace_switcher.workspace_switcher.selected', function(window, path, label)
  local workspace_state = resurrect.workspace_state
  resurrect.save_state(workspace_state.get_workspace_state())
end)

-- Wezterm <-> nvim pane navigation
-- if you are *NOT* lazy-loading smart-splits.nvim (recommended)
local function is_vim(pane)
  -- this is set by the plugin, and unset on ExitPre in Neovim
  return pane:get_user_vars().IS_NVIM == 'true'
end

-- if you *ARE* lazy-loading smart-splits.nvim (not recommended)
-- you have to use this instead, but note that this will not work
-- in all cases (e.g. over an SSH connection). Also note that
-- `pane:get_foreground_process_name()` can have high and highly variable
-- latency, so the other implementation of `is_vim()` will be more
-- performant as well.
local function is_vim(pane)
  -- This gsub is equivalent to POSIX basename(3)
  -- Given "/foo/bar" returns "bar"
  -- Given "c:\\foo\\bar" returns "bar"
  local process_name = string.gsub(pane:get_foreground_process_name(), '(.*[/\\])(.*)', '%2')
  return process_name == 'nvim' or process_name == 'vim'
end

local direction_keys = {
  h = 'Left',
  j = 'Down',
  k = 'Up',
  l = 'Right',
}

local function split_nav(resize_or_move, key)
  return {
    key = key,
    mods = resize_or_move == 'resize' and 'META' or 'CTRL',
    action = wezterm.action_callback(function(win, pane)
      if is_vim(pane) then
        -- pass the keys through to vim/nvim
        win:perform_action({
          SendKey = { key = key, mods = resize_or_move == 'resize' and 'ALT' or 'CTRL' },
        }, pane)
      else
        if resize_or_move == 'resize' then
          win:perform_action({ AdjustPaneSize = { direction_keys[key], 5 } }, pane)
        else
          win:perform_action({ ActivatePaneDirection = direction_keys[key] }, pane)
        end
      end
    end),
  }
end

-- Custom key bindings
config.keys = {
  -- move between split panes
  split_nav('move', 'h'),
  split_nav('move', 'j'),
  split_nav('move', 'k'),
  split_nav('move', 'l'),
  -- resize panes
  split_nav('resize', 'h'),
  split_nav('resize', 'j'),
  split_nav('resize', 'k'),
  split_nav('resize', 'l'),
  -- -- Disable Alt-Enter combination (already used in tmux to split pane)
  -- {
  --     key = 'Enter',
  --     mods = 'ALT',
  --     action = act.DisableDefaultAssignment,
  -- },
  {
    key = 'D',
    mods = 'LEADER',
    action = wezterm.action_callback(function(win, pane)
      resurrect.fuzzy_load(win, pane, function(id)
        resurrect.delete_state(id)
      end, {
        title = 'Delete State',
        description = 'Select State to Delete and press Enter = accept, Esc = cancel, / = filter',
        fuzzy_description = 'Search State to Delete: ',
        is_fuzzy = true,
      })
    end),
  },

  -- Copy mode
  {
    key = 'e',
    mods = 'LEADER',
    action = act.ActivateCopyMode,
  },

  -- ----------------------------------------------------------------
  -- TABS
  --
  -- Where possible, I'm using the same combinations as I would in tmux
  -- ----------------------------------------------------------------

  -- Show tab navigator; similar to listing panes in tmux
  -- {
  --   key = 'w',
  --   mods = 'LEADER',
  --   action = act.ShowTabNavigator,
  -- },
  {
    key = 'w',
    mods = 'LEADER',
    action = workspace_switcher.switch_workspace(),
  },
  {
    key = 'W',
    mods = 'LEADER',
    action = wezterm.action_callback(function(win, pane)
      resurrect.save_state(resurrect.workspace_state.get_workspace_state())
    end),
  },
  -- Create a tab (alternative to Ctrl-Shift-Tab)
  {
    key = 'c',
    mods = 'LEADER',
    action = act.SpawnTab 'CurrentPaneDomain',
  },
  -- Rename current tab; analagous to command in tmux
  {
    key = ',',
    mods = 'LEADER',
    action = act.PromptInputLine {
      description = 'Enter new name for tab',
      action = wezterm.action_callback(function(window, pane, line)
        if line then
          window:active_tab():set_title(line)
        end
      end),
    },
  },
  -- Move to next/previous TAB
  {
    key = 'n',
    mods = 'LEADER',
    action = act.ActivateTabRelative(1),
  },
  {
    key = 'p',
    mods = 'LEADER',
    action = act.ActivateTabRelative(-1),
  },
  -- Close tab
  {
    key = 'X',
    mods = 'LEADER',
    action = act.CloseCurrentTab { confirm = true },
  },

  -- ----------------------------------------------------------------
  -- PANES
  --
  -- These are great and get me most of the way to replacing tmux
  -- entirely, particularly as you can use "wezterm ssh" to ssh to another
  -- server, and still retain Wezterm as your terminal there.
  -- ----------------------------------------------------------------

  -- -- Vertical split
  {
    -- |
    key = 'v',
    mods = 'LEADER',
    action = act.SplitPane {
      direction = 'Right',
      size = { Percent = 50 },
    },
  },
  -- Horizontal split
  {
    -- -
    key = 's',
    mods = 'LEADER',
    action = act.SplitPane {
      direction = 'Down',
      size = { Percent = 50 },
    },
  },

  -- Close/kill active pane
  {
    key = 'x',
    mods = 'LEADER',
    action = act.CloseCurrentPane { confirm = true },
  },
  -- Swap active pane with another one
  {
    key = '{',
    mods = 'LEADER',
    action = act.PaneSelect { mode = 'SwapWithActiveKeepFocus' },
  },
  -- Zoom current pane (toggle)
  {
    key = 'm',
    mods = 'LEADER',
    action = act.TogglePaneZoomState,
  },
  {
    key = 'f',
    mods = 'ALT',
    action = act.TogglePaneZoomState,
  },
  -- rotate panes
  {
    key = '1',
    mods = 'LEADER',
    action = wezterm.action.RotatePanes 'Clockwise',
  },
  -- show the pane selection mode, but have it swap the active and selected panes
  {
    mods = 'LEADER',
    key = '0',
    action = wezterm.action.PaneSelect {
      mode = 'SwapWithActive',
    },
  },
  -- -- Move to next/previous pane
  -- {
  --   key = ';',
  --   mods = 'LEADER',
  --   action = act.ActivatePaneDirection 'Prev',
  -- },
  -- {
  --   key = 'o',
  --   mods = 'LEADER',
  --   action = act.ActivatePaneDirection 'Next',
  -- },

  -- ----------------------------------------------------------------
  -- Workspaces
  --
  -- These are roughly equivalent to tmux sessions.
  -- ----------------------------------------------------------------

  -- Attach to muxer
  {
    key = 'a',
    mods = 'LEADER',
    action = act.AttachDomain 'unix',
  },

  -- Detach from muxer
  {
    key = 'd',
    mods = 'LEADER',
    action = act.DetachDomain { DomainName = 'unix' },
  },

  -- Show list of workspaces
  {
    key = 's',
    mods = 'LEADER',
    action = act.ShowLauncherArgs { flags = 'WORKSPACES' },
  },
}

-- and finally, return the configuration to wezterm
return config
