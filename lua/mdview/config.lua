---@class mdview.config
local M = {}

---@alias mdview.ImageRootFn fun(buf: integer): string|nil

---@class mdview.Config
---@field enabled boolean|fun(): boolean
---@field browser string
---@field filetypes string[]
---@field keymap string|false
---@field render_debounce integer
---@field image_root string|mdview.ImageRootFn|nil
---@field max_image_bytes integer
---@field theme "dark"|"light"|nil
---@field csp string|false

---@type mdview.Config
M.defaults = {
	enabled = true,
	browser = "google-chrome-stable",
	filetypes = { "markdown", "markdown.pandoc", "markdown.mdx" },
	keymap = "<leader>mp",
	render_debounce = 250,
	-- nil means "the markdown file's directory". Return the git root to allow ../assets/x.png.
	image_root = nil,
	max_image_bytes = 20 * 1024 * 1024,
	-- Content-Security-Policy for the preview page. The default keeps the page's own
	-- resources working and lets remote images load (README badges and the like), but
	-- stops the rendered markdown from running scripts, framing pages, submitting
	-- forms, or phoning home. Set to false to drop the header.
	csp = "default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline'; "
		.. "img-src 'self' https: data:; media-src 'self' https: data:; "
		.. "frame-src 'none'; object-src 'none'; form-action 'none'; base-uri 'none'",
	-- "dark" or "light" fixes the look; nil follows vim.o.background ("auto" counts
	-- as dark). :MdViewStyle switches a running preview and remembers the choice.
	theme = nil,
}

---@type mdview.Config
M.options = vim.deepcopy(M.defaults)

---@param opts? table<string, any>
function M.setup(opts)
	M.options = vim.tbl_extend("force", M.defaults, opts or {}) --[[@as mdview.Config]]
end

---@return boolean
function M.is_enabled()
	local e = M.options.enabled
	if type(e) == "function" then
		return e() == true
	end
	return e == true
end

return M
