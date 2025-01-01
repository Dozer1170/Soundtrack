SoundtrackUI.ControlFrame = {}

--#region Next button handlers
function SoundtrackUI.ControlFrame.OnNextButtonClick()
	Soundtrack.Events.PlaybackNext()
end

function SoundtrackUI.ControlFrame.OnNextButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_NEXT, SOUNDTRACK_NEXT_TIP)
	SoundtrackControlFrame_NextButton:SetAlpha(1.0)
end

function SoundtrackUI.ControlFrame.OnNextButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_NextButton:SetAlpha(0.6)
end
--#endregion

--#region Stop button handlers
function SoundtrackUI.ControlFrame.OnStopButtonClick()
	Soundtrack.Events.PlaybackPlayStop()
end

function SoundtrackUI.ControlFrame.OnStopButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_PAUSE, SOUNDTRACK_PAUSE_TIP)
	SoundtrackControlFrame_StopButton:SetAlpha(1.0)
end

function SoundtrackUI.ControlFrame.OnStopButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_StopButton:SetAlpha(0.6)
end
--#endregion

--#region Play button handlers
function SoundtrackUI.ControlFrame.OnPlayButtonClick()
	Soundtrack.Events.PlaybackPlayStop()
end

function SoundtrackUI.ControlFrame.OnPlayButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_PLAY, SOUNDTRACK_PLAY_TIP)
	SoundtrackControlFrame_PlayButton:SetAlpha(1.0)
end

function SoundtrackUI.ControlFrame.OnPlayButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_PlayButton:SetAlpha(0.6)
end
--#endregion

--#region Previous button handlers
function SoundtrackUI.ControlFrame.OnPreviousButtonClick()
	Soundtrack.Events.PlaybackPrevious()
end

function SoundtrackUI.ControlFrame.OnPreviousButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_PREVIOUS, SOUNDTRACK_PREVIOUS_TIP)
	SoundtrackControlFrame_PreviousButton:SetAlpha(1.0)
end

function SoundtrackUI.ControlFrame.OnPreviousButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_PreviousButton:SetAlpha(0.6)
end
--#endregion

--#region True stop button handlers
function SoundtrackUI.ControlFrame.OnTrueStopButtonClick()
	Soundtrack.Events.PlaybackTrueStop()
end

function SoundtrackUI.ControlFrame.OnTrueStopButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_STOP, SOUNDTRACK_STOP_TIP)
	SoundtrackControlFrame_TrueStopButton:SetAlpha(1.0)
end

function SoundtrackUI.ControlFrame.OnTrueStopButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_TrueStopButton:SetAlpha(0.6)
end
--#endregion

--#region Report button handlers
function SoundtrackUI.ControlFrame.OnReportButtonClick()
	SoundtrackReportFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
	SoundtrackReportFrame:Show()
end

function SoundtrackUI.ControlFrame.OnReportButtonEnter(self)
	Soundtrack.ShowTip(self, SOUNDTRACK_REPORT, SOUNDTRACK_REPORT_TIP)
	SoundtrackControlFrame_ReportButton:SetAlpha(1.0)
end

function SoundtrackUI.ControlFrame.OnReportButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_ReportButton:SetAlpha(0.6)
end
--#endregion

--#region Info button handlers
function SoundtrackUI.ControlFrame.OnInfoButtonClick()
	local currentTrackName = Soundtrack.Library.CurrentlyPlayingTrack
	if currentTrackName ~= nil and currentTrackName ~= "None" then
		local track = Soundtrack_Tracks[currentTrackName]
		SoundtrackUI.NowPlayingFrame.SetNowPlayingText(track.title, track.artist, track.album)
	end
end

function SoundtrackUI.ControlFrame.OnInfoButtonEnter(self)
	SoundtrackControlFrame_InfoButton:SetAlpha(1.0)
	local currentTrackName = Soundtrack.Library.CurrentlyPlayingTrack
	if currentTrackName ~= nil and currentTrackName ~= "None" then
		local track = Soundtrack_Tracks[currentTrackName]
		Soundtrack.ShowTip(self, track.title, nil, track.artist, track.album)
	else
		Soundtrack.ShowTip(self, SOUNDTRACK_INFO, SOUNDTRACK_INFO_TIP)
	end
end

function SoundtrackUI.ControlFrame.OnInfoButtonLeave()
	Soundtrack.HideTip()
	SoundtrackControlFrame_InfoButton:SetAlpha(0.6)
end
--#endregion
