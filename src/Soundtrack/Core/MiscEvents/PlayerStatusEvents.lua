Soundtrack.PlayerStatusEvents = {}

local PlayerStatus = {}
PlayerStatus.IsInAuctionHouse = false
PlayerStatus.WasInAuctionHouse = false

PlayerStatus.IsInBank = false
PlayerStatus.WasInBank = false

PlayerStatus.IsAtMerchant = false
PlayerStatus.WasAtMerchant = false

PlayerStatus.IsOnFlightPath = false
PlayerStatus.WasOnFlightPath = false

PlayerStatus.IsAtBarbershop = false
PlayerStatus.WasAtBarbershop = false

PlayerStatus.IsAtTrainer = false
PlayerStatus.WasAtTrainer = false

PlayerStatus.WasStealthed = false
PlayerStatus.WasSwimming = false
PlayerStatus.WasInCinematic = false
PlayerStatus.WasInParty = false
PlayerStatus.WasInRaid = false

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
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_RESTING)
	else
		Soundtrack.Misc.StopEvent(SOUNDTRACK_RESTING)
	end
end

local function OnJump()
	local jumpDelayTime = 0
	local jumpUpdateTime = 0.7
	if HasFullControl() and not IsFlying() and not IsSwimming() and not UnitInVehicle("player") then
		local currentTime = GetTime()
		if currentTime >= jumpDelayTime then
			jumpDelayTime = currentTime + jumpUpdateTime
			if Soundtrack.Events.EventHasTracks(ST_MISC, SOUNDTRACK_JUMP) then
				Soundtrack.Misc.PlayEvent(SOUNDTRACK_JUMP)
			end
		end
	end
end

local function OnSwimmingEvent()
	if PlayerStatus.WasSwimming and not IsSwimming() then
		Soundtrack.Misc.StopEvent(SOUNDTRACK_SWIMMING)
		PlayerStatus.WasSwimming = false
	elseif not PlayerStatus.WasSwimming and IsSwimming() then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_SWIMMING)
		PlayerStatus.WasSwimming = true
	end
end

local function OnAuctionHouseEvent()
	if PlayerStatus.WasInAuctionHouse and not PlayerStatus.AuctionHouse then
		Soundtrack.Misc.StopEvent(SOUNDTRACK_AUCTION_HOUSE)
		PlayerStatus.WasInAuctionHouse = false
	elseif not PlayerStatus.WasInAuctionHouse and PlayerStatus.AuctionHouse then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_AUCTION_HOUSE)
		PlayerStatus.WasInAuctionHouse = true
	end
end

local function OnBankEvent()
	-- Soundtrack.* does not deal with localization
	if PlayerStatus.WasInBank and not PlayerStatus.IsInBank then
		Soundtrack.Misc.StopEvent(SOUNDTRACK_BANK)
		PlayerStatus.WasInBank = false
	elseif not PlayerStatus.WasInBank and PlayerStatus.IsInBank then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_BANK)
		PlayerStatus.WasInBank = true
	end
end

local function OnMerchantEvent()
	if PlayerStatus.WasAtMerchant and not PlayerStatus.IsAtMerchant then
		Soundtrack.Misc.StopEvent(SOUNDTRACK_MERCHANT)
		PlayerStatus.WasAtMerchant = false
	elseif not PlayerStatus.WasAtMerchant and PlayerStatus.IsAtMerchant then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_MERCHANT)
		PlayerStatus.WasAtMerchant = true
	end
end

local function OnFlightMasterEvent()
	if PlayerStatus.WasOnFlightPath and not PlayerStatus.IsOnFlightPath then
		Soundtrack.Misc.StopEvent(SOUNDTRACK_FLIGHTMASTER)
		PlayerStatus.WasOnFlightPath = false
	elseif not PlayerStatus.WasOnFlightPath and PlayerStatus.IsOnFlightPath then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_FLIGHTMASTER)
		PlayerStatus.WasOnFlightPath = true
	end
end

local function OnTrainerEvent()
	if PlayerStatus.WasAtTrainer and not PlayerStatus.IsAtTrainer then
		Soundtrack.Misc.StopEvent(SOUNDTRACK_TRAINER)
		PlayerStatus.WasAtTrainer = false
	elseif not PlayerStatus.WasAtTrainer and PlayerStatus.IsAtTrainer then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_TRAINER)
		PlayerStatus.WasAtTrainer = true
	end
end

local function OnBarbershopEvent()
	if PlayerStatus.WasAtBarbershop and not PlayerStatus.IsAtBarbershop then
		Soundtrack.Misc.StopEvent(SOUNDTRACK_BARBERSHOP)
		PlayerStatus.WasAtBarbershop = false
	elseif not PlayerStatus.WasAtBarbershop and PlayerStatus.IsAtBarbershop then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_BARBERSHOP)
		PlayerStatus.WasAtBarbershop = true
	end
end

local function OnCinematicEvent()
	if PlayerStatus.WasInCinematic and not PlayerStatus.Cinematic then
		Soundtrack.Misc.StopEvent(SOUNDTRACK_CINEMATIC)
		PlayerStatus.WasInCinematic = false
	elseif not PlayerStatus.WasInCinematic and PlayerStatus.Cinematic then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_CINEMATIC)
		PlayerStatus.WasInCinematic = true
	end
end

local function OnJoinPartyEvent()
	if not PlayerStatus.WasInParty and GetNumSubgroupMembers() == 0 and GetNumSubgroupMembers() > 0 then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_JOIN_PARTY)
		Soundtrack.Misc.WasInParty = true
	elseif PlayerStatus.WasInParty and GetNumSubgroupMembers() == 0 then
		PlayerStatus.WasInParty = false
	end
end

local function OnJoinRaidEvent()
	if not PlayerStatus.WasInRaid and GetNumSubgroupMembers() > 0 then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_JOIN_RAID)
		PlayerStatus.WasInRaid = true
	elseif PlayerStatus.WasInRaid and not GetNumSubgroupMembers() == 0 then
		PlayerStatus.WasInRaid = false
	end
end

function Soundtrack.PlayerStatusEvents.Register()
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

	if IsRetail then
		Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRAGONRIDING_RACE, 369968, ST_BUFF_LVL, true, false)

		Soundtrack.Misc.RegisterUpdateScript( -- Barbershop
			SoundtrackMiscDUMMY,
			SOUNDTRACK_BARBERSHOP,
			ST_NPC_LVL,
			true,
			OnBarbershopEvent,
			false
		)
	else
		Soundtrack.Misc.RegisterUpdateScript( -- Trainer
			SoundtrackMiscDUMMY,
			SOUNDTRACK_TRAINER,
			ST_NPC_LVL, -- TODO Anthony: This conflicts with battle level, was 6
			true,
			OnTrainerEvent,
			false
		)
	end

	Soundtrack.Misc.RegisterUpdateScript( -- Swimming
		SoundtrackMiscDUMMY,
		SOUNDTRACK_SWIMMING,
		ST_STATUS_LVL,
		true,
		OnSwimmingEvent,
		false
	)

	Soundtrack.Misc.RegisterUpdateScript( -- Auction House
		SoundtrackMiscDUMMY,
		SOUNDTRACK_AUCTION_HOUSE,
		ST_NPC_LVL,
		true,
		OnAuctionHouseEvent,
		false
	)

	Soundtrack.Misc.RegisterUpdateScript( -- Bank
		SoundtrackMiscDUMMY,
		SOUNDTRACK_BANK,
		ST_NPC_LVL,
		true,
		OnBankEvent,
		false
	)

	Soundtrack.Misc.RegisterUpdateScript( -- Merchant
		SoundtrackMiscDUMMY,
		SOUNDTRACK_MERCHANT,
		ST_NPC_LVL, -- TODO Anthony: This conflicts with battle level, was 6
		true,
		OnMerchantEvent,
		false
	)

	Soundtrack.Misc.RegisterUpdateScript( -- FlightMaster
		SoundtrackMiscDUMMY,
		SOUNDTRACK_FLIGHTMASTER,
		ST_NPC_LVL,
		true,
		OnFlightMasterEvent,
		false
	)

	Soundtrack.Misc.RegisterUpdateScript( -- Cinematic
		SoundtrackMiscDUMMY,
		SOUNDTRACK_CINEMATIC,
		ST_NPC_LVL,
		true,
		OnCinematicEvent,
		false
	)

	Soundtrack.Misc.RegisterEventScript( -- Level Up
		SoundtrackMiscDUMMY,
		SOUNDTRACK_LEVEL_UP,
		"PLAYER_LEVEL_UP",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack.Misc.PlayEvent(SOUNDTRACK_LEVEL_UP)
		end,
		true
	)

	Soundtrack.Misc.RegisterEventScript( -- Join Party
		SoundtrackMiscDUMMY,
		SOUNDTRACK_JOIN_PARTY,
		"GROUP_ROSTER_UPDATE",
		ST_SFX_LVL,
		false,
		OnJoinPartyEvent,
		true
	)

	Soundtrack.Misc.RegisterEventScript( -- Join Raid
		SoundtrackMiscDUMMY,
		SOUNDTRACK_JOIN_RAID,
		"GROUP_ROSTER_UPDATE",
		ST_SFX_LVL,
		false,
		OnJoinRaidEvent,
		true
	)

	Soundtrack.Misc.RegisterEventScript( -- Duel Requested
		SoundtrackMiscDUMMY,
		SOUNDTRACK_DUEL_REQUESTED,
		"DUEL_REQUESTED",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack.Misc.PlayEvent(SOUNDTRACK_DUEL_REQUESTED)
		end,
		true
	)

	Soundtrack.Misc.RegisterEventScript( -- Quest Complete
		SoundtrackMiscDUMMY,
		SOUNDTRACK_QUEST_COMPLETE,
		"QUEST_COMPLETE",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack.Misc.PlayEvent(SOUNDTRACK_QUEST_COMPLETE)
		end,
		true
	)

	-- Thanks to appakanna for the code
	Soundtrack.Misc.RegisterEventScript( -- Resting
		SoundtrackMiscDUMMY,
		SOUNDTRACK_RESTING,
		"PLAYER_UPDATE_RESTING",
		ST_MINIMAP_LVL,
		true,
		OnRestingEvent,
		false
	)

	-- Thanks to sgtrama!
	Soundtrack.Misc.RegisterEventScript( -- LFG Complete
		SoundtrackMiscDUMMY,
		SOUNDTRACK_LFG_COMPLETE,
		"LFG_COMPLETION_REWARD",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack.Misc.PlayEvent(SOUNDTRACK_LFG_COMPLETE)
		end,
		true
	)

	Soundtrack.Misc.RegisterEventScript( -- Achievement
		SoundtrackMiscDUMMY,
		SOUNDTRACK_ACHIEVEMENT,
		"ACHIEVEMENT_EARNED",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack.Misc.PlayEvent(SOUNDTRACK_ACHIEVEMENT)
		end,
		true
	)

	Soundtrack.Misc.RegisterEventScript( -- Mythic Plus Start
		SoundtrackMiscDUMMY,
		SOUNDTRACK_MYTHIC_PLUS_START,
		"CHALLENGE_MODE_START",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack.Misc.PlayEvent(SOUNDTRACK_MYTHIC_PLUS_START)
		end,
		false
	)

	Soundtrack.Misc.RegisterEventScript( -- Mythic Plus Complete Timed
		SoundtrackMiscDUMMY,
		SOUNDTRACK_MYTHIC_PLUS_COMPLETE_TIMED,
		"CHALLENGE_MODE_COMPLETED",
		ST_SFX_LVL,
		false,
		function()
			local info = C_ChallengeMode.GetChallengeCompletionInfo()
			if info.onTime then
				Soundtrack.Misc.PlayEvent(SOUNDTRACK_MYTHIC_PLUS_COMPLETE_TIMED)
			end
		end,
		false
	)

	Soundtrack.Misc.RegisterEventScript( -- Mythic Plus Complete Timed
		SoundtrackMiscDUMMY,
		SOUNDTRACK_MYTHIC_PLUS_COMPLETE_OVER_TIME,
		"CHALLENGE_MODE_COMPLETED",
		ST_SFX_LVL,
		false,
		function()
			local info = C_ChallengeMode.GetChallengeCompletionInfo()
			if not info.onTime then
				Soundtrack.Misc.PlayEvent(SOUNDTRACK_MYTHIC_PLUS_COMPLETE_OVER_TIME)
			end
		end,
		false
	)

	hooksecurefunc("JumpOrAscendStart", OnJump)
end

function Soundtrack.PlayerStatusEvents.OnEvent(event)
	if event == "AUCTION_HOUSE_SHOW" then
		PlayerStatus.AuctionHouse = true
	elseif event == "AUCTION_HOUSE_CLOSED" then
		PlayerStatus.AuctionHouse = false
	elseif event == "BANKFRAME_OPENED" then
		PlayerStatus.IsInBank = true
	elseif event == "BANKFRAME_CLOSED" then
		PlayerStatus.IsInBank = false
	elseif event == "MERCHANT_SHOW" then
		PlayerStatus.IsAtMerchant = true
	elseif event == "MERCHANT_CLOSED" then
		PlayerStatus.IsAtMerchant = false
	elseif event == "TAXIMAP_OPENED" then
		PlayerStatus.IsOnFlightPath = true
	elseif event == "TAXIMAP_CLOSED" then
		PlayerStatus.IsOnFlightPath = false
	elseif event == "BARBER_SHOP_OPEN" then
		PlayerStatus.IsAtBarbershop = true
	elseif event == "BARBER_SHOP_CLOSE" then
		PlayerStatus.IsAtBarbershop = false
	elseif event == "CINEMATIC_START" then
		PlayerStatus.Cinematic = true
	elseif event == "CINEMATIC_STOP" then
		PlayerStatus.Cinematic = false
	elseif event == "TRAINER_SHOW" then
		PlayerStatus.IsAtTrainer = true
	elseif event == "TRAINER_CLOSED" then
		PlayerStatus.IsAtTrainer = false
	end
end
