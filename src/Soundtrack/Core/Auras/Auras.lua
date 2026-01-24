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

function Soundtrack.Auras.UpdateActiveAuras()
	Soundtrack.Auras.ActiveAuras = {}
	for i = 1, 40 do
		local buff = C_UnitAuras.GetBuffDataByIndex("player", i)
		if buff ~= nil and not issecretvalue(buff.spellId) then
			Soundtrack.Auras.ActiveAuras[buff.spellId] = buff.spellId
		end
		local debuff = C_UnitAuras.GetDebuffDataByIndex("player", i)
		if debuff ~= nil and not issecretvalue(debuff.spellId) then
			Soundtrack.Auras.ActiveAuras[debuff.spellId] = debuff.spellId
		end
	end
end --]]

-- Returns the spellID of the buff, else nil
function Soundtrack.Auras.IsAuraActive(spellId)
	return Soundtrack.Auras.ActiveAuras[spellId]
end
