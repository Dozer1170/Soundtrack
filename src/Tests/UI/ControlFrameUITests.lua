if not Tests then
	return
end

local Tests = Tests("ControlFrameUI", "PLAYER_ENTERING_WORLD")

-- Button Click Handler Tests

function Tests:OnNextButtonClick_CallsPlaybackNext()
	local called = false
	Replace(Soundtrack.Events, "PlaybackNext", function() called = true end)

	SoundtrackUI.ControlFrame.OnNextButtonClick()

	IsTrue(called, "PlaybackNext was called")
end

function Tests:OnStopButtonClick_CallsPlaybackPlayStop()
	local called = false
	Replace(Soundtrack.Events, "PlaybackPlayStop", function() called = true end)

	SoundtrackUI.ControlFrame.OnStopButtonClick()

	IsTrue(called, "PlaybackPlayStop was called")
end

function Tests:OnPlayButtonClick_CallsPlaybackPlayStop()
	local called = false
	Replace(Soundtrack.Events, "PlaybackPlayStop", function() called = true end)

	SoundtrackUI.ControlFrame.OnPlayButtonClick()

	IsTrue(called, "PlaybackPlayStop was called")
end

function Tests:OnPreviousButtonClick_CallsPlaybackPrevious()
	local called = false
	Replace(Soundtrack.Events, "PlaybackPrevious", function() called = true end)

	SoundtrackUI.ControlFrame.OnPreviousButtonClick()

	IsTrue(called, "PlaybackPrevious was called")
end

function Tests:OnTrueStopButtonClick_CallsPlaybackTrueStop()
	local called = false
	Replace(Soundtrack.Events, "PlaybackTrueStop", function() called = true end)

	SoundtrackUI.ControlFrame.OnTrueStopButtonClick()

	IsTrue(called, "PlaybackTrueStop was called")
end

-- Info Button Tests

function Tests:OnInfoButtonClick_WithNoTrack_DoesNotCallSetNowPlayingText()
	local called = false
	Replace(SoundtrackUI.NowPlayingFrame, "SetNowPlayingText", function() called = true end)
	Soundtrack.Library.CurrentlyPlayingTrack = nil

	SoundtrackUI.ControlFrame.OnInfoButtonClick()

	IsFalse(called, "SetNowPlayingText not called when no track")
end

function Tests:OnInfoButtonClick_WithTrackNone_DoesNotCallSetNowPlayingText()
	local called = false
	Replace(SoundtrackUI.NowPlayingFrame, "SetNowPlayingText", function() called = true end)
	Soundtrack.Library.CurrentlyPlayingTrack = "None"

	SoundtrackUI.ControlFrame.OnInfoButtonClick()

	IsFalse(called, "SetNowPlayingText not called when track is 'None'")
end

function Tests:OnInfoButtonClick_WithValidTrack_CallsSetNowPlayingText()
	local capturedTitle, capturedArtist, capturedAlbum
	Replace(SoundtrackUI.NowPlayingFrame, "SetNowPlayingText", function(title, artist, album)
		capturedTitle = title
		capturedArtist = artist
		capturedAlbum = album
	end)

	Soundtrack.Library.CurrentlyPlayingTrack = "Sound/Music/Test.mp3"
	Soundtrack_Tracks["Sound/Music/Test.mp3"] = {
		title = "Test Track",
		artist = "Test Artist",
		album = "Test Album",
	}

	SoundtrackUI.ControlFrame.OnInfoButtonClick()

	AreEqual("Test Track", capturedTitle, "Title passed correctly")
	AreEqual("Test Artist", capturedArtist, "Artist passed correctly")
	AreEqual("Test Album", capturedAlbum, "Album passed correctly")
end

-- Button Alpha Tests

function Tests:OnNextButtonEnter_SetsAlphaToFull()
	local alpha = nil
	_G["SoundtrackControlFrame_NextButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "ShowTip", function() end)

	SoundtrackUI.ControlFrame.OnNextButtonEnter(SoundtrackControlFrame_NextButton)

	AreEqual(1.0, alpha, "Alpha set to 1.0 on enter")
end

function Tests:OnNextButtonLeave_SetsAlphaToPartial()
	local alpha = nil
	_G["SoundtrackControlFrame_NextButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "HideTip", function() end)

	SoundtrackUI.ControlFrame.OnNextButtonLeave()

	AreEqual(0.6, alpha, "Alpha set to 0.6 on leave")
end

function Tests:OnStopButtonEnter_SetsAlphaToFull()
	local alpha = nil
	_G["SoundtrackControlFrame_StopButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "ShowTip", function() end)

	SoundtrackUI.ControlFrame.OnStopButtonEnter(SoundtrackControlFrame_StopButton)

	AreEqual(1.0, alpha, "Alpha set to 1.0 on enter")
end

function Tests:OnStopButtonLeave_SetsAlphaToPartial()
	local alpha = nil
	_G["SoundtrackControlFrame_StopButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "HideTip", function() end)

	SoundtrackUI.ControlFrame.OnStopButtonLeave()

	AreEqual(0.6, alpha, "Alpha set to 0.6 on leave")
end

function Tests:OnTrueStopButtonEnter_SetsAlphaToFull()
	local alpha = nil
	_G["SoundtrackControlFrame_TrueStopButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "ShowTip", function() end)

	SoundtrackUI.ControlFrame.OnTrueStopButtonEnter(SoundtrackControlFrame_TrueStopButton)

	AreEqual(1.0, alpha, "Alpha set to 1.0 on enter")
end

function Tests:OnInfoButtonLeave_SetsAlphaToPartial()
	local alpha = nil
	_G["SoundtrackControlFrame_InfoButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "HideTip", function() end)

	SoundtrackUI.ControlFrame.OnInfoButtonLeave()

	AreEqual(0.6, alpha, "Alpha set to 0.6 on leave")
end

-- Play button Enter/Leave Tests (currently uncovered)

function Tests:OnPlayButtonEnter_SetsAlphaToFull()
	local alpha = nil
	_G["SoundtrackControlFrame_PlayButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "ShowTip", function() end)

	SoundtrackUI.ControlFrame.OnPlayButtonEnter(SoundtrackControlFrame_PlayButton)

	AreEqual(1.0, alpha, "Alpha set to 1.0 on enter")
end

function Tests:OnPlayButtonLeave_SetsAlphaToPartial()
	local alpha = nil
	_G["SoundtrackControlFrame_PlayButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "HideTip", function() end)

	SoundtrackUI.ControlFrame.OnPlayButtonLeave()

	AreEqual(0.6, alpha, "Alpha set to 0.6 on leave")
end

-- Previous button Enter/Leave Tests (currently uncovered)

function Tests:OnPreviousButtonEnter_SetsAlphaToFull()
	local alpha = nil
	_G["SoundtrackControlFrame_PreviousButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "ShowTip", function() end)

	SoundtrackUI.ControlFrame.OnPreviousButtonEnter(SoundtrackControlFrame_PreviousButton)

	AreEqual(1.0, alpha, "Alpha set to 1.0 on enter")
end

function Tests:OnPreviousButtonLeave_SetsAlphaToPartial()
	local alpha = nil
	_G["SoundtrackControlFrame_PreviousButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "HideTip", function() end)

	SoundtrackUI.ControlFrame.OnPreviousButtonLeave()

	AreEqual(0.6, alpha, "Alpha set to 0.6 on leave")
end

-- TrueStop button Leave Test (currently uncovered)

function Tests:OnTrueStopButtonLeave_SetsAlphaToPartial()
	local alpha = nil
	_G["SoundtrackControlFrame_TrueStopButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "HideTip", function() end)

	SoundtrackUI.ControlFrame.OnTrueStopButtonLeave()

	AreEqual(0.6, alpha, "Alpha set to 0.6 on leave")
end

-- OnInfoButtonEnter Tests (currently uncovered branches)

function Tests:OnInfoButtonEnter_WithValidTrack_CallsShowTipWithTrackInfo()
	local capturedTitle, capturedArtist, capturedAlbum
	Replace(Soundtrack, "ShowTip", function(_, title, _, artist, album)
		capturedTitle = title
		capturedArtist = artist
		capturedAlbum = album
	end)

	Soundtrack.Library.CurrentlyPlayingTrack = "Sound/Music/TestInfo.mp3"
	Soundtrack_Tracks["Sound/Music/TestInfo.mp3"] = {
		title = "Info Track",
		artist = "Info Artist",
		album = "Info Album",
	}

	SoundtrackUI.ControlFrame.OnInfoButtonEnter(SoundtrackControlFrame_InfoButton)

	AreEqual("Info Track", capturedTitle, "Title passed to ShowTip")
	AreEqual("Info Artist", capturedArtist, "Artist passed to ShowTip")
	AreEqual("Info Album", capturedAlbum, "Album passed to ShowTip")
end

function Tests:OnInfoButtonEnter_WithNoTrack_CallsShowTipWithGenericInfo()
	local capturedTitle
	Replace(Soundtrack, "ShowTip", function(_, title)
		capturedTitle = title
	end)
	Soundtrack.Library.CurrentlyPlayingTrack = nil

	SoundtrackUI.ControlFrame.OnInfoButtonEnter(SoundtrackControlFrame_InfoButton)

	AreEqual(SOUNDTRACK_INFO, capturedTitle, "Generic info tip shown when no track playing")
end

function Tests:OnInfoButtonEnter_SetsAlphaToFull()
	local alpha = nil
	_G["SoundtrackControlFrame_InfoButton"].SetAlpha = function(_, a) alpha = a end
	Replace(Soundtrack, "ShowTip", function() end)
	Soundtrack.Library.CurrentlyPlayingTrack = nil

	SoundtrackUI.ControlFrame.OnInfoButtonEnter(SoundtrackControlFrame_InfoButton)

	AreEqual(1.0, alpha, "Alpha set to 1.0 on enter")
end
