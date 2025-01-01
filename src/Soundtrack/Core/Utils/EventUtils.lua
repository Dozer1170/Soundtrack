-- Replaces each folder in an event path with spaces
function GetLeafText(eventPath)
	if eventPath then
		return string.gsub(eventPath, "[^/]*/", "    ")
	else
		return eventPath
	end
end

-- Counts the number of / in a path to calculate the depth
function GetEventDepth(eventPath)
	local count = 0
	local i = 0
	while true do
		i = string.find(eventPath, "/", i + 1)
		-- find 'next' newline
		if i == nil then
			return count
		end
		count = count + 1
	end
end

function GetFlatEventsTable()
	return Soundtrack_FlatEvents[SoundtrackUI.SelectedEventsTable]
end
