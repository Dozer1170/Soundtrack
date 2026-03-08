Soundtrack.Library                       = {}

local nextTrackInfo
local nextFileName
local nextTrackName
-- Fade state machine: "idle" | "instant" | "fading_out" | "fading_in"
local fadeState                          = "idle"
local fadeStartTime                      = 0
local fadeDuration                       = 0
local savedMusicVolume                   = 1
local isPreviewActive                    = false -- true while a preview track is playing

Soundtrack.Library.CurrentlyPlayingTrack = nil

local function PlayOnceTrackFinished()
	Soundtrack.StopEventAtLevel(Soundtrack.Events.GetCurrentStackLevel())
end

local function RemoveContinuityTimers()
	Soundtrack.Timers.Remove("FadeOut")
	Soundtrack.Timers.Remove("TrackFinished")
end

local function IsFadeEnabled()
	if not SoundtrackAddon or not SoundtrackAddon.db then return false end
	local s = SoundtrackAddon.db.profile.settings
	return s.FadeTransition == true and (s.FadeTransitionDuration or 0) > 0
end

local function GetMusicVolume()
	return tonumber(GetCVar("Sound_MusicVolume")) or 1
end

local function SetMusicVolume(v)
	SetCVar("Sound_MusicVolume", tostring(math.max(0, math.min(1, v))))
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

function Soundtrack.Library.AddDefaultTrack(trackName, _length, _title, _artist, _album, _resourceId)
	if _extension == nil then
		Soundtrack_Tracks[trackName] =
		{ length = _length, title = _title, artist = _artist, album = _album, defaultTrack = true, resourceId =
		_resourceId }
	elseif _extension == ".MP3" then
		Soundtrack_Tracks[trackName] =
		{ length = _length, title = _title, artist = _artist, album = _album, mp3 = true, defaultTrack = true, resourceId =
		_resourceId }
	elseif _extension == ".OGG" then
		Soundtrack_Tracks[trackName] =
		{ length = _length, title = _title, artist = _artist, album = _album, ogg = true, defaultTrack = true, resourceId =
		_resourceId }
	elseif _extension == ".WAV" then
		Soundtrack_Tracks[trackName] =
		{ length = _length, title = _title, artist = _artist, album = _album, wav = true, defaultTrack = true, resourceId =
		_resourceId }
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

function Soundtrack.Library.IsFadingOut()
	return fadeState == "fading_out"
end

function Soundtrack.Library.IsFadingIn()
	return fadeState == "fading_in"
end

function Soundtrack.Library.StopTrack()
	local nothingPlaying = (Soundtrack.Library.CurrentlyPlayingTrack == nil
		or Soundtrack.Library.CurrentlyPlayingTrack == "None")
	Soundtrack.Chat.TraceLibrary(string.format(
		"[StopTrack] playing=%s fadeState=%s fadeEnabled=%s preview=%s nothingPlaying=%s",
		tostring(Soundtrack.Library.CurrentlyPlayingTrack),
		tostring(fadeState),
		tostring(IsFadeEnabled()),
		tostring(isPreviewActive),
		tostring(nothingPlaying)
	))
	nextTrackInfo = nil
	if IsFadeEnabled() and not isPreviewActive and not nothingPlaying then
		if fadeState == "fading_out" then
			-- Already fading out; nextTrackInfo=nil above ensures we stop after the fade completes.
			Soundtrack.Chat.TraceLibrary("[StopTrack] -> already fading_out, will stop after current fade")
		elseif fadeState == "fading_in" then
			-- Interrupt the fade-in: snap to full volume then start a fresh fade-out.
			-- savedMusicVolume already holds the correct reference level; do not overwrite it.
			Soundtrack.Chat.TraceLibrary("[StopTrack] -> interrupting fade-in, snap + fade-out")
			SetMusicVolume(savedMusicVolume)
			fadeDuration  = SoundtrackAddon.db.profile.settings.FadeTransitionDuration
			fadeStartTime = GetTime()
			fadeState     = "fading_out"
		else
			-- idle: capture the current user volume and start a fresh fade-out.
			Soundtrack.Chat.TraceLibrary("[StopTrack] -> starting fade-out")
			savedMusicVolume = GetMusicVolume()
			fadeDuration     = SoundtrackAddon.db.profile.settings.FadeTransitionDuration
			fadeStartTime    = GetTime()
			fadeState        = "fading_out"
		end
	else
		Soundtrack.Chat.TraceLibrary("[StopTrack] -> instant stop")
		fadeState = "instant"
	end
	isPreviewActive = false
end

function Soundtrack.Library.OnUpdate()
	local now = GetTime()

	-- Volume fade-out in progress
	if fadeState == "fading_out" then
		local elapsed  = now - fadeStartTime
		local progress = fadeDuration > 0 and math.min(1, elapsed / fadeDuration) or 1
		SetMusicVolume(savedMusicVolume * (1 - progress))
		if progress >= 1 then
			Soundtrack.Chat.TraceLibrary(string.format(
				"[OnUpdate/fading_out] complete. nextTrack=%s",
				nextTrackName and tostring(nextTrackName) or "nil"
			))
			Soundtrack.Library.StopMusic()
			Soundtrack.Library.CurrentlyPlayingTrack = nil
			if nextTrackInfo ~= nil then
				Soundtrack.Chat.TraceLibrary("[OnUpdate/fading_out] -> playing next track, starting fade-in")
				DelayedPlayMusic()
				nextTrackInfo = nil
				fadeStartTime = now
				fadeState     = "fading_in"
			else
				Soundtrack.Chat.TraceLibrary("[OnUpdate/fading_out] -> no next track, returning to idle")
				SetMusicVolume(savedMusicVolume)
				fadeState = "idle"
				SoundtrackUI.UpdateTracksUI()
			end
		end
		return
	end

	-- Volume fade-in in progress
	if fadeState == "fading_in" then
		local elapsed  = now - fadeStartTime
		local progress = fadeDuration > 0 and math.min(1, elapsed / fadeDuration) or 1
		SetMusicVolume(savedMusicVolume * progress)
		if progress >= 1 then
			SetMusicVolume(savedMusicVolume)
			Soundtrack.Chat.TraceLibrary(string.format(
				"[OnUpdate/fading_in] complete. playing=%s nextTrack=%s",
				tostring(Soundtrack.Library.CurrentlyPlayingTrack),
				nextTrackName and tostring(nextTrackName) or "nil"
			))
			if nextTrackInfo ~= nil then
				-- New track requested during fade-in; start a fresh fade-out
				Soundtrack.Chat.TraceLibrary("[OnUpdate/fading_in] -> pending next track, starting fade-out")
				fadeDuration  = (SoundtrackAddon.db.profile.settings.FadeTransitionDuration or 2)
				fadeStartTime = now
				fadeState     = "fading_out"
			else
				Soundtrack.Chat.TraceLibrary("[OnUpdate/fading_in] -> idle")
				fadeState = "idle"
			end
		end
		return
	end

	-- Instant switch (fade disabled)
	if fadeState == "instant" then
		Soundtrack.Library.StopMusic()
		Soundtrack.Library.CurrentlyPlayingTrack = nil
		if nextTrackInfo ~= nil then
			DelayedPlayMusic()
			nextTrackInfo = nil
		end
		SoundtrackUI.UpdateTracksUI()
		fadeState = "idle"
		return
	end

	-- Idle: stop music if nothing is on the stack
	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
	if stackLevel == 0 and Soundtrack.Library.CurrentlyPlayingTrack ~= nil then
		Soundtrack.Library.StopMusic()
		Soundtrack.Library.CurrentlyPlayingTrack = nil
		if nextTrackInfo ~= nil then
			DelayedPlayMusic()
			nextTrackInfo = nil
		end
		SoundtrackUI.UpdateTracksUI()
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

-- Called when the Sound_MusicVolume CVar changes externally (CVAR_UPDATE).
-- Only update savedMusicVolume when we are not mid-fade; during a fade we
-- are the ones writing the CVar and must not corrupt the reference level.
function Soundtrack.Library.OnMusicVolumeCVarChanged(newVolume)
	if fadeState == "idle" then
		savedMusicVolume = newVolume
	end
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
		if nextTrackInfo.resourceId and nextTrackInfo.resourceId ~= 0 then
			newTrackName = tostring(nextTrackInfo.resourceId)
			Soundtrack.Chat.TraceLibrary("PlayDefaultMusicResourceId(" .. newTrackName .. ")")
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
		local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
		local playingPreview = (stackLevel == ST_PREVIEW_LVL)
		local skipFade = playingPreview or isPreviewActive
		isPreviewActive = playingPreview
		local nothingPlaying = (Soundtrack.Library.CurrentlyPlayingTrack == nil
			or Soundtrack.Library.CurrentlyPlayingTrack == "None")

		Soundtrack.Chat.TraceLibrary(string.format(
			"[PlayTrack] track=%s stackLevel=%d fadeState=%s fadeEnabled=%s playing=%s nothingPlaying=%s skipFade=%s preview=%s",
			tostring(trackName),
			tostring(stackLevel),
			tostring(fadeState),
			tostring(IsFadeEnabled()),
			tostring(Soundtrack.Library.CurrentlyPlayingTrack),
			tostring(nothingPlaying),
			tostring(skipFade),
			tostring(playingPreview)
		))

		if nothingPlaying or skipFade then
			-- Nothing to fade from: play immediately rather than waiting for OnUpdate.
			-- Going through the "instant" state leaves a window where StopTrack can
			-- clear nextTrackInfo before OnUpdate fires, silently dropping the track.
			Soundtrack.Chat.TraceLibrary("[PlayTrack] -> immediate play (nothing playing or skipFade)")
			Soundtrack.Library.StopMusic()
			Soundtrack.Library.CurrentlyPlayingTrack = nil
			DelayedPlayMusic()
			nextTrackInfo = nil
			fadeState = "idle"
		elseif IsFadeEnabled() then
			if fadeState == "idle" then
				Soundtrack.Chat.TraceLibrary("[PlayTrack] -> fade enabled, idle -> starting fade-out")
				savedMusicVolume = GetMusicVolume()
				fadeDuration     = SoundtrackAddon.db.profile.settings.FadeTransitionDuration
				fadeStartTime    = GetTime()
				fadeState        = "fading_out"
			elseif fadeState == "fading_out" then
				-- Already fading out; updated nextTrackInfo will play when done
				Soundtrack.Chat.TraceLibrary(string.format(
					"[PlayTrack] -> already fading_out, queueing track=%s (overwrites previous queue)",
					tostring(trackName)
				))
			elseif fadeState == "fading_in" then
				-- Interrupt the fade-in early: snap to full volume and start a fresh
				-- fade-out so the new track (e.g. combat music) plays without delay.
				Soundtrack.Chat.TraceLibrary(string.format(
					"[PlayTrack] -> fading_in, interrupting with new track=%s -> snap vol + new fade-out",
					tostring(trackName)
				))
				SetMusicVolume(savedMusicVolume)
				fadeDuration  = SoundtrackAddon.db.profile.settings.FadeTransitionDuration
				fadeStartTime = GetTime()
				fadeState     = "fading_out"
			end
		else
			Soundtrack.Chat.TraceLibrary("[PlayTrack] -> fade disabled, instant switch")
			fadeState = "instant"
		end
	else
		Soundtrack.Chat.TraceLibrary("[PlayTrack] -> sound effect: PlaySoundFile(" .. nextFileName .. ")")
		PlaySoundFile(nextFileName)
		nextTrackInfo = nil
	end

	-- Update the UI if its opened
	SoundtrackUI.UpdateTracksUI()
end
