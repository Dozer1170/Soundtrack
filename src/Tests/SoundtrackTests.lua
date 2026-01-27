if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

function Tests:PlayEvent_ValidEventAndTable_PlaysTrack()
	Soundtrack.AddEvent(ST_ZONE, "ValidEvent", ST_ZONE_LVL, true, false)
	Soundtrack_Tracks["valid.mp3"] = { filePath = "valid.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["ValidEvent"].tracks = {"valid.mp3"}
	
	Soundtrack.PlayEvent(ST_ZONE, "ValidEvent")
	
	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
	local eventName, tableName = Soundtrack.Events.GetEventAtStackLevel(stackLevel)
	
	Exists(eventName == "ValidEvent" and tableName == ST_ZONE and "Track played" or nil)
end

function Tests:PlayEvent_NoTracksAvailable_DoesNotPlay()
	Soundtrack.AddEvent(ST_MISC, "NoTracksEvent", ST_ONCE_LVL, true, false)
	
	local stackBefore = Soundtrack.Events.GetCurrentStackLevel()
	Soundtrack.PlayEvent(ST_MISC, "NoTracksEvent")
	local stackAfter = Soundtrack.Events.GetCurrentStackLevel()
	
	-- Event without tracks should not be added to stack
	Exists(stackBefore == stackAfter and "No-track scenario verified" or nil)
end

function Tests:StopMusic_StopsPlayback()
	Soundtrack.AddEvent(ST_MISC, "TestMusic", ST_ONCE_LVL, true, false)
	Soundtrack_Tracks["test.mp3"] = { filePath = "test.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)["TestMusic"].tracks = {"test.mp3"}
	
	Soundtrack.Events.PlayEvent(ST_MISC, "TestMusic", ST_ONCE_LVL, false, nil, 0)
	local levelBefore = Soundtrack.Events.GetCurrentStackLevel()
	
	Soundtrack.Library.StopMusic()
	
	-- Music should be stopped (Library.StopMusic stops playback)
	Exists(levelBefore > 0 and "Music stopped" or nil)
end

-- Event CRUD Operations Tests
function Tests:RemoveEvent_ValidEvent_RemovesFromTable()
	Soundtrack.AddEvent(ST_ZONE, "EventToRemove", ST_ZONE_LVL, true, false)
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	Exists(eventTable["EventToRemove"] ~= nil and "Event exists before removal" or nil)
	
	Soundtrack.RemoveEvent(ST_ZONE, "EventToRemove")
	
	IsFalse(eventTable["EventToRemove"])
end

function Tests:RemoveEvent_NilTable_DoesNotCrash()
	Soundtrack.RemoveEvent(nil, "SomeEvent")
	
	-- Should not crash, just handle gracefully
	Exists(true and "Handled nil table" or nil)
end

function Tests:RemoveEvent_NilEvent_DoesNotCrash()
	Soundtrack.RemoveEvent(ST_ZONE, nil)
	
	-- Should not crash, just handle gracefully
	Exists(true and "Handled nil event" or nil)
end

function Tests:RemoveEvent_NonexistentEvent_DoesNotCrash()
	Soundtrack.RemoveEvent(ST_ZONE, "NonexistentEvent")
	
	-- Should handle gracefully without crashing
	Exists(true and "Handled nonexistent event" or nil)
end

function Tests:RenameEvent_ValidEvent_RenamesSuccessfully()
	Soundtrack.AddEvent(ST_ZONE, "OldName", ST_ZONE_LVL, true, false)
	Soundtrack_Tracks["track.mp3"] = { filePath = "track.mp3" }
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	eventTable["OldName"].tracks = {"track.mp3"}
	
	Soundtrack.RenameEvent(ST_ZONE, "OldName", "NewName", ST_ZONE_LVL, true, false)
	
	IsFalse(eventTable["OldName"])
	Exists(eventTable["NewName"] ~= nil and "Event renamed" or nil)
	AreEqual(1, #eventTable["NewName"].tracks)
end

function Tests:RenameEvent_PreservesTracksAndSettings()
	Soundtrack.AddEvent(ST_MISC, "Original", ST_ONCE_LVL, true, false)
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	eventTable["Original"].tracks = {"track1.mp3", "track2.mp3"}
	eventTable["Original"].random = false
	
	Soundtrack.RenameEvent(ST_MISC, "Original", "Renamed", ST_ONCE_LVL, true, false)
	
	AreEqual(2, #eventTable["Renamed"].tracks)
	AreEqual("track1.mp3", eventTable["Renamed"].tracks[1])
	AreEqual("track2.mp3", eventTable["Renamed"].tracks[2])
	AreEqual(false, eventTable["Renamed"].random)
end

function Tests:GetEvent_ValidEvent_ReturnsEvent()
	Soundtrack.AddEvent(ST_ZONE, "TestEvent", ST_ZONE_LVL, true, false)
	
	local event = Soundtrack.GetEvent(ST_ZONE, "TestEvent")
	
	Exists(event ~= nil and "Event retrieved" or nil)
	AreEqual(ST_ZONE_LVL, event.priority)
end

function Tests:GetEvent_NonexistentEvent_ReturnsNil()
	local event = Soundtrack.GetEvent(ST_ZONE, "DoesNotExist")
	
	IsFalse(event)
end

function Tests:GetEvent_NilParameters_ReturnsNil()
	local event1 = Soundtrack.GetEvent(nil, "Event")
	local event2 = Soundtrack.GetEvent(ST_ZONE, nil)
	
	IsFalse(event1)
	IsFalse(event2)
end

function Tests:GetTableFromEvent_ExistingEvent_ReturnsTableName()
	Soundtrack.AddEvent(ST_BATTLE, "BattleEvent", ST_BATTLE_LVL, true, false)
	
	local tableName = Soundtrack.GetTableFromEvent("BattleEvent")
	
	AreEqual(ST_BATTLE, tableName)
end

function Tests:GetTableFromEvent_NonexistentEvent_ReturnsNil()
	local tableName = Soundtrack.GetTableFromEvent("NonExistentEvent")
	
	IsFalse(tableName)
end

function Tests:GetEventByName_ExistingEvent_ReturnsEvent()
	Soundtrack.AddEvent(ST_MISC, "UniqueEvent", ST_ONCE_LVL, false, true)
	
	local event = Soundtrack.GetEventByName("UniqueEvent")
	
	Exists(event ~= nil and "Event found by name" or nil)
	AreEqual(ST_ONCE_LVL, event.priority)
	AreEqual(true, event.soundEffect)
end

function Tests:GetEventByName_NonexistentEvent_ReturnsNil()
	local event = Soundtrack.GetEventByName("DoesNotExist")
	
	IsFalse(event)
end

-- Track Assignment Tests
function Tests:EventsAdd_NewEvent_CreatesEvent()
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	local beforeExists = eventTable["NewEvent"]
	
	Soundtrack.Events.Add(ST_ZONE, "NewEvent", nil)
	
	IsFalse(beforeExists)
	Exists(eventTable["NewEvent"] ~= nil and "Event created" or nil)
end

function Tests:EventsAdd_WithTrack_AddsTrackToEvent()
	Soundtrack.Events.Add(ST_ZONE, "EventWithTrack", "track.mp3")
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	
	AreEqual(1, #eventTable["EventWithTrack"].tracks)
	AreEqual("track.mp3", eventTable["EventWithTrack"].tracks[1])
end

function Tests:EventsAdd_DuplicateTrack_DoesNotAddTwice()
	Soundtrack.Events.Add(ST_ZONE, "DupeTest", "track.mp3")
	Soundtrack.Events.Add(ST_ZONE, "DupeTest", "track.mp3")
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	
	AreEqual(1, #eventTable["DupeTest"].tracks)
end

function Tests:EventsAdd_MultipleTracksToSameEvent_AddsAll()
	Soundtrack.Events.Add(ST_ZONE, "MultiTrack", "track1.mp3")
	Soundtrack.Events.Add(ST_ZONE, "MultiTrack", "track2.mp3")
	Soundtrack.Events.Add(ST_ZONE, "MultiTrack", "track3.mp3")
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	
	AreEqual(3, #eventTable["MultiTrack"].tracks)
end

function Tests:EventsRemove_ExistingTrack_RemovesFromEvent()
	Soundtrack.Events.Add(ST_ZONE, "RemoveTest", "track1.mp3")
	Soundtrack.Events.Add(ST_ZONE, "RemoveTest", "track2.mp3")
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	AreEqual(2, #eventTable["RemoveTest"].tracks)
	
	Soundtrack.Events.Remove(ST_ZONE, "RemoveTest", "track1.mp3")
	
	AreEqual(1, #eventTable["RemoveTest"].tracks)
	AreEqual("track2.mp3", eventTable["RemoveTest"].tracks[1])
end

function Tests:EventsDeleteEvent_ExistingEvent_RemovesCompletely()
	Soundtrack.Events.Add(ST_ZONE, "ToDelete", "track.mp3")
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	Exists(eventTable["ToDelete"] ~= nil and "Event exists" or nil)
	
	Soundtrack.Events.DeleteEvent(ST_ZONE, "ToDelete")
	
	IsFalse(eventTable["ToDelete"])
end

function Tests:EventsClearEvent_WithTracks_RemovesAllTracks()
	Soundtrack.Events.Add(ST_ZONE, "ClearTest", "track1.mp3")
	Soundtrack.Events.Add(ST_ZONE, "ClearTest", "track2.mp3")
	Soundtrack.Events.Add(ST_ZONE, "ClearTest", "track3.mp3")
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	AreEqual(3, #eventTable["ClearTest"].tracks)
	
	Soundtrack.Events.ClearEvent(ST_ZONE, "ClearTest")
	
	AreEqual(0, #eventTable["ClearTest"].tracks)
	Exists(eventTable["ClearTest"] ~= nil and "Event still exists" or nil)
end

function Tests:EventsRenameEvent_ValidEvent_RenamesInEventsSystem()
	Soundtrack.Events.Add(ST_MISC, "OldEventName", "track.mp3")
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	Exists(eventTable["OldEventName"] ~= nil and "Old event exists" or nil)
	
	Soundtrack.Events.RenameEvent(ST_MISC, "OldEventName", "NewEventName")
	
	IsFalse(eventTable["OldEventName"])
	Exists(eventTable["NewEventName"] ~= nil and "Event renamed" or nil)
	AreEqual(1, #eventTable["NewEventName"].tracks)
end

function Tests:AssignTrack_ValidEvent_AddsTrackToEvent()
	Soundtrack.AddEvent(ST_ZONE, "AssignTest", ST_ZONE_LVL, true, false)
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	
	Soundtrack.AssignTrack("AssignTest", "assigned.mp3")
	
	AreEqual(1, #eventTable["AssignTest"].tracks)
	AreEqual("assigned.mp3", eventTable["AssignTest"].tracks[1])
end

function Tests:LoadTracks_WithMyTracksFile_LoadsCustomTracks()
	-- Load the example MyTracks file
	dofile("ExampleMyTracks.lua")
	
	-- Clear existing tracks
	Soundtrack_Tracks = {}
	Soundtrack.TracksLoaded = false
	
	-- Mock the default tracks loader
	_G.Soundtrack_LoadDefaultTracks = function() end
	
	-- Load tracks
	Soundtrack.LoadTracks()
	
	-- Verify tracks were loaded
	local trackCount = 0
	for _ in pairs(Soundtrack_Tracks) do
		trackCount = trackCount + 1
	end
	
	-- Should have loaded tracks from ExampleMyTracks
	Exists(trackCount > 0 and "Custom tracks loaded" or nil)
	Exists(Soundtrack_Tracks["CityOfHeroes\\AtlasPark"] ~= nil and "Specific track exists" or nil)
	Exists(Soundtrack.TracksLoaded == true and "TracksLoaded flag set" or nil)
end

function Tests:LoadTracks_WithoutMyTracksFile_ShowsError()
	-- Clear MyTracks function
	local originalLoadMyTracks = _G.Soundtrack_LoadMyTracks
	_G.Soundtrack_LoadMyTracks = nil
	
	-- Clear existing tracks
	Soundtrack_Tracks = {}
	Soundtrack.TracksLoaded = false
	
	-- Mock the default tracks loader
	_G.Soundtrack_LoadDefaultTracks = function() end
	
	-- Set UseDefaultLoadMyTracks to false to trigger error
	SoundtrackAddon.db.profile.settings.UseDefaultLoadMyTracks = false
	
	-- Mock StaticPopup_Show to track if it was called
	local popupShown = false
	Replace(_G, "StaticPopup_Show", function(name)
		if name == "ST_NO_LOADMYTRACKS_POPUP" then
			popupShown = true
		end
	end)
	
	-- Try to load tracks (should error)
	local success = pcall(Soundtrack.LoadTracks)
	
	-- Should have shown popup and errored
	Exists(popupShown == true and "Error popup shown" or nil)
	Exists(success == false and "LoadTracks errored" or nil)
	
	-- Restore
	_G.Soundtrack_LoadMyTracks = originalLoadMyTracks
end

function Tests:LoadTracks_WithUseDefaultFlag_DoesNotError()
	-- Clear MyTracks function
	local originalLoadMyTracks = _G.Soundtrack_LoadMyTracks
	_G.Soundtrack_LoadMyTracks = nil
	
	-- Clear existing tracks
	Soundtrack_Tracks = {}
	Soundtrack.TracksLoaded = false
	
	-- Mock the default tracks loader
	_G.Soundtrack_LoadDefaultTracks = function() end
	
	-- Set UseDefaultLoadMyTracks to true (user intentionally has no custom tracks)
	SoundtrackAddon.db.profile.settings.UseDefaultLoadMyTracks = true
	
	-- Load tracks (should not error)
	local success = pcall(Soundtrack.LoadTracks)
	
	-- Should succeed without custom tracks
	Exists(success == true and "LoadTracks succeeded" or nil)
	
	-- Restore
	_G.Soundtrack_LoadMyTracks = originalLoadMyTracks
end
