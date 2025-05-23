--[[
    Soundtrack addon for World of Warcraft

    Battle events functions.
    Functions that manage battle situation changes.
]]

Soundtrack.BattleEvents = {}

local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23

-- Classifications for mobs
local classifications = {
	"Critter",
	"normal",
	"rare",
	"elite",
	"rareelite",
	"worldboss",
}

-- Difficulties for mobs
local difficulties = {
	"Unknown", -- Attacked
	"1 Trivial", -- gray
	"2 Easy", -- green
	"3 Normal", -- yellow
	"4 Tough", -- orange
	"5 Impossible", -- red
}

-- Initialize difficulties only once. Prevents de-escalations during combat. -Gotest
local highestlevel = 1
local highestDifficulty = 1
local highestClassification = 1

-- Battle event priority for mob types
local battleEvents = {
	SOUNDTRACK_UNKNOWN_BATTLE,
	SOUNDTRACK_CRITTER,
	SOUNDTRACK_NORMAL_MOB,
	SOUNDTRACK_ELITE_MOB,
	SOUNDTRACK_NORMAL_MOB .. "/1 Trivial", -- Gray
	SOUNDTRACK_ELITE_MOB .. "/1 Trivial", -- Gray
	SOUNDTRACK_NORMAL_MOB .. "/2 Easy", -- Green
	SOUNDTRACK_ELITE_MOB .. "/2 Easy", -- Green
	SOUNDTRACK_NORMAL_MOB .. "/3 Normal", -- Yellow
	SOUNDTRACK_ELITE_MOB .. "/3 Normal", -- Yellow
	SOUNDTRACK_NORMAL_MOB .. "/4 Tough", -- Orange
	SOUNDTRACK_ELITE_MOB .. "/4 Tough", -- Orange
	SOUNDTRACK_NORMAL_MOB .. "/5 Impossible", -- Red
	SOUNDTRACK_ELITE_MOB .. "/5 Impossible", -- Red
	SOUNDTRACK_RARE,
	SOUNDTRACK_BOSS_BATTLE,
	SOUNDTRACK_WORLD_BOSS_BATTLE,
	SOUNDTRACK_PVP_BATTLE,
}

-- Figures out mob difficulty from text
local function GetDifficultyFromText(difficultyText)
	for i, d in ipairs(difficulties) do
		if d == difficultyText then
			return i
		end
	end
	Soundtrack.Chat.TraceBattle("Cannot find difficulty : " .. difficultyText)
	return 0
end

-- Returns a classification number. Used to compare classifications
local function GetClassificationLevel(classificationText)
	for i, c in ipairs(classifications) do
		if c == classificationText then
			return i
		end
	end
	Soundtrack.Chat.TraceBattle("Cannot find classification : " .. classificationText)
	return 0
end

-- Gets difficulty text from difficulty level
local function GetDifficultyText(difficultyLevel)
	return difficulties[difficultyLevel]
end

-- Gets classification text from clasification level
local function GetClassificationText(classificationLevel)
	return classifications[classificationLevel]
end

-- Returns the difficulty of a target based on the level of the mob,
-- compared to the players level. (also known as the color of the mob).
local function GetDifficulty(target, targetLevel)
	local playerLevel = UnitLevel("player")
	local levelDiff = targetLevel - playerLevel
	if UnitIsTrivial(target) then
		return GetDifficultyFromText("1 Trivial")
	elseif
		(
			GetQuestDifficultyColor(targetLevel).r == 1
			and GetQuestDifficultyColor(targetLevel).g == 0.1
			and GetQuestDifficultyColor(targetLevel).b == 0.1
		)
		or targetLevel == -1
		or targetLevel >= playerLevel + 10
	then
		return GetDifficultyFromText("5 Impossible")
	elseif
		(
			GetQuestDifficultyColor(targetLevel).r == 1
			and GetQuestDifficultyColor(targetLevel).g == 0.5
			and GetQuestDifficultyColor(targetLevel).b == 0.25
		) or (levelDiff >= 5 and levelDiff <= 10)
	then
		return GetDifficultyFromText("4 Tough")
	elseif
		(
			GetQuestDifficultyColor(targetLevel).r == 1
			and GetQuestDifficultyColor(targetLevel).g == 0.82
			and GetQuestDifficultyColor(targetLevel).b == 0
		) or (levelDiff >= -3 and levelDiff <= 4)
	then
		return GetDifficultyFromText("3 Normal")
	else
		return GetDifficultyFromText("2 Easy")
	end
end

-- Calculates the highest enemy level amongs all the party members and pet
-- targets. Thanks to Athame!
-- Returns classification, difficulty, pvpEnabled
function GetGroupEnemyLevel()
	local prefix
	local total
	if GetNumGroupMembers() > 0 then
		prefix = "raid"
		total = GetNumGroupMembers()
	else
		prefix = "party"
		total = GetNumSubgroupMembers()
	end

	-- create table of units
	local units = {}

	-- add you!
	table.insert(units, "player")

	-- add your party/raid members
	if not SoundtrackAddon.db.profile.settings.YourEnemyLevelOnly then
		if total > 0 then
			for index = 1, total do
				table.insert(units, prefix .. index)
			end
		end
	end

	-- add your pet
	if UnitExists("pet") then
		table.insert(units, "pet")
	end

	-- add your party/raid pets
	if not SoundtrackAddon.db.profile.settings.YourEnemyLevelOnly then
		for index = 0, total do
			if UnitExists(prefix .. "pet" .. index) then
				table.insert(units, prefix .. "pet" .. index)
			end
		end
	end

	-- local highestlevel = 1
	-- local highestDifficulty = 1
	-- local highestClassification = 1
	local pvpEnabled = false
	local isBoss = false
	local bossName = nil
	local hasLowHealth = false

	local bossTable = Soundtrack.Events.GetTable(ST_BOSS)

	for _, unit in ipairs(units) do
		local target = unit .. "target"
		local unitExists = UnitExists(target)
		local unitIsEnemy = not UnitIsFriend("player", target)
		local unitIsAlive = not UnitIsDeadOrGhost(target)

		if unitExists and unitIsEnemy and unitIsAlive then
			local unitName = UnitName(target)
			local unitHealthPercent = UnitHealth(target) / UnitHealthMax(target)
			local unitIsPlayer = UnitIsPlayer(target)
			local unitCanAttack = UnitCanAttack("player", target)
			local targetlevel = UnitLevel(target)
			local unitCreatureType = UnitCreatureType(target)
			local unitClass = UnitClassification(target)

			-- Check for pvp
			if not pvpEnabled then
				pvpEnabled = unitIsPlayer and unitCanAttack
			end

			-- Get the target level
			if targetlevel then
				if targetlevel == -1 then
					targetlevel = UnitLevel("player") + 10 -- at least 10 levels higher
				end
				if targetlevel > highestlevel then
					highestlevel = targetlevel -- this unit has the highest living hostile target so far
				end
			end

			-- Get target difficulty from level
			local difficultyLevel = GetDifficulty(target, targetlevel)
			if difficultyLevel > highestDifficulty then
				highestDifficulty = difficultyLevel
			end

			-- Get the target classification
			if unitCreatureType == "Critter" then
				unitClass = unitCreatureType
			else
				if
					unitClass == "worldboss"
					and unitHealthPercent < SoundtrackAddon.db.profile.settings.LowHealthPercent
				then
					hasLowHealth = true
				end
			end

			local classificationLevel = GetClassificationLevel(unitClass)
			if classificationLevel > highestClassification then
				highestClassification = classificationLevel
			end

			-- Check if in the boss table
			if bossTable then
				local bossEvent = bossTable[unitName]
				if bossEvent then
					Soundtrack.Chat.TraceBattle(unitName .. " is a boss.")
					isBoss = true
					if Soundtrack.Events.EventHasTracks(ST_BOSS, unitName) then
						bossName = unitName
					end
					if unitHealthPercent < SoundtrackAddon.db.profile.settings.LowHealthPercent then
						hasLowHealth = true
					end
					if bossEvent.worldboss then
						unitClass = "worldboss"
					end
				end
			end
		end
	end

	local classificationText = GetClassificationText(highestClassification)
	local difficultyText = GetDifficultyText(highestDifficulty)
	return classificationText, difficultyText, pvpEnabled, isBoss, bossName, hasLowHealth
end

-- When the player is engaged in battle, this determines
-- the type of battle.
local function GetBattleType()
	local classification, difficulty, pvpEnabled, isBoss, bossName, hasLowHealth = GetGroupEnemyLevel()
	if pvpEnabled then
		return SOUNDTRACK_PVP_BATTLE
	else
		if difficulty == "Unknown" then
			return SOUNDTRACK_UNKNOWN_BATTLE
		end

		if isBoss then -- Boss or World Boss
			if classification == "worldboss" then
				return SOUNDTRACK_WORLD_BOSS_BATTLE, bossName, hasLowHealth -- World Boss( raid)
			else
				return SOUNDTRACK_BOSS_BATTLE, bossName, hasLowHealth -- Boss (party)
			end
		end

		if classification == "rareelite" or classification == "rare" then
			return SOUNDTRACK_RARE -- Rare mob
		end

		if classification == "elite" then -- Elite mob
			local EliteMobDifficulty = SOUNDTRACK_ELITE_MOB .. "/" .. difficulty
			local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
			if #eventTable[EliteMobDifficulty].tracks ~= 0 then
				return EliteMobDifficulty -- Elite mob difficulty
			else
				return SOUNDTRACK_ELITE_MOB -- default to Elite mob w/o difficulty
			end
		end

		if classification == "normal" then -- Normal mob
			local NormalMobDifficulty = SOUNDTRACK_NORMAL_MOB .. "/" .. difficulty
			local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
			if #eventTable[NormalMobDifficulty].tracks ~= 0 then
				return NormalMobDifficulty -- Normal mob difficulty
			else
				return SOUNDTRACK_NORMAL_MOB -- default to Normal mob w/o difficulty
			end
		end

		if classification == "Critter" then -- Critter
			return SOUNDTRACK_CRITTER
		end
	end

	return "InvalidBattle"
end

local hostileDeathCount = 0
local currentBattleTypeIndex = 0 -- Used to determine battle priorities and escalations
local function StartVictoryMusic()
	if SoundtrackAddon.db.profile.settings.EnableBattleMusic then
		if hostileDeathCount > 0 then
			local battleEventName = Soundtrack.Events.Stack[ST_BATTLE_LVL].eventName
			local bossEventName = Soundtrack.Events.Stack[ST_BOSS_LVL].eventName
			if bossEventName ~= nil then
				local victoryEvent = Soundtrack.GetEvent(ST_MISC, SOUNDTRACK_VICTORY_BOSS)
				if victoryEvent.soundEffect == true then
					Soundtrack.PlayEvent(ST_MISC, SOUNDTRACK_VICTORY_BOSS)
					Soundtrack.StopEventAtLevel(ST_BATTLE_LVL)
					Soundtrack.StopEventAtLevel(ST_BOSS_LVL)
				else
					Soundtrack.StopEventAtLevel(ST_BATTLE_LVL)
					Soundtrack.StopEventAtLevel(ST_BOSS_LVL)
					Soundtrack.PlayEvent(ST_MISC, SOUNDTRACK_VICTORY_BOSS)
				end
			elseif battleEventName ~= SOUNDTRACK_CRITTER and battleEventName ~= SOUNDTRACK_UNKNOWN_BATTLE then
				local victoryEvent = Soundtrack.GetEvent(ST_MISC, SOUNDTRACK_VICTORY)
				if victoryEvent.soundEffect == true then
					Soundtrack.PlayEvent(ST_MISC, SOUNDTRACK_VICTORY)
					Soundtrack.StopEventAtLevel(ST_BATTLE_LVL)
					Soundtrack.StopEventAtLevel(ST_BOSS_LVL)
				else
					Soundtrack.StopEventAtLevel(ST_BATTLE_LVL)
					Soundtrack.StopEventAtLevel(ST_BOSS_LVL)
					Soundtrack.PlayEvent(ST_MISC, SOUNDTRACK_VICTORY)
				end
			else
				Soundtrack.StopEventAtLevel(ST_BATTLE_LVL)
				Soundtrack.StopEventAtLevel(ST_BOSS_LVL)
			end
		else
			Soundtrack.StopEventAtLevel(ST_BATTLE_LVL)
			Soundtrack.StopEventAtLevel(ST_BOSS_LVL)
		end
	end
	hostileDeathCount = 0
end

local function StopCombatMusic()
	Soundtrack.Chat.TraceBattle("Stop Combat Music")
	StartVictoryMusic()
	currentBattleTypeIndex = 0 -- we are out of battle
	--Reset difficulties outside of combat. -Gotest
	highestlevel = 1
	highestDifficulty = 1
	highestClassification = 1
end

local function AnalyzeBattleSituation()
	local battleType, bossName, hasLowHealth = GetBattleType()
	local battleTypeIndex = IndexOf(battleEvents, battleType)

	-- If we're in cooldown, but a higher battle is already playing, keep that one,
	-- otherwise we can escalate the battle music.
	-- If we are out of combat, we play the battle event.
	-- If we are in combat, we only escalate if option is turned on
	if
		currentBattleTypeIndex == 0
		or battleType == SOUNDTRACK_BOSS_BATTLE
		or battleType == SOUNDTRACK_WORLD_BOSS_BATTLE
		or (SoundtrackAddon.db.profile.settings.EscalateBattleMusic and battleTypeIndex > currentBattleTypeIndex)
	then
		if battleType == SOUNDTRACK_BOSS_BATTLE then
			if bossName ~= nil then
				local bossLowHealth = bossName .. " " .. SOUNDTRACK_LOW_HEALTH
				if hasLowHealth and Soundtrack.Events.EventHasTracks(ST_BOSS, bossLowHealth) then
					Soundtrack.PlayEvent(ST_BOSS, bossLowHealth)
				elseif hasLowHealth and Soundtrack.Events.EventHasTracks(ST_BATTLE, SOUNDTRACK_BOSS_LOW_HEALTH) then
					Soundtrack.PlayEvent(ST_BATTLE, SOUNDTRACK_BOSS_LOW_HEALTH)
				elseif Soundtrack.Events.EventHasTracks(ST_BOSS, bossName) then
					Soundtrack.PlayEvent(ST_BOSS, bossName)
				else
					Soundtrack.PlayEvent(ST_BATTLE, battleType)
				end
			else
				if hasLowHealth and Soundtrack.Events.EventHasTracks(ST_BATTLE, SOUNDTRACK_BOSS_LOW_HEALTH) then
					Soundtrack.PlayEvent(ST_BATTLE, SOUNDTRACK_BOSS_LOW_HEALTH)
				else
					Soundtrack.PlayEvent(ST_BATTLE, battleType)
				end
			end
		elseif battleType == SOUNDTRACK_WORLD_BOSS_BATTLE then
			if bossName ~= nil then
				local bossLowHealth = bossName .. " " .. SOUNDTRACK_LOW_HEALTH
				if hasLowHealth and Soundtrack.Events.EventHasTracks(ST_BOSS, bossLowHealth) then
					Soundtrack.PlayEvent(ST_BOSS, bossLowHealth)
				elseif
					hasLowHealth and Soundtrack.Events.EventHasTracks(ST_BATTLE, SOUNDTRACK_WORLD_BOSS_LOW_HEALTH)
				then
					Soundtrack.PlayEvent(ST_BATTLE, SOUNDTRACK_WORLD_BOSS_LOW_HEALTH)
				elseif Soundtrack.Events.EventHasTracks(ST_BOSS, bossName) then
					Soundtrack.PlayEvent(ST_BOSS, bossName)
				else
					Soundtrack.PlayEvent(ST_BATTLE, battleType)
				end
			else
				if hasLowHealth and Soundtrack.Events.EventHasTracks(ST_BATTLE, SOUNDTRACK_WORLD_BOSS_LOW_HEALTH) then
					Soundtrack.PlayEvent(ST_BATTLE, SOUNDTRACK_WORLD_BOSS_LOW_HEALTH)
				else
					Soundtrack.PlayEvent(ST_BATTLE, battleType)
				end
			end
		else
			Soundtrack.PlayEvent(ST_BATTLE, battleType)
		end
	end
	currentBattleTypeIndex = battleTypeIndex
end

-- True when a battle event is currently playing
Soundtrack.BattleEvents.Stealthed = false

function Soundtrack.BattleEvents.OnLoad(self)
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
	self:RegisterEvent("PLAYER_UNGHOST")
	self:RegisterEvent("PLAYER_ALIVE")
	self:RegisterEvent("PLAYER_DEAD")
	self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
	self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
end

local nextUpdateTime = 0
local updateInterval = 0.2

function Soundtrack.BattleEvents.OnUpdate(_, _)
	local currentTime = GetTime()

	if currentBattleTypeIndex > 0 then
		if currentTime > nextUpdateTime then
			nextUpdateTime = currentTime + updateInterval
			AnalyzeBattleSituation()
		end
	end
end

function Soundtrack.BattleEvents.OnEvent(_, event, ...)
	_, arg2, _, _, arg5, _, _, _, _, _, _, _, _, _, _, _, _, arg18, _, _, arg21, _, _ = select(1, ...)

	local _, eventType, _, _, _, _, _, _ = CombatLogGetCurrentEventInfo() --CSCIGUY 8-10-18

	if event == "PLAYER_REGEN_DISABLED" then
		if not SoundtrackAddon.db.profile.settings.EnableBattleMusic then
			return
		end

		-- If we re-enter combat after cooldown, clear timers.
		Soundtrack.Timers.Remove("BattleCooldown")
		AnalyzeBattleSituation()
	elseif event == "PLAYER_REGEN_ENABLED" and not UnitIsCorpse("player") and not UnitIsDead("player") then
		if SoundtrackAddon.db.profile.settings.BattleCooldown > 0 then
			Soundtrack.Timers.AddTimer(
				"BattleCooldown",
				SoundtrackAddon.db.profile.settings.BattleCooldown,
				StopCombatMusic
			)
		else
			StopCombatMusic()
		end
	elseif event == "COMBAT_LOG_EVENT_UNFILTERED" then
		if eventType == "PARTY_KILL" then --CSCIGUY added 8-10-18
			hostileDeathCount = hostileDeathCount + 1
			Soundtrack.Chat.TraceBattle("Death count: " .. hostileDeathCount)
		else
			if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
				for _, v in pairs(Soundtrack_BattleEvents) do
					if Soundtrack.Events.EventHasTracks(ST_MISC, v) then
						v.script()
					end
				end
			end
		end
	elseif event == "PLAYER_UNGHOST" then
		Soundtrack.StopEvent(ST_MISC, SOUNDTRACK_GHOST)
	elseif event == "PLAYER_ALIVE" then
		Soundtrack.Chat.TraceBattle("PLAYER_ALIVE")
		if UnitIsDeadOrGhost("player") then
			Soundtrack.PlayEvent(ST_MISC, SOUNDTRACK_GHOST)
			currentBattleTypeIndex = 0
		else
			Soundtrack.StopEvent(ST_MISC, SOUNDTRACK_GHOST)
		end
	elseif event == "PLAYER_DEAD" then
		Soundtrack.Chat.TraceBattle("PLAYER_DEAD")
		if UnitIsDeadOrGhost("player") then
			Soundtrack.StopEventAtLevel(ST_BATTLE_LVL)
			Soundtrack.StopEventAtLevel(ST_BOSS_LVL)
			Soundtrack.PlayEvent(ST_MISC, SOUNDTRACK_DEATH)
			--Reset difficulties outside of combat. -Gotest
			currentBattleTypeIndex = 0 -- we are out of battle
			highestlevel = 1
			highestDifficulty = 1
			highestClassification = 1
		end
		currentBattleTypeIndex = 0 -- out of combat
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		Soundtrack.Chat.TraceBattle("ZONE_CHANGED_NEW_AREA")
		local inInstance, instanceType = IsInInstance()
		if inInstance and (instanceType == "party" or instanceType == "raid") then
			local _, _, encountersTotal, _ = GetInstanceLockTimeRemaining()
			for i = 1, encountersTotal, 1 do
				local bossName, _, _ = GetInstanceLockTimeRemainingEncounter(i)
				local lowhealthbossname = bossName .. " " .. SOUNDTRACK_LOW_HEALTH
				Soundtrack.AddEvent(ST_BOSS, bossName, ST_BOSS_LVL, true)
				Soundtrack.AddEvent(ST_BOSS, lowhealthbossname, ST_BOSS_LVL, true)
				local bossTable = Soundtrack.Events.GetTable(ST_BOSS)
				local bossEvent = bossTable[bossName]
				local bossEventLowHealth = bossTable[lowhealthbossname]
				if instanceType == "raid" then
					bossEvent.worldboss = true
					bossEventLowHealth.worldboss = true
				end
			end
		end
	end
end

function Soundtrack.BattleEvents.RegisterEventScript(
	self,
	name,
	tableName,
	_trigger,
	_priority,
	_continuous,
	_script,
	_soundEffect
)
	Soundtrack_MiscEvents[name] = {
		trigger = _trigger,
		script = _script,
		eventtype = ST_EVENT_SCRIPT,
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}
	Soundtrack_BattleEvents[name] = { script = _script }

	self:RegisterEvent(_trigger)

	Soundtrack.AddEvent(tableName, name, _priority, _continuous, _soundEffect)
end

function Soundtrack.BattleEvents.Initialize()
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_UNKNOWN_BATTLE, ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_CRITTER, ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB, ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB .. "/1 Trivial", ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB .. "/2 Easy", ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB .. "/3 Normal", ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB .. "/4 Tough", ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB .. "/5 Impossible", ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_ELITE_MOB, ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_ELITE_MOB .. "/1 Trivial", ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_ELITE_MOB .. "/2 Easy", ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_ELITE_MOB .. "/3 Normal", ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_ELITE_MOB .. "/4 Tough", ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_ELITE_MOB .. "/5 Impossible", ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_BOSS_BATTLE, ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_BOSS_LOW_HEALTH, ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_WORLD_BOSS_BATTLE, ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_WORLD_BOSS_LOW_HEALTH, ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_PVP_BATTLE, ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_RARE, ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_VICTORY, ST_BATTLE_LVL, false, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_VICTORY_BOSS, ST_BOSS_LVL, false, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_DEATH, ST_DEATH_LVL, true, false)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_GHOST, ST_DEATH_LVL, true, false)

	--[[
  ==========================================================
    MISC EVENTS with COMBAT_LOG_EVENT_UNFILTERED event

    This allows them to register with the same frame
      so that only one frame handles all
      COMBAT_LOG_EVENT_UNFILTERED events
  ==========================================================
  --]]

	Soundtrack.BattleEvents.RegisterEventScript( -- Swing Crit
		SoundtrackBattleDUMMY,
		SOUNDTRACK_SWING_CRIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "SWING_DAMAGE" and arg5 == UnitName("player") and arg18 == 1 then
				Soundtrack.Misc.PlayEvent(SOUNDTRACK_SWING_CRIT)
			end
		end,
		true
	)
	Soundtrack.BattleEvents.RegisterEventScript( -- Swing
		SoundtrackBattleDUMMY,
		SOUNDTRACK_SWING_HIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "SWING_DAMAGE" and arg5 == UnitName("player") then
				if arg18 == nil then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_SWING_HIT)
				elseif arg18 == 1 and Soundtrack.Events.EventHasTracks(ST_MISC, SOUNDTRACK_SWING_CRIT) == false then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_SWING_HIT)
				end
			end
		end,
		true
	)

	Soundtrack.BattleEvents.RegisterEventScript( -- Damage Spells Crit
		SoundtrackBattleDUMMY,
		SOUNDTRACK_SPELL_CRIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "SPELL_DAMAGE" and arg5 == UnitName("player") and arg21 == 1 then
				Soundtrack.Misc.PlayEvent(SOUNDTRACK_SPELL_CRIT)
			end
		end,
		true
	)

	Soundtrack.BattleEvents.RegisterEventScript( -- Damage Spells
		SoundtrackBattleDUMMY,
		SOUNDTRACK_SPELL_HIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "SPELL_DAMAGE" and arg5 == UnitName("player") then
				if arg21 == nil then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_SPELL_HIT)
				elseif arg21 == 1 and Soundtrack.Events.EventHasTracks(ST_MISC, SOUNDTRACK_SPELL_CRIT) == false then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_SPELL_HIT)
				end
			end
		end,
		true
	)

	Soundtrack.BattleEvents.RegisterEventScript( -- DoTs Crit
		SoundtrackBattleDUMMY,
		SOUNDTRACK_DOT_CRIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "SPELL_PERIODIC_DAMAGE" and arg5 == UnitName("player") and arg21 == 1 then
				Soundtrack.Misc.PlayEvent(SOUNDTRACK_DOT_CRIT)
			end
		end,
		true
	)

	Soundtrack.BattleEvents.RegisterEventScript( -- DoTs
		SoundtrackBattleDUMMY,
		SOUNDTRACK_DOT_HIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "SPELL_PERIODIC_DAMAGE" and arg5 == UnitName("player") then
				if arg21 == nil then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_DOT_HIT)
				elseif arg21 == 1 and Soundtrack.Events.EventHasTracks(ST_MISC, SOUNDTRACK_DOT_CRIT) == false then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_DOT_HIT)
				end
			end
		end,
		true
	)

	Soundtrack.BattleEvents.RegisterEventScript( -- Healing Spells Crit
		SoundtrackBattleDUMMY,
		SOUNDTRACK_HEAL_CRIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "SPELL_HEAL" and arg5 == UnitName("player") and arg18 == 1 then
				Soundtrack.Misc.PlayEvent(SOUNDTRACK_HEAL_CRIT)
			end
		end,
		true
	)

	Soundtrack.BattleEvents.RegisterEventScript( -- Healing Spells
		SoundtrackBattleDUMMY,
		SOUNDTRACK_HEAL_HIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "SPELL_HEAL" and arg5 == UnitName("player") then
				if arg18 == nil then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_HEAL_HIT)
				elseif arg18 == 1 and Soundtrack.Events.EventHasTracks(ST_MISC, SOUNDTRACK_HEAL_CRIT) == false then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_HEAL_HIT)
				end
			end
		end,
		true
	)

	Soundtrack.BattleEvents.RegisterEventScript( -- HoTs Crit
		SoundtrackBattleDUMMY,
		SOUNDTRACK_HOT_CRIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "SPELL_PERIODIC_HEAL" and arg5 == UnitName("player") and arg18 == 1 then
				Soundtrack.Misc.PlayEvent(SOUNDTRACK_HOT_CRIT)
			end
		end,
		true
	)

	Soundtrack.BattleEvents.RegisterEventScript( -- HoTs
		SoundtrackBattleDUMMY,
		SOUNDTRACK_HOT_HIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "SPELL_PERIODIC_HEAL" and arg5 == UnitName("player") then
				if arg18 == nil then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_HOT_HIT)
				elseif arg18 == 1 and Soundtrack.Events.EventHasTracks(ST_MISC, SOUNDTRACK_HOT_CRIT) == false then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_HOT_HIT)
				end
			end
		end,
		true
	)

	Soundtrack.BattleEvents.RegisterEventScript( -- Range Crit
		SoundtrackBattleDUMMY,
		SOUNDTRACK_RANGE_CRIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "RANGE_DAMAGE" and arg5 == UnitName("player") and arg21 == 1 then
				Soundtrack.Misc.PlayEvent(SOUNDTRACK_RANGE_CRIT)
			end
		end,
		true
	)

	Soundtrack.BattleEvents.RegisterEventScript( -- Range
		SoundtrackBattleDUMMY,
		SOUNDTRACK_RANGE_HIT,
		ST_MISC,
		"COMBAT_LOG_EVENT_UNFILTERED",
		ST_SFX_LVL,
		false,
		function()
			if arg2 == "RANGE_DAMAGE" and arg5 == UnitName("player") then
				if arg21 == nil then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_RANGE_HIT)
				elseif arg21 == 1 and Soundtrack.Events.EventHasTracks(ST_MISC, SOUNDTRACK_RANGE_CRIT) == false then
					Soundtrack.Misc.PlayEvent(SOUNDTRACK_RANGE_HIT)
				end
			end
		end,
		true
	)
end
