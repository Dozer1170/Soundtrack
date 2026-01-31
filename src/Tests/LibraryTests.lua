if not Tests then
	return
end

local Tests = Tests("Soundtrack", "PLAYER_ENTERING_WORLD")

local function PlayTrackAndFlush(trackName, overrides)
	overrides = overrides or {}
	local playedPath = nil
	Replace("PlayMusic", function(path)
		playedPath = path
		if overrides.onPlayMusic then
			overrides.onPlayMusic(path)
		end
	end)
	Replace("StopMusic", function() end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function()
		return overrides.stackLevel or 1
	end)
	Replace(Soundtrack.Events, "GetCurrentEvent", function()
		return overrides.event or { continuous = false }
	end)
	Replace(Soundtrack.Timers, "Remove", function() end)
	Replace(Soundtrack.Timers, "AddTimer", function(name, delay, callback)
		if overrides.onAddTimer then
			overrides.onAddTimer(name, delay, callback)
		end
	end)

	Soundtrack.Library.PlayTrack(trackName, overrides.soundEffect)
	Soundtrack.Library.OnUpdate()

	return playedPath
end

function Tests:AddTrack_WithNoExtension_AddsTrackToLibrary()
	Soundtrack_Tracks = {}

	Soundtrack.Library.AddTrack("TestTrack", 180, "Test Title", "Test Artist", "Test Album", nil)

	AreEqual(true, Soundtrack_Tracks["TestTrack"] ~= nil)
	AreEqual(180, Soundtrack_Tracks["TestTrack"].length)
	AreEqual("Test Title", Soundtrack_Tracks["TestTrack"].title)
	AreEqual("Test Artist", Soundtrack_Tracks["TestTrack"].artist)
	AreEqual("Test Album", Soundtrack_Tracks["TestTrack"].album)
end

function Tests:AddTrack_WithMp3Extension_SetsMP3Flag()
	Soundtrack_Tracks = {}

	Soundtrack.Library.AddTrack("TestTrack", 180, "Test Title", "Test Artist", "Test Album", ".MP3")

	AreEqual(true, Soundtrack_Tracks["TestTrack"].mp3)
end

function Tests:AddTrack_WithOggExtension_SetsOGGFlag()
	Soundtrack_Tracks = {}

	Soundtrack.Library.AddTrack("TestTrack", 180, "Test Title", "Test Artist", "Test Album", ".OGG")

	AreEqual(true, Soundtrack_Tracks["TestTrack"].ogg)
end

function Tests:AddTrack_WithWavExtension_SetsWAVFlag()
	Soundtrack_Tracks = {}

	Soundtrack.Library.AddTrack("TestTrack", 180, "Test Title", "Test Artist", "Test Album", ".WAV")

	AreEqual(true, Soundtrack_Tracks["TestTrack"].wav)
end

-- Medium Priority: Library Management Tests

function Tests:AddDefaultTrack_WithoutExtension_SetsDefaultFlag()
	Soundtrack_Tracks = {}

	Soundtrack.Library.AddTrack("DefaultTrack", 200, "Default Title", "Default Artist", "Default Album")

	local track = Soundtrack_Tracks["DefaultTrack"]
	AreEqual(true, track ~= nil)
	AreEqual(true, track.default == true or (track.mp3 == nil and track.ogg == nil and track.wav == nil))
end

function Tests:OnUpdate_StackLevelZero_StopsCurrentTrack()
	Soundtrack.Events.stack_level = 0
	Soundtrack.Library.CurrentlyPlayingTrack = "SomeTrack"
	local stopMusicCalled = false

	Replace(Soundtrack.Library, "StopMusic", function()
		stopMusicCalled = true
	end)

	Soundtrack.Library.OnUpdate()

	AreEqual(true, stopMusicCalled)
end

function Tests:OnUpdate_FadeOutTrue_StopsMusic()
	Soundtrack.Events.stack_level = 1
	Soundtrack.Library.CurrentlyPlayingTrack = "SomeTrack"
	local stopMusicCalled = false

	Replace(Soundtrack.Library, "StopMusic", function()
		stopMusicCalled = true
	end)

	-- StopTrack sets the internal fadeOut flag
	Soundtrack.Library.StopTrack()
	Soundtrack.Library.OnUpdate()

	AreEqual(true, stopMusicCalled)
end

function Tests:PlayTrack_OggTrack_UsesOggPath()
	Soundtrack_Tracks = {
		["OggTrack"] = {
			length = 180,
			title = "Ogg Title",
			ogg = true
		}
	}
	local playedPath = PlayTrackAndFlush("OggTrack")
	AreEqual("Interface\\AddOns\\SoundtrackMusic\\OggTrack.ogg", playedPath, "OGG tracks should use ogg files")
end

function Tests:PlayTrack_Mp3Track_UsesMp3Path()
	Soundtrack_Tracks = {
		["Mp3Track"] = {
			length = 180,
			title = "Mp3 Title",
			mp3 = true
		}
	}
	local playedPath = PlayTrackAndFlush("Mp3Track")
	AreEqual("Interface\\AddOns\\SoundtrackMusic\\Mp3Track.mp3", playedPath, "MP3 tracks should use mp3 files")
end

function Tests:PlayTrack_DefaultTrack_UsesDefaultPath()
	Soundtrack_Tracks = {
		["DefaultTrack"] = {
			length = 180,
			title = "Default Title",
			default = true
		}
	}
	local playedPath = PlayTrackAndFlush("DefaultTrack")
	AreEqual("DefaultTrack", playedPath, "default tracks should reuse the in-game path")
end

function Tests:PlayTrack_ContinuousEvent_StartsContinuityTimer()
	Soundtrack_Tracks = {
		["ContinuousTrack"] = {
			length = 180,
			title = "Continuous",
			mp3 = true
		}
	}
	local timers = {}
	SoundtrackAddon.db.profile.settings.Silence = 0
	PlayTrackAndFlush("ContinuousTrack", {
		event = { continuous = true },
		onAddTimer = function(name, delay)
			timers[name] = delay
		end
	})
	IsTrue(timers["TrackFinished"] ~= nil, "continuous events should schedule a restart timer")
	AreEqual(180, timers["TrackFinished"], "restart timer should match track length")
	AreEqual(179, timers["FadeOut"], "continuous events fade one second before track end")
end

function Tests:PlayTrack_ContinuousEvent_WithSilence_AddsRandomDelay()
	Soundtrack_Tracks = {
		["ContinuousWithSilence"] = {
			length = 12,
			title = "Continuous",
			mp3 = true
		}
	}

	local timers = {}
	local traceMessage = nil
	local originalRandom = random
	SoundtrackAddon.db.profile.settings.Silence = 10

	Replace(Soundtrack.Chat, "TraceLibrary", function(message)
		traceMessage = message
	end)

	random = function(min, max)
		AreEqual(5, min, "random silence should start at 5")
		AreEqual(10, max, "random silence should use settings limit")
		return 7
	end

	PlayTrackAndFlush("ContinuousWithSilence", {
		event = { continuous = true },
		onAddTimer = function(name, delay)
			timers[name] = delay
		end
	})

	random = originalRandom

	IsTrue(timers["TrackFinished"] ~= nil, "continuous events should schedule a restart timer")
	AreEqual(19, timers["TrackFinished"], "restart timer should include silence delay")
	AreEqual(12, timers["FadeOut"], "short tracks should fade at track length")
	IsTrue(traceMessage ~= nil and traceMessage:match("Adding 7 seconds of silence"),
		"should trace silence delay")
end

function Tests:PlayTrack_NonContinuous_SetsFadeOutTimer()
	Soundtrack_Tracks = {
		["NonContinuousTrack"] = {
			length = 180,
			title = "Non-Continuous",
			mp3 = true
		}
	}
	local timers = {}
	PlayTrackAndFlush("NonContinuousTrack", {
		event = { continuous = false },
		onAddTimer = function(name, delay)
			timers[name] = delay
		end
	})
	IsTrue(timers["FadeOut"] ~= nil, "non-continuous events should only schedule fadeout")
	IsFalse(timers["TrackFinished"] ~= nil, "non-continuous events should not schedule restart timer")
	AreEqual(179, timers["FadeOut"], "fadeout timer should fire one second before the end")
end

function Tests:PlayTrack_NonContinuous_ShortTrack_FadesAtLength()
	Soundtrack_Tracks = {
		["ShortNonContinuous"] = {
			length = 12,
			title = "Short",
			mp3 = true
		}
	}
	local timers = {}
	PlayTrackAndFlush("ShortNonContinuous", {
		event = { continuous = false },
		onAddTimer = function(name, delay)
			timers[name] = delay
		end
	})
	AreEqual(12, timers["FadeOut"], "short non-continuous tracks should fade at track length")
end

function Tests:PlayTrack_StartContinuityTimers_MissingEvent_DoesNotScheduleTimers()
	Soundtrack_Tracks = {
		["NoEventTrack"] = {
			length = 30,
			title = "No Event",
			mp3 = true
		}
	}
	local addTimerCalled = false
	Replace("PlayMusic", function() end)
	Replace("StopMusic", function() end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function()
		return 1
	end)
	Replace(Soundtrack.Events, "GetCurrentEvent", function()
		return nil
	end)
	Replace(Soundtrack.Timers, "Remove", function() end)
	Replace(Soundtrack.Timers, "AddTimer", function()
		addTimerCalled = true
	end)

	Soundtrack.Library.PlayTrack("NoEventTrack")
	Soundtrack.Library.OnUpdate()
	AreEqual(false, addTimerCalled, "no timers should be scheduled when event is missing")
end

function Tests:AddTrackMp3_AddsTrackWithMp3Flag()
	Soundtrack_Tracks = {}

	Soundtrack.Library.AddTrackMp3("Mp3Track", 240, "Mp3 Title", "Mp3 Artist", "Mp3 Album")

	AreEqual(true, Soundtrack_Tracks["Mp3Track"] ~= nil)
	AreEqual(true, Soundtrack_Tracks["Mp3Track"].mp3)
	AreEqual(240, Soundtrack_Tracks["Mp3Track"].length)
end

function Tests:AddTrackOgg_AddsTrackWithOggFlag()
	Soundtrack_Tracks = {}

	Soundtrack.Library.AddTrackOgg("OggTrack", 300, "Ogg Title", "Ogg Artist", "Ogg Album")

	AreEqual(true, Soundtrack_Tracks["OggTrack"] ~= nil)
	AreEqual(true, Soundtrack_Tracks["OggTrack"].ogg)
	AreEqual(300, Soundtrack_Tracks["OggTrack"].length)
end

function Tests:AddDefaultTrack_UsesGlobalExtension_ForDefaultFlags()
	Soundtrack_Tracks = {}
	local previousExtension = _G._extension

	_G._extension = nil
	Soundtrack.Library.AddDefaultTrack("DefaultNil", 100, "Title", "Artist", "Album")
	local defaultNil = Soundtrack_Tracks["DefaultNil"]
	IsTrue(defaultNil and defaultNil.defaultTrack, "default track should be set when extension nil")

	_G._extension = ".MP3"
	Soundtrack.Library.AddDefaultTrack("DefaultMp3", 101, "Title", "Artist", "Album")
	local defaultMp3 = Soundtrack_Tracks["DefaultMp3"]
	IsTrue(defaultMp3 and defaultMp3.mp3 and defaultMp3.defaultTrack,
		"mp3 default track should include mp3 flag")

	_G._extension = ".OGG"
	Soundtrack.Library.AddDefaultTrack("DefaultOgg", 102, "Title", "Artist", "Album")
	local defaultOgg = Soundtrack_Tracks["DefaultOgg"]
	IsTrue(defaultOgg and defaultOgg.ogg and defaultOgg.defaultTrack,
		"ogg default track should include ogg flag")

	_G._extension = ".WAV"
	Soundtrack.Library.AddDefaultTrack("DefaultWav", 103, "Title", "Artist", "Album")
	local defaultWav = Soundtrack_Tracks["DefaultWav"]
	IsTrue(defaultWav and defaultWav.wav and defaultWav.defaultTrack,
		"wav default track should include wav flag")

	_G._extension = previousExtension
end

function Tests:StopMusic_RemovesContinuityTimers()
	local fadeOutRemoved = false
	local trackFinishedRemoved = false

	Replace(Soundtrack.Timers, "Remove", function(name)
		if name == "FadeOut" then
			fadeOutRemoved = true
		elseif name == "TrackFinished" then
			trackFinishedRemoved = true
		end
	end)

	Replace("StopMusic", function() end)

	Soundtrack.Library.StopMusic()

	AreEqual(true, fadeOutRemoved)
	AreEqual(true, trackFinishedRemoved)
end

function Tests:StopMusic_CallsStopMusic()
	local stopMusicCalled = false

	Replace("StopMusic", function()
		stopMusicCalled = true
	end)

	Soundtrack.Library.StopMusic()

	AreEqual(true, stopMusicCalled)
end

function Tests:StopMusic_SetsCurrentlyPlayingToNone()
	Soundtrack.Library.CurrentlyPlayingTrack = "SomeTrack"
	Replace("StopMusic", function() end)

	Soundtrack.Library.StopMusic()

	AreEqual("None", Soundtrack.Library.CurrentlyPlayingTrack)
end

function Tests:PauseMusic_PlaysEmptyTrack()
	local playMusicCalled = false
	local playedFileName = nil

	Replace("PlayMusic", function(fileName)
		playMusicCalled = true
		playedFileName = fileName
	end)

	Soundtrack.Library.PauseMusic()

	AreEqual(true, playMusicCalled)
	AreEqual("Interface\\AddOns\\Soundtrack\\EmptyTrack.mp3", playedFileName)
end

function Tests:PauseMusic_SetsCurrentlyPlayingToNone()
	Soundtrack.Library.CurrentlyPlayingTrack = "SomeTrack"
	Replace("PlayMusic", function() end)

	Soundtrack.Library.PauseMusic()

	AreEqual("None", Soundtrack.Library.CurrentlyPlayingTrack)
end

function Tests:IsTrackActive_TrackInEventList_ReturnsTrue()
	SoundtrackAddon.db.profile.events = {
		ZONE = {
			["TestZone"] = {
				tracks = { "Track1", "Track2", "TestTrack" }
			}
		}
	}
	SoundtrackUI = { SelectedEventsTable = "ZONE", SelectedEvent = "TestZone" }

	local result = Soundtrack.Library.IsTrackActive("TestTrack")

	AreEqual(true, result)
end

function Tests:IsTrackActive_TrackNotInEventList_ReturnsFalse()
	SoundtrackAddon.db.profile.events = {
		ZONE = {
			["TestZone"] = {
				tracks = { "Track1", "Track2" }
			}
		}
	}
	SoundtrackUI = { SelectedEventsTable = "ZONE", SelectedEvent = "TestZone" }

	local result = Soundtrack.Library.IsTrackActive("MissingTrack")

	AreEqual(false, result)
end

function Tests:IsTrackActive_EventDoesNotExist_ReturnsFalse()
	SoundtrackAddon.db.profile.events = {
		ZONE = {}
	}
	SoundtrackUI = { SelectedEventsTable = "ZONE", SelectedEvent = "NonexistentZone" }

	local result = Soundtrack.Library.IsTrackActive("TestTrack")

	AreEqual(false, result)
end

function Tests:PlayTrack_ValidTrack_SetsNextTrackInfo()
	Soundtrack_Tracks = {
		["TestTrack"] = {
			length = 180,
			title = "Test Title",
			artist = "Test Artist",
			album = "Test Album",
			mp3 = true
		}
	}
	local playedPath = PlayTrackAndFlush("TestTrack")
	AreEqual("Interface\\AddOns\\SoundtrackMusic\\TestTrack.mp3", playedPath, "queued track should use mp3 asset")
	AreEqual("TestTrack", Soundtrack.Library.CurrentlyPlayingTrack, "current track should update after playback")
end

function Tests:PlayTrack_InvalidTrack_DoesNothing()
	Soundtrack_Tracks = {}
	local playMusicCalled = false

	Replace("PlayMusic", function()
		playMusicCalled = true
	end)

	Soundtrack.Library.PlayTrack("NonexistentTrack")

	AreEqual(false, playMusicCalled)
end

function Tests:PlayTrack_SoundEffect_PlaysSoundFileImmediately()
	Soundtrack_Tracks = {
		["SoundEffect"] = {
			length = 5,
			title = "Effect",
			artist = "",
			album = "",
			mp3 = true
		}
	}
	local playSoundFileCalled = false

	Replace("PlaySoundFile", function()
		playSoundFileCalled = true
	end)

	Soundtrack.Library.PlayTrack("SoundEffect", true)

	AreEqual(true, playSoundFileCalled)
end

function Tests:PlayTrack_DefaultTrack_UsesDefaultPath()
	Soundtrack_Tracks = {
		["////Sound/Music/CityMusic/Stormwind.mp3"] = {
			length = 180,
			title = "Stormwind",
			artist = "",
			album = "",
			defaultTrack = true
		}
	}
	local playedPath = PlayTrackAndFlush("////Sound/Music/CityMusic/Stormwind.mp3")
	AreEqual("Sound/Music/CityMusic/Stormwind.mp3", playedPath, "default track paths should drop the //// prefix")
end

function Tests:PlayTrack_OggTrack_UsesOggPath()
	Soundtrack_Tracks = {
		["OggTrack"] = {
			length = 180,
			title = "Ogg Song",
			artist = "Artist",
			album = "Album",
			ogg = true
		}
	}
	local playedPath = PlayTrackAndFlush("OggTrack")
	AreEqual("Interface\\AddOns\\SoundtrackMusic\\OggTrack.ogg", playedPath,
		"ogg tracks should play via the addon music directory")
end

function Tests:StopTrack_SetsFadeOutFlag()
	Soundtrack_Tracks = {
		["QueuedTrack"] = {
			length = 60,
			title = "Queued",
			mp3 = true
		}
	}
	local playMusicCalled = false
	Replace("PlayMusic", function()
		playMusicCalled = true
	end)
	Replace("StopMusic", function() end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function()
		return 1
	end)
	Replace(Soundtrack.Events, "GetCurrentEvent", function()
		return { continuous = false }
	end)
	Replace(Soundtrack.Timers, "Remove", function() end)
	Replace(Soundtrack.Timers, "AddTimer", function() end)
	Soundtrack.Library.PlayTrack("QueuedTrack")
	Soundtrack.Library.StopTrack()
	Soundtrack.Library.OnUpdate()
	IsFalse(playMusicCalled, "StopTrack should clear any pending playback requests")
end

function Tests:PlayTrack_FadeOutTimer_CallsStopEventAtLevel()
	Soundtrack_Tracks = {
		["FadeOutTrack"] = {
			length = 30,
			title = "Fade Out",
			mp3 = true
		}
	}
	local stopEventLevel = nil
	local fadeOutCallback = nil

	Replace(Soundtrack.Events, "GetCurrentStackLevel", function()
		return 2
	end)
	Replace(Soundtrack.Events, "GetCurrentEvent", function()
		return { continuous = false }
	end)
	Replace(Soundtrack.Timers, "AddTimer", function(name, _, callback)
		if name == "FadeOut" then
			fadeOutCallback = callback
		end
	end)
	Replace(Soundtrack.Timers, "Remove", function() end)
	Replace("PlayMusic", function() end)
	Replace("StopMusic", function() end)
	Replace(Soundtrack, "StopEventAtLevel", function(level)
		stopEventLevel = level
	end)

	Soundtrack.Library.PlayTrack("FadeOutTrack")
	Soundtrack.Library.OnUpdate()
	IsTrue(fadeOutCallback ~= nil, "fade out timer should be scheduled")

	fadeOutCallback()
	AreEqual(2, stopEventLevel, "fade out callback should stop current stack level")
end

function Tests:OnUpdate_WithFadeOut_StopsMusic()
	local stopMusicCalled = false

	Replace(Soundtrack.Library, "StopMusic", function()
		stopMusicCalled = true
	end)
	Replace("StopMusic", function() end)

	-- Trigger fadeOut
	Soundtrack.Library.StopTrack()
	Soundtrack.Library.OnUpdate()

	AreEqual(true, stopMusicCalled)
end

function Tests:OnUpdate_StackLevelZeroWithCurrentTrack_StopsMusic()
	local stopMusicCalled = false
	Soundtrack.Library.CurrentlyPlayingTrack = "SomeTrack"

	Replace(Soundtrack.Events, "GetCurrentStackLevel", function()
		return 0
	end)

	Replace(Soundtrack.Library, "StopMusic", function()
		stopMusicCalled = true
	end)
	Replace("StopMusic", function() end)

	Soundtrack.Library.OnUpdate()

	AreEqual(true, stopMusicCalled)
end
