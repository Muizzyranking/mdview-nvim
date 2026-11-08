---@class mdview.images
local M = {}

local uv = vim.uv

local MIME = {
	png = "image/png",
	jpg = "image/jpeg",
	jpeg = "image/jpeg",
	gif = "image/gif",
	webp = "image/webp",
	avif = "image/avif",
	bmp = "image/bmp",
	svg = "image/svg+xml",
}

local CSP = "Content-Security-Policy: sandbox"

---@param done fun(code: integer, ctype: string, body: string, cache: string|nil, extra: string|nil)
local function not_found(done)
	done(404, "text/plain", "not found")
end

---@param path string
---@return string|nil
local function safe_rel(path)
	local segs = {}
	for seg in path:sub(6):gmatch("[^/]+") do
		local name = seg:gsub("%%(%x%x)", function(h)
			return string.char(tonumber(h, 16))
		end)
		if name == "." or name == ".." or name:find("/", 1, true) or name:find("\0", 1, true) then
			return nil
		end
		segs[#segs + 1] = name
	end
	if #segs == 0 then
		return nil
	end
	return table.concat(segs, "/")
end

---Serve an image from under root. Path containment is checked synchronously
---(cheap syscalls); the file itself is read asynchronously so a large image
---cannot stall the editor's event loop. Replies 304 when the client's
---If-None-Match matches, so re-renders revalidate instead of re-downloading.
---@param root string
---@param root_real string
---@param path string
---@param max_bytes integer
---@param req mdview.Req
---@param done mdview.Done
function M.serve(root, root_real, path, max_bytes, req, done)
	local rel = safe_rel(path)
	local ctype = rel and MIME[(rel:match("%.(%w+)$") or ""):lower()]
	if not rel or not ctype then
		return not_found(done)
	end

	local real = uv.fs_realpath(root .. "/" .. rel)
	if not real or real:sub(1, #root_real + 1) ~= root_real .. "/" then
		return not_found(done)
	end

	uv.fs_open(real, "r", 438, function(err, fd)
		if err or not fd then
			return not_found(done)
		end

		-- Every exit path through the nesting below closes the file first.
		local function send(code, ctype_, body, cache, extra)
			uv.fs_close(fd, function() end)
			done(code, ctype_, body, cache, extra)
		end

		uv.fs_fstat(fd, function(serr, st)
			if serr or not st or st.type ~= "file" then
				return send(404, "text/plain", "not found")
			end
			if st.size > max_bytes then
				return send(
					413,
					"text/plain",
					("image larger than %.0f MB (max_image_bytes)"):format(max_bytes / 1024 / 1024)
				)
			end
			local etag = ('"%x-%x"'):format(st.mtime.sec, st.size)
			if req and req.if_none_match == etag then
				return send(304, ctype, "", "no-store", CSP .. "\r\nETag: " .. etag)
			end
			uv.fs_read(fd, st.size, 0, function(rerr, data)
				if rerr or not data then
					return send(404, "text/plain", "not found")
				end
				-- no-cache keeps the preview honest after an edit: the browser
				-- revalidates every request, and the ETag turns unchanged files
				-- into a 304 instead of a re-download.
				send(200, ctype, data, "no-cache", CSP .. "\r\nETag: " .. etag)
			end)
		end)
	end)
end

return M
