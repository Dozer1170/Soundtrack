--[[
    Soundtrack addon for World of Warcraft

    Misc events functions.
    Functions that manage misc. and custom events.
]]

-- TODO: Should break out the actual event registration to more organized chunks

Soundtrack.MiscEvents = {}
Soundtrack.ActionHouse = false
Soundtrack.Bank = false
Soundtrack.Merchant = false
Soundtrack.FlightMaster = false
Soundtrack.Barbershop = false
Soundtrack.Trainer = false
Soundtrack.CurrentStance = 0
Soundtrack.ActiveAuras = {}

local ST_CLASS_STEALTH

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
	if SNDCUSTOM_IsSwimming == nil then
		SNDCUSTOM_IsSwimming = false
	end

	if SNDCUSTOM_IsSwimming and not IsSwimming() then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_SWIMMING)
		SNDCUSTOM_IsSwimming = false
	elseif not SNDCUSTOM_IsSwimming and IsSwimming() then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_SWIMMING)
		SNDCUSTOM_IsSwimming = true
	end
end

local function OnAuctionHouseEvent()
	if SNDCUSTOM_AuctionHouse == nil then
		SNDCUSTOM_AuctionHouse = false
	end

	if SNDCUSTOM_AuctionHouse and not Soundtrack.AuctionHouse then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_AUCTION_HOUSE)
		SNDCUSTOM_AuctionHouse = false
	elseif not SNDCUSTOM_AuctionHouse and Soundtrack.AuctionHouse then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_AUCTION_HOUSE)
		SNDCUSTOM_AuctionHouse = true
	end
end

local function OnBankEvent()
	if SNDCUSTOM_Bank == nil then
		SNDCUSTOM_Bank = false
	end

	-- Soundtrack.* does not deal with localization
	if SNDCUSTOM_Bank and not Soundtrack.Bank then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_BANK)
		SNDCUSTOM_Bank = false
	elseif not SNDCUSTOM_Bank and Soundtrack.Bank then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_BANK)
		SNDCUSTOM_Bank = true
	end
end

local function OnMerchantEvent()
	if SNDCUSTOM_Merchant == nil then
		SNDCUSTOM_Merchant = false
	end

	if SNDCUSTOM_Merchant and not Soundtrack.Merchant then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_MERCHANT)
		SNDCUSTOM_Merchant = false
	elseif not SNDCUSTOM_Merchant and Soundtrack.Merchant then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_MERCHANT)
		SNDCUSTOM_Merchant = true
	end
end

local function OnFlightMasterEvent()
	if SNDCUSTOM_FlightMaster == nil then
		SNDCUSTOM_FlightMaster = false
	end

	if SNDCUSTOM_FlightMaster and not Soundtrack.FlightMaster then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_FLIGHTMASTER)
		SNDCUSTOM_FlightMaster = false
	elseif not SNDCUSTOM_FlightMaster and Soundtrack.FlightMaster then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_FLIGHTMASTER)
		SNDCUSTOM_FlightMaster = true
	end
end

local function OnTrainerEvent()
	if SNDCUSTOM_Trainer == nil then
		SNDCUSTOM_Trainer = false
	end

	if SNDCUSTOM_Trainer and not Soundtrack.Trainer then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_TRAINER)
		SNDCUSTOM_Trainer = false
	elseif not SNDCUSTOM_Trainer and Soundtrack.Trainer then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_TRAINER)
		SNDCUSTOM_Trainer = true
	end
end

local function OnBarbershopEvent()
	if SNDCUSTOM_Barbershop == nil then
		SNDCUSTOM_Barbershop = false
	end

	if SNDCUSTOM_Barbershop and not Soundtrack.Barbershop then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_BARBERSHOP)
		SNDCUSTOM_Barbershop = false
	elseif not SNDCUSTOM_Barbershop and Soundtrack.Barbershop then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_BARBERSHOP)
		SNDCUSTOM_Barbershop = true
	end
end

local function OnCinematicEvent()
	if SNDCUSTOM_Cinematic == nil then
		SNDCUSTOM_Cinematic = false
	end

	if SNDCUSTOM_Cinematic and not Soundtrack.Cinematic then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_CINEMATIC)
		SNDCUSTOM_Cinematic = false
	elseif not SNDCUSTOM_Cinematic and Soundtrack.Cinematic then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_CINEMATIC)
		SNDCUSTOM_Cinematic = true
	end
end

local function OnJoinPartyEvent()
	if SOUNDTRACK_InParty == nil then
		SOUNDTRACK_InParty = false
	end
	if not SOUNDTRACK_InParty and GetNumSubgroupMembers() == 0 and GetNumSubgroupMembers() > 0 then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_JOIN_PARTY)
		SOUNDTRACK_InParty = true
	elseif SOUNDTRACK_InParty and GetNumSubgroupMembers() == 0 then
		SOUNDTRACK_InParty = false
	end
end

local function OnJoinRaidEvent()
	if SOUNDTRACK_InRaid == nil then
		SOUNDTRACK_InRaid = false
	end
	if not SOUNDTRACK_InRaid and GetNumSubgroupMembers() > 0 then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_JOIN_RAID)
		SOUNDTRACK_InRaid = true
	elseif SOUNDTRACK_InRaid and not GetNumSubgroupMembers() == 0 then
		SOUNDTRACK_InRaid = false
	end
end

local function OnDruidProwlEvent()
	local class = UnitClass("player")
	if ST_CLASS_STEALTH == nil then
		ST_CLASS_STEALTH = false
	end
	if ST_CLASS_STEALTH and not IsStealthed() and class == "Druid" then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_DRUID_PROWL)
		ST_CLASS_STEALTH = false
	elseif not ST_CLASS_STEALTH and IsStealthed() and class == "Druid" then
		if Soundtrack.MiscEvents.IsAuraActive(5215) then
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_DRUID_PROWL)
			ST_CLASS_STEALTH = true
		end
	end
end

function OnChangeShapeshiftEvent()
	local class = UnitClass("player")
	local stance = GetShapeshiftForm()
	if class == "Death Knight" and stance ~= 0 and stance ~= Soundtrack.CurrentStance then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_DK_CHANGE)
		Soundtrack.CurrentStance = stance
	elseif class == "Druid" and stance ~= 0 and stance ~= Soundtrack.CurrentStance then
		Soundtrack_Misc_PlayEvent("Misc", SOUNDTRACK_DRUID_CHANGE)
		Soundtrack.CurrentStance = stance
	elseif class == "Druid" and stance == 0 and stance ~= Soundtrack.CurrentStance then
		Soundtrack.CurrentStance = stance
	elseif class == "Paladin" and stance ~= 0 and stance ~= Soundtrack.CurrentStance then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_PALADIN_CHANGE)
		Soundtrack.CurrentStance = stance
	elseif class == "Priest" and stance ~= 0 then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_PRIEST_CHANGE)
		Soundtrack.CurrentStance = stance
	elseif class == "Rogue" and stance ~= 0 and stance ~= 2 and not IsStealthed() then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_ROGUE_CHANGE)
		Soundtrack.CurrentStance = stance
	elseif class == "Shaman" and stance ~= 0 then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_SHAMAN_CHANGE)
		Soundtrack.CurrentStance = stance
	elseif class == "Warrior" and stance ~= 0 and stance ~= Soundtrack.CurrentStance then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_WARRIOR_CHANGE)
		Soundtrack.CurrentStance = stance
	end
end

local function RogueStealthUpdate()
	local class = UnitClass("player")
	if ST_CLASS_STEALTH == nil then
		ST_CLASS_STEALTH = false
	end
	if ST_CLASS_STEALTH and not IsStealthed() and class == "Rogue" then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_ROGUE_STEALTH)
		ST_CLASS_STEALTH = false
	elseif not ST_CLASS_STEALTH and IsStealthed() and class == "Rogue" then
		if Soundtrack.MiscEvents.IsAuraActive(1784) then
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_ROGUE_STEALTH)
			ST_CLASS_STEALTH = true
		end
	end
end

local function StealthUpdate()
	if SNDCUSTOM_IsStealthed == nil then
		SNDCUSTOM_IsStealthed = false
	end
	if SNDCUSTOM_IsStealthed and not IsStealthed() then
		Soundtrack_Misc_StopEvent(SOUNDTRACK_STEALTHED)
		SNDCUSTOM_IsStealthed = false
	elseif not SNDCUSTOM_IsStealthed and IsStealthed() then
		Soundtrack_Misc_PlayEvent(SOUNDTRACK_STEALTHED)
		SNDCUSTOM_IsStealthed = true
	end
end

local function DruidTravelFormUpdate()
	local buff = Soundtrack.MiscEvents.IsAuraActive(783)
	--local isFlying = IsFlying()
	local canFly = IsFlyableArea()
	local isSwimming = IsSwimming()
	if buff == 783 then
		if isSwimming then
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_DRUID_AQUATIC)
		elseif canFly then
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_DRUID_FLIGHT)
		else
			Soundtrack_Misc_PlayEvent(SOUNDTRACK_DRUID_TRAVEL)
		end
	else
		Soundtrack_Misc_StopEvent(SOUNDTRACK_DRUID_AQUATIC)
		Soundtrack_Misc_StopEvent(SOUNDTRACK_DRUID_FLIGHT)
		Soundtrack_Misc_StopEvent(SOUNDTRACK_DRUID_TRAVEL)
	end
end

function Soundtrack.MiscEvents.RegisterUpdateScript(_, name, _priority, _continuous, _script, _soundEffect)
	if not name then
		return
	end

	Soundtrack_MiscEvents[name] = {
		script = _script,
		eventtype = "Update Script",
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
		eventtype = "Event Script",
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	self:RegisterEvent(_trigger)
	Soundtrack.AddEvent(ST_MISC, name, _priority, _continuous, _soundEffect)
end

-- TODO: Dedupe this, custom also has it
function Soundtrack.MiscEvents.UpdateActiveAuras()
	Soundtrack.ActiveAuras = {}
	for i = 1, 40 do
		local buff = C_UnitAuras.GetBuffDataByIndex("player", i)
		if buff ~= nil then
			Soundtrack.ActiveAuras[buff.spellId] = buff.spellId
		end
		local debuff = C_UnitAuras.GetDebuffDataByIndex("player", i)
		if debuff ~= nil then
			Soundtrack.ActiveAuras[debuff.spellId] = debuff.spellId
		end
	end
end --]]

-- Returns the spellID of the buff, else nil
function Soundtrack.MiscEvents.IsAuraActive(spellId)
	return Soundtrack.ActiveAuras[spellId]
end

function Soundtrack.MiscEvents.RegisterBuffEvent(eventName, _spellId, _priority, _continuous, _soundEffect)
	if not eventName then
		return
	end

	Soundtrack_MiscEvents[eventName] = {
		spellId = _spellId,
		stackLevel = _priority,
		active = false,
		eventtype = "Buff",
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	Soundtrack.AddEvent(ST_MISC, eventName, _priority, _continuous, _soundEffect)
end

function Soundtrack_Misc_PlayEvent(eventName)
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

-- MiscEvents
function Soundtrack.MiscEvents.MiscInitialize()
	debug("Initializing misc. events...")

	SoundtrackMiscDUMMY:RegisterEvent("UNIT_AURA")
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

	-- Add fixed custom events
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

	Soundtrack.MiscEvents.RegisterUpdateScript( -- Druid Prowl
		SoundtrackMiscDUMMY,
		SOUNDTRACK_DRUID_PROWL,
		ST_BUFF_LVL,
		true,
		OnDruidProwlEvent,
		false
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
		SOUNDTRACK_DRUID_CHANGE,
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

	Soundtrack.MiscEvents.RegisterUpdateScript(
		SoundtrackMiscDUMMY,
		SOUNDTRACK_DRUID_TRAVEL,
		ST_AURA_LVL,
		true,
		DruidTravelFormUpdate,
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

	Soundtrack.MiscEvents.RegisterEventScript( -- Resting, thanks to appakanna for the code
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
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID, 0, 1, false, false)
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
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_DASH, 1850, ST_BUFF_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_TIGER_DASH, 252216, ST_BUFF_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_CAT, 768, ST_AURA_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_BEAR, 5487, ST_AURA_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_MOONKIN, 24858, ST_AURA_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_AQUATIC, 0, ST_AURA_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_FLIGHT, 0, ST_AURA_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_TREE, 33891, ST_BUFF_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_BEAR, 102558, ST_BUFF_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_CAT, 102543, ST_BUFF_LVL, true, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_MOONKIN, 102560, ST_BUFF_LVL, true, false)

	LootEvents.RegisterItemGetEventsToMiscFrame()

	Soundtrack_SortEvents(ST_MISC)
end

function Soundtrack.MiscEvents.MiscOnUpdate(_, _)
	if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
		for k, v in pairs(Soundtrack_MiscEvents) do
			if v.eventtype == "Update Script" and SoundtrackEvents_EventHasTracks(ST_MISC, k) then
				v.script()
			end
		end

		LootEvents.OnUpdate()
	end
end

-- MiscEvents
function Soundtrack.MiscEvents.MiscOnEvent(_, event, ...)
	local st_arg1, _, _, _, st_arg5, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ = ...

	Soundtrack.MiscEvents.UpdateActiveAuras()

	if event == "AUCTION_HOUSE_SHOW" then
		Soundtrack.AuctionHouse = true
	elseif event == "AUCTION_HOUSE_CLOSED" then
		Soundtrack.AuctionHouse = false
	elseif event == "BANKFRAME_OPENED" then
		Soundtrack.Bank = true
	elseif event == "BANKFRAME_CLOSED" then
		Soundtrack.Bank = false
	elseif event == "MERCHANT_SHOW" then
		Soundtrack.Merchant = true
	elseif event == "MERCHANT_CLOSED" then
		Soundtrack.Merchant = false
	elseif event == "TAXIMAP_OPENED" then
		Soundtrack.FlightMaster = true
	elseif event == "TAXIMAP_CLOSED" then
		Soundtrack.FlightMaster = false
	elseif event == "BARBER_SHOP_OPEN" then
		Soundtrack.Barbershop = true
	elseif event == "BARBER_SHOP_CLOSE" then
		Soundtrack.Barbershop = false
	elseif event == "CINEMATIC_START" then
		Soundtrack.Cinematic = true
	elseif event == "CINEMATIC_STOP" then
		Soundtrack.Cinematic = false
	elseif event == "TRAINER_SHOW" then
		Soundtrack.Trainer = true
	elseif event == "TRAINER_CLOSED" then
		Soundtrack.Trainer = false
	elseif event == "CHAT_MSG_LOOT" then
		LootEvents.HandleLootMessageEvent(st_arg1, st_arg5)
	-- Handle buff/debuff events
	elseif (event == "UNIT_AURA" and st_arg1 == "player") or event == "UPDATE_SHAPESHIFT_FORM" then
		if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
			for k, v in pairs(Soundtrack_MiscEvents) do
				if v.spellId ~= 0 and SoundtrackEvents_EventHasTracks(ST_MISC, k) then
					local isActive = Soundtrack.MiscEvents.IsAuraActive(v.spellId)
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

	-- Handle custom script events
	if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
		for k, v in pairs(Soundtrack_MiscEvents) do
			if v.eventtype == "Event Script" and event == v.trigger and SoundtrackEvents_EventHasTracks(ST_MISC, k) then
				v.script()
			end
		end
	end
end
