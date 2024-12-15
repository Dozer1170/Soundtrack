SoundtrackLocalization = {}
SoundtrackLocalization.LOCALIZATION_LOADED = false

function SoundtrackLocalization.GetSpellName(spellId)
	local spellInfo = C_Spell.GetSpellInfo(spellId)
	if spellInfo == nil then
		return nil
	end

	return spellInfo.name
end

function SoundtrackLocalization.CreateSpellNamePath(spellId, path)
	local spellName = SoundtrackLocalization.GetSpellName(spellId)
	if spellName == nil then
		return ""
	end

	return path .. spellName
end

function SoundtrackLocalization.RegisterDruidStrings(localizedClassName, localizedChangeStanceText)
	local druidPath = localizedClassName .. "/"
	SOUNDTRACK_DRUID = localizedClassName
	SOUNDTRACK_DRUID_CHANGE = druidPath .. localizedChangeStanceText

	local retailAquaticFormPath = SoundtrackLocalization.CreateSpellNamePath(276012, druidPath)
	if retailAquaticFormPath ~= "" then
		SOUNDTRACK_DRUID_AQUATIC = retailAquaticFormPath
	else
		SOUNDTRACK_DRUID_AQUATIC = SoundtrackLocalization.CreateSpellNamePath(1066, druidPath)
	end

	local bearFormPath = SoundtrackLocalization.CreateSpellNamePath(5487, druidPath)
	if bearFormPath ~= nil then
		SOUNDTRACK_DRUID_BEAR = bearFormPath
	end

	local catFormPath = SoundtrackLocalization.CreateSpellNamePath(768, druidPath)
	if catFormPath ~= nil then
		SOUNDTRACK_DRUID_CAT = catFormPath
	end

	local dashPath = SoundtrackLocalization.CreateSpellNamePath(1850, druidPath)
	if dashPath ~= nil then
		SOUNDTRACK_DRUID_DASH = dashPath
	end

	local tigerDashPath = SoundtrackLocalization.CreateSpellNamePath(252216, druidPath)
	if tigerDashPath ~= nil then
		SOUNDTRACK_DRUID_TIGER_DASH = tigerDashPath
	end

	local flightFormPath = SoundtrackLocalization.CreateSpellNamePath(276029, druidPath)
	if flightFormPath then
		SOUNDTRACK_DRUID_FLIGHT = flightFormPath
	else
		SOUNDTRACK_DRUID_FLIGHT = SoundtrackLocalization.CreateSpellNamePath(33943, druidPath)
	end

	local moonkinFormPath = SoundtrackLocalization.CreateSpellNamePath(24858, druidPath)
	if moonkinFormPath ~= nil then
		SOUNDTRACK_DRUID_MOONKIN = moonkinFormPath
	end

	local prowlPath = SoundtrackLocalization.CreateSpellNamePath(5215, druidPath)
	if prowlPath ~= nil then
		SOUNDTRACK_DRUID_PROWL = prowlPath
	end

	local travelFormPath = SoundtrackLocalization.CreateSpellNamePath(783, druidPath)
	if travelFormPath ~= nil then
		SOUNDTRACK_DRUID_TRAVEL = travelFormPath
	end

	local incarnTreePath = SoundtrackLocalization.CreateSpellNamePath(33891, druidPath)
	if incarnTreePath ~= nil then
		SOUNDTRACK_DRUID_INCARNATION_TREE = incarnTreePath
	end

	local incarnBearPath = SoundtrackLocalization.CreateSpellNamePath(102558, druidPath)
	if incarnBearPath ~= nil then
		SOUNDTRACK_DRUID_INCARNATION_BEAR = incarnBearPath
	end

	local incarnCatPath = SoundtrackLocalization.CreateSpellNamePath(102543, druidPath)
	if incarnCatPath ~= nil then
		SOUNDTRACK_DRUID_INCARNATION_CAT = incarnCatPath
	end

	local incarnMoonkinPath = SoundtrackLocalization.CreateSpellNamePath(102560, druidPath)
	if incarnMoonkinPath ~= nil then
		SOUNDTRACK_DRUID_INCARNATION_MOONKIN = incarnMoonkinPath
	end
end

function SoundtrackLocalization.RegisterHunterStrings(localizedClassName)
	SOUNDTRACK_HUNTER = localizedClassName
	local camoPath = SoundtrackLocalization.CreateSpellNamePath(90954, localizedClassName .. "/")
	if camoPath ~= nil then
		SOUNDTRACK_HUNTER_CAMO = camoPath
	end
end

function SoundtrackLocalization.RegisterDeathKnightStrings(localizedClassName, localizedChangeStanceText)
	SOUNDTRACK_DK = localizedClassName
	SOUNDTRACK_DK_CHANGE = localizedClassName .. "/" .. localizedChangeStanceText
end

function SoundtrackLocalization.RegisterEvokerStrings(localizedClassName)
	SOUNDTRACK_EVOKER = localizedClassName
	local soarPath = SoundtrackLocalization.CreateSpellNamePath(369536, localizedClassName .. "/")
	if soarPath ~= nil then
		SOUNDTRACK_EVOKER_SOAR = soarPath
	end
end

function SoundtrackLocalization.RegisterPaladinStrings(localizedClassName, localizedChangeStanceText)
	SOUNDTRACK_PALADIN = localizedClassName
	SOUNDTRACK_PALADIN_CHANGE = localizedClassName .. "/" .. localizedChangeStanceText
end

function SoundtrackLocalization.RegisterPriestStrings(localizedClassName, localizedChangeStanceText)
	SOUNDTRACK_PRIEST = localizedClassName
	SOUNDTRACK_PRIEST_CHANGE = localizedClassName .. "/" .. localizedChangeStanceText
end

function SoundtrackLocalization.RegisterRogueStrings(localizedClassName, localizedChangeStanceText)
	local roguePath = localizedClassName .. "/"
	SOUNDTRACK_ROGUE = localizedClassName
	SOUNDTRACK_ROGUE_CHANGE = roguePath .. localizedChangeStanceText
	local sprintPath = SoundtrackLocalization.CreateSpellNamePath(2983, roguePath)
	if sprintPath ~= nil then
		SOUNDTRACK_ROGUE_SPRINT = sprintPath
	end

	local stealthSpellId = 1784
	local stealthPath = SoundtrackLocalization.CreateSpellNamePath(stealthSpellId, roguePath)
	if stealthPath ~= nil then
		SOUNDTRACK_ROGUE_STEALTH = stealthPath
	end
end

function SoundtrackLocalization.RegisterShamanStrings(localizedClassName, localizedChangeStanceText)
	local shamanPath = localizedClassName .. "/"
	SOUNDTRACK_SHAMAN = localizedClassName
	SOUNDTRACK_SHAMAN_CHANGE = shamanPath .. localizedChangeStanceText

	local ghostWolfPath = SoundtrackLocalization.CreateSpellNamePath(2645, shamanPath)
	if ghostWolfPath ~= nil then
		SOUNDTRACK_SHAMAN_GHOST_WOLF = ghostWolfPath
	end
end

function SoundtrackLocalization.RegisterWarriorStrings(localizedClassName, localizedChangeStanceText)
	SOUNDTRACK_WARRIOR = localizedClassName
	SOUNDTRACK_WARRIOR_CHANGE = localizedClassName .. "/" .. localizedChangeStanceText
end

function SoundtrackLocalization.RegisterMageStrings(localizedClassName)
	SOUNDTRACK_MAGE = localizedClassName
end

function SoundtrackLocalization.RegisterMonkStrings(localizedClassName)
	SOUNDTRACK_MONK = localizedClassName
end

function SoundtrackLocalization.RegisterWarlockStrings(localizedClassName)
	SOUNDTRACK_WARLOCK = localizedClassName
end
