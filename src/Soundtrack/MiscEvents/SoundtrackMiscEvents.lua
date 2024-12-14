--[[
    Soundtrack addon for World of Warcraft

    Misc events functions.
    Functions that manage misc. and custom events.
]]

-- TODO: Should break out the actual event registration to more organized chunks

local function debug(msg)
	Soundtrack.TraceCustom(msg)
end

Soundtrack.MiscEvents = {}
Soundtrack.MiscEvents.ActionHouse = false
Soundtrack.MiscEvents.Bank = false
Soundtrack.MiscEvents.Merchant = false
Soundtrack.MiscEvents.FlightMaster = false
Soundtrack.MiscEvents.Barbershop = false
Soundtrack.MiscEvents.Trainer = false
Soundtrack.MiscEvents.CurrentStance = 0
Soundtrack.MiscEvents.WasStealthed = false
Soundtrack.MiscEvents.WasSwimming = false
Soundtrack.MiscEvents.WasInAuctionHouse = false
Soundtrack.MiscEvents.WasInBank = false
Soundtrack.MiscEvents.WasAtMerchant = false
Soundtrack.MiscEvents.WasOnFlightMaster = false
Soundtrack.MiscEvents.WasAtTrainer = false
Soundtrack.MiscEvents.WasAtBarbershop = false
Soundtrack.MiscEvents.WasInCinematic = false
Soundtrack.MiscEvents.WasInParty = false
Soundtrack.MiscEvents.WasInRaid = false

local nonInnZones = {
	["Ironforge"] = 1,
	["Stormwind City"] = 1,
	["Darnassus"] = 1,
	["Orgrimmar"] = 1,
	["Thunder Bluff"] = 1,
	["Undercity"] = 1,
}

local function OnRestingEvent()
	local currentZone = GetZoneText()
	if IsResting() and not nonInnZones[currentZone] then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_RESTING)
	else
		Soundtrack_Misc_StopEvent(SOUNDTRACK_RESTING)
	end
end

local function OnSwimmingEvent()
	if Soundtrack.MiscEvents.WasSwimming and not IsSwimming() then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_SWIMMING)
		Soundtrack.MiscEvents.WasSwimming = false
	elseif not Soundtrack.MiscEvents.WasSwimming and IsSwimming() then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_SWIMMING)
		Soundtrack.MiscEvents.WasSwimming = true
	end
end

local function OnAuctionHouseEvent()
	if Soundtrack.MiscEvents.WasInAuctionHouse and not Soundtrack.MiscEvents.AuctionHouse then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_AUCTION_HOUSE)
		Soundtrack.MiscEvents.WasInAuctionHouse = false
	elseif not Soundtrack.MiscEvents.WasInAuctionHouse and Soundtrack.MiscEvents.AuctionHouse then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_AUCTION_HOUSE)
		Soundtrack.MiscEvents.WasInAuctionHouse = true
	end
end

local function OnBankEvent()
	-- Soundtrack.* does not deal with localization
	if Soundtrack.MiscEvents.WasInBank and not Soundtrack.MiscEvents.Bank then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_BANK)
		Soundtrack.MiscEvents.WasInBank = false
	elseif not Soundtrack.MiscEvents.WasInBank and Soundtrack.MiscEvents.Bank then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_BANK)
		Soundtrack.MiscEvents.WasInBank = true
	end
end

local function OnMerchantEvent()
	if Soundtrack.MiscEvents.WasAtMerchant and not Soundtrack.MiscEvents.Merchant then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_MERCHANT)
		Soundtrack.MiscEvents.WasAtMerchant = false
	elseif not Soundtrack.MiscEvents.WasAtMerchant and Soundtrack.MiscEvents.Merchant then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_MERCHANT)
		Soundtrack.MiscEvents.WasAtMerchant = true
	end
end

local function OnFlightMasterEvent()
	if Soundtrack.MiscEvents.WasOnFlightMaster and not Soundtrack.MiscEvents.FlightMaster then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_FLIGHTMASTER)
		Soundtrack.MiscEvents.WasOnFlightMaster = false
	elseif not Soundtrack.MiscEvents.WasOnFlightMaster and Soundtrack.MiscEvents.FlightMaster then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_FLIGHTMASTER)
		Soundtrack.MiscEvents.WasOnFlightMaster = true
	end
end

local function OnTrainerEvent()
	if Soundtrack.MiscEvents.WasAtTrainer and not Soundtrack.MiscEvents.Trainer then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_TRAINER)
		Soundtrack.MiscEvents.WasAtTrainer = false
	elseif not Soundtrack.MiscEvents.WasAtTrainer and Soundtrack.MiscEvents.Trainer then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_TRAINER)
		Soundtrack.MiscEvents.WasAtTrainer = true
	end
end

local function OnBarbershopEvent()
	if Soundtrack.MiscEvents.WasAtBarbershop and not Soundtrack.MiscEvents.Barbershop then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_BARBERSHOP)
		Soundtrack.MiscEvents.WasAtBarbershop = false
	elseif not Soundtrack.MiscEvents.WasAtBarbershop and Soundtrack.MiscEvents.Barbershop then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_BARBERSHOP)
		Soundtrack.MiscEvents.WasAtBarbershop = true
	end
end

local function OnCinematicEvent()
	if Soundtrack.MiscEvents.WasInCinematic and not Soundtrack.MiscEvents.Cinematic then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_CINEMATIC)
		Soundtrack.MiscEvents.WasInCinematic = false
	elseif not Soundtrack.MiscEvents.WasInCinematic and Soundtrack.MiscEvents.Cinematic then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_CINEMATIC)
		Soundtrack.MiscEvents.WasInCinematic = true
	end
end

local function OnJoinPartyEvent()
	if not Soundtrack.MiscEvents.WasInParty and GetNumSubgroupMembers() == 0 and GetNumSubgroupMembers() > 0 then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_JOIN_PARTY)
		Soundtrack.MiscEvents.WasInParty = true
	elseif Soundtrack.MiscEvents.WasInParty and GetNumSubgroupMembers() == 0 then
		Soundtrack.MiscEvents.WasInParty = false
	end
end

local function OnJoinRaidEvent()
	if not Soundtrack.MiscEvents.WasInRaid and GetNumSubgroupMembers() > 0 then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_JOIN_RAID)
		Soundtrack.MiscEvents.WasInRaid = true
	elseif Soundtrack.MiscEvents.WasInRaid and not GetNumSubgroupMembers() == 0 then
		Soundtrack.MiscEvents.WasInRaid = false
	end
end

function OnChangeShapeshiftEvent()
	local class = UnitClass("player")
	local stance = GetShapeshiftForm()
	if class == "Death Knight" and stance ~= 0 and stance ~= Soundtrack.MiscEvents.CurrentStance then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_DK_CHANGE)
		Soundtrack.MiscEvents.CurrentStance = stance
	elseif class == "Druid" and stance ~= 0 and stance ~= Soundtrack.MiscEvents.CurrentStance then
		Soundtrack_Misc_PlayEvent("Misc", SOUNDTRACK_DRUID_CHANGE)
		Soundtrack.MiscEvents.CurrentStance = stance
	elseif class == "Druid" and stance == 0 and stance ~= Soundtrack.MiscEvents.CurrentStance then
		Soundtrack.MiscEvents.CurrentStance = stance
	elseif class == "Paladin" and stance ~= 0 and stance ~= Soundtrack.MiscEvents.CurrentStance then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_PALADIN_CHANGE)
		Soundtrack.MiscEvents.CurrentStance = stance
	elseif class == "Priest" and stance ~= 0 then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_PRIEST_CHANGE)
		Soundtrack.MiscEvents.CurrentStance = stance
	elseif class == "Rogue" and stance ~= 0 and stance ~= 2 and not IsStealthed() then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_ROGUE_CHANGE)
		Soundtrack.MiscEvents.CurrentStance = stance
	elseif class == "Shaman" and stance ~= 0 then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_SHAMAN_CHANGE)
		Soundtrack.MiscEvents.CurrentStance = stance
	elseif class == "Warrior" and stance ~= 0 and stance ~= Soundtrack.MiscEvents.CurrentStance then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_WARRIOR_CHANGE)
		Soundtrack.MiscEvents.CurrentStance = stance
	end
end

local function RogueStealthUpdate()
	local class = UnitClass("player")
	if Soundtrack.MiscEvents.WasStealthed and not IsStealthed() and class == "Rogue" then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_ROGUE_STEALTH)
		Soundtrack.MiscEvents.WasStealthed = false
	elseif not Soundtrack.MiscEvents.WasStealthed and IsStealthed() and class == "Rogue" then
		if Soundtrack.Auras.IsAuraActive(1784) then
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_ROGUE_STEALTH)
			Soundtrack.MiscEvents.WasStealthed = true
		end
	end
end

local function StealthUpdate()
	if Soundtrack.MiscEvents.WasStealthed and not IsStealthed() then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_STEALTHED)
		Soundtrack.MiscEvents.WasStealthed = false
	elseif not Soundtrack.MiscEvents.WasStealthed and IsStealthed() then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_STEALTHED)
		Soundtrack.MiscEvents.WasStealthed = true
	end
end

function Soundtrack.MiscEvents.RegisterUpdateScript(_, name, _priority, _continuous, _script, _soundEffect)
	if not name then
		return
	end

	Soundtrack_MiscEvents[name] = {
		script = _script,
		eventtype = ST_UPDATE_SCRIPT,
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	Soundtrack.AddEvent(ST_MISC, name, _priority, _continuous, _soundEffect)
end

function Soundtrack.MiscEvents.RegisterEventScript(self, name, _trigger, _priority, _continuous, _script, _soundEffect)
	if not name then
		return
	end

	Soundtrack_MiscEvents[name] = {
		trigger = _trigger,
		script = _script,
		eventtype = ST_EVENT_SCRIPT,
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	self:RegisterEvent(_trigger)
	Soundtrack.AddEvent(ST_MISC, name, _priority, _continuous, _soundEffect)
end

function Soundtrack.MiscEvents.RegisterBuffEvent(eventName, _spellId, _priority, _continuous, _soundEffect)
	if not eventName then
		return
	end

	Soundtrack_MiscEvents[eventName] = {
		spellId = _spellId,
		stackLevel = _priority,
		active = false,
		eventtype = ST_BUFF_SCRIPT,
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	Soundtrack.AddEvent(ST_MISC, eventName, _priority, _continuous, _soundEffect)
end

local function Soundtrack_Misc_PlayEvent(eventName)
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	if not eventTable then
		return
	end

	local currentEvent = Soundtrack.Events.Stack[eventTable[eventName].priority].eventName
	if eventName ~= currentEvent then
		Soundtrack.PlayEvent(ST_MISC, eventName)
	end
end

function Soundtrack_Misc_StopEvent(eventName)
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	if not eventTable then
		return
	end

	local currentEvent = Soundtrack.Events.Stack[eventTable[eventName].priority].eventName
	if eventName == currentEvent then
		Soundtrack.StopEvent(ST_MISC, eventName)
	end
end

local jumpDelayTime = 0
local jumpUpdateTime = 0.7
hooksecurefunc("JumpOrAscendStart", function()
	if HasFullControl() and not IsFlying() and not IsSwimming() and not UnitInVehicle("player") then
		local currentTime = GetTime()
		if currentTime >= jumpDelayTime then
			jumpDelayTime = currentTime + jumpUpdateTime
			if SoundtrackEvents_EventHasTracks(ST_MISC, SOUNDTRACK_JUMP) then
				Soundtrack_Misc_PlayEvent(SOUNDTRACK_JUMP)
			end
		end
	end
end)

-- TODO: Should break out the actual event registration to more organized chunks
function Soundtrack.MiscEvents.MiscInitialize()
	debug("Initializing misc. events...")

	SoundtrackMiscDUMMY:RegisterEvent("AUCTION_HOUSE_CLOSED")
	SoundtrackMiscDUMMY:RegisterEvent("AUCTION_HOUSE_SHOW")
	SoundtrackMiscDUMMY:RegisterEvent("BANKFRAME_CLOSED")
	SoundtrackMiscDUMMY:RegisterEvent("BANKFRAME_OPENED")
	SoundtrackMiscDUMMY:RegisterEvent("MERCHANT_CLOSED")
	SoundtrackMiscDUMMY:RegisterEvent("MERCHANT_SHOW")
	SoundtrackMiscDUMMY:RegisterEvent("TAXIMAP_CLOSED")
	SoundtrackMiscDUMMY:RegisterEvent("TAXIMAP_OPENED")
	SoundtrackMiscDUMMY:RegisterEvent("BARBER_SHOP_OPEN")
	SoundtrackMiscDUMMY:RegisterEvent("BARBER_SHOP_CLOSE")
	SoundtrackMiscDUMMY:RegisterEvent("TRAINER_SHOW")
	SoundtrackMiscDUMMY:RegisterEvent("TRAINER_CLOSED")

	-- Add fixed misc events
	Soundtrack.MiscEvents.RegisterUpdateScript( -- Swimming
		SoundtrackMiscDUMMY,
		SOUNDTRACK_SWIMMING,
		ST_STATUS_LVL,
		true,
		OnSwimmingEvent,
		false
	)

	Soundtrack.MiscEvents.RegisterUpdateScript( -- Auction House
		SoundtrackMiscDUMMY,
		SOUNDTRACK_AUCTION_HOUSE,
		ST_NPC_LVL,
		true,
		OnAuctionHouseEvent,
		false
	)

	Soundtrack.MiscEvents.RegisterUpdateScript( -- Bank
		SoundtrackMiscDUMMY,
		SOUNDTRACK_BANK,
		ST_NPC_LVL,
		true,
		OnBankEvent,
		false
	)

	Soundtrack.MiscEvents.RegisterUpdateScript( -- Merchant
		SoundtrackMiscDUMMY,
		SOUNDTRACK_MERCHANT,
		ST_NPC_LVL, -- TODO Anthony: This conflicts with battle level, was 6
		true,
		OnMerchantEvent,
		false
	)

	Soundtrack.MiscEvents.RegisterUpdateScript( -- FlightMaster
		SoundtrackMiscDUMMY,
		SOUNDTRACK_FLIGHTMASTER,
		ST_NPC_LVL,
		true,
		OnFlightMasterEvent,
		false
	)

	Soundtrack.MiscEvents.RegisterUpdateScript( -- Trainer
		SoundtrackMiscDUMMY,
		SOUNDTRACK_TRAINER,
		ST_NPC_LVL, -- TODO Anthony: This conflicts with battle level, was 6
		true,
		OnTrainerEvent,
		false
	)

	Soundtrack.MiscEvents.RegisterUpdateScript( -- Barbershop
		SoundtrackMiscDUMMY,
		SOUNDTRACK_BARBERSHOP,
		ST_NPC_LVL,
		true,
		OnBarbershopEvent,
		false
	)

	Soundtrack.MiscEvents.RegisterUpdateScript( -- Cinematic
		SoundtrackMiscDUMMY,
		SOUNDTRACK_CINEMATIC,
		ST_NPC_LVL,
		true,
		OnCinematicEvent,
		false
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- NPC Emote
		SoundtrackMiscDUMMY,
		SOUNDTRACK_NPC_EMOTE,
		"CHAT_MSG_MONSTER_EMOTE",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_NPC_EMOTE)
		end,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- NPC Say
		SoundtrackMiscDUMMY,
		SOUNDTRACK_NPC_SAY,
		"CHAT_MSG_MONSTER_SAY",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_NPC_SAY)
		end,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- NPC Whisper
		SoundtrackMiscDUMMY,
		SOUNDTRACK_NPC_WHISPER,
		"CHAT_MSG_MONSTER_WHISPER",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_NPC_WHISPER)
		end,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- NPC Yell
		SoundtrackMiscDUMMY,
		SOUNDTRACK_NPC_YELL,
		"CHAT_MSG_MONSTER_YELL",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_NPC_YELL)
		end,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Level Up
		SoundtrackMiscDUMMY,
		SOUNDTRACK_LEVEL_UP,
		"PLAYER_LEVEL_UP",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_LEVEL_UP)
		end,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Join Party
		SoundtrackMiscDUMMY,
		SOUNDTRACK_JOIN_PARTY,
		"GROUP_ROSTER_UPDATE",
		ST_SFX_LVL,
		false,
		OnJoinPartyEvent,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Join Raid
		SoundtrackMiscDUMMY,
		SOUNDTRACK_JOIN_RAID,
		"GROUP_ROSTER_UPDATE",
		ST_SFX_LVL,
		false,
		OnJoinRaidEvent,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_PALADIN_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_ROGUE_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_SHAMAN_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_PRIEST_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_DK_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_WARRIOR_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.MiscEvents.RegisterUpdateScript( -- Rogue Stealth
		SoundtrackMiscDUMMY,
		SOUNDTRACK_ROGUE_STEALTH,
		ST_BUFF_LVL,
		true,
		RogueStealthUpdate,
		false
	)

	-- Thanks to zephus67 for the code!
	Soundtrack.MiscEvents.RegisterUpdateScript( -- Stealthed
		SoundtrackMiscDUMMY,
		SOUNDTRACK_STEALTHED,
		ST_AURA_LVL,
		true,
		StealthUpdate,
		false
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Duel Requested
		SoundtrackMiscDUMMY,
		SOUNDTRACK_DUEL_REQUESTED,
		"DUEL_REQUESTED",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_DUEL_REQUESTED)
		end,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Quest Complete
		SoundtrackMiscDUMMY,
		SOUNDTRACK_QUEST_COMPLETE,
		"QUEST_COMPLETE",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_QUEST_COMPLETE)
		end,
		true
	)

	-- Thanks to appakanna for the code
	Soundtrack.MiscEvents.RegisterEventScript( -- Resting
		SoundtrackMiscDUMMY,
		SOUNDTRACK_RESTING,
		"PLAYER_UPDATE_RESTING",
		ST_MINIMAP_LVL,
		true,
		OnRestingEvent,
		false
	)

	-- Thanks to sgtrama!
	Soundtrack.MiscEvents.RegisterEventScript( -- LFG Complete
		SoundtrackMiscDUMMY,
		SOUNDTRACK_LFG_COMPLETE,
		"LFG_COMPLETION_REWARD",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_LFG_COMPLETE)
		end,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- Achievement
		SoundtrackMiscDUMMY,
		SOUNDTRACK_ACHIEVEMENT,
		"ACHIEVEMENT_EARNED",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_ACHIEVEMENT)
		end,
		true
	)

	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRAGONRIDING_RACE, 369968, ST_BUFF_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DK, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_PALADIN, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_PRIEST, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_ROGUE, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_SHAMAN, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_WARRIOR, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_HUNTER, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_EVOKER, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_COMBAT_EVENTS, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_GROUP_EVENTS, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_NPC_EVENTS, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_STATUS_EVENTS, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_HUNTER_CAMO, 90954, ST_BUFF_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_EVOKER_SOAR, 369536, ST_BUFF_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_ROGUE_SPRINT, 2983, ST_BUFF_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_SHAMAN_GHOST_WOLF, 2645, ST_AURA_LVL, true, false)
	Soundtrack.MiscDruid.RegisterEvents()

	LootEvents.RegisterItemGetEventsToMiscFrame()

	Soundtrack_SortEvents(ST_MISC)
end

function Soundtrack.MiscEvents.MiscOnUpdate(_, _)
	if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
		for k, v in pairs(Soundtrack_MiscEvents) do
			if v.eventtype == ST_UPDATE_SCRIPT and SoundtrackEvents_EventHasTracks(ST_MISC, k) then
				v.script()
			end
		end

		LootEvents.OnUpdate()
	end
end

-- MiscEvents
function Soundtrack.MiscEvents.MiscOnEvent(_, event, ...)
	local st_arg1, _, _, _, st_arg5, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ = ...

	if event == "AUCTION_HOUSE_SHOW" then
		Soundtrack.MiscEvents.AuctionHouse = true
	elseif event == "AUCTION_HOUSE_CLOSED" then
		Soundtrack.MiscEvents.AuctionHouse = false
	elseif event == "BANKFRAME_OPENED" then
		Soundtrack.MiscEvents.Bank = true
	elseif event == "BANKFRAME_CLOSED" then
		Soundtrack.MiscEvents.Bank = false
	elseif event == "MERCHANT_SHOW" then
		Soundtrack.MiscEvents.Merchant = true
	elseif event == "MERCHANT_CLOSED" then
		Soundtrack.MiscEvents.Merchant = false
	elseif event == "TAXIMAP_OPENED" then
		Soundtrack.MiscEvents.FlightMaster = true
	elseif event == "TAXIMAP_CLOSED" then
		Soundtrack.MiscEvents.FlightMaster = false
	elseif event == "BARBER_SHOP_OPEN" then
		Soundtrack.MiscEvents.Barbershop = true
	elseif event == "BARBER_SHOP_CLOSE" then
		Soundtrack.MiscEvents.Barbershop = false
	elseif event == "CINEMATIC_START" then
		Soundtrack.MiscEvents.Cinematic = true
	elseif event == "CINEMATIC_STOP" then
		Soundtrack.MiscEvents.Cinematic = false
	elseif event == "TRAINER_SHOW" then
		Soundtrack.MiscEvents.Trainer = true
	elseif event == "TRAINER_CLOSED" then
		Soundtrack.MiscEvents.Trainer = false
	elseif event == "CHAT_MSG_LOOT" then
		LootEvents.HandleLootMessageEvent(st_arg1, st_arg5)
	end
end

-- TODO: Make sure shapeshift events works this way
function Soundtrack.MiscEvents.OnPlayerAurasUpdated()
	if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
		for k, v in pairs(Soundtrack_MiscEvents) do
			if v.spellId ~= 0 and SoundtrackEvents_EventHasTracks(ST_MISC, k) then
				local isActive = Soundtrack.Auras.IsAuraActive(v.spellId)
				if not v.active and isActive then
					v.active = true
					Soundtrack_Misc_PlayEvent(k)
				elseif v.active and not isActive then
					v.active = false
					Soundtrack_Misc_StopEvent(k)
				end
			end
		end
	end
end
