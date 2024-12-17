Soundtrack.DruidEvents = {}

local function DruidTravelFormUpdate()
	local buff = Soundtrack.Auras.IsAuraActive(783)
	local canFly = IsFlyableArea()
	local isSwimming = IsSwimming()
	if buff == 783 then
		if isSwimming then
			Soundtrack.Misc.PlayEvent(SOUNDTRACK_DRUID_AQUATIC)
		elseif canFly then
			Soundtrack.Misc.PlayEvent(SOUNDTRACK_DRUID_FLIGHT)
		else
			Soundtrack.Misc.PlayEvent(SOUNDTRACK_DRUID_TRAVEL)
		end
	else
		Soundtrack.Misc.StopEvent(SOUNDTRACK_DRUID_AQUATIC)
		Soundtrack.Misc.StopEvent(SOUNDTRACK_DRUID_FLIGHT)
		Soundtrack.Misc.StopEvent(SOUNDTRACK_DRUID_TRAVEL)
	end
end

local function OnDruidProwlEvent()
	local class = UnitClass("player")
	if Soundtrack.Misc.WasStealthed and not IsStealthed() and class == "Druid" then
		Soundtrack.Misc.StopEvent(SOUNDTRACK_DRUID_PROWL)
		Soundtrack.Misc.WasStealthed = false
	elseif not Soundtrack.Misc.WasStealthed and IsStealthed() and class == "Druid" then
		if Soundtrack.Auras.IsAuraActive(5215) then
			Soundtrack.Misc.PlayEvent(SOUNDTRACK_DRUID_PROWL)
			Soundtrack.Misc.WasStealthed = true
		end
	end
end

function Soundtrack.DruidEvents.Register()
	Soundtrack.Misc.RegisterUpdateScript( -- Druid Prowl
		SoundtrackMiscDUMMY,
		SOUNDTRACK_DRUID_PROWL,
		ST_BUFF_LVL,
		true,
		OnDruidProwlEvent,
		false
	)

	Soundtrack.Misc.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_DRUID_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		Soundtrack.ClassEvents.OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.Misc.RegisterUpdateScript(
		SoundtrackMiscDUMMY,
		SOUNDTRACK_DRUID_TRAVEL,
		ST_AURA_LVL,
		true,
		DruidTravelFormUpdate,
		false
	)

	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID, 0, 1, false, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID_DASH, 1850, ST_BUFF_LVL, true, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID_TIGER_DASH, 252216, ST_BUFF_LVL, true, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID_CAT, 768, ST_AURA_LVL, true, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID_BEAR, 5487, ST_AURA_LVL, true, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID_MOONKIN, 24858, ST_AURA_LVL, true, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID_AQUATIC, 0, ST_AURA_LVL, true, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID_FLIGHT, 0, ST_AURA_LVL, true, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_TREE, 33891, ST_BUFF_LVL, true, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_BEAR, 102558, ST_BUFF_LVL, true, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_CAT, 102543, ST_BUFF_LVL, true, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_DRUID_INCARNATION_MOONKIN, 102560, ST_BUFF_LVL, true, false)
end
