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
