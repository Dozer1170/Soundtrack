Soundtrack.ZoneEvents = {}

local nextUpdateTime = 0
local updateInterval = 1
local zoneType = nil

local function FindContinentByZone()
	local inInstance, instanceType = IsInInstance()
	if inInstance then
		if instanceType == "arena" or instanceType == "pvp" then
			return SOUNDTRACK_PVP, nil
		end

		if instanceType == "party" or instanceType == "raid" or instanceType == "scenario" then
			return SOUNDTRACK_INSTANCES, nil
		end
	end

	-- Get continent
	local mapId = C_Map.GetBestMapForUnit("player")
	if mapId == nil then
		return SOUNDTRACK_UNKNOWN, nil
	end

	local c = MapUtil.GetMapParentInfo(mapId, Enum.UIMapType.Continent, true)
	local continent
	if c ~= nil then
		continent = c.name
	end

	-- Get zone
	-- Test that map has a zone map (i.e. Legion Dalaran is labeled dungeon, no zone map)
	local z = MapUtil.GetMapParentInfo(mapId, 3)
	local zone = GetRealZoneText()
	if z ~= nil then
		zone = z.name
	end

	if continent == nil then
		continent = SOUNDTRACK_UNKNOWN
	end

	return continent, zone
end

-- After migration, zone events have no priorities set. We only
-- discover them as we figure out which parent zones exist
local function AssignPriority(tableName, eventName, priority)
	local event = Soundtrack.GetEventByName(tableName, eventName)
	if event then
		event.priority = priority
	end
end

function Soundtrack.ZoneEvents.GetCurrentZonePaths()
	local zoneText = GetRealZoneText()
	if zoneText == nil then
		return {}
	end

	local continentName, zoneName = FindContinentByZone()
	local zoneSubText = GetSubZoneText()
	local minimapZoneText = GetMinimapZoneText()

	if zoneName ~= nil and zoneName ~= zoneText then
		if zoneSubText ~= nil and zoneSubText ~= "" then
			minimapZoneText = zoneSubText
		end
		if zoneText ~= nil and zoneText ~= "" then
			zoneSubText = zoneText
		end
		zoneText = zoneName
	end

	local zoneText1, zoneText2, zoneText3, zoneText4
	local zonePath

	if not IsNullOrEmpty(continentName) then
		zoneText1 = continentName
		zonePath = continentName
	end

	if not IsNullOrEmpty(zoneText) then
		zoneText2 = continentName .. "/" .. zoneText
		zonePath = zoneText2
	end

	if zoneText ~= zoneSubText and not IsNullOrEmpty(zoneSubText) then
		zoneText3 = zonePath .. "/" .. zoneSubText
		zonePath = zoneText3
	end

	if zoneText ~= minimapZoneText and zoneSubText ~= minimapZoneText and not IsNullOrEmpty(minimapZoneText) then
		zoneText4 = zonePath .. "/" .. minimapZoneText
		zonePath = zoneText4
	end

	local results = {}
	if zoneText4 then
		table.insert(results, zoneText4)
	end
	if zoneText3 then
		table.insert(results, zoneText3)
	end
	if zoneText2 then
		table.insert(results, zoneText2)
	end
	if zoneText1 then
		table.insert(results, zoneText1)
	end

	return results
end

function Soundtrack_ZoneEvents_AddZones()
	local zoneText = GetRealZoneText()
	if zoneText == nil then
		return
	end

	local continentName, zoneName = FindContinentByZone()
	local zoneSubText = GetSubZoneText()
	local minimapZoneText = GetMinimapZoneText()

	if zoneName ~= nil and zoneName ~= zoneText then
		if zoneSubText ~= nil and zoneSubText ~= "" then
			minimapZoneText = zoneSubText
		end
		if zoneText ~= nil and zoneText ~= "" then
			zoneSubText = zoneText
		end
		zoneText = zoneName
	end

	-- Construct full zone path
	local zoneText1, zoneText2, zoneText3, zoneText4, zonePath

	if not IsNullOrEmpty(continentName) then
		zoneText1 = continentName
		Soundtrack.Chat.TraceZones("AddZone Continent: " .. zoneText1)
		zonePath = continentName
	end

	if not IsNullOrEmpty(zoneText) then
		zoneText2 = continentName .. "/" .. zoneText
		Soundtrack.Chat.TraceZones("AddZone ZoneText: " .. zoneText2)
		zonePath = zoneText2
	end

	if zoneText ~= zoneSubText and not IsNullOrEmpty(zoneSubText) then
		zoneText3 = zonePath .. "/" .. zoneSubText
		Soundtrack.Chat.TraceZones("AddZone SubZoneText: " .. zoneText3)
		zonePath = zoneText3
	end

	if zoneText ~= minimapZoneText and zoneSubText ~= minimapZoneText and not IsNullOrEmpty(minimapZoneText) then
		zoneText4 = zonePath .. "/" .. minimapZoneText
		Soundtrack.Chat.TraceZones("AddZone MinimapZoneText: " .. zoneText4)
		zonePath = zoneText4
	end

	Soundtrack.Chat.TraceZones("AddZone Zone: " .. zonePath)

	local function AddZoneEvent(eventName, priority)
		local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
		if eventTable[eventName] == nil then
			Soundtrack.AddEvent(ST_ZONE, eventName, priority, true)
		end
		AssignPriority(ST_ZONE, eventName, priority)
	end
	if zoneText4 then
		AddZoneEvent(zoneText4, ST_MINIMAP_LVL)
	end

	if zoneText3 then
		AddZoneEvent(zoneText3, ST_SUBZONE_LVL)
	end

	if zoneText2 then
		AddZoneEvent(zoneText2, ST_ZONE_LVL)
	end

	if zoneText1 then
		AddZoneEvent(zoneText1, ST_CONTINENT_LVL)
	end
end

local function OnZoneChanged()
	local zoneText = GetRealZoneText()
	if zoneText == nil then
		return
	end

	local continentName, zoneName = FindContinentByZone()
	local zoneSubText = GetSubZoneText()
	local minimapZoneText = GetMinimapZoneText()
	if zoneName ~= nil and zoneName ~= zoneText then
		if zoneSubText ~= nil and zoneSubText ~= "" then
			minimapZoneText = zoneSubText
		end
		if zoneText ~= nil and zoneText ~= "" then
			zoneSubText = zoneText
		end
		zoneText = zoneName
	end

	-- Construct full zone path
	local zoneText1, zoneText2, zoneText3, zoneText4
	local zonePath

	if not IsNullOrEmpty(continentName) then
		zoneText1 = continentName
		zonePath = continentName
	end

	if not IsNullOrEmpty(zoneText) then
		zoneText2 = continentName .. "/" .. zoneText
		zonePath = zoneText2
	end

	if zoneText ~= zoneSubText and not IsNullOrEmpty(zoneSubText) then
		zoneText3 = zonePath .. "/" .. zoneSubText
		zonePath = zoneText3
	end

	if zoneText ~= minimapZoneText and zoneSubText ~= minimapZoneText and not IsNullOrEmpty(minimapZoneText) then
		zoneText4 = zonePath .. "/" .. minimapZoneText
		zonePath = zoneText4
	end

	Soundtrack.Chat.TraceZones("OnZoneChanged: " .. zonePath)

	if zoneText4 then
		if SoundtrackAddon.db.profile.settings.AutoAddZones then
			local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
			if eventTable ~= nil and eventTable[zoneText4] == nil then
				Soundtrack.AddEvent(ST_ZONE, zoneText4, ST_MINIMAP_LVL, true)
			end
		end
		AssignPriority(ST_ZONE, zoneText4, ST_MINIMAP_LVL)
		Soundtrack.PlayEvent(ST_ZONE, zoneText4, false)
	else
		Soundtrack.StopEventAtLevel(ST_MINIMAP_LVL)
	end

	if zoneText3 then
		if SoundtrackAddon.db.profile.settings.AutoAddZones then
			local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
			-- TODO: Make sure this still works as expected after add ~= check
			if eventTable ~= nil and eventTable[zoneText3] == nil then
				Soundtrack.AddEvent(ST_ZONE, zoneText3, ST_SUBZONE_LVL, true)
			end
		end
		AssignPriority(ST_ZONE, zoneText3, ST_SUBZONE_LVL)
		Soundtrack.PlayEvent(ST_ZONE, zoneText3, false)
	else
		Soundtrack.StopEventAtLevel(ST_SUBZONE_LVL)
	end

	if zoneText2 then
		if SoundtrackAddon.db.profile.settings.AutoAddZones then
			local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
			-- TODO: Make sure this still works as expected after add ~= check
			if eventTable ~= nil and eventTable[zoneText2] == nil then
				Soundtrack.AddEvent(ST_ZONE, zoneText2, ST_ZONE_LVL, true)
			end
		end
		AssignPriority(ST_ZONE, zoneText2, ST_ZONE_LVL)
		Soundtrack.PlayEvent(ST_ZONE, zoneText2, false)
	else
		Soundtrack.StopEventAtLevel(ST_ZONE_LVL)
	end

	if zoneText1 then
		if SoundtrackAddon.db.profile.settings.AutoAddZones then
			local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
			-- TODO: Make sure this still works as expected after add ~= check
			if eventTable ~= nil and eventTable[zoneText1] == nil then
				Soundtrack.AddEvent(ST_ZONE, zoneText1, ST_CONTINENT_LVL, true)
			end
		end
		AssignPriority(ST_ZONE, zoneText1, ST_CONTINENT_LVL)
		Soundtrack.PlayEvent(ST_ZONE, zoneText1, false)
	else
		Soundtrack.StopEventAtLevel(ST_CONTINENT_LVL)
	end
end

function Soundtrack.ZoneEvents.OnLoad(self)
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
	self:RegisterEvent("ZONE_CHANGED")
	self:RegisterEvent("ZONE_CHANGED_INDOORS")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
end

function Soundtrack.ZoneEvents.OnUpdate()
	local currentTime = GetTime()

	if currentTime >= nextUpdateTime then
		nextUpdateTime = currentTime + updateInterval

		local _, newZoneType = IsInInstance()
		if newZoneType ~= zoneType then
			zoneType = newZoneType
			OnZoneChanged()
		end
	end
end

function Soundtrack.ZoneEvents.OnEvent(_, event, _)
	if not SoundtrackAddon.db.profile.settings.EnableZoneMusic then
		return
	end

	Soundtrack.Chat.TraceZones(event)

	if
		event == "ZONE_CHANGED"
		or event == "ZONE_CHANGED_INDOORS"
		or event == "ZONE_CHANGED_NEW_AREA"
		or event == "PLAYER_ENTERING_WORLD"
	then
		Soundtrack.Chat.TraceZones("Event: " .. event)
		OnZoneChanged()
	end
end

function Soundtrack.ZoneEvents.Initialize()
	-- Add Instances and PVP 'continents'
	Soundtrack.AddEvent(ST_ZONE, SOUNDTRACK_INSTANCES, ST_CONTINENT_LVL, true)
	Soundtrack.AddEvent(ST_ZONE, SOUNDTRACK_PVP, ST_CONTINENT_LVL, true)

	-- 0 = "Cosmic"
	-- 1 = "World"
	-- 2 = "Continent"
	-- 3 = "Zone"
	-- 4 = "Dungeon"
	-- 5 = "Micro"
	-- 6 = "Orphan"

	local continents = C_Map.GetMapChildrenInfo(946, 2, 1)
	if continents == nil then
		return
	end

	for _, v in pairs(continents) do
		local continentName = v.name
		Soundtrack.AddEvent(ST_ZONE, continentName, ST_CONTINENT_LVL, true)
		-- Add zones for each continent
		local zones = C_Map.GetMapChildrenInfo(v.mapID, 3)
		for _, b in pairs(zones) do
			local zoneName = continentName .. "/" .. b.name
			Soundtrack.AddEvent(ST_ZONE, zoneName, ST_ZONE_LVL, true)
		end
	end
end
