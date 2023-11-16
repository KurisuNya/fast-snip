---@diagnostic disable: need-check-nil, undefined-field, param-type-mismatch
local utils = require("fast-snip.lib.utils")
local format_session = require("fast-snip.lib.format-session").FormatSession

-- if you want to use custom template, remember to add
-- a line match the regex, so plugin can add the snippet
-- to the correct position
local defaults_options = {
	snippets_dir = nil, -- use defaults dir vim.fn.stdpath("data") .. "/fast-snip/snippets"
	template_file_path = nil, -- use plugin defaults template file
	regex = [[-\+ generated snippets]], -- regex pattern
	format_config = nil, -- see "fast-snip.lib.format-session"
}

local snippets_dir = nil
local current_session = nil
local template_file_path = nil

local M = {}
M.reload_snippets = function()
	-- check snippets dir
	if vim.fn.isdirectory(snippets_dir) == 0 then
		utils.notify(utils.info.snip_dir_error, vim.log.levels.ERROR)
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
		utils.notify(utils.info.session_create_info, vim.log.levels.INFO)
	-- add placeholder
	else
		current_session:add_placeholder()
		utils.notify(utils.info.placeholder_add_info, vim.log.levels.INFO)
	end
end

M.finalize_snippet = function()
	-- pre check
	if vim.fn.isdirectory(snippets_dir) == 0 then
		utils.notify(utils.info.snip_dir_error, vim.log.levels.ERROR)
		return
	end
	if vim.fn.filereadable(template_file_path) == 0 then
		utils.notify(utils.info.template_file_error, vim.log.levels.ERROR)
		return
	end
	-- detect session
	if not current_session then
		utils.notify(utils.info.snip_empty_error, vim.log.levels.ERROR)
		return
	end
	-- create snippet
	local file_type = vim.bo.ft
	vim.ui.input({ prompt = "Enter trigger word: " }, function(trigger)
		if not trigger then
			utils.notify(utils.info.trigger_empty_error, vim.log.levels.ERROR)
			return
		end
		current_session:set_trigger(trigger)
		local snippet_string = current_session:produce_final_snippet()
		local info, log_level = utils.write_snippet_to_file(
			snippets_dir,
			template_file_path,
			defaults_options.regex,
			file_type,
			snippet_string
		)
		current_session = nil
		utils.notify(info, log_level)
	end)
end

M.setup = function(opts)
	-- read user opts
	defaults_options = vim.tbl_deep_extend("force", defaults_options, opts or {})
	snippets_dir = defaults_options.snippets_dir or utils.get_snippets_dir()
	template_file_path = defaults_options.template_file_path or utils.get_template_path()
	-- pre check
	if vim.fn.isdirectory(snippets_dir) == 0 then
		utils.notify(utils.info.snip_dir_error, vim.log.levels.ERROR)
		return
	end
	if vim.fn.filereadable(template_file_path) == 0 then
		utils.notify(utils.info.template_file_error, vim.log.levels.ERROR)
		return
	end
	snippets_dir = vim.fs.normalize(snippets_dir)
	template_file_path = vim.fs.normalize(template_file_path)
	require("luasnip.loaders.from_lua").lazy_load({ paths = snippets_dir })
end
return M
