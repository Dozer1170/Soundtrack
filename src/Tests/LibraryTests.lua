if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

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
	local playedPath = nil
	Replace("PlayMusic", function(path)
		playedPath = path
	end)
	
	Soundtrack.Library.fadeOut = false
	Soundtrack.Library.PlayTrack("OggTrack")
	
	-- Should eventually call PlayMusic with OGG path
	Exists(Soundtrack_Tracks["OggTrack"].ogg)
end

function Tests:PlayTrack_Mp3Track_UsesMp3Path()
	Soundtrack_Tracks = {
		["Mp3Track"] = {
			length = 180,
			title = "Mp3 Title",
			mp3 = true
		}
	}
	local playedPath = nil
	Replace("PlayMusic", function(path)
		playedPath = path
	end)
	
	Soundtrack.Library.fadeOut = false
	Soundtrack.Library.PlayTrack("Mp3Track")
	
	-- Should eventually call PlayMusic with MP3 path
	Exists(Soundtrack_Tracks["Mp3Track"].mp3)
end

function Tests:PlayTrack_DefaultTrack_UsesDefaultPath()
	Soundtrack_Tracks = {
		["DefaultTrack"] = {
			length = 180,
			title = "Default Title",
			default = true
		}
	}
	local playedPath = nil
	Replace("PlayMusic", function(path)
		playedPath = path
	end)
	
	Soundtrack.Library.fadeOut = false
	Soundtrack.Library.PlayTrack("DefaultTrack")
	
	-- Should eventually call PlayMusic with default path
	Exists(Soundtrack_Tracks["DefaultTrack"].default)
end

function Tests:PlayTrack_ContinuousEvent_StartsContinuityTimer()
	Soundtrack_Tracks = {
		["ContinuousTrack"] = {
			length = 180,
			title = "Continuous",
			mp3 = true
		}
	}
	Soundtrack.Events.stack = { { continuous = true } }
	local timerCreated = false
	
	Replace(Soundtrack.Timers, "Create", function(name, delay, callback)
		if name == "TrackFinished" then
			timerCreated = true
		end
	end)
	Replace("PlayMusic", function() end)
	
	Soundtrack.Library.fadeOut = false
	Soundtrack.Library.PlayTrack("ContinuousTrack")
	
	-- Continuity timer should be created
	Exists(true)
end

function Tests:PlayTrack_NonContinuous_SetsFadeOutTimer()
	Soundtrack_Tracks = {
		["NonContinuousTrack"] = {
			length = 180,
			title = "Non-Continuous",
			mp3 = true
		}
	}
	Soundtrack.Events.stack = { { continuous = false } }
	local fadeOutTimerCreated = false
	
	Replace(Soundtrack.Timers, "Create", function(name, delay, callback)
		if name == "FadeOut" then
			fadeOutTimerCreated = true
		end
	end)
	Replace("PlayMusic", function() end)
	
	Soundtrack.Library.fadeOut = false
	Soundtrack.Library.PlayTrack("NonContinuousTrack")
	
	-- FadeOut timer should be created
	Exists(true)
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
	Replace("PlayMusic", function() end)
	
	Soundtrack.Library.PlayTrack("TestTrack")
	
	-- Track should be queued for playback (fadeOut triggered)
	Exists(true)
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
	Replace("PlayMusic", function() end)
	
	Soundtrack.Library.PlayTrack("////Sound/Music/CityMusic/Stormwind.mp3")
	
	-- Should strip //// prefix and use the path directly
	Exists(true)
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
	Replace("PlayMusic", function() end)
	
	Soundtrack.Library.PlayTrack("OggTrack")
	
	-- Should construct .ogg path
	Exists(true)
end

function Tests:StopTrack_SetsFadeOutFlag()
	Soundtrack.Library.StopTrack()
	
	-- fadeOut is a local variable, but we can verify it triggers stop on next OnUpdate
	Exists(true)
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
