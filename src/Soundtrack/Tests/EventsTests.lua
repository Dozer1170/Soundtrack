if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

function Tests:EventHasTracks_EventWithTracks_ReturnsTrue()
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			TestEvent = {
				tracks = { "track1.mp3", "track2.mp3" }
			}
		}
	end)
	
	Exists(Soundtrack.Events.EventHasTracks("TestTable", "TestEvent") and "Event has tracks" or nil)
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
	
	IsFalse(Soundtrack.Events.EventHasTracks("TestTable", "NonexistentEvent"))
end

function Tests:EventExists_ExistingEvent_ReturnsTrue()
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			TestEvent = {
				tracks = { "track1.mp3" }
			}
		}
	end)
	
	Exists(Soundtrack.Events.EventExists("TestTable", "TestEvent") and "Event exists" or nil)
end

function Tests:EventExists_NonexistentEvent_ReturnsFalse()
	Replace(Soundtrack.Events, "GetTable", function()
		return {}
	end)
	
	IsFalse(Soundtrack.Events.EventExists("TestTable", "NonexistentEvent"))
end

function Tests:PushEvent_ValidStackLevel_PushesEvent()
	Soundtrack.Events.Stack = {}
	for i = 1, 16 do
		table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil })
	end
	
	Soundtrack.Events.PushEvent(ST_ZONE, "TestZone", 1)
	
	Exists(Soundtrack.Events.Stack[1].eventName == "TestZone" and "Event pushed" or nil)
end

function Tests:PopEvent_ValidStackLevel_PopsEvent()
	Soundtrack.Events.Stack = {}
	for i = 1, 16 do
		table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil })
	end
	Soundtrack.Events.Stack[1] = { eventName = "TestZone", tableName = ST_ZONE }
	
	Soundtrack.Events.PopEvent(1)
	
	Exists(Soundtrack.Events.Stack[1].eventName == nil and "Event popped" or nil)
end

function Tests:GetStack_ReturnsCurrentStack()
	Soundtrack.Events.Stack = { {eventName = "Test"} }
	
	local stack = Soundtrack.Events.GetStack()
	
	Exists(stack[1].eventName == "Test" and "Stack returned" or nil)
end

function Tests:GetEventName_WithEventAtLevel_ReturnsEventName()
	Soundtrack.Events.Stack = {}
	for i = 1, 16 do
		table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil })
	end
	Soundtrack.Events.Stack[5] = { eventName = "MountEvent", tableName = ST_MOUNT }
	
	local eventName = Soundtrack.Events.GetEventName(5)
	
	AreEqual("MountEvent", eventName)
end

function Tests:GetTableName_WithTableAtLevel_ReturnsTableName()
	Soundtrack.Events.Stack = {}
	for i = 1, 16 do
		table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil })
	end
	Soundtrack.Events.Stack[5] = { eventName = "MountEvent", tableName = ST_MOUNT }
	
	local tableName = Soundtrack.Events.GetTableName(5)
	
	AreEqual(ST_MOUNT, tableName)
end

function Tests:PauseEvents_SetsEventsPaused()
	Soundtrack.Events.Paused = false
	
	Soundtrack.Events.PauseEvents()
	
	Exists(Soundtrack.Events.Paused and "Events paused" or nil)
end

function Tests:ResumeEvents_ResumesPlayback()
	Soundtrack.Events.Paused = true
	
	Soundtrack.Events.ResumeEvents()
	
	IsFalse(Soundtrack.Events.Paused)
end
