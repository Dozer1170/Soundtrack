function IndexOf(table, value)
	if table == nil then
		return 0
	end

	for i = 1, #table do
		if table[i] == value then
			return i
		end
	end

	return 0
end
