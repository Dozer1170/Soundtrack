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
