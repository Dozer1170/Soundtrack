if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

function Tests:CleanupOldEvents_RemovesObsoleteEvents()
	-- Setup: Initialize RegisteredEvents and profile.events structures
	Soundtrack.RegisteredEvents[ST_BATTLE] = Soundtrack.RegisteredEvents[ST_BATTLE] or {}
	Soundtrack.RegisteredEvents[ST_MISC] = Soundtrack.RegisteredEvents[ST_MISC] or {}
	Soundtrack.RegisteredEvents[ST_ZONE] = Soundtrack.RegisteredEvents[ST_ZONE] or {}
	Soundtrack.RegisteredEvents[ST_PETBATTLES] = Soundtrack.RegisteredEvents[ST_PETBATTLES] or {}
	
	if not SoundtrackAddon.db.profile.events then
		SoundtrackAddon.db.profile.events = {}
	end
	
	-- Create events in saved data that are not in registered events across multiple tables
	SoundtrackAddon.db.profile.events[ST_BATTLE] = {
		ValidEvent = { tracks = {} },
		ObsoleteEvent = { tracks = {} },
	}
	
	SoundtrackAddon.db.profile.events[ST_ZONE] = {
		ValidZone = { tracks = {} },
		ObsoleteZone = { tracks = {} },
	}
	
	SoundtrackAddon.db.profile.events[ST_MISC] = SoundtrackAddon.db.profile.events[ST_MISC] or {}
	SoundtrackAddon.db.profile.events[ST_PETBATTLES] = SoundtrackAddon.db.profile.events[ST_PETBATTLES] or {}
	
	Soundtrack.RegisteredEvents[ST_BATTLE] = {
		ValidEvent = { tracks = {} },
		-- ObsoleteEvent is not registered, should be removed
	}
	
	Soundtrack.RegisteredEvents[ST_ZONE] = {
		ValidZone = { tracks = {} },
		-- ObsoleteZone is not registered, should be removed
	}
	
	-- Mock UpdateEventsUI
	local updateCalled = false
	Replace(SoundtrackUI, "UpdateEventsUI", function()
		updateCalled = true
	end)
	
	-- Run cleanup
	Soundtrack.Cleanup.CleanupOldEvents()
	
	-- Obsolete events should be removed from all tables
	Exists(SoundtrackAddon.db.profile.events[ST_BATTLE].ObsoleteEvent == nil and "Obsolete battle event removed" or nil)
	Exists(SoundtrackAddon.db.profile.events[ST_BATTLE].ValidEvent ~= nil and "Valid battle event kept" or nil)
	Exists(SoundtrackAddon.db.profile.events[ST_ZONE].ObsoleteZone == nil and "Obsolete zone event removed" or nil)
	Exists(SoundtrackAddon.db.profile.events[ST_ZONE].ValidZone ~= nil and "Valid zone event kept" or nil)
	Exists(updateCalled and "UI updated" or nil)
end

function Tests:CleanupOldEvents_PreservesPreviewEvent()
	-- Setup: Initialize RegisteredEvents and profile.events structures
	Soundtrack.RegisteredEvents[ST_BATTLE] = Soundtrack.RegisteredEvents[ST_BATTLE] or {}
	Soundtrack.RegisteredEvents[ST_MISC] = Soundtrack.RegisteredEvents[ST_MISC] or {}
	
	if not SoundtrackAddon.db.profile.events then
		SoundtrackAddon.db.profile.events = {}
	end
	
	-- Preview event should not be removed even if not registered
	SoundtrackAddon.db.profile.events[ST_BATTLE] = {
		Preview = { tracks = {} },
	}
	
	SoundtrackAddon.db.profile.events[ST_MISC] = SoundtrackAddon.db.profile.events[ST_MISC] or {}
	
	Soundtrack.RegisteredEvents[ST_BATTLE] = {
		-- Preview not in registered events
	}
	
	-- Run cleanup
	Soundtrack.Cleanup.CleanupOldEvents()
	
	-- Preview should be preserved
	Exists(SoundtrackAddon.db.profile.events[ST_BATTLE].Preview ~= nil and "Preview event preserved" or nil)
end

function Tests:CleanupOldEvents_HandlesMiscEvents()
	-- Setup: Initialize RegisteredEvents and profile.events structures
	Soundtrack.RegisteredEvents[ST_BATTLE] = Soundtrack.RegisteredEvents[ST_BATTLE] or {}
	Soundtrack.RegisteredEvents[ST_MISC] = Soundtrack.RegisteredEvents[ST_MISC] or {}
	
	if not SoundtrackAddon.db.profile.events then
		SoundtrackAddon.db.profile.events = {}
	end
	
	SoundtrackAddon.db.profile.events[ST_BATTLE] = SoundtrackAddon.db.profile.events[ST_BATTLE] or {}
	
	-- Test with MISC event table
	SoundtrackAddon.db.profile.events[ST_MISC] = {
		ValidMiscEvent = { tracks = {} },
		ObsoleteMiscEvent = { tracks = {} },
	}
	
	Soundtrack.RegisteredEvents[ST_MISC] = {
		ValidMiscEvent = { tracks = {} },
	}
	
	-- Run cleanup
	Soundtrack.Cleanup.CleanupOldEvents()
	
	-- ObsoleteMiscEvent should be removed
	Exists(SoundtrackAddon.db.profile.events[ST_MISC].ObsoleteMiscEvent == nil and "Obsolete misc event removed" or nil)
	Exists(SoundtrackAddon.db.profile.events[ST_MISC].ValidMiscEvent ~= nil and "Valid misc event kept" or nil)
end

function Tests:PurgeOldTracksFromEvents_ShowsPopupWhenOldTracksFound()
	-- Setup: Create event with obsolete track
	local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
	eventTable["TestEvent"] = {
		tracks = { "ValidTrack.mp3", "ObsoleteTrack.mp3" }
	}
	
	-- Add only the valid track to library
	Soundtrack_Tracks["ValidTrack.mp3"] = { filePath = "ValidTrack.mp3" }
	-- ObsoleteTrack.mp3 is not in library
	
	-- Mock StaticPopup_Show
	local popupShown = false
	Replace(_G, "StaticPopup_Show", function(name)
		if name == "SOUNDTRACK_PURGE_POPUP" then
			popupShown = true
		end
	end)
	
	-- Run purge check
	Soundtrack.Cleanup.PurgeOldTracksFromEvents()
	
	-- Popup should be shown
	Exists(popupShown and "Purge popup shown" or nil)
end

function Tests:PurgeOldTracksFromEvents_DoesNotShowPopupWhenNoOldTracks()
	-- Setup: Create event with only valid tracks
	local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
	eventTable["TestEvent"] = {
		tracks = { "ValidTrack1.mp3", "ValidTrack2.mp3" }
	}
	
	-- Add all tracks to library
	Soundtrack_Tracks["ValidTrack1.mp3"] = { filePath = "ValidTrack1.mp3" }
	Soundtrack_Tracks["ValidTrack2.mp3"] = { filePath = "ValidTrack2.mp3" }
	
	-- Mock StaticPopup_Show
	local popupShown = false
	Replace(_G, "StaticPopup_Show", function(name)
		if name == "SOUNDTRACK_PURGE_POPUP" then
			popupShown = true
		end
	end)
	
	-- Run purge check
	Soundtrack.Cleanup.PurgeOldTracksFromEvents()
	
	-- Popup should NOT be shown
	Exists(not popupShown and "Purge popup not shown" or nil)
end

function Tests:PurgeOldTracksFromEvents_ChecksAllEventTables()
	-- Setup: Create events in multiple tables with obsolete tracks
	local battleTable = Soundtrack.Events.GetTable(ST_BATTLE)
	battleTable["BattleEvent"] = {
		tracks = { "ObsoleteTrack1.mp3" }
	}
	
	local zoneTable = Soundtrack.Events.GetTable(ST_ZONE)
	zoneTable["ZoneEvent"] = {
		tracks = { "ValidTrack.mp3" }
	}
	
	-- Add only one valid track
	Soundtrack_Tracks["ValidTrack.mp3"] = { filePath = "ValidTrack.mp3" }
	-- ObsoleteTrack1.mp3 is not in library
	
	-- Mock StaticPopup_Show
	local popupShown = false
	Replace(_G, "StaticPopup_Show", function(name)
		if name == "SOUNDTRACK_PURGE_POPUP" then
			popupShown = true
		end
	end)
	
	-- Run purge check
	Soundtrack.Cleanup.PurgeOldTracksFromEvents()
	
	-- Popup should be shown because at least one table has obsolete tracks
	Exists(popupShown and "Purge popup shown for any table with old tracks" or nil)
end

function Tests:PurgePopup_OnAcceptRemovesOldTracks()
	-- Setup: Create event with obsolete tracks
	local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
	eventTable["TestEvent"] = {
		tracks = { "ValidTrack.mp3", "ObsoleteTrack.mp3" }
	}
	
	Soundtrack_Tracks["ValidTrack.mp3"] = { filePath = "ValidTrack.mp3" }
	
	-- Mock Events.Remove to track calls
	local removedTracks = {}
	Replace(Soundtrack.Events, "Remove", function(tableName, eventName, trackName)
		table.insert(removedTracks, { table = tableName, event = eventName, track = trackName })
	end)
	
	-- Trigger the OnAccept callback directly
	if StaticPopupDialogs["SOUNDTRACK_PURGE_POPUP"] and StaticPopupDialogs["SOUNDTRACK_PURGE_POPUP"].OnAccept then
		StaticPopupDialogs["SOUNDTRACK_PURGE_POPUP"].OnAccept()
	end
	
	-- Check that obsolete track was removed
	Exists(#removedTracks > 0 and "Tracks were removed" or nil)
	
	-- Verify the obsolete track was in the removal list
	local foundObsolete = false
	for _, removal in ipairs(removedTracks) do
		if removal.track == "ObsoleteTrack.mp3" then
			foundObsolete = true
		end
	end
	Exists(foundObsolete and "Obsolete track was removed" or nil)
end

function Tests:PurgePopup_OnCancelShowsNoPurgePopup()
	-- Mock StaticPopup_Show to track calls
	local noPurgeShown = false
	Replace(_G, "StaticPopup_Show", function(name)
		if name == "SOUNDTRACK_NO_PURGE_POPUP" then
			noPurgeShown = true
		end
	end)
	
	-- Trigger the OnCancel callback
	if StaticPopupDialogs["SOUNDTRACK_PURGE_POPUP"] and StaticPopupDialogs["SOUNDTRACK_PURGE_POPUP"].OnCancel then
		StaticPopupDialogs["SOUNDTRACK_PURGE_POPUP"].OnCancel()
	end
	
	-- Check that no-purge popup was shown
	Exists(noPurgeShown and "No purge popup shown" or nil)
end

function Tests:PurgeOldTracks_HandlesEmptyEventTable()
	-- Setup: Clear all events
	for _, eventTabName in ipairs(Soundtrack_EventTabs) do
		local eventTable = Soundtrack.Events.GetTable(eventTabName)
		for k in pairs(eventTable) do
			eventTable[k] = nil
		end
	end
	
	-- Mock StaticPopup_Show
	local popupShown = false
	Replace(_G, "StaticPopup_Show", function(name)
		if name == "SOUNDTRACK_PURGE_POPUP" then
			popupShown = true
		end
	end)
	
	-- Run purge check
	Soundtrack.Cleanup.PurgeOldTracksFromEvents()
	
	-- Popup should NOT be shown for empty tables
	Exists(not popupShown and "No popup for empty tables" or nil)
end

function Tests:CleanupOldEvents_HandlesEmptyRegisteredEvents()
	-- Setup: Initialize RegisteredEvents and profile.events structures
	Soundtrack.RegisteredEvents[ST_BATTLE] = Soundtrack.RegisteredEvents[ST_BATTLE] or {}
	Soundtrack.RegisteredEvents[ST_MISC] = Soundtrack.RegisteredEvents[ST_MISC] or {}
	Soundtrack.RegisteredEvents[ST_ZONE] = Soundtrack.RegisteredEvents[ST_ZONE] or {}
	Soundtrack.RegisteredEvents[ST_DANCE] = Soundtrack.RegisteredEvents[ST_DANCE] or {}
	
	if not SoundtrackAddon.db.profile.events then
		SoundtrackAddon.db.profile.events = {}
	end
	
	-- Empty registered events - events in profile should be removed
	SoundtrackAddon.db.profile.events[ST_BATTLE] = {
		SomeBattleEvent = { tracks = {} },
	}
	
	SoundtrackAddon.db.profile.events[ST_ZONE] = {
		SomeZoneEvent = { tracks = {} },
	}
	
	SoundtrackAddon.db.profile.events[ST_DANCE] = {
		SomeDanceEvent = { tracks = {} },
	}
	
	SoundtrackAddon.db.profile.events[ST_MISC] = SoundtrackAddon.db.profile.events[ST_MISC] or {}
	
	Soundtrack.RegisteredEvents[ST_BATTLE] = {}
	Soundtrack.RegisteredEvents[ST_ZONE] = {}
	Soundtrack.RegisteredEvents[ST_DANCE] = {}
	
	-- Run cleanup
	Soundtrack.Cleanup.CleanupOldEvents()
	
	-- All events should be removed except Preview from all tables
	Exists(SoundtrackAddon.db.profile.events[ST_BATTLE].SomeBattleEvent == nil and "Battle event removed when no registered events" or nil)
	Exists(SoundtrackAddon.db.profile.events[ST_ZONE].SomeZoneEvent == nil and "Zone event removed when no registered events" or nil)
	Exists(SoundtrackAddon.db.profile.events[ST_DANCE].SomeDanceEvent == nil and "Dance event removed when no registered events" or nil)
end
