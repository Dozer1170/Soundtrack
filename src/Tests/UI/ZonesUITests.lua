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
