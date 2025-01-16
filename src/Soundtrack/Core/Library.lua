Soundtrack.Library = {}

local nextTrackInfo
local nextFileName
local nextTrackName
local fadeOut = false

Soundtrack.Library.CurrentlyPlayingTrack = nil

local function PlayOnceTrackFinished()
	Soundtrack.StopEventAtLevel(Soundtrack.Events.GetCurrentStackLevel())
end

local function RemoveContinuityTimers()
	Soundtrack.Timers.Remove("FadeOut")
	Soundtrack.Timers.Remove("TrackFinished")
end

local fadeOutTime = 1
local function StartContinuityTimers()
	local track = Soundtrack_Tracks[nextTrackName]
	local event = Soundtrack.Events.GetCurrentEvent()
	if track == nil or event == nil then
		return
	end

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
					Soundtrack.Chat.TraceLibrary("Adding " .. randomSilence .. " seconds of silence after track")
				end
				Soundtrack.Timers.AddTimer("TrackFinished", length + randomSilence, Soundtrack.Events.RestartLastEvent)
				if track.length > 20 then
					Soundtrack.Timers.AddTimer("FadeOut", length - fadeOutTime, Soundtrack.Library.PauseMusic)
				else
					Soundtrack.Timers.AddTimer("FadeOut", length, Soundtrack.Library.PauseMusic)
				end
			end
		end
	end
end

local function DelayedPlayMusic()
	RemoveContinuityTimers()
	Soundtrack.Library.CurrentlyPlayingTrack = nextTrackName
	Soundtrack.Chat.TraceLibrary("PlayMusic(" .. nextFileName .. ")")
	PlayMusic(nextFileName)
	StartContinuityTimers()
	SoundtrackUI.NowPlayingFrame.SetNowPlayingText(nextTrackInfo.title, nextTrackInfo.artist, nextTrackInfo.album)
end

function Soundtrack.Library.AddTrack(trackName, _length, _title, _artist, _album, _extension)
	if _extension == nil then
		Soundtrack_Tracks[trackName] = { length = _length, title = _title, artist = _artist, album = _album }
	elseif _extension == ".MP3" then
		Soundtrack_Tracks[trackName] =
			{ length = _length, title = _title, artist = _artist, album = _album, mp3 = true }
	elseif _extension == ".OGG" then
		Soundtrack_Tracks[trackName] =
			{ length = _length, title = _title, artist = _artist, album = _album, ogg = true }
	elseif _extension == ".WAV" then
		Soundtrack_Tracks[trackName] =
			{ length = _length, title = _title, artist = _artist, album = _album, wav = true }
	end
end

function Soundtrack.Library.AddTrackMp3(trackName, _length, _title, _artist, _album)
	Soundtrack_Tracks[trackName] = { length = _length, title = _title, artist = _artist, album = _album, mp3 = true }
end

function Soundtrack.Library.AddTrackOgg(trackName, _length, _title, _artist, _album)
	Soundtrack_Tracks[trackName] = { length = _length, title = _title, artist = _artist, album = _album, ogg = true }
end

function Soundtrack.Library.AddDefaultTrack(trackName, _length, _title, _artist, _album)
	if _extension == nil then
		Soundtrack_Tracks[trackName] =
			{ length = _length, title = _title, artist = _artist, album = _album, defaultTrack = true }
	elseif _extension == ".MP3" then
		Soundtrack_Tracks[trackName] =
			{ length = _length, title = _title, artist = _artist, album = _album, mp3 = true, defaultTrack = true }
	elseif _extension == ".OGG" then
		Soundtrack_Tracks[trackName] =
			{ length = _length, title = _title, artist = _artist, album = _album, ogg = true, defaultTrack = true }
	elseif _extension == ".WAV" then
		Soundtrack_Tracks[trackName] =
			{ length = _length, title = _title, artist = _artist, album = _album, wav = true, defaultTrack = true }
	end
end

function Soundtrack.Library.StopMusic()
	-- Remove the playback continuity timers
	-- because we're stopping!
	RemoveContinuityTimers()

	Soundtrack.Library.CurrentlyPlayingTrack = "None"
	Soundtrack.Chat.TraceLibrary("StopMusic()")
	StopMusic()
	SoundtrackUI.UpdateTracksUI()
end

function Soundtrack.Library.PauseMusic()
	-- Play EmptyTrack
	Soundtrack.Library.CurrentlyPlayingTrack = "None"
	Soundtrack.Chat.TraceLibrary("PlayMusic('Interface\\AddOns\\Soundtrack\\EmptyTrack.mp3')")
	PlayMusic("Interface\\AddOns\\Soundtrack\\EmptyTrack.mp3")
	SoundtrackUI.UpdateTracksUI()
end

function Soundtrack.Library.StopTrack()
	Soundtrack.Chat.TraceLibrary("StopTrack()")
	fadeOut = true
	nextTrackInfo = nil
end

function Soundtrack.Library.OnUpdate()
	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
	if fadeOut == true or (stackLevel == 0 and Soundtrack.Library.CurrentlyPlayingTrack ~= nil) then
		Soundtrack.Library.StopMusic()
		Soundtrack.Library.CurrentlyPlayingTrack = nil

		if nextTrackInfo ~= nil then
			DelayedPlayMusic()
			nextTrackInfo = nil
		end

		SoundtrackUI.UpdateTracksUI()
		fadeOut = false
	end
end

-- Checks if a particular track is already set for an event
function Soundtrack.Library.IsTrackActive(trackName)
	local event = SoundtrackAddon.db.profile.events[SoundtrackUI.SelectedEventsTable][SoundtrackUI.SelectedEvent]
	if not event then
		return false
	end

	for _, tn in ipairs(event.tracks) do
		if tn == trackName then
			return true
		end
	end

	return false
end

function Soundtrack.Library.PlayTrack(trackName, soundEffect)
	if soundEffect == nil then
		soundEffect = false
	end

	-- Check if the track is valid
	if not Soundtrack_Tracks or not Soundtrack_Tracks[trackName] then
		return
	end

	nextTrackInfo = Soundtrack_Tracks[trackName]

	if nextTrackInfo.defaultTrack then
		local newTrackName = trackName
		Soundtrack.Chat.TraceLibrary("PlayDefaultMusicFileName(" .. newTrackName .. ")")
		local dtrackIndexB, dtrackIndexE = string.find(newTrackName, "////")
		if not dtrackIndexB then
			dtrackIndexB = 0
			dtrackIndexE = 0
		else
			newTrackName = string.sub(newTrackName, dtrackIndexE + 1)
			Soundtrack.Chat.TraceLibrary("PlayDefaultMusicCroppedName(" .. newTrackName .. ")")
		end
		nextFileName = "" .. newTrackName .. ""
	else
		if nextTrackInfo.ogg then
			nextFileName = "Interface\\AddOns\\SoundtrackMusic\\" .. trackName .. ".ogg"
		elseif nextTrackInfo.mp3 then
			nextFileName = "Interface\\AddOns\\SoundtrackMusic\\" .. trackName .. ".mp3"
		else
			nextFileName = "Interface\\AddOns\\SoundtrackMusic\\" .. trackName .. ".mp3"
		end
	end

	-- Everything ok, play the track
	if not soundEffect then
		nextTrackName = trackName
		-- HACK because of Blizzard broke cross fading
		-- Start fading out current song
		fadeOut = true
	else
		Soundtrack.Chat.TraceLibrary("PlaySoundFile(" .. nextFileName .. ")") -- EDITED, replaced fileName with nextFileName
		PlaySoundFile(nextFileName) -- sound effect. play the music overlapping other music
		nextTrackInfo = nil
	end

	-- Update the UI if its opened
	SoundtrackUI.UpdateTracksUI()
end
