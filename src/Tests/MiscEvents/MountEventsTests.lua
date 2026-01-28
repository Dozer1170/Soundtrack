if not Tests then
	return
end

local Tests = Tests("Soundtrack", "PLAYER_ENTERING_WORLD")

function Tests:Initialize_AddsGroundMountEvent()
	local eventsAdded = {}

	Replace(Soundtrack, "AddEvent", function(eventType, eventName, level, continuous)
		table.insert(eventsAdded, { type = eventType, name = eventName, level = level, continuous = continuous })
	end)

	Soundtrack.MountEvents.Initialize()

	local foundGroundMount = false
	for _, evt in ipairs(eventsAdded) do
		if evt.name == SOUNDTRACK_MOUNT_GROUND then
			foundGroundMount = true
			AreEqual(ST_MISC, evt.type)
			AreEqual(ST_MOUNT_LVL, evt.level)
			AreEqual(true, evt.continuous)
		end
	end

	AreEqual(true, foundGroundMount)
end

function Tests:Initialize_AddsFlightEvent()
	local eventsAdded = {}

	Replace(Soundtrack, "AddEvent", function(eventType, eventName, level, continuous)
		table.insert(eventsAdded, { type = eventType, name = eventName, level = level, continuous = continuous })
	end)

	Soundtrack.MountEvents.Initialize()

	local foundFlight = false
	for _, evt in ipairs(eventsAdded) do
		if evt.name == SOUNDTRACK_FLIGHT then
			foundFlight = true
			AreEqual(ST_MISC, evt.type)
			AreEqual(ST_MOUNT_LVL, evt.level)
		end
	end

	AreEqual(true, foundFlight)
end

function Tests:Initialize_RetailVersion_AddsFlyingMountEvent()
	local eventsAdded = {}

	Replace(Soundtrack, "AddEvent", function(eventType, eventName, level, continuous)
		table.insert(eventsAdded, { type = eventType, name = eventName, level = level, continuous = continuous })
	end)

	_G.IsRetail = true

	Soundtrack.MountEvents.Initialize()

	local foundFlyingMount = false
	for _, evt in ipairs(eventsAdded) do
		if evt.name == SOUNDTRACK_MOUNT_FLYING then
			foundFlyingMount = true
		end
	end

	AreEqual(true, foundFlyingMount)
	_G.IsRetail = nil
end

function Tests:OnUpdate_PlayerOnTaxi_PlaysFlightMusic()
	local playEventCalled = false
	local playedEventName = nil

	Replace("UnitOnTaxi", function() return true end)
	Replace("GetTime", function() return 1.0 end)
	Replace(Soundtrack, "PlayEvent", function(eventType, eventName)
		playEventCalled = true
		playedEventName = eventName
	end)
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			[SOUNDTRACK_FLIGHT] = {
				tracks = { "FlightTrack1" }
			}
		}
	end)

	Soundtrack.Events.Stack[ST_MOUNT_LVL] = { tableName = nil, eventName = nil }

	Soundtrack.MountEvents.OnUpdate()

	AreEqual(true, playEventCalled)
	AreEqual(SOUNDTRACK_FLIGHT, playedEventName)
end

function Tests:OnUpdate_PlayerLeavingTaxi_StopsFlightMusic()
	local stopEventCalled = false
	local stoppedEventName = nil

	Replace("UnitOnTaxi", function() return false end)
	Replace("GetTime", function() return 1.0 end)
	Replace(Soundtrack, "StopEvent", function(eventType, eventName)
		stopEventCalled = true
		stoppedEventName = eventName
	end)
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			[SOUNDTRACK_FLIGHT] = {
				tracks = { "FlightTrack1" }
			}
		}
	end)

	Soundtrack.Events.Stack[ST_MOUNT_LVL] = { tableName = ST_MISC, eventName = SOUNDTRACK_FLIGHT }

	-- Simulate being in flight first
	Replace("UnitOnTaxi", function() return true end)
	Soundtrack.MountEvents.OnUpdate()

	-- Now leaving taxi
	Replace("UnitOnTaxi", function() return false end)
	Replace("GetTime", function() return 1.2 end)
	Soundtrack.MountEvents.OnUpdate()

	AreEqual(true, stopEventCalled)
	AreEqual(SOUNDTRACK_FLIGHT, stoppedEventName)
end

function Tests:OnUpdate_PlayerMountedOnGround_PlaysGroundMountMusic()
	local playEventCalled = false
	local playedEventName = nil

	Replace("UnitOnTaxi", function() return false end)
	Replace("GetTime", function() return 1.0 end)
	Replace("IsMounted", function() return true end)
	Replace("IsFlying", function() return false end)
	Replace(Soundtrack, "PlayEvent", function(eventType, eventName)
		playEventCalled = true
		playedEventName = eventName
	end)
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			[SOUNDTRACK_MOUNT_GROUND] = {
				tracks = { "GroundMountTrack" }
			}
		}
	end)

	Soundtrack.Events.Stack[ST_MOUNT_LVL] = { tableName = nil, eventName = nil }

	Soundtrack.MountEvents.OnUpdate()

	AreEqual(true, playEventCalled)
	AreEqual(SOUNDTRACK_MOUNT_GROUND, playedEventName)
end

function Tests:OnUpdate_PlayerFlyingMounted_PlaysFlyingMountMusic()
	local playEventCalled = false
	local playedEventName = nil

	Replace("UnitOnTaxi", function() return false end)
	Replace("GetTime", function() return 1.0 end)
	Replace("IsMounted", function() return true end)
	Replace("IsFlying", function() return true end)
	Replace(Soundtrack, "PlayEvent", function(eventType, eventName)
		playEventCalled = true
		playedEventName = eventName
	end)
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			[SOUNDTRACK_MOUNT_FLYING] = {
				tracks = { "FlyingMountTrack" }
			}
		}
	end)

	Soundtrack.Events.Stack[ST_MOUNT_LVL] = { tableName = nil, eventName = nil }

	Soundtrack.MountEvents.OnUpdate()

	AreEqual(true, playEventCalled)
	AreEqual(SOUNDTRACK_MOUNT_FLYING, playedEventName)
end

function Tests:OnUpdate_PlayerDismounts_StopsGroundMountMusic()
	local stopEventCalled = false
	local stoppedEventName = nil

	Replace("UnitOnTaxi", function() return false end)
	Replace("GetTime", function() return 1.0 end)
	Replace("IsMounted", function() return false end)
	Replace("IsFlying", function() return false end)
	Replace(Soundtrack, "StopEvent", function(eventType, eventName)
		stopEventCalled = true
		stoppedEventName = eventName
	end)
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			[SOUNDTRACK_MOUNT_GROUND] = {
				tracks = { "GroundMountTrack" }
			}
		}
	end)

	Soundtrack.Events.Stack[ST_MOUNT_LVL] = { tableName = ST_MISC, eventName = SOUNDTRACK_MOUNT_GROUND }

	Soundtrack.MountEvents.OnUpdate()

	AreEqual(true, stopEventCalled)
	AreEqual(SOUNDTRACK_MOUNT_GROUND, stoppedEventName)
end

function Tests:OnUpdate_PlayerDismountFromFlying_StopsFlyingMountMusic()
	local stopEventCalled = false
	local stoppedEventName = nil

	Replace("UnitOnTaxi", function() return false end)
	Replace("GetTime", function() return 1.0 end)
	Replace("IsMounted", function() return false end)
	Replace("IsFlying", function() return false end)
	Replace(Soundtrack, "StopEvent", function(eventType, eventName)
		stopEventCalled = true
		stoppedEventName = eventName
	end)
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			[SOUNDTRACK_MOUNT_FLYING] = {
				tracks = { "FlyingMountTrack" }
			}
		}
	end)

	Soundtrack.Events.Stack[ST_MOUNT_LVL] = { tableName = ST_MISC, eventName = SOUNDTRACK_MOUNT_FLYING }

	Soundtrack.MountEvents.OnUpdate()

	AreEqual(true, stopEventCalled)
	AreEqual(SOUNDTRACK_MOUNT_FLYING, stoppedEventName)
end

function Tests:OnUpdate_MiscMusicDisabled_DoesNotPlayEvents()
	local playEventCalled = false

	Replace("UnitOnTaxi", function() return false end)
	Replace("GetTime", function() return 1.0 end)
	Replace("IsMounted", function() return true end)
	Replace("IsFlying", function() return false end)
	Replace(Soundtrack, "PlayEvent", function()
		playEventCalled = true
	end)

	SoundtrackAddon.db.profile.settings.EnableMiscMusic = false

	Soundtrack.MountEvents.OnUpdate()

	AreEqual(false, playEventCalled)
end

function Tests:OnUpdate_NoTracksAvailable_DoesNotPlay()
	local playEventCalled = false

	Replace("UnitOnTaxi", function() return false end)
	Replace("GetTime", function() return 1.0 end)
	Replace("IsMounted", function() return true end)
	Replace("IsFlying", function() return false end)
	Replace(Soundtrack, "PlayEvent", function()
		playEventCalled = true
	end)
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			[SOUNDTRACK_MOUNT_GROUND] = {
				tracks = {}
			}
		}
	end)

	Soundtrack.Events.Stack[ST_MOUNT_LVL] = { tableName = nil, eventName = nil }

	Soundtrack.MountEvents.OnUpdate()

	AreEqual(false, playEventCalled)
end

function Tests:OnUpdate_SameEventAlreadyPlaying_DoesNotPlayAgain()
	local playEventCallCount = 0

	Replace("UnitOnTaxi", function() return false end)
	Replace("GetTime", function() return 1.0 end)
	Replace("IsMounted", function() return true end)
	Replace("IsFlying", function() return false end)
	Replace(Soundtrack, "PlayEvent", function()
		playEventCallCount = playEventCallCount + 1
	end)
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			[SOUNDTRACK_MOUNT_GROUND] = {
				tracks = { "GroundMountTrack" }
			}
		}
	end)

	Soundtrack.Events.Stack[ST_MOUNT_LVL] = { tableName = ST_MISC, eventName = SOUNDTRACK_MOUNT_GROUND }

	Soundtrack.MountEvents.OnUpdate()

	AreEqual(0, playEventCallCount)
end

function Tests:OnUpdate_RespectUpdateInterval_ThrottlesCalls()
	local updateCount = 0

	Replace("UnitOnTaxi", function() return false end)
	Replace("IsMounted", function() return false end)
	Replace("IsFlying", function() return false end)

	-- First call at time 0
	Replace("GetTime", function() return 0.0 end)
	Soundtrack.MountEvents.OnUpdate()
	updateCount = updateCount + 1

	-- Second call at time 0.05 (should be throttled)
	Replace("GetTime", function() return 0.05 end)
	Soundtrack.MountEvents.OnUpdate()
	-- Logic would not run due to throttle

	-- Third call at time 0.2 (should run)
	Replace("GetTime", function() return 0.2 end)
	Soundtrack.MountEvents.OnUpdate()
	updateCount = updateCount + 1

	-- We expect the logic to run twice
	AreEqual(2, updateCount)
end
