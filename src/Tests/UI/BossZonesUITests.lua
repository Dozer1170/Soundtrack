if not Tests then
    return
end

local Tests = Tests("BossZonesUI", "PLAYER_ENTERING_WORLD")

local function SetupUI()
    Replace(SoundtrackUI, "UpdateEventsUI", function() end)
end

local function TriggerRemoveConfirmed()
    Replace(_G, "StaticPopup_Show", function() end)
    SoundtrackUI.OnFrameRemoveBossZoneButtonClick()
    StaticPopupDialogs["SOUNDTRACK_REMOVE_BOSS_ZONE_POPUP"].OnAccept()
end

-- RemoveBossZone Tests

function Tests:RemoveBossZone_RemovesSelectedZone()
    SetupUI()
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances", ST_BOSS_LVL, true)
    SoundtrackUI.SelectedEvent = "Instances"

    TriggerRemoveConfirmed()

    local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
    IsTrue(eventTable["Instances"] == nil, "Selected zone removed")
end

function Tests:RemoveBossZone_RemovesChildZones()
    SetupUI()
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances", ST_BOSS_LVL, true)
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances/The Deadmines", ST_BOSS_LVL, true)
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances/Blackfathom Deeps", ST_BOSS_LVL, true)
    SoundtrackUI.SelectedEvent = "Instances"

    TriggerRemoveConfirmed()

    local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
    IsTrue(eventTable["Instances"] == nil, "Parent zone removed")
    IsTrue(eventTable["Instances/The Deadmines"] == nil, "First child zone removed")
    IsTrue(eventTable["Instances/Blackfathom Deeps"] == nil, "Second child zone removed")
end

function Tests:RemoveBossZone_RemovesDeepNestedChildren()
    SetupUI()
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Eastern Kingdoms", ST_BOSS_LVL, true)
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Eastern Kingdoms/Elwynn Forest", ST_BOSS_LVL, true)
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Eastern Kingdoms/Elwynn Forest/Goldshire", ST_BOSS_LVL, true)
    SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

    TriggerRemoveConfirmed()

    local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
    IsTrue(eventTable["Eastern Kingdoms"] == nil, "Grandparent removed")
    IsTrue(eventTable["Eastern Kingdoms/Elwynn Forest"] == nil, "Child removed")
    IsTrue(eventTable["Eastern Kingdoms/Elwynn Forest/Goldshire"] == nil, "Deep child removed")
end

function Tests:RemoveBossZone_DoesNotRemoveUnrelatedZones()
    SetupUI()
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances", ST_BOSS_LVL, true)
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances/The Deadmines", ST_BOSS_LVL, true)
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Eastern Kingdoms", ST_BOSS_LVL, true)
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Eastern Kingdoms/Elwynn Forest", ST_BOSS_LVL, true)
    SoundtrackUI.SelectedEvent = "Instances"

    TriggerRemoveConfirmed()

    local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
    IsTrue(eventTable["Eastern Kingdoms"] ~= nil, "Unrelated zone preserved")
    IsTrue(eventTable["Eastern Kingdoms/Elwynn Forest"] ~= nil, "Unrelated child zone preserved")
end

function Tests:RemoveBossZone_PrefixMatchIsExact()
    -- "Instances" should not remove "InstancesExtra" or "Instances2"
    SetupUI()
    Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances", ST_BOSS_LVL, true)
    Soundtrack.AddEvent(ST_BOSS_ZONES, "InstancesExtra", ST_BOSS_LVL, true)
    SoundtrackUI.SelectedEvent = "Instances"

    TriggerRemoveConfirmed()

    local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
    IsTrue(eventTable["Instances"] == nil, "Selected zone removed")
    IsTrue(eventTable["InstancesExtra"] ~= nil, "Zone with similar name prefix preserved")
end
