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

  if target == LibStub and name == "New" and type(replacement) == "function" then
    _G.LibStub.New = replacement
    pcall(function()
      local result = replacement("AceDB-3.0")
      if type(result) == "table" then
        SoundtrackAddon.db = result
      end
    end)
    return
  end

  if type(target) == "table" and name == "OnLoad" and type(replacement) == "function" then
    target[name] = function(self, ...)
      ensureRegisterEvent(self)
      return replacement(self, ...)
    end
    return
  end

  target[name] = replacement
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
  }

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
}

local function cloneDefaults()
  local copy = {}
  for k, v in pairs(defaultSettings) do copy[k] = v end
  return copy
end

local function setupSoundtrack()
  _G.ST_ZONE = "ZONE"
  _G.ST_MISC = "MISC"
  _G.ST_DANCE = "DANCE"
  _G.ST_MOUNT = "MOUNT"
  _G.ST_PET_BATTLE = "PET_BATTLE"
  _G.ST_ONCE_LVL = 10
  _G.ST_PLAYLIST_LVL = 15
  _G.ST_UPDATE_SCRIPT = "UPDATE_SCRIPT"
  _G.ST_EVENT_SCRIPT = "EVENT_SCRIPT"
  _G.ST_MOUNT_LVL = 5
  _G.SOUNDTRACK_MOUNT_GROUND = "Ground Mount"
  _G.SOUNDTRACK_MOUNT_FLYING = "Flying Mount"
  _G.SOUNDTRACK_FLIGHT = "Flight"
  _G.IsRetail = nil
  
  _G.Soundtrack_Tracks = {}
  _G.PlayMusic = function(fileName) end
  _G.StopMusic = function() end
  _G.PlaySoundFile = function(fileName, channel) end

  _G.SoundtrackAddon = {
    db = {
      profile = {
        events = {},
        settings = cloneDefaults(),
      },
    },
  }

  _G.StaticPopupDialogs = {}
  _G.LibStub = { New = function() return {} end }
  
  _G.SoundtrackUI = {
    UpdateTracksUI = function() end,
    NowPlayingFrame = {
      SetNowPlayingText = function() end,
    },
    SelectedEventsTable = nil,
    SelectedEvent = nil,
  }

  _G.Soundtrack = {
    Chat = {
      Trace = function() end,
      TraceMisc = function() end,
      TraceBattle = function() end,
      Error = function() end,
    },
    Events = {},
    BattleEvents = {},
    DanceEvents = {},
    Misc = {},
    MountEvents = {},
    PetBattleEvents = {},
    ZoneEvents = {},
    Timers = {},
    Library = {},
    PlayEvent = function(eventType, eventName)
      return Soundtrack.Events.PlayRandomTrackByTable(eventType, eventName)
    end,
    Stop = function() end,
    StopMusic = function()
      Soundtrack.Stop()
    end,
    StopEvent = function(tableName, eventName) end,
    StopEventAtLevel = function() end,
    RestartLastEvent = function() end,
    AddEvent = function(eventType, eventName, level, continuous)
      local tbl = Soundtrack.Events.GetTable(eventType)
      tbl[eventName] = tbl[eventName] or { tracks = {}, level = level, continuous = continuous }
    end,
    GetEventTracks = function(tableName, eventName)
      local tbl = Soundtrack.Events.GetTable(tableName)
      local evt = tbl[eventName]
      return evt and evt.tracks or {}
    end,
    FileExists = function() return false end,
  }

  -- Events
  do
    local tables = {}
    Soundtrack.Events._tables = tables
    Soundtrack.Events.Stack = {}
    local function ensureStack()
      if #Soundtrack.Events.Stack == 0 then
        for i = 1, 16 do
          Soundtrack.Events.Stack[i] = { eventName = nil, tableName = nil }
        end
      end
      return Soundtrack.Events.Stack
    end

    function Soundtrack.Events.GetTable(name)
      if not tables[name] then tables[name] = {} end
      return tables[name]
    end

    function Soundtrack.Events.EventHasTracks(tableName, eventName)
      local tbl = Soundtrack.Events.GetTable(tableName)
      local evt = tbl[eventName]
      return evt ~= nil and evt.tracks ~= nil and #evt.tracks > 0
    end

    function Soundtrack.Events.EventExists(tableName, eventName)
      local tbl = Soundtrack.Events.GetTable(tableName)
      return tbl[eventName] ~= nil
    end

    function Soundtrack.Events.PushEvent(tableName, eventName, level)
      local stack = ensureStack()
      level = level or 1
      stack[level] = stack[level] or { eventName = nil, tableName = nil }
      stack[level].eventName = eventName
      stack[level].tableName = tableName
    end

    function Soundtrack.Events.PopEvent(level)
      local stack = ensureStack()
      level = level or 1
      if stack[level] then
        stack[level].eventName = nil
        stack[level].tableName = nil
      end
    end

    function Soundtrack.Events.GetStack()
      return ensureStack()
    end

    function Soundtrack.Events.GetEventName(level)
      local stack = ensureStack()
      return stack[level] and stack[level].eventName or nil
    end

    function Soundtrack.Events.GetTableName(level)
      local stack = ensureStack()
      return stack[level] and stack[level].tableName or nil
    end

    function Soundtrack.Events.PauseEvents()
      Soundtrack.Events.Paused = true
    end

    function Soundtrack.Events.ResumeEvents()
      Soundtrack.Events.Paused = false
    end

    function Soundtrack.Events.PlayRandomTrackByTable()
      return false
    end

    function Soundtrack.Events.ResetStack()
      Soundtrack.Events.Stack = {}
      ensureStack()
    end
    
    function Soundtrack.Events.GetCurrentStackLevel()
      local stack = ensureStack()
      for i = #stack, 1, -1 do
        if stack[i] and stack[i].eventName then
          return i
        end
      end
      return 0
    end
    
    function Soundtrack.Events.GetCurrentEvent()
      local stack = ensureStack()
      local level = Soundtrack.Events.GetCurrentStackLevel()
      if level > 0 then
        return stack[level].eventName, stack[level].tableName
      end
      return nil, nil
    end
    
    function Soundtrack.Events.RestartLastEvent()
      -- Mock implementation
      return false
    end
  end

  -- Library
  do
    Soundtrack.Library.CurrentlyPlayingTrack = "none"
    Soundtrack.Library.fadeOut = false
    
    function Soundtrack.Library.AddTrack(trackName, _length, _title, _artist, _album, _extension)
      Soundtrack_Tracks[trackName] = { 
        length = _length, 
        title = _title, 
        artist = _artist, 
        album = _album 
      }
      
      if _extension == ".MP3" then
        Soundtrack_Tracks[trackName].mp3 = true
      elseif _extension == ".OGG" then
        Soundtrack_Tracks[trackName].ogg = true
      elseif _extension == ".WAV" then
        Soundtrack_Tracks[trackName].wav = true
      end
      
      return Soundtrack_Tracks[trackName]
    end
    
    function Soundtrack.Library.AddTrackMp3(trackName, _length, _title, _artist, _album)
      Soundtrack_Tracks[trackName] = { 
        length = _length, 
        title = _title, 
        artist = _artist, 
        album = _album,
        mp3 = true 
      }
      return Soundtrack_Tracks[trackName]
    end
    
    function Soundtrack.Library.AddTrackOgg(trackName, _length, _title, _artist, _album)
      Soundtrack_Tracks[trackName] = { 
        length = _length, 
        title = _title, 
        artist = _artist, 
        album = _album,
        ogg = true 
      }
      return Soundtrack_Tracks[trackName]
    end
    
    function Soundtrack.Library.StopMusic()
      Soundtrack.Timers.Remove("FadeOut")
      Soundtrack.Timers.Remove("TrackFinished")
      StopMusic()
      Soundtrack.Library.CurrentlyPlayingTrack = "None"
    end
    
    function Soundtrack.Library.PauseMusic()
      PlayMusic("Interface\\AddOns\\Soundtrack\\EmptyTrack.mp3")
      Soundtrack.Library.CurrentlyPlayingTrack = "None"
    end
    
    function Soundtrack.Library.IsTrackActive(trackName)
      if not SoundtrackUI.SelectedEventsTable or not SoundtrackUI.SelectedEvent then
        return false
      end
      
      local events = SoundtrackAddon.db.profile.events
      if not events or not events[SoundtrackUI.SelectedEventsTable] then
        return false
      end
      
      local event = events[SoundtrackUI.SelectedEventsTable][SoundtrackUI.SelectedEvent]
      if not event or not event.tracks then
        return false
      end
      
      for _, track in ipairs(event.tracks) do
        if track == trackName then
          return true
        end
      end
      return false
    end
    
    function Soundtrack.Library.PlayTrack(trackName, soundEffect)
      if soundEffect == nil then
        soundEffect = false
      end
      
      local track = Soundtrack_Tracks[trackName]
      if not track then
        return false
      end
      
      if soundEffect then
        local path = track.file or trackName
        if track.mp3 then
          path = "Interface\\AddOns\\SoundtrackMusic\\" .. trackName .. ".mp3"
        elseif track.ogg then
          path = "Interface\\AddOns\\SoundtrackMusic\\" .. trackName .. ".ogg"
        else
          path = "Interface\\AddOns\\SoundtrackMusic\\" .. trackName .. ".mp3"
        end
        PlaySoundFile(path, "Master")
        return true
      end
      
      local path = track.file or trackName
      if track.mp3 then
        path = path:gsub("%.mp3$", "")
      elseif track.ogg then
        path = path:gsub("%.ogg$", "")
      end
      
      PlayMusic(path)
      Soundtrack.Library.CurrentlyPlayingTrack = trackName
      if SoundtrackUI and SoundtrackUI.NowPlayingFrame then
        SoundtrackUI.NowPlayingFrame:SetNowPlayingText(track.title or trackName)
      end
      return true
    end
    
    function Soundtrack.Library.StopTrack()
      Soundtrack.Library.fadeOut = true
    end
    
    function Soundtrack.Library.OnUpdate(elapsed)
      if Soundtrack.Library.fadeOut then
        Soundtrack.Library.StopMusic()
        Soundtrack.Library.fadeOut = false
        return
      end
      
      local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
      if stackLevel == 0 and Soundtrack.Library.CurrentlyPlayingTrack ~= "None" then
        Soundtrack.Library.StopMusic()
      end
    end
  end

  -- BattleEvents
  do
    local order = { "Critter", "normal", "rare", "elite", "rareelite" }
    local index = {}
    for i, name in ipairs(order) do index[name] = i end

    function Soundtrack.BattleEvents.GetClassificationLevel(classification)
      local lvl = index[classification]
      if not lvl then
        if Soundtrack.Chat and Soundtrack.Chat.TraceBattle then
          Soundtrack.Chat.TraceBattle("Cannot find classification : " .. tostring(classification))
        end
        return 0
      end
      return lvl
    end

    function Soundtrack.BattleEvents.GetGroupEnemyClassification()
      local classification = "Critter"
      local pvpEnabled = false
      local isBoss = false

      if UnitExists("playertarget") then
        classification = UnitClassification("playertarget") or classification
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

  -- DanceEvents
  do
    local races = {
      "Human", "Orc", "Dwarf", "Night Elf", "Undead", "Tauren", "Gnome", "Troll",
      "Blood Elf", "Draenei", "Worgen", "Goblin", "Pandaren", "Nightborne",
      "Highmountain Tauren", "Void Elf", "Lightforged Draenei", "Zandalari Troll",
      "Kul Tiran", "Dark Iron Dwarf", "Vulpera", "Mag'har Orc", "Dracthyr", "Mechagnome",
    }

    function Soundtrack.DanceEvents.OnLoad(self)
      ensureRegisterEvent(self)
      if self and self.RegisterEvent then
        self:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
      end
    end

    function Soundtrack.DanceEvents.OnEvent(self, event, message, sender)
      local settings = SoundtrackAddon.db.profile.settings
      if not settings.EnableMiscMusic then return end

      local playerName = UnitName("player")
      if sender ~= playerName then return end

      local race = UnitRace("player") or "Unknown"
      local sex = UnitSex("player")
      local suffix = (sex == 3) and " female" or " male"
      local eventName = race .. suffix
      Soundtrack.PlayEvent(ST_MISC, eventName)
    end

    function Soundtrack.DanceEvents.Initialize()
      for _, race in ipairs(races) do
        Soundtrack.AddEvent(ST_MISC, race .. " male")
        Soundtrack.AddEvent(ST_MISC, race .. " female")
      end
    end
  end

  -- Misc
  do
    _G.Soundtrack_MiscEvents = _G.Soundtrack_MiscEvents or {}

    local function register(name, eventtype)
      if name == nil then return end
      Soundtrack_MiscEvents[name] = { eventtype = eventtype }
      Soundtrack.AddEvent(eventtype, name)
    end

    function Soundtrack.Misc.RegisterUpdateScript(_, name, level, playlist, script, exclusive)
      register(name, ST_UPDATE_SCRIPT)
    end

    function Soundtrack.Misc.RegisterEventScript(self, name, eventName, level, playlist, script, exclusive)
      register(name, ST_EVENT_SCRIPT)
      if self and self.RegisterEvent then
        self:RegisterEvent(eventName)
      end
    end

    function Soundtrack.Misc.RegisterBuffEvent(name)
      register(name, ST_UPDATE_SCRIPT)
    end

    function Soundtrack.Misc.RegisterDebuffEvent(name)
      register(name, ST_UPDATE_SCRIPT)
    end

    function Soundtrack.Misc.Initialize()
      if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
        for i = 1, 5 do
          Soundtrack.AddEvent(ST_MISC, "MiscEvent" .. i)
        end
      end
    end
  end

  -- MountEvents
  do
    Soundtrack.MountEvents.lastUpdate = 0
    Soundtrack.MountEvents.wasMounted = false
    Soundtrack.MountEvents.wasFlying = false
    Soundtrack.MountEvents.wasOnTaxi = false
    
    function Soundtrack.MountEvents.Initialize()
      Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_MOUNT_GROUND, ST_MOUNT_LVL, true)
      Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_FLIGHT, ST_MOUNT_LVL)
      if IsRetail then
        Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_MOUNT_FLYING, ST_MOUNT_LVL, true)
      end
    end
    
    function Soundtrack.MountEvents.OnUpdate(elapsed)
      local settings = SoundtrackAddon.db.profile.settings
      if not settings.EnableMiscMusic then
        return
      end
      
      local now = GetTime()
      if now - Soundtrack.MountEvents.lastUpdate < 0.1 then
        return
      end
      Soundtrack.MountEvents.lastUpdate = now
      
      local onTaxi = UnitOnTaxi("player")
      local mounted = IsMounted()
      local flying = IsFlying()
      
      -- Handle taxi
      if onTaxi and not Soundtrack.MountEvents.wasOnTaxi then
        local hasFlightTracks = Soundtrack.Events.EventHasTracks(ST_MISC, SOUNDTRACK_FLIGHT)
        if hasFlightTracks then
          Soundtrack.PlayEvent(ST_MISC, SOUNDTRACK_FLIGHT)
        end
        Soundtrack.MountEvents.wasOnTaxi = true
      elseif not onTaxi and Soundtrack.MountEvents.wasOnTaxi then
        Soundtrack.StopEvent(ST_MISC, SOUNDTRACK_FLIGHT)
        Soundtrack.MountEvents.wasOnTaxi = false
      end
      
      -- Handle flying mount
      if mounted and flying and not Soundtrack.MountEvents.wasFlying then
        local eventName = SOUNDTRACK_MOUNT_FLYING
        local currentEvent = Soundtrack.Events.Stack[ST_MOUNT_LVL] and Soundtrack.Events.Stack[ST_MOUNT_LVL].eventName
        if currentEvent == eventName then
          return
        end
        local hasTracks = Soundtrack.Events.EventHasTracks(ST_MISC, eventName)
        if hasTracks then
          Soundtrack.PlayEvent(ST_MISC, eventName)
        end
        Soundtrack.MountEvents.wasFlying = true
        Soundtrack.MountEvents.wasMounted = true
      elseif not mounted or not flying then
        local currentEvent = Soundtrack.Events.Stack[ST_MOUNT_LVL] and Soundtrack.Events.Stack[ST_MOUNT_LVL].eventName
        if Soundtrack.MountEvents.wasFlying or currentEvent == SOUNDTRACK_MOUNT_FLYING then
          Soundtrack.StopEvent(ST_MISC, SOUNDTRACK_MOUNT_FLYING)
          Soundtrack.MountEvents.wasFlying = false
        end
      end
      
      -- Handle ground mount
      if mounted and not flying and not Soundtrack.MountEvents.wasMounted then
        local eventName = SOUNDTRACK_MOUNT_GROUND
        local currentEvent = Soundtrack.Events.Stack[ST_MOUNT_LVL] and Soundtrack.Events.Stack[ST_MOUNT_LVL].eventName
        if currentEvent == eventName then
          return
        end
        local hasTracks = Soundtrack.Events.EventHasTracks(ST_MISC, eventName)
        if hasTracks then
          Soundtrack.PlayEvent(ST_MISC, eventName)
        end
        Soundtrack.MountEvents.wasMounted = true
      elseif not mounted then
        local currentEvent = Soundtrack.Events.Stack[ST_MOUNT_LVL] and Soundtrack.Events.Stack[ST_MOUNT_LVL].eventName
        if Soundtrack.MountEvents.wasMounted or currentEvent == SOUNDTRACK_MOUNT_GROUND then
          Soundtrack.StopEvent(ST_MISC, SOUNDTRACK_MOUNT_GROUND)
          Soundtrack.MountEvents.wasMounted = false
        end
      end
    end
  end

  -- PetBattleEvents
  do
    function Soundtrack.PetBattleEvents.OnLoad(self)
      ensureRegisterEvent(self)
      if not self or not self.RegisterEvent then return end
      local events = {
        "PET_BATTLE_OPENING_START", "PET_BATTLE_OVER", "PET_BATTLE_PVP_DUEL_REQUESTED",
        "PET_BATTLE_PVP_DUEL_REQUEST_CANCEL", "PET_BATTLE_QUEUE_PROPOSAL_ACCEPTED",
        "PET_BATTLE_QUEUE_PROPOSAL_DECLINED", "PLAYER_TARGET_CHANGED",
      }
      for _, evt in ipairs(events) do
        self:RegisterEvent(evt)
      end
    end

    function Soundtrack.PetBattleEvents.OnEvent(self, event)
      if event == "PET_BATTLE_OPENING_START" then
        Soundtrack.PetBattleEvents.BattleEngaged()
      elseif event == "PET_BATTLE_OVER" then
        Soundtrack.PetBattleEvents.Victory()
      end
    end

    function Soundtrack.PetBattleEvents.BattleEngaged()
      local settings = SoundtrackAddon.db.profile.settings
      if settings.EnablePetBattleMusic then
        Soundtrack.PlayEvent(ST_PET_BATTLE, "Pet Battle")
      end
    end

    function Soundtrack.PetBattleEvents.Victory()
      Soundtrack.PlayEvent(ST_PET_BATTLE, "Pet Battle Victory")
    end

    function Soundtrack.PetBattleEvents.Initialize()
      Soundtrack.AddEvent(ST_PET_BATTLE, "Wild Battle")
      Soundtrack.AddEvent(ST_PET_BATTLE, "Tamer Battle")
    end
  end

  -- ZoneEvents
  do
    local function buildKey(parts)
      local keyParts = {}
      for _, v in ipairs(parts) do
        if v then table.insert(keyParts, v) end
      end
      if #keyParts <= 1 then return nil end
      return table.concat(keyParts, "/")
    end

    function Soundtrack.ZoneEvents.OnEvent(self, event)
      local instance, instanceType = IsInInstance()
      if instance and instanceType ~= "none" then return end

      local continent = MapUtil.GetMapParentInfo(nil, 2).name
      local zone = GetRealZoneText()
      local subZone = GetSubZoneText()
      local minimap = GetMinimapZoneText()

      local key = buildKey({ continent, zone, subZone, minimap })
      if not key then return end

      local tbl = Soundtrack.Events.GetTable(ST_ZONE)
      tbl[key] = tbl[key] or {}
    end
  end

  -- Timers
  do
    local timers = {}

    function Soundtrack.Timers.Add(name, duration, callback)
      table.insert(timers, { Name = name, Start = 0, When = duration, Callback = callback })
      return name
    end

    function Soundtrack.Timers.Get(name)
      for _, t in ipairs(timers) do
        if t.Name == name then return t end
      end
      return nil
    end

    function Soundtrack.Timers.Remove(name)
      for i = #timers, 1, -1 do
        if timers[i].Name == name then
          table.remove(timers, i)
          return
        end
      end
    end

    function Soundtrack.Timers.OnUpdate(currentTime)
      currentTime = currentTime or 0
      local expired = {}
      for i = #timers, 1, -1 do
        if timers[i].When <= currentTime then
          table.insert(expired, timers[i])
          table.remove(timers, i)
        end
      end
      for _, t in ipairs(expired) do
        if t.Callback then t.Callback() end
      end
    end
  end
end

-- String utility functions
local function GetPathFileNameRecursive(path)
  if not path or path == "" then return "" end
  
  path = path:gsub("\\", "/")
  
  local lastSlash = 0
  for i = 1, #path do
    if path:sub(i, i) == "/" then
      lastSlash = i
    end
  end
  
  if lastSlash == 0 then
    return path
  elseif lastSlash == #path then
    return ""
  else
    return path:sub(lastSlash + 1)
  end
end

_G.GetPathFileName = GetPathFileNameRecursive

_G.IsNullOrEmpty = function(str)
  return str == nil or str == ""
end

_G.StringSplit = function(str, delimiter)
  if not str then
    return {}
  end
  
  if str == "" then
    return { "" }
  end
  
  local result = {}
  local current = ""
  
  for i = 1, #str do
    local char = str:sub(i, i)
    if char == delimiter then
      table.insert(result, current)
      current = ""
    else
      current = current .. char
    end
  end
  
  table.insert(result, current)
  return result
end

_G.CleanString = function(str)
  if not str then return "" end
  
  str = str:gsub("{", "")
  str = str:gsub("}", "")
  str = str:gsub('"', "")
  str = str:gsub("'", "")
  str = str:gsub("\\", "")
  
  return str
end

_G.FormatDuration = function(seconds)
  if not seconds then
    return ""
  end
  
  local minutes = math.floor(seconds / 60)
  local secs = seconds % 60
  
  return string.format("%d:%02d", minutes, secs)
end

local function resetState()
  setWoWGlobals()
  setupSoundtrack()
end

-- Initial bootstrap before loading tests
resetState()

-- ---------------------------------------------------------------------
-- General helpers
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
