local Table = require("fast-snip.lib.table")
local Strings = require("fast-snip.lib.strings")
local Utils = {}

Utils.info = {
	snip_dir_error = "Can't find snippets dir.",
	template_file_error = "Can't read template file.",
	file_illegal_error = "Can't find line match regex.",
	file_create_error = "Can't create snippet file.",
	snip_create_error = "Can't write snippet to file.",
	snip_empty_error = "Can't create empty snippet.",
	trigger_empty_error = "Can't add empty trigger.",
	session_create_info = "Creating new snippet...",
	snip_create_info = "Create new snippet success.",
	placeholder_add_info = "Add snippet placeholder success.",
}

Utils.__file_copy = function(from_file_path, to_file_path)
	local from_file = nil
	from_file = vim.fn.readfile(from_file_path)
	if vim.fn.writefile(from_file, to_file_path) == -1 then
		return false
	end
	return true
end

Utils.notify = function(msg, log_level)
	vim.notify(msg, log_level, { title = "Fast Snip" })
end

Utils.get_snippets_dir = function()
	local snippest_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/fast-snip/snippets")
	if vim.fn.isdirectory(snippest_dir) == 1 then
		return snippest_dir
	end
	if vim.fn.mkdir(snippest_dir, "p") == 0 then
		return nil
	end
	return snippest_dir
end

Utils.get_template_path = function()
	local template_path = vim.fn.expand(vim.fn.stdpath("data") .. "/fast-snip/template")
	if vim.fn.filereadable(template_path) == 1 then
		return template_path
	end
	-- copy template in plugin to data folder
	local runtime_paths = vim.api.nvim_list_runtime_paths()
	local plugin_path_index = Strings.find_first_match_lua(runtime_paths, "fast%-snip")
	local plugin_template_path = vim.fn.expand(runtime_paths[plugin_path_index] .. "/lua/fast-snip/template")
	if not Utils.__file_copy(plugin_template_path, template_path) then
		return nil
	end
	return template_path
end

Utils.write_snippet_to_file = function(snippets_dir, template_file_path, regex, file_type, snippet_string)
	-- read old snippet file
	local file_path = snippets_dir .. "/" .. file_type .. ".lua"
	local created_new_file = false
	if vim.fn.filereadable(file_path) == 0 then
		-- create snippet file form template
		if not Utils.__file_copy(template_file_path, file_path) then
			return Utils.info.file_create_error, vim.log.levels.ERROR
		end
		created_new_file = true
	end
	local old_file = vim.fn.readfile(file_path)
	-- find regex.
	local target_line = Strings.find_first_match_regex(old_file, regex)
	if not target_line then
		return Utils.info.file_illegal_error, vim.log.levels.ERROR
	end
	-- write snip to file
	local new_file = Table.insert_table(target_line, old_file, vim.split(snippet_string, "\n"))
	if vim.fn.writefile(new_file, file_path) == -1 then
		return Utils.info.snip_create_error, vim.log.levels.ERROR
	end
	if created_new_file then
		require("luasnip.loaders.from_lua").lazy_load({ paths = snippets_dir })
	else
		require("luasnip.loaders").reload_file(vim.fn.expand(file_path)) -- hot reloading with LuaSnip
	end
	return Utils.info.snip_create_info, vim.log.levels.INFO
end

return Utils
