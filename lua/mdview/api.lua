---@class mdview.api
local M = {}

---@param fn fun()
local function guard(fn)
	local ok, err = xpcall(fn, debug.traceback)
	if not ok then
		vim.notify("mdview error:\n" .. tostring(err), vim.log.levels.ERROR, { title = "mdview" })
	end
end

function M.start()
	guard(function()
		require("mdview.session").start()
	end)
end

function M.stop()
	guard(function()
		require("mdview.session").stop()
	end)
end

function M.toggle()
	guard(function()
		local session = require("mdview.session")
		local util = require("mdview.util")
		if session.is_active(vim.api.nvim_get_current_buf()) then
			session.stop()
			util.notify.info("Stopped the preview")
		else
			session.start()
			util.notify.info("Started the preview")
		end
	end)
end

---@param buf? integer
---@return boolean
function M.is_active(buf)
	return require("mdview.session").is_active(buf)
end

---@return { buf: integer, port: integer, url: string }|nil
function M.status()
	return require("mdview.session").status()
end

---@param theme "dark"|"light"
function M.style(theme)
	guard(function()
		require("mdview.session").set_theme(theme)
	end)
end

---@param buf integer
local function map_buffer(buf)
	local keymap = require("mdview.config").options.keymap
	if not keymap then
		return
	end
	vim.keymap.set("n", keymap, function()
		M.toggle()
	end, { buffer = buf, silent = true, desc = "Toggle the markdown preview" })
end

---@param opts? table<string, any>  overrides for mdview.Config, see config.lua
function M.setup(opts)
	local config = require("mdview.config")
	config.setup(opts)
	local cfg = config.options

	local group = vim.api.nvim_create_augroup("MdViewKeymap", { clear = true })

	vim.api.nvim_create_autocmd("FileType", {
		group = group,
		pattern = cfg.filetypes,
		callback = function(ev)
			map_buffer(ev.buf)
		end,
	})

	for _, buf in ipairs(vim.api.nvim_list_bufs()) do
		if vim.api.nvim_buf_is_loaded(buf) then
			map_buffer(buf)
		end
	end
end

return M
