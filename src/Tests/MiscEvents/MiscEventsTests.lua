if not WoWUnit then
  return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

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
local function resetMisc()
  Soundtrack.Misc.PlayedEvents = {}
  Soundtrack.Misc.StoppedEvents = {}
  Soundtrack.Misc.WasStealthed = false
  Soundtrack.ClassEvents.CurrentStance = 0
end

local function setConstants()
  SOUNDTRACK_DRUID_CHANGE = "DRUID_CHANGE"
  SOUNDTRACK_DRUID = "DRUID"
  SOUNDTRACK_DRUID_DASH = "DRUID_DASH"
  SOUNDTRACK_DRUID_CAT = "DRUID_CAT"
  SOUNDTRACK_DRUID_BEAR = "DRUID_BEAR"
  SOUNDTRACK_DRUID_MOONKIN = "DRUID_MOONKIN"
  SOUNDTRACK_DRUID_AQUATIC = "DRUID_AQUATIC"
  SOUNDTRACK_DRUID_FLIGHT = "DRUID_FLIGHT"
  SOUNDTRACK_DRUID_TRAVEL = "DRUID_TRAVEL"
  SOUNDTRACK_DRUID_PROWL = "DRUID_PROWL"
  SOUNDTRACK_DK_CHANGE = "DK_CHANGE"
  SOUNDTRACK_PALADIN_CHANGE = "PALADIN_CHANGE"
  SOUNDTRACK_PRIEST_CHANGE = "PRIEST_CHANGE"
  SOUNDTRACK_ROGUE_CHANGE = "ROGUE_CHANGE"
  SOUNDTRACK_SHAMAN_CHANGE = "SHAMAN_CHANGE"
  SOUNDTRACK_WARRIOR_CHANGE = "WARRIOR_CHANGE"
  SOUNDTRACK_PALADIN = "PALADIN"
  SOUNDTRACK_PRIEST = "PRIEST"
  SOUNDTRACK_ROGUE = "ROGUE"
  SOUNDTRACK_SHAMAN = "SHAMAN"
  SOUNDTRACK_WARRIOR = "WARRIOR"
  SOUNDTRACK_HUNTER = "HUNTER"
  SOUNDTRACK_ROGUE_SPRINT = "ROGUE_SPRINT"
  SOUNDTRACK_ROGUE_STEALTH = "ROGUE_STEALTH"
  SOUNDTRACK_STEALTHED = "STEALTHED"
  SOUNDTRACK_EVOKER = "EVOKER"
  SOUNDTRACK_EVOKER_SOAR = "EVOKER_SOAR"
  SOUNDTRACK_HUNTER_CAMO = "HUNTER_CAMO"
  ST_BUFF_LVL = 1
  ST_AURA_LVL = 2
  ST_SFX_LVL = 3
end

local function setMiscConstants()
  SOUNDTRACK_ITEM_GET = "ITEM_GET"
  SOUNDTRACK_ITEM_GET_JUNK = "ITEM_GET_JUNK"
  SOUNDTRACK_ITEM_GET_COMMON = "ITEM_GET_COMMON"
  SOUNDTRACK_ITEM_GET_UNCOMMON = "ITEM_GET_UNCOMMON"
  SOUNDTRACK_ITEM_GET_RARE = "ITEM_GET_RARE"
  SOUNDTRACK_ITEM_GET_EPIC = "ITEM_GET_EPIC"
  SOUNDTRACK_ITEM_GET_LEGENDARY = "ITEM_GET_LEGENDARY"
  SOUNDTRACK_NPC_EMOTE = "NPC_EMOTE"
  SOUNDTRACK_NPC_SAY = "NPC_SAY"
  SOUNDTRACK_NPC_WHISPER = "NPC_WHISPER"
  SOUNDTRACK_NPC_YELL = "NPC_YELL"
  SOUNDTRACK_SWIMMING = "SWIMMING"
  SOUNDTRACK_MERCHANT = "MERCHANT"
end

function Tests:ClassEvents_OnChangeShapeshift_TriggersDruidChange()
  resetMisc()
  setConstants()

  Replace("UnitClass", function()
    return "Druid"
  end)

  local stance = 0
  Replace("GetShapeshiftForm", function()
    stance = stance + 1
    return stance
  end)

  Soundtrack.ClassEvents.OnChangeShapeshiftEvent()

  AreEqual("DRUID_CHANGE", Soundtrack.Misc.PlayedEvents[#Soundtrack.Misc.PlayedEvents])
  AreEqual(1, Soundtrack.ClassEvents.CurrentStance)
end

function Tests:DruidEvents_Register_AddsBuffEvents()
  resetMisc()
  setConstants()

  Soundtrack.Misc.UpdateScripts = {}
  Soundtrack.Misc.EventScripts = {}
  Soundtrack_MiscEvents = {}

  Soundtrack.DruidEvents.Register()

  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_DRUID], "druid event should be added")
  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_DRUID_DASH], "druid dash event should be added")
  IsTrue(Soundtrack.Misc.UpdateScripts[SOUNDTRACK_DRUID_PROWL], "druid prowl update script should be added")
end

function Tests:LootEvents_OnEvent_QueuesPlayEvent()
  resetMisc()

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

function Tests:NpcEvents_Register_AddsAllNpcEvents()
  resetMisc()

  Soundtrack_MiscEvents = {}
  Soundtrack.NpcEvents.Register()

  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_NPC_EMOTE], "NPC emote event should be added")
  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_NPC_SAY], "NPC say event should be added")
  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_NPC_WHISPER], "NPC whisper event should be added")
  IsTrue(Soundtrack_MiscEvents[SOUNDTRACK_NPC_YELL], "NPC yell event should be added")
end

function Tests:PlayerStatusEvents_OnEvent_TogglesMerchant()
  resetMisc()

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

function Tests:StealthEvents_Register_SetsUpdateScripts()
  resetMisc()
  setConstants()

  Soundtrack.Misc.UpdateScripts = {}
  Soundtrack.StealthEvents.Register()

  IsTrue(Soundtrack.Misc.UpdateScripts[SOUNDTRACK_ROGUE_STEALTH], "rogue stealth update script should be added")
  IsTrue(Soundtrack.Misc.UpdateScripts[SOUNDTRACK_STEALTHED], "stealthed update script should be added")
end
