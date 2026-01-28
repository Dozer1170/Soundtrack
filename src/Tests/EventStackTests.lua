if not WoWUnit then
    return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

-- OnStackChanged Tests
function Tests:OnStackChanged_EmptyStack_CallsGetCurrentStackLevel()
    -- Setup: Clear the stack
    Soundtrack.Events.Stack = {}
    for i = 1, 16 do
        table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil, offset = 0 })
    end

    -- Mock GetCurrentStackLevel to return 0 (empty stack)
    local getLevelCalled = false
    Replace(Soundtrack.Events, "GetCurrentStackLevel", function()
        getLevelCalled = true
        return 0
    end)

    -- Mock dependencies
    Replace(Soundtrack.Library, "StopTrack", function() end)
    Replace(SoundtrackUI, "OnEventStackChanged", function() end)

    -- Call OnStackChanged
    Soundtrack.Events.OnStackChanged(false)

    -- Verify GetCurrentStackLevel was called
    AreEqual(true, getLevelCalled)
end

function Tests:OnStackChanged_WithValidEvent_PlaysTrack()
    -- Setup: Create a valid event on the stack
    Soundtrack.Events.Stack = {}
    for i = 1, 16 do
        table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil, offset = 0 })
    end

    -- Add valid event to stack
    Soundtrack.Events.Stack[1] = {
        eventName = "TestEvent",
        tableName = ST_BATTLE,
        offset = 0
    }

    -- Create the event in the database
    local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
    eventTable["TestEvent"] = {
        tracks = { "track1.mp3" },
        random = true,
        continuous = false
    }

    -- Mock dependencies
    local playRandomCalled = false
    Replace(Soundtrack.Events, "PlayRandomTrackByTable", function(tableName, eventName, offset)
        if tableName == ST_BATTLE and eventName == "TestEvent" then
            playRandomCalled = true
        end
        return true
    end)
    Replace(SoundtrackUI, "OnEventStackChanged", function() end)

    -- Call OnStackChanged
    Soundtrack.Events.OnStackChanged(false)

    -- Verify track played
    IsTrue(playRandomCalled, "PlayRandomTrackByTable called")
end

function Tests:OnStackChanged_SameEventPlaying_DoesNotRestart()
    -- Setup: Create event already playing
    Soundtrack.Events.Stack = {}
    for i = 1, 16 do
        table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil, offset = 0 })
    end

    Soundtrack.Events.Stack[1] = {
        eventName = "TestEvent",
        tableName = ST_BATTLE,
        offset = 0
    }

    local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
    eventTable["TestEvent"] = {
        tracks = { "track1.mp3" },
        random = true
    }

    -- Set as currently playing
    Soundtrack.Library.CurrentlyPlayingTrack = "track1.mp3"

    local playCount = 0
    Replace(Soundtrack.Events, "PlayRandomTrackByTable", function()
        playCount = playCount + 1
        return true
    end)
    Replace(SoundtrackUI, "OnEventStackChanged", function() end)
    Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)

    -- First call - should play
    Soundtrack.Events.OnStackChanged(false)
    local firstCallCount = playCount

    -- Second call with same event - should not play again
    Soundtrack.Events.OnStackChanged(false)

    AreEqual(firstCallCount, playCount)
end

function Tests:OnStackChanged_ForceRestart_RestartsTrack()
    -- Setup: Create event already playing
    Soundtrack.Events.Stack = {}
    for i = 1, 16 do
        table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil, offset = 0 })
    end

    Soundtrack.Events.Stack[1] = {
        eventName = "TestEvent",
        tableName = ST_BATTLE,
        offset = 0
    }

    local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
    eventTable["TestEvent"] = {
        tracks = { "track1.mp3" },
        random = true
    }

    Soundtrack.Library.CurrentlyPlayingTrack = "track1.mp3"

    local playCount = 0
    Replace(Soundtrack.Events, "PlayRandomTrackByTable", function()
        playCount = playCount + 1
        return true
    end)
    Replace(SoundtrackUI, "OnEventStackChanged", function() end)
    Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)

    -- Call with forceRestart = true
    Soundtrack.Events.OnStackChanged(true)

    -- Should play even though same event is already playing
    IsTrue(playCount > 0, "Track restarted with forceRestart")
end

function Tests:OnStackChanged_DifferentEvent_SwitchesToNewEvent()
    -- Setup: Create first event
    Soundtrack.Events.Stack = {}
    for i = 1, 16 do
        table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil, offset = 0 })
    end

    Soundtrack.Events.Stack[1] = {
        eventName = "Event1",
        tableName = ST_BATTLE,
        offset = 0
    }

    local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
    eventTable["Event1"] = { tracks = { "track1.mp3" }, random = true }
    eventTable["Event2"] = { tracks = { "track2.mp3" }, random = true }

    local lastPlayedEvent = nil
    Replace(Soundtrack.Events, "PlayRandomTrackByTable", function(tableName, eventName)
        lastPlayedEvent = eventName
        return true
    end)
    Replace(SoundtrackUI, "OnEventStackChanged", function() end)
    Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)

    -- Play first event
    Soundtrack.Events.OnStackChanged(false)
    AreEqual("Event1", lastPlayedEvent)

    -- Change to different event
    Soundtrack.Events.Stack[1].eventName = "Event2"
    Soundtrack.Events.OnStackChanged(false)

    -- Should switch to new event
    AreEqual("Event2", lastPlayedEvent)
end

function Tests:OnStackChanged_CallsUIUpdate()
    -- Setup
    Soundtrack.Events.Stack = {}
    for i = 1, 16 do
        table.insert(Soundtrack.Events.Stack, { eventName = nil, tableName = nil, offset = 0 })
    end

    local uiUpdateCalled = false
    Replace(SoundtrackUI, "OnEventStackChanged", function()
        uiUpdateCalled = true
    end)
    Replace(Soundtrack.Library, "StopTrack", function() end)

    -- Call OnStackChanged
    Soundtrack.Events.OnStackChanged(false)

    -- Verify UI was notified
    IsTrue(uiUpdateCalled, "UI OnEventStackChanged called")
end

-- OnEventTreeChanged Tests
function Tests:OnEventTreeChanged_UpdatesFlatEventsList()
    -- Setup: Create some events
    local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
    eventTable["Event1"] = { tracks = {}, expanded = true }
    eventTable["Event2"] = { tracks = {}, expanded = true }

    -- Initialize event nodes
    if not Soundtrack_EventNodes[ST_BATTLE] then
        Soundtrack_EventNodes[ST_BATTLE] = { name = ST_BATTLE, nodes = {}, tag = nil }
    end

    -- Add some nodes
    table.insert(Soundtrack_EventNodes[ST_BATTLE].nodes, {
        name = "Event1",
        tag = "Event1",
        nodes = {}
    })
    table.insert(Soundtrack_EventNodes[ST_BATTLE].nodes, {
        name = "Event2",
        tag = "Event2",
        nodes = {}
    })

    -- Mock UpdateEventsUI
    local updateCalled = false
    SoundtrackUI.UpdateEventsUI = function()
        updateCalled = true
    end

    -- Call OnEventTreeChanged
    Soundtrack.OnEventTreeChanged(ST_BATTLE)

    -- Verify flat events table was initialized
    IsTrue(Soundtrack_FlatEvents[ST_BATTLE] ~= nil)
    -- Verify UI was NOT updated (OnEventTreeChanged doesn't call UI directly)
    AreEqual(false, updateCalled)
end

function Tests:OnEventTreeChanged_HandlesExpandedEvents()
    -- Setup: Create hierarchical events
    local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
    eventTable["Continent"] = { tracks = {}, expanded = true }
    eventTable["Continent/Zone"] = { tracks = {}, expanded = false }
    eventTable["Continent/Zone/SubZone"] = { tracks = {}, expanded = true }

    -- Initialize event nodes
    Soundtrack_EventNodes[ST_ZONE] = {
        name = ST_ZONE,
        nodes = {
            {
                name = "Continent",
                tag = "Continent",
                nodes = {
                    {
                        name = "Zone",
                        tag = "Continent/Zone",
                        nodes = {
                            {
                                name = "SubZone",
                                tag = "Continent/Zone/SubZone",
                                nodes = {}
                            }
                        }
                    }
                }
            }
        },
        tag = nil
    }

    Replace(SoundtrackUI, "UpdateEventsUI", function() end)

    -- Call OnEventTreeChanged
    Soundtrack.OnEventTreeChanged(ST_ZONE)

    -- Verify collapsed node children are not in flat list
    local hasContinent = false
    local hasZone = false
    local hasSubZone = false

    for _, node in ipairs(Soundtrack_FlatEvents[ST_ZONE] or {}) do
        if node.tag == "Continent" then hasContinent = true end
        if node.tag == "Continent/Zone" then hasZone = true end
        if node.tag == "Continent/Zone/SubZone" then hasSubZone = true end
    end

    IsTrue(hasContinent, "Expanded parent in list")
    IsTrue(hasZone, "Zone in list")
    -- SubZone should NOT be in list because Zone is collapsed
    IsFalse(hasSubZone, "Collapsed children not in list")
end

function Tests:OnEventTreeChanged_DoesNotCallUI()
    -- Setup
    if not Soundtrack_EventNodes[ST_BATTLE] then
        Soundtrack_EventNodes[ST_BATTLE] = { name = ST_BATTLE, nodes = {}, tag = nil }
    end

    local updateCalled = false
    SoundtrackUI.UpdateEventsUI = function()
        updateCalled = true
    end

    -- Call OnEventTreeChanged
    Soundtrack.OnEventTreeChanged(ST_BATTLE)

    -- Verify UI update was NOT called (this function doesn't call UI directly)
    AreEqual(false, updateCalled)
end
