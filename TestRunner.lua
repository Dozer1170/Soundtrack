#!/usr/bin/env lua
-- Standalone test runner with custom harness (no WoWUnit dependency)

-- ---------------------------------------------------------------------
-- Minimal test harness
local allTests = {}
local passed, failed = 0, 0

local function ensureRegisterEvent(self)
  if self and type(self.RegisterEvent) ~= "function" then
    function self:RegisterEvent(evt)
      self._events = self._events or {}
      table.insert(self._events, evt)
    end
  end
end

local WoWUnit = {}
setmetatable(WoWUnit, {
  __call = function(_, addonName, event)
    local testClass = {}
    table.insert(allTests, { name = addonName, event = event, tests = testClass })
    return testClass
  end,
})

function WoWUnit.AreEqual(expected, actual)
  if expected ~= actual then
    print(string.format("    ✗ FAIL: expected %s, got %s", tostring(expected), tostring(actual)))
    failed = failed + 1
    return false
  end
  passed = passed + 1
  return true
end

function WoWUnit.IsFalse(value)
  if value then
    print(string.format("    ✗ FAIL: expected false, got %s", tostring(value)))
    failed = failed + 1
    return false
  end
  passed = passed + 1
  return true
end

function WoWUnit.Exists(value)
  if not value then
    print("    ✗ FAIL: expected truthy value")
    failed = failed + 1
    return false
  end
  passed = passed + 1
  return true
end

function WoWUnit.Replace(target, name, replacement)
  if replacement == nil then
    _G[target] = name
    return
  end

  -- LibStub is now a function, not a table, so handle it differently
  if (target == LibStub or target == "LibStub") and type(name) == "string" then
    -- Tests trying to replace LibStub behavior - skip since we're using real Ace mocks
    return
  end

  if type(target) == "table" and name == "OnLoad" and type(replacement) == "function" then
    target[name] = function(self, ...)
      ensureRegisterEvent(self)
      return replacement(self, ...)
    end
    return
  end

  if type(target) == "table" then
    target[name] = replacement
  end
end

_G.WoWUnit = WoWUnit
_G.AreEqual = WoWUnit.AreEqual
_G.IsFalse = WoWUnit.IsFalse
_G.Exists = WoWUnit.Exists
_G.Replace = WoWUnit.Replace

-- ---------------------------------------------------------------------
-- Global mocks
local function setWoWGlobals()
  _G.UnitExists = function() return false end
  _G.UnitClassification = function() return "normal" end
  _G.UnitIsPlayer = function() return false end
  _G.UnitIsDeadOrGhost = function() return false end
  _G.UnitIsFriend = function() return true end
  _G.UnitCanAttack = function() return false end
  _G.UnitIsBossMob = function() return false end
  _G.UnitCreatureType = function() return nil end
  _G.UnitName = function() return "Player" end
  _G.UnitRace = function() return "Human" end
  _G.UnitSex = function() return 2 end
  _G.UnitClass = function() return "Warrior" end
  _G.GetShapeshiftForm = function() return 0 end
  _G.IsStealthed = function() return false end
  _G.IsFlyableArea = function() return false end
  _G.IsSwimming = function() return false end
  _G.HasFullControl = function() return true end
  _G.UnitInVehicle = function() return false end
  _G.GetNumGroupMembers = function() return 0 end
  _G.GetNumSubgroupMembers = function() return 0 end
  _G.GetTime = function() return 0 end
  _G.UnitOnTaxi = function(unit) return false end
  _G.IsMounted = function() return false end
  _G.IsFlying = function() return false end
  _G.GetRealZoneText = function() return "Zone" end
  _G.GetSubZoneText = function() return "SubZone" end
  _G.GetMinimapZoneText = function() return "Minimap" end
  _G.IsInInstance = function() return false, "none" end
  _G.random = math.random

  _G.C_Map = {
    GetBestMapForUnit = function() return 946 end,
    GetMapInfo = function() return { mapID = 1, name = "TestZone" } end,
    GetMapChildrenInfo = function(mapID, mapType, allDescendants)
      return {}  -- Return empty table for tests
    end
  }

  _G.C_Spell = {
    GetSpellInfo = function(spellId)
      -- Return nil for test environment - localization will handle missing spells
      return nil
    end
  }

  _G.C_UnitAuras = {
    GetBuffDataByIndex = function()
      return nil
    end,
    GetDebuffDataByIndex = function()
      return nil
    end,
  }

  _G.C_ChallengeMode = {
    GetChallengeCompletionInfo = function()
      return { onTime = false }
    end,
  }

  _G.GetItemInfo = function()
    return nil, nil, 0, nil, nil, nil, nil, nil, nil, nil, nil, nil, nil
  end

  _G.hooksecurefunc = function(_, func)
    -- call immediately for tests to simulate hook
    if type(func) == "function" then
      func()
    end
  end

  _G.hooksecurefunc = _G.hooksecurefunc

  _G.JumpOrAscendStart = function() end

  _G.issecretvalue = function()
    return false
  end

  _G.MapUtil = {
    GetMapParentInfo = function(_, level)
      if level == 3 then
        return { name = "Zone" }
      elseif level == 2 then
        return { name = "Continent" }
      end
      return { name = "World" }
    end,
    GetZoneTextByID = function() return "Zone" end,
  }
end

local defaultSettings = {
  EnableBattleMusic = true,
  EnableZoneMusic = true,
  EnableMiscMusic = true,
  EnablePetBattleMusic = true,
  BattleCooldown = 0,
  Silence = 5,
  EscalateBattleMusic = true,
  AutoAddZones = true,
}

local function cloneDefaults()
  local copy = {}
  for k, v in pairs(defaultSettings) do copy[k] = v end
  return copy
end

local function setupSoundtrack()
  -- Load actual Constants, Globals, and Localization from source files
  dofile("src/Soundtrack/Core/Constants.lua")
  dofile("src/Soundtrack/Core/Globals.lua")
  dofile("src/Soundtrack/Core/Localization/SoundtrackLocalization.lua")
  dofile("src/Soundtrack/Core/Localization/Localization.en.lua")
  
  _G.IsRetail = true
  
  _G.Soundtrack_Tracks = {}
  _G.PlayMusic = function(fileName) end
  _G.StopMusic = function() end
  _G.PlaySoundFile = function(fileName, channel) end

  _G.SoundtrackAddon = {
    db = {
      profile = {
        events = {},  -- Event configuration storage
        settings = cloneDefaults(),
      },
    },
  }

  _G.StaticPopupDialogs = {}
  _G.StaticPopup_Show = function() end
  
  -- Mock Ace libraries
  local AceAddon = {
    NewAddon = function(self, name, ...)
      local addon = {
        db = nil,
        RegisterEvent = function() end,
      }
      return addon
    end
  }
  
  local AceDB = {
    New = function(self, dbName, defaults, defaultProfile)
      return {
        profile = defaults and defaults.profile or {
          events = {},
          settings = cloneDefaults()
        }
      }
    end
  }
  
  _G.LibStub = function(libName)
    if libName == "AceAddon-3.0" then
      return AceAddon
    elseif libName == "AceDB-3.0" then
      return AceDB
    elseif libName == "AceEvent-3.0" then
      return { RegisterEvent = function() end }
    end
    return { New = function() return {} end }
  end

  _G.SoundtrackAurasDUMMY = { _events = {} }
  function _G.SoundtrackAurasDUMMY:RegisterEvent(evt)
    self._events[evt] = true
  end

  _G.SoundtrackMiscDUMMY = { _events = {} }
  function _G.SoundtrackMiscDUMMY:RegisterEvent(evt)
    self._events[evt] = true
  end
  
  _G.SoundtrackUI = {
    UpdateTracksUI = function() end,
    UpdateEventsUI = function() end,
    RefreshShowingTab = function() end,
    Initialize = function() end,
    OnEventStackChanged = function() end,
    NowPlayingFrame = {
      SetNowPlayingText = function() end,
    },
    SelectedEventsTable = nil,
    SelectedEvent = nil,
  }

  -- Mock C_AddOns for getting addon metadata
  _G.C_AddOns = {
    GetAddOnMetadata = function(addonName, field)
      if field == "Title" then
        return "Soundtrack"
      end
      return nil
    end
  }
  
  -- Stubs for functions that Soundtrack.lua needs
  _G.SoundtrackMinimap_Initialize = function() end
  _G.SoundtrackFrame_RefreshPlaybackControls = function() end
  _G.Soundtrack_LoadDefaultTracks = function() end
  _G.Soundtrack_LoadMyTracks = nil  -- Intentionally nil to test default behavior

  _G.Soundtrack = {
    Chat = {
      Trace = function() end,
      TraceMisc = function() end,
      TraceBattle = function() end,
      TraceEvents = function() end,
      TraceLibrary = function() end,
      TraceZones = function() end,
      TracePetBattles = function() end,
      TraceFrame = function() end,
      Error = function() end,
      Message = function() end,
      InitDebugChatFrame = function() end,
    },
    RegisteredEvents = {},
    MigrateFromOldSavedVariables = function() end,
    Cleanup = {
      CleanupOldEvents = function() end,
      PurgeOldTracksFromEvents = function() end,
    },
    SortAllEvents = function() end,
    SortTracks = function() end,
  }
  
  -- Lua 5.1 compatibility for table.getn
  if not table.getn then
    table.getn = function(t) return t and #t or 0 end
  end
  
  -- Global functions that source files expect
  _G.getn = function(t) return t and #t or 0 end
  _G.strfind = string.find
  _G.strsub = string.sub
  _G.strlen = string.len
  _G.tinsert = table.insert
  _G.tremove = table.remove
  _G.Enum = {
    MapCanvasPosition = { None = 0, BottomLeft = 1, BottomRight = 2, TopLeft = 3, TopRight = 4 },
    UIMapType = { World = 0, Continent = 1, Zone = 3, Dungeon = 4, Micro = 5, Orphan = 6 }
  }
  _G.C_Map = _G.C_Map or {
    GetMapInfo = function() return { mapType = Enum.UIMapType.Zone } end,
    GetMapChildrenInfo = function(mapID, mapType, allDescendants)
      return {}  -- Return empty table for tests
    end
  }
  _G.C_PetBattles = {
    IsInBattle = function() return false end,
    GetPVPMatchmakingInfo = function() return false end,
    IsWildBattle = function() return false end
  }
  
  -- Global battle functions that tests expect
  _G.GetGroupEnemyClassification = function()
    local classification = "normal"
    local pvpEnabled = false
    local isBoss = false
    
    if UnitExists("playertarget") then
      classification = UnitClassification("playertarget") or "normal"
      if UnitIsBossMob("playertarget") then
        isBoss = true
      end
      if UnitIsPlayer("playertarget") and UnitCanAttack("player", "playertarget") then
        pvpEnabled = true
      end
    end
    
    return classification, pvpEnabled, isBoss
  end
end

-- Helper to load source files
local function loadSourceFile(filepath)
  local file = io.open(filepath, "r")
  if not file then
    print("Error: could not open source file " .. filepath)
    return
  end
  local content = file:read("*a")
  file:close()

  local fn, err = load(content, filepath)
  if not fn then
    print("Error loading source file " .. filepath .. ": " .. err)
    return
  end
  fn()
end

-- Helper to load source files
local function loadSourceFile(filepath)
  local file = io.open(filepath, "r")
  if not file then
    print("Error: could not open source file " .. filepath)
    return
  end
  local content = file:read("*a")
  file:close()

  local fn, err = load(content, filepath)
  if not fn then
    print("Error loading source file " .. filepath .. ": " .. err)
    return
  end
  fn()
end

local function resetState()
  setWoWGlobals()
  setupSoundtrack()
  
  loadSourceFile("src/Soundtrack/Core/Utils/StringUtils.lua")
  loadSourceFile("src/Soundtrack/Core/Utils/Sorting.lua")
  loadSourceFile("src/Soundtrack/Core/Events.lua")
  -- Patch GetTable to auto-create missing tables (for test compatibility)
  local originalGetTable = Soundtrack.Events.GetTable
  Soundtrack.Events.GetTable = function(eventTableName)
    if not eventTableName then
      return nil
    end
    
    -- Ensure profile and events structure exists (for tests that replace profile)
    if not SoundtrackAddon.db.profile then
      SoundtrackAddon.db.profile = { events = {}, settings = cloneDefaults() }
    end
    if not SoundtrackAddon.db.profile.events then
      SoundtrackAddon.db.profile.events = {}
    end
    
    -- Auto-create table if it doesn't exist (for tests)
    if not SoundtrackAddon.db.profile.events[eventTableName] then
      SoundtrackAddon.db.profile.events[eventTableName] = {}
    end
    
    return SoundtrackAddon.db.profile.events[eventTableName]
  end
  
  loadSourceFile("src/Soundtrack/Core/Timers.lua")
  loadSourceFile("src/Soundtrack/Core/Library.lua")
  
  -- Load real Soundtrack.lua for actual implementations
  loadSourceFile("src/Soundtrack/Core/Soundtrack.lua")
  
  -- Initialize SoundtrackAddon to set up db (simulate OnInitialize)
  if SoundtrackAddon and SoundtrackAddon.OnInitialize then
    SoundtrackAddon:OnInitialize()
  end
  
  -- Wrap Soundtrack.PlayEvent to track calls for tests (used by loot events)
  local original_SoundtrackPlayEvent = Soundtrack.PlayEvent
  Soundtrack.PlayEvent = function(tableName, eventName, forceRestart)
    if tableName == ST_MISC then
      table.insert(Soundtrack.Misc.PlayedEvents, eventName)
    end
    if original_SoundtrackPlayEvent then
      return original_SoundtrackPlayEvent(tableName, eventName, forceRestart)
    end
  end
  
  loadSourceFile("src/Soundtrack/Core/Auras/Auras.lua")
  loadSourceFile("src/Soundtrack/Core/Battle/BattleEvents.lua")
  loadSourceFile("src/Soundtrack/Core/Dance/DanceEvents.lua")
  loadSourceFile("src/Soundtrack/Core/MiscEvents/MiscEvents.lua")
  
  -- Add test mocks and legacy functions for Misc module
  if Soundtrack.Misc then
    -- Mock for tracking test state
    Soundtrack.Misc.AurasUpdated = false
    Soundtrack.Misc.PlayedEvents = {}
    Soundtrack.Misc.StoppedEvents = {}
    Soundtrack.Misc.UpdateScripts = {}  -- Track registered update scripts for tests
    
    -- Wrap RegisterUpdateScript to track for tests
    local original_RegisterUpdateScript = Soundtrack.Misc.RegisterUpdateScript
    Soundtrack.Misc.RegisterUpdateScript = function(self, name, priority, continuous, script, soundEffect)
      if name then
        Soundtrack.Misc.UpdateScripts[name] = {
          priority = priority,
          continuous = continuous,
          script = script,
          soundEffect = soundEffect
        }
      end
      if original_RegisterUpdateScript then
        return original_RegisterUpdateScript(self, name, priority, continuous, script, soundEffect)
      end
    end
    
    -- Wrap OnPlayerAurasUpdated to set test flag
    local original_OnPlayerAurasUpdated = Soundtrack.Misc.OnPlayerAurasUpdated
    Soundtrack.Misc.OnPlayerAurasUpdated = function()
      Soundtrack.Misc.AurasUpdated = true
      if original_OnPlayerAurasUpdated then
        original_OnPlayerAurasUpdated()
      end
    end
    
    -- Wrap PlayEvent and StopEvent to track for tests
    local original_PlayEvent = Soundtrack.Misc.PlayEvent
    Soundtrack.Misc.PlayEvent = function(eventName)
      table.insert(Soundtrack.Misc.PlayedEvents, eventName)
      if original_PlayEvent then
        -- Use pcall to prevent errors from unregistered events
        local success, err = pcall(original_PlayEvent, eventName)
        if not success then
          -- Event not registered, that's okay for tests
        end
      end
    end
    
    local original_StopEvent = Soundtrack.Misc.StopEvent
    Soundtrack.Misc.StopEvent = function(eventName)
      table.insert(Soundtrack.Misc.StoppedEvents, eventName)
      if original_StopEvent then
        local success, err = pcall(original_StopEvent, eventName)
        if not success then
          -- Event not registered, that's okay for tests
        end
      end
    end
  end
  
  loadSourceFile("src/Soundtrack/Core/MiscEvents/ClassEvents.lua")
  loadSourceFile("src/Soundtrack/Core/MiscEvents/DruidEvents.lua")
  loadSourceFile("src/Soundtrack/Core/MiscEvents/LootEvents.lua")
  loadSourceFile("src/Soundtrack/Core/MiscEvents/MountEvents.lua")
  loadSourceFile("src/Soundtrack/Core/MiscEvents/NpcEvents.lua")
  loadSourceFile("src/Soundtrack/Core/MiscEvents/PlayerStatusEvents.lua")
  loadSourceFile("src/Soundtrack/Core/MiscEvents/StealthEvents.lua")
  loadSourceFile("src/Soundtrack/Core/PetBattle/PetBattleEvents.lua")
  loadSourceFile("src/Soundtrack/Core/Zones/ZoneEvents.lua")
end

-- Initial bootstrap before loading tests
resetState()

-- ---------------------------------------------------------------------
-- General helpers for test loading
local function loadTestFile(filepath)
  local file = io.open(filepath, "r")
  if not file then
    print("Error: could not open " .. filepath)
    return
  end
  local content = file:read("*a")
  file:close()

  local fn, err = load(content, filepath)
  if not fn then
    print("Error loading " .. filepath .. ": " .. err)
    return
  end
  fn()
end

-- Discover and load tests ---------------------------------------------
local testFiles = {
  "src/Soundtrack/Tests/BattleEventTests.lua",
  "src/Soundtrack/Tests/DanceEventTests.lua",
  "src/Soundtrack/Tests/EventsTests.lua",
  "src/Soundtrack/Tests/AurasTests.lua",
  "src/Soundtrack/Tests/LibraryTests.lua",
  "src/Soundtrack/Tests/MiscEventTests.lua",
  "src/Soundtrack/Tests/MountEventsTests.lua",
  "src/Soundtrack/Tests/PetBattleEventTests.lua",
  "src/Soundtrack/Tests/SoundtrackTests.lua",
  "src/Soundtrack/Tests/StringUtilsTests.lua",
  "src/Soundtrack/Tests/TimersTests.lua",
  "src/Soundtrack/Tests/ZoneEventTests.lua",
}

for _, path in ipairs(testFiles) do
  loadTestFile(path)
end

-- ---------------------------------------------------------------------
-- Run tests
print("=" .. string.rep("=", 68) .. "=")
print("  Lua Test Runner (custom harness)")
print("=" .. string.rep("=", 68) .. "=")
print()

for _, entry in ipairs(allTests) do
  for name, fn in pairs(entry.tests) do
    if type(fn) == "function" and name:match("^[A-Z]") then
      local label = string.format("[%s] %s", entry.name or "", name)
      print(label)
      resetState()
      local ok, err = pcall(fn, entry.tests)
      if not ok then
        failed = failed + 1
        print("    ✗ ERROR: " .. tostring(err))
      end
    end
  end
end

print()
print("=" .. string.rep("=", 68) .. "=")
print(string.format("  Tests: %d passed, %d failed", passed, failed))
print("=" .. string.rep("=", 68) .. "=")

os.exit(failed > 0 and 1 or 0)
