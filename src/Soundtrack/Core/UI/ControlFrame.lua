SoundtrackFrame.ControlFrame = {}

--#region Next button handlers
function SoundtrackFrame.ControlFrame.OnNextButtonClick()
	Soundtrack.Events.PlaybackNext()
end

function SoundtrackFrame.ControlFrame.OnNextButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_NEXT, SOUNDTRACK_NEXT_TIP)
	SoundtrackControlFrame_NextButton:SetAlpha(1.0)
end

function SoundtrackFrame.ControlFrame.OnNextButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_NextButton:SetAlpha(0.6)
end
--#endregion

--#region Stop button handlers
function SoundtrackFrame.ControlFrame.OnStopButtonClick()
	Soundtrack.Events.PlaybackPlayStop()
end

function SoundtrackFrame.ControlFrame.OnStopButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_PAUSE, SOUNDTRACK_PAUSE_TIP)
	SoundtrackControlFrame_StopButton:SetAlpha(1.0)
end

function SoundtrackFrame.ControlFrame.OnStopButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_StopButton:SetAlpha(0.6)
end
--#endregion

--#region Play button handlers
function SoundtrackFrame.ControlFrame.OnPlayButtonClick()
	Soundtrack.Events.PlaybackPlayStop()
end

function SoundtrackFrame.ControlFrame.OnPlayButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_PLAY, SOUNDTRACK_PLAY_TIP)
	SoundtrackControlFrame_PlayButton:SetAlpha(1.0)
end

function SoundtrackFrame.ControlFrame.OnPlayButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_PlayButton:SetAlpha(0.6)
end
--#endregion

--#region Previous button handlers
function SoundtrackFrame.ControlFrame.OnPreviousButtonClick()
	Soundtrack.Events.PlaybackPrevious()
end

function SoundtrackFrame.ControlFrame.OnPreviousButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_PREVIOUS, SOUNDTRACK_PREVIOUS_TIP)
	SoundtrackControlFrame_PreviousButton:SetAlpha(1.0)
end

function SoundtrackFrame.ControlFrame.OnPreviousButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_PreviousButton:SetAlpha(0.6)
end
--#endregion

--#region True stop button handlers
function SoundtrackFrame.ControlFrame.OnTrueStopButtonClick()
	Soundtrack.Events.PlaybackTrueStop()
end

function SoundtrackFrame.ControlFrame.OnTrueStopButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_STOP, SOUNDTRACK_STOP_TIP)
	SoundtrackControlFrame_TrueStopButton:SetAlpha(1.0)
end

function SoundtrackFrame.ControlFrame.OnTrueStopButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_TrueStopButton:SetAlpha(0.6)
end
--#endregion

--#region Report button handlers
function SoundtrackFrame.ControlFrame.OnReportButtonClick()
	SoundtrackReportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	SoundtrackReportFrame:Show()
end

function SoundtrackFrame.ControlFrame.OnReportButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_REPORT, SOUNDTRACK_REPORT_TIP)
	SoundtrackControlFrame_ReportButton:SetAlpha(1.0)
end

function SoundtrackFrame.ControlFrame.OnReportButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_ReportButton:SetAlpha(0.6)
end
--#endregion

--#region Info button handlers
function SoundtrackFrame.ControlFrame.OnInfoButtonClick()
	local currentTrackName = Soundtrack.Library.CurrentlyPlayingTrack
	if currentTrackName ~= nil and currentTrackName ~= "None" then
		local track = Soundtrack_Tracks[currentTrackName]
		SoundtrackFrame.NowPlayingFrame.SetNowPlayingText(track.title, track.artist, track.album)
	end
end

function SoundtrackFrame.ControlFrame.OnInfoButtonEnter(self)
	SoundtrackControlFrame_InfoButton:SetAlpha(1.0)
	local currentTrackName = Soundtrack.Library.CurrentlyPlayingTrack
	if currentTrackName ~= nil and currentTrackName ~= "None" then
		local track = Soundtrack_Tracks[currentTrackName]
		Soundtrack.ShowTip(self, track.title, nil, track.artist, track.album)
	else
		Soundtrack.ShowTip(self, SOUNDTRACK_INFO, SOUNDTRACK_INFO_TIP)
	end
end

function SoundtrackFrame.ControlFrame.OnInfoButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_InfoButton:SetAlpha(0.6)
end
--#endregion
