---@diagnostic disable: undefined-field
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

Utils.notify = function(msg, log_level)
	vim.notify(msg, log_level, { title = "Fast Snip" })
end

Utils.get_snippets_dir = function()
	local snippest_dir = vim.fn.expand(vim.fn.stdpath("data") .. "/fast-snip/snippets")
	if vim.fn.isdirectory(snippest_dir) == 0 then
		if vim.fn.mkdir(snippest_dir, "p") == 0 then
			return nil
		end
	end
	return snippest_dir
end

Utils.get_template_path = function()
	local runtime_paths = vim.api.nvim_list_runtime_paths()
	local template_path = vim.fn.expand(vim.fn.stdpath("data") .. "/fast-snip/template")
	-- copy template in plugin to data folder
	if vim.fn.filereadable(template_path) == 0 then
		local plugin_template_path = nil
		for _, path in ipairs(runtime_paths) do
			local from
			from, _ = path:find("fast%-snip")
			if from then
				plugin_template_path = vim.fn.expand(path .. "/lua/fast-snip/template")
				break
			end
		end
		if not plugin_template_path or vim.fn.filereadable(plugin_template_path) == 0 then
			return nil
		end
		local template_file = vim.fn.readfile(plugin_template_path)
		if vim.fn.writefile(template_file, template_path) == -1 then
			return nil
		end
	end
	return template_path
end

Utils.write_snippet_to_file = function(snippets_dir, template_file_path, regex, file_type, snippet_string)
	-- read old snippet file
	local file_path = snippets_dir .. "/" .. file_type .. ".lua"
	local old_file = nil
	local created_new_file = false
	if vim.fn.filereadable(file_path) == 0 then
		-- create snippet file form template
		old_file = vim.fn.readfile(template_file_path)
		if vim.fn.writefile(old_file, file_path) == -1 then
			return Utils.info.file_create_error, vim.log.levels.ERROR
		end
		created_new_file = true
	end
	old_file = old_file or vim.fn.readfile(file_path)
	-- find regex.
	local target_line = nil
	for line_number, line in ipairs(old_file) do
		if vim.regex(regex):match_str(line) then
			target_line = line_number
			break
		end
	end
	if not target_line then
		return Utils.info.file_illegal_error, vim.log.levels.ERROR
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
