Soundtrack.Cleanup = {}

local function CleanupTableEvents(savedEventTable, liveEventTable)
	for key, _ in pairs(savedEventTable) do
		if liveEventTable[key] == nil and key ~= "Preview" then
			savedEventTable[key] = nil
			Soundtrack.Chat.Message("Found obsolete event " .. key .. " removing from saved data.")
		end
	end
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

local function CleanupDuplicateBossEvents()
	local bossEventTable = SoundtrackAddon.db.profile.events[ST_BOSS]
	if not bossEventTable then
		return
	end

	-- Remove boss events that contain "Low Health" since they're obsolete
	for key, _ in pairs(bossEventTable) do
		if string.find(key, "Low Health") then
			bossEventTable[key] = nil
			Soundtrack.Chat.Message("Found obsolete boss event " .. key .. " removing from saved data.")
		end
	end
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
	CleanupTableEvents(SoundtrackAddon.db.profile.events[ST_BATTLE], Soundtrack.RegisteredEvents[ST_BATTLE])
	CleanupTableEvents(SoundtrackAddon.db.profile.events[ST_MISC], Soundtrack.RegisteredEvents[ST_MISC])
	CleanupDuplicateBossEvents()

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
