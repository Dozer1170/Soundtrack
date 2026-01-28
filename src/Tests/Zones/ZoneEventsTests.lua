if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

local function MockZone(continentName, zoneName, subZoneName, minimapZoneName)
	Replace("IsInInstance", function()
		return false, "none"
	end)
	Replace(C_Map, "GetBestMapForUnit", function()
		return 946
	end)
	Replace(MapUtil, "GetMapParentInfo", function(_, zoneLevel)
		return {
			name = zoneLevel == 3 and zoneName or continentName,
		}
	end)
	Replace("GetRealZoneText", function()
		return zoneName
	end)
	Replace("GetSubZoneText", function()
		return subZoneName
	end)
	Replace("GetMinimapZoneText", function()
		return minimapZoneName
	end)
end

function Tests:OnEvent_FullyQualifiedOutdoorZone_Adds()
	MockZone("Eastern Kingdoms", "Elwynn Forest", "Dabrie Farm", "House")

	Soundtrack.ZoneEvents.OnEvent(self, "PLAYER_ENTERING_WORLD")

	Exists(Soundtrack.Events.GetTable(ST_ZONE)["Eastern Kingdoms/Elwynn Forest/Dabrie Farm/House"])
end

function Tests:OnEvent_ThreePartOutdoorZone_Adds()
	MockZone("Eastern Kingdoms", "Elwynn Forest", "Dabrie Farm")

	Soundtrack.ZoneEvents.OnEvent(self, "PLAYER_ENTERING_WORLD")

	Exists(Soundtrack.Events.GetTable(ST_ZONE)["Eastern Kingdoms/Elwynn Forest/Dabrie Farm"])
end

function Tests:OnEvent_TwoPartOutdoorZone_Adds()
	MockZone("Eastern Kingdoms", "Elwynn Forest New")

	Soundtrack.ZoneEvents.OnEvent(self, "PLAYER_ENTERING_WORLD")

	Exists(Soundtrack.Events.GetTable(ST_ZONE)["Eastern Kingdoms/Elwynn Forest New"])
end

function Tests:OnEvent_OnlyContinent_DoesNotAdd()
	MockZone("BrandNewContinent", nil, nil, nil)

	Soundtrack.ZoneEvents.OnEvent(self, "PLAYER_ENTERING_WORLD")

	IsFalse(Soundtrack.Events.GetTable(ST_ZONE)["BrandNewContinent"])
end

-- Zone Initialization Tests
function Tests:AddZones_FullHierarchy_CreatesAllLevels()
	MockZone("Kalimdor", "Mulgore", "Thunder Bluff", "Elder Rise")

	Soundtrack_ZoneEvents_AddZones()

	local zoneTable = Soundtrack.Events.GetTable(ST_ZONE)
	Exists(zoneTable["Kalimdor"])
	Exists(zoneTable["Kalimdor/Mulgore"])
	Exists(zoneTable["Kalimdor/Mulgore/Thunder Bluff"])
	Exists(zoneTable["Kalimdor/Mulgore/Thunder Bluff/Elder Rise"])
end

function Tests:AddZones_AssignsPriorities_CorrectLevels()
	MockZone("Northrend", "Dragonblight", "Wyrmrest Temple", "Library")

	Soundtrack_ZoneEvents_AddZones()

	local continent = Soundtrack.GetEvent(ST_ZONE, "Northrend")
	local zone = Soundtrack.GetEvent(ST_ZONE, "Northrend/Dragonblight")
	local subzone = Soundtrack.GetEvent(ST_ZONE, "Northrend/Dragonblight/Wyrmrest Temple")
	local minimap = Soundtrack.GetEvent(ST_ZONE, "Northrend/Dragonblight/Wyrmrest Temple/Library")

	AreEqual(ST_CONTINENT_LVL, continent.priority)
	AreEqual(ST_ZONE_LVL, zone.priority)
	AreEqual(ST_SUBZONE_LVL, subzone.priority)
	AreEqual(ST_MINIMAP_LVL, minimap.priority)
end

function Tests:AddZones_Instance_CreatesInstanceEvent()
	Replace("IsInInstance", function()
		return true, "party"
	end)
	Replace("GetRealZoneText", function()
		return "Deadmines"
	end)

	Soundtrack.ZoneEvents.OnEvent(self, "PLAYER_ENTERING_WORLD")

	Exists(Soundtrack.Events.GetTable(ST_ZONE)[SOUNDTRACK_INSTANCES])
end

function Tests:AddZones_Arena_CreatesPvPEvent()
	Replace("IsInInstance", function()
		return true, "arena"
	end)
	Replace("GetRealZoneText", function()
		return "Dalaran Arena"
	end)

	Soundtrack.ZoneEvents.OnEvent(self, "PLAYER_ENTERING_WORLD")

	Exists(Soundtrack.Events.GetTable(ST_ZONE)[SOUNDTRACK_PVP])
end

function Tests:AddZones_NilZoneName_DoesNotCrash()
	Replace("GetRealZoneText", function()
		return nil
	end)

	Soundtrack_ZoneEvents_AddZones()

	Exists(true, "should handle nil zone gracefully without crashing")
end

function Tests:OnUpdate_ZoneMusicEnabled_PlaysZone()
	SoundtrackAddon.db.profile.settings.EnableZoneMusic = true
	MockZone("Outland", "Hellfire Peninsula", "", "")

	Soundtrack_ZoneEvents_AddZones()
	Soundtrack_Tracks["hellfire.mp3"] = { filePath = "hellfire.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["Outland/Hellfire Peninsula"].tracks = { "hellfire.mp3" }

	Soundtrack.ZoneEvents.OnUpdate()

	local eventName = Soundtrack.Events.GetEventAtStackLevel(ST_ZONE_LVL)
	AreEqual("Outland/Hellfire Peninsula", eventName)
end

function Tests:OnUpdate_ZoneMusicDisabled_DoesNotPlay()
	SoundtrackAddon.db.profile.settings.EnableZoneMusic = false
	MockZone("Draenor", "Frostfire Ridge", "", "")

	Soundtrack_ZoneEvents_AddZones()
	Soundtrack_Tracks["frostfire.mp3"] = { filePath = "frostfire.mp3" }
	Soundtrack.Events.GetTable(ST_ZONE)["Draenor/Frostfire Ridge"].tracks = { "frostfire.mp3" }

	local playEventCalled = false
	Replace(Soundtrack.Events, "PlayEvent", function()
		playEventCalled = true
	end)

	Soundtrack.ZoneEvents.OnUpdate()

	-- Zone music is disabled, so no event should be played
	IsFalse(playEventCalled)
end
