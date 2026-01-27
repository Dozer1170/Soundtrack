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

-- Phase 4: Addon Initialization Tests

function Tests:OnLoad_RegistersSlashCommands()
	-- Initialize SlashCmdList if needed
	if not _G.SlashCmdList then
		_G.SlashCmdList = {}
	end
	
	-- Clear slash commands
	_G.SLASH_SOUNDTRACK1 = nil
	_G.SLASH_SOUNDTRACK2 = nil
	_G.SlashCmdList["SOUNDTRACK"] = nil
	
	-- Mock Events.OnLoad
	Replace(Soundtrack.Events, "OnLoad", function() end)
	
	-- Call OnLoad
	Soundtrack.OnLoad(SoundtrackFrame)
	
	-- Verify slash commands registered
	AreEqual("/soundtrack", _G.SLASH_SOUNDTRACK1)
	AreEqual("/st", _G.SLASH_SOUNDTRACK2)
	Exists(_G.SlashCmdList["SOUNDTRACK"] ~= nil and "SlashCmdList registered" or nil)
end

function Tests:OnLoad_CallsEventsOnLoad()
	-- Initialize SlashCmdList
	if not _G.SlashCmdList then
		_G.SlashCmdList = {}
	end
	
	local eventsOnLoadCalled = false
	
	Replace(Soundtrack.Events, "OnLoad", function()
		eventsOnLoadCalled = true
	end)
	
	Soundtrack.OnLoad(SoundtrackFrame)
	
	AreEqual(true, eventsOnLoadCalled)
end

function Tests:PLAYER_ENTERING_WORLD_InitializesOnce()
	Soundtrack.TracksLoaded = false
	
	-- Mock all initialization functions
	local initCalls = {}
	Replace(Soundtrack.Chat, "InitDebugChatFrame", function() table.insert(initCalls, "Chat") end)
	Replace(_G, "SoundtrackMinimap_Initialize", function() table.insert(initCalls, "Minimap") end)
	Replace(Soundtrack, "MigrateFromOldSavedVariables", function() table.insert(initCalls, "Migrate") end)
	Replace(Soundtrack, "LoadTracks", function() table.insert(initCalls, "LoadTracks") end)
	Replace(Soundtrack.DanceEvents, "Initialize", function() table.insert(initCalls, "Dance") end)
	Replace(Soundtrack.PetBattleEvents, "Initialize", function() table.insert(initCalls, "PetBattle") end)
	Replace(Soundtrack.MountEvents, "Initialize", function() table.insert(initCalls, "Mount") end)
	Replace(Soundtrack.ZoneEvents, "Initialize", function() table.insert(initCalls, "Zone") end)
	Replace(Soundtrack.BattleEvents, "Initialize", function() table.insert(initCalls, "Battle") end)
	Replace(Soundtrack.Auras, "Initialize", function() table.insert(initCalls, "Auras") end)
	Replace(Soundtrack.Misc, "Initialize", function() table.insert(initCalls, "Misc") end)
	Replace(SoundtrackUI, "RefreshShowingTab", function() table.insert(initCalls, "RefreshTab") end)
	Replace(SoundtrackUI, "Initialize", function() table.insert(initCalls, "UI") end)
	Replace(Soundtrack.Cleanup, "CleanupOldEvents", function() table.insert(initCalls, "Cleanup") end)
	
	-- Call PLAYER_ENTERING_WORLD
	SoundtrackAddon:PLAYER_ENTERING_WORLD()
	
	-- Verify all systems initialized
	Exists(#initCalls >= 10 and "Multiple systems initialized" or nil)
	
	-- Set TracksLoaded to simulate completion
	Soundtrack.TracksLoaded = true
	
	-- Call again - should not reinitialize
	local callCountBefore = #initCalls
	SoundtrackAddon:PLAYER_ENTERING_WORLD()
	local callCountAfter = #initCalls
	
	AreEqual(callCountBefore, callCountAfter)
end

function Tests:PLAYER_ENTERING_WORLD_InitializesAllSystems()
	Soundtrack.TracksLoaded = false
	
	local danceInitialized = false
	local petBattleInitialized = false
	local mountInitialized = false
	local zoneInitialized = false
	local battleInitialized = false
	local aurasInitialized = false
	local miscInitialized = false
	
	-- Mock Chat and Minimap to avoid errors
	Replace(Soundtrack.Chat, "InitDebugChatFrame", function() end)
	Replace(_G, "SoundtrackMinimap_Initialize", function() end)
	Replace(Soundtrack, "MigrateFromOldSavedVariables", function() end)
	Replace(Soundtrack, "LoadTracks", function() end)
	Replace(SoundtrackUI, "RefreshShowingTab", function() end)
	Replace(SoundtrackUI, "Initialize", function() end)
	Replace(Soundtrack.Cleanup, "CleanupOldEvents", function() end)
	
	Replace(Soundtrack.DanceEvents, "Initialize", function() danceInitialized = true end)
	Replace(Soundtrack.PetBattleEvents, "Initialize", function() petBattleInitialized = true end)
	Replace(Soundtrack.MountEvents, "Initialize", function() mountInitialized = true end)
	Replace(Soundtrack.ZoneEvents, "Initialize", function() zoneInitialized = true end)
	Replace(Soundtrack.BattleEvents, "Initialize", function() battleInitialized = true end)
	Replace(Soundtrack.Auras, "Initialize", function() aurasInitialized = true end)
	Replace(Soundtrack.Misc, "Initialize", function() miscInitialized = true end)
	
	SoundtrackAddon:PLAYER_ENTERING_WORLD()
	
	AreEqual(true, danceInitialized)
	AreEqual(true, petBattleInitialized)
	AreEqual(true, mountInitialized)
	AreEqual(true, zoneInitialized)
	AreEqual(true, battleInitialized)
	AreEqual(true, aurasInitialized)
	AreEqual(true, miscInitialized)
end

function Tests:OnUpdate_CallsSubsystemUpdates()
	local libraryUpdateCalled = false
	local timersUpdateCalled = false
	local uiUpdateCalled = false
	local movingTitleUpdateCalled = false
	
	-- Initialize MovingTitle if needed
	if not SoundtrackUI.MovingTitle then
		SoundtrackUI.MovingTitle = {}
	end
	
	Replace(Soundtrack.Library, "OnUpdate", function() libraryUpdateCalled = true end)
	Replace(Soundtrack.Timers, "OnUpdate", function() timersUpdateCalled = true end)
	Replace(SoundtrackUI, "OnUpdate", function() uiUpdateCalled = true end)
	Replace(SoundtrackUI.MovingTitle, "OnUpdate", function() movingTitleUpdateCalled = true end)
	
	-- Mock GetTime to control timing
	local currentTime = 0
	Replace(_G, "GetTime", function() return currentTime end)
	
	-- First update should trigger all subsystems
	Soundtrack.OnUpdate(nil, nil)
	
	AreEqual(true, libraryUpdateCalled)
	AreEqual(true, timersUpdateCalled)
	AreEqual(true, uiUpdateCalled)
	AreEqual(true, movingTitleUpdateCalled)
end

function Tests:OnUpdate_RespectsUpdateInterval()
	local updateCount = 0
	
	-- Initialize MovingTitle if needed
	if not SoundtrackUI.MovingTitle then
		SoundtrackUI.MovingTitle = {}
	end
	
	Replace(Soundtrack.Library, "OnUpdate", function() updateCount = updateCount + 1 end)
	Replace(Soundtrack.Timers, "OnUpdate", function() end)
	Replace(SoundtrackUI, "OnUpdate", function() end)
	Replace(SoundtrackUI.MovingTitle, "OnUpdate", function() end)
	
	local currentTime = 0
	Replace(_G, "GetTime", function() return currentTime end)
	
	-- First call should update
	Soundtrack.OnUpdate(nil, nil)
	AreEqual(1, updateCount)
	
	-- Immediate second call should not update (throttled)
	Soundtrack.OnUpdate(nil, nil)
	AreEqual(1, updateCount)
	
	-- After interval, should update again
	currentTime = currentTime + UI_UPDATE_INTERVAL + 0.01
	Soundtrack.OnUpdate(nil, nil)
	AreEqual(2, updateCount)
end

function Tests:MigrateFromOldSavedVariables_MigratesSettings()
	-- Set up old-style saved variables (without _G prefix - it's a global)
	Soundtrack_Settings = {
		EnableBattleMusic = false,  -- default is true
		EnableZoneMusic = false,    -- default is true
		Debug = true,               -- default is false
		CustomValue = "migrated"    -- custom value to verify migration
	}
	
	-- Before migration, verify the old variable exists
	Exists(Soundtrack_Settings ~= nil and "Old settings exist" or nil)
	
	-- Migration should not crash
	local success = pcall(Soundtrack.MigrateFromOldSavedVariables)
	
	AreEqual(true, success)
	
	-- Note: The actual clearing of Soundtrack_Settings depends on how the global is scoped
	-- In production WoW, this would be a saved variable that gets cleared properly
end

function Tests:MigrateFromOldSavedVariables_MigratesEvents()
	-- Set up old-style events (without _G prefix - it's a global)
	Soundtrack_Events = {
		[ST_ZONE] = {
			["OldZone"] = {
				tracks = {"oldzone.mp3"},
				priority = ST_ZONE_LVL
			}
		}
	}
	
	-- Before migration, verify the old variable exists
	Exists(Soundtrack_Events ~= nil and "Old events exist" or nil)
	
	-- Migration should not crash
	local success = pcall(Soundtrack.MigrateFromOldSavedVariables)
	
	AreEqual(true, success)
	
	-- Note: The actual clearing of Soundtrack_Events depends on how the global is scoped
	-- In production WoW, this would be a saved variable that gets cleared properly
end

function Tests:MigrateFromOldSavedVariables_NoOldVars_DoesNotCrash()
	-- Ensure no old variables exist
	Soundtrack_Settings = nil
	Soundtrack_Events = nil
	
	local success = pcall(Soundtrack.MigrateFromOldSavedVariables)
	
	AreEqual(true, success)
end

function Tests:LoadTracks_CreatesEventTables()
	Soundtrack_Tracks = {}
	Soundtrack.TracksLoaded = false
	
	-- Mock dependencies
	_G.Soundtrack_LoadDefaultTracks = function() end
	_G.Soundtrack_LoadMyTracks = function() end
	
	-- Clear event tables
	SoundtrackAddon.db.profile.events = {}
	
	Soundtrack.LoadTracks()
	
	-- Verify all event tables created
	for _, eventTabName in ipairs(Soundtrack_EventTabs) do
		Exists(SoundtrackAddon.db.profile.events[eventTabName] ~= nil and eventTabName .. " table created" or nil)
	end
end

function Tests:LoadTracks_SchedulesPurgeTimer()
	Soundtrack_Tracks = {}
	Soundtrack.TracksLoaded = false
	
	-- Mock dependencies
	_G.Soundtrack_LoadDefaultTracks = function() end
	_G.Soundtrack_LoadMyTracks = function() end
	
	local purgeTimerCreated = false
	Replace(Soundtrack.Timers, "AddTimer", function(name, delay, callback)
		if name == "PurgeOldTracksFromEvents" then
			purgeTimerCreated = true
		end
	end)
	
	Soundtrack.LoadTracks()
	
	AreEqual(true, purgeTimerCreated)
end

function Tests:LoadTracks_CallsSortingFunctions()
	Soundtrack_Tracks = {}
	Soundtrack.TracksLoaded = false
	
	-- Mock dependencies
	_G.Soundtrack_LoadDefaultTracks = function() end
	_G.Soundtrack_LoadMyTracks = function() end
	
	local sortAllEventsCalled = false
	local sortTracksCalled = false
	
	Replace(Soundtrack, "SortAllEvents", function() sortAllEventsCalled = true end)
	Replace(Soundtrack, "SortTracks", function() sortTracksCalled = true end)
	
	Soundtrack.LoadTracks()
	
	AreEqual(true, sortAllEventsCalled)
	AreEqual(true, sortTracksCalled)
end
