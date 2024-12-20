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

	SoundtrackFrame_RefreshTracks()
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

	for k, _ in pairs(SoundtrackAddon.db.profile.events[eventTableName]) do
		if k ~= "Preview" then -- Hide internal events
			if not Soundtrack.eventFilter or Soundtrack.eventFilter == "" then
				table.insert(Soundtrack_FlatEvents[eventTableName], k)
			elseif k ~= nil and string.find(string.lower(k), lowerEventFilter) ~= nil then
				table.insert(Soundtrack_FlatEvents[eventTableName], k)
			end
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
	--
	-- Print tree
	Soundtrack.Chat.TraceFrame("SortEvents")
	Soundtrack_OnTreeChanged(eventTableName)
	SoundtrackFrame_RefreshEvents()
end

function Soundtrack.SortAllEvents()
	for _, eventTabName in ipairs(Soundtrack_EventTabs) do
		Soundtrack.SortEvents(eventTabName)
	end
end
