SoundtrackFrame = {}
SoundtrackFrame.SelectedEvent = nil
SoundtrackFrame.SelectedTrack = nil
SoundtrackFrame.SelectedEventsTable = nil

local EVENTS_TO_DISPLAY = 21

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

local function TabChanged()
	if SoundtrackFrame.SelectedEventsTable == nil then
	else
		Soundtrack.StopEvent(ST_MISC, "Preview") -- Stop preview track

		-- Select first event if possible
		SoundtrackFrame.SelectedEvent = nil

		local table = GetFlatEventsTable()

		if table and #(GetFlatEventsTable()) >= 1 then
			SoundtrackFrame.SelectedEvent = table[1].tag
		end

		SoundtrackFrame.UpdateEventsUI()

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

local function SelectActiveTab()
	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()

	if stackLevel > 0 then
		Soundtrack.Chat.TraceFrame("Selecting currently playing tab")
		local tableName = Soundtrack.Events.Stack[stackLevel].tableName
		SoundtrackFrame.SelectedEventsTable = tableName
		PanelTemplates_SetTab(SoundtrackFrame, TabUtils.GetTabIndex(tableName))
		TabChanged()
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

local function RefreshCurrentlyPlaying()
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

local function ClearEvent(eventToClear)
	Soundtrack.Events.ClearEvent(SoundtrackFrame.SelectedEventsTable, eventToClear)

	SoundtrackFrame.UpdateEventsUI()
end

local function SoundtrackFrame_EventTypeDropDown_OnClick(self)
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

	SoundtrackFrame.UpdateCustomEventUI()
end

local function SoundtrackFrame_EventTypeDropDown_AddInfo(id, caption)
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

local function SoundtrackFrame_EventTypeDropDown_Initialize()
	for i = 1, #EVENT_TYPES do
		SoundtrackFrame_EventTypeDropDown_AddInfo(i, EVENT_TYPES[i])
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

function SoundtrackFrame.InitializeColumnHeaderNameDropDown()
	local info = UIDropDownMenu_CreateInfo()
	for i = 1, #SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST, 1 do
		info.text = SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST[i].name
		info.func = OnColumnHeaderNameDropDownClick
		UIDropDownMenu_AddButton(info)
	end
end

function SoundtrackFrame.OnEventStackChanged()
	RefreshCurrentlyPlaying()
	SoundtrackFrame.UpdateEventStackUI()
	SoundtrackFrame.UpdateEventsUI()
end

function SoundtrackFrame.UpdateTracksUI()
	SoundtrackFrame_RefreshTracks()
	RefreshCurrentlyPlaying()
end

function SoundtrackFrame.ToggleRandomMusic()
	local eventTable = Soundtrack.Events.GetTable(SoundtrackFrame.SelectedEventsTable)
	if eventTable[SoundtrackFrame.SelectedEvent] then
		eventTable[SoundtrackFrame.SelectedEvent].random = not eventTable[SoundtrackFrame.SelectedEvent].random
	end
end

function SoundtrackFrame.ToggleSoundEffect()
	local eventTable = Soundtrack.Events.GetTable(SoundtrackFrame.SelectedEventsTable)
	if eventTable[SoundtrackFrame.SelectedEvent] then
		eventTable[SoundtrackFrame.SelectedEvent].soundEffect =
			not eventTable[SoundtrackFrame.SelectedEvent].soundEffect
	end
end

function SoundtrackFrame.ToggleContinuousMusic()
	local eventTable = Soundtrack.Events.GetTable(SoundtrackFrame.SelectedEventsTable)
	if eventTable[SoundtrackFrame.SelectedEvent] then
		eventTable[SoundtrackFrame.SelectedEvent].continuous = not eventTable[SoundtrackFrame.SelectedEvent].continuous
	end
end

function SoundtrackFrame.OnShow()
	RefreshCurrentlyPlaying()
	SelectActiveTab()
	SoundtrackFrame.RefreshShowingTab()
end

function SoundtrackFrame.OnHide()
	Soundtrack.StopEventAtLevel(ST_PREVIEW_LVL)

	if SoundtrackFrame.SelectedEventsTable ~= "Playlists" then
		Soundtrack.StopEventAtLevel(ST_PLAYLIST_LVL)
	end
end

function SoundtrackFrame.OnStatusBarClick(_, _, _)
	Soundtrack.Chat.TraceFrame("StatusBar_OnClick")
	local menu = _G["SoundtrackControlFrame_PlaylistMenu"]
	local button = _G["SoundtrackControlFrame_StatusBarTrack"]
	menu.point = "TOPLEFT"
	menu.relativePoint = "BOTTOMLEFT"
	ToggleDropDownMenu(1, nil, menu, button, 0, 0)
end

function SoundtrackFrame.OnClearButtonClick()
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
			ClearEvent(SoundtrackFrame.SelectedEvent)
		end,
		enterClicksFirstButton = 1,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopup_Show("SOUNDTRACK_CLEAR_SELECTED_EVENT")
end

function SoundtrackFrame.RefreshShowingTab()
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

	TabChanged()
end

function SoundtrackFrame.OnFilterChanged()
	Soundtrack.trackFilter = SoundtrackFrame_TrackFilter:GetText()
	Soundtrack.SortTracks()
end

function SoundtrackFrame.OnEventFilterChanged()
	Soundtrack.eventFilter = SoundtrackFrame_EventFilter:GetText()
	Soundtrack.SortAllEvents()
end

function SoundtrackFrame.DisableAllEventButtons()
	for i = 1, EVENTS_TO_DISPLAY, 1 do
		local button = _G["SoundtrackFrameEventButton" .. i]
		button:Hide()
	end
end

function SoundtrackFrame.RenameEvent()
	if SoundtrackFrame.SelectedEvent and not suspendRenameEvent then
		Soundtrack.Events.RenameEvent(
			SoundtrackFrame.SelectedEventsTable,
			SoundtrackFrame.SelectedEvent,
			_G["SoundtrackFrame_EventName"]:GetText()
		)
		SoundtrackFrame.UpdateEventsUI()
	end
end

function SoundtrackFrame.Toggle()
	if SoundtrackFrame:IsVisible() then
		SoundtrackFrame:Hide()
	else
		SoundtrackFrame:Show()
	end
end

function SoundtrackFrame.EventTypeDropDownOnLoad(self)
	UIDropDownMenu_Initialize(self, SoundtrackFrame_EventTypeDropDown_Initialize)
	UIDropDownMenu_SetWidth(self, 130)
end

function SoundtrackFrame_RefreshUpDownButtons()
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
	SoundtrackFrame.UpdateEventsUI()
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
		SoundtrackFrame.UpdateEventsUI()
	end
end

function SoundtrackFramePasteCopiedTracksButton_OnClick()
	if SoundtrackFrame.SelectedEvent then
		for i = 0, #CopiedTracks do
			Soundtrack.Events.Add(SoundtrackFrame.SelectedEventsTable, SoundtrackFrame.SelectedEvent, CopiedTracks[i])
		end
		SoundtrackFrame.UpdateEventsUI()
	end
end

function SoundtrackFrameClearCopiedTracksButton_OnClick()
	CopiedTracks = {}
end
