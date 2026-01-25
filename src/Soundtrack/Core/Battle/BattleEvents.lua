--[[
    Soundtrack addon for World of Warcraft

    Battle events functions.
    Functions that manage battle situation changes.
]]

Soundtrack.BattleEvents = {}

local arg1, arg2, arg3, arg4, arg5, arg6, arg7, arg8, arg9, arg10, arg11, arg12, arg13, arg14, arg15, arg16, arg17, arg18, arg19, arg20, arg21, arg22, arg23

-- TODO(Eric): Is there a way to check for boss?
-- Classifications for mobs
local classifications = {
	"Critter",
	"normal",
	"rare",
	"elite",
	"rareelite",
	"worldboss",
}

-- Initialize difficulties only once. Prevents de-escalations during combat. -Gotest
local highestlevel = 1
local highestClassification = 1

-- Battle event priority for mob types
local battleEvents = {
	SOUNDTRACK_UNKNOWN_BATTLE,
	SOUNDTRACK_CRITTER,
	SOUNDTRACK_NORMAL_MOB,
	SOUNDTRACK_ELITE_MOB,
	SOUNDTRACK_RARE,
	SOUNDTRACK_BOSS_BATTLE,
	SOUNDTRACK_WORLD_BOSS_BATTLE,
	SOUNDTRACK_PVP_BATTLE,
}

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

-- Gets classification text from clasification level
local function GetClassificationText(classificationLevel)
	return classifications[classificationLevel]
end

-- Calculates the highest enemy level amongs all the party members and pet
-- targets. Thanks to Athame!
-- Returns classification, pvpEnabled
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

	for _, unit in ipairs(units) do
		local target = unit .. "target"
		local unitExists = UnitExists(target)
		local unitIsEnemy = not UnitIsFriend("player", target)
		local unitIsAlive = not UnitIsDeadOrGhost(target)

		if unitExists and unitIsEnemy and unitIsAlive then
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

			-- Get the target classification
			if not issecretvalue(unitCreatureType) and unitCreatureType == "Critter" then
				unitClass = unitCreatureType
			end

			local classificationLevel = GetClassificationLevel(unitClass)
			if classificationLevel > highestClassification then
				highestClassification = classificationLevel
			end
		end
	end

	local classificationText = GetClassificationText(highestClassification)
	return classificationText, pvpEnabled, isBoss, bossName
end

-- When the player is engaged in battle, this determines
-- the type of battle.
local function GetBattleType()
	local classification, pvpEnabled, isBoss, bossName = GetGroupEnemyLevel()
	if pvpEnabled then
		return SOUNDTRACK_PVP_BATTLE
	else
		if isBoss then -- Boss or World Boss
			if classification == "worldboss" then
				return SOUNDTRACK_WORLD_BOSS_BATTLE, bossName -- World Boss( raid)
			else
				return SOUNDTRACK_BOSS_BATTLE, bossName -- Boss (party)
			end
		end

		if classification == "rareelite" or classification == "rare" then
			return SOUNDTRACK_RARE -- Rare mob
		end

		if classification == "elite" then -- Elite mob
			return SOUNDTRACK_ELITE_MOB
		end

		if classification == "normal" then -- Normal mob
			return SOUNDTRACK_NORMAL_MOB
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
	local battleType, bossName = GetBattleType()
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
		if battleType == SOUNDTRACK_BOSS_BATTLE or battleType == SOUNDTRACK_WORLD_BOSS_BATTLE then
			Soundtrack.PlayEvent(ST_BATTLE, battleType)
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
			Soundtrack.PlayEvent(ST_MISC, SOUNDTRACK_DEATH)
			--Reset difficulties outside of combat. -Gotest
			currentBattleTypeIndex = 0 -- we are out of battle
			highestlevel = 1
			highestClassification = 1
		end
		currentBattleTypeIndex = 0 -- out of combat
	elseif event == "ZONE_CHANGED_NEW_AREA" then
		Soundtrack.Chat.TraceBattle("ZONE_CHANGED_NEW_AREA")
	end
end

function Soundtrack.BattleEvents.Initialize()
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_UNKNOWN_BATTLE, ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_CRITTER, ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_NORMAL_MOB, ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_ELITE_MOB, ST_BATTLE_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_BOSS_BATTLE, ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_WORLD_BOSS_BATTLE, ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_PVP_BATTLE, ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_BATTLE, SOUNDTRACK_RARE, ST_BOSS_LVL, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_VICTORY, ST_BATTLE_LVL, false, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_VICTORY_BOSS, ST_BOSS_LVL, false, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_DEATH, ST_DEATH_LVL, true, false)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_GHOST, ST_DEATH_LVL, true, false)
end
