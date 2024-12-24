SoundtrackFrame = {}
SoundtrackFrame.SelectedEvent = nil
SoundtrackFrame.SelectedTrack = nil
SoundtrackFrame.SelectedEventsTable = nil

local EVENTS_TO_DISPLAY = 21
local TRACKS_TO_DISPLAY = 16
local ASSIGNED_TRACKS_TO_DISPLAY = 7

local EVENT_TYPES = {
	ST_EVENT_SCRIPT,
	ST_UPDATE_SCRIPT,
	ST_BUFF_SCRIPT,
	ST_DEBUFF_SCRIPT,
}

SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST = {
	{ name = "File Path", type = "filePath" },
	{ name = "File Name", type = "fileName" },
	{ name = "Title", type = "title" },
}

local SUB_FRAME_ASSIGNED_TRACKS = "SoundtrackFrameAssignedTracks"
local SUB_FRAME_EVENT_SETTINGS = "SoundtrackFrame_EventSettings"
local EVENT_SUB_FRAMES = {
	SUB_FRAME_ASSIGNED_TRACKS,
	SUB_FRAME_EVENT_SETTINGS,
}

local currentSubFrame = SUB_FRAME_ASSIGNED_TRACKS
local nextUpdateTime = 0
local suspendRenameEvent = false

local function GetFlatEventsTable()
	return Soundtrack_FlatEvents[SoundtrackFrame.SelectedEventsTable]
end

-- Returns the number of seconds in "mm.ss" format
local function FormatDuration(seconds)
	if not seconds then
		return ""
	else
		return string.format("%i:%02i", math.floor(seconds / 60), seconds % 60)
	end
end

local function RefreshEventSettings()
	if SoundtrackFrame.SelectedEvent then
		suspendRenameEvent = true
		_G["SoundtrackFrame_EventName"]:SetText(SoundtrackFrame.SelectedEvent)
		suspendRenameEvent = false

		local eventTable = Soundtrack.Events.GetTable(SoundtrackFrame.SelectedEventsTable)
		local event = eventTable[SoundtrackFrame.SelectedEvent]
		if event then
			SoundtrackFrame_RandomCheckButton:SetChecked(event.random)
			SoundtrackFrame_ContinuousCheckBox:SetChecked(event.continuous)
			SoundtrackFrame_SoundEffectCheckBox:SetChecked(event.soundEffect)
		end
	end
end

local function SelectActiveTab()
	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()

	if stackLevel > 0 then
		Soundtrack.Chat.TraceFrame("Selecting currently playing tab")
		local tableName = Soundtrack.Events.Stack[stackLevel].tableName
		SoundtrackFrame.SelectedEventsTable = tableName
		PanelTemplates_SetTab(SoundtrackFrame, TabUtils.GetTabIndex(tableName))
		SoundtrackFrame_OnTabChanged()
	end
end

local function SetStatusBarProgress(statusBarID, max, current)
	-- Skill bar objects
	local statusBar = _G[statusBarID]
	local statusBarBackground = _G[statusBarID .. "Background"]
	local statusBarFillBar = _G[statusBarID .. "FillBar"]
	local statusBarLabel = _G[statusBarID .. "Text1"]

	statusBarFillBar:Hide()
	statusBarBackground:Hide()

	-- Set bar color depending on skill cost
	if max then
		statusBar:SetStatusBarColor(0.0, 0.75, 0.0, 0.5)
		statusBarBackground:SetVertexColor(0.0, 0.5, 0.0, 0.5)
		statusBarFillBar:SetVertexColor(0.0, 1.0, 0.0, 0.5)
	else
		statusBar:SetStatusBarColor(0.25, 0.25, 0.25)
		statusBar:SetMinMaxValues(0, 0)
		statusBar:SetValue(1)
		statusBarBackground:SetVertexColor(0.75, 0.75, 0.75, 0.5)
		statusBarFillBar:Hide()
		return
	end

	statusBar:SetMinMaxValues(0, max)
	statusBar:SetValue(current)
	if current <= max and max ~= 0 then
		local fillBarWidth = (current / max) * (statusBar:GetWidth() - 4)
		statusBarFillBar:SetPoint("TOPRIGHT", statusBarLabel, "TOPLEFT", fillBarWidth, 0)
		statusBarFillBar:Show()
	else
		statusBarFillBar:Hide()
	end
end

local function OnColumnHeaderNameDropDownClick(self)
	UIDropDownMenu_SetSelectedID(SoundtrackFrame_ColumnHeaderNameDropDown, self:GetID())
	SoundtrackFrame.nameHeaderType = SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST[self:GetID()].type
	Soundtrack.Chat.TraceFrame("Refreshing tracks with " .. SoundtrackFrame.nameHeaderType)
	if
		self.sortType == "name" and SoundtrackAddon.db.profile.settings.TrackSortingCriteria == "fileName"
		or SoundtrackAddon.db.profile.settings.TrackSortingCriteria == "filePath"
		or SoundtrackAddon.db.profile.settings.TrackSortingCriteria == "title"
	then
		Soundtrack.SortTracks(SoundtrackFrame.nameHeaderType)
	else
		Soundtrack.SortTracks(self.sortType)
	end
end

local function ShowSubFrame(frameName)
	for _, value in ipairs(EVENT_SUB_FRAMES) do
		if value == frameName then
			_G[value]:Show()
		else
			_G[value]:Hide()
		end
	end
end

local function RefreshEventSubFrame()
	ShowSubFrame(SUB_FRAME_ASSIGNED_TRACKS)

	if currentSubFrame == SUB_FRAME_ASSIGNED_TRACKS then
		SoundtrackFrame_RefreshAssignedTracks()
	end
end

function SoundtrackFrame.Initialize()
	Soundtrack.OptionsTab.Initialize()
end

function SoundtrackFrame.ShowAssignedTracksSubFrame()
	currentSubFrame = SUB_FRAME_ASSIGNED_TRACKS
	RefreshEventSubFrame()
end

function SoundtrackFrame.ShowEventSettingsSubFrame()
	currentSubFrame = SUB_FRAME_EVENT_SETTINGS
	RefreshEventSubFrame()
end

function SoundtrackFrame.OnLoad(self)
	tinsert(UISpecialFrames, "SoundtrackFrame")

	PanelTemplates_SetNumTabs(self, 11)
	PanelTemplates_SetTab(self, 1)
end

function SoundtrackFrame.OnUpdate()
	local currentTime = GetTime()
	if currentTime >= nextUpdateTime then
		nextUpdateTime = currentTime + UI_UPDATE_INTERVAL
		SoundtrackFrame.MovingTitle.Update()
		SoundtrackFrame.RefreshTrackProgress()
	end
end

function SoundtrackFrame.RefreshTrackProgress()
	if not Soundtrack.Library.CurrentlyPlayingTrack then
		SetStatusBarProgress("SoundtrackFrame_StatusBarTrack", nil, nil)
		SetStatusBarProgress("SoundtrackControlFrame_StatusBarTrack", nil, nil)
		return
	end

	local track = Soundtrack_Tracks[Soundtrack.Library.CurrentlyPlayingTrack]
	if not track then
		SetStatusBarProgress("SoundtrackFrame_StatusBarTrack", nil, nil)
		SetStatusBarProgress("SoundtrackControlFrame_StatusBarTrack", nil, nil)
		return
	end

	local timer = Soundtrack.Timers.Get("FadeOut")
	local currentTime = 0
	local duration = track.length
	if timer then
		currentTime = GetTime() - timer.Start
	end

	local textRemain = FormatDuration(duration - currentTime)
	SoundtrackFrame_StatusBarTrackText2:SetText(textRemain)
	SoundtrackControlFrame_StatusBarTrackText2:SetText(textRemain)

	SetStatusBarProgress("SoundtrackFrame_StatusBarTrack", duration, currentTime)
	SetStatusBarProgress("SoundtrackControlFrame_StatusBarTrack", duration, currentTime)
end

local function SoundtrackFrame_RefreshCurrentlyPlaying()
	-- Refresh event
	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
	local currentTrack = Soundtrack.Library.CurrentlyPlayingTrack

	if stackLevel == 0 then
		SoundtrackFrame_StatusBarEventText1:SetText(SOUNDTRACK_NO_EVENT_PLAYING)
		SoundtrackFrame_StatusBarEventText2:SetText("")
		SetStatusBarProgress("SoundtrackFrame_StatusBarEvent", nil, nil)
		SetStatusBarProgress("SoundtrackControlFrame_StatusBarEvent", nil, nil)
	else
		local tableName = Soundtrack.Events.Stack[stackLevel].tableName
		local eventName = Soundtrack.Events.Stack[stackLevel].eventName
		SoundtrackFrame_StatusBarEventText1:SetText(GetPathFileName(eventName))
		local event = Soundtrack.GetEvent(tableName, eventName)

		if event and event.tracks then
			local numTracks = getn(event.tracks)

			if Soundtrack.Library.CurrentlyPlayingTrack then
				local curTrackIndex = IndexOf(event.tracks, currentTrack)
				SoundtrackFrame_StatusBarEventText2:SetText(curTrackIndex .. " / " .. numTracks)
				SetStatusBarProgress("SoundtrackFrame_StatusBarEvent", numTracks, curTrackIndex)
				SetStatusBarProgress("SoundtrackControlFrame_StatusBarEvent", numTracks, curTrackIndex)
			else
				SoundtrackFrame_StatusBarEventText2:SetText(numTracks .. " tracks")
			end
		else
			SoundtrackFrame_StatusBarEventText2:SetText("")
		end
	end

	-- Refresh control frame too
	SoundtrackControlFrame_StatusBarTrackText1:SetWidth(215)
	SoundtrackControlFrame_StatusBarEventText1:SetWidth(215)
	SoundtrackControlFrame_StatusBarEventText1:SetText(SoundtrackFrame_StatusBarEventText1:GetText()) -- event name
	SoundtrackControlFrame_StatusBarEventText2:SetText(SoundtrackFrame_StatusBarEventText2:GetText()) -- track number in list
	SoundtrackControlFrame_StatusBarTrackText1:SetText(SoundtrackFrame_StatusBarTrackText1:GetText()) -- track name
	SoundtrackControlFrame_StatusBarTrackText2:SetText(SoundtrackFrame_StatusBarTrackText2:GetText()) -- time
end

function SoundtrackFrame.InitializeColumnHeaderNameDropDown()
	local info = UIDropDownMenu_CreateInfo()
	for i = 1, #SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST, 1 do
		info.text = SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST[i].name
		info.func = OnColumnHeaderNameDropDownClick
		UIDropDownMenu_AddButton(info)
	end
end

-- Functions to call from outside, to refresh the UI partially
function SoundtrackFrame_TouchEvents()
	SoundtrackFrame_RefreshCurrentlyPlaying()

	for i = 1, Soundtrack.Events.MaxStackLevel, 1 do
		local tableName = Soundtrack.Events.Stack[i].tableName
		local eventName = Soundtrack.Events.Stack[i].eventName
		local label = _G["SoundtrackControlFrameStack" .. i]
		if not eventName then
			label:SetText(i .. ") None")
		else
			local playOnceText
			local event = Soundtrack.GetEvent(tableName, eventName)
			if event.continuous then
				playOnceText = "Loop"
			else
				playOnceText = "Once"
			end
			local eventText = GetPathFileName(eventName)
			label:SetText(i .. ") " .. eventText .. " (" .. playOnceText .. ")")
		end
	end

	SoundtrackFrame_RefreshEvents()
end

-- Functions to call from outside, to refresh the UI partially
function SoundtrackFrame_TouchTracks()
	SoundtrackFrame_RefreshTracks()
	SoundtrackFrame_RefreshCurrentlyPlaying()
end

function SoundtrackFrame_RefreshProfilesFrame() end

function SoundtrackFrame_SetControlsButtonsPosition()
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

function SoundtrackFrame_RefreshPlaybackControls()
	if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
		return
	end

	SoundtrackFrame_SetControlsButtonsPosition()
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

	local controlFrame = _G["SoundtrackControlFrame"]

	if controlFrame then
		if SoundtrackAddon.db.profile.settings.ShowPlaybackControls then
			controlFrame:Show()

			if SoundtrackAddon.db.profile.settings.ShowEventStack then
				SoundtrackControlFrameStackTitle:Show()
				SoundtrackControlFrameStack1:Show()
				SoundtrackControlFrameStack2:Show()
				SoundtrackControlFrameStack3:Show()
				SoundtrackControlFrameStack4:Show()
				SoundtrackControlFrameStack5:Show()
				SoundtrackControlFrameStack6:Show()
				SoundtrackControlFrameStack7:Show()
				SoundtrackControlFrameStack8:Show()
				SoundtrackControlFrameStack9:Show()
				SoundtrackControlFrameStack10:Show()
				SoundtrackControlFrameStack11:Show()
				SoundtrackControlFrameStack12:Show()
				SoundtrackControlFrameStack13:Show()
				SoundtrackControlFrameStack14:Show()
				SoundtrackControlFrameStack15:Show()
				SoundtrackControlFrameStack16:Show()
			else
				SoundtrackControlFrameStackTitle:Hide()
				SoundtrackControlFrameStack1:Hide()
				SoundtrackControlFrameStack2:Hide()
				SoundtrackControlFrameStack3:Hide()
				SoundtrackControlFrameStack4:Hide()
				SoundtrackControlFrameStack5:Hide()
				SoundtrackControlFrameStack6:Hide()
				SoundtrackControlFrameStack7:Hide()
				SoundtrackControlFrameStack8:Hide()
				SoundtrackControlFrameStack9:Hide()
				SoundtrackControlFrameStack10:Hide()
				SoundtrackControlFrameStack11:Hide()
				SoundtrackControlFrameStack12:Hide()
				SoundtrackControlFrameStack13:Hide()
				SoundtrackControlFrameStack14:Hide()
				SoundtrackControlFrameStack15:Hide()
				SoundtrackControlFrameStack16:Hide()
			end
		else
			controlFrame:Hide()
		end
	end
end

function SoundtrackFrame_ToggleRandomMusic()
	local eventTable = Soundtrack.Events.GetTable(SoundtrackFrame.SelectedEventsTable)
	if eventTable[SoundtrackFrame.SelectedEvent] then
		eventTable[SoundtrackFrame.SelectedEvent].random = not eventTable[SoundtrackFrame.SelectedEvent].random
	end
end

function SoundtrackFrame_ToggleSoundEffect()
	local eventTable = Soundtrack.Events.GetTable(SoundtrackFrame.SelectedEventsTable)
	if eventTable[SoundtrackFrame.SelectedEvent] then
		eventTable[SoundtrackFrame.SelectedEvent].soundEffect =
			not eventTable[SoundtrackFrame.SelectedEvent].soundEffect
	end
end

function SoundtrackFrame_ToggleContinuousMusic()
	local eventTable = Soundtrack.Events.GetTable(SoundtrackFrame.SelectedEventsTable)
	if eventTable[SoundtrackFrame.SelectedEvent] then
		eventTable[SoundtrackFrame.SelectedEvent].continuous = not eventTable[SoundtrackFrame.SelectedEvent].continuous
	end
end

function SoundtrackFrame_OnShow()
	SoundtrackFrame_RefreshCurrentlyPlaying()
	SelectActiveTab()
	SoundtrackFrame_RefreshShowingTab()
end

function SoundtrackFrame_OnHide()
	Soundtrack.StopEventAtLevel(ST_PREVIEW_LVL)

	if SoundtrackFrame.SelectedEventsTable ~= "Playlists" then
		Soundtrack.StopEventAtLevel(ST_PLAYLIST_LVL)
	end
end

function SoundtrackFrame_RefreshCustomEvent()
	local customEvent = SoundtrackAddon.db.profile.customEvents[SoundtrackFrame.SelectedEvent]

	if customEvent == nil then
		return
	end

	if customEvent then
		_G["SoundtrackFrame_Priority"]:SetText(tostring(customEvent.priority))
		if customEvent.type == ST_EVENT_SCRIPT then
			_G["SoundtrackFrame_FontStringTrigger"]:SetText("Trigger")
			_G["SoundtrackFrame_EventTrigger"]:SetText(customEvent.trigger)
			_G["SoundtrackFrame_EventScript"]:SetText(customEvent.script)
		elseif customEvent.type == ST_BUFF_SCRIPT then
			_G["SoundtrackFrame_FontStringTrigger"]:SetText("Spell ID")
			_G["SoundtrackFrame_EventTrigger"]:SetText(customEvent.spellId)
			_G["SoundtrackFrame_EventScript"]:SetText(
				"Buff events do not need a script.\nThey remain active while the specified buff is active."
			)
		elseif customEvent.type == ST_UPDATE_SCRIPT then
			_G["SoundtrackFrame_FontStringTrigger"]:SetText("Trigger")
			_G["SoundtrackFrame_EventTrigger"]:SetText("OnUpdate")
			_G["SoundtrackFrame_EventScript"]:SetText(customEvent.script)
		end
	end

	if customEvent.type == nil then
		Soundtrack.Chat.TraceFrame("Nil type on " .. SoundtrackFrame.SelectedEvent)
		customEvent.type = ST_UPDATE_SCRIPT
	end

	local eventTypeIndex = IndexOf(EVENT_TYPES, customEvent.type)
	UIDropDownMenu_SetSelectedID(SoundtrackFrame_EventTypeDropDown, eventTypeIndex)
	UIDropDownMenu_SetText(SoundtrackFrame_EventTypeDropDown, customEvent.type)
end

function SoundtrackFrameEventButton_OnClick(self, mouseButton, _)
	Soundtrack.Chat.TraceFrame("EventButton_OnClick")

	Soundtrack.Events.Pause(false)

	local flatEventsTable = GetFlatEventsTable()
	local button = _G["SoundtrackFrameEventButton" .. self:GetID() .. "ButtonTextName"]
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameEventScrollFrame)
	SoundtrackFrame.SelectedEvent = flatEventsTable[self:GetID() + listOffset].tag -- The event name.

	local event = SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][SoundtrackFrame.SelectedEvent]
	if mouseButton == "RightButton" then
		-- Do nothing
	elseif event.expanded then
		event.expanded = false
		Soundtrack.Chat.TraceFrame(SoundtrackFrame.SelectedEvent .. " is now collapsed")
	else
		event.expanded = true
		Soundtrack.Chat.TraceFrame(SoundtrackFrame.SelectedEvent .. " is now expanded")
	end

	SoundtrackFrame.OnEventTreeChanged(SoundtrackFrame.SelectedEventsTable)

	SoundtrackFrame_RefreshEvents()

	if mouseButton == "RightButton" and SoundtrackFrame.SelectedEventsTable == "Zone" then
		-- Toggle menu
		local menu = _G["SoundtrackFrameEventMenu"]
		menu.point = "TOPRIGHT"
		menu.relativePoint = "CENTER"
		ToggleDropDownMenu(1, nil, menu, button, 0, 0)
	elseif SoundtrackFrame.SelectedEventsTable == "Playlists" then
		Soundtrack.PlayEvent(SoundtrackFrame.SelectedEventsTable, SoundtrackFrame.SelectedEvent)
	end

	if SoundtrackFrame.SelectedEventsTable == "Custom" then
		SoundtrackFrame_RefreshCustomEvent()
	end
end

function SoundtrackFrameAddZoneButton_OnClick()
	Soundtrack_ZoneEvents_AddZones()

	-- Select the newly added area.
	if GetSubZoneText() ~= nil then
		SoundtrackFrame.SelectedEvent = GetSubZoneText()
	else
		SoundtrackFrame.SelectedEvent = GetRealZoneText()
	end

	SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameCollapseAllZoneButton_OnClick()
	Soundtrack.Chat.TraceFrame("Collapsing all zone events")
	for _, eventNode in pairs(SoundtrackAddon.db.profile.events["Zone"]) do
		eventNode.expanded = false
	end
	SoundtrackFrame.OnEventTreeChanged("Zone")
	SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameExpandAllZoneButton_OnClick()
	Soundtrack.Chat.TraceFrame("Expanding all zone events")
	for _, eventNode in pairs(SoundtrackAddon.db.profile.events["Zone"]) do
		eventNode.expanded = true
	end
	SoundtrackFrame.OnEventTreeChanged("Zone")
	SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameAddBossTargetButton_OnClick()
	local targetName = UnitName("target")
	if targetName then
		SoundtrackFrame_AddNamedBoss(targetName)
	else
		StaticPopupDialogs["SOUNDTRACK_ADD_BOSS"] = {
			preferredIndex = 3,
			text = SOUNDTRACK_ADD_BOSS_TIP,
			button1 = ACCEPT,
			button2 = CANCEL,
			hasEditBox = 1,
			maxLetters = 100,
			OnAccept = function(self)
				local editBox = _G[self:GetName() .. "EditBox"]
				SoundtrackFrame_AddNamedBoss(editBox:GetText())
			end,
			OnShow = function(self)
				_G[self:GetName() .. "EditBox"]:SetFocus()
			end,
			OnHide = function(self)
				if ChatFrame1EditBox:IsVisible() then
					ChatFrame1EditBox:SetFocus()
				end
				_G[self:GetName() .. "EditBox"]:SetText("")
			end,
			EditBoxOnEnterPressed = function(self)
				local editBox = _G[self:GetName() .. "EditBox"]
				SoundtrackFrame_AddNamedBoss(editBox:GetText())
				self:Hide()
			end,
			EditBoxOnEscapePressed = function(self)
				self:Hide()
			end,
			timeout = 0,
			exclusive = 1,
			whileDead = 1,
			hideOnEscape = 1,
		}

		StaticPopup_Show("SOUNDTRACK_ADD_BOSS")
	end
end

function SoundtrackFrame_AddNamedBoss(targetName)
	Soundtrack.AddEvent("Boss", targetName, ST_BOSS_LVL, true)
	local lowhealthbossname = targetName .. " " .. SOUNDTRACK_LOW_HEALTH
	Soundtrack.AddEvent("Boss", lowhealthbossname, ST_BOSS_LVL, true)
	SoundtrackFrame.SelectedEvent = targetName
	SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameAddWorldBossTargetButton_OnClick()
	local targetName = UnitName("target")
	if targetName then
		SoundtrackFrame_AddNamedWorldBoss(targetName)
	else
		StaticPopupDialogs["SOUNDTRACK_ADD_WORLD_BOSS"] = {
			preferredIndex = 3,
			text = SOUNDTRACK_ADD_BOSS_TIP,
			button1 = ACCEPT,
			button2 = CANCEL,
			hasEditBox = 1,
			maxLetters = 100,
			OnAccept = function(self)
				local editBox = _G[self:GetName() .. "EditBox"]
				SoundtrackFrame_AddNamedWorldBoss(editBox:GetText())
			end,
			OnShow = function(self)
				_G[self:GetName() .. "EditBox"]:SetFocus()
			end,
			OnHide = function(self)
				if ChatFrame1EditBox:IsVisible() then
					ChatFrame1EditBox:SetFocus()
				end
				_G[self:GetName() .. "EditBox"]:SetText("")
			end,
			EditBoxOnEnterPressed = function(self)
				local editBox = _G[self:GetName() .. "EditBox"]
				SoundtrackFrame_AddNamedWorldBoss(editBox:GetText())
				self:Hide()
			end,
			EditBoxOnEscapePressed = function(self)
				self:Hide()
			end,
			timeout = 0,
			exclusive = 1,
			whileDead = 1,
			hideOnEscape = 0,
		}

		StaticPopup_Show("SOUNDTRACK_ADD_WORLD_BOSS")
	end
end

function SoundtrackFrame_AddNamedWorldBoss(targetName)
	Soundtrack.AddEvent("Boss", targetName, ST_BOSS_LVL, true)
	local bossTable = Soundtrack.Events.GetTable(ST_BOSS)
	local bossEvent = bossTable[targetName]
	bossEvent.worldboss = true
	local lowhealthbossname = targetName .. " " .. SOUNDTRACK_LOW_HEALTH
	Soundtrack.AddEvent("Boss", lowhealthbossname, ST_BOSS_LVL, true)
	local bossEvent = bossTable[lowhealthbossname]
	bossEvent.worldboss = true
	SoundtrackFrame.SelectedEvent = targetName
	SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameAddPetBattleTargetButton_OnClick()
	local targetName = UnitName("target")
	local isPlayer
	if UnitIsPlayer("target") then
		isPlayer = true
	else
		isPlayer = false
	end
	if targetName then
		SoundtrackFrame_AddPetBattleTarget(targetName, isPlayer)
	end
end

function SoundtrackFrame_AddPetBattleTarget(targetName, isPlayer)
	if isPlayer then
		Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS .. "/" .. targetName, ST_NPC_LVL, true)
	else
		Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS .. "/" .. targetName, ST_NPC_LVL, true)
	end
	SoundtrackFrame.SelectedEvent = targetName
	SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameRemovePetBattleTargetButton_OnClick()
	StaticPopupDialogs["SOUNDTRACK_REMOVE_PETBATTLETARGET_POPUP"] = {
		preferredIndex = 3,
		text = "Do you want to remove this pet battle event?",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(self)
			SoundtrackFrame_RemovePetBattleTarget(SoundtrackFrame.SelectedEvent)
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopup_Show("SOUNDTRACK_REMOVE_PETBATTLETARGET_POPUP")
end

function SoundtrackFrame_RemovePetBattleTarget(eventName)
	Soundtrack.Events.DeleteEvent(ST_PETBATTLES, eventName)
end

function SoundtrackFrameRemoveZoneButton_OnClick()
	StaticPopupDialogs["SOUNDTRACK_REMOVE_ZONE_POPUP"] = {
		preferredIndex = 3,
		text = "Do you want to remove this zone?",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(self)
			SoundtrackFrame_RemoveZone(SoundtrackFrame.SelectedEvent)
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopup_Show("SOUNDTRACK_REMOVE_ZONE_POPUP")
end
function SoundtrackFrame_RemoveZone(eventName)
	Soundtrack.Events.DeleteEvent("Zone", eventName)
end

function SoundtrackFrameAddPlaylistButton_OnClick(_)
	StaticPopupDialogs["SOUNDTRACK_ADD_PLAYLIST_POPUP"] = {
		preferredIndex = 3,
		text = SOUNDTRACK_ENTER_PLAYLIST_NAME,
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 100,
		OnAccept = function(self)
			local playlistName = _G[self:GetName() .. "EditBox"]
			SoundtrackFrame_AddPlaylist(playlistName:GetText())
		end,
		OnShow = function(self)
			_G[self:GetName() .. "EditBox"]:SetFocus()
			_G[self:GetName() .. "EditBox"]:SetText("")
		end,
		OnHide = function(self) end,
		EditBoxOnEnterPressed = function(self)
			local playlistName = _G[self:GetName()]
			SoundtrackFrame_AddPlaylist(playlistName:GetText())
			self:GetParent():Hide()
		end,
		EditBoxOnEscapePressed = function(self)
			self:GetParent():Hide()
		end,
		timeout = 0,
		exclusive = 1,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopup_Show("SOUNDTRACK_ADD_PLAYLIST_POPUP")
end

function SoundtrackFrame_AddPlaylist(playlistName)
	if playlistName == "" then
		local name = "New Event"
		local index = 1

		local indexedName = name .. " " .. index

		while Soundtrack.GetEvent("Playlists", indexedName) ~= nil do
			index = index + 1
			indexedName = name .. " " .. index
		end

		playlistName = indexedName
	end
	Soundtrack.AddEvent("Playlists", playlistName, ST_PLAYLIST_LVL, true)
	SoundtrackFrame.SelectedEvent = playlistName
	Soundtrack.SortEvents("Playlists")
	SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameDeletePlaylistButton_OnClick()
	Soundtrack.Chat.TraceFrame("Deleting " .. SoundtrackFrame.SelectedEvent)
	Soundtrack.Events.DeleteEvent(ST_PLAYLISTS, SoundtrackFrame.SelectedEvent)
	SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameEventMenu_Initialize() end

function SoundtrackFrame_StatusBar_OnClick(_, _, _)
	Soundtrack.Chat.TraceFrame("StatusBar_OnClick")
	local menu = _G["SoundtrackControlFrame_PlaylistMenu"]
	local button = _G["SoundtrackControlFrame_StatusBarTrack"]
	menu.point = "TOPLEFT"
	menu.relativePoint = "BOTTOMLEFT"
	ToggleDropDownMenu(1, nil, menu, button, 0, 0)
end

function SoundtrackControlFrame_PlaylistMenu_OnClick(self)
	Soundtrack.Chat.TraceFrame("PlaylistMenu_OnClick")

	local table = Soundtrack.Events.GetTable(ST_PLAYLISTS)
	Soundtrack.Chat.TraceFrame(self:GetID())

	local i = 1
	local eventName = nil
	for k, _ in pairs(table) do
		if i == self:GetID() then
			eventName = k
		end
		i = i + 1
	end

	if eventName then
		Soundtrack.PlayEvent(ST_PLAYLISTS, eventName)
	end
end

function SoundtrackControlFrame_PlaylistMenu_Initialize()
	local playlistTable = Soundtrack.Events.GetTable(ST_PLAYLISTS)

	table.sort(playlistTable, function(a, b)
		return a < b
	end)
	table.sort(playlistTable, function(a, b)
		return a > b
	end)
	table.sort(playlistTable, function(a, b)
		return a > b
	end)
	table.sort(playlistTable, function(a, b)
		return a < b
	end)

	for k, _ in pairs(playlistTable) do
		local info = {}
		info.text = k
		info.value = k
		info.func = SoundtrackControlFrame_PlaylistMenu_OnClick
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, 1)
	end
end

function SoundtrackFrameTrackMenu_Initialize()
	-- Remove track
	local info = {}
	info.text = SOUNDTRACK_REMOVE_TRACK
	info.value = "RemoveTrack"
	info.func = function(_)
		Soundtrack.Library.RemoveTrackWithConfirmation()
	end
	info.notCheckable = 1
	UIDropDownMenu_AddButton(info, 1)
end

function SoundtrackFrameTrackCheckBox_OnClick(self, _, _)
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameTrackScrollFrame)
	SoundtrackFrame.SelectedTrack = Soundtrack_SortedTracks[self:GetID() + listOffset] -- track file name

	if SoundtrackFrame.SelectedEvent then
		if SoundtrackFrame_IsTrackActive(SoundtrackFrame.SelectedTrack) then
			Soundtrack.Events.Remove(
				SoundtrackFrame.SelectedEventsTable,
				SoundtrackFrame.SelectedEvent,
				SoundtrackFrame.SelectedTrack
			)
		else
			-- Add the track to the events list.
			Soundtrack.AssignTrack(SoundtrackFrame.SelectedEvent, SoundtrackFrame.SelectedTrack)
		end
	end

	-- To refresh assigned track counts.
	SoundtrackFrame_RefreshEvents()
	SoundtrackFrame_RefreshTracks()
end

function SoundtrackFrameAssignedTrackCheckBox_OnClick(self, _, _)
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameAssignedTracksScrollFrame)

	local assignedTracks =
		SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][SoundtrackFrame.SelectedEvent].tracks
	SoundtrackFrame.SelectedTrack = assignedTracks[self:GetID() + listOffset] -- track file name

	if SoundtrackFrame_IsTrackActive(SoundtrackFrame.SelectedTrack) then
		Soundtrack.Events.Remove(
			SoundtrackFrame.SelectedEventsTable,
			SoundtrackFrame.SelectedEvent,
			SoundtrackFrame.SelectedTrack
		)
	else
		-- Add the track to the events list.
		Soundtrack.AssignTrack(SoundtrackFrame.SelectedEvent, SoundtrackFrame.SelectedTrack)
	end

	-- To refresh assigned track counts.
	SoundtrackFrame_RefreshEvents()
	SoundtrackFrame_RefreshTracks()
end

-- Plays a track using a temporary "preview" event on stack level 16
function PlayPreviewTrack(trackName)
	-- Make sure the preview event exists
	Soundtrack.Events.DeleteEvent(ST_MISC, "Preview")
	Soundtrack.AddEvent(ST_MISC, "Preview", ST_PREVIEW_LVL, true)
	Soundtrack.AssignTrack("Preview", trackName)
	Soundtrack.PlayEvent(ST_MISC, "Preview", true)
end

function SoundtrackFrameTrackButton_OnClick(self, _, _)
	Soundtrack.Chat.TraceFrame("OnClick")

	Soundtrack.Events.Pause(false)

	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameTrackScrollFrame)
	SoundtrackFrame.SelectedTrack = Soundtrack_SortedTracks[self:GetID() + listOffset] -- track file name

	PlayPreviewTrack(SoundtrackFrame.SelectedTrack)

	SoundtrackFrame_RefreshTracks()
end

function SoundtrackFrameAssignedTrackButton_OnClick(self, _, _)
	Soundtrack.Events.Pause(false)

	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameAssignedTracksScrollFrame)

	local assignedTracks =
		SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][SoundtrackFrame.SelectedEvent].tracks

	SoundtrackFrame.SelectedTrack = assignedTracks[self:GetID() + listOffset] -- track file name

	PlayPreviewTrack(SoundtrackFrame.SelectedTrack)

	SoundtrackFrame_RefreshTracks()
end

function SoundtrackFrameAllButton_OnClick()
	-- Start by clearing all tracks
	Soundtrack.Events.ClearEvent(SoundtrackFrame.SelectedEventsTable, SoundtrackFrame.SelectedEvent)

	-- The highlight all of them
	for i = 1, #Soundtrack_SortedTracks, 1 do
		Soundtrack.AssignTrack(SoundtrackFrame.SelectedEvent, Soundtrack_SortedTracks[i])
	end
	SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrameClearButton_OnClick()
	if not SoundtrackFrame.SelectedEvent then
		Soundtrack.Chat.Error("The Clear button was enabled without a selected event")
		return
	end

	StaticPopupDialogs["SOUNDTRACK_CLEAR_SELECTED_EVENT"] = {
		preferredIndex = 3,
		text = SOUNDTRACK_CLEAR_SELECTED_EVENT_QUESTION,
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			SoundtrackFrame_ClearEvent(SoundtrackFrame.SelectedEvent)
		end,
		enterClicksFirstButton = 1,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopup_Show("SOUNDTRACK_CLEAR_SELECTED_EVENT")
end

function SoundtrackFrame_ClearEvent(eventToClear)
	Soundtrack.Events.ClearEvent(SoundtrackFrame.SelectedEventsTable, eventToClear)

	SoundtrackFrame_RefreshEvents()
end

function SoundtrackFrame_RefreshShowingTab()
	SoundtrackFrame.SelectedEventsTable = nil
	SoundtrackFrameEventFrame:Hide()
	SoundtrackFrameOptionsTab:Hide()
	SoundtrackFrameProfilesFrame:Hide()
	SoundtrackFrameAboutFrame:Hide()
	if SoundtrackFrame.selectedTab == 1 then
		SoundtrackFrame.SelectedEventsTable = "Battle"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 2 then
		SoundtrackFrame.SelectedEventsTable = "Boss"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 3 then
		SoundtrackFrame.SelectedEventsTable = "Zone"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 4 then
		SoundtrackFrame.SelectedEventsTable = "Pet Battles"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 5 then
		SoundtrackFrame.SelectedEventsTable = "Dance"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 6 then
		SoundtrackFrame.SelectedEventsTable = "Misc"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 7 then
		SoundtrackFrame.SelectedEventsTable = "Custom"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 8 then
		SoundtrackFrame.SelectedEventsTable = "Playlists"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 9 then
		SoundtrackFrameOptionsTab:Show()
	elseif SoundtrackFrame.selectedTab == 10 then
		SoundtrackFrameProfilesFrame:Show()
	elseif SoundtrackFrame.selectedTab == 11 then
		SoundtrackFrameAboutFrame:Show()
	end

	SoundtrackFrame_OnTabChanged()
end

function SoundtrackFrame_OnTabChanged()
	if SoundtrackFrame.SelectedEventsTable == nil then
	else
		Soundtrack.StopEvent(ST_MISC, "Preview") -- Stop preview track

		-- Select first event if possible
		SoundtrackFrame.SelectedEvent = nil

		local table = GetFlatEventsTable()

		if table and #(GetFlatEventsTable()) >= 1 then
			SoundtrackFrame.SelectedEvent = table[1].tag
		end

		SoundtrackFrame_RefreshEvents()

		if SoundtrackFrame.SelectedEventsTable == "Zone" then
			SoundtrackFrameAddZoneButton:Show()
			SoundtrackFrameRemoveZoneButton:Show()
			SoundtrackFrameCollapseAllZoneButton:Show()
			SoundtrackFrameExpandAllZoneButton:Show()
		else
			SoundtrackFrameAddZoneButton:Hide()
			SoundtrackFrameRemoveZoneButton:Hide()
			SoundtrackFrameCollapseAllZoneButton:Hide()
			SoundtrackFrameExpandAllZoneButton:Hide()
		end

		if SoundtrackFrame.SelectedEventsTable == "Pet Battles" then
			SoundtrackFrameAddPetBattlesTargetButton:Show()
			SoundtrackFrameDeletePetBattlesTargetButton:Show()
		else
			SoundtrackFrameAddPetBattlesTargetButton:Hide()
			SoundtrackFrameDeletePetBattlesTargetButton:Hide()
		end

		if SoundtrackFrame.SelectedEventsTable == "Boss" then
			SoundtrackFrameAddBossTargetButton:Show()
			SoundtrackFrameAddWorldBossTargetButton:Show()
			SoundtrackFrameDeleteTargetButton:Show()
		else
			SoundtrackFrameAddBossTargetButton:Hide()
			SoundtrackFrameAddWorldBossTargetButton:Hide()
			SoundtrackFrameDeleteTargetButton:Hide()
		end

		if SoundtrackFrame.SelectedEventsTable == "Custom" then
			SoundtrackFrameAddCustomEventButton:Show()
			SoundtrackFrameEditCustomEventButton:Show()
			SoundtrackFrameDeleteCustomEventButton:Show()
		else
			SoundtrackFrameAddCustomEventButton:Hide()
			SoundtrackFrameEditCustomEventButton:Hide()
			SoundtrackFrameDeleteCustomEventButton:Hide()
			_G["SoundtrackFrameRightPanelTracks"]:Show()
			_G["SoundtrackFrameRightPanelEditEvent"]:Hide()
		end

		if SoundtrackFrame.SelectedEventsTable == "Playlists" then
			SoundtrackFrameAddPlaylistButton:Show()
			SoundtrackFrameDeletePlaylistButton:Show()
		else
			SoundtrackFrameAddPlaylistButton:Hide()
			SoundtrackFrameDeletePlaylistButton:Hide()
		end

		if SoundtrackFrame.SelectedEventsTable ~= "Options" then
			RefreshEventSubFrame()
		end

		if SoundtrackFrame.SelectedEventsTable ~= "Playlists" then
			Soundtrack.StopEventAtLevel(ST_PLAYLIST_LVL) -- Stop playlists when we go out of the playlist panel
		end
	end
end

function SoundtrackFrame_OnFilterChanged()
	Soundtrack.trackFilter = SoundtrackFrame_TrackFilter:GetText()
	Soundtrack.SortTracks()
end

function SoundtrackFrame_OnEventFilterChanged()
	Soundtrack.eventFilter = SoundtrackFrame_EventFilter:GetText()
	Soundtrack.SortAllEvents()
end

function SoundtrackFrame_DisableAllEventButtons()
	for i = 1, EVENTS_TO_DISPLAY, 1 do
		local button = _G["SoundtrackFrameEventButton" .. i]
		button:Hide()
	end
end

function SoundtrackFrame_DisableAllTrackButtons()
	for i = 1, TRACKS_TO_DISPLAY, 1 do
		local button = _G["SoundtrackFrameTrackButton" .. i]
		button:Hide()
	end
end

function SoundtrackFrame_DisableAllAssignedTrackButtons()
	for i = 1, ASSIGNED_TRACKS_TO_DISPLAY, 1 do
		local button = _G["SoundtrackAssignedTrackButton" .. i]
		button:Hide()
	end
end

-- Replaces each folder in an event path with spaces
local function GetLeafText(eventPath)
	if eventPath then
		return string.gsub(eventPath, "[^/]*/", "    ")
	else
		return eventPath
	end
end

-- Counts the number of / in a path to calculate the depth
local function GetEventDepth(eventPath)
	local count = 0
	local i = 0
	while true do
		i = string.find(eventPath, "/", i + 1)
		-- find 'next' newline
		if i == nil then
			return count
		end
		count = count + 1
	end
end

function SoundtrackFrame_RefreshEvents()
	if not SoundtrackFrame:IsVisible() or not SoundtrackFrame.SelectedEventsTable then
		Soundtrack.Chat.TraceFrame("Skipping event refresh")
		return
	end

	Soundtrack.Chat.TraceFrame("SoundtrackFrame.SelectedEventsTable: " .. SoundtrackFrame.SelectedEventsTable)
	local flatEventsTable = GetFlatEventsTable()

	-- The selected event was deleted, activate another one if possible
	if SoundtrackFrame.SelectedEventsTable and SoundtrackFrame.SelectedEvent then
		if
			not SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][SoundtrackFrame.SelectedEvent]
		then
			if table.maxn(flatEventsTable) > 0 then
				SoundtrackFrame.SelectedEvent = flatEventsTable[1].tag
			else
				SoundtrackFrame.SelectedEvent = ""
			end
		end
	end

	SoundtrackFrame_DisableAllEventButtons()

	local numEvents = #flatEventsTable
	local button
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameEventScrollFrame)
	local buttonIndex
	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
	local currentEvent
	if stackLevel ~= 0 then
		currentEvent = Soundtrack.Events.Stack[stackLevel].eventName
	end

	for i, eventNode in ipairs(flatEventsTable) do
		local eventName = eventNode.tag or error("nil event!")

		if i > listOffset and i < listOffset + EVENTS_TO_DISPLAY then
			buttonIndex = i - listOffset
			if buttonIndex <= EVENTS_TO_DISPLAY then
				button = _G["SoundtrackFrameEventButton" .. buttonIndex]
				local fo = button:CreateFontString()
				fo:SetJustifyH("LEFT")
				fo:SetFont("Fonts/FRIZQT__.TTF", 10)
				fo:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
				fo:SetText(GetLeafText(eventName))
				fo:SetWidth(180)
				fo:SetHeight(16)
				button:SetFontString(fo)

				button:SetNormalFontObject("GameFontHighlightSmall")
				button:SetHighlightFontObject("GameFontNormalSmall")

				button:SetID(buttonIndex)
				button:Show()

				local event = SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][eventName]

				-- Add expandable (+ or -) texture
				local collapserTexture = _G["SoundtrackFrameEventButton" .. buttonIndex .. "CollapserTexture"]
				local expanderTexture = _G["SoundtrackFrameEventButton" .. buttonIndex .. "ExpanderTexture"]
				collapserTexture:Hide()
				expanderTexture:Hide()

				local eventDepth = GetEventDepth(eventName)
				local expandTextureIndent = 16 * eventDepth
				collapserTexture:SetPoint("TOPLEFT", expandTextureIndent, 0)
				expanderTexture:SetPoint("TOPLEFT", expandTextureIndent, 0)

				local expandable = eventNode.nodes and #eventNode.nodes >= 1
				if expandable then
					if event.expanded then
						collapserTexture:Show()
						fo:SetText("    " .. GetLeafText(eventName))
					else
						expanderTexture:Show()
						fo:SetText("    " .. GetLeafText(eventName))
					end
					button:UnlockHighlight()
				else
					button:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
					expanderTexture:Hide()
				end

				-- Show number of assigned tracks
				if event then
					local numAssignedTracks = table.maxn(event.tracks)
					if numAssignedTracks == 0 then
						local tempText = button:GetText()
						fo:SetText(tempText .. "   ")
					else
						local tempText = button:GetText()
						fo:SetText(tempText .. " (" .. numAssignedTracks .. ")")
					end
				end

				local icon = _G["SoundtrackFrameEventButton" .. buttonIndex .. "Icon"]
				icon:Hide()

				-- Update the highlight if that track is active for the event.
				if eventName == SoundtrackFrame.SelectedEvent then
					button:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
					button:LockHighlight()
				else
					button:UnlockHighlight()
				end

				-- Update the icon
				if currentEvent == eventName then
					icon:Show()
				end
			end
		end
		--i = i + 1
	end

	-- ScrollFrame stuff
	FauxScrollFrame_Update(SoundtrackFrameEventScrollFrame, numEvents + 1, EVENTS_TO_DISPLAY, EVENTS_ITEM_HEIGHT)

	SoundtrackFrame_RefreshTracks()
	--SoundtrackFrame_RefreshCurrentlyPlaying()
	RefreshEventSettings()
end

function SoundtrackFrame_RenameEvent()
	if SoundtrackFrame.SelectedEvent and not suspendRenameEvent then
		Soundtrack.Events.RenameEvent(
			SoundtrackFrame.SelectedEventsTable,
			SoundtrackFrame.SelectedEvent,
			_G["SoundtrackFrame_EventName"]:GetText()
		)
		SoundtrackFrame_RefreshEvents()
	end
end

-- Checks if a particular track is already set for an event
function SoundtrackFrame_IsTrackActive(trackName)
	local event = SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][SoundtrackFrame.SelectedEvent]
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

function SoundtrackFrame_Toggle()
	if SoundtrackFrame:IsVisible() then
		SoundtrackFrame:Hide()
	else
		SoundtrackFrame:Show()
	end
end

function SoundtrackFrame_EventTypeDropDown_OnLoad(self)
	UIDropDownMenu_Initialize(self, SoundtrackFrame_EventTypeDropDown_Initialize)
	UIDropDownMenu_SetWidth(self, 130)
end

function SoundtrackFrame_EventTypeDropDown_AddInfo(id, caption)
	local info = UIDropDownMenu_CreateInfo()
	info.value = id
	info.text = caption
	info.func = SoundtrackFrame_EventTypeDropDown_OnClick
	local checked = nil
	local selectedId = UIDropDownMenu_GetSelectedID(SoundtrackFrame_EventTypeDropDown)
	if selectedId ~= nil and selectedId == id then
		checked = 1
	end
	info.checked = checked
	UIDropDownMenu_AddButton(info)
end

function SoundtrackFrame_EventTypeDropDown_Initialize()
	for i = 1, #EVENT_TYPES do
		SoundtrackFrame_EventTypeDropDown_AddInfo(i, EVENT_TYPES[i])
	end
end

function SoundtrackFrame_EventTypeDropDown_OnClick(self)
	local oldSelectedId = UIDropDownMenu_GetSelectedID(SoundtrackFrame_EventTypeDropDown)
	local selectedId = self:GetID()

	if selectedId == oldSelectedId then
		return
	end

	local customEvent = SoundtrackAddon.db.profile.customEvents[SoundtrackFrame.SelectedEvent]

	customEvent.type = EVENT_TYPES[selectedId]

	if EVENT_TYPES[selectedId] == ST_UPDATE_SCRIPT then
		if customEvent.script == nil then
			customEvent.swcript = "type your update script here"
		end
	elseif EVENT_TYPES[selectedId] == ST_BUFF_SCRIPT then
		if customEvent.spellId == nil then
			customEvent.spellId = "0"
		end
	elseif EVENT_TYPES[selectedId] == ST_EVENT_SCRIPT then
		if customEvent.trigger == nil then
			customEvent.trigger = "UNIT_AURA"
		end
		if customEvent.script == nil then
			customEvent.script = "type in your event script here"
		end
	end

	SoundtrackFrame_RefreshCustomEvent()
end

-- get shown and you can check things on/off anyways.
function SoundtrackFrame_RefreshTracks()
	if not SoundtrackFrame:IsVisible() or SoundtrackFrame.SelectedEventsTable == nil then
		return
	end

	SoundtrackFrame_DisableAllTrackButtons()
	local numTracks = table.maxn(Soundtrack_SortedTracks)
	local icon
	local button
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameTrackScrollFrame)
	local buttonIndex
	for i = 1, numTracks, 1 do
		if i > listOffset and i < listOffset + TRACKS_TO_DISPLAY then
			buttonIndex = i - listOffset
			if buttonIndex <= TRACKS_TO_DISPLAY then
				local nameText = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextName"]

				if SoundtrackFrame.nameHeaderType == "filePath" or SoundtrackFrame.nameHeaderType == nil then
					nameText:SetText(Soundtrack_SortedTracks[i])
				elseif SoundtrackFrame.nameHeaderType == "fileName" then
					nameText:SetText(GetPathFileName(Soundtrack_SortedTracks[i]))
				elseif SoundtrackFrame.nameHeaderType == "title" then
					nameText:SetText(Soundtrack_Tracks[Soundtrack_SortedTracks[i]].title)
				end

				local albumText = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextAlbum"]
				albumText:SetText(Soundtrack_Tracks[Soundtrack_SortedTracks[i]].album)

				local artistText = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextArtist"]
				artistText:SetText(Soundtrack_Tracks[Soundtrack_SortedTracks[i]].artist)

				button = _G["SoundtrackFrameTrackButton" .. buttonIndex]

				button:SetID(buttonIndex)

				button:Show()

				-- Show duration of track
				local durationLabel = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextDuration"]
				local duration = Soundtrack_Tracks[Soundtrack_SortedTracks[i]].length
				durationLabel:SetText(FormatDuration(duration))

				icon = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "Icon"]
				icon:Hide()

				local checkBox = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "CheckBox"]
				checkBox:SetID(buttonIndex)

				if Soundtrack_SortedTracks[i] == SoundtrackFrame.SelectedTrack then
					button:LockHighlight()
				else
					button:UnlockHighlight()
				end

				if SoundtrackFrame.SelectedEvent ~= nil then
					-- Update the highlight if that track is active for the event.
					if SoundtrackFrame_IsTrackActive(Soundtrack_SortedTracks[i]) then
						checkBox:SetChecked(true)
					else
						checkBox:SetChecked(false)
					end

					-- Update the icon
					if Soundtrack.Library.CurrentlyPlayingTrack == Soundtrack_SortedTracks[i] then
						icon:Show()
					end
				end
			end
		end
	end

	-- ScrollFrame stuff
	FauxScrollFrame_Update(SoundtrackFrameTrackScrollFrame, numTracks + 1, TRACKS_TO_DISPLAY, EVENTS_ITEM_HEIGHT)

	SoundtrackFrame_RefreshAssignedTracks()
end

local function SoundtrackFrame_RefreshUpDownButtons()
	local eventTable = Soundtrack.Events.GetTable(SoundtrackFrame.SelectedEventsTable)
	if eventTable[SoundtrackFrame.SelectedEvent] ~= nil then
		local event = eventTable[SoundtrackFrame.SelectedEvent]
		local currentIndex = IndexOf(event.tracks, SoundtrackFrame.SelectedTrack)

		if currentIndex > 0 and currentIndex > 1 then
			_G["SoundtrackFrameMoveUp"]:Enable()
		else
			_G["SoundtrackFrameMoveUp"]:Disable()
		end

		if currentIndex > 0 and currentIndex < #event.tracks then
			_G["SoundtrackFrameMoveDown"]:Enable()
		else
			_G["SoundtrackFrameMoveDown"]:Disable()
		end
	end
end

function SoundtrackFrame_RefreshAssignedTracks()
	if not SoundtrackFrame:IsVisible() or SoundtrackFrame.SelectedEventsTable == nil then
		return
	end

	SoundtrackFrame_DisableAllAssignedTrackButtons()

	if SoundtrackFrame.SelectedEvent == nil then
		return
	end

	local event = SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][SoundtrackFrame.SelectedEvent]
	if event == nil then
		return
	end

	local icon
	local button
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameAssignedTracksScrollFrame)
	local buttonIndex
	local assignedTracks = event.tracks
	for i = 1, #assignedTracks, 1 do
		if i > listOffset and i < listOffset + ASSIGNED_TRACKS_TO_DISPLAY then
			buttonIndex = i - listOffset
			if buttonIndex <= ASSIGNED_TRACKS_TO_DISPLAY then
				local nameText = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextName"]

				if SoundtrackFrame.nameHeaderType == "filePath" or SoundtrackFrame.nameHeaderType == nil then
					nameText:SetText(assignedTracks[i])
				elseif SoundtrackFrame.nameHeaderType == "fileName" then
					nameText:SetText(GetPathFileName(assignedTracks[i]))
				elseif SoundtrackFrame.nameHeaderType == "title" then
					nameText:SetText(Soundtrack_Tracks[assignedTracks[i]].title)
				end

				local albumText = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextAlbum"]
				albumText:SetText(Soundtrack_Tracks[assignedTracks[i]].album)

				local artistText = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextArtist"]
				artistText:SetText(Soundtrack_Tracks[assignedTracks[i]].artist)

				button = _G["SoundtrackAssignedTrackButton" .. buttonIndex]
				button:SetID(buttonIndex)
				button:Show()

				-- Show duration of track
				local durationLabel = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextDuration"]
				local duration = Soundtrack_Tracks[assignedTracks[i]].length
				durationLabel:SetText(FormatDuration(duration))

				icon = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "Icon"]
				icon:Hide()

				local checkBox = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "CheckBox"]
				checkBox:SetID(buttonIndex)

				if assignedTracks[i] == SoundtrackFrame.SelectedTrack then
					button:LockHighlight()
				else
					button:UnlockHighlight()
				end

				if SoundtrackFrame.SelectedEvent ~= nil then
					-- Update the highlight if that track is active for the event.
					if SoundtrackFrame_IsTrackActive(assignedTracks[i]) then
						checkBox:SetChecked(true)
					else
						checkBox:SetChecked(false)
					end

					-- Update the icon
					if Soundtrack.Library.CurrentlyPlayingTrack == assignedTracks[i] then
						icon:Show()
					end
				end
			end
		end
	end

	-- ScrollFrame stuff
	FauxScrollFrame_Update(
		SoundtrackFrameAssignedTracksScrollFrame,
		#assignedTracks + 1,
		ASSIGNED_TRACKS_TO_DISPLAY,
		EVENTS_ITEM_HEIGHT
	)

	SoundtrackFrame_RefreshUpDownButtons()
end

function SoundtrackFrame_MoveAssignedTrack(direction)
	local eventTable = Soundtrack.Events.GetTable(SoundtrackFrame.SelectedEventsTable)
	if eventTable[SoundtrackFrame.SelectedEvent] ~= nil then
		local event = eventTable[SoundtrackFrame.SelectedEvent]
		local currentIndex = IndexOf(event.tracks, SoundtrackFrame.SelectedTrack)

		if currentIndex > 0 then
			if direction < 0 and currentIndex > 1 then
				-- Move up
				local newIndex = currentIndex - 1
				local temp = event.tracks[newIndex]
				event.tracks[newIndex] = event.tracks[currentIndex]
				event.tracks[currentIndex] = temp
			elseif direction > 0 and currentIndex < #event.tracks then
				-- Move down
				local newIndex = currentIndex + 1
				local temp = event.tracks[newIndex]
				event.tracks[newIndex] = event.tracks[currentIndex]
				event.tracks[currentIndex] = temp
			end
		end

		SoundtrackFrame_RefreshAssignedTracks()
	end
end

-- DELETE TARGET BUTTON
function SoundtrackFrameDeleteTargetButton_OnClick()
	if SoundtrackFrame.SelectedEvent then
		StaticPopupDialogs["SOUNDTRACK_DELETE_TARGET_POPUP"] = {
			preferredIndex = 3,
			text = SOUNDTRACK_REMOVE_QUESTION,
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function()
				SoundtrackFrame_DeleteTarget(SoundtrackFrame.SelectedEvent)
			end,
			enterClicksFirstButton = 1,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
		}

		StaticPopup_Show("SOUNDTRACK_DELETE_TARGET_POPUP")
	end
end

function SoundtrackFrame_DeleteTarget(eventName)
	Soundtrack.Chat.TraceFrame("Deleting " .. SoundtrackFrame.SelectedEvent)
	Soundtrack.Events.DeleteEvent("Boss", eventName)
	SoundtrackFrame_RefreshEvents()
end

-- COPIED TRACKS BUTTONS
CopiedTracks = {}
function SoundtrackFrameCopyCopiedTracksButton_OnClick()
	if SoundtrackFrame.SelectedEvent then
		CopiedTracks = {}
		local eventTable = Soundtrack.Events.GetTable(SoundtrackFrame.SelectedEventsTable)
		local event = eventTable[SoundtrackFrame.SelectedEvent]
		for i = 0, #event.tracks do
			CopiedTracks[i] = event.tracks[i]
		end
		SoundtrackFrame_RefreshEvents()
	end
end

function SoundtrackFramePasteCopiedTracksButton_OnClick()
	if SoundtrackFrame.SelectedEvent then
		for i = 0, #CopiedTracks do
			Soundtrack.Events.Add(SoundtrackFrame.SelectedEventsTable, SoundtrackFrame.SelectedEvent, CopiedTracks[i])
		end
		SoundtrackFrame_RefreshEvents()
	end
end

function SoundtrackFrameClearCopiedTracksButton_OnClick()
	CopiedTracks = {}
end
