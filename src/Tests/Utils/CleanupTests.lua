if not Tests then
	return
end

local Tests = Tests("Soundtrack", "PLAYER_ENTERING_WORLD")

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

	-- Obsolete events should be removed from non-zone tables only
	IsTrue(SoundtrackAddon.db.profile.events[ST_BATTLE].ObsoleteEvent == nil, "Obsolete battle event removed")
	IsTrue(SoundtrackAddon.db.profile.events[ST_BATTLE].ValidEvent ~= nil, "Valid battle event kept")
	IsTrue(SoundtrackAddon.db.profile.events[ST_ZONE].ObsoleteZone ~= nil, "Zone events preserved during cleanup")
	IsTrue(SoundtrackAddon.db.profile.events[ST_ZONE].ValidZone ~= nil, "Valid zone event kept")
	IsTrue(updateCalled, "UI updated")
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
	IsTrue(SoundtrackAddon.db.profile.events[ST_BATTLE].Preview ~= nil, "Preview event preserved")
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
	IsTrue(SoundtrackAddon.db.profile.events[ST_MISC].ObsoleteMiscEvent == nil, "Obsolete misc event removed")
	IsTrue(SoundtrackAddon.db.profile.events[ST_MISC].ValidMiscEvent ~= nil, "Valid misc event kept")
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
	IsTrue(popupShown, "Purge popup shown")
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
	IsFalse(popupShown, "Purge popup not shown")
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
	IsTrue(popupShown, "Purge popup shown for any table with old tracks")
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
	IsTrue(#removedTracks > 0, "Tracks were removed")

	-- Verify the obsolete track was in the removal list
	local foundObsolete = false
	for _, removal in ipairs(removedTracks) do
		if removal.track == "ObsoleteTrack.mp3" then
			foundObsolete = true
		end
	end
	IsTrue(foundObsolete, "Obsolete track was removed")
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
	IsTrue(noPurgeShown, "No purge popup shown")
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
	IsFalse(popupShown, "No popup for empty tables")
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

	-- All events except zones should be removed when there are no registered events
	IsTrue(SoundtrackAddon.db.profile.events[ST_BATTLE].SomeBattleEvent == nil,
		"Battle event removed when no registered events")
	IsTrue(SoundtrackAddon.db.profile.events[ST_ZONE].SomeZoneEvent ~= nil,
		"Zone event preserved when no registered zone events")
	IsTrue(SoundtrackAddon.db.profile.events[ST_DANCE].SomeDanceEvent == nil,
		"Dance event removed when no registered events")
end

function Tests:CleanupOldEvents_DoesNotTouchZoneEvents()
	Soundtrack.RegisteredEvents[ST_ZONE] = {}
	SoundtrackAddon.db.profile.events = SoundtrackAddon.db.profile.events or {}
	SoundtrackAddon.db.profile.events[ST_ZONE] = {
		ZoneOne = { tracks = { "track" } },
		ZoneTwo = { tracks = {} },
	}

	Soundtrack.Cleanup.CleanupOldEvents()

	IsTrue(SoundtrackAddon.db.profile.events[ST_ZONE].ZoneOne ~= nil, "Existing zone kept")
	IsTrue(SoundtrackAddon.db.profile.events[ST_ZONE].ZoneTwo ~= nil, "Additional zones kept")
end
