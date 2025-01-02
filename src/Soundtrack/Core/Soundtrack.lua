Soundtrack.TracksLoaded = false

StaticPopupDialogs["ST_NO_LOADMYTRACKS_POPUP"] = {
	preferredIndex = 3,
	text = SOUNDTRACK_NO_MYTRACKS,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		SoundtrackAddon.db.profile.settings.UseDefaultLoadMyTracks = true
		Soundtrack.LoadTracks()
	end,
	OnCancel = function()
		SoundtrackAddon.db.profile.settings.UseDefaultLoadMyTracks = false
	end,
	timeout = 0,
	whileDead = 1,
}

local offset = 0
local nextUpdateTime = 0

local function SetUserEventsToCorrectLevel()
	local tableName = Soundtrack.Events.GetTable("Boss")
	if not tableName then
		return
	end

	for _, v in pairs(tableName) do
		v.priority = ST_BOSS_LVL
	end

	tableName = Soundtrack.Events.GetTable("Playlists")
	if not tableName then
		return
	end

	for _, v in pairs(tableName) do
		v.priority = ST_PLAYLIST_LVL
	end
end

-- Returns a flat list of tree nodes, based on whether each level is expanded or not
local function GetFlattenedEventNodes(eventTableName, rootNode, list)
	table.insert(list, rootNode)

	-- if expandable
	if table.getn(rootNode.nodes) >= 1 then
		local event = SoundtrackAddon.db.profile.events[eventTableName][rootNode.tag]
			or error("Cannot locate event " .. rootNode.name)
		if not event then
			return
		end

		-- By default every event is expanded
		if event.expanded == nil then
			event.expanded = true
		end

		if event.expanded then
			for _, n in ipairs(rootNode.nodes) do
				GetFlattenedEventNodes(eventTableName, n, list)
			end
		end
	end
end

SoundtrackAddon = LibStub("AceAddon-3.0"):NewAddon("SoundtrackAddon", "AceEvent-3.0")
_G.SOUNDTRACK_BINDING_HEADER = C_AddOns.GetAddOnMetadata(..., "Title")

function SoundtrackAddon:OnInitialize()
	self.db = LibStub("AceDB-3.0"):New("SoundtrackDB", {
		profile = {
			minimap = { hide = false },
			events = {},
			customEvents = {},
			settings = {
				MinimapIconPos = 45,
				EnableMinimapButton = true,
				ShowTrackInformation = true,
				ShowDefaultMusic = false,
				ShowEventStack = false,
				ShowPlaybackControls = false,
				EnableBattleMusic = true,
				EnableZoneMusic = true,
				EnableMiscMusic = true,
				EnableCustomMusic = true,
				Debug = false,
				BattleCooldown = 0,
				Silence = 5,
				AutoAddZones = true,
				EscalateBattleMusic = true,
				trackSortingCriteria = "filePath",
				CurrentProfileBattle = "Default",
				CurrentProfileZone = "Default",
				CurrentProfileDance = "Default",
				CurrentProfileMisc = "Default",
				UseDefaultLoadMyTracks = false,
				LockNowPlayingFrame = false,
				LockPlaybackControls = false,
				HideControlButtons = false,
				PlaybackButtonsPosition = "LEFT",
				LowHealthPercent = 0.25,
				YourEnemyLevelOnly = false,
				k = true,
			},
		},
	}, true)
	self:RegisterEvent("VARIABLES_LOADED")
end

function SoundtrackAddon:VARIABLES_LOADED()
	Soundtrack.Chat.InitDebugChatFrame()
	SoundtrackMinimap_Initialize()
	Soundtrack.MigrateFromOldSavedVariables()
	Soundtrack.LoadTracks()
	Soundtrack.DanceEvents.Initialize()
	Soundtrack.PetBattleEvents.Initialize()
	Soundtrack.MountEvents.Initialize()
	Soundtrack.ZoneEvents.Initialize()
	Soundtrack.BattleEvents.Initialize()
	Soundtrack.Auras.Initialize()
	Soundtrack.Misc.Initialize()
	Soundtrack.CustomEvents.CustomInitialize()
	SoundtrackUI.RefreshShowingTab()
	SoundtrackUI.Initialize()
	Soundtrack.Cleanup.CleanupOldEvents()
end

function Soundtrack.LoadTracks()
	Soundtrack_Tracks = {}

	-- Load tracks in generated script if available
	Soundtrack_LoadDefaultTracks()

	if Soundtrack_LoadMyTracks and not Soundtrack.TracksLoaded then
		Soundtrack_LoadMyTracks()
		SoundtrackAddon.db.profile.settings.UseDefaultLoadMyTracks = false
		Soundtrack.TracksLoaded = true
	elseif not Soundtrack_LoadMyTracks and not SoundtrackAddon.db.profile.settings.UseDefaultLoadMyTracks then
		StaticPopup_Show("ST_NO_LOADMYTRACKS_POPUP")
		error(SOUNDTRACK_ERROR_LOADING)
	elseif not Soundtrack_LoadMyTracks and SoundtrackAddon.db.profile.settings.UseDefaultLoadMyTracks then
		-- User has no tracks to load, and is intentional
	end

	-- Create events table
	for _, eventTabName in ipairs(Soundtrack_EventTabs) do
		if not SoundtrackAddon.db.profile.events[eventTabName] then
			Soundtrack.Chat.TraceEvents("Creating table " .. eventTabName)
			SoundtrackAddon.db.profile.events[eventTabName] = {}
		end
	end

	-- Remove obsolete predefined events
	Soundtrack.Timers.AddTimer("PurgeOldTracksFromEvents", 10, Soundtrack.Cleanup.PurgeOldTracksFromEvents)

	Soundtrack.SortAllEvents()
	Soundtrack.SortTracks()
	SetUserEventsToCorrectLevel()

	local numTracks = getn(Soundtrack_SortedTracks)
	Soundtrack.Chat.Message("Soundtrack: Loaded with " .. numTracks .. " track(s) in library.")

	SoundtrackFrame_RefreshPlaybackControls()
end

function Soundtrack.AddEvent(tableName, eventName, _priority, _continuous, _soundEffect)
	if IsNullOrEmpty(tableName) then
		Soundtrack.Chat.Error("AddEvent: Nil table")
		return
	end

	if IsNullOrEmpty(eventName) then
		return
	end

	-- Used by cleanup events to remove events that are no longer valid
	if Soundtrack.RegisteredEvents[tableName] == nil then
		Soundtrack.RegisteredEvents[tableName] = {}
	end
	Soundtrack.RegisteredEvents[tableName][eventName] = true

	local eventTable = Soundtrack.Events.GetTable(tableName)

	if not eventTable then
		Soundtrack.Chat.Error("AddEvent: Cannot find table : " .. tableName)
		return
	end

	local event = eventTable[eventName]
	if event then
		event.priority = _priority
		if event.continuous == nil then
			event.continuous = _continuous
		end
		if event.soundEffect == nil then
			event.soundEffect = _soundEffect
		end
		return -- event is already registered
	else
		Soundtrack.Chat.TraceEvents("AddEvent: " .. tableName .. ": " .. eventName)
		eventTable[eventName] = {
			tracks = {},
			lastTrackIndex = 0,
			random = true,
			priority = _priority,
			continuous = _continuous,
			soundEffect = _soundEffect,
		}
	end

	Soundtrack.SortEvents(tableName)
end

function Soundtrack.RemoveEvent(tableName, eventName)
	if IsNullOrEmpty(tableName) then
		Soundtrack.Chat.Error("RemoveEvent: Nil table")
		return
	end
	if IsNullOrEmpty(eventName) then
		Soundtrack.Chat.Error("RemoveEvent: Nil event")
		return
	end

	local eventTable = Soundtrack.Events.GetTable(tableName)
	if not eventTable then
		Soundtrack.Chat.Error("RemoveEvent: Cannot find table : " .. tableName)
		return
	end

	local event = eventTable[eventName]
	if event then
		Soundtrack.Chat.TraceEvents("RemoveEvent: " .. tableName .. ": " .. eventName)
		eventTable[eventName] = nil
	end
end

function Soundtrack.RenameEvent(tableName, oldEventName, newEventName, _priority, _continuous, _soundEffect)
	if IsNullOrEmpty(tableName) then
		Soundtrack.Chat.Error("RenameEvent: Nil table")
		return
	end
	if IsNullOrEmpty(oldEventName) then
		Soundtrack.Chat.Error("RenmeEvent: Nil old event")
		return
	end
	if IsNullOrEmpty(newEventName) then
		Soundtrack.Chat.Error("RenameEvent: Nil new event " .. oldEventName)
		return
	end

	local eventTable = Soundtrack.Events.GetTable(tableName)

	if not eventTable then
		Soundtrack.Chat.Error("RenameEvent: Cannot find table : " .. tableName)
		return
	end

	local event = eventTable[newEventName]
	if event then
		if event.priority == nil then
			event.priority = _priority
		end
		if event.continuous == nil then
			event.continuous = _continuous
		end
		event.soundEffect = _soundEffect
		return -- event is already registered
	end

	Soundtrack.Chat.TraceEvents("RenameEvent: " .. tableName .. ": " .. oldEventName .. " to " .. newEventName)

	eventTable[newEventName] = eventTable[oldEventName]

	-- Now that we changed the name of the event, delete the old event
	Soundtrack.Events.DeleteEvent(tableName, oldEventName)

	-- Because I cant figure out how to sort the hashtable...
	Soundtrack.SortEvents(tableName)
end

function Soundtrack.AssignTrack(eventName, trackName)
	if IsNullOrEmpty(eventName) or IsNullOrEmpty(trackName) then
		debugEvents("AssignTrack: Invalid table or event name")
		return
	end

	local tableName = Soundtrack.GetTableFromEvent(eventName)
	local eventTable = Soundtrack.Events.GetTable(tableName)

	if not eventTable then
		debugEvents("Cannot find table : " .. tableName)
		return
	end

	table.insert(eventTable[eventName].tracks, trackName)
end

function Soundtrack.GetTableFromEvent(eventName)
	for _, eventTabName in ipairs(Soundtrack_EventTabs) do
		local eventTable = Soundtrack.Events.GetTable(eventTabName)
		if eventTable and eventTable[eventName] then
			return eventTabName
		end
	end

	return nil
end

function Soundtrack.GetEvent(tableName, eventName)
	if not tableName or not eventName then
		return nil
	end

	local eventTable = Soundtrack.Events.GetTable(tableName)
	if not eventTable then
		return nil
	end
	return eventTable[eventName]
end

function Soundtrack.GetEventByName(eventName)
	if not eventName then
		return nil
	end

	local tableName = Soundtrack.GetTableFromEvent(eventName)
	if not tableName then
		return nil
	end

	local eventTable = Soundtrack.Events.GetTable(tableName)
	if not eventTable then
		return nil
	end
	return eventTable[eventName]
end

function Soundtrack.PlayEvent(tableName, eventName, forceRestart)
	if not tableName then
		Soundtrack.Chat.Error("PlayEvent: Invalid table name")
		return
	end
	if not eventName then
		Soundtrack.Chat.Error("PlayEvent: Invalid event name")
		return
	end

	local eventTable = Soundtrack.Events.GetTable(tableName)
	if not eventTable then
		return
	end

	local event = eventTable[eventName]
	if not event then
		return
	end

	local playOnceText
	if event.continuous then
		playOnceText = "Loop"
	else
		playOnceText = "Once"
	end

	local priorityText = "Priority: " .. (event.priority or "Unset")

	local sfxText = ""
	if event.soundEffect then
		sfxText = " (SFX)"
	end

	Soundtrack.Chat.TraceEvents(
		"PlayEvent("
			.. tableName
			.. ", "
			.. GetPathFileName(eventName)
			.. ", "
			.. priorityText
			.. ") "
			.. playOnceText
			.. sfxText
	)

	-- Add event on the stack
	if not event.priority then
		Soundtrack.Chat.Error("Cannot play event " .. eventName .. ". It has no priority!")
	elseif event.soundEffect then
		-- Sound effects are never added to the stack
		Soundtrack.Events.PlayRandomTrackByTable(tableName, eventName, offset)
	else
		if Soundtrack.Events.GetEventAtStackLevel(event.priority) ~= eventName then
			Soundtrack.Events.Stack[event.priority].tableName = tableName
			Soundtrack.Events.Stack[event.priority].eventName = eventName
			Soundtrack.Events.Stack[event.priority].offset = offset
			Soundtrack.Events.OnStackChanged(forceRestart)
		end
	end
end

-- Call this to stop music. Makes sure it only stops music Soundtrack has started.
function Soundtrack.StopEventAtLevel(stackLevel)
	if stackLevel == 0 or not stackLevel then
		return
	else
		if Soundtrack.Events.Stack[stackLevel].eventName ~= nil then
			Soundtrack.Chat.TraceEvents("StopEvent(" .. stackLevel .. ")")
			-- Remove the event from the stack.
			Soundtrack.Events.Stack[stackLevel].eventName = nil
			Soundtrack.Events.Stack[stackLevel].tableName = nil
			Soundtrack.Events.Stack[stackLevel].offset = 0
			Soundtrack.Events.OnStackChanged()
		end
	end
end

function Soundtrack.StopEvent(tableName, eventName)
	local event = Soundtrack.GetEvent(tableName, eventName)
	if event then
		Soundtrack.Chat.TraceEvents("StopEvent(" .. tableName .. ", " .. eventName .. ")")
		Soundtrack.StopEventAtLevel(event.priority)
	end
end

-- Call after events have changed or been expanded/collapsed
function Soundtrack.OnEventTreeChanged(eventTableName)
	-- Remove collapsed portions from Sorted events
	Soundtrack_FlatEvents[eventTableName] = {}
	local rootEventNode = Soundtrack_EventNodes[eventTableName]
	for _, n in ipairs(rootEventNode.nodes) do
		GetFlattenedEventNodes(eventTableName, n, Soundtrack_FlatEvents[eventTableName])
	end
end

function Soundtrack.OnUpdate(_, deltaT)
	local currentTime = GetTime()
	Soundtrack.Library.OnUpdate(deltaT)
	if currentTime >= nextUpdateTime then
		nextUpdateTime = currentTime + UI_UPDATE_INTERVAL
		Soundtrack.Timers.OnUpdate(deltaT)
	end
end

function Soundtrack.OnLoad(self)
	SLASH_SOUNDTRACK1, SLASH_SOUNDTRACK2 = "/soundtrack", "/st"
	local function SoundtrackSlashCmd(msg)
		if msg == "debug" then
			SoundtrackAddon.db.profile.settings.Debug = not SoundtrackAddon.db.profile.settings.Debug
			Soundtrack.Chat.InitDebugChatFrame()
		elseif msg == "reset" then
			SoundtrackFrame:ClearAllPoints()
			SoundtrackFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
		elseif msg == "report" then
			SoundtrackReportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
			SoundtrackReportFrame:Show()
		else
			SoundtrackFrame:Show()
		end
	end
	SlashCmdList["SOUNDTRACK"] = SoundtrackSlashCmd

	Soundtrack.Events.OnLoad(self)
end
