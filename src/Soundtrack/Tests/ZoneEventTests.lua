if not WoWUnit then
	return
end

local AreEqual, Exists, Replace = WoWUnit.AreEqual, WoWUnit.Exists, WoWUnit.Replace
local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

local function MockZone(continentName, zoneName, subZoneName, minimapZoneName)
	Replace("C_Map.GetBestMapForUnit", function()
		return 946
	end)
	Replace("MapUtil.GetMapParentInfo", function()
		return {
			c = continentName,
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

function Tests:OnEvent_AddsFullyQualifiedOutdoorZone_WhenPlayerEntersWorld()
	MockZone("Eastern Kingdoms", "Elwynn Forest", "Dabrie Farm", "House")

	Soundtrack.Events.OnEvent(self, "PLAYER_ENTERING_WORLD")

	Exists(Soundtrack.Events.GetTable(ST_ZONE)["Eastern Kingdoms/Elwynn Forest/Dabrie Farm/House"])
end

function Tests:OnEvent_AddsThreePartOutdoorZone_WhenPlayerEntersWorld()
	MockZone("Eastern Kingdoms", "Elwynn Forest", "Dabrie Farm")

	Soundtrack.Events.OnEvent(self, "PLAYER_ENTERING_WORLD")

	Exists(Soundtrack.Events.GetTable(ST_ZONE)["Eastern Kingdoms/Elwynn Forest/Dabrie Farm"])
end

function Tests:OnEvent_AddsTwoPartOutdoorZone_WhenPlayerEntersWorld()
	MockZone("Eastern Kingdoms", "Elwynn Forest New")

	Soundtrack.Events.OnEvent(self, "PLAYER_ENTERING_WORLD")

	Exists(Soundtrack.Events.GetTable(ST_ZONE)["Eastern Kingdoms/Elwynn Forest New"])
end

function Tests:OnEvent_AddsContinentZone_WhenPlayerEntersWorld()
	MockZone("BrandNewContinent")

	Soundtrack.Events.OnEvent(self, "PLAYER_ENTERING_WORLD")

	Exists(Soundtrack.Events.GetTable(ST_ZONE)["BrandNewContinent"])
end
