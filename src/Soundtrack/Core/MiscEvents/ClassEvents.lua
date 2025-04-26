Soundtrack.ClassEvents = {}
Soundtrack.ClassEvents.CurrentStance = 0

function Soundtrack.ClassEvents.OnChangeShapeshiftEvent()
	local class = UnitClass("player")
	local stance = GetShapeshiftForm()
	if class == "Death Knight" and stance ~= 0 and stance ~= Soundtrack.ClassEvents.CurrentStance then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_DK_CHANGE)
		Soundtrack.ClassEvents.CurrentStance = stance
	elseif class == "Druid" and stance ~= 0 and stance ~= Soundtrack.ClassEvents.CurrentStance then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_DRUID_CHANGE)
		Soundtrack.ClassEvents.CurrentStance = stance
	elseif class == "Druid" and stance == 0 and stance ~= Soundtrack.ClassEvents.CurrentStance then
		Soundtrack.ClassEvents.CurrentStance = stance
	elseif class == "Paladin" and stance ~= 0 and stance ~= Soundtrack.ClassEvents.CurrentStance then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_PALADIN_CHANGE)
		Soundtrack.ClassEvents.CurrentStance = stance
	elseif class == "Priest" and stance ~= 0 then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_PRIEST_CHANGE)
		Soundtrack.ClassEvents.CurrentStance = stance
	elseif class == "Rogue" and stance ~= 0 and stance ~= 2 and not IsStealthed() then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_ROGUE_CHANGE)
		Soundtrack.ClassEvents.CurrentStance = stance
	elseif class == "Shaman" and stance ~= 0 then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_SHAMAN_CHANGE)
		Soundtrack.ClassEvents.CurrentStance = stance
	elseif class == "Warrior" and stance ~= 0 and stance ~= Soundtrack.ClassEvents.CurrentStance then
		Soundtrack.Misc.PlayEvent(SOUNDTRACK_WARRIOR_CHANGE)
		Soundtrack.ClassEvents.CurrentStance = stance
	end
end

function Soundtrack.ClassEvents.Register()
	Soundtrack.DruidEvents.Register()

	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_PALADIN, 0, 1, false, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_PRIEST, 0, 1, false, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_ROGUE, 0, 1, false, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_SHAMAN, 0, 1, false, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_WARRIOR, 0, 1, false, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_HUNTER, 0, 1, false, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_ROGUE_SPRINT, 2983, ST_BUFF_LVL, true, false)

	if IsRetail then
		Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_EVOKER, 0, 1, false, false)
		Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_HUNTER_CAMO, 90954, ST_BUFF_LVL, true, false)
		Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_EVOKER_SOAR, 369536, ST_BUFF_LVL, true, false)
	end

	Soundtrack.Misc.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_DK_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.Misc.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_PALADIN_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.Misc.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_PRIEST_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.Misc.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_ROGUE_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.Misc.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_SHAMAN_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)

	Soundtrack.Misc.RegisterEventScript( -- Update shapeshift form
		SoundtrackMiscDUMMY,
		SOUNDTRACK_WARRIOR_CHANGE,
		"UPDATE_SHAPESHIFT_FORM",
		ST_SFX_LVL,
		false,
		OnChangeShapeshiftEvent,
		true
	)
end
