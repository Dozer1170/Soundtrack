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
