--[[
    Soundtrack addon for World of Warcraft

    Pet battle event functions.
	
	Written by Sciz.
	
	Notes:	
	The in-game Pet Battle Music option MUST BE OFF for zone music to resume properly.
	If it's left on, the default music will interrupt whatever's playing a couple seconds
	after battle ends.
	
	Known Issues:
	-The PVP Random loads and executes correctly, but is overwritten by the zone event of wherever
	 the system teleports you to after the battle starts
	-Victory music works, but causes the WoW default zone music to kick in after the battle instead
	 of reverting to Soundtrack's zone event
	 
	Functionality for both is currently disabled.
	
	Possible features:
	-Play different tracks based on wild pet rarity
	-Play different tracks based on wild pet species
]]

Soundtrack.PetBattleEvents = {}

function Soundtrack.PetBattleEvents.OnLoad(self)
	self:RegisterEvent("PET_BATTLE_OPENING_START")
	self:RegisterEvent("PET_BATTLE_OVER")
	self:RegisterEvent("PET_BATTLE_PVP_DUEL_REQUESTED")
	self:RegisterEvent("PET_BATTLE_PVP_DUEL_REQUEST_CANCEL")
	self:RegisterEvent("PET_BATTLE_QUEUE_PROPOSAL_ACCEPTED")
	self:RegisterEvent("PET_BATTLE_QUEUE_PROPOSAL_DECLINED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
end

local isPlayer = false
local hasTracks = false --used to fall back to the Players/Named NPCs subheading if a player-registered event has no tracks
local targetName = nil
local zoneText

function Soundtrack.PetBattleEvents.OnEvent(_, event)
	if event == "PET_BATTLE_OPENING_START" then
		Soundtrack.PetBattleEvents.BattleEngaged()
	end

	if event == "PET_BATTLE_OVER" then
		Soundtrack.PetBattleEvents.Victory()
	end

	if event == "PLAYER_TARGET_CHANGED" then
		if UnitExists("target") then
			Soundtrack.PetBattleEvents.GetPlayerTargetInfo()
			Soundtrack.PetBattleEvents.CheckPlayerTarget()
		else --This might be a bad idea if the target changes when a battle loads
			isPlayer = false
			hasTracks = false
			targetName = nil
		end
	end
end

function Soundtrack.PetBattleEvents.BattleEngaged()
	if not targetName and isPlayer then
		Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PVP_DUEL)
	elseif targetName then --Registered target battle
		if isPlayer then
			if hasTracks then
				Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS .. "/" .. targetName)
			else --Event is registered but has no assigned tracks, fall back to the subheading's tracks
				Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS)
			end
		else
			if hasTracks then
				Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS .. "/" .. targetName)
			else
				Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS)
			end
		end
	else --Continental NPC or wild battle
		zoneText = C_Map.GetMapInfo(C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player")).parentMapID).name
		if zoneText == nil then
			return
		end

		if C_PetBattles.IsWildBattle() then
			Soundtrack.Chat.TracePetBattles(zoneText .. "=continentText " .. SOUNDTRACK_WILD_BATTLE)
			Soundtrack.PlayEvent(ST_PETBATTLES, zoneText .. " " .. SOUNDTRACK_WILD_BATTLE)
		elseif not C_PetBattles.IsWildBattle() then
			Soundtrack.Chat.TracePetBattles(zoneText .. " " .. SOUNDTRACK_NPC_BATTLE)
			Soundtrack.PlayEvent(ST_PETBATTLES, zoneText .. " " .. SOUNDTRACK_NPC_BATTLE)
		end
	end
end

function Soundtrack.PetBattleEvents.Victory()
	Soundtrack.StopEventAtLevel(ST_NPC_LVL)
	isPlayer = false
	hasTracks = false
	targetName = nil
end

function Soundtrack.PetBattleEvents.GetPlayerTargetInfo()
	targetName = UnitName("target")
	if UnitIsPlayer("target") then
		isPlayer = true
	else
		isPlayer = false
	end
end

function Soundtrack.PetBattleEvents.CheckPlayerTarget()
	if isPlayer then
		if Soundtrack.Events.EventExists(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS .. "/" .. targetName) then
			Soundtrack.Chat.TracePetBattles("Target player has known named event")
			if Soundtrack.Events.EventHasTracks(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS .. "/" .. targetName) then
				hasTracks = true
			end
		else
			hasTracks = false
			targetName = nil
		end
	else
		if Soundtrack.Events.EventExists(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS .. "/" .. targetName) then
			Soundtrack.Chat.TracePetBattles("Target NPC has known named event")
			if
				Soundtrack.Events.EventHasTracks(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS .. "/" .. targetName)
			then
				hasTracks = true
			end
		else
			hasTracks = false
			targetName = nil
		end
	end
end

function Soundtrack.PetBattleEvents.Initialize()
	Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PVP_DUEL, ST_NPC_LVL, true)
	Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS, ST_NPC_LVL, true)
	Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS, ST_NPC_LVL, true)

	local continents = C_Map.GetMapChildrenInfo(946, 2, 1)
	if continents == nil then
		return
	end

	for _, v in pairs(continents) do
		Soundtrack.AddEvent(ST_PETBATTLES, v.name .. " " .. SOUNDTRACK_WILD_BATTLE, ST_NPC_LVL, true)
		Soundtrack.AddEvent(ST_PETBATTLES, v.name .. " " .. SOUNDTRACK_NPC_BATTLE, ST_NPC_LVL, true)
	end
end
