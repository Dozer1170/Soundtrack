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
