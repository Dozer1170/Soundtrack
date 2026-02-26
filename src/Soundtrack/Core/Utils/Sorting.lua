local function CompareTracksByAlbum(i1, i2)
	return Soundtrack_Tracks[i1].album < Soundtrack_Tracks[i2].album
end

local function CompareTracksByArtist(i1, i2)
	return Soundtrack_Tracks[i1].artist < Soundtrack_Tracks[i2].artist
end

local function CompareTracksByTitle(i1, i2)
	return Soundtrack_Tracks[i1].title < Soundtrack_Tracks[i2].title
end

local function CompareTracksByFileName(i1, i2)
	return GetPathFileName(i1) < GetPathFileName(i2)
end

local function MatchTrack(trackName, track, filter)
	local lowerFilter = string.lower(filter)
	local index = string.find(string.lower(trackName), lowerFilter)
	if index then
		return true
	end
	index = string.find(string.lower(track.artist), lowerFilter)
	if index then
		return true
	end
	index = string.find(string.lower(track.album), lowerFilter)
	if index then
		return true
	end
	index = string.find(string.lower(track.title), lowerFilter)
	if index then
		return true
	end

	return nil
end

-- Sorts the list of tracks using the passed criteria, or uses
-- the last used sorting criteria
function Soundtrack.SortTracks(sortCriteria)
	if sortCriteria then
		Soundtrack.lastSortCriteria = sortCriteria
	else
		if Soundtrack.lastSortCriteria == nil then
			Soundtrack.lastSortCriteria = "filePath"
			sortCriteria = "filePath"
		else
			sortCriteria = Soundtrack.lastSortCriteria
		end
	end

	Soundtrack_SortedTracks = {}
	for k, v in pairs(Soundtrack_Tracks) do
		if not v.defaultTrack or SoundtrackAddon.db.profile.settings.ShowDefaultMusic then
			if not Soundtrack.trackFilter then
				table.insert(Soundtrack_SortedTracks, k)
			elseif MatchTrack(k, v, Soundtrack.trackFilter) then
				table.insert(Soundtrack_SortedTracks, k)
			end
		end
	end

	if sortCriteria == "album" then
		table.sort(Soundtrack_SortedTracks, CompareTracksByAlbum)
	elseif sortCriteria == "artist" then
		table.sort(Soundtrack_SortedTracks, CompareTracksByArtist)
	elseif sortCriteria == "filePath" then
		table.sort(Soundtrack_SortedTracks)
	elseif sortCriteria == "fileName" then
		table.sort(Soundtrack_SortedTracks, CompareTracksByFileName)
	elseif sortCriteria == "title" then
		table.sort(Soundtrack_SortedTracks, CompareTracksByTitle)
	end

	SoundtrackUI.RefreshTracks()
end

local function GetChildNode(rootNode, childNodeName)
	if not rootNode then
		return nil
	end

	for _, n in ipairs(rootNode.nodes) do
		if childNodeName == n.name then
			return n
		end
	end

	return nil
end

local function AddEventNode(rootNode, eventPath)
	if not rootNode then
		error("rootNode is nil")
	end

	local currentRootNode = rootNode
	local parts = StringSplit(eventPath, "/")
	for _, part in ipairs(parts) do
		local childNode = GetChildNode(currentRootNode, part)
		if not childNode then
			-- Add a new node if its missing
			local newNode = { name = part, nodes = {}, tag = eventPath }
			table.insert(currentRootNode.nodes, newNode)
			currentRootNode = newNode
		else
			currentRootNode = childNode
		end
	end
end

function Soundtrack.SortEvents(eventTableName)
	Soundtrack_FlatEvents[eventTableName] = {}

	local lowerEventFilter = ""
	if Soundtrack.eventFilter ~= nil then
		lowerEventFilter = string.lower(Soundtrack.eventFilter)
	end

	local eventTable = Soundtrack.Events.GetTable(eventTableName)
	if not eventTable then
		return
	end

	Soundtrack.Chat.TraceFrame(
		"Sorting events for " .. eventTableName .. " (" .. #eventTable .. ")"
	)

	if not Soundtrack.eventFilter or Soundtrack.eventFilter == "" then
		-- No filter: include every event.
		for k, _ in pairs(eventTable) do
			if k ~= "Preview" then
				table.insert(Soundtrack_FlatEvents[eventTableName], k)
			end
		end
	else
		-- Filter active: include matching events AND their ancestors/descendants so
		-- the tree renders correctly (e.g. searching "Naxxramas" also shows
		-- "Instances" above it and "Instances/Naxxramas/Plague Quarter" below it).
		local included = {}
		for k, _ in pairs(eventTable) do
			if k ~= "Preview" and string.find(string.lower(k), lowerEventFilter) ~= nil then
				included[k] = true

				-- Include every ancestor path that exists in the event table.
				local parts = StringSplit(k, "/")
				local ancestorPath = ""
				for i, part in ipairs(parts) do
					ancestorPath = i == 1 and part or (ancestorPath .. "/" .. part)
					if ancestorPath ~= k and eventTable[ancestorPath] then
						included[ancestorPath] = true
					end
				end

				-- Include every descendant path that exists in the event table.
				local prefix = k .. "/"
				for otherKey, _ in pairs(eventTable) do
					if otherKey ~= "Preview" and string.sub(otherKey, 1, #prefix) == prefix then
						included[otherKey] = true
					end
				end
			end
		end
		for k, _ in pairs(included) do
			table.insert(Soundtrack_FlatEvents[eventTableName], k)
		end
	end

	-- Only sort is user do not wish to bypass
	table.sort(Soundtrack_FlatEvents[eventTableName])

	-- Construct the event node tree, after events have been sorted
	local rootNode = { name = eventTableName, nodes = {}, tag = nil }
	for _, e in ipairs(Soundtrack_FlatEvents[eventTableName]) do
		AddEventNode(rootNode, e)
	end
	Soundtrack_EventNodes[eventTableName] = rootNode

	Soundtrack.OnEventTreeChanged(eventTableName)
	SoundtrackUI.UpdateEventsUI()
end

function Soundtrack.SortAllEvents()
	for _, eventTabName in ipairs(Soundtrack_EventTabs) do
		Soundtrack.SortEvents(eventTabName)
	end
end
