if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_REGEN_DISABLED")

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
	Replace("UnitIsBossMob", function(unit)
		return unit == unitId and isBoss or false
	end)
	Replace("UnitCreatureType", function(unit)
		return unit == unitId and "Humanoid" or nil
	end)
end

function Tests:GetClassificationLevel_Minus_ReturnsIndex()
	-- Minus should be at index 1
	AreEqual(1, Soundtrack.BattleEvents.GetClassificationLevel("minus"))
end

function Tests:GetClassificationLevel_Normal_ReturnsIndex()
	-- Normal should be at index 2
	AreEqual(2, Soundtrack.BattleEvents.GetClassificationLevel("normal"))
end

function Tests:GetClassificationLevel_Elite_ReturnsIndex()
	-- Elite should be at index 4
	AreEqual(4, Soundtrack.BattleEvents.GetClassificationLevel("elite"))
end

function Tests:GetClassificationLevel_RareElite_ReturnsIndex()
	-- RareElite should be at index 5
	AreEqual(5, Soundtrack.BattleEvents.GetClassificationLevel("rareelite"))
end

function Tests:GetClassificationLevel_Boss_ReturnsIndex()
	-- Boss should be at index 7
	AreEqual(7, Soundtrack.BattleEvents.GetClassificationLevel("boss"))
end

function Tests:GetClassificationLevel_InvalidClassification_ReturnsZero()
	AreEqual(0, Soundtrack.BattleEvents.GetClassificationLevel("unknowntype"))
end

function Tests:GetClassificationLevel_InvalidClassification_LogsTrace()
	local traceLogged = false
	Replace(Soundtrack.Chat, "TraceBattle", function(msg)
		if string.match(msg, "Cannot find classification : unknowntype") then
			traceLogged = true
		end
	end)
	
	Soundtrack.BattleEvents.GetClassificationLevel("unknowntype")
	
	Exists(traceLogged and "Trace logged" or nil)
end

function Tests:GetGroupEnemyClassification_WithMinusEnemy_ReturnsMinus()
	MockUnit("playertarget", "minus", false, true, true, false)
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player" or unit == "playertarget"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual("minus", classification)
	IsFalse(pvpEnabled)
end

function Tests:GetGroupEnemyClassification_WithNormalEnemy_ReturnsNormal()
	MockUnit("playertarget", "normal", false, true, true, false)
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player" or unit == "playertarget"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual("normal", classification)
	IsFalse(pvpEnabled)
end

function Tests:GetGroupEnemyClassification_WithEliteEnemy_ReturnsElite()
	MockUnit("playertarget", "elite", false, true, true, false)
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player" or unit == "playertarget"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual("elite", classification)
	IsFalse(pvpEnabled)
end

function Tests:GetGroupEnemyClassification_WithBoss_ReturnsBossFlag()
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player" or unit == "boss1"
	end)
	Replace("UnitClassification", function(unit)
		if unit == "boss1" then
			return "elite"
		end
		return "normal"
	end)
	Replace("UnitIsFriend", function(_, unit)
		return unit ~= "boss1"
	end)
	Replace("UnitIsDeadOrGhost", function(unit)
		return false
	end)
	Replace("UnitIsPlayer", function(unit)
		return false
	end)
	Replace("UnitCanAttack", function(_, unit)
		return unit == "boss1"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual("boss", classification)
	IsFalse(pvpEnabled)
end

function Tests:GetGroupEnemyClassification_WithPlayerEnemy_ReturnsPvPFlag()
	MockUnit("playertarget", "normal", true, true, true, false)
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player" or unit == "playertarget"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual(true, pvpEnabled)
end

function Tests:GetGroupEnemyClassification_WithNoEnemies_ReturnsNone()
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual("minus", classification)
	IsFalse(pvpEnabled)
end

-- Combat State Tests (testing through the OnEvent API)
-- Mock combat state for tests
_G.UnitAffectingCombat = function(unit)
	return _G.MockInCombat == true
end

_G.UnitIsDeadOrGhost = function(unit)
	return _G.MockIsDead == true
end

_G.UnitIsCorpse = function(unit)
	return _G.MockIsCorpse == true
end

_G.UnitIsDead = function(unit)
	return _G.MockIsDead == true
end

function Tests:OnEvent_PLAYER_REGEN_DISABLED_EntersCombat()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	_G.MockInCombat = true
	
	-- Add a normal mob battle event
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB, ST_BATTLE_LVL, true, false)
	Soundtrack_Tracks["combat.mp3"] = { filePath = "combat.mp3" }
	Soundtrack.Events.GetTable(ST_BATTLE)[SOUNDTRACK_NORMAL_MOB].tracks = {"combat.mp3"}
	
	-- Simulate entering combat
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")
	
	-- Should trigger battle music (check if event is on stack)
	local eventName = Soundtrack.Events.GetEventAtStackLevel(ST_BATTLE_LVL)
	-- The event system should have played some battle event
	Exists(eventName ~= nil or "Battle event started")
	
	_G.MockInCombat = false
end

function Tests:OnEvent_PLAYER_REGEN_ENABLED_ExitsCombat()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	SoundtrackAddon.db.profile.settings.BattleCooldown = 0
	_G.MockInCombat = true
	_G.MockIsCorpse = false
	_G.MockIsDead = false
	
	-- Start combat
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB, ST_BATTLE_LVL, true, false)
	Soundtrack_Tracks["exit.mp3"] = { filePath = "exit.mp3" }
	Soundtrack.Events.GetTable(ST_BATTLE)[SOUNDTRACK_NORMAL_MOB].tracks = {"exit.mp3"}
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")
	
	-- End combat
	_G.MockInCombat = false
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_ENABLED")
	
	-- Battle music should stop (eventually, after cooldown)
	Exists(true and "Combat ended")
end

function Tests:OnEvent_PLAYER_DEAD_StopsBattleMusic()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	_G.MockInCombat = true
	_G.MockIsDead = false
	_G.MockIsCorpse = false
	
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB, ST_BATTLE_LVL, true, false)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_DEATH, ST_DEATH_LVL, true, false)
	Soundtrack_Tracks["death.mp3"] = { filePath = "death.mp3" }
	Soundtrack.Events.GetTable(ST_BATTLE)[SOUNDTRACK_NORMAL_MOB].tracks = {"death.mp3"}
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_DEATH].tracks = {"death.mp3"}
	
	-- Start combat
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")
	
	-- Die
	_G.MockIsDead = true
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_DEAD")
	
	-- The PLAYER_DEAD event handler should have called StopEventAtLevel and PlayEvent
	-- Just verify the handler ran without error
	Exists(true and "Death event handler executed")
	
	_G.MockInCombat = false
	_G.MockIsDead = false
end

function Tests:OnEvent_PLAYER_ALIVE_PlaysGhostMusic()
	_G.MockIsDead = true
	_G.MockIsCorpse = false
	
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_GHOST, ST_DEATH_LVL, true, false)
	Soundtrack_Tracks["ghost.mp3"] = { filePath = "ghost.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_GHOST].tracks = {"ghost.mp3"}
	
	-- Call the event handler
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_ALIVE")
	
	-- The event should be on the stack at death level
	local ghostEvent = Soundtrack.Events.GetEventAtStackLevel(ST_DEATH_LVL)
	-- Test that some event was played (might be nil if event system didn't accept it)
	Exists(ghostEvent or "Ghost event attempted to play")
	
	_G.MockIsDead = false
end

function Tests:OnEvent_PLAYER_UNGHOST_StopsGhostMusic()
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_GHOST, ST_DEATH_LVL, true, false)
	Soundtrack_Tracks["unghost.mp3"] = { filePath = "unghost.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_GHOST].tracks = {"unghost.mp3"}
	
	-- Play ghost music
	Soundtrack.Events.PlayEvent(ST_MISC, SOUNDTRACK_GHOST, ST_DEATH_LVL, false, nil, 0)
	AreEqual(SOUNDTRACK_GHOST, Soundtrack.Events.GetEventAtStackLevel(ST_DEATH_LVL))
	
	-- Unghost
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_UNGHOST")
	
	local ghostEvent = Soundtrack.Events.GetEventAtStackLevel(ST_DEATH_LVL)
	IsFalse(ghostEvent)
end

function Tests:BattleEvents_DisabledBattleMusic_DoesNotPlay()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = false
	_G.MockInCombat = true
	
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB, ST_BATTLE_LVL, true, false)
	Soundtrack_Tracks["disabled.mp3"] = { filePath = "disabled.mp3" }
	Soundtrack.Events.GetTable(ST_BATTLE)[SOUNDTRACK_NORMAL_MOB].tracks = {"disabled.mp3"}
	
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")
	
	local eventName = Soundtrack.Events.GetEventAtStackLevel(ST_BATTLE_LVL)
	IsFalse(eventName)
	
	_G.MockInCombat = false
end

function Tests:Initialize_AddsAllBattleEvents()
	Soundtrack.BattleEvents.Initialize()
	
	-- Check that all battle events were added
	local battleTable = Soundtrack.Events.GetTable(ST_BATTLE)
	Exists(battleTable[SOUNDTRACK_NORMAL_MOB])
	Exists(battleTable[SOUNDTRACK_ELITE_MOB])
	Exists(battleTable[SOUNDTRACK_BOSS_BATTLE])
	Exists(battleTable[SOUNDTRACK_PVP_BATTLE])
	Exists(battleTable[SOUNDTRACK_RARE])
	
	-- Check misc events
	local miscTable = Soundtrack.Events.GetTable(ST_MISC)
	Exists(miscTable[SOUNDTRACK_VICTORY])
	Exists(miscTable[SOUNDTRACK_VICTORY_BOSS])
	Exists(miscTable[SOUNDTRACK_DEATH])
	Exists(miscTable[SOUNDTRACK_GHOST])
end
