local wezterm = require 'wezterm'

local M = {}

function M.apply(config)
  config.font = wezterm.font_with_fallback({ -- default: JetBrains Mono
    'JetBrainsMono Nerd Font',
    'JetBrainsMonoNL Nerd Font',
    'Menlo',
    'Apple Color Emoji',
  })
  config.font_size = 13.0 -- default: 12.0
  config.line_height = 1.15 -- default: 1.0
  config.harfbuzz_features = { 'calt=0', 'clig=0', 'liga=0' } -- default: kern, liga, clig (off: no ==, !=, -> ligatures)

  config.color_scheme = 'Dracula' -- default: unset (built-in colors)
  config.colors = {
    -- Dracula background is #282a36; this is a ~10% lighter tint so the
    -- visual bell flash (see behavior.lua) is barely noticeable instead of
    -- flashing the default bright foreground color.
    visual_bell = '#34364a',
  }

  config.macos_window_background_blur = 20 -- default: 0
  config.native_macos_fullscreen_mode = true -- default: false
  config.window_decorations = 'RESIZE' -- default: TITLE | RESIZE
  -- config.initial_cols = 120 -- default: 80
  -- config.initial_rows = 32 -- default: 24

  config.enable_tab_bar = false -- default: true
  -- config.hide_tab_bar_if_only_one_tab = true -- default: false
  config.use_fancy_tab_bar = false -- default: true
  -- config.tab_bar_at_bottom = false -- default: false

  config.default_cursor_style = 'BlinkingBar' -- default: SteadyBlock (overridden by zsh-vi-mode in zsh)
  config.cursor_blink_rate = 500 -- default: 800
end

return M
