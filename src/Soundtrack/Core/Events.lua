Soundtrack.Events = {}
Soundtrack.Events.MaxStackLevel = 16
Soundtrack.Events.Paused = false
Soundtrack.Events.Stack = {
	-- This must match number of levels in Constants.lua
	{ eventName = nil, tableName = nil }, -- Level 1: Continent
	{ eventName = nil, tableName = nil }, -- Level 2: Region
	{ eventName = nil, tableName = nil }, -- Level 3: Zones
	{ eventName = nil, tableName = nil }, -- Level 4: Interiors
	{ eventName = nil, tableName = nil }, -- Level 5: Mount: Mount, Flight
	{ eventName = nil, tableName = nil }, -- Level 6: Auras: Forms
	{ eventName = nil, tableName = nil }, -- Level 7: Status: Swimming, Stealthed
	{ eventName = nil, tableName = nil }, -- Level 8: Temp. Buffs: Dash, Class Stealth
	{ eventName = nil, tableName = nil }, -- Level 9: NPCs: Merchant, Auction House
	{ eventName = nil, tableName = nil }, -- Level 10: One-time: Dance, Cinematics
	{ eventName = nil, tableName = nil }, -- Level 11: Battle
	{ eventName = nil, tableName = nil }, -- Level 12: Boss
	{ eventName = nil, tableName = nil }, -- Level 13: Death, Ghost
	{ eventName = nil, tableName = nil }, -- Level 14: SFX: Victory, Level up, LFG Complete
	{ eventName = nil, tableName = nil }, -- Level 15: Playlists
	{ eventName = nil, tableName = nil }, -- Level 16: Preview
}

local fadeOutTime = 1
local currentTableName = nil
local currentEventName = nil

local function VerifyStackLevel(stackLevel)
	if not stackLevel or stackLevel < 1 or stackLevel > Soundtrack.Events.MaxStackLevel then
		Soundtrack.Chat.Error("BAD STACK LEVEL " .. stackLevel)
	end
end

-- Returns if event has tracks.
function Soundtrack.Events.EventHasTracks(tableName, eventName)
	local eventTable = Soundtrack.Events.GetTable(tableName)
	if not eventTable then
		return false
	end

	if eventTable[eventName] then
		local trackList = eventTable[eventName].tracks
		if trackList then
			local numTracks = table.getn(trackList)
			if numTracks >= 1 then
				return true
			end
		end
	end
	return false
end

function Soundtrack.Events.EventExists(tableName, eventName)
	local eventTable = Soundtrack.Events.GetTable(tableName)
	if eventTable[eventName] then
		return true
	else
		return false
	end
end

local nextTrack -- Hack because of fading issue
-- Attempts to play a random track on a specific event table. Returns true if it found a track to play.
function Soundtrack.Events.PlayRandomTrackByTable(tableName, eventName, offset)
	Soundtrack.Chat.TraceEvents("Soundtrack.Events.PlayRandomTrackByTable (" .. tableName .. ", " .. eventName .. ")")
	local eventTable = Soundtrack.Events.GetTable(tableName)

	if eventTable[eventName] then
		local trackList = eventTable[eventName].tracks

		if trackList then
			local numTracks = table.getn(trackList)
			if numTracks >= 1 then
				local index

				if eventTable[eventName].random then
					-- if eventTable[eventName].random and tableName ~= "Playlists" then
					--Soundtrack.Chat.TraceEvents("Random")
					index = random(1, numTracks)
					--Soundtrack.Chat.TraceEvents("Random index: "..index)

					-- Avoid playing same track twice
					if index == eventTable[eventName].lastTrackIndex then
						index = index + 1
						if index > numTracks then
							index = 1
						end
					end
				--Soundtrack.Chat.TraceEvents("Adjusted Random index: "..index)
				else
					--Soundtrack.Chat.TraceEvents("Non random")
					-- Non random playback
					if not eventTable[eventName].lastTrackIndex then
						index = 1
					else
						index = eventTable[eventName].lastTrackIndex + offset
						if index > numTracks then
							index = 1
						elseif index == 0 then
							index = numTracks
						end
					end
				end

				local trackName = trackList[index]
				eventTable[eventName].lastTrackIndex = index
				if not Soundtrack.Events.Paused then
					Soundtrack.Library.PlayTrack(trackName, eventTable[eventName].soundEffect)
					nextTrack = trackName
				elseif eventTable[eventName].soundEffect then
					Soundtrack.Library.PlayTrack(trackName, eventTable[eventName].soundEffect)
				else
					Soundtrack.Chat.TraceEvents("Paused")
				end
				return true
			end
		end
	end
	return false
end

local function TrackFinished()
	Soundtrack.Events.RestartLastEvent()
end

local function StartEmptyTrack()
	Soundtrack.Library.PauseMusic()
end

local function PlayOnceTrackFinished()
	Soundtrack.StopEventAtLevel(Soundtrack.Events.GetCurrentStackLevel()) -- TODO Anthony : by name?
end

local function GetTrackCount(event)
	if not event then
		return 0
	end

	local trackList = event.tracks
	if trackList then
		return table.getn(trackList)
	else
		return 0
	end
end

-- Returns the current stack level on which a valid event is found.
local function GetValidStackLevel()
	local validStackLevel = 0

	for i = table.getn(Soundtrack.Events.Stack), 1, -1 do
		local event = Soundtrack.GetEvent(Soundtrack.Events.Stack[i].tableName, Soundtrack.Events.Stack[i].eventName)
		if event then
			local trackCount = GetTrackCount(event)
			if validStackLevel == 0 and trackCount > 0 then
				validStackLevel = i
			elseif not event.continuous then
				Soundtrack.Chat.TraceEvents("Removing obsolete event: " .. Soundtrack.Events.Stack[i].eventName)
				Soundtrack.Events.Stack[i].eventName = nil
				Soundtrack.Events.Stack[i].tableName = nil
				Soundtrack.Events.Stack[i].offset = 0
			end
		else
			Soundtrack.Events.Stack[i].eventName = nil
			Soundtrack.Events.Stack[i].tableName = nil
			Soundtrack.Events.Stack[i].offset = 0
		end
	end

	return validStackLevel
end

function Soundtrack.Events.GetEventAtStackLevel(level)
	local eventName = Soundtrack.Events.Stack[level].eventName
	local tableName = Soundtrack.Events.Stack[level].tableName
	return eventName, tableName
end

-- Called anytime the stack has changed. Makes sure the top most event gets played,
-- and avoids playing unnecessary events.
function Soundtrack.Events.OnStackChanged(forceRestart)
	-- Remove any playOnce events that do not have any valid tracks or they will never be removed
	SoundtrackFrame.OnEventStackChanged()

	local validStackLevel = GetValidStackLevel()
	if validStackLevel == 0 then
		-- Nothing to play.
		-- Stop events if something was already active
		if currentTableName then
			Soundtrack.Timers.Remove("FadeOut")
			Soundtrack.Timers.Remove("TrackFinished")
			Soundtrack.Library.StopTrack()
		end
		currentTableName = nil
		currentEventName = nil
	else
		-- There is something valid on the stack.
		local stackItem = Soundtrack.Events.Stack[validStackLevel]
		if not stackItem then
			error("BAD DATA " .. validStackLevel)
		end
		local tableName = Soundtrack.Events.Stack[validStackLevel].tableName
		local eventName = Soundtrack.Events.Stack[validStackLevel].eventName
		local event = Soundtrack.GetEvent(tableName, eventName)
		local offset = Soundtrack.Events.Stack[validStackLevel].offset
		local currentTrack = Soundtrack.Library.CurrentlyPlayingTrack

		-- Avoid restarting already playing event
		if forceRestart or currentTableName ~= tableName or currentEventName ~= eventName then
			-- Avoid restarting a song that is in both events
			local sameTrack = false
			for _, v in ipairs(event.tracks) do
				if v == currentTrack then
					sameTrack = true
					break
				end
			end
			if not sameTrack or forceRestart then
				-- We are starting a new track!
				-- Remove the playback continuity timers
				Soundtrack.Timers.Remove("FadeOut")
				Soundtrack.Timers.Remove("TrackFinished")

				nextTrack = nil
				local res = Soundtrack.Events.PlayRandomTrackByTable(tableName, eventName, offset)
				if not res then
					Soundtrack.Chat.TraceEvents("Not supposed to play invalid events.")
				end

				currentTableName = tableName
				currentEventName = eventName

				-- A track is now playing, register continuity timers
				if nextTrack and Soundtrack_Tracks then
					local track = Soundtrack_Tracks[nextTrack]
					if track then
						local length = track.length
						if length then
							if not event.continuous then
								if track.length > 20 then
									Soundtrack.Timers.AddTimer("FadeOut", length - fadeOutTime, PlayOnceTrackFinished)
								else
									Soundtrack.Timers.AddTimer("FadeOut", length, PlayOnceTrackFinished)
								end
							else
								local randomSilence = 0
								if SoundtrackAddon.db.profile.settings.Silence > 0 then
									randomSilence = random(5, SoundtrackAddon.db.profile.settings.Silence)
									Soundtrack.Chat.TraceEvents(
										"Adding " .. randomSilence .. " seconds of silence after track"
									)
								end
								Soundtrack.Timers.AddTimer("TrackFinished", length + randomSilence, TrackFinished)
								if track.length > 20 then
									Soundtrack.Timers.AddTimer("FadeOut", length - fadeOutTime, StartEmptyTrack)
								else
									Soundtrack.Timers.AddTimer("FadeOut", length, StartEmptyTrack)
								end
							end
						end
					end
				end
			end
		end
	end
end

-- Returns the event table for a tab name.
function Soundtrack.Events.GetTable(eventTableName)
	if not eventTableName then
		return
	end

	local eventTable = SoundtrackAddon.db.profile.events[eventTableName]
	if not eventTable then
		Soundtrack.Chat.Error("Attempt to access invalid event table (" .. eventTableName .. ")")
		return nil
	end

	return eventTable
end

-- Adds an event to the events table. If no trackName is passed, the event is created empty.
-- If a trackName is passed it is added to that events track list.
function Soundtrack.Events.Add(eventTableName, eventName, trackName)
	if not eventName then
		return
	end

	local eventTable = Soundtrack.Events.GetTable(eventTableName)
	if not eventTable then
		Soundtrack.Chat.TraceEvents("Cannot find table : " .. eventTableName)
		return
	end

	if not eventTable[eventName] then
		if not trackName then
			Soundtrack.Chat.TraceEvents("Add Event: " .. eventTableName .. ": " .. eventName)
		end

		-- Create event
		eventTable[eventName] = { tracks = {}, lastTrackIndex = 0, random = true }

		-- Because I cant figure out how to sort the hashtable...
		Soundtrack.SortEvents(eventTableName)
	end

	if trackName then
		local trackNotListed = true
		for i = 0, #eventTable[eventName].tracks do
			if trackName == eventTable[eventName].tracks[i] then
				trackNotListed = false
				break
			end
		end
		if trackNotListed then
			table.insert(eventTable[eventName].tracks, trackName)
		end
	end
end

-- Removes an event from the events table.
function Soundtrack.Events.Remove(eventTableName, eventName, trackName)
	local eventTable = Soundtrack.Events.GetTable(eventTableName)
	local tracks = eventTable[eventName].tracks
	for i, tn in ipairs(tracks) do
		if tn == trackName then
			table.remove(tracks, i)
			return
		end
	end
end

function Soundtrack.Events.DeleteEvent(tableName, eventName)
	local eventTable = Soundtrack.Events.GetTable(tableName)
	if eventTable then
		if eventTable[eventName] then
			Soundtrack.Chat.TraceEvents("Removing event: " .. eventName)
			eventTable[eventName] = nil
		end
		Soundtrack.SortEvents(tableName)
	end
end

-- TODO: Needs to be fixed, does not function
-- Look at EditEvent, possibly same function.
function Soundtrack.Events.RenameEvent(tableName, oldName, newName)
	if oldName == newName then
		return
	end

	local eventTable = SoundtrackAddon.db.profile.events[tableName]
	if eventTable and eventTable[oldName] then
		Soundtrack.Chat.TraceEvents("Renaming event: " .. oldName .. " => " .. newName)
		local event = eventTable[oldName]
		eventTable[newName] = event
		eventTable[oldName] = nil
		Soundtrack.SortEvents(tableName)
	end

	-- Also rename event in CustomEvents
	if SoundtrackAddon.db.profile.customEvents[oldName] then
		local event = SoundtrackAddon.db.profile.customEvents[oldName]
		SoundtrackAddon.db.profile.customEvents[newName] = event
		SoundtrackAddon.db.profile.customEvents[oldName] = nil
	end

	if Soundtrack_MiscEvents[oldName] then
		local event = Soundtrack_MiscEvents[oldName]
		Soundtrack_MiscEvents[newName] = event
		Soundtrack_MiscEvents[oldName] = nil
	end
end

function Soundtrack.Events.ClearEvent(eventTableName, eventName)
	Soundtrack.Chat.TraceEvents("ClearEvent(" .. eventTableName .. ", " .. eventName)
	local eventTable = Soundtrack.Events.GetTable(eventTableName)

	eventTable[eventName].tracks = {}
end

-- Adds an event on the stack and refreshes active track
function Soundtrack.Events.PlayEvent(tableName, eventName, stackLevel, forceRestart, _, offset)
	if eventName == nil then
		Soundtrack.Chat.TraceEvents("Attempting to PlayEvent with a nil name!")
		return
	end

	if not stackLevel then
		Soundtrack.Chat.TraceEvents("Cannot PlayEvent(" .. eventName .. "). It has no priority level.")
		return
	end

	VerifyStackLevel(stackLevel)

	if not tableName then
		Soundtrack.Chat.TraceEvents("PlayEvent: Invalid table name")
		return
	end

	if not eventName then
		Soundtrack.Chat.TraceEvents("PlayEvent: Invalid event name")
		return
	end

	-- Check if event exists
	local event = Soundtrack.GetEvent(tableName, eventName)
	if not event then
		return
	end

	-- Check if event has assigned tracks
	local eventHasTracks = false
	local eventTable = Soundtrack.Events.GetTable(tableName)
	if eventTable[eventName] then
		local trackList = eventTable[eventName].tracks
		if trackList then
			local numTracks = table.getn(trackList)
			if numTracks >= 1 then
				eventHasTracks = true
			end
		end
	end

	local playOnceText
	if event.continuous then
		playOnceText = "Loop"
	else
		playOnceText = "Once"
	end
	Soundtrack.Chat.TraceEvents(
		"PlayEvent(" .. tableName .. ", " .. eventName .. ", " .. stackLevel .. ") " .. playOnceText
	)

	if not offset then
		offset = 0
	end

	-- Add event on the stack
	if event.soundEffect then
		if eventHasTracks then
			-- Sound effects are never added to the stack
			Soundtrack.Events.PlayRandomTrackByTable(tableName, eventName, offset)
		end
	else
		if eventHasTracks then
			Soundtrack.Events.Stack[stackLevel].tableName = tableName
			Soundtrack.Events.Stack[stackLevel].eventName = eventName
			Soundtrack.Events.Stack[stackLevel].offset = offset
			Soundtrack.Events.OnStackChanged(forceRestart)
		end
	end
end

function Soundtrack.Events.RestartLastEvent(offset)
	local stackLevel = GetValidStackLevel()
	if stackLevel > 0 then
		Soundtrack.Events.PlayEvent(
			Soundtrack.Events.Stack[stackLevel].tableName,
			Soundtrack.Events.Stack[stackLevel].eventName,
			stackLevel,
			true,
			nil,
			offset
		) -- Edit by Lunaqua, missing variable in function call, changed to nil
	end
end

function Soundtrack.Events.GetCurrentStackLevel()
	return GetValidStackLevel()
end

function Soundtrack.Events.PlaybackNext()
	Soundtrack.Events.RestartLastEvent(1)
end

function Soundtrack.Events.PlaybackPrevious()
	Soundtrack.Events.RestartLastEvent(-1)
end

function Soundtrack.Events.PlaybackPlayStop()
	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
	local currentEvent = "None"
	if stackLevel ~= 0 then
		currentEvent = Soundtrack.Events.Stack[stackLevel].eventName
	end
	if Soundtrack.Events.Paused and currentEvent ~= SOUNDTRACK_NO_EVENT_PLAYING then
		Soundtrack.Chat.TraceEvents("All music unpaused")
		Soundtrack.Events.Paused = false
		Soundtrack.Events.RestartLastEvent(0)
	else
		Soundtrack.Chat.TraceEvents("All music paused")
		Soundtrack.Events.Paused = true
		Soundtrack.Library.StopMusic()
	end
	SoundtrackFrame_RefreshPlaybackControls()
end

function Soundtrack.Events.PlaybackTrueStop()
	Soundtrack.Chat.TraceEvents("All music stopped")
	Soundtrack.StopEventAtLevel(Soundtrack.Events.GetCurrentStackLevel())
	Soundtrack.Library.StopMusic()
	SoundtrackFrame_RefreshPlaybackControls()
end

function Soundtrack.Events.Pause(enable)
	Soundtrack.Events.Paused = enable
	SoundtrackFrame_RefreshPlaybackControls()
end

function Soundtrack.Events.OnLoad(self)
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("PLAYER_ENTERING_BATTLEGROUND")
end

function Soundtrack.Events.OnEvent(_, event)
	if event == "PLAYER_ENTERING_WORLD" or event == "PLAYER_ENTERING_BATTLEGROUND" then
		if Soundtrack.Events.Paused == false then
			Soundtrack.Events.RestartLastEvent(1)
		end
	end
end
