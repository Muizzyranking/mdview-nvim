---@class mdview.util
local M = {}

local TITLE = "mdview"

-- Directory of this file, found from its own source path so it does not depend on
-- runtimepath. The leading "@" that debug.getinfo adds is stripped.
M.dir = vim.fs.dirname(debug.getinfo(1, "S").source:sub(2))
M.assets = vim.fs.normalize(M.dir .. "/../assets")

M.notify = {}

---@param message string
function M.notify.info(message)
	vim.notify(message, vim.log.levels.INFO, { title = TITLE })
end

---@param message string
function M.notify.warn(message)
	vim.notify(message, vim.log.levels.WARN, { title = TITLE })
end

---@param message string
function M.notify.error(message)
	vim.notify(message, vim.log.levels.ERROR, { title = TITLE })
end

---@param path string
---@return string|nil
function M.read_file(path)
	local f = io.open(path, "rb")
	if not f then
		return nil
	end
	local data = f:read("*a")
	f:close()
	return data
end

---@param buf integer
---@return boolean
function M.is_markdown(buf)
	return vim.tbl_contains(require("mdview.config").options.filetypes, vim.bo[buf].filetype)
end

---@param buf integer
---@return string
function M.buf_path(buf)
	return vim.api.nvim_buf_get_name(buf)
end

---@param buf integer
---@return string
function M.buf_dir(buf)
	return vim.fs.dirname(vim.fn.fnamemodify(M.buf_path(buf), ":p"))
end

---@return string
function M.cache_dir()
	return vim.fn.stdpath("cache") .. "/mdview"
end

return M
