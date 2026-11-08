# mdview.nvim

Markdown preview in its own disposable Chrome app window.

Renders the current markdown buffer with [cmark-gfm](https://github.com/github/cmark-gfm) and shows the result in a Chrome window started in `--app` mode: no tabs, no address bar, no bookmarks. The window keeps its own profile, goes away on its own when you stop the preview or close it, and the local server dies with Neovim — no stale processes, no stray tabs in your normal browser session.

## Features

- **Live sync** — debounced re-renders while you type, and the page scrolls to follow your cursor (via `data-sourcepos`).
- **Follows across buffers** — switch buffers or files and the same window re-targets to the markdown file you open.
- **Local images** — relative image paths resolve against the file's directory (or a configurable root, e.g. the git root), served by the plugin's localhost server; large files are rejected, path traversal is blocked.
- **Link following** — relative links to markdown files open the linked file in Neovim (the preview re-targets); `http(s)` links open in your normal browser.
- **File tracking in the window title** — the Chrome window title shows the previewed file's name.
- **Dark and light** — follows `vim.o.background` by default; flip a running preview with `:MdViewStyle dark|light` without restarting the window.
- **Disposable** — each session's Chrome profile and server are torn down when the window closes, the preview stops, or Neovim exits.
- **Lean startup** — the `plugin/` entry only defines `:MdView*` commands; nothing loads until a command or keymap fires.
- Hardened: sandboxed image responses, per-request host checks, and a strict default CSP for preview document.

## Requirements

- Neovim 0.10+ (needs `vim.pack`-less? no — only `vim.loop`, stdlib)
- [`cmark-gfm`](https://github.com/github/cmark-gfm) on your `PATH`
- A Chromium-based browser (Chrome, Chromium, Brave...). If it is missing, the preview falls back to your default browser.

```sh
# Debian/Ubuntu
sudo apt install cmark-gfm

# Arch
yay -S cmark-gfm

# macOS
brew install cmark-gfm
```

## Installation

### Using `vim.pack` (Neovim 0.12+)

```lua
vim.pack.add("https://github.com/muizzyranking/mdview")

require("mdview").setup({})
```

### Lazy-load it

The plugin is already lazy-friendly and idle at startup; in a LazyVim-style spec:

```lua
{
	"muizzyranking/mdview",
	ft = { "markdown" },
	keys = {
		{ "<leader>mp", "<cmd>MdViewToggle<cr>", desc = "Toggle markdown preview" },
	},
	config = function()
		require("mdview").setup({})
	end,
}
```

`setup()` registers the buffer-local keymap (`&filetype` = markdown) and the commands come from the plugin's runtime entry, so you can also skip `keys` and rely on `ft` alone.

## Configuration

```lua
require("mdview").setup({
	keymap = "<leader>mp",          -- buffer-local keymap, false to disable
	filetypes = { "markdown" },     -- filetypes that get the keymap
	render_debounce = 250,          -- ms of pause before re-rendering
	-- image_root = function(buf)   -- where relative image paths resolve from;
	-- 	return vim.fs.root(buf, ".git")  -- nil = the markdown file's directory
	-- end,
	max_image_bytes = 20 * 1024 * 1024,  -- refuse larger local assets
	theme = nil,                    -- "dark"/"light", nil follows &background
	-- theme = "dark",
	-- browser = "google-chrome-stable",  -- any chromium binary name
	-- csp = false,  -- drop the Content-Security-Policy header
})
```

## Commands

| Command        | Description                                                |
| -------------- | ---------------------------------------------------------- |
| `MdViewStart`  | Start the preview for the current markdown buffer          |
| `MdViewStop`   | Stop the preview and close the window                      |
| `MdViewToggle` | Start if not running, stop the previewed buffer otherwise  |
| `MdViewStyle {dark\|light}` | Switch a running preview's look and remember it |

## Notes

- Unsaved buffers start an error: save first, or preview nothing but RAM.
- The default `csp` blocks scripts/frames/tracking in rendered markdown while allowing the page's own resources (and `https:`/`data:`/images, for README badges and the like). Remote markdown *scripts* are deliberately dead.
- Clicking an image or a link that has no resolvable target is reported instead of silently ignored.

## License

MIT
