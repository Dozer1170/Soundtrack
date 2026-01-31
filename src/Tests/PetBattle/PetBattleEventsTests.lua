if not Tests then
	return
end

local Tests = Tests("Soundtrack", "PET_BATTLE_OPENING_START")

local function SetupTarget(name, isPlayerValue, eventExists, hasTracks)
	Replace(_G, "UnitName", function() return name end)
	Replace(_G, "UnitIsPlayer", function() return isPlayerValue end)
	Replace(Soundtrack.Events, "EventExists", function()
		return eventExists
	end)
	Replace(Soundtrack.Events, "EventHasTracks", function()
		return hasTracks
	end)

	Soundtrack.PetBattleEvents.GetPlayerTargetInfo()
	Soundtrack.PetBattleEvents.CheckPlayerTarget()
end

local function CapturePlayEvent()
	local played = {}
	Replace(Soundtrack, "PlayEvent", function(tableName, eventName)
		played.tableName = tableName
		played.eventName = eventName
	end)
	return played
end

function Tests:OnLoad_RegistersPetBattleEvents()
	local events = {}
	local frame = {
		RegisterEvent = function(_, eventName)
			table.insert(events, eventName)
		end,
	}

	Soundtrack.PetBattleEvents.OnLoad(frame)

	AreEqual(7, #events)
	IsTrue(events[1] == "PET_BATTLE_OPENING_START")
	IsTrue(events[2] == "PET_BATTLE_OVER")
	IsTrue(events[3] == "PET_BATTLE_PVP_DUEL_REQUESTED")
	IsTrue(events[4] == "PET_BATTLE_PVP_DUEL_REQUEST_CANCEL")
	IsTrue(events[5] == "PET_BATTLE_QUEUE_PROPOSAL_ACCEPTED")
	IsTrue(events[6] == "PET_BATTLE_QUEUE_PROPOSAL_DECLINED")
	IsTrue(events[7] == "PLAYER_TARGET_CHANGED")
end

function Tests:OnEvent_PetBattleOpeningStart_TriggersBattleEngaged()
	local battleEngagedCalled = false
	Replace(Soundtrack.PetBattleEvents, "BattleEngaged", function()
		battleEngagedCalled = true
	end)

	Soundtrack.PetBattleEvents.OnEvent(nil, "PET_BATTLE_OPENING_START")

	IsTrue(battleEngagedCalled, "BattleEngaged called")
end

function Tests:OnEvent_PetBattleOver_TriggersVictory()
	local victoryCalled = false
	Replace(Soundtrack.PetBattleEvents, "Victory", function()
		victoryCalled = true
	end)

	Soundtrack.PetBattleEvents.OnEvent(nil, "PET_BATTLE_OVER")

	IsTrue(victoryCalled, "Victory called")
end

function Tests:BattleEngaged_PlaysCorrectEvent()
	Replace(SoundtrackAddon.db, "profile", {
		settings = {
			EnablePetBattleMusic = true
		},
		events = SoundtrackAddon.db.profile.events
	})

	Replace("C_PetBattles", {
		IsWildBattle = function() return true end,
		IsInBattle = function() return true end,
		GetPVPMatchmakingInfo = function() return false end
	})

	Replace(C_Map, "GetBestMapForUnit", function() return 946 end)
	Replace(C_Map, "GetMapInfo", function(mapID)
		if mapID == 946 then
			return { parentMapID = 12 }
		elseif mapID == 12 then
			return { name = "Kalimdor" }
		end
		return { name = "TestZone" }
	end)

	Soundtrack.AddEvent(ST_PETBATTLES, "Kalimdor Wild Battle", ST_NPC_LVL, true, false)
	local eventTable = Soundtrack.Events.GetTable(ST_PETBATTLES)
	eventTable["Kalimdor Wild Battle"].tracks = { "test.mp3" }
	Soundtrack_Tracks["test.mp3"] = { filePath = "test.mp3" }

	Soundtrack.PetBattleEvents.BattleEngaged()

	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
	local eventName, tableName = Soundtrack.Events.GetEventAtStackLevel(stackLevel)

	AreEqual(true, tableName == ST_PETBATTLES)
end

function Tests:Initialize_AddsPetBattleWildEvents()
	Soundtrack_MiscEvents = {}
	local eventTable = Soundtrack.Events.GetTable(ST_PETBATTLES)
	local initialCount = 0
	for _ in pairs(eventTable) do
		initialCount = initialCount + 1
	end

	Soundtrack.PetBattleEvents.Initialize()

	local finalCount = 0
	for _ in pairs(eventTable) do
		finalCount = finalCount + 1
	end

	IsTrue(finalCount > initialCount, "Pet battle events initialized")
end

function Tests:OnEvent_PlayerTargetChanged_WithTarget_QueriesTarget()
	local getInfoCalled = false
	local checkCalled = false
	Replace(_G, "UnitExists", function() return true end)
	Replace(Soundtrack.PetBattleEvents, "GetPlayerTargetInfo", function()
		getInfoCalled = true
	end)
	Replace(Soundtrack.PetBattleEvents, "CheckPlayerTarget", function()
		checkCalled = true
	end)

	Soundtrack.PetBattleEvents.OnEvent(nil, "PLAYER_TARGET_CHANGED")

	IsTrue(getInfoCalled, "GetPlayerTargetInfo called")
	IsTrue(checkCalled, "CheckPlayerTarget called")
end

function Tests:OnEvent_PlayerTargetChanged_NoTarget_ClearsTargetState()
	Replace(_G, "UnitExists", function() return false end)
	Replace(_G, "UnitName", function() return "Target" end)
	Replace(_G, "UnitIsPlayer", function() return true end)
	Replace(_G, "issecretvalue", function() return false end)
	Replace(C_Map, "GetBestMapForUnit", function() return 946 end)
	Replace(C_Map, "GetMapInfo", function(mapID)
		if mapID == 946 then
			return { parentMapID = 12 }
		elseif mapID == 12 then
			return { name = "Kalimdor" }
		end
		return { name = "TestZone" }
	end)
	Replace("C_PetBattles", {
		IsWildBattle = function() return false end,
		IsInBattle = function() return true end,
		GetPVPMatchmakingInfo = function() return false end
	})

	Soundtrack.PetBattleEvents.GetPlayerTargetInfo()
	Soundtrack.PetBattleEvents.CheckPlayerTarget()

	local played = CapturePlayEvent()
	Soundtrack.PetBattleEvents.OnEvent(nil, "PLAYER_TARGET_CHANGED")
	Soundtrack.PetBattleEvents.BattleEngaged()

	AreEqual(ST_PETBATTLES, played.tableName)
	AreEqual("Kalimdor " .. SOUNDTRACK_NPC_BATTLE, played.eventName)
end

function Tests:BattleEngaged_PlayerTargetWithTracks_PlaysNamedPlayerEvent()
	local played = CapturePlayEvent()
	Replace(_G, "issecretvalue", function() return false end)

	SetupTarget("Duelist", true, true, true)
	Soundtrack.PetBattleEvents.BattleEngaged()

	AreEqual(ST_PETBATTLES, played.tableName)
	AreEqual(SOUNDTRACK_PETBATTLES_PLAYERS .. "/Duelist", played.eventName)
end

function Tests:BattleEngaged_PlayerTargetNoTracks_PlaysPlayersFallback()
	local played = CapturePlayEvent()
	Replace(_G, "issecretvalue", function() return false end)

	SetupTarget("Duelist", true, true, false)
	Soundtrack.PetBattleEvents.BattleEngaged()

	AreEqual(ST_PETBATTLES, played.tableName)
	AreEqual(SOUNDTRACK_PETBATTLES_PLAYERS, played.eventName)
end

function Tests:BattleEngaged_PlayerTargetNotRegistered_PlaysPvpDuel()
	local played = CapturePlayEvent()
	Replace(_G, "issecretvalue", function() return false end)

	SetupTarget("Duelist", true, false, false)
	Soundtrack.PetBattleEvents.BattleEngaged()

	AreEqual(ST_PETBATTLES, played.tableName)
	AreEqual(SOUNDTRACK_PVP_DUEL, played.eventName)
end

function Tests:BattleEngaged_NpcTargetWithTracks_PlaysNamedNpcEvent()
	local played = CapturePlayEvent()
	Replace(_G, "issecretvalue", function() return false end)

	SetupTarget("Trainer", false, true, true)
	Soundtrack.PetBattleEvents.BattleEngaged()

	AreEqual(ST_PETBATTLES, played.tableName)
	AreEqual(SOUNDTRACK_PETBATTLES_NAMEDNPCS .. "/Trainer", played.eventName)
end

function Tests:BattleEngaged_NpcTargetNoTracks_PlaysNpcFallback()
	local played = CapturePlayEvent()
	Replace(_G, "issecretvalue", function() return false end)

	SetupTarget("Trainer", false, true, false)
	Soundtrack.PetBattleEvents.BattleEngaged()

	AreEqual(ST_PETBATTLES, played.tableName)
	AreEqual(SOUNDTRACK_PETBATTLES_NAMEDNPCS, played.eventName)
end

function Tests:BattleEngaged_NpcTargetNotRegistered_PlaysNpcBattle()
	local played = CapturePlayEvent()
	Replace(_G, "issecretvalue", function() return false end)

	SetupTarget("Trainer", false, false, false)
	Replace(C_Map, "GetBestMapForUnit", function() return 946 end)
	Replace(C_Map, "GetMapInfo", function(mapID)
		if mapID == 946 then
			return { parentMapID = 12 }
		elseif mapID == 12 then
			return { name = "Kalimdor" }
		end
		return { name = "TestZone" }
	end)
	Replace("C_PetBattles", {
		IsWildBattle = function() return false end,
		IsInBattle = function() return true end,
		GetPVPMatchmakingInfo = function() return false end
	})

	Soundtrack.PetBattleEvents.BattleEngaged()

	AreEqual(ST_PETBATTLES, played.tableName)
	AreEqual("Kalimdor " .. SOUNDTRACK_NPC_BATTLE, played.eventName)
end

function Tests:BattleEngaged_NoTarget_ZoneTextNil_ReturnsEarly()
	local played = CapturePlayEvent()
	Replace(_G, "issecretvalue", function() return false end)

	SetupTarget("Trainer", false, false, false)
	Replace(C_Map, "GetBestMapForUnit", function() return 946 end)
	Replace(C_Map, "GetMapInfo", function(mapID)
		if mapID == 946 then
			return { parentMapID = 12 }
		elseif mapID == 12 then
			return { name = nil }
		end
		return { name = nil }
	end)
	Replace("C_PetBattles", {
		IsWildBattle = function() return true end,
		IsInBattle = function() return true end,
		GetPVPMatchmakingInfo = function() return false end
	})

	Soundtrack.PetBattleEvents.BattleEngaged()

	IsTrue(played.eventName == nil, "No event played when zoneText is nil")
end

function Tests:CheckPlayerTarget_SecretName_FallsBackToWildBattle()
	local played = CapturePlayEvent()

	Replace(_G, "issecretvalue", function() return true end)
	Replace(_G, "UnitName", function() return "Secret" end)
	Replace(_G, "UnitIsPlayer", function() return true end)
	Replace(C_Map, "GetBestMapForUnit", function() return 946 end)
	Replace(C_Map, "GetMapInfo", function(mapID)
		if mapID == 946 then
			return { parentMapID = 12 }
		elseif mapID == 12 then
			return { name = "Kalimdor" }
		end
		return { name = "TestZone" }
	end)
	Replace("C_PetBattles", {
		IsWildBattle = function() return true end,
		IsInBattle = function() return true end,
		GetPVPMatchmakingInfo = function() return false end
	})

	Soundtrack.PetBattleEvents.GetPlayerTargetInfo()
	Soundtrack.PetBattleEvents.CheckPlayerTarget()
	Soundtrack.PetBattleEvents.BattleEngaged()

	AreEqual(ST_PETBATTLES, played.tableName)
	AreEqual("Kalimdor " .. SOUNDTRACK_WILD_BATTLE, played.eventName)
end

function Tests:Victory_StopsNpcLevelAndClearsTargetState()
	local stoppedLevel = nil
	Replace(Soundtrack, "StopEventAtLevel", function(level)
		stoppedLevel = level
	end)
	Replace(_G, "issecretvalue", function() return false end)
	Replace(C_Map, "GetBestMapForUnit", function() return 946 end)
	Replace(C_Map, "GetMapInfo", function(mapID)
		if mapID == 946 then
			return { parentMapID = 12 }
		elseif mapID == 12 then
			return { name = "Kalimdor" }
		end
		return { name = "TestZone" }
	end)
	Replace("C_PetBattles", {
		IsWildBattle = function() return false end,
		IsInBattle = function() return true end,
		GetPVPMatchmakingInfo = function() return false end
	})

	SetupTarget("Trainer", false, true, true)
	Soundtrack.PetBattleEvents.Victory()

	AreEqual(ST_NPC_LVL, stoppedLevel)

	local played = CapturePlayEvent()
	Replace(_G, "UnitExists", function() return false end)
	Soundtrack.PetBattleEvents.OnEvent(nil, "PLAYER_TARGET_CHANGED")
	Soundtrack.PetBattleEvents.BattleEngaged()

	AreEqual(ST_PETBATTLES, played.tableName)
	AreEqual("Kalimdor " .. SOUNDTRACK_NPC_BATTLE, played.eventName)
end

function Tests:Initialize_ContinentsNil_ReturnsEarly()
	Replace(C_Map, "GetMapChildrenInfo", function() return nil end)

	local eventTable = Soundtrack.Events.GetTable(ST_PETBATTLES)
	local initialCount = 0
	for _ in pairs(eventTable) do
		initialCount = initialCount + 1
	end

	Soundtrack.PetBattleEvents.Initialize()

	local finalCount = 0
	for _ in pairs(eventTable) do
		finalCount = finalCount + 1
	end

	AreEqual(initialCount + 3, finalCount)
end

function Tests:Initialize_AddsEventsForContinents()
	local added = {}
	Replace(Soundtrack, "AddEvent", function(tableName, eventName, priority, continuous)
		if tableName == ST_PETBATTLES then
			added[eventName] = { priority = priority, continuous = continuous }
		end
	end)
	Replace(C_Map, "GetMapChildrenInfo", function(_, _, _)
		return { { name = "Kalimdor" }, { name = "Eastern Kingdoms" } }
	end)

	Soundtrack.PetBattleEvents.Initialize()

	IsTrue(added["Kalimdor " .. SOUNDTRACK_WILD_BATTLE] ~= nil, "Wild battle added for continent")
	IsTrue(added["Kalimdor " .. SOUNDTRACK_NPC_BATTLE] ~= nil, "NPC battle added for continent")
	IsTrue(added["Eastern Kingdoms " .. SOUNDTRACK_WILD_BATTLE] ~= nil, "Wild battle added for second continent")
	IsTrue(added["Eastern Kingdoms " .. SOUNDTRACK_NPC_BATTLE] ~= nil, "NPC battle added for second continent")
end
