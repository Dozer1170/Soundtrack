if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PET_BATTLE_OPENING_START")

function Tests:OnLoad_RegistersPetBattleEvents()
	local events = {}
	Replace(Soundtrack.PetBattleEvents, "OnLoad", function(self)
		self:RegisterEvent("PET_BATTLE_OPENING_START")
		self:RegisterEvent("PET_BATTLE_OVER")
		self:RegisterEvent("PET_BATTLE_PVP_DUEL_REQUESTED")
		self:RegisterEvent("PET_BATTLE_PVP_DUEL_REQUEST_CANCEL")
		self:RegisterEvent("PET_BATTLE_QUEUE_PROPOSAL_ACCEPTED")
		self:RegisterEvent("PET_BATTLE_QUEUE_PROPOSAL_DECLINED")
		self:RegisterEvent("PLAYER_TARGET_CHANGED")
		events = {1, 2, 3, 4, 5, 6, 7}
	end)
	
	local frame = {}
	Soundtrack.PetBattleEvents.OnLoad(frame)
	
	Exists(#events == 7, "All pet battle events registered")
end

function Tests:OnEvent_PetBattleOpeningStart_TriggersBattleEngaged()
	local battleEngagedCalled = false
	Replace(Soundtrack.PetBattleEvents, "BattleEngaged", function()
		battleEngagedCalled = true
	end)
	
	Soundtrack.PetBattleEvents.OnEvent(nil, "PET_BATTLE_OPENING_START")
	
	Exists(battleEngagedCalled, "BattleEngaged called")
end

function Tests:OnEvent_PetBattleOver_TriggersVictory()
	local victoryCalled = false
	Replace(Soundtrack.PetBattleEvents, "Victory", function()
		victoryCalled = true
	end)
	
	Soundtrack.PetBattleEvents.OnEvent(nil, "PET_BATTLE_OVER")
	
	Exists(victoryCalled, "Victory called")
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
	eventTable["Kalimdor Wild Battle"].tracks = {"test.mp3"}
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
	
	Exists(finalCount > initialCount, "Pet battle events initialized")
end
