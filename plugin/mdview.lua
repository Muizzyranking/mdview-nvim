--- mdview.nvim: markdown preview in its own disposable Chrome app window.
---
--- Startup entry, deliberately minimal: it only defines the :MdView* commands.
--- No module loads, no autocmd runs, and no file is read until a command or
--- keymap fires. Keymaps are mapped per markdown buffer by setup(); see
--- README.md for the recommended lazy-load dance.
for _, cmd in ipairs({
	{ name = "MdViewStart", desc = "Start the markdown preview" },
	{ name = "MdViewStop", desc = "Stop the markdown preview" },
	{ name = "MdViewToggle", desc = "Toggle the markdown preview" },
}) do
	vim.api.nvim_create_user_command(cmd.name, function()
		require("mdview")[string.gsub(string.lower(cmd.name), "^mdview", "")]()
	end, { desc = cmd.desc })
end

vim.api.nvim_create_user_command("MdViewStyle", function(o)
	require("mdview").style(o.args)
end, {
	desc = "Switch the preview's dark/light look and remember it",
	nargs = 1,
	complete = function()
		return { "dark", "light" }
	end,
})
