Soundtrack.StealthEvents = {}

local function RogueStealthUpdate()
	local class = UnitClass("player")
	if Soundtrack.Misc.WasStealthed and not IsStealthed() and class == "Rogue" then
		Soundtrack.Misc.StopEvent(SOUNDTRACK_ROGUE_STEALTH)
		Soundtrack.Misc.WasStealthed = false
	elseif not Soundtrack.Misc.WasStealthed and IsStealthed() and class == "Rogue" then
		if Soundtrack.Auras.IsAuraActive(1784) then
			Soundtrack.Misc.PlayEvent(SOUNDTRACK_ROGUE_STEALTH)
			Soundtrack.Misc.WasStealthed = true
		end
	end
end

local function StealthUpdate()
	if Soundtrack.Misc.WasStealthed and not IsStealthed() then
		Soundtrack.Misc.StopEvent(SOUNDTRACK_STEALTHED)
		Soundtrack.Misc.WasStealthed = false
	elseif not Soundtrack.Misc.WasStealthed and IsStealthed() then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_STEALTHED)
		Soundtrack.Misc.WasStealthed = true
	end
end

function Soundtrack.StealthEvents.Register()
	Soundtrack.Misc.RegisterUpdateScript( -- Rogue Stealth
		SoundtrackMiscDUMMY,
		SOUNDTRACK_ROGUE_STEALTH,
		ST_BUFF_LVL,
		true,
		RogueStealthUpdate,
		false
	)

	-- Thanks to zephus67 for the code!
	Soundtrack.Misc.RegisterUpdateScript( -- Stealthed
		SoundtrackMiscDUMMY,
		SOUNDTRACK_STEALTHED,
		ST_AURA_LVL,
		true,
		StealthUpdate,
		false
	)
end
