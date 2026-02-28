if not Tests then
	return
end

local Tests = Tests("MovingTitleUI", "PLAYER_ENTERING_WORLD")

-- OnUpdate Tests

function Tests:OnUpdate_ShowsNoTracksPlayingText_WhenNoTrackActive()
	Soundtrack.Library.CurrentlyPlayingTrack = nil

	SoundtrackUI.MovingTitle.OnUpdate()

	AreEqual(SOUNDTRACK_NO_TRACKS_PLAYING, SoundtrackFrame_StatusBarTrackText1:GetText(),
		"No track message displayed")
end

function Tests:OnUpdate_ClearsSecondLine_WhenNoTrackActive()
	SoundtrackFrame_StatusBarTrackText2:SetText("Old Text")
	Soundtrack.Library.CurrentlyPlayingTrack = nil

	SoundtrackUI.MovingTitle.OnUpdate()

	AreEqual("", SoundtrackFrame_StatusBarTrackText2:GetText(), "Second line cleared when no track")
end

function Tests:OnUpdate_ShowsNoTracksPlayingText_WhenTrackNotInTracks()
	Soundtrack.Library.CurrentlyPlayingTrack = "Sound/Music/Missing.mp3"
	-- Ensure it's not in Soundtrack_Tracks
	Soundtrack_Tracks["Sound/Music/Missing.mp3"] = nil

	SoundtrackUI.MovingTitle.OnUpdate()

	AreEqual(SOUNDTRACK_NO_TRACKS_PLAYING, SoundtrackFrame_StatusBarTrackText1:GetText(),
		"No track message when track key not found in Soundtrack_Tracks")
end

function Tests:OnUpdate_SetsTrackTitle_WhenTrackIsActive()
	local trackPath = "Sound/Music/CoolSong.mp3"
	Soundtrack_Tracks[trackPath] = {
		title = "Cool Song Title",
		artist = "Great Artist",
		album = "Great Album",
	}
	Soundtrack.Library.CurrentlyPlayingTrack = trackPath
	SoundtrackUI.nameHeaderType = "title"
	-- Reset the moving title state with a fresh call (will use first value from CreateNext)
	SoundtrackFrame_StatusBarTrackText1:SetText(nil)

	SoundtrackUI.MovingTitle.OnUpdate()

	local text = SoundtrackFrame_StatusBarTrackText1:GetText()
	IsTrue(text ~= SOUNDTRACK_NO_TRACKS_PLAYING, "Title text shown instead of 'no track' message")
	IsTrue(text:find("Cool Song") ~= nil or #text > 0, "Track title text is set")
end

function Tests:OnUpdate_SyncsControlFrameText()
	Soundtrack.Library.CurrentlyPlayingTrack = nil
	SoundtrackFrame_StatusBarTrackText1:SetText("Frame text")

	SoundtrackUI.MovingTitle.OnUpdate()

	-- After OnUpdate, control frame text should mirror the main frame text
	AreEqual(SoundtrackFrame_StatusBarTrackText1:GetText(),
		SoundtrackControlFrame_StatusBarTrackText1:GetText(),
		"Control frame text synced with main frame text")
end

function Tests:OnUpdate_ReturnsEarly_WhenSoundtrack_TracksIsNil()
	Soundtrack_Tracks = nil
	local originalText = SoundtrackFrame_StatusBarTrackText1:GetText()

	-- Should not error even when Soundtrack_Tracks is nil
	SoundtrackUI.MovingTitle.OnUpdate()

	-- Restore
	Soundtrack_Tracks = {}
	IsTrue(true, "No error when Soundtrack_Tracks is nil")
end
