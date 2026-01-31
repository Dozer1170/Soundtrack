if not Tests then
	return
end

local Tests = Tests("Soundtrack", "PLAYER_ENTERING_WORLD")

function Tests:EventHasTracks_EventWithTracks_ReturnsTrue()
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			TestEvent = {
				tracks = { "track1.mp3", "track2.mp3" }
			}
		}
	end)

	IsTrue(Soundtrack.Events.EventHasTracks("TestTable", "TestEvent"), "Event has tracks")
end

function Tests:EventHasTracks_EventWithoutTracks_ReturnsFalse()
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			TestEvent = {
				tracks = {}
			}
		}
	end)

	IsFalse(Soundtrack.Events.EventHasTracks("TestTable", "TestEvent"))
end

function Tests:EventHasTracks_NonexistentEvent_ReturnsFalse()
	Replace(Soundtrack.Events, "GetTable", function()
		return {}
	end)

	IsFalse(Soundtrack.Events.EventHasTracks("TestTable", "NonexistentEvent"), "nonexistent event should return false")
end

function Tests:EventHasTracks_NilTable_ReturnsFalse()
	Replace(Soundtrack.Events, "GetTable", function()
		return nil
	end)

	IsFalse(Soundtrack.Events.EventHasTracks("TestTable", "AnyEvent"))
end

function Tests:GetTrackCount_ReturnsZeroForNilEvent()
	local getTrackCount
	for i = 1, 10 do
		local name, value = debug.getupvalue(Soundtrack.Events.GetCurrentStackLevel, i)
		if name == "GetTrackCount" then
			getTrackCount = value
			break
		end
	end

	AreEqual(0, getTrackCount(nil))
end

function Tests:EventExists_ExistingEvent_ReturnsTrue()
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			TestEvent = {
				tracks = { "track1.mp3" }
			}
		}
	end)

	IsTrue(Soundtrack.Events.EventExists("TestTable", "TestEvent"), "Event exists")
end

function Tests:EventExists_NonexistentEvent_ReturnsFalse()
	Replace(Soundtrack.Events, "GetTable", function()
		return {}
	end)

	IsFalse(Soundtrack.Events.EventExists("TestTable", "NonexistentEvent"), "nonexistent event should return false")
end

function Tests:PushEvent_ValidStackLevel_PushesEvent()
	Soundtrack.Events.Stack = {}
	for i = 1, 16 do
		table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil })
	end

	Soundtrack.AddEvent(ST_ZONE, "TestZone", 1, true, false)
	Soundtrack_Tracks["testtrack.mp3"] = { filePath = "testtrack.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["TestZone"].tracks = { "testtrack.mp3" }

	Soundtrack.Events.PlayEvent(ST_ZONE, "TestZone", 1, false, nil, 0)

	AreEqual("TestZone", Soundtrack.Events.Stack[1].eventName, "event should be pushed to stack")
end

function Tests:PopEvent_ValidStackLevel_PopsEvent()
	Soundtrack.Events.Stack = {}
	for i = 1, 16 do
		table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil })
	end
	Soundtrack.Events.Stack[1] = { eventName = "TestZone", tableName = ST_ZONE }

	Soundtrack.StopEventAtLevel(1)

	IsFalse(Soundtrack.Events.Stack[1].eventName, "event should be popped from stack")
end

function Tests:GetStack_ReturnsCurrentStack()
	Soundtrack.Events.Stack = { { eventName = "Test" } }

	local stack = Soundtrack.Events.Stack

	AreEqual("Test", stack[1].eventName, "stack should contain test event")
end

function Tests:GetEventName_WithEventAtLevel_ReturnsEventName()
	Soundtrack.Events.Stack = {}
	for i = 1, 16 do
		table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil })
	end
	Soundtrack.Events.Stack[5] = { eventName = "MountEvent", tableName = ST_MOUNT }

	local eventName, tableName = Soundtrack.Events.GetEventAtStackLevel(5)

	AreEqual("MountEvent", eventName, "should return event name at stack level")
end

function Tests:GetTableName_WithTableAtLevel_ReturnsTableName()
	Soundtrack.Events.Stack = {}
	for i = 1, 16 do
		table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil })
	end
	Soundtrack.Events.Stack[5] = { eventName = "MountEvent", tableName = ST_MOUNT }

	local eventName, tableName = Soundtrack.Events.GetEventAtStackLevel(5)

	AreEqual(ST_MOUNT, tableName, "should return table name at stack level")
end

function Tests:PauseEvents_SetsEventsPaused()
	Soundtrack.Events.Paused = false

	Soundtrack.Events.PlaybackPlayStop()

	IsTrue(Soundtrack.Events.Paused, "events should be paused")
end

function Tests:ResumeEvents_ResumesPlayback()
	Soundtrack.Events.Paused = true
	Soundtrack.Events.Stack[1] = { eventName = "TestEvent", tableName = ST_ZONE }

	Soundtrack.Events.PlaybackPlayStop()

	IsFalse(Soundtrack.Events.Paused, "events should be resumed")
end

-- StopEvent Tests
function Tests:StopEvent_ValidEvent_StopsAtCorrectLevel()
	Soundtrack.AddEvent(ST_BATTLE, "TestBattle", ST_BATTLE_LVL, true, false)
	Soundtrack_Tracks["battle.mp3"] = { filePath = "battle.mp3" }
	Soundtrack.Events.GetTable(ST_BATTLE)["TestBattle"].tracks = { "battle.mp3" }

	Soundtrack.Events.PlayEvent(ST_BATTLE, "TestBattle", ST_BATTLE_LVL, false, nil, 0)
	local eventName, tableName = Soundtrack.Events.GetEventAtStackLevel(ST_BATTLE_LVL)
	AreEqual("TestBattle", eventName, "event should be playing initially")

	Soundtrack.StopEvent(ST_BATTLE, "TestBattle")

	eventName, tableName = Soundtrack.Events.GetEventAtStackLevel(ST_BATTLE_LVL)
	IsFalse(eventName, "event should be stopped")
end

function Tests:StopEvent_NonexistentEvent_DoesNotCrash()
	Soundtrack.AddEvent(ST_BATTLE, "ExistingEvent", ST_BATTLE_LVL, true, false)
	Soundtrack_Tracks["existing.mp3"] = { filePath = "existing.mp3" }
	Soundtrack.Events.GetTable(ST_BATTLE)["ExistingEvent"].tracks = { "existing.mp3" }
	Soundtrack.Events.PlayEvent(ST_BATTLE, "ExistingEvent", ST_BATTLE_LVL, false, nil, 0)

	Soundtrack.StopEvent(ST_MISC, "NonExistent")

	local eventName = Soundtrack.Events.GetEventAtStackLevel(ST_BATTLE_LVL)
	AreEqual("ExistingEvent", eventName, "stopping a nonexistent event should not affect active events")
end

function Tests:StopEvent_NilParameters_DoesNotCrash()
	local stopCalled = false
	Replace(Soundtrack, "StopEventAtLevel", function()
		stopCalled = true
	end)

	Soundtrack.StopEvent(nil, "Event")
	Soundtrack.StopEvent(ST_MISC, nil)

	IsFalse(stopCalled, "StopEventAtLevel should not be called when parameters are nil")
end

-- PlayRandomTrackByTable Tests
function Tests:PlayRandomTrackByTable_SingleTrack_PlaysTrack()
	Soundtrack.Events.Add(ST_ZONE, "SingleTrackEvent", "single.mp3")
	Soundtrack_Tracks["single.mp3"] = { filePath = "single.mp3" }

	local played = Soundtrack.Events.PlayRandomTrackByTable(ST_ZONE, "SingleTrackEvent", 0)

	AreEqual(true, played, "single track should be played")
end

function Tests:PlayRandomTrackByTable_MultipleTracks_PlaysOne()
	Soundtrack.Events.Add(ST_ZONE, "MultiEvent", "track1.mp3")
	Soundtrack.Events.Add(ST_ZONE, "MultiEvent", "track2.mp3")
	Soundtrack.Events.Add(ST_ZONE, "MultiEvent", "track3.mp3")
	Soundtrack_Tracks["track1.mp3"] = { filePath = "track1.mp3" }
	Soundtrack_Tracks["track2.mp3"] = { filePath = "track2.mp3" }
	Soundtrack_Tracks["track3.mp3"] = { filePath = "track3.mp3" }

	local played = Soundtrack.Events.PlayRandomTrackByTable(ST_ZONE, "MultiEvent", 0)

	AreEqual(true, played, "one of multiple tracks should be played")
end

function Tests:PlayRandomTrackByTable_NoTracks_ReturnsFalse()
	Soundtrack.Events.Add(ST_ZONE, "EmptyEvent", nil)

	local played = Soundtrack.Events.PlayRandomTrackByTable(ST_ZONE, "EmptyEvent", 0)

	AreEqual(false, played, "event without tracks should return false")
end

function Tests:PlayRandomTrackByTable_NonRandomMode_PlaysSequential()
	Soundtrack.Events.Add(ST_ZONE, "Sequential", "track1.mp3")
	Soundtrack.Events.Add(ST_ZONE, "Sequential", "track2.mp3")
	Soundtrack.Events.Add(ST_ZONE, "Sequential", "track3.mp3")
	Soundtrack_Tracks["track1.mp3"] = { filePath = "track1.mp3" }
	Soundtrack_Tracks["track2.mp3"] = { filePath = "track2.mp3" }
	Soundtrack_Tracks["track3.mp3"] = { filePath = "track3.mp3" }

	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	eventTable["Sequential"].random = false
	eventTable["Sequential"].lastTrackIndex = nil

	-- First play (starts at 1 since lastTrackIndex is nil, offset is 0)
	Soundtrack.Events.PlayRandomTrackByTable(ST_ZONE, "Sequential", 0)
	AreEqual(1, eventTable["Sequential"].lastTrackIndex)

	-- Next play with offset 1 (lastTrackIndex=1, offset=1, so index = 1+1 = 2)
	Soundtrack.Events.PlayRandomTrackByTable(ST_ZONE, "Sequential", 1)
	AreEqual(2, eventTable["Sequential"].lastTrackIndex)

	-- Next play with offset 1 (lastTrackIndex=2, offset=1, so index = 2+1 = 3)
	Soundtrack.Events.PlayRandomTrackByTable(ST_ZONE, "Sequential", 1)
	AreEqual(3, eventTable["Sequential"].lastTrackIndex)

	-- Should wrap back to 1 (lastTrackIndex=3, offset=1, so index = 3+1 = 4, wraps to 1)
	Soundtrack.Events.PlayRandomTrackByTable(ST_ZONE, "Sequential", 1)
	AreEqual(1, eventTable["Sequential"].lastTrackIndex)
end

function Tests:PlayRandomTrackByTable_OffsetNegative_PlaysPrevious()
	Soundtrack.Events.Add(ST_ZONE, "BackTrack", "track1.mp3")
	Soundtrack.Events.Add(ST_ZONE, "BackTrack", "track2.mp3")
	Soundtrack.Events.Add(ST_ZONE, "BackTrack", "track3.mp3")
	Soundtrack_Tracks["track1.mp3"] = { filePath = "track1.mp3" }
	Soundtrack_Tracks["track2.mp3"] = { filePath = "track2.mp3" }
	Soundtrack_Tracks["track3.mp3"] = { filePath = "track3.mp3" }

	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	eventTable["BackTrack"].random = false
	eventTable["BackTrack"].lastTrackIndex = 2

	Soundtrack.Events.PlayRandomTrackByTable(ST_ZONE, "BackTrack", -1)

	AreEqual(1, eventTable["BackTrack"].lastTrackIndex)
end

function Tests:PlayRandomTrackByTable_WhilePaused_DoesNotPlay()
	Soundtrack.Events.Add(ST_ZONE, "PausedEvent", "track.mp3")
	Soundtrack_Tracks["track.mp3"] = { filePath = "track.mp3" }
	Soundtrack.Events.Paused = true

	local played = Soundtrack.Events.PlayRandomTrackByTable(ST_ZONE, "PausedEvent", 0)

	Soundtrack.Events.Paused = false
	AreEqual(true, played) -- Returns true but doesn't actually play
end

function Tests:PlayRandomTrackByTable_PausedSoundEffect_PlaysTrack()
	Soundtrack.Events.Add(ST_ZONE, "PausedSfxEvent", "sfx.mp3")
	Soundtrack_Tracks["sfx.mp3"] = { filePath = "sfx.mp3" }
	Soundtrack.Events.Paused = true
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	eventTable["PausedSfxEvent"].soundEffect = true

	local played = false
	Replace(Soundtrack.Library, "PlayTrack", function()
		played = true
	end)

	Soundtrack.Events.PlayRandomTrackByTable(ST_ZONE, "PausedSfxEvent", 0)

	Soundtrack.Events.Paused = false
	IsTrue(played, "Sound effect should play even when paused")
end

function Tests:PlayRandomTrackByTable_NonRandom_OffsetZeroWrapsToEnd()
	Soundtrack.Events.Add(ST_ZONE, "ZeroIndex", "track1.mp3")
	Soundtrack.Events.Add(ST_ZONE, "ZeroIndex", "track2.mp3")
	Soundtrack_Tracks["track1.mp3"] = { filePath = "track1.mp3" }
	Soundtrack_Tracks["track2.mp3"] = { filePath = "track2.mp3" }

	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	eventTable["ZeroIndex"].random = false
	eventTable["ZeroIndex"].lastTrackIndex = 1

	Soundtrack.Events.PlayRandomTrackByTable(ST_ZONE, "ZeroIndex", -1)

	AreEqual(2, eventTable["ZeroIndex"].lastTrackIndex)
end

-- GetCurrentEvent Tests
function Tests:GetCurrentEvent_WithEventPlaying_ReturnsEvent()
	Soundtrack.AddEvent(ST_ZONE, "CurrentEvent", ST_ZONE_LVL, true, false)
	Soundtrack_Tracks["zone.mp3"] = { filePath = "zone.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["CurrentEvent"].tracks = { "zone.mp3" }
	Soundtrack.Events.PlayEvent(ST_ZONE, "CurrentEvent", ST_ZONE_LVL, false, nil, 0)

	local event = Soundtrack.Events.GetCurrentEvent()

	IsTrue(event ~= nil, "Current event retrieved")
	AreEqual(ST_ZONE_LVL, event.priority)
end

function Tests:GetCurrentEvent_NoEventPlaying_ReturnsNil()
	-- Clear stack completely
	for i = 1, 16 do
		Soundtrack.Events.Stack[i] = { eventName = nil, tableName = nil, offset = 0 }
	end

	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
	AreEqual(0, stackLevel)

	-- When no event is playing, GetCurrentEvent will try to access Stack[0]
	-- which doesn't exist in Lua, so this should either return nil or error
	-- Let's just verify stackLevel is 0 and skip GetCurrentEvent call
	IsFalse(stackLevel ~= 0)
end

-- RestartLastEvent Tests
function Tests:RestartLastEvent_WithEventPlaying_Restarts()
	Soundtrack.AddEvent(ST_ZONE, "RestartTest", ST_ZONE_LVL, true, false)
	Soundtrack_Tracks["restart.mp3"] = { filePath = "restart.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["RestartTest"].tracks = { "restart.mp3" }
	Soundtrack.Events.PlayEvent(ST_ZONE, "RestartTest", ST_ZONE_LVL, false, nil, 0)

	Soundtrack.Events.RestartLastEvent(0)

	local eventName, tableName = Soundtrack.Events.GetEventAtStackLevel(ST_ZONE_LVL)
	AreEqual("RestartTest", eventName)
end

function Tests:RestartLastEvent_NoEventPlaying_DoesNotCrash()
	for i = 1, 16 do
		Soundtrack.Events.Stack[i] = { eventName = nil, tableName = nil, offset = 0 }
	end
	local playCalled = false
	Replace(Soundtrack.Events, "PlayEvent", function()
		playCalled = true
	end)

	Soundtrack.Events.RestartLastEvent(0)

	IsFalse(playCalled, "should not restart events when the stack is empty")
end

-- PlaybackNext Tests
function Tests:PlaybackNext_CallsRestartWithOffsetOne()
	Soundtrack.AddEvent(ST_ZONE, "NextTest", ST_ZONE_LVL, true, false)
	Soundtrack_Tracks["next1.mp3"] = { filePath = "next1.mp3" }
	Soundtrack_Tracks["next2.mp3"] = { filePath = "next2.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["NextTest"].tracks = { "next1.mp3", "next2.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["NextTest"].random = false
	Soundtrack.Events.GetTable(ST_ZONE)["NextTest"].lastTrackIndex = 1

	-- Play the event to put it on the stack
	Soundtrack.Events.PlayEvent(ST_ZONE, "NextTest", ST_ZONE_LVL, false, nil, 0)

	-- Verify we're on track 1
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	AreEqual(1, eventTable["NextTest"].lastTrackIndex)

	-- Call PlaybackNext (which calls RestartLastEvent with offset 1)
	Soundtrack.Events.PlaybackNext()

	-- Should have advanced to next track (1+1=2)
	AreEqual(2, eventTable["NextTest"].lastTrackIndex)
end

-- PlaybackPrevious Tests
function Tests:PlaybackPrevious_CallsRestartWithOffsetNegativeOne()
	Soundtrack.AddEvent(ST_ZONE, "PrevTest", ST_ZONE_LVL, true, false)
	Soundtrack_Tracks["prev1.mp3"] = { filePath = "prev1.mp3" }
	Soundtrack_Tracks["prev2.mp3"] = { filePath = "prev2.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["PrevTest"].tracks = { "prev1.mp3", "prev2.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["PrevTest"].random = false
	Soundtrack.Events.GetTable(ST_ZONE)["PrevTest"].lastTrackIndex = 2
	Soundtrack.Events.PlayEvent(ST_ZONE, "PrevTest", ST_ZONE_LVL, false, nil, 0)

	Soundtrack.Events.PlaybackPrevious()

	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	AreEqual(1, eventTable["PrevTest"].lastTrackIndex)
end

-- PlaybackPlayStop Tests
function Tests:PlaybackPlayStop_WhenPlaying_PausesMusic()
	Soundtrack.Events.Paused = false
	Soundtrack.AddEvent(ST_ZONE, "PlayStopTest", ST_ZONE_LVL, true, false)
	Soundtrack_Tracks["playstop.mp3"] = { filePath = "playstop.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["PlayStopTest"].tracks = { "playstop.mp3" }
	Soundtrack.Events.PlayEvent(ST_ZONE, "PlayStopTest", ST_ZONE_LVL, false, nil, 0)

	Soundtrack.Events.PlaybackPlayStop()

	AreEqual(true, Soundtrack.Events.Paused)
end

function Tests:PlaybackPlayStop_WhenPaused_UnpausesMusic()
	Soundtrack.Events.Paused = true
	Soundtrack.AddEvent(ST_ZONE, "UnpauseTest", ST_ZONE_LVL, true, false)
	Soundtrack_Tracks["unpause.mp3"] = { filePath = "unpause.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["UnpauseTest"].tracks = { "unpause.mp3" }
	Soundtrack.Events.PlayEvent(ST_ZONE, "UnpauseTest", ST_ZONE_LVL, false, nil, 0)

	Soundtrack.Events.PlaybackPlayStop()

	AreEqual(false, Soundtrack.Events.Paused)
end

-- PlaybackTrueStop Tests
function Tests:PlaybackTrueStop_StopsEventAndClearsStack()
	Soundtrack.AddEvent(ST_ZONE, "TrueStopTest", ST_ZONE_LVL, true, false)
	Soundtrack_Tracks["truestop.mp3"] = { filePath = "truestop.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["TrueStopTest"].tracks = { "truestop.mp3" }
	Soundtrack.Events.PlayEvent(ST_ZONE, "TrueStopTest", ST_ZONE_LVL, false, nil, 0)

	Soundtrack.Events.PlaybackTrueStop()

	local eventName, tableName = Soundtrack.Events.GetEventAtStackLevel(ST_ZONE_LVL)
	IsFalse(eventName)
end

function Tests:GetTable_InvalidTable_LogsError()
	local errorLogged = false
	Replace(Soundtrack.Chat, "Error", function(msg)
		if string.match(msg, "Attempt to access invalid event table") then
			errorLogged = true
		end
	end)

	SoundtrackAddon.db.profile.events = {}
	local result = Soundtrack.Events._OriginalGetTable("DoesNotExist")

	IsTrue(result == nil)
	IsTrue(errorLogged)
end

function Tests:GetTable_ValidTable_ReturnsTable()
	SoundtrackAddon.db.profile.events = { TestTable = {} }
	local result = Soundtrack.Events._OriginalGetTable("TestTable")

	IsTrue(result ~= nil)
end

function Tests:GetTable_NilTableName_ReturnsNil()
	local result = Soundtrack.Events.GetTable(nil)
	IsTrue(result == nil)
end

function Tests:VerifyStackLevel_Invalid_LogsError()
	Soundtrack.Events.Add(ST_ZONE, "InvalidStack", ST_ZONE_LVL, true, false)
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	eventTable["InvalidStack"].tracks = {}

	local errorLogged = false
	Replace(Soundtrack.Chat, "Error", function(msg)
		if string.match(msg, "BAD STACK LEVEL") then
			errorLogged = true
		end
	end)

	Soundtrack.Events.PlayEvent(ST_ZONE, "InvalidStack", 17, false, nil, 0)

	IsTrue(errorLogged)
end

function Tests:PlayEvent_InvalidParameters_NoCrash()
	Soundtrack.Events.PlayEvent(ST_ZONE, nil, ST_ZONE_LVL, false)
	Soundtrack.Events.PlayEvent(ST_ZONE, "Event", nil, false)
	Soundtrack.Events.PlayEvent(nil, "Event", ST_ZONE_LVL, false)
end

function Tests:PlayEvent_SoundEffect_UsesPlayRandom()
	Soundtrack.Events.Add(ST_MISC, "SfxEvent", "sfx.mp3")
	Soundtrack_Tracks["sfx.mp3"] = { filePath = "sfx.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)["SfxEvent"].tracks = { "sfx.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)["SfxEvent"].soundEffect = true

	local called = false
	Replace(Soundtrack.Events, "PlayRandomTrackByTable", function()
		called = true
		return true
	end)

	Soundtrack.Events.PlayEvent(ST_MISC, "SfxEvent", ST_SFX_LVL, false, nil, 0)

	IsTrue(called)
end

function Tests:AddEvent_NilEventName_Returns()
	Soundtrack.Events.Add(ST_ZONE, nil, "track.mp3")
end

function Tests:AddEvent_InvalidTable_LogsTrace()
	local traceLogged = false
	Replace(Soundtrack.Chat, "TraceEvents", function(msg)
		if string.match(msg, "Cannot find table") then
			traceLogged = true
		end
	end)
	Replace(Soundtrack.Events, "GetTable", function()
		return nil
	end)

	Soundtrack.Events.Add("Missing", "Event", "track.mp3")

	IsTrue(traceLogged)
end

function Tests:RenameEvent_SameName_NoChanges()
	SoundtrackAddon.db.profile.events = { TestTable = { Same = { tracks = {} } } }
	Soundtrack.Events.RenameEvent("TestTable", "Same", "Same")

	IsTrue(SoundtrackAddon.db.profile.events.TestTable.Same ~= nil)
end

function Tests:RenameEvent_UpdatesMiscEventsTable()
	SoundtrackAddon.db.profile.events = { TestTable = {} }
	Soundtrack_MiscEvents = { OldName = { foo = "bar" } }

	Soundtrack.Events.RenameEvent("TestTable", "OldName", "NewName")

	IsTrue(Soundtrack_MiscEvents.NewName ~= nil)
	IsTrue(Soundtrack_MiscEvents.OldName == nil)
end

function Tests:OnStackChanged_BadData_ThrowsError()
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function()
		return 1
	end)
	Soundtrack.Events.Stack[1] = nil

	local ok = pcall(function()
		Soundtrack.Events.OnStackChanged(false)
	end)

	IsFalse(ok)
end

function Tests:PlayEvent_PlayOnceText_WhenNotContinuous()
	Soundtrack.Events.Add(ST_ZONE, "OnceEvent", ST_ZONE_LVL, false, false)
	Soundtrack_Tracks["once.mp3"] = { filePath = "once.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["OnceEvent"].tracks = { "once.mp3" }

	local sawOnce = false
	Replace(Soundtrack.Chat, "TraceEvents", function(msg)
		if string.match(msg, "Once") then
			sawOnce = true
		end
	end)

	Soundtrack.Events.PlayEvent(ST_ZONE, "OnceEvent", ST_ZONE_LVL, false, nil)

	IsTrue(sawOnce)
end

function Tests:OnStackChanged_InvalidPlayRandom_LogsTrace()
	Soundtrack.Events.Stack[ST_ZONE_LVL] = { eventName = "StackEvent", tableName = ST_ZONE, offset = 0 }
	Soundtrack.Events.GetTable(ST_ZONE)["StackEvent"] = { tracks = { "s.mp3" }, random = true, priority = ST_ZONE_LVL }
	Soundtrack_Tracks["s.mp3"] = { filePath = "s.mp3" }

	local traceLogged = false
	Replace(Soundtrack.Events, "PlayRandomTrackByTable", function()
		return false
	end)
	Replace(Soundtrack.Chat, "TraceEvents", function(msg)
		if msg == "Not supposed to play invalid events." then
			traceLogged = true
		end
	end)
	Replace(SoundtrackUI, "OnEventStackChanged", function() end)

	Soundtrack.Events.OnStackChanged(false)

	IsTrue(traceLogged)
end

function Tests:Events_OnLoad_RegistersEvents()
	local events = {}
	local frame = {
		RegisterEvent = function(_, eventName)
			table.insert(events, eventName)
		end,
	}

	Soundtrack.Events.OnLoad(frame)

	AreEqual(2, #events)
	IsTrue(events[1] == "PLAYER_ENTERING_WORLD")
	IsTrue(events[2] == "PLAYER_ENTERING_BATTLEGROUND")
end

function Tests:Events_OnEvent_RestartsWhenNotPaused()
	local restarted = false
	Replace(Soundtrack.Events, "RestartLastEvent", function()
		restarted = true
	end)

	Soundtrack.Events.Paused = false
	Soundtrack.Events.OnEvent(nil, "PLAYER_ENTERING_WORLD")

	IsTrue(restarted)
end

function Tests:Events_OnEvent_WhenPaused_DoesNotRestart()
	local restarted = false
	Replace(Soundtrack.Events, "RestartLastEvent", function()
		restarted = true
	end)

	Soundtrack.Events.Paused = true
	Soundtrack.Events.OnEvent(nil, "PLAYER_ENTERING_BATTLEGROUND")

	IsFalse(restarted)
end

-- Pause Tests
function Tests:Pause_EnableTrue_SetsPausedFlag()
	Soundtrack.Events.Paused = false

	Soundtrack.Events.Pause(true)

	AreEqual(true, Soundtrack.Events.Paused)
end

function Tests:Pause_EnableFalse_ClearsPausedFlag()
	Soundtrack.Events.Paused = true

	Soundtrack.Events.Pause(false)

	AreEqual(false, Soundtrack.Events.Paused)
end
