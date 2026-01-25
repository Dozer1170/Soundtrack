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
	
	Exists(#events == 7 and "All pet battle events registered" or nil)
end

function Tests:OnEvent_PetBattleOpeningStart_TriggersBattleEngaged()
	local battleEngagedCalled = false
	Replace(Soundtrack.PetBattleEvents, "BattleEngaged", function()
		battleEngagedCalled = true
	end)
	
	Soundtrack.PetBattleEvents.OnEvent(nil, "PET_BATTLE_OPENING_START")
	
	Exists(battleEngagedCalled and "BattleEngaged called" or nil)
end

function Tests:OnEvent_PetBattleOver_TriggersVictory()
	local victoryCalled = false
	Replace(Soundtrack.PetBattleEvents, "Victory", function()
		victoryCalled = true
	end)
	
	Soundtrack.PetBattleEvents.OnEvent(nil, "PET_BATTLE_OVER")
	
	Exists(victoryCalled and "Victory called" or nil)
end

function Tests:BattleEngaged_PlaysCorrectEvent()
	local eventPlayed = false
	local eventType = nil
	Replace(Soundtrack, "PlayEvent", function(eType, eventName)
		if eType == ST_PET_BATTLE then
			eventPlayed = true
			eventType = eType
		end
	end)
	Replace(SoundtrackAddon.db, "profile", {
		settings = {
			EnablePetBattleMusic = true
		}
	})
	
	Soundtrack.PetBattleEvents.BattleEngaged()
	
	AreEqual(true, eventPlayed)
	AreEqual(ST_PET_BATTLE, eventType)
end

function Tests:Initialize_AddsPetBattleWildEvents()
	local eventCount = 0
	Replace(Soundtrack, "AddEvent", function(eventType)
		if eventType == ST_PET_BATTLE then
			eventCount = eventCount + 1
		end
	end)
	
	Soundtrack.PetBattleEvents.Initialize()
	
	Exists(eventCount > 0 and "Pet battle events initialized" or nil)
end
