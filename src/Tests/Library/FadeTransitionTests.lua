if not Tests then
	return
end

local Tests = Tests("Soundtrack", "PLAYER_ENTERING_WORLD")

-- ---------------------------------------------------------------------------
-- Shared helpers
-- ---------------------------------------------------------------------------

local function SetupFadeTrack()
	Soundtrack_Tracks = {
		["FadeTrack"]    = { length = 180, title = "Fade Song", mp3 = true },
		["PrevFadeTrack"] = { length = 180, title = "Previous Song", mp3 = true },
	}
	-- Simulate something already playing so fade tests exercise the real fade path.
	-- Fading only kicks in when transitioning between tracks, not on first play.
	Soundtrack.Library.CurrentlyPlayingTrack = "PrevFadeTrack"
end

local function EnableFade(duration)
	SoundtrackAddon.db.profile.settings.FadeTransition = true
	SoundtrackAddon.db.profile.settings.FadeTransitionDuration = duration or 2
end

local function MakeFadeHelpers(overrides)
	overrides = overrides or {}
	local currentTime = overrides.startTime or 0
	local playedPath  = nil
	local stopCalled  = false
	local setCvarCalls = {}

	Replace("GetTime",   function() return currentTime end)
	Replace("PlayMusic", function(path) playedPath = path end)
	Replace("StopMusic", function() stopCalled = true end)
	Replace("SetCVar",   function(key, value)
		if key == "Sound_MusicVolume" then
			table.insert(setCvarCalls, tonumber(value))
		end
	end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function()
		return overrides.stackLevel or 1
	end)
	Replace(Soundtrack.Events, "GetCurrentEvent", function()
		return overrides.event or { continuous = false }
	end)
	Replace(Soundtrack.Timers, "Remove",   function() end)
	Replace(Soundtrack.Timers, "AddTimer", function() end)

	return {
		SetTime = function(t) currentTime = t end,
		PlayedPath  = function() return playedPath  end,
		StopCalled  = function() return stopCalled  end,
		SetCVarCalls = function() return setCvarCalls end,
	}
end

-- ---------------------------------------------------------------------------
-- Tests: fade disabled (default in test harness)
-- ---------------------------------------------------------------------------

function Tests:FadeDisabled_PlayTrack_PlaysOnNextUpdate()
	SetupFadeTrack()
	local h = MakeFadeHelpers()

	Soundtrack.Library.PlayTrack("FadeTrack")
	Soundtrack.Library.OnUpdate()

	IsTrue(h.PlayedPath() ~= nil, "Track should play immediately when fade is disabled")
	AreEqual("Interface\\AddOns\\SoundtrackMusic\\FadeTrack.mp3", h.PlayedPath())
end

function Tests:FadeDisabled_StopTrack_StopsOnNextUpdate()
	SetupFadeTrack()
	Soundtrack.Library.CurrentlyPlayingTrack = "FadeTrack"

	local stopCalled = false
	Replace("StopMusic", function() stopCalled = true end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)
	Replace(Soundtrack.Timers, "Remove", function() end)

	Soundtrack.Library.StopTrack()
	Soundtrack.Library.OnUpdate()

	IsTrue(stopCalled, "StopMusic should be called immediately when fade is disabled")
end

-- ---------------------------------------------------------------------------
-- Tests: fade enabled
-- ---------------------------------------------------------------------------

function Tests:FadeEnabled_PlayTrack_DoesNotPlayImmediately()
	EnableFade(2)
	SetupFadeTrack()
	local h = MakeFadeHelpers()

	Soundtrack.Library.PlayTrack("FadeTrack")
	-- t=0: fade just started
	Soundtrack.Library.OnUpdate()

	IsFalse(h.PlayedPath() ~= nil, "Track must not play before fade-out completes")
end

function Tests:FadeEnabled_PlayTrack_PlaysAfterFadeDuration()
	EnableFade(2)
	SetupFadeTrack()
	local h = MakeFadeHelpers()

	Soundtrack.Library.PlayTrack("FadeTrack")
	h.SetTime(2) -- advance past full fade duration
	Soundtrack.Library.OnUpdate()

	IsTrue(h.PlayedPath() ~= nil, "Track should play once fade-out completes")
	AreEqual("Interface\\AddOns\\SoundtrackMusic\\FadeTrack.mp3", h.PlayedPath())
end

function Tests:FadeEnabled_FadeOut_DecreasesVolumeDuringTransition()
	EnableFade(2)
	SetupFadeTrack()
	local h = MakeFadeHelpers()

	Soundtrack.Library.PlayTrack("FadeTrack")
	h.SetTime(1) -- halfway through fade-out
	Soundtrack.Library.OnUpdate()

	local calls = h.SetCVarCalls()
	IsTrue(#calls > 0, "SetCVar should be called while fading")
	local vol = calls[#calls]
	IsTrue(vol < 1.0, "Volume must be below 1 at mid-fade")
	IsTrue(vol >= 0.0, "Volume must be non-negative")
end

function Tests:FadeEnabled_FadeIn_RestoresVolumeAfterTrackStarts()
	EnableFade(2)
	SetupFadeTrack()

	local currentTime = 0
	local lastVolume  = nil
	Replace("GetTime",   function() return currentTime end)
	Replace("PlayMusic", function() end)
	Replace("StopMusic", function() end)
	Replace("GetCVar",   function(key)
		if key == "Sound_MusicVolume" then return "0.8" end
		return "0"
	end)
	Replace("SetCVar", function(key, value)
		if key == "Sound_MusicVolume" then lastVolume = tonumber(value) end
	end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)
	Replace(Soundtrack.Events, "GetCurrentEvent",      function() return { continuous = false } end)
	Replace(Soundtrack.Timers, "Remove",   function() end)
	Replace(Soundtrack.Timers, "AddTimer", function() end)

	Soundtrack.Library.PlayTrack("FadeTrack")
	currentTime = 2  -- fade-out complete, track starts + fade-in begins
	Soundtrack.Library.OnUpdate()
	currentTime = 4  -- fade-in complete
	Soundtrack.Library.OnUpdate()

	AreEqual(0.8, lastVolume, "Volume must be restored to 0.8 after fade-in completes")
end

function Tests:FadeEnabled_PlayTrack_NothingPlaying_PlaysImmediately()
	EnableFade(2)
	SetupFadeTrack()
	Soundtrack.Library.CurrentlyPlayingTrack = nil -- nothing currently playing
	local h = MakeFadeHelpers()

	-- With nothing playing, music must start during PlayTrack itself (not deferred to OnUpdate)
	Soundtrack.Library.PlayTrack("FadeTrack")

	IsTrue(h.PlayedPath() ~= nil, "Track must play immediately during PlayTrack when nothing is playing, even with fade enabled")
	AreEqual("Interface\\AddOns\\SoundtrackMusic\\FadeTrack.mp3", h.PlayedPath())
end

function Tests:FadeEnabled_PlayTrack_DuringFadeIn_InterruptsFadeInImmediately()
	EnableFade(2)
	Soundtrack_Tracks = {
		["ZoneTrack"]   = { length = 180, title = "Zone", mp3 = true },
		["CombatTrack"] = { length = 180, title = "Combat", mp3 = true },
	}

	local currentTime = 0
	local playedPaths = {}
	Replace("GetTime",   function() return currentTime end)
	Replace("PlayMusic", function(path) table.insert(playedPaths, path) end)
	Replace("StopMusic", function() end)
	Replace("SetCVar",   function() end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)
	Replace(Soundtrack.Events, "GetCurrentEvent",      function() return { continuous = false } end)
	Replace(Soundtrack.Timers, "Remove",   function() end)
	Replace(Soundtrack.Timers, "AddTimer", function() end)

	-- Zone track starts (simulating something already playing so fade is used)
	Soundtrack.Library.CurrentlyPlayingTrack = "ZoneTrack"
	Soundtrack.Library.PlayTrack("ZoneTrack") -- zone changes to a new zone; fade-out starts
	currentTime = 2                            -- fade-out complete -> zone plays, fade-in begins
	Soundtrack.Library.OnUpdate()

	-- Mid fade-in, combat starts
	currentTime = 3  -- 1s into a 2s fade-in
	Soundtrack.Library.PlayTrack("CombatTrack")

	-- Should immediately start a fade-out (not wait for fade-in to complete)
	-- Advance time past the new fade-out duration
	currentTime = 5
	Soundtrack.Library.OnUpdate()

	local lastPath = playedPaths[#playedPaths]
	AreEqual("Interface\\AddOns\\SoundtrackMusic\\CombatTrack.mp3", lastPath,
		"Combat track must play after fade-out completes, not wait for zone fade-in to finish")
end

function Tests:FadeEnabled_StopTrack_NothingPlaying_StopsInstantly()
	EnableFade(2)
	Soundtrack.Library.CurrentlyPlayingTrack = nil
	local stopCalled = false
	Replace("StopMusic", function() stopCalled = true end)
	Replace("SetCVar", function() end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 0 end)
	Replace(Soundtrack.Timers, "Remove", function() end)

	Soundtrack.Library.StopTrack()
	Soundtrack.Library.OnUpdate()

	IsTrue(stopCalled, "StopMusic should still be called even with nothing playing")
end

function Tests:FadeEnabled_StopTrack_FadesOutWithoutPlayingNewTrack()
	EnableFade(2)
	SetupFadeTrack()
	Soundtrack.Library.CurrentlyPlayingTrack = "FadeTrack"

	local stopCalled  = false
	local playCalled  = false
	local currentTime = 0
	Replace("GetTime",   function() return currentTime end)
	Replace("PlayMusic", function() playCalled = true end)
	Replace("StopMusic", function() stopCalled = true end)
	Replace("SetCVar",   function() end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)
	Replace(Soundtrack.Timers, "Remove",   function() end)
	Replace(Soundtrack.Timers, "AddTimer", function() end)

	Soundtrack.Library.StopTrack() -- no next track
	currentTime = 2
	Soundtrack.Library.OnUpdate()

	IsTrue(stopCalled,   "StopMusic must be called after fade-out")
	IsFalse(playCalled,  "PlayMusic must not be called when just stopping")
end

function Tests:FadeEnabled_SecondPlayTrackDuringFadeOut_PlaysLatestTrack()
	EnableFade(2)
	Soundtrack_Tracks = {
		["TrackA"] = { length = 180, title = "A", mp3 = true },
		["TrackB"] = { length = 180, title = "B", mp3 = true },
	}

	local currentTime = 0
	local playedPath  = nil
	Replace("GetTime",   function() return currentTime end)
	Replace("PlayMusic", function(path) playedPath = path end)
	Replace("StopMusic", function() end)
	Replace("SetCVar",   function() end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)
	Replace(Soundtrack.Events, "GetCurrentEvent",      function() return { continuous = false } end)
	Replace(Soundtrack.Timers, "Remove",   function() end)
	Replace(Soundtrack.Timers, "AddTimer", function() end)

	Soundtrack.Library.PlayTrack("TrackA")
	Soundtrack.Library.OnUpdate() -- fade-out starts for TrackA

	Soundtrack.Library.PlayTrack("TrackB") -- override target before fade completes
	currentTime = 2
	Soundtrack.Library.OnUpdate() -- fade-out completes, plays latest target

	IsTrue(playedPath ~= nil, "A track should have been played")
	AreEqual("Interface\\AddOns\\SoundtrackMusic\\TrackB.mp3", playedPath,
		"Should play the most recently requested track")
end

function Tests:FadeEnabled_OptionsTab_ToggleFadeTransition_TogglesFlag()
	SoundtrackAddon.db.profile.settings.FadeTransition = false
	Soundtrack.OptionsTab.ToggleFadeTransition()
	IsTrue(SoundtrackAddon.db.profile.settings.FadeTransition, "ToggleFadeTransition should turn it on")
	Soundtrack.OptionsTab.ToggleFadeTransition()
	IsFalse(SoundtrackAddon.db.profile.settings.FadeTransition, "ToggleFadeTransition should turn it off")
end

function Tests:FadeEnabled_OptionsTab_DurationDropDownOnClick_SavesDuration()
	-- Simulate selecting "1 second" (index 2 → 1 second value)
	SoundtrackUI.selectedFadeDuration = 1
	local mockSelf = { GetID = function() return 2 end }
	Replace("UIDropDownMenu_SetSelectedID", function() end)
	Soundtrack.OptionsTab.FadeTransitionDurationDropDown_OnClick(mockSelf)
	AreEqual(1, SoundtrackAddon.db.profile.settings.FadeTransitionDuration,
		"Selecting index 2 should save 1-second duration")
end

-- ---------------------------------------------------------------------------
-- Tests: OnMusicVolumeCVarChanged
-- ---------------------------------------------------------------------------

function Tests:OnMusicVolumeCVarChanged_WhenIdle_UpdatesSavedVolume()
	EnableFade(2)
	SetupFadeTrack()
	local h = MakeFadeHelpers()
	-- No fade in progress; volume change should be respected
	Replace("GetCVar", function(key)
		if key == "Sound_MusicVolume" then return "0.5" end
		return "0"
	end)

	Soundtrack.Library.OnMusicVolumeCVarChanged(0.6)

	-- Start a fade and confirm the new volume is used as the base
	Soundtrack.Library.PlayTrack("FadeTrack")
	h.SetTime(1) -- halfway through fade-out
	Soundtrack.Library.OnUpdate()

	local calls = h.SetCVarCalls()
	IsTrue(#calls > 0, "SetCVar should be called during fade")
	-- At t=1/2 of a 2s fade, volume should be around 0.5 * 0.6 = 0.3 (not 0.5 * 1.0)
	local vol = calls[#calls]
	IsTrue(vol <= 0.31, "Volume should be based on externally updated volume (0.6), not default 1.0")
end

function Tests:OnMusicVolumeCVarChanged_WhenFading_DoesNotUpdateSavedVolume()
	EnableFade(2)
	SetupFadeTrack()
	local currentTime = 0
	local lastSetVolume = nil
	Replace("GetTime",   function() return currentTime end)
	Replace("PlayMusic", function() end)
	Replace("StopMusic", function() end)
	Replace("GetCVar",   function(key)
		if key == "Sound_MusicVolume" then return "0.8" end
		return "0"
	end)
	Replace("SetCVar", function(key, value)
		if key == "Sound_MusicVolume" then lastSetVolume = tonumber(value) end
	end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)
	Replace(Soundtrack.Events, "GetCurrentEvent",      function() return { continuous = false } end)
	Replace(Soundtrack.Timers, "Remove",   function() end)
	Replace(Soundtrack.Timers, "AddTimer", function() end)

	-- Start a fade (savedMusicVolume captured as 0.8)
	Soundtrack.Library.PlayTrack("FadeTrack")
	currentTime = 1 -- mid-fade; now simulate external CVar change
	Soundtrack.Library.OnMusicVolumeCVarChanged(0.3) -- should be ignored during fade
	Soundtrack.Library.OnUpdate() -- continue fade

	-- Fade completes; volume should restore to original 0.8, not 0.3
	currentTime = 2
	Soundtrack.Library.OnUpdate()
	currentTime = 4 -- fade-in completes
	Soundtrack.Library.OnUpdate()

	AreEqual(0.8, lastSetVolume, "Volume should restore to 0.8 (original), ignoring mid-fade CVar change")
end

function Tests:SoundtrackAddon_CVAR_UPDATE_ForMusicVolume_CallsLibrary()
	local capturedVolume = nil
	Replace(Soundtrack.Library, "OnMusicVolumeCVarChanged", function(vol) capturedVolume = vol end)

	SoundtrackAddon:CVAR_UPDATE("Sound_MusicVolume", "0.75")

	AreEqual(0.75, capturedVolume, "Library.OnMusicVolumeCVarChanged called with parsed volume")
end

function Tests:SoundtrackAddon_CVAR_UPDATE_ForOtherCvar_DoesNotCallLibrary()
	local called = false
	Replace(Soundtrack.Library, "OnMusicVolumeCVarChanged", function() called = true end)

	SoundtrackAddon:CVAR_UPDATE("Sound_MasterVolume", "0.5")

	IsFalse(called, "Library.OnMusicVolumeCVarChanged must not be called for unrelated CVars")
end

function Tests:SoundtrackAddon_CVAR_UPDATE_InvalidValue_DefaultsToOne()
	local capturedVolume = nil
	Replace(Soundtrack.Library, "OnMusicVolumeCVarChanged", function(vol) capturedVolume = vol end)

	SoundtrackAddon:CVAR_UPDATE("Sound_MusicVolume", "badvalue")

	AreEqual(1, capturedVolume, "Defaults to 1 when value cannot be parsed as number")
end

-- ---------------------------------------------------------------------------
-- Tests: StopTrack during active fades (volume-stuck regression)
-- ---------------------------------------------------------------------------

-- Regression: StopTrack called during fading_in must restore the original volume,
-- not the intermediate low volume that was current at the moment of the call.
function Tests:FadeEnabled_StopTrackDuringFadeIn_RestoresOriginalVolume()
	EnableFade(2)
	Soundtrack_Tracks = {
		["Track1"] = { length = 180, title = "Track1", mp3 = true },
		["Track2"] = { length = 180, title = "Track2", mp3 = true },
	}

	local currentTime  = 0
	local lastVolume   = nil
	Replace("GetTime",   function() return currentTime end)
	Replace("PlayMusic", function() end)
	Replace("StopMusic", function() end)
	Replace("GetCVar",   function(key)
		if key == "Sound_MusicVolume" then return "0.8" end
		return "0"
	end)
	Replace("SetCVar", function(key, value)
		if key == "Sound_MusicVolume" then lastVolume = tonumber(value) end
	end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)
	Replace(Soundtrack.Events, "GetCurrentEvent",      function() return { continuous = false } end)
	Replace(Soundtrack.Timers, "Remove",   function() end)
	Replace(Soundtrack.Timers, "AddTimer", function() end)

	-- Something playing; play a new track (starts fade-out of old, then fade-in of new)
	Soundtrack.Library.CurrentlyPlayingTrack = "Track1"
	Soundtrack.Library.PlayTrack("Track2")
	currentTime = 2        -- fade-out complete; Track2 starts + fade-in begins
	Soundtrack.Library.OnUpdate()

	-- Mid fade-in at t=3  (1s into 2s fade-in → vol ≈ 0.4)
	currentTime = 3
	Soundtrack.Library.OnUpdate()

	-- StopTrack called while volume is partway up
	Soundtrack.Library.StopTrack()

	-- Advance through the full stop fade-out
	currentTime = 5
	Soundtrack.Library.OnUpdate()

	-- Volume must be restored to the original 0.8, not the ~0.4 captured mid-fade-in
	AreEqual(0.8, lastVolume, "Volume must restore to 0.8 after StopTrack during fade-in, not the intermediate value")
end

-- Regression: StopTrack called a second time during an already-running fading_out
-- must not restart the fade (which would pop volume back up) and must still
-- restore to the original volume when complete.
function Tests:FadeEnabled_StopTrackDuringFadeOut_DoesNotRestartFade()
	EnableFade(2)
	SetupFadeTrack()
	Soundtrack.Library.CurrentlyPlayingTrack = "FadeTrack"

	local currentTime  = 0
	local volumeHistory = {}
	Replace("GetTime",   function() return currentTime end)
	Replace("PlayMusic", function() end)
	Replace("StopMusic", function() end)
	Replace("GetCVar",   function(key)
		if key == "Sound_MusicVolume" then return "0.8" end
		return "0"
	end)
	Replace("SetCVar", function(key, value)
		if key == "Sound_MusicVolume" then table.insert(volumeHistory, tonumber(value)) end
	end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)
	Replace(Soundtrack.Events, "GetCurrentEvent",      function() return { continuous = false } end)
	Replace(Soundtrack.Timers, "Remove",   function() end)
	Replace(Soundtrack.Timers, "AddTimer", function() end)

	-- First StopTrack: starts fade-out from 0.8
	Soundtrack.Library.StopTrack()
	currentTime = 1  -- halfway through the 2s fade-out; vol ≈ 0.4
	Soundtrack.Library.OnUpdate()

	-- Capture the volume at the halfway point
	local volAtHalfway = volumeHistory[#volumeHistory]
	IsTrue(volAtHalfway < 0.8, "Volume should be below 0.8 halfway through fade-out")

	-- Second StopTrack (e.g. another event fires): must NOT restart / pop volume back up
	Soundtrack.Library.StopTrack()
	currentTime = 1.01
	Soundtrack.Library.OnUpdate()
	local volAfterSecondStop = volumeHistory[#volumeHistory]
	IsTrue(volAfterSecondStop <= volAtHalfway + 0.01,
		"Second StopTrack must not pop volume back up above halfway value")

	-- Complete fade-out; original volume must be restored
	currentTime = 2
	Soundtrack.Library.OnUpdate()
	local lastVolume = volumeHistory[#volumeHistory]
	AreEqual(0.8, lastVolume, "Volume must restore to 0.8 (original) after fade-out completes")
end
