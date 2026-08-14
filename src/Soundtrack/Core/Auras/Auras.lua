--[[
    Soundtrack addon for World of Warcraft

    Auras functions.
    Functions that manage aura events.
]]

Soundtrack.Auras = {}
Soundtrack.Auras.ActiveAuras = {}

function Soundtrack.Auras.Initialize()
	SoundtrackAurasDUMMY:RegisterEvent("UNIT_AURA")
end

function Soundtrack.Auras.OnEvent(_, event, ...)
	local st_arg1, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ = ...

	Soundtrack.Auras.UpdateActiveAuras()

	if event == "UNIT_AURA" and st_arg1 == "player" then
		Soundtrack.Misc.OnPlayerAurasUpdated()
	end
end

-- Reading aura data while these restrictions are active can hit secret
-- (hidden) auras, which errors and logs a taint violation even inside pcall.
local RESTRICTED_AURA_ACCESS_TYPES = IsRetail and C_RestrictedActions and {
	Enum.AddOnRestrictionType.Combat,
	Enum.AddOnRestrictionType.Encounter,
	Enum.AddOnRestrictionType.ChallengeMode,
	Enum.AddOnRestrictionType.PvPMatch,
}

local function IsAuraAccessRestricted()
	if not RESTRICTED_AURA_ACCESS_TYPES then
		return false
	end
	for _, restrictionType in ipairs(RESTRICTED_AURA_ACCESS_TYPES) do
		if C_RestrictedActions.IsAddOnRestrictionActive(restrictionType) then
			return true
		end
	end
	return false
end

function Soundtrack.Auras.UpdateActiveAuras()
	if IsAuraAccessRestricted() then
		return
	end

	Soundtrack.Auras.ActiveAuras = {}
	for i = 1, 40 do
		local ok, buff = pcall(C_UnitAuras.GetBuffDataByIndex, "player", i)
		if ok and buff ~= nil and not issecretvalue(buff.spellId) then
			Soundtrack.Auras.ActiveAuras[buff.spellId] = buff.spellId
		end
		local ok2, debuff = pcall(C_UnitAuras.GetDebuffDataByIndex, "player", i)
		if ok2 and debuff ~= nil and not issecretvalue(debuff.spellId) then
			Soundtrack.Auras.ActiveAuras[debuff.spellId] = debuff.spellId
		end
	end
end --]]

-- Returns the spellID of the buff, else nil
function Soundtrack.Auras.IsAuraActive(spellId)
	return Soundtrack.Auras.ActiveAuras[spellId]
end
