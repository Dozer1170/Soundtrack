if not Tests then
	return
end

local Tests = Tests("ZonesUI", "PLAYER_ENTERING_WORLD")

local function SetupUI()
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
end

local function TriggerRemoveConfirmed()
	Replace(_G, "StaticPopup_Show", function() end)
	SoundtrackUI.OnFrameRemoveZoneButtonClick()
	StaticPopupDialogs["SOUNDTRACK_REMOVE_ZONE_POPUP"].OnAccept()
end

-- RemoveZone Tests

function Tests:RemoveZone_RemovesSelectedZone()
	SetupUI()
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	TriggerRemoveConfirmed()

	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	IsTrue(eventTable["Eastern Kingdoms"] == nil, "Selected zone removed")
end

function Tests:RemoveZone_RemovesChildZones()
	SetupUI()
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms/Elwynn Forest", ST_ZONE_LVL, true)
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms/Dun Morogh", ST_ZONE_LVL, true)
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	TriggerRemoveConfirmed()

	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	IsTrue(eventTable["Eastern Kingdoms"] == nil, "Parent zone removed")
	IsTrue(eventTable["Eastern Kingdoms/Elwynn Forest"] == nil, "First child zone removed")
	IsTrue(eventTable["Eastern Kingdoms/Dun Morogh"] == nil, "Second child zone removed")
end

function Tests:RemoveZone_RemovesDeepNestedChildren()
	SetupUI()
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms/Elwynn Forest", ST_ZONE_LVL, true)
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms/Elwynn Forest/Goldshire", ST_SUBZONE_LVL, true)
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	TriggerRemoveConfirmed()

	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	IsTrue(eventTable["Eastern Kingdoms"] == nil, "Grandparent removed")
	IsTrue(eventTable["Eastern Kingdoms/Elwynn Forest"] == nil, "Child removed")
	IsTrue(eventTable["Eastern Kingdoms/Elwynn Forest/Goldshire"] == nil, "Deep child removed")
end

function Tests:RemoveZone_DoesNotRemoveUnrelatedZones()
	SetupUI()
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms/Elwynn Forest", ST_ZONE_LVL, true)
	Soundtrack.AddEvent(ST_ZONE, "Kalimdor", ST_CONTINENT_LVL, true)
	Soundtrack.AddEvent(ST_ZONE, "Kalimdor/Mulgore", ST_ZONE_LVL, true)
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	TriggerRemoveConfirmed()

	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	IsTrue(eventTable["Kalimdor"] ~= nil, "Unrelated zone preserved")
	IsTrue(eventTable["Kalimdor/Mulgore"] ~= nil, "Unrelated child zone preserved")
end

function Tests:RemoveZone_PrefixMatchIsExact()
	SetupUI()
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	Soundtrack.AddEvent(ST_ZONE, "Eastern KingdomsExtra", ST_CONTINENT_LVL, true)
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	TriggerRemoveConfirmed()

	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	IsTrue(eventTable["Eastern Kingdoms"] == nil, "Selected zone removed")
	IsTrue(eventTable["Eastern KingdomsExtra"] ~= nil, "Zone with similar name prefix preserved")
end

-- OnAddZoneButtonClick Tests

function Tests:OnAddZoneButtonClick_WithZonePath_SetsSelectedEvent()
	SetupUI()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	Replace(_G, "Soundtrack_ZoneEvents_AddZones", function() end)
	Replace(Soundtrack.ZoneEvents, "GetCurrentZonePaths", function()
		return { "Eastern Kingdoms/Elwynn Forest", "Eastern Kingdoms" }
	end)

	SoundtrackUI.OnAddZoneButtonClick()

	AreEqual("Eastern Kingdoms/Elwynn Forest", SoundtrackUI.SelectedEvent, "SelectedEvent set to first zone path")
end

function Tests:OnAddZoneButtonClick_WithNoZonePath_SetsSelectedEventToRealZone()
	SetupUI()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	Replace(_G, "Soundtrack_ZoneEvents_AddZones", function() end)
	Replace(Soundtrack.ZoneEvents, "GetCurrentZonePaths", function()
		return {}
	end)
	Replace(_G, "GetRealZoneText", function() return "Stormwind City" end)

	SoundtrackUI.OnAddZoneButtonClick()

	AreEqual("Stormwind City", SoundtrackUI.SelectedEvent, "SelectedEvent set to GetRealZoneText when no paths")
end

function Tests:OnAddZoneButtonClick_CallsUpdateEventsUI()
	SetupUI()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	local called = false
	Replace(_G, "Soundtrack_ZoneEvents_AddZones", function() end)
	Replace(Soundtrack.ZoneEvents, "GetCurrentZonePaths", function() return {} end)
	Replace(SoundtrackUI, "UpdateEventsUI", function() called = true end)

	SoundtrackUI.OnAddZoneButtonClick()

	IsTrue(called, "UpdateEventsUI called after adding zone")
end

-- OnCollapseAllZoneButtonClick Tests

function Tests:OnCollapseAllZoneButtonClick_SetsExpandedFalse()
	SetupUI()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	Replace(Soundtrack, "OnEventTreeChanged", function() end)

	SoundtrackUI.OnCollapseAllZoneButtonClick()

	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	IsTrue(eventTable["Eastern Kingdoms"].expanded == false, "Zone event collapsed")
end

-- OnExpandAllZoneButtonClick Tests

function Tests:OnExpandAllZoneButtonClick_SetsExpandedTrue()
	SetupUI()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	SoundtrackAddon.db.profile.events[ST_ZONE]["Eastern Kingdoms"].expanded = false
	Replace(Soundtrack, "OnEventTreeChanged", function() end)

	SoundtrackUI.OnExpandAllZoneButtonClick()

	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	IsTrue(eventTable["Eastern Kingdoms"].expanded == true, "Zone event expanded")
end
