Soundtrack.Cleanup = {}

local function CleanupTableEvents(savedEventTable, liveEventTable)
	local removedAny = false
	for key, _ in pairs(savedEventTable) do
		if liveEventTable[key] == nil and key ~= "Preview" then
			savedEventTable[key] = nil
			removedAny = true
			Soundtrack.Chat.Message("Found obsolete event " .. key .. " removing from saved data.")
		end
	end
	return removedAny
end

local function PurgeOldTracksFromTable(eventTableName)
	local eventTable = Soundtrack.Events.GetTable(eventTableName)
	if not eventTable then
		return
	end

	for k, v in pairs(eventTable) do
		local tracksToRemove = {}

		-- Find tracks to remove
		for _, trackName in ipairs(v.tracks) do
			if not Soundtrack_Tracks[trackName] then
				Soundtrack.Chat.Message("Removed obsolete track " .. trackName)
				table.insert(tracksToRemove, trackName)
			end
		end

		-- Remove tracks
		for _, trackToRemove in ipairs(tracksToRemove) do
			Soundtrack.Events.Remove(eventTableName, k, trackToRemove)
		end
	end
end

local function DoesEventHaveOldTracks(eventTableName)
	local eventTable = Soundtrack.Events.GetTable(eventTableName)
	if not eventTable then
		return
	end

	for _, v in pairs(eventTable) do
		-- Find tracks to remove
		for _, trackName in ipairs(v.tracks) do
			if not Soundtrack_Tracks[trackName] then
				-- Track found to remove
				return true
			end
		end
	end

	return false
end


local function OnConfirmPurgeOldTracks()
	for _, event in ipairs(Soundtrack_EventTabs) do
		PurgeOldTracksFromTable(event)
	end
end

StaticPopupDialogs["SOUNDTRACK_NO_PURGE_POPUP"] = {
	preferredIndex = 3,
	text = SOUNDTRACK_GEN_LIBRARY,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function() end,
	OnCancel = function() end,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["SOUNDTRACK_PURGE_POPUP"] = {
	preferredIndex = 3,
	text = SOUNDTRACK_PURGE_EVENTS_QUESTION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		OnConfirmPurgeOldTracks()
	end,
	OnCancel = function()
		StaticPopup_Show("SOUNDTRACK_NO_PURGE_POPUP")
	end,
	timeout = 0,
	whileDead = 1,
}

function Soundtrack.Cleanup.CleanupOldEvents()
	local cleanedTables = {}

	-- Iterate through all event tables in the profile
	for tableName, savedEventTable in pairs(SoundtrackAddon.db.profile.events) do
		-- Zone and encounter entries are player-learned and should never be purged automatically
		if tableName ~= ST_ZONE and tableName ~= ST_ENCOUNTER then
			local liveEventTable = Soundtrack.RegisteredEvents[tableName]
			if liveEventTable then
				if CleanupTableEvents(savedEventTable, liveEventTable) then
					table.insert(cleanedTables, tableName)
				end
			end
		end
	end

	-- Soundtrack_FlatEvents/Soundtrack_EventNodes still hold nodes tagged with the
	-- keys just removed, and the events UI indexes an event by that tag. Rebuild
	-- the tree for every table that lost something, the way every other removal
	-- path does.
	for _, tableName in ipairs(cleanedTables) do
		Soundtrack.SortEvents(tableName)
	end

	SoundtrackUI.UpdateEventsUI()
end

-- Removes obsolete tracks from event assignments
function Soundtrack.Cleanup.PurgeOldTracksFromEvents()
	local eventsToPurge = false
	for _, event in ipairs(Soundtrack_EventTabs) do
		if DoesEventHaveOldTracks(event) then
			eventsToPurge = true
		end
	end
	if eventsToPurge then
		StaticPopup_Show("SOUNDTRACK_PURGE_POPUP")
	end
end
