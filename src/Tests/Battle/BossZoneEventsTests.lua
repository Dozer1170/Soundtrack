if not Tests then
	return
end

local Tests = Tests("BossZoneEvents", "PLAYER_REGEN_DISABLED")

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

local function MockInstance(continentName, instanceName)
	Replace("IsInInstance", function()
		return true, "party"
	end)
	Replace(C_Map, "GetBestMapForUnit", function()
		return 946
	end)
	Replace(MapUtil, "GetMapParentInfo", function(_, zoneLevel)
		return {
			name = zoneLevel == 3 and instanceName or continentName,
		}
	end)
	Replace("GetRealZoneText", function()
		return instanceName
	end)
	Replace("GetSubZoneText", function()
		return ""
	end)
	Replace("GetMinimapZoneText", function()
		return instanceName
	end)
end

-- Initialize Tests

function Tests:Initialize_CreatesNoEvents()
	Soundtrack.BossZoneEvents.Initialize()

	local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	local count = 0
	for _ in pairs(eventTable) do
		count = count + 1
	end
	AreEqual(0, count, "Boss Zones should start empty")
end

function Tests:Initialize_CopiesZonesFromZoneTable()
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms/Elwynn Forest", ST_ZONE_LVL, true)

	Soundtrack.BossZoneEvents.Initialize()

	local bossZoneTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	IsTrue(bossZoneTable["Eastern Kingdoms"] ~= nil, "Continent copied to boss zones")
	IsTrue(bossZoneTable["Eastern Kingdoms/Elwynn Forest"] ~= nil, "Zone copied to boss zones")
	AreEqual(ST_BOSS_LVL, bossZoneTable["Eastern Kingdoms"].priority, "Continent has boss priority")
	AreEqual(ST_BOSS_LVL, bossZoneTable["Eastern Kingdoms/Elwynn Forest"].priority, "Zone has boss priority")
end

function Tests:Initialize_DoesNotOverwriteExistingBossZones()
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms/Elwynn Forest", ST_ZONE_LVL, true)
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Eastern Kingdoms/Elwynn Forest", ST_BOSS_LVL, true)
	Soundtrack.Events.Add(ST_BOSS_ZONES, "Eastern Kingdoms/Elwynn Forest", "Sound/Music/boss.mp3")

	Soundtrack.BossZoneEvents.Initialize()

	local bossZoneTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	AreEqual(1, #bossZoneTable["Eastern Kingdoms/Elwynn Forest"].tracks, "Existing boss zone tracks preserved")
end

function Tests:Initialize_CreatesAncestorPathsForDeepZones()
	-- Only the deep path is in ST_ZONE (e.g. player visited instance before zone init ran)
	Soundtrack.AddEvent(ST_ZONE, "Instances/Amirdrassil", ST_ZONE_LVL, true)

	Soundtrack.BossZoneEvents.Initialize()

	local bossZoneTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	IsTrue(bossZoneTable["Instances"] ~= nil, "Ancestor 'Instances' created in boss zones")
	IsTrue(bossZoneTable["Instances/Amirdrassil"] ~= nil, "Zone 'Instances/Amirdrassil' created in boss zones")
end

-- AddCurrentZone Tests

function Tests:AddCurrentZone_OutdoorZone_CreatesHierarchy()
	MockZone("Eastern Kingdoms", "Elwynn Forest", "Goldshire", "Lion's Pride Inn")

	Soundtrack.BossZoneEvents.AddCurrentZone()

	local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	IsTrue(eventTable["Eastern Kingdoms"], "Continent created")
	IsTrue(eventTable["Eastern Kingdoms/Elwynn Forest"], "Zone created")
	IsTrue(eventTable["Eastern Kingdoms/Elwynn Forest/Goldshire"], "Subzone created")
	IsTrue(eventTable["Eastern Kingdoms/Elwynn Forest/Goldshire/Lion's Pride Inn"], "Minimap zone created")
end

function Tests:AddCurrentZone_TwoPartZone_CreatesEntries()
	MockZone("Kalimdor", "Mulgore", "", "")

	Soundtrack.BossZoneEvents.AddCurrentZone()

	local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	IsTrue(eventTable["Kalimdor"], "Continent created")
	IsTrue(eventTable["Kalimdor/Mulgore"], "Zone created")
end

function Tests:AddCurrentZone_Instance_UsesInstanceCategory()
	MockInstance("Instances", "The Deadmines")

	Soundtrack.BossZoneEvents.AddCurrentZone()

	local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	IsTrue(eventTable["Instances"], "Instance continent created")
	IsTrue(eventTable["Instances/The Deadmines"], "Instance zone created")
end

function Tests:AddCurrentZone_CalledTwice_DoesNotDuplicate()
	MockZone("Eastern Kingdoms", "Elwynn Forest", "", "")

	Soundtrack.BossZoneEvents.AddCurrentZone()
	Soundtrack.BossZoneEvents.AddCurrentZone()

	local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	IsTrue(eventTable["Eastern Kingdoms/Elwynn Forest"], "Zone exists")
end

function Tests:AddCurrentZone_EventHasBossLevelPriority()
	MockZone("Eastern Kingdoms", "Deadmines", "", "")

	Soundtrack.BossZoneEvents.AddCurrentZone()

	local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	AreEqual(ST_BOSS_LVL, eventTable["Eastern Kingdoms/Deadmines"].priority,
		"Boss zone event should have boss level priority")
end

-- GetCurrentBossZoneEvent Tests

function Tests:GetCurrentBossZoneEvent_NoEvents_ReturnsNil()
	MockZone("Eastern Kingdoms", "Elwynn Forest", "", "")

	local result = Soundtrack.BossZoneEvents.GetCurrentBossZoneEvent()

	AreEqual(nil, result, "Should return nil when no boss zone events exist")
end

function Tests:GetCurrentBossZoneEvent_EventWithNoTracks_ReturnsNil()
	MockZone("Eastern Kingdoms", "Elwynn Forest", "", "")
	Soundtrack.BossZoneEvents.AddCurrentZone()

	local result = Soundtrack.BossZoneEvents.GetCurrentBossZoneEvent()

	AreEqual(nil, result, "Should return nil when event has no tracks")
end

function Tests:GetCurrentBossZoneEvent_EventWithTracks_ReturnsMostSpecific()
	MockZone("Eastern Kingdoms", "Elwynn Forest", "Goldshire", "")

	Soundtrack.BossZoneEvents.AddCurrentZone()

	-- Add tracks to the zone-level event
	Soundtrack.Events.Add(ST_BOSS_ZONES, "Eastern Kingdoms/Elwynn Forest", "Sound/Music/boss1.mp3")

	local result = Soundtrack.BossZoneEvents.GetCurrentBossZoneEvent()

	AreEqual("Eastern Kingdoms/Elwynn Forest", result, "Should return the zone with tracks")
end

function Tests:GetCurrentBossZoneEvent_MultipleEventsWithTracks_ReturnsMostSpecific()
	MockZone("Eastern Kingdoms", "Elwynn Forest", "Goldshire", "")

	Soundtrack.BossZoneEvents.AddCurrentZone()

	-- Add tracks to both zone and subzone
	Soundtrack.Events.Add(ST_BOSS_ZONES, "Eastern Kingdoms/Elwynn Forest", "Sound/Music/boss1.mp3")
	Soundtrack.Events.Add(ST_BOSS_ZONES, "Eastern Kingdoms/Elwynn Forest/Goldshire", "Sound/Music/boss2.mp3")

	local result = Soundtrack.BossZoneEvents.GetCurrentBossZoneEvent()

	AreEqual("Eastern Kingdoms/Elwynn Forest/Goldshire", result, "Should return most specific zone with tracks")
end

function Tests:GetCurrentBossZoneEvent_OnlyContinentHasTracks_ReturnsContinentEvent()
	MockZone("Eastern Kingdoms", "Elwynn Forest", "", "")

	Soundtrack.BossZoneEvents.AddCurrentZone()

	-- Add tracks only to continent
	Soundtrack.Events.Add(ST_BOSS_ZONES, "Eastern Kingdoms", "Sound/Music/boss_continent.mp3")

	local result = Soundtrack.BossZoneEvents.GetCurrentBossZoneEvent()

	AreEqual("Eastern Kingdoms", result, "Should fall back to continent event")
end

-- Integration: Battle system uses boss zone events

local function MockUnit(unitId, classification, isPlayer, isAlive, isEnemy, isBoss)
	Replace("UnitExists", function(unit)
		return unit == unitId or string.match(unitId, unit)
	end)
	Replace("UnitClassification", function(unit)
		if unit == unitId then
			return classification
		end
		return "normal"
	end)
	Replace("UnitIsPlayer", function(unit)
		return unit == unitId and isPlayer or false
	end)
	Replace("UnitIsDeadOrGhost", function(unit)
		return unit == unitId and not isAlive or false
	end)
	Replace("UnitIsFriend", function(_, unit)
		if unit == unitId then
			return not isEnemy
		end
		return true
	end)
	Replace("UnitCanAttack", function(_, unit)
		return unit == unitId and isEnemy or false
	end)
end

function Tests:BossBattle_WithBossZoneTracks_PlaysBossZoneEvent()
	MockZone("Eastern Kingdoms", "Deadmines", "", "")

	-- Set up a boss zone event with tracks
	Soundtrack.BossZoneEvents.AddCurrentZone()
	Soundtrack.Events.Add(ST_BOSS_ZONES, "Eastern Kingdoms/Deadmines", "Sound/Music/deadmines_boss.mp3")

	-- Simulate boss encounter
	MockUnit("playertarget", "boss", false, true, true, true)
	Soundtrack.BattleEvents.Initialize()
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	local stackEvent = Soundtrack.Events.Stack[ST_BOSS_LVL]
	AreEqual("Eastern Kingdoms/Deadmines", stackEvent.eventName, "Boss zone event should be on the stack")
	AreEqual(ST_BOSS_ZONES, stackEvent.tableName, "Should be from Boss Zones table")
end

function Tests:BossBattle_WithoutBossZoneTracks_FallsBackToGeneric()
	MockZone("Eastern Kingdoms", "Deadmines", "", "")

	-- No boss zone tracks set up
	MockUnit("playertarget", "boss", false, true, true, true)
	Soundtrack.BattleEvents.Initialize()

	-- Add a track to the generic boss battle event so it plays
	Soundtrack.Events.Add(ST_BATTLE, SOUNDTRACK_BOSS_BATTLE, "Sound/Music/generic_boss.mp3")

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	local stackEvent = Soundtrack.Events.Stack[ST_BOSS_LVL]
	AreEqual(SOUNDTRACK_BOSS_BATTLE, stackEvent.eventName, "Generic boss event should be on the stack")
	AreEqual(ST_BATTLE, stackEvent.tableName, "Should be from Battle table")
end

-- TabUtils Tests

function Tests:TabUtils_BossZones_ReturnsIndex2()
	AreEqual(2, TabUtils.GetTabIndex(ST_BOSS_ZONES), "Boss Zones should be tab index 2")
end

function Tests:TabUtils_Zone_ReturnsIndex3()
	AreEqual(3, TabUtils.GetTabIndex(ST_ZONE), "Zone should be tab index 3 (shifted)")
end

function Tests:TabUtils_Battle_ReturnsIndex1()
	AreEqual(1, TabUtils.GetTabIndex(ST_BATTLE), "Battle should still be tab index 1")
end

function Tests:TabUtils_Playlists_ReturnsIndex7()
	AreEqual(7, TabUtils.GetTabIndex(ST_PLAYLISTS), "Playlists should be tab index 7 (shifted)")
end

-- DeleteZone Tests

function Tests:DeleteZone_RemovesSelectedZone()
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances", ST_BOSS_LVL, true)

	Soundtrack.BossZoneEvents.DeleteZone("Instances")

	IsTrue(Soundtrack.Events.GetTable(ST_BOSS_ZONES)["Instances"] == nil, "Selected zone removed")
end

function Tests:DeleteZone_RemovesChildZones()
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances", ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances/The Deadmines", ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances/Blackfathom Deeps", ST_BOSS_LVL, true)

	Soundtrack.BossZoneEvents.DeleteZone("Instances")

	local t = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	IsTrue(t["Instances"] == nil, "Parent zone removed")
	IsTrue(t["Instances/The Deadmines"] == nil, "First child removed")
	IsTrue(t["Instances/Blackfathom Deeps"] == nil, "Second child removed")
end

function Tests:DeleteZone_RemovesDeepChildren()
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Eastern Kingdoms", ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Eastern Kingdoms/Elwynn Forest", ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Eastern Kingdoms/Elwynn Forest/Goldshire", ST_BOSS_LVL, true)

	Soundtrack.BossZoneEvents.DeleteZone("Eastern Kingdoms")

	local t = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	IsTrue(t["Eastern Kingdoms"] == nil, "Grandparent removed")
	IsTrue(t["Eastern Kingdoms/Elwynn Forest"] == nil, "Child removed")
	IsTrue(t["Eastern Kingdoms/Elwynn Forest/Goldshire"] == nil, "Deep child removed")
end

function Tests:DeleteZone_PreservesUnrelatedZones()
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances", ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances/The Deadmines", ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Eastern Kingdoms", ST_BOSS_LVL, true)

	Soundtrack.BossZoneEvents.DeleteZone("Instances")

	IsTrue(Soundtrack.Events.GetTable(ST_BOSS_ZONES)["Eastern Kingdoms"] ~= nil, "Unrelated zone preserved")
end

function Tests:DeleteZone_ExactPrefixMatch_DoesNotRemoveSimilarNames()
	Soundtrack.AddEvent(ST_BOSS_ZONES, "Instances", ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BOSS_ZONES, "InstancesExtra", ST_BOSS_LVL, true)

	Soundtrack.BossZoneEvents.DeleteZone("Instances")

	IsTrue(Soundtrack.Events.GetTable(ST_BOSS_ZONES)["InstancesExtra"] ~= nil, "Similar-named zone preserved")
end
