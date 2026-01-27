if not WoWUnit then
  return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

local function resetMocks()
  Soundtrack.Misc.AurasUpdated = false
  Soundtrack.Misc.PlayedEvents = {}
  Soundtrack.Misc.StoppedEvents = {}
  Soundtrack.Auras.ActiveAuras = {}
end

function Tests:Initialize_RegistersUnitAura()
  resetMocks()

  SoundtrackAurasDUMMY._events = {}
  Soundtrack.Auras.Initialize()

  AreEqual(true, SoundtrackAurasDUMMY._events["UNIT_AURA"] ~= nil)
end

function Tests:UpdateActiveAuras_AddsBuffAndDebuff()
  resetMocks()

  local callCount = 0
  Replace(C_UnitAuras, "GetBuffDataByIndex", function(_, idx)
    callCount = callCount + 1
    if idx == 1 then
      return { spellId = 1001 }
    end
    return nil
  end)

  Replace(C_UnitAuras, "GetDebuffDataByIndex", function(_, idx)
    if idx == 1 then
      return { spellId = 2002 }
    end
    return nil
  end)

  Soundtrack.Auras.UpdateActiveAuras()

  AreEqual(1001, Soundtrack.Auras.ActiveAuras[1001])
  AreEqual(2002, Soundtrack.Auras.ActiveAuras[2002])
end

function Tests:UpdateActiveAuras_SkipsSecretValues()
  resetMocks()

  Replace("issecretvalue", function(val)
    return val == 9999
  end)

  Replace(C_UnitAuras, "GetBuffDataByIndex", function(_, idx)
    if idx == 1 then
      return { spellId = 9999 }
    end
    return nil
  end)

  Replace(C_UnitAuras, "GetDebuffDataByIndex", function()
    return nil
  end)

  Soundtrack.Auras.UpdateActiveAuras()

  IsFalse(Soundtrack.Auras.ActiveAuras[9999])
end

function Tests:IsAuraActive_ReturnsValue()
  resetMocks()
  Soundtrack.Auras.ActiveAuras = { [321] = 321 }

  local result = Soundtrack.Auras.IsAuraActive(321)
  AreEqual(321, result)
end

function Tests:OnEvent_PlayerAuraUpdate_TriggersMiscCallback()
  resetMocks()

  Soundtrack.Auras.OnEvent(nil, "UNIT_AURA", "player")

  AreEqual(true, Soundtrack.Misc.AurasUpdated)
end
