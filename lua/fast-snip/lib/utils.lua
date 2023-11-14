local Utils = {}

Utils.notify = function(msg, log_level)
	vim.notify(msg, log_level, { title = "Fast Snip" })
end

Utils.get_template_path = function()
	local runtime_paths = vim.api.nvim_list_runtime_paths()
	for _, path in ipairs(runtime_paths) do
		local from
		from, _ = path:find("fast%-snip")
		if from then
			return path .. "/lua/fast-snip/template"
		end
	end
	return nil
end

Utils.get_snippets_dir = function()
	local runtime_paths = vim.api.nvim_list_runtime_paths()
	for _, path in ipairs(runtime_paths) do
		local from
		from, _ = path:find("fast%-snip")
		if from then
			return path .. "/lua/fast-snip/snippets"
		end
	end
	return nil
end

return Utils
