function SetControlsButtonsPosition()
	if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
		return
	end

	local nextButton = _G["SoundtrackControlFrame_NextButton"]
	local playButton = _G["SoundtrackControlFrame_PlayButton"]
	local stopButton = _G["SoundtrackControlFrame_StopButton"]
	local previousButton = _G["SoundtrackControlFrame_PreviousButton"]
	local trueStopButton = _G["SoundtrackControlFrame_TrueStopButton"]
	local reportButton = _G["SoundtrackControlFrame_ReportButton"]
	local infoButton = _G["SoundtrackControlFrame_InfoButton"]
	if
		nextButton
		and playButton
		and stopButton
		and previousButton
		and trueStopButton
		and reportButton
		and infoButton
	then
		local position = SoundtrackAddon.db.profile.settings.PlaybackButtonsPosition
		SoundtrackControlFrame_NextButton:ClearAllPoints()
		SoundtrackControlFrame_PlayButton:ClearAllPoints()
		SoundtrackControlFrame_StopButton:ClearAllPoints()
		SoundtrackControlFrame_PreviousButton:ClearAllPoints()
		SoundtrackControlFrame_TrueStopButton:ClearAllPoints()
		SoundtrackControlFrame_ReportButton:ClearAllPoints()
		SoundtrackControlFrame_InfoButton:ClearAllPoints()
		if position == "LEFT" then
			SoundtrackControlFrame_NextButton:SetPoint(
				"BOTTOMRIGHT",
				"SoundtrackControlFrame_StatusBarEvent",
				"BOTTOMLEFT",
				-12,
				-1
			)
			SoundtrackControlFrame_PlayButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
			SoundtrackControlFrame_StopButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
			SoundtrackControlFrame_PreviousButton:SetPoint("RIGHT", "SoundtrackControlFrame_PlayButton", "LEFT")
			SoundtrackControlFrame_TrueStopButton:SetPoint("TOP", "SoundtrackControlFrame_PlayButton", "BOTTOM")
			SoundtrackControlFrame_ReportButton:SetPoint("LEFT", "SoundtrackControlFrame_TrueStopButton", "RIGHT")
			SoundtrackControlFrame_InfoButton:SetPoint("RIGHT", "SoundtrackControlFrame_TrueStopButton", "LEFT")
		elseif position == "TOPLEFT" then
			SoundtrackControlFrame_PreviousButton:SetPoint(
				"BOTTOMLEFT",
				"SoundtrackControlFrame_StatusBarEvent",
				"TOPLEFT",
				-3,
				7
			)
			SoundtrackControlFrame_PlayButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
			SoundtrackControlFrame_StopButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
			SoundtrackControlFrame_NextButton:SetPoint("LEFT", "SoundtrackControlFrame_PlayButton", "RIGHT")
			SoundtrackControlFrame_InfoButton:SetPoint("LEFT", "SoundtrackControlFrame_NextButton", "RIGHT")
			SoundtrackControlFrame_TrueStopButton:SetPoint("LEFT", "SoundtrackControlFrame_InfoButton", "RIGHT")
			SoundtrackControlFrame_ReportButton:SetPoint("LEFT", "SoundtrackControlFrame_TrueStopButton", "RIGHT")
		elseif position == "TOPRIGHT" then
			SoundtrackControlFrame_ReportButton:SetPoint(
				"BOTTOMRIGHT",
				"SoundtrackControlFrame_StatusBarEvent",
				"TOPRIGHT",
				3,
				7
			)
			SoundtrackControlFrame_TrueStopButton:SetPoint("RIGHT", "SoundtrackControlFrame_ReportButton", "LEFT")
			SoundtrackControlFrame_InfoButton:SetPoint("RIGHT", "SoundtrackControlFrame_TrueStopButton", "LEFT")
			SoundtrackControlFrame_NextButton:SetPoint("RIGHT", "SoundtrackControlFrame_InfoButton", "LEFT")
			SoundtrackControlFrame_PlayButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
			SoundtrackControlFrame_StopButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
			SoundtrackControlFrame_PreviousButton:SetPoint("RIGHT", "SoundtrackControlFrame_PlayButton", "LEFT")
		elseif position == "RIGHT" then
			SoundtrackControlFrame_PreviousButton:SetPoint(
				"BOTTOMLEFT",
				"SoundtrackControlFrame_StatusBarEvent",
				"BOTTOMRIGHT",
				12,
				-1
			)
			SoundtrackControlFrame_PlayButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
			SoundtrackControlFrame_StopButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
			SoundtrackControlFrame_NextButton:SetPoint("LEFT", "SoundtrackControlFrame_StopButton", "RIGHT")
			SoundtrackControlFrame_TrueStopButton:SetPoint("TOP", "SoundtrackControlFrame_PlayButton", "BOTTOM")
			SoundtrackControlFrame_ReportButton:SetPoint("LEFT", "SoundtrackControlFrame_TrueStopButton", "RIGHT")
			SoundtrackControlFrame_InfoButton:SetPoint("RIGHT", "SoundtrackControlFrame_TrueStopButton", "LEFT")
		elseif position == "BOTTOMRIGHT" then
			SoundtrackControlFrame_NextButton:SetPoint(
				"TOPRIGHT",
				"SoundtrackControlFrame_StatusBarTrack",
				"BOTTOMRIGHT",
				3,
				-7
			)
			SoundtrackControlFrame_PlayButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
			SoundtrackControlFrame_StopButton:SetPoint("RIGHT", "SoundtrackControlFrame_NextButton", "LEFT")
			SoundtrackControlFrame_PreviousButton:SetPoint("RIGHT", "SoundtrackControlFrame_PlayButton", "LEFT")
			SoundtrackControlFrame_TrueStopButton:SetPoint("RIGHT", "SoundtrackControlFrame_PreviousButton", "LEFT")
			SoundtrackControlFrame_ReportButton:SetPoint("RIGHT", "SoundtrackControlFrame_TrueStopButton", "LEFT")
			SoundtrackControlFrame_InfoButton:SetPoint("RIGHT", "SoundtrackControlFrame_ReportButton", "LEFT")
		elseif position == "BOTTOMLEFT" then
			SoundtrackControlFrame_PreviousButton:SetPoint(
				"TOPLEFT",
				"SoundtrackControlFrame_StatusBarTrack",
				"BOTTOMLEFT",
				-3,
				-7
			)
			SoundtrackControlFrame_PlayButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
			SoundtrackControlFrame_StopButton:SetPoint("LEFT", "SoundtrackControlFrame_PreviousButton", "RIGHT")
			SoundtrackControlFrame_NextButton:SetPoint("LEFT", "SoundtrackControlFrame_PlayButton", "RIGHT")
			SoundtrackControlFrame_InfoButton:SetPoint("LEFT", "SoundtrackControlFrame_NextButton", "RIGHT")
			SoundtrackControlFrame_TrueStopButton:SetPoint("LEFT", "SoundtrackControlFrame_InfoButton", "RIGHT")
			SoundtrackControlFrame_ReportButton:SetPoint("LEFT", "SoundtrackControlFrame_TrueStopButton", "RIGHT")
		end
	end
end

function SoundtrackFrame_RefreshPlaybackControls()
	if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
		return
	end

	SetControlsButtonsPosition()
	SoundtrackFrame_HideControlButtons()

	if SoundtrackAddon.db.profile.settings.HideControlButtons == false then
		local stopButton = _G["SoundtrackControlFrame_StopButton"]
		local playButton = _G["SoundtrackControlFrame_PlayButton"]

		if stopButton and playButton then
			if Soundtrack.Events.Paused then
				stopButton:Hide()
				playButton:Show()
			else
				stopButton:Show()
				playButton:Hide()
			end
		end
	end

	local stopButton2 = _G["SoundtrackFrame_StopButton"]
	local playButton2 = _G["SoundtrackFrame_PlayButton"]

	if stopButton2 and playButton2 then
		if Soundtrack.Events.Paused then
			stopButton2:Hide()
			playButton2:Show()
		else
			stopButton2:Show()
			playButton2:Hide()
		end
	end

	SoundtrackFrame.RefreshEventStack()
end

function SoundtrackFrame_HideControlButtons()
	local nextButton = _G["SoundtrackControlFrame_NextButton"]
	local playButton = _G["SoundtrackControlFrame_PlayButton"]
	local stopButton = _G["SoundtrackControlFrame_StopButton"]
	local previousButton = _G["SoundtrackControlFrame_PreviousButton"]
	local trueStopButton = _G["SoundtrackControlFrame_TrueStopButton"]
	local reportButton = _G["SoundtrackControlFrame_ReportButton"]
	local infoButton = _G["SoundtrackControlFrame_InfoButton"]
	if
		nextButton
		and playButton
		and stopButton
		and previousButton
		and trueStopButton
		and reportButton
		and infoButton
	then
		if SoundtrackAddon.db.profile.settings.HideControlButtons then
			SoundtrackControlFrame_NextButton:Hide()
			SoundtrackControlFrame_PlayButton:Hide()
			SoundtrackControlFrame_StopButton:Hide()
			SoundtrackControlFrame_PreviousButton:Hide()
			SoundtrackControlFrame_TrueStopButton:Hide()
			SoundtrackControlFrame_ReportButton:Hide()
			SoundtrackControlFrame_InfoButton:Hide()
		else
			SoundtrackControlFrame_NextButton:Show()
			SoundtrackControlFrame_PlayButton:Show()
			SoundtrackControlFrame_StopButton:Show()
			SoundtrackControlFrame_PreviousButton:Show()
			SoundtrackControlFrame_TrueStopButton:Show()
			SoundtrackControlFrame_ReportButton:Show()
			SoundtrackControlFrame_InfoButton:Show()
		end
		SoundtrackControlFrame_NextButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
		SoundtrackControlFrame_PlayButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
		SoundtrackControlFrame_StopButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
		SoundtrackControlFrame_PreviousButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
		SoundtrackControlFrame_TrueStopButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
		SoundtrackControlFrame_ReportButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
		SoundtrackControlFrame_InfoButton:EnableMouse(not SoundtrackAddon.db.profile.settings.HideControlButtons)
	end
end
