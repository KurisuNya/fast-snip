local Table = {}

Table.to_table = function(value)
	return type(value) ~= "table" and { value } or value
end

Table.append_table = function(table_to_append, table_append)
	local new_table = {}
	for _, value in ipairs(table_to_append) do
		table.insert(new_table, value)
	end
	for _, value in ipairs(table_append) do
		table.insert(new_table, value)
	end
	return new_table
end

Table.insert_table = function(insert_index, table_to_insert, table_insert)
	local new_table = {}
	for index, value in ipairs(table_to_insert) do
		if index == insert_index then
			new_table = Table.append_table(new_table, table_insert)
		end
		table.insert(new_table, value)
	end
	return new_table
end

return Table
