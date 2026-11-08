--- mdview: markdown preview in its own disposable Chrome app window.
---
--- What it does:
---   Renders the current markdown buffer with cmark-gfm and shows it in a Chrome
---   window started in --app mode. The window has no tabs, address bar, or
---   bookmarks. It stays in sync with the cursor and with edits, follows local
---   images, opens markdown links in Neovim itself, and closes when the session
---   ends.
---
--- Why it exists:
---   Most preview plugins open their page as a tab in your existing Chrome
---   session. mdview uses a separate, disposable window instead: its own
---   profile, no browser chrome, and it goes away on its own when you stop the
---   preview or close the window. That keeps it out of your browsing session
---   and makes the preview feel like part of the editor.
---
--- Usage:
---   The plugin/mdview.lua entry defines the :MdView* commands, and nothing
---   heavier loads until one of them runs, or until setup() maps its buffer
---   keymap. See README.md for examples.
---   - :MdViewToggle / :MdViewStart / :MdViewStop on a markdown buffer
---   - :MdViewStyle [dark|light] to switch the look of a running preview
---
---@class mdview
local M = {}

local api = require("mdview.api")

M.setup = api.setup
M.start = api.start
M.stop = api.stop
M.toggle = api.toggle
M.style = api.style
M.is_active = api.is_active
M.status = api.status

return M
