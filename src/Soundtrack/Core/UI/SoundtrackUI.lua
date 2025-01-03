SoundtrackUI.SelectedEvent = nil
SoundtrackUI.SelectedTrack = nil
SoundtrackUI.SelectedEventsTable = nil

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
local suspendRenameEvent = false
local copiedTracks = {}

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
	ShowSubFrame(currentSubFrame)

	if currentSubFrame == SUB_FRAME_ASSIGNED_TRACKS then
		SoundtrackUI.RefreshAssignedTracks()
	end
end

local function TabChanged()
	if SoundtrackUI.SelectedEventsTable == nil then
		return
	end
	Soundtrack.StopEvent(ST_MISC, "Preview") -- Stop preview track

	-- Select first event if possible
	SoundtrackUI.SelectedEvent = nil

	local flatEvents = GetFlatEventsTableForCurrentTab()
	if flatEvents and #flatEvents >= 1 then
		SoundtrackUI.SelectedEvent = flatEvents[1].tag
	end

	SoundtrackUI.UpdateEventsUI()

	if SoundtrackUI.SelectedEventsTable == ST_ZONE then
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

	if SoundtrackUI.SelectedEventsTable == ST_PETBATTLES then
		SoundtrackFrameAddPetBattlesTargetButton:Show()
		SoundtrackFrameDeletePetBattlesTargetButton:Show()
	else
		SoundtrackFrameAddPetBattlesTargetButton:Hide()
		SoundtrackFrameDeletePetBattlesTargetButton:Hide()
	end

	if SoundtrackUI.SelectedEventsTable == ST_BOSS then
		SoundtrackFrameAddBossTargetButton:Show()
		SoundtrackFrameAddWorldBossTargetButton:Show()
		SoundtrackFrameDeleteTargetButton:Show()
	else
		SoundtrackFrameAddBossTargetButton:Hide()
		SoundtrackFrameAddWorldBossTargetButton:Hide()
		SoundtrackFrameDeleteTargetButton:Hide()
	end

	if SoundtrackUI.SelectedEventsTable == ST_CUSTOM then
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

	if SoundtrackUI.SelectedEventsTable == ST_PLAYLISTS then
		SoundtrackFrameAddPlaylistButton:Show()
		SoundtrackFrameDeletePlaylistButton:Show()
	else
		SoundtrackFrameAddPlaylistButton:Hide()
		SoundtrackFrameDeletePlaylistButton:Hide()
	end

	if SoundtrackUI.SelectedEventsTable ~= ST_OPTIONS then
		RefreshEventSubFrame()
	end

	if SoundtrackUI.SelectedEventsTable ~= ST_PLAYLISTS then
		Soundtrack.StopEventAtLevel(ST_PLAYLIST_LVL) -- Stop playlists when we go out of the playlist panel
	end
end

local function SelectActiveTab()
	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()

	if stackLevel > 0 then
		Soundtrack.Chat.TraceFrame("Selecting currently playing tab")
		local tableName = Soundtrack.Events.Stack[stackLevel].tableName
		SoundtrackUI.SelectedEventsTable = tableName
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
	SoundtrackUI.nameHeaderType = SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST[self:GetID()].type
	Soundtrack.Chat.TraceFrame("Refreshing tracks with " .. SoundtrackUI.nameHeaderType)
	if
		self.sortType == "name" and SoundtrackAddon.db.profile.settings.TrackSortingCriteria == "fileName"
		or SoundtrackAddon.db.profile.settings.TrackSortingCriteria == "filePath"
		or SoundtrackAddon.db.profile.settings.TrackSortingCriteria == "title"
	then
		Soundtrack.SortTracks(SoundtrackUI.nameHeaderType)
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
	Soundtrack.Events.ClearEvent(SoundtrackUI.SelectedEventsTable, eventToClear)

	SoundtrackUI.UpdateEventsUI()
end

local function SoundtrackFrame_EventTypeDropDown_OnClick(self)
	local oldSelectedId = UIDropDownMenu_GetSelectedID(SoundtrackFrame_EventTypeDropDown)
	local selectedId = self:GetID()

	if selectedId == oldSelectedId then
		return
	end

	local customEvent = SoundtrackAddon.db.profile.customEvents[SoundtrackUI.SelectedEvent]

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

	SoundtrackUI.UpdateCustomEventUI()
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

local function DeleteTarget(eventName)
	Soundtrack.Chat.TraceFrame("Deleting " .. SoundtrackUI.SelectedEvent)
	Soundtrack.Events.DeleteEvent("Boss", eventName)
	SoundtrackUI.UpdateEventsUI()
end

function SoundtrackUI.Initialize()
	Soundtrack.OptionsTab.Initialize()
end

function SoundtrackUI.ShowAssignedTracksSubFrame()
	currentSubFrame = SUB_FRAME_ASSIGNED_TRACKS
	RefreshEventSubFrame()
end

function SoundtrackUI.ShowEventSettingsSubFrame()
	currentSubFrame = SUB_FRAME_EVENT_SETTINGS
	RefreshEventSubFrame()
end

function SoundtrackUI.OnLoad()
	tinsert(UISpecialFrames, "SoundtrackFrame")

	PanelTemplates_SetNumTabs(SoundtrackFrame, 11)
	PanelTemplates_SetTab(SoundtrackFrame, 1)
end

function SoundtrackUI.OnUpdate()
	SoundtrackUI.RefreshTrackProgress()
end

function SoundtrackUI.RefreshTrackProgress()
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

function SoundtrackUI.InitializeColumnHeaderNameDropDown()
	local info = UIDropDownMenu_CreateInfo()
	for i = 1, #SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST, 1 do
		info.text = SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST[i].name
		info.func = OnColumnHeaderNameDropDownClick
		UIDropDownMenu_AddButton(info)
	end
end

function SoundtrackUI.OnEventStackChanged()
	RefreshCurrentlyPlaying()
	SoundtrackUI.UpdateEventStackUI()
	SoundtrackUI.UpdateEventsUI()
end

function SoundtrackUI.UpdateTracksUI()
	SoundtrackUI.RefreshTracks()
	RefreshCurrentlyPlaying()
end

function SoundtrackUI.ToggleRandomMusic()
	local eventTable = Soundtrack.Events.GetTable(SoundtrackUI.SelectedEventsTable)
	if eventTable[SoundtrackUI.SelectedEvent] then
		eventTable[SoundtrackUI.SelectedEvent].random = not eventTable[SoundtrackUI.SelectedEvent].random
	end
end

function SoundtrackUI.ToggleSoundEffect()
	local eventTable = Soundtrack.Events.GetTable(SoundtrackUI.SelectedEventsTable)
	if eventTable[SoundtrackUI.SelectedEvent] then
		eventTable[SoundtrackUI.SelectedEvent].soundEffect = not eventTable[SoundtrackUI.SelectedEvent].soundEffect
	end
end

function SoundtrackUI.ToggleContinuousMusic()
	local eventTable = Soundtrack.Events.GetTable(SoundtrackUI.SelectedEventsTable)
	if eventTable[SoundtrackUI.SelectedEvent] then
		eventTable[SoundtrackUI.SelectedEvent].continuous = not eventTable[SoundtrackUI.SelectedEvent].continuous
	end
end

function SoundtrackUI.OnShow()
	RefreshCurrentlyPlaying()
	SelectActiveTab()
	SoundtrackUI.RefreshShowingTab()
end

function SoundtrackUI.OnHide()
	Soundtrack.StopEventAtLevel(ST_PREVIEW_LVL)

	if SoundtrackUI.SelectedEventsTable ~= "Playlists" then
		Soundtrack.StopEventAtLevel(ST_PLAYLIST_LVL)
	end
end

function SoundtrackUI.OnStatusBarClick(_, _, _)
	Soundtrack.Chat.TraceFrame("StatusBar_OnClick")
	local menu = _G["SoundtrackControlFrame_PlaylistMenu"]
	local button = _G["SoundtrackControlFrame_StatusBarTrack"]
	menu.point = "TOPLEFT"
	menu.relativePoint = "BOTTOMLEFT"
	ToggleDropDownMenu(1, nil, menu, button, 0, 0)
end

function SoundtrackUI.OnClearButtonClick()
	if not SoundtrackUI.SelectedEvent then
		Soundtrack.Chat.Error("The Clear button was enabled without a selected event")
		return
	end

	StaticPopupDialogs["SOUNDTRACK_CLEAR_SELECTED_EVENT"] = {
		preferredIndex = 3,
		text = SOUNDTRACK_CLEAR_SELECTED_EVENT_QUESTION,
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			ClearEvent(SoundtrackUI.SelectedEvent)
		end,
		enterClicksFirstButton = 1,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopup_Show("SOUNDTRACK_CLEAR_SELECTED_EVENT")
end

function SoundtrackUI.RefreshShowingTab()
	SoundtrackUI.SelectedEventsTable = nil
	SoundtrackFrameEventFrame:Hide()
	SoundtrackFrameOptionsTab:Hide()
	SoundtrackFrameProfilesFrame:Hide()
	SoundtrackFrameAboutFrame:Hide()
	if SoundtrackFrame.selectedTab == 1 then
		SoundtrackUI.SelectedEventsTable = "Battle"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 2 then
		SoundtrackUI.SelectedEventsTable = "Boss"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 3 then
		SoundtrackUI.SelectedEventsTable = "Zone"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 4 then
		SoundtrackUI.SelectedEventsTable = "Pet Battles"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 5 then
		SoundtrackUI.SelectedEventsTable = "Dance"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 6 then
		SoundtrackUI.SelectedEventsTable = "Misc"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 7 then
		SoundtrackUI.SelectedEventsTable = "Custom"
		SoundtrackFrameEventFrame:Show()
	elseif SoundtrackFrame.selectedTab == 8 then
		SoundtrackUI.SelectedEventsTable = "Playlists"
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

function SoundtrackUI.OnFilterChanged()
	Soundtrack.trackFilter = SoundtrackFrame_TrackFilter:GetText()
	Soundtrack.SortTracks()
end

function SoundtrackUI.OnEventFilterChanged()
	Soundtrack.eventFilter = SoundtrackFrame_EventFilter:GetText()
	Soundtrack.SortAllEvents()
end

function SoundtrackUI.DisableAllEventButtons()
	for i = 1, EVENTS_TO_DISPLAY, 1 do
		local button = _G["SoundtrackFrameEventButton" .. i]
		button:Hide()
	end
end

function SoundtrackUI.RenameEvent()
	if SoundtrackUI.SelectedEvent and not suspendRenameEvent then
		Soundtrack.Events.RenameEvent(
			SoundtrackUI.SelectedEventsTable,
			SoundtrackUI.SelectedEvent,
			_G["SoundtrackFrame_EventName"]:GetText()
		)
		SoundtrackUI.UpdateEventsUI()
	end
end

function SoundtrackUI.Toggle()
	if SoundtrackFrame:IsVisible() then
		SoundtrackFrame:Hide()
	else
		SoundtrackFrame:Show()
	end
end

function SoundtrackUI.EventTypeDropDownOnLoad(self)
	UIDropDownMenu_Initialize(self, SoundtrackFrame_EventTypeDropDown_Initialize)
	UIDropDownMenu_SetWidth(self, 130)
end

function SoundtrackUI.RefreshUpDownButtons()
	local eventTable = Soundtrack.Events.GetTable(SoundtrackUI.SelectedEventsTable)
	if eventTable[SoundtrackUI.SelectedEvent] ~= nil then
		local event = eventTable[SoundtrackUI.SelectedEvent]
		local currentIndex = IndexOf(event.tracks, SoundtrackUI.SelectedTrack)

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
function SoundtrackUI.OnDeleteTargetButtonClick()
	if SoundtrackUI.SelectedEvent then
		StaticPopupDialogs["SOUNDTRACK_DELETE_TARGET_POPUP"] = {
			preferredIndex = 3,
			text = SOUNDTRACK_REMOVE_QUESTION,
			button1 = ACCEPT,
			button2 = CANCEL,
			OnAccept = function()
				DeleteTarget(SoundtrackUI.SelectedEvent)
			end,
			enterClicksFirstButton = 1,
			timeout = 0,
			whileDead = 1,
			hideOnEscape = 1,
		}

		StaticPopup_Show("SOUNDTRACK_DELETE_TARGET_POPUP")
	end
end

function SoundtrackUI.OnCopyTracksButtonClick()
	if SoundtrackUI.SelectedEvent then
		copiedTracks = {}
		local eventTable = Soundtrack.Events.GetTable(SoundtrackUI.SelectedEventsTable)
		local event = eventTable[SoundtrackUI.SelectedEvent]
		for i = 0, #event.tracks do
			copiedTracks[i] = event.tracks[i]
		end
		SoundtrackUI.UpdateEventsUI()
	end
end

function SoundtrackUI.OnPasteTracksButtonClick()
	if SoundtrackUI.SelectedEvent then
		for i = 0, #copiedTracks do
			Soundtrack.Events.Add(SoundtrackUI.SelectedEventsTable, SoundtrackUI.SelectedEvent, copiedTracks[i])
		end
		SoundtrackUI.UpdateEventsUI()
	end
end

function SoundtrackUI.OnClearCopiedTracksButtonClick()
	copiedTracks = {}
end
