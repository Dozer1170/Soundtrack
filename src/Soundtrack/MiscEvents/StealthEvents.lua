local function RogueStealthUpdate()
	local class = UnitClass("player")
	if Soundtrack.MiscEvents.WasStealthed and not IsStealthed() and class == "Rogue" then
		Soundtrack.MiscEvents.StopEvent(SOUNDTRACK_ROGUE_STEALTH)
		Soundtrack.MiscEvents.WasStealthed = false
	elseif not Soundtrack.MiscEvents.WasStealthed and IsStealthed() and class == "Rogue" then
		if Soundtrack.Auras.IsAuraActive(1784) then
			Soundtrack.MiscEvents.PlayEvent(SOUNDTRACK_ROGUE_STEALTH)
			Soundtrack.MiscEvents.WasStealthed = true
		end
	end
end

local function StealthUpdate()
	if Soundtrack.MiscEvents.WasStealthed and not IsStealthed() then
		Soundtrack.MiscEvents.StopEvent(SOUNDTRACK_STEALTHED)
		Soundtrack.MiscEvents.WasStealthed = false
	elseif not Soundtrack.MiscEvents.WasStealthed and IsStealthed() then
		Soundtrack.MiscEvents.PlayEvent(SOUNDTRACK_STEALTHED)
		Soundtrack.MiscEvents.WasStealthed = true
	end
end

function Soundtrack.StealthEvents.Register()
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
end
