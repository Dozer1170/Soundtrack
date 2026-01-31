if not Tests then
  return
end

local Tests = Tests("Soundtrack", "PLAYER_ENTERING_WORLD")

-- Base Misc Module Tests
function Tests:RegisterUpdateScript_ValidName_RegistersScript()
  Soundtrack_MiscEvents = {}
  local registered = false
  Replace(Soundtrack, "AddEvent", function()
    registered = true
  end)

  Soundtrack.Misc.RegisterUpdateScript(nil, "TestScript", ST_ONCE_LVL, false, "test_function", false)

  AreEqual(true, Soundtrack_MiscEvents["TestScript"] ~= nil)
  AreEqual(true, registered)
end

function Tests:RegisterUpdateScript_ValidName_SetCorrectEventType()
  Soundtrack_MiscEvents = {}

  Soundtrack.Misc.RegisterUpdateScript(nil, "TestScript", ST_ONCE_LVL, false, "test_function", false)

  AreEqual(ST_UPDATE_SCRIPT, Soundtrack_MiscEvents["TestScript"].eventtype)
end

function Tests:RegisterUpdateScript_NoName_DoesNotRegister()
  Soundtrack_MiscEvents = {}

  Soundtrack.Misc.RegisterUpdateScript(nil, nil, ST_ONCE_LVL, false, "test_function", false)

  IsFalse(Soundtrack_MiscEvents["nil"])
end

function Tests:RegisterEventScript_ValidName_RegistersScript()
  Soundtrack_MiscEvents = {}
  local registered = false
  Replace(Soundtrack, "AddEvent", function()
    registered = true
  end)

  Soundtrack.Misc.RegisterEventScript({ RegisterEvent = function() end }, "TestEvent", "UNIT_SPELLCAST_SUCCEEDED",
    ST_ONCE_LVL, false, "test_function", false)

  AreEqual(true, Soundtrack_MiscEvents["TestEvent"] ~= nil)
  AreEqual(true, registered)
end

function Tests:RegisterEventScript_ValidName_SetCorrectEventType()
  Soundtrack_MiscEvents = {}
  local self = { RegisterEvent = function() end }

  Soundtrack.Misc.RegisterEventScript(self, "TestEvent", "UNIT_SPELLCAST_SUCCEEDED", ST_ONCE_LVL, false, "test_function",
    false)

  AreEqual(ST_EVENT_SCRIPT, Soundtrack_MiscEvents["TestEvent"].eventtype)
end

function Tests:RegisterBuffEvent_ValidName_RegistersBuffEvent()
  Soundtrack_MiscEvents = {}
  local registered = false
  Replace(Soundtrack, "AddEvent", function()
    registered = true
  end)

  Soundtrack.Misc.RegisterBuffEvent("TestBuff", 1234, ST_ONCE_LVL, false, false)

  AreEqual(true, Soundtrack_MiscEvents["TestBuff"] ~= nil)
  AreEqual(true, registered)
end

function Tests:Initialize_AddsAllMiscEventsToDatabase()
  local eventCount = 0
  Replace(Soundtrack, "AddEvent", function()
    eventCount = eventCount + 1
  end)
  Replace(SoundtrackAddon.db, "profile", {
    settings = {
      EnableMiscMusic = true
    }
  })
  Soundtrack_MiscEvents = {}

  Soundtrack.Misc.Initialize()

  AreEqual(true, eventCount > 0)
end

-- Misc Submodule Tests (Auras, ClassEvents, DruidEvents, LootEvents, NpcEvents, PlayerStatusEvents, StealthEvents)
local function ResetMisc()
  Soundtrack.Misc.PlayedEvents = {}
  Soundtrack.Misc.StoppedEvents = {}
  Soundtrack.Misc.WasStealthed = false
  Soundtrack.ClassEvents.CurrentStance = 0
end

local function ListContains(list, value)
  for _, item in ipairs(list) do
    if item == value then
      return true
    end
  end
  return false
end

local function EnsureDruidLocalization()
  if SOUNDTRACK_DRUID_PROWL ~= "" then
    return
  end

  local originalGetSpellName = SoundtrackLocalization.GetSpellName
  local spellNames = {
    [5215] = "Prowl",
    [783] = "Travel Form",
    [768] = "Cat Form",
    [5487] = "Bear Form",
    [24858] = "Moonkin Form",
    [1850] = "Dash",
    [33943] = "Flight Form",
    [276029] = "Flight Form",
    [1066] = "Aquatic Form",
    [276012] = "Aquatic Form",
    [252216] = "Tiger Dash",
    [33891] = "Incarnation: Tree of Life",
    [102558] = "Incarnation: Guardian of Ursoc",
    [102543] = "Incarnation: King of the Jungle",
    [102560] = "Incarnation: Chosen of Elune",
  }

  SoundtrackLocalization.GetSpellName = function(spellId)
    return spellNames[spellId]
  end

  SoundtrackLocalization.RegisterDruidStrings("Druid", "Change Form")
  SoundtrackLocalization.GetSpellName = originalGetSpellName
end

function Tests:ClassEvents_OnChangeShapeshift_TriggersDruidChange()
  ResetMisc()

  Replace("UnitClass", function()
    return "Druid"
  end)

  local stance = 0
  Replace("GetShapeshiftForm", function()
    stance = stance + 1
    return stance
  end)

  Soundtrack.ClassEvents.OnChangeShapeshiftEvent()

  AreEqual(SOUNDTRACK_DRUID_CHANGE, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
  AreEqual(1, Soundtrack.ClassEvents.CurrentStance)
end

function Tests:ClassEvents_OnChangeShapeshift_TriggersRogueChange()
  ResetMisc()

  Replace("UnitClass", function()
    return "Rogue"
  end)

  Replace("GetShapeshiftForm", function()
    return 1
  end)

  Replace("IsStealthed", function()
    return false
  end)

  Soundtrack.ClassEvents.OnChangeShapeshiftEvent()

  AreEqual(SOUNDTRACK_ROGUE_CHANGE, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
end

function Tests:ClassEvents_OnChangeShapeshift_ResetsDruidStance()
  ResetMisc()

  Replace("UnitClass", function()
    return "Druid"
  end)

  Replace("GetShapeshiftForm", function()
    return 0
  end)

  Soundtrack.ClassEvents.CurrentStance = 2
  Soundtrack.ClassEvents.OnChangeShapeshiftEvent()

  AreEqual(0, Soundtrack.ClassEvents.CurrentStance)
end

function Tests:DruidEvents_Register_AddsBuffEvents()
  ResetMisc()
  EnsureDruidLocalization()

  Soundtrack.Misc.UpdateScripts = {}
  Soundtrack.Misc.EventScripts = {}
  Soundtrack_MiscEvents = {}

  Soundtrack.DruidEvents.Register()

  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_DRUID], "druid event should be added")
  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_DRUID_DASH], "druid dash event should be added")
  IsTrue(Soundtrack.Misc.UpdateScripts[SOUNDTRACK_DRUID_PROWL], "druid prowl update script should be added")
end

function Tests:DruidEvents_TravelForm_PlaysCorrectEvent()
  ResetMisc()
  EnsureDruidLocalization()

  Soundtrack.Misc.UpdateScripts = {}
  Soundtrack.DruidEvents.Register()

  Replace(Soundtrack.Auras, "IsAuraActive", function()
    return 783
  end)

  Replace("IsSwimming", function() return true end)
  Replace("IsFlyableArea", function() return false end)

  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_DRUID_TRAVEL].script()
  AreEqual(SOUNDTRACK_DRUID_AQUATIC, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Replace("IsSwimming", function() return false end)
  Replace("IsFlyableArea", function() return true end)

  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_DRUID_TRAVEL].script()
  AreEqual(SOUNDTRACK_DRUID_FLIGHT, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Replace("IsFlyableArea", function() return false end)
  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_DRUID_TRAVEL].script()
  AreEqual(SOUNDTRACK_DRUID_TRAVEL, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
end

function Tests:DruidEvents_TravelForm_StopsWhenAuraMissing()
  ResetMisc()
  EnsureDruidLocalization()

  Soundtrack.Misc.UpdateScripts = {}
  Soundtrack.DruidEvents.Register()

  Replace(Soundtrack.Auras, "IsAuraActive", function()
    return nil
  end)

  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_DRUID_TRAVEL].script()

  AreEqual(SOUNDTRACK_DRUID_TRAVEL, Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])
end

function Tests:DruidEvents_Prowl_StopsWhenLeavingStealth()
  ResetMisc()
  EnsureDruidLocalization()

  Soundtrack.Misc.UpdateScripts = {}
  Soundtrack.DruidEvents.Register()

  Replace("UnitClass", function() return "Druid" end)
  Replace("IsStealthed", function() return false end)
  Soundtrack.Misc.WasStealthed = true

  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_DRUID_PROWL].script()

  AreEqual(SOUNDTRACK_DRUID_PROWL, Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])
end

function Tests:DruidEvents_Prowl_StartsWhenEnteringStealth()
  ResetMisc()
  EnsureDruidLocalization()

  Soundtrack.Misc.UpdateScripts = {}
  Soundtrack.DruidEvents.Register()

  Replace("UnitClass", function() return "Druid" end)
  Replace("IsStealthed", function() return true end)
  Replace(Soundtrack.Auras, "IsAuraActive", function()
    return 5215
  end)
  Soundtrack.Misc.WasStealthed = false

  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_DRUID_PROWL].script()

  AreEqual(SOUNDTRACK_DRUID_PROWL, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
end

function Tests:LootEvents_OnEvent_QueuesPlayEvent()
  ResetMisc()

  Replace("UnitName", function()
    return "Player"
  end)

  Replace("GetItemInfo", function()
    return nil, nil, 2, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
  end)

  local now = 0
  Replace("GetTime", function()
    now = now + 0.6
    return now
  end)

  local lootString = "You receive loot: |cffffffff|Hitem:12345:0:0:0:0:0:0:0|h[Test Item]|h|r"
  Soundtrack.LootEvents.OnEvent("CHAT_MSG_LOOT", lootString, "Player")
  Soundtrack.LootEvents.OnUpdate()

  AreEqual(SOUNDTRACK_ITEM_GET_UNCOMMON, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
end

function Tests:LootEvents_OnEvent_IgnoresNonLootEvent()
  ResetMisc()

  Soundtrack.LootEvents.OnEvent("SOME_EVENT", "loot", "Player")
  Soundtrack.LootEvents.OnUpdate()

  IsTrue(#Soundtrack.Misc.PlayedEvents == 0)
end

function Tests:LootEvents_OnEvent_IgnoresSecretValue()
  ResetMisc()

  Replace("issecretvalue", function() return true end)
  Soundtrack.LootEvents.OnEvent("CHAT_MSG_LOOT", "secret", "Player")
  Soundtrack.LootEvents.OnUpdate()

  IsTrue(#Soundtrack.Misc.PlayedEvents == 0)
end

function Tests:LootEvents_OnEvent_IgnoresMissingItemLink()
  ResetMisc()

  Replace("issecretvalue", function() return false end)
  Soundtrack.LootEvents.OnEvent("CHAT_MSG_LOOT", "No item here", "Player")
  Soundtrack.LootEvents.OnUpdate()

  IsTrue(#Soundtrack.Misc.PlayedEvents == 0)
end

function Tests:LootEvents_OnEvent_IgnoresOtherPlayerLoot()
  ResetMisc()

  Replace("UnitName", function() return "Player" end)
  Replace("issecretvalue", function() return false end)
  Replace("GetItemInfo", function()
    return nil, nil, 5, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
  end)

  local lootString = "OtherPlayer receives loot: |cffffffff|Hitem:12345:0:0:0:0:0:0:0|h[Test Item]|h|r"
  Soundtrack.LootEvents.OnEvent("CHAT_MSG_LOOT", lootString, "OtherPlayer")
  Soundtrack.LootEvents.OnUpdate()

  IsTrue(#Soundtrack.Misc.PlayedEvents == 0)
end

function Tests:LootEvents_OnEvent_PlaysLegendary()
  ResetMisc()

  Replace("UnitName", function() return "Player" end)
  Replace("issecretvalue", function() return false end)
  Replace("GetItemInfo", function()
    return nil, nil, 5, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
  end)

  local now = 0
  Replace("GetTime", function()
    now = now + 1
    return now
  end)

  local lootString = "You receive loot: |cffffffff|Hitem:12345:0:0:0:0:0:0:0|h[Test Item]|h|r"
  Soundtrack.LootEvents.OnEvent("CHAT_MSG_LOOT", lootString, "Player")
  Soundtrack.LootEvents.OnUpdate()

  AreEqual(SOUNDTRACK_ITEM_GET_LEGENDARY, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
end

function Tests:NpcEvents_Register_AddsAllNpcEvents()
  ResetMisc()

  Soundtrack_MiscEvents = {}
  Soundtrack.NpcEvents.Register()

  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_NPC_EMOTE], "NPC emote event should be added")
  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_NPC_SAY], "NPC say event should be added")
  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_NPC_WHISPER], "NPC whisper event should be added")
  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_NPC_YELL], "NPC yell event should be added")
end

function Tests:NpcEvents_OnEvent_TriggersNpcYell()
  ResetMisc()

  Soundtrack_MiscEvents = {}
  Soundtrack.NpcEvents.Register()

  Soundtrack.Misc.OnEvent(nil, "CHAT_MSG_MONSTER_YELL")

  AreEqual(SOUNDTRACK_NPC_YELL, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
end

function Tests:PlayerStatusEvents_OnEvent_TogglesMerchant()
  ResetMisc()

  -- Enable misc music and register player status events
  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Soundtrack.PlayerStatusEvents.Register()

  -- Add a track so the update script runs
  local eventTable = Soundtrack.Events.GetTable(ST_MISC)
  eventTable[SOUNDTRACK_MERCHANT].tracks = { "dummy_track.mp3" }

  Soundtrack.PlayerStatusEvents.OnEvent("MERCHANT_SHOW")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_MERCHANT, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Soundtrack.PlayerStatusEvents.OnEvent("MERCHANT_CLOSED")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_MERCHANT, Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])
end

function Tests:PlayerStatusEvents_Resting_TogglesPlayAndStop()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Replace("GetZoneText", function() return "Elwynn Forest" end)
  Replace("IsResting", function() return true end)

  Soundtrack.PlayerStatusEvents.Register()
  Soundtrack.Misc.OnEvent(nil, "PLAYER_UPDATE_RESTING")

  AreEqual(SOUNDTRACK_RESTING, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Replace("GetZoneText", function() return "Stormwind City" end)
  Replace("IsResting", function() return false end)

  Soundtrack.Misc.OnEvent(nil, "PLAYER_UPDATE_RESTING")

  AreEqual(SOUNDTRACK_RESTING, Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])
end

function Tests:PlayerStatusEvents_Swimming_TogglesPlayAndStop()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Soundtrack.PlayerStatusEvents.Register()

  Replace("IsSwimming", function() return true end)
  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_SWIMMING].script()
  AreEqual(SOUNDTRACK_SWIMMING, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Replace("IsSwimming", function() return false end)
  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_SWIMMING].script()
  AreEqual(SOUNDTRACK_SWIMMING, Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])
end

function Tests:PlayerStatusEvents_AuctionHouse_TogglesPlayAndStop()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Soundtrack.PlayerStatusEvents.Register()

  local eventTable = Soundtrack.Events.GetTable(ST_MISC)
  eventTable[SOUNDTRACK_AUCTION_HOUSE].tracks = { "dummy_track.mp3" }

  Soundtrack.PlayerStatusEvents.OnEvent("AUCTION_HOUSE_SHOW")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_AUCTION_HOUSE, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Soundtrack.PlayerStatusEvents.OnEvent("AUCTION_HOUSE_CLOSED")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_AUCTION_HOUSE, Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])
end

function Tests:PlayerStatusEvents_FlightMaster_TogglesPlayAndStop()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Soundtrack.PlayerStatusEvents.Register()

  local eventTable = Soundtrack.Events.GetTable(ST_MISC)
  eventTable[SOUNDTRACK_FLIGHTMASTER].tracks = { "dummy_track.mp3" }

  Soundtrack.PlayerStatusEvents.OnEvent("TAXIMAP_OPENED")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_FLIGHTMASTER, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Soundtrack.PlayerStatusEvents.OnEvent("TAXIMAP_CLOSED")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_FLIGHTMASTER, Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])
end

function Tests:PlayerStatusEvents_Trainer_TogglesPlayAndStop_NonRetail()
  ResetMisc()

  local previousRetail = IsRetail
  IsRetail = false

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Soundtrack.PlayerStatusEvents.Register()

  local eventTable = Soundtrack.Events.GetTable(ST_MISC)
  eventTable[SOUNDTRACK_TRAINER].tracks = { "dummy_track.mp3" }

  Soundtrack.PlayerStatusEvents.OnEvent("TRAINER_SHOW")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_TRAINER, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Soundtrack.PlayerStatusEvents.OnEvent("TRAINER_CLOSED")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_TRAINER, Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])

  IsRetail = previousRetail
end

function Tests:PlayerStatusEvents_Barbershop_TogglesPlayAndStop_Retail()
  ResetMisc()

  local previousRetail = IsRetail
  IsRetail = true

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Soundtrack.PlayerStatusEvents.Register()

  local eventTable = Soundtrack.Events.GetTable(ST_MISC)
  eventTable[SOUNDTRACK_BARBERSHOP].tracks = { "dummy_track.mp3" }

  Soundtrack.PlayerStatusEvents.OnEvent("BARBER_SHOP_OPEN")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_BARBERSHOP, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Soundtrack.PlayerStatusEvents.OnEvent("BARBER_SHOP_CLOSE")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_BARBERSHOP, Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])

  IsRetail = previousRetail
end

function Tests:PlayerStatusEvents_Cinematic_TogglesPlayAndStop()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Soundtrack.PlayerStatusEvents.Register()

  local eventTable = Soundtrack.Events.GetTable(ST_MISC)
  eventTable[SOUNDTRACK_CINEMATIC].tracks = { "dummy_track.mp3" }

  Soundtrack.PlayerStatusEvents.OnEvent("CINEMATIC_START")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_CINEMATIC, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Soundtrack.PlayerStatusEvents.OnEvent("CINEMATIC_STOP")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_CINEMATIC, Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])
end

function Tests:PlayerStatusEvents_JoinParty_BothBranches()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  local originalRegisterEventScript = Soundtrack.Misc.RegisterEventScript
  local joinPartyScript = nil

  Replace(Soundtrack.Misc, "RegisterEventScript", function(self, name, trigger, priority, continuous, script, soundEffect)
    if name == SOUNDTRACK_JOIN_PARTY then
      joinPartyScript = script
    end
    return originalRegisterEventScript(self, name, trigger, priority, continuous, script, soundEffect)
  end)

  Soundtrack.PlayerStatusEvents.Register()

  local function setPlayerStatusField(value)
    for i = 1, 10 do
      local upName, upValue = debug.getupvalue(joinPartyScript, i)
      if upName == "PlayerStatus" then
        upValue.WasInParty = value
        return upValue
      end
    end
  end

  local calls = 0
  Replace("GetNumSubgroupMembers", function()
    calls = calls + 1
    if calls == 1 then
      return 0
    end
    return 1
  end)

  joinPartyScript()
  IsTrue(ListContains(Soundtrack.Misc.PlayedEvents, SOUNDTRACK_JOIN_PARTY))

  Replace("GetNumSubgroupMembers", function() return 0 end)
  local status = setPlayerStatusField(true)
  joinPartyScript()
  IsTrue(status.WasInParty == false)
end

function Tests:PlayerStatusEvents_OnEvent_TogglesBank()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Soundtrack.PlayerStatusEvents.Register()

  local eventTable = Soundtrack.Events.GetTable(ST_MISC)
  eventTable[SOUNDTRACK_BANK].tracks = { "dummy_track.mp3" }

  Soundtrack.PlayerStatusEvents.OnEvent("BANKFRAME_OPENED")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_BANK, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Soundtrack.PlayerStatusEvents.OnEvent("BANKFRAME_CLOSED")
  Soundtrack.Misc.OnUpdate()
  AreEqual(SOUNDTRACK_BANK, Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])
end

function Tests:PlayerStatusEvents_GroupRosterUpdate_TriggersRaid()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Soundtrack.PlayerStatusEvents.Register()

  Replace("GetNumSubgroupMembers", function() return 1 end)
  Soundtrack.Misc.OnEvent(nil, "GROUP_ROSTER_UPDATE")

  AreEqual(SOUNDTRACK_JOIN_RAID, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
end

function Tests:PlayerStatusEvents_GroupRosterUpdate_ClearsRaidFlag()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true

  local originalRegisterEventScript = Soundtrack.Misc.RegisterEventScript
  local joinRaidScript = nil

  Replace(Soundtrack.Misc, "RegisterEventScript", function(self, name, trigger, priority, continuous, script, soundEffect)
    if name == SOUNDTRACK_JOIN_RAID then
      joinRaidScript = script
    end
    return originalRegisterEventScript(self, name, trigger, priority, continuous, script, soundEffect)
  end)

  Soundtrack.PlayerStatusEvents.Register()

  for i = 1, 10 do
    local upName, upValue = debug.getupvalue(joinRaidScript, i)
    if upName == "PlayerStatus" then
      upValue.WasInRaid = true
      break
    end
  end

  Replace("GetNumSubgroupMembers", function() return 0 end)
  joinRaidScript()

  for i = 1, 10 do
    local upName, upValue = debug.getupvalue(joinRaidScript, i)
    if upName == "PlayerStatus" then
      IsTrue(upValue.WasInRaid == false)
      break
    end
  end
end

function Tests:PlayerStatusEvents_JumpPlaysEventWhenTracksExist()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Replace(Soundtrack.Events, "EventHasTracks", function()
    return true
  end)
  Replace("HasFullControl", function() return true end)
  Replace("IsFlying", function() return false end)
  Replace("IsSwimming", function() return false end)
  Replace("UnitInVehicle", function() return false end)
  Replace("GetTime", function() return 1 end)

  Soundtrack.PlayerStatusEvents.Register()

  AreEqual(SOUNDTRACK_JUMP, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
end

function Tests:PlayerStatusEvents_MythicPlusCompletionBranches()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Replace(C_ChallengeMode, "GetChallengeCompletionInfo", function()
    return { onTime = true }
  end)

  Soundtrack.PlayerStatusEvents.Register()
  Soundtrack.Misc.OnEvent(nil, "CHALLENGE_MODE_COMPLETED")

  AreEqual(SOUNDTRACK_MYTHIC_PLUS_COMPLETE_TIMED, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])

  Replace(C_ChallengeMode, "GetChallengeCompletionInfo", function()
    return { onTime = false }
  end)

  Soundtrack.Misc.OnEvent(nil, "CHALLENGE_MODE_COMPLETED")
  AreEqual(SOUNDTRACK_MYTHIC_PLUS_COMPLETE_OVER_TIME, Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
end

function Tests:StealthEvents_Register_SetsUpdateScripts()
  ResetMisc()

  Soundtrack.Misc.UpdateScripts = {}
  Soundtrack.StealthEvents.Register()

  IsTrue(Soundtrack.Misc.UpdateScripts[SOUNDTRACK_ROGUE_STEALTH], "rogue stealth update script should be added")
  IsTrue(Soundtrack.Misc.UpdateScripts[SOUNDTRACK_STEALTHED], "stealthed update script should be added")
end

function Tests:StealthEvents_Update_TriggersStealthAndRogueStealth()
  ResetMisc()

  Soundtrack.Misc.UpdateScripts = {}
  Soundtrack.StealthEvents.Register()

  Replace("UnitClass", function() return "Rogue" end)
  Replace("IsStealthed", function() return true end)

  Soundtrack.Misc.WasStealthed = false
  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_STEALTHED].script()

  Replace(Soundtrack.Auras, "IsAuraActive", function()
    return 1784
  end)

  Soundtrack.Misc.WasStealthed = false
  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_ROGUE_STEALTH].script()

  IsTrue(ListContains(Soundtrack.Misc.PlayedEvents, SOUNDTRACK_STEALTHED))
  IsTrue(ListContains(Soundtrack.Misc.PlayedEvents, SOUNDTRACK_ROGUE_STEALTH))
end

function Tests:StealthEvents_Update_StopsOnExit()
  ResetMisc()

  Soundtrack.Misc.UpdateScripts = {}
  Soundtrack.StealthEvents.Register()

  Replace("IsStealthed", function() return false end)
  Replace("UnitClass", function() return "Rogue" end)

  Soundtrack.Misc.WasStealthed = true
  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_ROGUE_STEALTH].script()

  Soundtrack.Misc.WasStealthed = true
  Soundtrack.Misc.UpdateScripts[SOUNDTRACK_STEALTHED].script()

  IsTrue(ListContains(Soundtrack.Misc.StoppedEvents, SOUNDTRACK_ROGUE_STEALTH))
  IsTrue(ListContains(Soundtrack.Misc.StoppedEvents, SOUNDTRACK_STEALTHED))
end

function Tests:Misc_OnUpdate_RunsUpdateScriptsWhenEnabled()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Soundtrack_MiscEvents = {
    TestUpdate = { eventtype = ST_UPDATE_SCRIPT, script = function()
      Soundtrack.Misc.PlayEvent("TestUpdate")
    end }
  }

  Replace(Soundtrack.Events, "EventHasTracks", function()
    return true
  end)
  Replace(Soundtrack.LootEvents, "OnUpdate", function()
    Soundtrack.Misc.PlayEvent("LootUpdate")
  end)
  Replace(Soundtrack.MountEvents, "OnUpdate", function()
    Soundtrack.Misc.PlayEvent("MountUpdate")
  end)

  Soundtrack.Misc.OnUpdate()

  AreEqual("MountUpdate", Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
end

function Tests:Misc_OnEvent_TriggersEventScriptsAndSubmodules()
  ResetMisc()

  local scriptCalled = false
  Soundtrack_MiscEvents = {
    ScriptEvent = { trigger = "CHAT_MSG_LOOT", script = function() scriptCalled = true end }
  }

  Replace(Soundtrack.PlayerStatusEvents, "OnEvent", function()
    Soundtrack.Misc.PlayEvent("PlayerStatusEvent")
  end)
  Replace(Soundtrack.LootEvents, "OnEvent", function()
    Soundtrack.Misc.PlayEvent("LootEvent")
  end)

  Soundtrack.Misc.OnEvent(nil, "CHAT_MSG_LOOT", "loot", "player")

  IsTrue(scriptCalled, "Event script executed")
  AreEqual("LootEvent", Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
end

function Tests:Misc_OnPlayerAurasUpdated_TogglesAuraEvents()
  ResetMisc()

  SoundtrackAddon.db.profile.settings.EnableMiscMusic = true
  Soundtrack_MiscEvents = {
    AuraEvent = { spellId = 123, active = false }
  }

  Replace(Soundtrack.Events, "EventHasTracks", function()
    return true
  end)

  Replace(Soundtrack.Auras, "IsAuraActive", function()
    return true
  end)

  Soundtrack.Misc.OnPlayerAurasUpdated()

  Replace(Soundtrack.Auras, "IsAuraActive", function()
    return false
  end)

  Soundtrack.Misc.OnPlayerAurasUpdated()

  AreEqual("AuraEvent", Soundtrack.Misc.StoppedEvents[#Soundtrack.Misc.StoppedEvents])
end
