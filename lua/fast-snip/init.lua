---@diagnostic disable: need-check-nil, undefined-field, param-type-mismatch
local utils = require("fast-snip.lib.utils")
local format_session = require("fast-snip.lib.format-session").FormatSession

-- if you want to use custom template, remember to add
-- a line match the regex, so plugin can add the snippet
-- to the correct position
local defaults_options = {
	snippets_dir = nil, -- use plugin snippets dir
	template_file_path = nil, -- use plugin defaults template
	format_config = nil, -- see "fast-snip.lib.format-session"
	regex = [[-\+ generated snippets]],
}
local snippets_dir = nil
local current_session = nil
local template_file_path = nil

local write_snippet_to_file = function(file_type, snippet_string)
	-- pre check
	if vim.fn.isdirectory(snippets_dir) == 0 then
		utils.notify("Can't find snippets dir.", vim.log.levels.ERROR)
		return
	end
	if vim.fn.filereadable(template_file_path) == 0 then
		utils.notify("can't read template file.", vim.log.levels.ERROR)
		return
	end
	-- read old snippet file
	local file_path = snippets_dir .. "/" .. file_type .. ".lua"
	local old_file = nil
	local created_new_file = false
	if vim.fn.filereadable(file_path) == 0 then
		-- create snippet file form template
		old_file = vim.fn.readfile(template_file_path)
		if vim.fn.writefile(old_file, file_path) == -1 then
			utils.notify("Can't create snippet file.", vim.log.levels.ERROR)
			return
		end
		created_new_file = true
	end
	old_file = old_file or vim.fn.readfile(file_path)
	-- find regex.
	local regex = vim.regex(defaults_options.regex)
	local target_line = nil
	for line_number, line in ipairs(old_file) do
		if regex:match_str(line) then
			target_line = line_number
			break
		end
	end
	if not target_line then
		utils.notify("Snippet file format illegal.", vim.log.levels.ERROR)
		return
	end
	-- generate new file
	local new_file = {}
	for line_number, line in ipairs(old_file) do
		if line_number == target_line then
			for _, snippet_line in ipairs(vim.split(snippet_string, "\n")) do
				table.insert(new_file, snippet_line)
			end
		end
		table.insert(new_file, line)
	end
	if vim.fn.writefile(new_file, file_path) == -1 then
		utils.notify("Can't write snippet to file.", vim.log.levels.ERROR)
		return
	end
	utils.notify("Creating new snippet success.", vim.log.levels.INFO)
	-- reload snippet file
	if created_new_file then
		require("luasnip.loaders.from_lua").lazy_load({ paths = snippets_dir })
	else
		require("luasnip.loaders").reload_file(vim.fn.expand(file_path)) -- hot reloading with LuaSnip
	end
end

local M = {}
M.reload_snippets = function()
	-- check snippets dir
	if vim.fn.isdirectory(snippets_dir) == 0 then
		utils.notify("Can't find snippets dir.", vim.log.levels.ERROR)
		return
	end
	-- reload all snippets in dir
	local files = require("plenary.scandir").scan_dir(snippets_dir, { hidden = true, depth = 1 })
	for _, path in pairs(files) do
		require("luasnip.loaders").reload_file(path)
	end
end
M.new_snippet_or_add_placeholder = function()
	-- create new snippet
	if not current_session then
		current_session = format_session:new(defaults_options.format_config)
		utils.notify("Creating new snippet...", vim.log.levels.INFO)
	-- add placeholder
	else
		current_session:add_placeholder()
		utils.notify("Add snippet placeholder success.", vim.log.levels.INFO)
	end
end
M.finalize_snippet = function()
	-- detect session
	if not current_session then
		utils.notify("Can't find snippets dir.", vim.log.levels.ERROR)
		return
	end
	-- create snippet
	local file_type = vim.bo.ft
	vim.ui.input({ prompt = "Enter trigger word: " }, function(trigger)
		if trigger then
			current_session:set_trigger(trigger)
			local snippet_string = current_session:produce_final_snippet()
			write_snippet_to_file(file_type, snippet_string)
			current_session = nil
		else
			utils.notify("Trigger word can't be empty.", vim.log.levels.ERROR)
		end
	end)
end
M.setup = function(opts)
	-- read user opts
	defaults_options = vim.tbl_deep_extend("force", defaults_options, opts or {})
	snippets_dir = defaults_options.snippets_dir or utils.get_snippets_dir()
	template_file_path = defaults_options.template_file_path or utils.get_template_path()
	snippets_dir = vim.fs.normalize(snippets_dir)
	template_file_path = vim.fs.normalize(template_file_path)
	-- load snippets
	if vim.fn.isdirectory(snippets_dir) == 0 then
		utils.notify("Can't find snippets dir.", vim.log.levels.ERROR)
		return
	end
	require("luasnip.loaders.from_lua").lazy_load({ paths = snippets_dir })
end
return M
