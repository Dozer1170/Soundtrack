if not Tests then
	return
end

local Tests = Tests("Soundtrack", "PLAYER_REGEN_DISABLED")

local function ResetBattleState()
	Replace("UnitIsDeadOrGhost", function()
		return true
	end)
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_DEAD")
end

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
	AreEqual(1, Soundtrack.BattleEvents.GetClassificationLevel("minus"), "minus classification should be at index 1")
end

function Tests:GetClassificationLevel_Normal_ReturnsIndex()
	-- Normal should be at index 2
	AreEqual(2, Soundtrack.BattleEvents.GetClassificationLevel("normal"), "normal classification should be at index 2")
end

function Tests:GetClassificationLevel_Elite_ReturnsIndex()
	-- Elite should be at index 4
	AreEqual(4, Soundtrack.BattleEvents.GetClassificationLevel("elite"), "elite classification should be at index 4")
end

function Tests:GetClassificationLevel_RareElite_ReturnsIndex()
	-- RareElite should be at index 5
	AreEqual(5, Soundtrack.BattleEvents.GetClassificationLevel("rareelite"),
		"rareelite classification should be at index 5")
end

function Tests:GetClassificationLevel_Boss_ReturnsIndex()
	-- Boss should be at index 7
	AreEqual(7, Soundtrack.BattleEvents.GetClassificationLevel("boss"), "boss classification should be at index 7")
end

function Tests:GetClassificationLevel_InvalidClassification_ReturnsZero()
	AreEqual(0, Soundtrack.BattleEvents.GetClassificationLevel("unknowntype"), "unknown classification should return 0")
end

function Tests:GetClassificationLevel_InvalidClassification_LogsTrace()
	local traceLogged = false
	Replace(Soundtrack.Chat, "TraceBattle", function(msg)
		if string.match(msg, "Cannot find classification : unknowntype") then
			traceLogged = true
		end
	end)

	Soundtrack.BattleEvents.GetClassificationLevel("unknowntype")

	IsTrue(traceLogged, "trace should be logged for unknown classification")
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

	AreEqual("minus", classification, "minus enemy should return minus classification")
	IsFalse(pvpEnabled, "PvP should not be enabled for minus mob")
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

	AreEqual("normal", classification, "normal enemy should return normal classification")
	IsFalse(pvpEnabled, "PvP should not be enabled for normal mob")
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

	AreEqual("elite", classification, "elite enemy should return elite classification")
	IsFalse(pvpEnabled, "PvP should not be enabled for elite mob")
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

	AreEqual("boss", classification, "boss enemy should return boss classification")
	IsFalse(pvpEnabled, "PvP should not be enabled for boss mob")
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

	AreEqual(true, pvpEnabled, "PvP should be enabled for player enemy")
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

	AreEqual("minus", classification, "no enemies should return minus classification")
	IsFalse(pvpEnabled, "PvP should not be enabled with no enemies")
end

function Tests:GetGroupEnemyClassification_WithRaidMembersAndPets_SetsPvP()
	ResetBattleState()
	SoundtrackAddon.db.profile.settings.YourEnemyLevelOnly = false

	Replace("GetNumGroupMembers", function()
		return 2
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player"
			or unit == "pet"
			or unit == "raid1"
			or unit == "raid2"
			or unit == "raidpet1"
			or unit == "raid1target"
			or unit == "raid2target"
			or unit == "pettarget"
			or unit == "raidpet1target"
	end)
	Replace("UnitIsFriend", function(_, unit)
		return unit ~= "raid1target" and unit ~= "pettarget" and unit ~= "raidpet1target"
	end)
	Replace("UnitIsDeadOrGhost", function()
		return false
	end)
	Replace("UnitIsPlayer", function(unit)
		return unit == "raid1target"
	end)
	Replace("UnitCanAttack", function(_, unit)
		return unit == "raid1target"
	end)
	Replace("UnitClassification", function(unit)
		if unit == "raid1target" then
			return "elite"
		end
		return "normal"
	end)

	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()

	AreEqual("elite", classification, "elite raid member should be detected")
	IsTrue(pvpEnabled, "PvP should be enabled for enemy player targets")
end

-- Combat State Tests (testing through the OnEvent API)
-- Tests set _G.MockInCombat, _G.MockIsDead, and _G.MockIsCorpse to control behavior

function Tests:OnEvent_PLAYER_REGEN_DISABLED_EntersCombat()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	_G.MockInCombat = true

	-- Add a normal mob battle event
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB, ST_BATTLE_LVL, true, false)
	Soundtrack_Tracks["combat.mp3"] = { filePath = "combat.mp3" }
	Soundtrack.Events.GetTable(ST_BATTLE)[SOUNDTRACK_NORMAL_MOB].tracks = { "combat.mp3" }

	-- Simulate entering combat
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	-- Should trigger battle music (check if event is on stack)
	local eventName = Soundtrack.Events.GetEventAtStackLevel(ST_BATTLE_LVL)
	-- The event system should have played some battle event
	IsTrue(eventName ~= nil, "battle event should be started on combat entry")

	_G.MockInCombat = false
end

function Tests:OnEvent_PLAYER_REGEN_DISABLED_PvPBattlePlays()
	ResetBattleState()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	SoundtrackAddon.db.profile.settings.YourEnemyLevelOnly = false

	Replace("GetNumGroupMembers", function()
		return 1
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player" or unit == "raid1" or unit == "raid1target"
	end)
	Replace("UnitIsFriend", function(_, unit)
		return unit ~= "raid1target"
	end)
	Replace("UnitIsDeadOrGhost", function()
		return false
	end)
	Replace("UnitIsPlayer", function(unit)
		return unit == "raid1target"
	end)
	Replace("UnitCanAttack", function(_, unit)
		return unit == "raid1target"
	end)
	Replace("UnitClassification", function()
		return "normal"
	end)

	local played = {}
	Replace(Soundtrack, "PlayEvent", function(tableName, eventName)
		played.tableName = tableName
		played.eventName = eventName
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	AreEqual(ST_BATTLE, played.tableName)
	AreEqual(SOUNDTRACK_PVP_BATTLE, played.eventName)
end

function Tests:OnEvent_PLAYER_REGEN_DISABLED_BossBattlePlays()
	ResetBattleState()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	Replace(Soundtrack.BattleEvents, "GetGroupEnemyClassification", function()
		return "boss", false
	end)

	local played = {}
	Replace(Soundtrack, "PlayEvent", function(tableName, eventName)
		played.tableName = tableName
		played.eventName = eventName
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	AreEqual(ST_BATTLE, played.tableName)
	AreEqual(SOUNDTRACK_BOSS_BATTLE, played.eventName)
end

function Tests:OnEvent_PLAYER_REGEN_DISABLED_BossBattlePrefersBossZone()
	ResetBattleState()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	Replace(Soundtrack.BattleEvents, "GetGroupEnemyClassification", function()
		return "boss", false
	end)

	Replace(Soundtrack.ZoneEvents, "GetCurrentZonePaths", function()
		return { "Kalimdor/Onyxia's Lair" }
	end)

	Soundtrack.Events.GetTable(ST_BOSS_ZONES)["Kalimdor/Onyxia's Lair"] = { tracks = { "boss.mp3" } }

	local played = {}
	Replace(Soundtrack, "PlayEvent", function(tableName, eventName)
		played.tableName = tableName
		played.eventName = eventName
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	AreEqual(ST_BOSS_ZONES, played.tableName)
	AreEqual("Kalimdor/Onyxia's Lair", played.eventName)
end

function Tests:OnEvent_PLAYER_REGEN_DISABLED_RareBattlePlays()
	ResetBattleState()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	Replace(Soundtrack.BattleEvents, "GetGroupEnemyClassification", function()
		return "rare", false
	end)

	local played = {}
	Replace(Soundtrack, "PlayEvent", function(_, eventName)
		played.eventName = eventName
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	AreEqual(SOUNDTRACK_RARE, played.eventName)
end

function Tests:OnEvent_PLAYER_REGEN_DISABLED_EliteBattlePlays()
	ResetBattleState()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	Replace(Soundtrack.BattleEvents, "GetGroupEnemyClassification", function()
		return "elite", false
	end)

	local played = {}
	Replace(Soundtrack, "PlayEvent", function(_, eventName)
		played.eventName = eventName
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	AreEqual(SOUNDTRACK_ELITE_MOB, played.eventName)
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
	Soundtrack.Events.GetTable(ST_BATTLE)[SOUNDTRACK_NORMAL_MOB].tracks = { "exit.mp3" }
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	-- End combat
	_G.MockInCombat = false
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_ENABLED")

	-- Battle music should stop (eventually, after cooldown)
	local clearedEvent = Soundtrack.Events.GetEventAtStackLevel(ST_BATTLE_LVL)
	IsFalse(clearedEvent, "battle event should clear once combat ends")
end

function Tests:OnEvent_PLAYER_REGEN_ENABLED_SetsCooldownTimer()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	SoundtrackAddon.db.profile.settings.BattleCooldown = 5

	local timerSet = false
	Replace(Soundtrack.Timers, "AddTimer", function(name, duration, callback)
		if name == "BattleCooldown" and duration == 5 and type(callback) == "function" then
			timerSet = true
		end
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_ENABLED")

	IsTrue(timerSet, "Battle cooldown timer should be set")
end

function Tests:OnEvent_PLAYER_REGEN_ENABLED_VictoryBossSoundEffect()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	SoundtrackAddon.db.profile.settings.BattleCooldown = 0
	Replace("UnitIsDeadOrGhost", function() return false end)

	Soundtrack.Events.Stack[ST_BOSS_LVL].eventName = SOUNDTRACK_BOSS_BATTLE
	Soundtrack.Events.Stack[ST_BATTLE_LVL].eventName = nil
	Replace(Soundtrack, "GetEvent", function(_, eventName)
		if eventName == SOUNDTRACK_VICTORY_BOSS then
			return { soundEffect = true }
		end
		return nil
	end)

	local played = {}
	Replace(Soundtrack, "PlayEvent", function(_, eventName)
		played.eventName = eventName
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_ENABLED")

	AreEqual(SOUNDTRACK_VICTORY_BOSS, played.eventName)
end

function Tests:OnEvent_PLAYER_REGEN_ENABLED_VictoryBossNonSfx()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	SoundtrackAddon.db.profile.settings.BattleCooldown = 0
	Replace("UnitIsDeadOrGhost", function() return false end)

	Soundtrack.Events.Stack[ST_BOSS_LVL].eventName = SOUNDTRACK_BOSS_BATTLE
	Soundtrack.Events.Stack[ST_BATTLE_LVL].eventName = nil
	Replace(Soundtrack, "GetEvent", function(_, eventName)
		if eventName == SOUNDTRACK_VICTORY_BOSS then
			return { soundEffect = false }
		end
		return nil
	end)

	local playCount = 0
	local stopBattle = false
	local stopBoss = false
	Replace(Soundtrack, "PlayEvent", function(_, eventName)
		if eventName == SOUNDTRACK_VICTORY_BOSS then
			playCount = playCount + 1
		end
	end)
	Replace(Soundtrack, "StopEventAtLevel", function(level)
		if level == ST_BATTLE_LVL then
			stopBattle = true
		elseif level == ST_BOSS_LVL then
			stopBoss = true
		end
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_ENABLED")

	AreEqual(1, playCount)
	IsTrue(stopBattle, "battle level stopped")
	IsTrue(stopBoss, "boss level stopped")
end

function Tests:OnEvent_PLAYER_REGEN_ENABLED_VictoryNormalSoundEffect()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	SoundtrackAddon.db.profile.settings.BattleCooldown = 0
	Replace("UnitIsDeadOrGhost", function() return false end)

	Soundtrack.Events.Stack[ST_BOSS_LVL].eventName = nil
	Soundtrack.Events.Stack[ST_BATTLE_LVL].eventName = SOUNDTRACK_NORMAL_MOB
	Replace(Soundtrack, "GetEvent", function(_, eventName)
		if eventName == SOUNDTRACK_VICTORY then
			return { soundEffect = true }
		end
		return nil
	end)

	local played = {}
	Replace(Soundtrack, "PlayEvent", function(_, eventName)
		played.eventName = eventName
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_ENABLED")

	AreEqual(SOUNDTRACK_VICTORY, played.eventName)
end

function Tests:OnEvent_PLAYER_DEAD_StopsBattleMusic()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	_G.MockInCombat = true
	_G.MockIsDead = false
	_G.MockIsCorpse = false

	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB, ST_BATTLE_LVL, true, false)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_DEATH, ST_DEATH_LVL, true, false)
	Soundtrack_Tracks["death.mp3"] = { filePath = "death.mp3" }
	Soundtrack.Events.GetTable(ST_BATTLE)[SOUNDTRACK_NORMAL_MOB].tracks = { "death.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_DEATH].tracks = { "death.mp3" }

	-- Start combat
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	-- Die
	_G.MockIsDead = true
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_DEAD")

	-- The PLAYER_DEAD event handler should stop battle music and play the death event
	local stoppedBattle = Soundtrack.Events.GetEventAtStackLevel(ST_BATTLE_LVL)
	IsFalse(stoppedBattle, "battle event should stop when the player dies")
	local deathEventPlaying = Soundtrack.Events.GetEventAtStackLevel(ST_DEATH_LVL)
	AreEqual(SOUNDTRACK_DEATH, deathEventPlaying, "death music should be on the stack after PLAYER_DEAD")

	_G.MockInCombat = false
	_G.MockIsDead = false
end

function Tests:OnEvent_PLAYER_ALIVE_PlaysGhostMusic()
	_G.MockIsDead = true
	_G.MockIsCorpse = false

	local ghostEventPlayed = false
	local originalPlayEvent = Soundtrack.PlayEvent

	Soundtrack.PlayEvent = function(tableName, eventName)
		if eventName == SOUNDTRACK_GHOST then
			ghostEventPlayed = true
		end
		-- Call original if it exists
		if originalPlayEvent then
			return originalPlayEvent(tableName, eventName)
		end
	end

	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_GHOST, ST_DEATH_LVL, true, false)
	Soundtrack_Tracks["ghost.mp3"] = { filePath = "ghost.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_GHOST].tracks = { "ghost.mp3" }

	-- Call the event handler - this should attempt to play ghost music
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_ALIVE")

	-- Verify ghost music was played
	IsTrue(ghostEventPlayed, "ghost music should play when player is dead/ghost")

	-- Restore
	Soundtrack.PlayEvent = originalPlayEvent
	_G.MockIsDead = false
end

function Tests:OnEvent_PLAYER_UNGHOST_StopsGhostMusic()
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_GHOST, ST_DEATH_LVL, true, false)
	Soundtrack_Tracks["unghost.mp3"] = { filePath = "unghost.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_GHOST].tracks = { "unghost.mp3" }

	-- Play ghost music
	Soundtrack.Events.PlayEvent(ST_MISC, SOUNDTRACK_GHOST, ST_DEATH_LVL, false, nil, 0)
	AreEqual(SOUNDTRACK_GHOST, Soundtrack.Events.GetEventAtStackLevel(ST_DEATH_LVL), "ghost event should be playing")

	-- Unghost
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_UNGHOST")

	local ghostEvent = Soundtrack.Events.GetEventAtStackLevel(ST_DEATH_LVL)
	IsFalse(ghostEvent, "ghost event should stop on unghost")
end

function Tests:OnEvent_ZONE_CHANGED_NEW_AREA_Traces()
	local traced = false
	Replace(Soundtrack.Chat, "TraceBattle", function(msg)
		if msg == "ZONE_CHANGED_NEW_AREA" then
			traced = true
		end
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "ZONE_CHANGED_NEW_AREA")

	IsTrue(traced, "zone change should trace")
end

function Tests:BattleEvents_DisabledBattleMusic_DoesNotPlay()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = false
	_G.MockInCombat = true

	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB, ST_BATTLE_LVL, true, false)
	Soundtrack_Tracks["disabled.mp3"] = { filePath = "disabled.mp3" }
	Soundtrack.Events.GetTable(ST_BATTLE)[SOUNDTRACK_NORMAL_MOB].tracks = { "disabled.mp3" }

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	local eventName = Soundtrack.Events.GetEventAtStackLevel(ST_BATTLE_LVL)
	IsFalse(eventName, "battle music should not play when disabled")

	_G.MockInCombat = false
end

function Tests:OnEvent_PLAYER_REGEN_ENABLED_PlayerAlive_TriggersVictory()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	SoundtrackAddon.db.profile.settings.BattleCooldown = 0
	_G.MockInCombat = true
	_G.MockIsCorpse = false
	_G.MockIsDead = false

	-- Mock PlayEvent and StopEventAtLevel to capture what events are played/stopped
	local victoryEventPlayed = false
	local battleLevelStopped = false
	local bossLevelStopped = false

	Replace(Soundtrack, "PlayEvent", function(eventTable, eventName, stackLevel, continuous, offset, fadeTime)
		if eventName == SOUNDTRACK_VICTORY or eventName == SOUNDTRACK_VICTORY_BOSS then
			victoryEventPlayed = true
		end
	end)

	Replace(Soundtrack, "StopEventAtLevel", function(level)
		if level == ST_BATTLE_LVL then
			battleLevelStopped = true
		elseif level == ST_BOSS_LVL then
			bossLevelStopped = true
		end
	end)

	-- Add battle and victory events
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB, ST_BATTLE_LVL, true, false)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_VICTORY, ST_BATTLE_LVL, true, false)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_VICTORY_BOSS, ST_BOSS_LVL, true, false)
	Soundtrack_Tracks["combat.mp3"] = { filePath = "combat.mp3" }
	Soundtrack_Tracks["victory.mp3"] = { filePath = "victory.mp3" }
	Soundtrack_Tracks["victoryboss.mp3"] = { filePath = "victoryboss.mp3" }
	Soundtrack.Events.GetTable(ST_BATTLE)[SOUNDTRACK_NORMAL_MOB].tracks = { "combat.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_VICTORY].tracks = { "victory.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_VICTORY_BOSS].tracks = { "victoryboss.mp3" }

	-- Manually set up the stack to simulate battle music playing
	Soundtrack.Events.Stack[ST_BATTLE_LVL] = {
		eventName = SOUNDTRACK_NORMAL_MOB,
		tableName = ST_BATTLE
	}

	-- Start combat
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	-- End combat while player is alive
	_G.MockInCombat = false
	_G.MockIsDead = false
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_ENABLED")

	-- Victory music should play and battle levels should stop
	AreEqual(true, victoryEventPlayed, "victory music should play when player survives combat")
	AreEqual(true, battleLevelStopped, "battle level should be stopped")
	AreEqual(true, bossLevelStopped, "boss level should be stopped")
end

function Tests:OnEvent_PLAYER_REGEN_ENABLED_NoBattleEvent_StopsLevelsWithoutVictory()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	SoundtrackAddon.db.profile.settings.BattleCooldown = 0
	_G.MockInCombat = true
	_G.MockIsCorpse = false
	_G.MockIsDead = false

	-- Track what gets called
	local victoryEventPlayed = false
	local battleLevelStopped = false
	local bossLevelStopped = false

	Replace(Soundtrack, "PlayEvent", function(eventTable, eventName, stackLevel, continuous, offset, fadeTime)
		if eventName == SOUNDTRACK_VICTORY or eventName == SOUNDTRACK_VICTORY_BOSS then
			victoryEventPlayed = true
		end
	end)

	Replace(Soundtrack, "StopEventAtLevel", function(level)
		if level == ST_BATTLE_LVL then
			battleLevelStopped = true
		elseif level == ST_BOSS_LVL then
			bossLevelStopped = true
		end
	end)

	-- Add victory events
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_VICTORY, ST_BATTLE_LVL, true, false)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_VICTORY_BOSS, ST_BOSS_LVL, true, false)
	Soundtrack_Tracks["victory.mp3"] = { filePath = "victory.mp3" }
	Soundtrack_Tracks["victoryboss.mp3"] = { filePath = "victoryboss.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_VICTORY].tracks = { "victory.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_VICTORY_BOSS].tracks = { "victoryboss.mp3" }

	-- Stack is empty - no battle music was playing (initialize as empty tables, not nil)
	Soundtrack.Events.Stack[ST_BATTLE_LVL] = {}
	Soundtrack.Events.Stack[ST_BOSS_LVL] = {}

	-- End combat without battle event
	_G.MockInCombat = false
	_G.MockIsDead = false
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_ENABLED")

	-- No victory music should play, but levels should stop
	IsFalse(victoryEventPlayed, "victory should not play when no battle event on stack")
	AreEqual(true, battleLevelStopped, "battle level should be stopped")
	AreEqual(true, bossLevelStopped, "boss level should be stopped")
end

function Tests:OnEvent_PLAYER_REGEN_ENABLED_PlayerDead_StopsLevelsWithoutVictory()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	SoundtrackAddon.db.profile.settings.BattleCooldown = 0
	_G.MockInCombat = true
	_G.MockIsCorpse = false
	_G.MockIsDead = true

	-- Mock PlayEvent and StopEventAtLevel to capture what events are played/stopped
	local victoryEventPlayed = false
	local battleLevelStopped = false
	local bossLevelStopped = false
	local unitIsDeadOrGhostCalled = false

	-- Track if UnitIsDeadOrGhost is called
	Replace(_G, "UnitIsDeadOrGhost", function(unit)
		unitIsDeadOrGhostCalled = true
		return _G.MockIsDead or _G.MockIsCorpse or false
	end)

	Replace(Soundtrack, "PlayEvent", function(eventTable, eventName, stackLevel, continuous, offset, fadeTime)
		if eventName == SOUNDTRACK_VICTORY or eventName == SOUNDTRACK_VICTORY_BOSS then
			victoryEventPlayed = true
		end
	end)

	Replace(Soundtrack, "StopEventAtLevel", function(level)
		if level == ST_BATTLE_LVL then
			battleLevelStopped = true
		elseif level == ST_BOSS_LVL then
			bossLevelStopped = true
		end
	end)

	-- Add battle and victory events
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB, ST_BATTLE_LVL, true, false)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_VICTORY, ST_BATTLE_LVL, true, false)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_VICTORY_BOSS, ST_BOSS_LVL, true, false)
	Soundtrack_Tracks["combat.mp3"] = { filePath = "combat.mp3" }
	Soundtrack_Tracks["victory.mp3"] = { filePath = "victory.mp3" }
	Soundtrack_Tracks["victoryboss.mp3"] = { filePath = "victoryboss.mp3" }
	Soundtrack.Events.GetTable(ST_BATTLE)[SOUNDTRACK_NORMAL_MOB].tracks = { "combat.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_VICTORY].tracks = { "victory.mp3" }
	Soundtrack.Events.GetTable(ST_MISC)[SOUNDTRACK_VICTORY_BOSS].tracks = { "victoryboss.mp3" }

	-- Manually set up the stack to simulate battle music playing
	Soundtrack.Events.Stack[ST_BATTLE_LVL] = {
		eventName = SOUNDTRACK_NORMAL_MOB,
		tableName = ST_BATTLE
	}

	-- Start combat
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	-- End combat while player is DEAD (keep MockIsDead = true)
	_G.MockInCombat = false
	-- MockIsDead stays true - player is dead
	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_ENABLED")

	-- Victory music should NOT play because player is dead, but levels should stop
	IsTrue(unitIsDeadOrGhostCalled, "UnitIsDeadOrGhost should be called")
	IsTrue(battleLevelStopped, "battle level should be stopped")
	IsTrue(bossLevelStopped, "boss level should be stopped")
	IsFalse(victoryEventPlayed, "victory should not play when player is dead")
end

function Tests:Initialize_AddsAllBattleEvents()
	Soundtrack.BattleEvents.Initialize()

	-- Check that all battle events were added
	local battleTable = Soundtrack.Events.GetTable(ST_BATTLE)
	IsTrue(battleTable[SOUNDTRACK_NORMAL_MOB], "normal mob battle event should exist")
	IsTrue(battleTable[SOUNDTRACK_ELITE_MOB], "elite mob battle event should exist")
	IsTrue(battleTable[SOUNDTRACK_BOSS_BATTLE], "boss battle event should exist")
	IsTrue(battleTable[SOUNDTRACK_PVP_BATTLE], "PvP battle event should exist")
	IsTrue(battleTable[SOUNDTRACK_RARE], "rare mob battle event should exist")

	-- Check misc events
	local miscTable = Soundtrack.Events.GetTable(ST_MISC)
	IsTrue(miscTable[SOUNDTRACK_VICTORY], "victory event should exist")
	IsTrue(miscTable[SOUNDTRACK_VICTORY_BOSS], "boss victory event should exist")
	IsTrue(miscTable[SOUNDTRACK_DEATH], "death event should exist")
	IsTrue(miscTable[SOUNDTRACK_GHOST], "ghost event should exist")
end

function Tests:OnEvent_PLAYER_ALIVE_StopsGhostMusic()
	Replace("UnitIsDeadOrGhost", function() return false end)

	local stopped = {}
	Replace(Soundtrack, "StopEvent", function(_, eventName)
		stopped.eventName = eventName
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_ALIVE")

	AreEqual(SOUNDTRACK_GHOST, stopped.eventName)
end

function Tests:BattleEvents_OnLoad_RegistersEvents()
	local events = {}
	local frame = {
		RegisterEvent = function(_, eventName)
			table.insert(events, eventName)
		end,
	}

	Soundtrack.BattleEvents.OnLoad(frame)

	AreEqual(6, #events)
	IsTrue(events[1] == "PLAYER_REGEN_DISABLED")
	IsTrue(events[2] == "PLAYER_REGEN_ENABLED")
	IsTrue(events[3] == "PLAYER_UNGHOST")
	IsTrue(events[4] == "PLAYER_ALIVE")
	IsTrue(events[5] == "PLAYER_DEAD")
	IsTrue(events[6] == "ZONE_CHANGED_NEW_AREA")
end

function Tests:BattleEvents_OnUpdate_ReanalyzesBattle()
	ResetBattleState()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	local classificationCalls = 0
	Replace(Soundtrack.BattleEvents, "GetGroupEnemyClassification", function()
		classificationCalls = classificationCalls + 1
		return "normal", false
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")
	classificationCalls = 0

	for i = 1, 10 do
		local name = debug.getupvalue(Soundtrack.BattleEvents.OnUpdate, i)
		if name == "currentBattleTypeIndex" then
			debug.setupvalue(Soundtrack.BattleEvents.OnUpdate, i, 1)
		elseif name == "nextUpdateTime" then
			debug.setupvalue(Soundtrack.BattleEvents.OnUpdate, i, 0)
		end
	end

	Replace("GetTime", function() return 10 end)
	Soundtrack.BattleEvents.OnUpdate()

	IsTrue(classificationCalls > 0, "Battle analysis should run on update when active")
end

function Tests:BattleEvents_GetBattleType_InvalidBattle()
	ResetBattleState()
	Replace(Soundtrack.BattleEvents, "GetGroupEnemyClassification", function()
		return "unknown", false
	end)

	local battleType = nil
	Replace(Soundtrack, "PlayEvent", function(_, eventName)
		battleType = eventName
	end)

	Soundtrack.BattleEvents.OnEvent(nil, "PLAYER_REGEN_DISABLED")

	AreEqual("InvalidBattle", battleType)
end
