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
	
	TODO: 
	-Fix the known issues
	-Check behavior when a real battle interrupts a pet battle
	-See if the PVP request declined checks are actually necessary (testing suggests no)
	-Add global pet battle music on/off toggle over in the options
	-Fix PVP duels with no target (maybe, needs testing)
	-Fix PVP duel proposals with an unregistered player
	--There is no event for proposing a duel
	--Check if not targetName and isPlayer, perhaps
	
	Possible features:
	-Play different tracks based on wild pet rarity
	-Play different tracks based on wild pet species
]]

Soundtrack.PetBattlesEvents = {}

function Soundtrack.PetBattlesEvents.OnLoad(self)
	self:RegisterEvent("PET_BATTLE_OPENING_START")
	self:RegisterEvent("PET_BATTLE_OVER")
	self:RegisterEvent("PET_BATTLE_PVP_DUEL_REQUESTED")
	self:RegisterEvent("PET_BATTLE_PVP_DUEL_REQUEST_CANCEL")
	self:RegisterEvent("PET_BATTLE_QUEUE_PROPOSAL_ACCEPTED")
	self:RegisterEvent("PET_BATTLE_QUEUE_PROPOSAL_DECLINED")
	self:RegisterEvent("PLAYER_TARGET_CHANGED")
end

local isPVPDuel = false
local isPVPRandom = false
local isPlayer = false
local hasTracks = false --used to fall back to the Players/Named NPCs subheading if a player-registered event has no tracks
local targetName = nil 

function Soundtrack.PetBattlesEvents.OnEvent(self, event, ...)
	Soundtrack.TracePetBattles(event)

	if event == "PET_BATTLE_OPENING_START" then
		Soundtrack.PetBattlesEvents.BattleEngaged()
	end	
	
	if event == "PET_BATTLE_OVER" then
		Soundtrack.PetBattlesEvents.Victory()
	end

	if event == "PLAYER_TARGET_CHANGED" then
		if UnitExists("target") then
			Soundtrack.PetBattlesEvents.GetPlayerTargetInfo()
			Soundtrack.PetBattlesEvents.CheckPlayerTarget()
		else --This might be a bad idea if the target changes when a battle loads
			isPVPDuel = false
			isPVPRandom = false
			isPlayer = false
			hasTracks = false
			targetName = nil
		end
	end

	if event == "PET_BATTLE_PVP_DUEL_REQUESTED" then
		isPVPDuel = true
		Soundtrack.TracePetBattles("PVP Duel flag set to true")
	end
	
	if event == "PET_BATTLE_PVP_DUEL_REQUEST_CANCEL" then
		isPVPDuel = false
		Soundtrack.TracePetBattles("PVP Duel flag set to false")
	end
	
	if event == "PET_BATTLE_QUEUE_PROPOSAL_ACCEPTED" then
		isPVPRandom = true
		Soundtrack.TracePetBattles("PVP Random flag set to true")
	end
	
	if event == "PET_BATTLE_QUEUE_PROPOSAL_DECLINED" then
		isPVPRandom = false
		Soundtrack.TracePetBattles("PVP Random flag set to false")
	end
	
end

local zoneText

--Copied from SoundtrackZoneEvents.lua
local function FindContinentByZone(zoneName)

		-- if zoneName == nil then return nil end
	
	-- local inInstance, instanceType = IsInInstance();
	-- if inInstance then
		-- if instanceType == "arena" or instanceType == "pvp" then
			-- return SOUNDTRACK_PVP, nil;
		-- end
		-- if instanceType == "party" or instanceType == "raid" then
			-- return SOUNDTRACK_INSTANCES, nil;
		-- end
	-- end
	
	-- -- Find the current continent
	-- local areaid = GetCurrentMapAreaID()				-- Save map (in case it is open)
	-- SetMapToCurrentZone()
	-- local continentValue = GetCurrentMapContinent() 	-- Grab continent and zone, WoD Fix: "* 2"
	-- Soundtrack.TraceZones("Continent Value:" .. continentValue);
	-- local zoneValue = GetCurrentMapAreaID()
	-- Soundtrack.TraceZones("Zone Value:" .. zoneValue);
	-- SetMapByID(areaid)									-- Set map back
	
	
	-- --local continentNames = {GetMapContinents()}			-- Get continents
	-- local continentNames = {};		
	-- local continentsP6 = { GetMapContinents() };
	-- local index = 0;
	-- for i = 2, #continentsP6, 2 do
		-- index = index + 1;
		-- continentNames[index] = continentsP6[i];
	-- end
	
	-- local zoneNames = {GetMapZones(continentValue)}		-- Get zones
	
	-- local continent = continentNames[continentValue]
	-- local zone = nil
	-- for i=1, #zoneNames, 2 do
		-- if zoneNames[i] == zoneValue then
			-- zone = zoneNames[zoneValue]
		-- end
	-- end
	
	-- if continent == nil then 
		-- return SOUNDTRACK_UNKNOWN, zone
	-- end

	-- return continent
end

function Soundtrack.PetBattlesEvents.BattleEngaged()

	--[[Logic flow:
	1. If is a PVP random, execute PVP random event
	----Player is using matchmaking
	2. Elseif is not a named unit but is a PVP duel, execute PVP duel event
	----Player is dueling a target without a registered name
	3. Elseif is a named unit, execute corresponding event
	----Player is battling an NPC or dueling a player with a registered name
	4. Elseif not a player and not a named unit and not a duel and not a random, execute continental event
	----Player is battling an unregistered NPC or wild pet
	
	The possibility exists for misfires if the player changes targets after triggering flags,
	e.g. targeting a registered player while accepting an unregistered NPC battle will execute #3
	
	--temp debug data
	Soundtrack.TracePetBattles("Flag status on BattleEngaged:")
	if targetName then
		Soundtrack.TracePetBattles("targetName exists, is "..targetName)
	else
		Soundtrack.TracePetBattles("targetName is nil")
	end
	if isPlayer then
		Soundtrack.TracePetBattles("isPlayer set to true")
	else
		Soundtrack.TracePetBattles("isPlayer set to false")
	end
	if hasTracks then
		Soundtrack.TracePetBattles("hasTracks set to true")
	else
		Soundtrack.TracePetBattles("hasTracks set to false")
	end
	if isPVPDuel then
		Soundtrack.TracePetBattles("isPVPDuel set to true")
	else
		Soundtrack.TracePetBattles("isPVPDuel set to false")
	end
	if isPVPRandom then
		Soundtrack.TracePetBattles("isPVPRandom set to true")
	else
		Soundtrack.TracePetBattles("isPVPRandom set to false")
	end]]

	
	--if isPVPRandom then --PVP Matchmaking battle
	--	Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PVP_MATCHMAKING)
	if not targetName and isPlayer then --PVP Duel battle
		Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PVP_DUEL)	
	elseif targetName then --Registered target battle
		if isPlayer then
			if hasTracks then
				Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS.."/"..targetName)
			else --Event is registered but has no assigned tracks, fall back to the subheading's tracks
				Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS)
			end
		else
			if hasTracks then
				Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS.."/"..targetName)
			else
				Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS)
			end
		end
	else --Continental NPC or wild battle

		zoneText = C_Map.GetMapInfo(C_Map.GetMapInfo(C_Map.GetBestMapForUnit("player")).parentMapID).name
		if zoneText == nil then return end
	
		if C_PetBattles.IsWildBattle() then
			Soundtrack.TracePetBattles(zoneText.."=continentText "..SOUNDTRACK_WILD_BATTLE);
			Soundtrack.PlayEvent(ST_PETBATTLES, zoneText.." "..SOUNDTRACK_WILD_BATTLE)
		elseif not C_PetBattles.IsWildBattle() then
			Soundtrack.TracePetBattles(zoneText.." "..SOUNDTRACK_NPC_BATTLE);
			Soundtrack.PlayEvent(ST_PETBATTLES, zoneText.." "..SOUNDTRACK_NPC_BATTLE)
		end
	end

end

function Soundtrack.PetBattlesEvents.Victory()

	Soundtrack.StopEventAtLevel(ST_NPC_LVL)
	isPVPDuel = false
	isPVPRandom = false
	isPlayer = false
	hasTracks = false
	targetName = nil
	--Causes the zone music to not resume after being played, not exactly certain why. Looking into it. Consider flipping playevent and stopevent calls. -Sciz
	--Soundtrack.PlayEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_VICTORY)
	
end

function Soundtrack.PetBattlesEvents.GetPlayerTargetInfo()
		
		targetName = UnitName("target")
		Soundtrack.TracePetBattles("Target name is: "..targetName)
		if UnitIsPlayer("target") then
			isPlayer = true
		else
			isPlayer = false
		end

end

function Soundtrack.PetBattlesEvents.CheckPlayerTarget()

	if isPlayer then
		if SoundtrackEvents_EventExists(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS.."/"..targetName) then
			Soundtrack.TracePetBattles("Target player has known named event")	
			if SoundtrackEvents_EventHasTracks(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS.."/"..targetName) then
				hasTracks = true
			end
		else
			Soundtrack.TracePetBattles("Target player does not have a known named event")
			hasTracks = false
			targetName = nil
		end
	else
		if SoundtrackEvents_EventExists(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS.."/"..targetName) then
			Soundtrack.TracePetBattles("Target NPC has known named event")	
			if SoundtrackEvents_EventHasTracks(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS.."/"..targetName) then
				hasTracks = true
			end
		else
			Soundtrack.TracePetBattles("Target NPC does not have a known named event")	
			hasTracks = false
			targetName = nil
		end
	end

end

function Soundtrack.PetBattlesEvents.Initialize()
	-- --Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PVP_MATCHMAKING, ST_NPC_LVL, true)
	Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PVP_DUEL, ST_NPC_LVL, true)
	Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS, ST_NPC_LVL, true)
	Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS, ST_NPC_LVL, true)
	-- --Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_VICTORY, ST_SFX_LVL, false, true)

	-- --Add pet battles by continent
	
	 local continents = C_Map.GetMapChildrenInfo(946,2,1)
	-- Add continents
	for k,v in pairs(continents) do
			 Soundtrack.AddEvent(ST_PETBATTLES, v.name.." "..SOUNDTRACK_WILD_BATTLE, ST_NPC_LVL, true)
			 Soundtrack.AddEvent(ST_PETBATTLES, v.name.." "..SOUNDTRACK_NPC_BATTLE, ST_NPC_LVL, true)
	 end
end
