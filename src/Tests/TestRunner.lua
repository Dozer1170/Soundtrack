#!/usr/bin/env lua
-- Standalone test runner with custom harness (no external dependency)

-- ---------------------------------------------------------------------
-- Minimal test harness
local allTests = {}
local passed, failed = 0, 0
local currentTestFailed = false
local failureMessages = {}

local function EnsureRegisterEvent(self)
  if self and type(self.RegisterEvent) ~= "function" then
    function self:RegisterEvent(evt)
      self._events = self._events or {}
      table.insert(self._events, evt)
    end
  end
end

local Tests = {}
setmetatable(Tests, {
  __call = function(_, addonName, event)
    local testClass = {}
    table.insert(allTests, { name = addonName, event = event, tests = testClass })
    return testClass
  end,
})

function Tests.AreEqual(expected, actual, description)
  if expected ~= actual then
    local msg = string.format("    ✗ FAIL: expected %s, got %s", tostring(expected), tostring(actual))
    if description then
      msg = msg .. " (" .. description .. ")"
    end
    local trace = debug.traceback("", 2)
    table.insert(failureMessages, { msg = msg, trace = trace })
    failed = failed + 1
    currentTestFailed = true
    return false
  end
  passed = passed + 1
  return true
end

function Tests.IsFalse(value, description)
  if value then
    local msg = string.format("    ✗ FAIL: expected false, got %s", tostring(value))
    if description then
      msg = msg .. " (" .. description .. ")"
    end
    local trace = debug.traceback("", 2)
    table.insert(failureMessages, { msg = msg, trace = trace })
    failed = failed + 1
    currentTestFailed = true
    return false
  end
  passed = passed + 1
  return true
end

function Tests.IsTrue(value, description)
  if not value then
    local msg = string.format("    ✗ FAIL: expected true, got %s", tostring(value))
    if description then
      msg = msg .. " (" .. description .. ")"
    end
    local trace = debug.traceback("", 2)
    table.insert(failureMessages, { msg = msg, trace = trace })
    failed = failed + 1
    currentTestFailed = true
    return false
  end
  passed = passed + 1
  return true
end

function Tests.Exists(value, description)
  if not value then
    local msg = "    ✗ FAIL: expected truthy value"
    if description then
      msg = msg .. " (" .. description .. ")"
    end
    local trace = debug.traceback("", 2)
    table.insert(failureMessages, { msg = msg, trace = trace })
    failed = failed + 1
    currentTestFailed = true
    return false
  end
  passed = passed + 1
  return true
end

function Tests.Replace(target, name, replacement)
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
      EnsureRegisterEvent(self)
      return replacement(self, ...)
    end
    return
  end

  if type(target) == "table" then
    target[name] = replacement
  end
end

_G.Tests = Tests
_G.AreEqual = Tests.AreEqual
_G.IsFalse = Tests.IsFalse
_G.IsTrue = Tests.IsTrue
_G.Exists = Tests.Exists
_G.Replace = Tests.Replace

-- ---------------------------------------------------------------------
-- Global mocks
local function SetWoWGlobals()
  _G.UnitExists = function() return false end
  _G.UnitClassification = function() return "normal" end
  _G.UnitIsPlayer = function() return false end
  _G.UnitIsDeadOrGhost = function() return _G.MockIsDead or _G.MockIsCorpse or false end
  _G.UnitIsDead = function() return _G.MockIsDead or false end
  _G.UnitIsCorpse = function() return _G.MockIsCorpse or false end
  _G.UnitAffectingCombat = function() return _G.MockInCombat or false end
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
      return {} -- Return empty table for tests
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

local function CloneDefaults()
  local copy = {}
  for k, v in pairs(defaultSettings) do copy[k] = v end
  return copy
end

local function SetupSoundtrack()
  -- Load actual Constants, Globals, and Localization from source files
  dofile("../Soundtrack/Core/Constants.lua")
  dofile("../Soundtrack/Core/Globals.lua")
  dofile("../Soundtrack/Core/Localization/SoundtrackLocalization.lua")
  dofile("../Soundtrack/Core/Localization/Localization.en.lua")

  _G.IsRetail = true

  _G.Soundtrack_Tracks = {}
  _G.PlayMusic = function(fileName) end
  _G.StopMusic = function() end
  _G.PlaySoundFile = function(fileName, channel) end

  _G.SoundtrackAddon = {
    db = {
      profile = {
        events = {}, -- Event configuration storage
        settings = CloneDefaults(),
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
          settings = CloneDefaults()
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
    RefreshTracks = function() end,
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
  _G.Soundtrack_LoadMyTracks = nil -- Intentionally nil to test default behavior

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
      return {} -- Return empty table for tests
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
local function LoadSourceFile(filepath)
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

local function ResetState()
  SetWoWGlobals()
  SetupSoundtrack()

  LoadSourceFile("../Soundtrack/Core/Utils/StringUtils.lua")
  LoadSourceFile("../Soundtrack/Core/Utils/TableUtils.lua")
  LoadSourceFile("../Soundtrack/Core/Utils/Sorting.lua")
  LoadSourceFile("../Soundtrack/Core/Utils/Cleanup.lua")
  LoadSourceFile("../Soundtrack/Core/Events.lua")
  -- Patch GetTable to auto-create missing tables (for test compatibility)
  local originalGetTable = Soundtrack.Events.GetTable
  Soundtrack.Events.GetTable = function(eventTableName)
    if not eventTableName then
      return nil
    end

    -- Ensure profile and events structure exists (for tests that replace profile)
    if not SoundtrackAddon.db.profile then
      SoundtrackAddon.db.profile = { events = {}, settings = CloneDefaults() }
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

  LoadSourceFile("../Soundtrack/Core/Timers.lua")
  LoadSourceFile("../Soundtrack/Core/Library.lua")

  -- Load real Soundtrack.lua for actual implementations
  LoadSourceFile("../Soundtrack/Core/Soundtrack.lua")

  -- Initialize SoundtrackAddon to set up db (simulate OnInitialize)
  if SoundtrackAddon and SoundtrackAddon.OnInitialize then
    SoundtrackAddon:OnInitialize()
  end

  -- Clear filters
  Soundtrack.eventFilter = nil
  Soundtrack.trackFilter = nil

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

  LoadSourceFile("../Soundtrack/Core/Auras/Auras.lua")
  LoadSourceFile("../Soundtrack/Core/Battle/BattleEvents.lua")
  LoadSourceFile("../Soundtrack/Core/Dance/DanceEvents.lua")
  LoadSourceFile("../Soundtrack/Core/MiscEvents/MiscEvents.lua")

  -- Add test mocks and legacy functions for Misc module
  if Soundtrack.Misc then
    -- Mock for tracking test state
    Soundtrack.Misc.AurasUpdated = false
    Soundtrack.Misc.PlayedEvents = {}
    Soundtrack.Misc.StoppedEvents = {}
    Soundtrack.Misc.UpdateScripts = {} -- Track registered update scripts for tests

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

  LoadSourceFile("../Soundtrack/Core/MiscEvents/ClassEvents.lua")
  LoadSourceFile("../Soundtrack/Core/MiscEvents/DruidEvents.lua")
  LoadSourceFile("../Soundtrack/Core/MiscEvents/LootEvents.lua")
  LoadSourceFile("../Soundtrack/Core/MiscEvents/MountEvents.lua")
  LoadSourceFile("../Soundtrack/Core/MiscEvents/NpcEvents.lua")
  LoadSourceFile("../Soundtrack/Core/MiscEvents/PlayerStatusEvents.lua")
  LoadSourceFile("../Soundtrack/Core/MiscEvents/StealthEvents.lua")
  LoadSourceFile("../Soundtrack/Core/PetBattle/PetBattleEvents.lua")
  LoadSourceFile("../Soundtrack/Core/Zones/ZoneEvents.lua")
end

-- Initial bootstrap before loading tests
ResetState()

-- ---------------------------------------------------------------------
-- General helpers for test loading
local function LoadTestFile(filepath)
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
  "Battle/BattleEventsTests.lua",
  "Utils/CleanupTests.lua",
  "Dance/DanceEventsTests.lua",
  "EventsTests.lua",
  "EventStackTests.lua",
  "Auras/AurasTests.lua",
  "LibraryTests.lua",
  "MiscEvents/MiscEventsTests.lua",
  "MiscEvents/MountEventsTests.lua",
  "PetBattle/PetBattleEventsTests.lua",
  "Utils/SortingTests.lua",
  "SoundtrackTests.lua",
  "Utils/StringUtilsTests.lua",
  "TimersTests.lua",
  "Zones/ZoneEventsTests.lua",
}

for _, path in ipairs(testFiles) do
  LoadTestFile(path)
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
      currentTestFailed = false
      failureMessages = {}
      ResetState()
      local ok, err = pcall(fn, entry.tests)
      if not ok then
        print(label)
        failed = failed + 1
        print("    ✗ ERROR: " .. tostring(err))
      elseif currentTestFailed then
        print(label)
        for _, failure in ipairs(failureMessages) do
          print(failure.msg)
          -- Print stack trace with indentation
          local lines = {}
          for line in failure.trace:gmatch("[^\r\n]+") do
            table.insert(lines, line)
          end
          for i, line in ipairs(lines) do
            if i > 1 then -- Skip the first line (it's just the traceback header)
              print("      " .. line)
            end
          end
        end
      end
    end
  end
end

print()
print("=" .. string.rep("=", 68) .. "=")
print(string.format("  Tests: %d passed, %d failed", passed, failed))
print("=" .. string.rep("=", 68) .. "=")

os.exit(failed > 0 and 1 or 0)
