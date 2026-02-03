if not Tests then
	return
end

local Tests = Tests("SoundtrackUI", "PLAYER_ENTERING_WORLD")

local function MockFrame(name)
	local obj = {
		_visible = false,
		_enabled = true,
		_id = 1,
		Show = function(self) self._visible = true end,
		Hide = function(self) self._visible = false end,
		IsVisible = function(self) return self._visible end,
		Enable = function(self) self._enabled = true end,
		Disable = function(self) self._enabled = false end,
		SetPoint = function() end,
		SetWidth = function() end,
		GetID = function(self) return self._id end,
		SetID = function(self, id) self._id = id end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function MockFontString(name)
	local obj = {
		_text = "",
		SetText = function(self, text) self._text = text or "" end,
		GetText = function(self) return self._text end,
		SetWidth = function() end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function MockEditBox(name, text)
	local obj = {
		_text = text or "",
		GetText = function(self) return self._text end,
		SetText = function(self, value) self._text = value end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function SetupEventFrameButtons()
	MockFrame("SoundtrackFrameAddZoneButton")
	MockFrame("SoundtrackFrameRemoveZoneButton")
	MockFrame("SoundtrackFrameCollapseAllZoneButton")
	MockFrame("SoundtrackFrameExpandAllZoneButton")
	MockFrame("SoundtrackFrameAddPetBattlesTargetButton")
	MockFrame("SoundtrackFrameDeletePetBattlesTargetButton")
	MockFrame("SoundtrackFrameAddPlaylistButton")
	MockFrame("SoundtrackFrameDeletePlaylistButton")
	MockFrame("SoundtrackFrameAssignedTracks")
	MockFrame("SoundtrackFrame_EventSettings")
end

local function SetupTabFrames()
	MockFrame("SoundtrackFrameEventFrame")
	MockFrame("SoundtrackFrameOptionsTab")
	MockFrame("SoundtrackFrameProfilesFrame")
	MockFrame("SoundtrackFrameAboutFrame")
end

function Tests:Initialize_CallsOptionsTabInitialize()
	local called = false
	Replace(Soundtrack.OptionsTab, "Initialize", function()
		called = true
	end)

	SoundtrackUI.Initialize()

	IsTrue(called, "OptionsTab.Initialize should be called")
end

function Tests:ShowAssignedTracksSubFrame_ShowsAssignedTracksAndRefreshes()
	SetupEventFrameButtons()

	local refreshCalls = 0
	Replace(SoundtrackUI, "RefreshAssignedTracks", function()
		refreshCalls = refreshCalls + 1
	end)

	SoundtrackUI.ShowAssignedTracksSubFrame()

	IsTrue(SoundtrackFrameAssignedTracks:IsVisible(), "Assigned tracks frame should be visible")
	IsFalse(SoundtrackFrame_EventSettings:IsVisible(), "Event settings frame should be hidden")
	AreEqual(1, refreshCalls, "Assigned tracks refresh should run once")

	SoundtrackUI.ShowEventSettingsSubFrame()
	IsFalse(SoundtrackFrameAssignedTracks:IsVisible(), "Assigned tracks frame should be hidden")
	IsTrue(SoundtrackFrame_EventSettings:IsVisible(), "Event settings frame should be visible")
	AreEqual(1, refreshCalls, "Assigned tracks refresh should not run for event settings")
end

function Tests:OnLoad_RegistersSpecialFrameAndTabs()
	UISpecialFrames = {}
	local numTabs
	local selectedTab
	Replace(_G, "PanelTemplates_SetNumTabs", function(_, value)
		numTabs = value
	end)
	Replace(_G, "PanelTemplates_SetTab", function(_, value)
		selectedTab = value
	end)

	SoundtrackUI.OnLoad()

	AreEqual("SoundtrackFrame", UISpecialFrames[1])
	AreEqual(10, numTabs)
	AreEqual(1, selectedTab)
end

function Tests:OnUpdate_RefreshesTrackProgress()
	local called = false
	Replace(SoundtrackUI, "RefreshTrackProgress", function()
		called = true
	end)

	SoundtrackUI.OnUpdate()

	IsTrue(called, "RefreshTrackProgress should be invoked")
end

function Tests:RefreshTrackProgress_NoTrackLeavesTextUnchanged()
	Soundtrack.Library.CurrentlyPlayingTrack = nil
	SoundtrackFrame_StatusBarTrackText2:SetText("old")
	SoundtrackControlFrame_StatusBarTrackText2:SetText("old")

	SoundtrackUI.RefreshTrackProgress()

	AreEqual("old", SoundtrackFrame_StatusBarTrackText2:GetText())
	AreEqual("old", SoundtrackControlFrame_StatusBarTrackText2:GetText())
end

function Tests:RefreshTrackProgress_WithTrackUpdatesRemainingTime()
	Soundtrack_Tracks["song.mp3"] = { length = 120 }
	Soundtrack.Library.CurrentlyPlayingTrack = "song.mp3"
	Replace(Soundtrack.Timers, "Get", function()
		return { Start = 0 }
	end)
	Replace(_G, "GetTime", function() return 20 end)

	SoundtrackUI.RefreshTrackProgress()

	AreEqual("1:40", SoundtrackFrame_StatusBarTrackText2:GetText())
	AreEqual("1:40", SoundtrackControlFrame_StatusBarTrackText2:GetText())
end

function Tests:RefreshTrackProgress_TrackMissingLeavesTextUnchanged()
	Soundtrack.Library.CurrentlyPlayingTrack = "missing.mp3"
	SoundtrackFrame_StatusBarTrackText2:SetText("before")
	SoundtrackControlFrame_StatusBarTrackText2:SetText("before")

	SoundtrackUI.RefreshTrackProgress()

	AreEqual("before", SoundtrackFrame_StatusBarTrackText2:GetText())
	AreEqual("before", SoundtrackControlFrame_StatusBarTrackText2:GetText())
end

function Tests:InitializeColumnHeaderNameDropDown_AddsEntriesAndSorts()
	SoundtrackAddon.db.profile.settings.TrackSortingCriteria = "File Name"
	local added = {}
	Replace(_G, "UIDropDownMenu_AddButton", function(info)
		local copy = {}
		for key, value in pairs(info) do
			copy[key] = value
		end
		table.insert(added, copy)
	end)

	SoundtrackUI.InitializeColumnHeaderNameDropDown()

	AreEqual(#SOUNDTRACKFRAME_COLUMNHEADERNAME_LIST, #added)
	IsTrue(added[2].checked, "File Name should be checked")

	local sortType
	Replace(Soundtrack, "SortTracks", function(value)
		sortType = value
	end)

	SoundtrackAddon.db.profile.settings.TrackSortingCriteria = "filePath"
	local mockSelf = { sortType = "name", GetID = function() return 1 end }
	added[1].func(mockSelf)
	AreEqual("filePath", SoundtrackUI.nameHeaderType)
	AreEqual("filePath", sortType)

	SoundtrackAddon.db.profile.settings.TrackSortingCriteria = "Other"
	mockSelf.sortType = "duration"
	added[1].func(mockSelf)
	AreEqual("duration", sortType)
end

function Tests:OnEventStackChanged_EmptyStackRefreshesUI()
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 0 end)
	local eventStackUpdated = false
	local eventsUpdated = false
	Replace(SoundtrackUI, "UpdateEventStackUI", function() eventStackUpdated = true end)
	Replace(SoundtrackUI, "UpdateEventsUI", function() eventsUpdated = true end)

	SoundtrackUI.OnEventStackChanged()

	IsTrue(eventStackUpdated)
	IsTrue(eventsUpdated)
	AreEqual(SOUNDTRACK_NO_EVENT_PLAYING, SoundtrackFrame_StatusBarEventText1:GetText())
end

function Tests:OnEventStackChanged_WithEventUpdatesStatusBar()
	Soundtrack.AddEvent(ST_ZONE, "Zones/Test", ST_ZONE_LVL, true, false)
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	eventTable["Zones/Test"].tracks = { "track1.mp3", "track2.mp3" }
	Soundtrack.Library.CurrentlyPlayingTrack = "track2.mp3"
	Soundtrack.Events.Stack = { { tableName = ST_ZONE, eventName = "Zones/Test" } }
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)
	Replace(SoundtrackUI, "UpdateEventStackUI", function() end)
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)

	SoundtrackUI.OnEventStackChanged()

	AreEqual("Test", SoundtrackFrame_StatusBarEventText1:GetText())
	AreEqual("2 / 2", SoundtrackFrame_StatusBarEventText2:GetText())
	AreEqual("Test", SoundtrackControlFrame_StatusBarEventText1:GetText())
	AreEqual("2 / 2", SoundtrackControlFrame_StatusBarEventText2:GetText())
end

function Tests:UpdateTracksUI_RefreshesTracksAndStatus()
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 0 end)
	local refreshCalled = false
	Replace(SoundtrackUI, "RefreshTracks", function() refreshCalled = true end)

	SoundtrackUI.UpdateTracksUI()

	IsTrue(refreshCalled)
	AreEqual(SOUNDTRACK_NO_EVENT_PLAYING, SoundtrackFrame_StatusBarEventText1:GetText())
end

function Tests:ToggleEventFlags_FlipValues()
	SoundtrackUI.SelectedEventsTable = ST_MISC
	SoundtrackUI.SelectedEvent = "TestEvent"
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	eventTable["TestEvent"] = { random = false, soundEffect = false, continuous = false }

	SoundtrackUI.ToggleRandomMusic()
	SoundtrackUI.ToggleSoundEffect()
	SoundtrackUI.ToggleContinuousMusic()

	IsTrue(eventTable["TestEvent"].random)
	IsTrue(eventTable["TestEvent"].soundEffect)
	IsTrue(eventTable["TestEvent"].continuous)
end

function Tests:OnShow_SelectsActiveTabAndRefreshes()
	SetupEventFrameButtons()
	Soundtrack.Events.Stack = { { tableName = ST_ZONE, eventName = "Zone" } }
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)
	local tabIndex
	Replace(_G, "PanelTemplates_SetTab", function(_, value) tabIndex = value end)
	local refreshCalled = false
	Replace(SoundtrackUI, "RefreshShowingTab", function() refreshCalled = true end)
	Replace(Soundtrack, "StopEventAtLevel", function() end)
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
	Replace(_G, "GetFlatEventsTableForCurrentTab", function()
		return { { tag = "Event" } }
	end)

	SoundtrackUI.OnShow()

	AreEqual(TabUtils.GetTabIndex(ST_ZONE), tabIndex)
	IsTrue(refreshCalled)
	AreEqual(ST_ZONE, SoundtrackUI.SelectedEventsTable)
end

function Tests:OnHide_StopsCorrectLevels()
	local calls = {}
	Replace(Soundtrack, "StopEventAtLevel", function(level)
		table.insert(calls, level)
	end)

	SoundtrackUI.SelectedEventsTable = "Playlists"
	SoundtrackUI.OnHide()
	AreEqual(1, #calls)
	AreEqual(ST_PREVIEW_LVL, calls[1])

	calls = {}
	SoundtrackUI.SelectedEventsTable = ST_MISC
	SoundtrackUI.OnHide()
	AreEqual(2, #calls)
	AreEqual(ST_PREVIEW_LVL, calls[1])
	AreEqual(ST_PLAYLIST_LVL, calls[2])
end

function Tests:OnStatusBarClick_OpensMenu()
	local args
	Replace(_G, "ToggleDropDownMenu", function(...)
		args = { ... }
	end)

	SoundtrackUI.OnStatusBarClick()

	AreEqual("TOPLEFT", SoundtrackControlFrame_PlaylistMenu.point)
	AreEqual("BOTTOMLEFT", SoundtrackControlFrame_PlaylistMenu.relativePoint)
	AreEqual(1, args[1])
	AreEqual(SoundtrackControlFrame_PlaylistMenu, args[3])
	AreEqual(SoundtrackControlFrame_StatusBarTrack, args[4])
end

function Tests:OnClearButtonClick_ShowsPopupAndClears()
	local errorMessages = {}
	Replace(Soundtrack.Chat, "Error", function(msg)
		table.insert(errorMessages, msg)
	end)

	SoundtrackUI.SelectedEvent = nil
	SoundtrackUI.OnClearButtonClick()
	AreEqual(1, #errorMessages)

	local cleared = {}
	Replace(Soundtrack.Events, "ClearEvent", function(tableName, eventName)
		cleared.tableName = tableName
		cleared.eventName = eventName
	end)
	local updated = false
	Replace(SoundtrackUI, "UpdateEventsUI", function() updated = true end)
	local popupKey
	Replace(_G, "StaticPopup_Show", function(key) popupKey = key end)

	SoundtrackUI.SelectedEventsTable = ST_MISC
	SoundtrackUI.SelectedEvent = "ToClear"
	SoundtrackUI.OnClearButtonClick()

	AreEqual("SOUNDTRACK_CLEAR_SELECTED_EVENT", popupKey)
	StaticPopupDialogs["SOUNDTRACK_CLEAR_SELECTED_EVENT"].OnAccept()

	AreEqual(ST_MISC, cleared.tableName)
	AreEqual("ToClear", cleared.eventName)
	IsTrue(updated)
end

function Tests:RefreshShowingTab_UpdatesFramesAndButtons()
	SetupEventFrameButtons()
	SetupTabFrames()

	Replace(_G, "GetFlatEventsTableForCurrentTab", function()
		return { { tag = "EventA" } }
	end)

	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
	Replace(SoundtrackUI, "RefreshAssignedTracks", function() end)
	Replace(Soundtrack, "StopEvent", function() end)
	Replace(Soundtrack, "StopEventAtLevel", function() end)

	SoundtrackFrame.selectedTab = 2
	SoundtrackUI.RefreshShowingTab()

	AreEqual("Zone", SoundtrackUI.SelectedEventsTable)
	IsTrue(SoundtrackFrameEventFrame:IsVisible())
	IsTrue(SoundtrackFrameAddZoneButton:IsVisible())
	IsFalse(SoundtrackFrameAddPlaylistButton:IsVisible())

	SoundtrackFrame.selectedTab = 7
	SoundtrackUI.RefreshShowingTab()

	IsTrue(SoundtrackFrameOptionsTab:IsVisible())
	IsFalse(SoundtrackFrameEventFrame:IsVisible())
end

function Tests:FilterChanges_UpdateSortingAndFilters()
	MockEditBox("SoundtrackFrame_TrackFilter", "abc")
	MockEditBox("SoundtrackFrame_EventFilter", "def")
	local sortTracksCalled = false
	local sortEventsCalled = false
	Replace(Soundtrack, "SortTracks", function() sortTracksCalled = true end)
	Replace(Soundtrack, "SortAllEvents", function() sortEventsCalled = true end)

	SoundtrackUI.OnFilterChanged()
	SoundtrackUI.OnEventFilterChanged()

	AreEqual("abc", Soundtrack.trackFilter)
	AreEqual("def", Soundtrack.eventFilter)
	IsTrue(sortTracksCalled)
	IsTrue(sortEventsCalled)
end

function Tests:DisableAllEventButtons_HidesButtons()
	EVENTS_TO_DISPLAY = 3
	for i = 1, EVENTS_TO_DISPLAY, 1 do
		MockFrame("SoundtrackFrameEventButton" .. i)
	end

	SoundtrackUI.DisableAllEventButtons()

	for i = 1, EVENTS_TO_DISPLAY, 1 do
		IsFalse(_G["SoundtrackFrameEventButton" .. i]:IsVisible())
	end
end

function Tests:RenameEvent_InvokesRenameAndRefreshes()
	SoundtrackUI.SelectedEventsTable = ST_MISC
	SoundtrackUI.SelectedEvent = "Old"
	MockEditBox("SoundtrackFrame_EventName", "New")
	local renamed = {}
	Replace(Soundtrack.Events, "RenameEvent", function(tableName, oldName, newName)
		renamed.tableName = tableName
		renamed.oldName = oldName
		renamed.newName = newName
	end)
	local updated = false
	Replace(SoundtrackUI, "UpdateEventsUI", function() updated = true end)

	SoundtrackUI.RenameEvent()

	AreEqual(ST_MISC, renamed.tableName)
	AreEqual("Old", renamed.oldName)
	AreEqual("New", renamed.newName)
	IsTrue(updated)

	renamed = {}
	SoundtrackUI.SelectedEvent = nil
	SoundtrackUI.RenameEvent()
	IsFalse(renamed.tableName)
end

function Tests:Toggle_ShowsAndHidesFrame()
	SoundtrackFrame:Hide()
	SoundtrackUI.Toggle()
	IsTrue(SoundtrackFrame:IsVisible())
	SoundtrackUI.Toggle()
	IsFalse(SoundtrackFrame:IsVisible())
end

function Tests:EventTypeDropDownOnLoad_InitializesWidth()
	local initTarget
	local initFunc
	local initWidth
	_G.SoundtrackFrame_EventTypeDropDown_Initialize = function() end
	Replace(_G, "UIDropDownMenu_Initialize", function(target, func)
		initTarget = target
		initFunc = func
	end)
	Replace(_G, "UIDropDownMenu_SetWidth", function(target, width)
		initWidth = width
	end)

	local dropdown = MockFrame()
	SoundtrackUI.EventTypeDropDownOnLoad(dropdown)

	AreEqual(dropdown, initTarget)
	AreEqual(SoundtrackFrame_EventTypeDropDown_Initialize, initFunc)
	AreEqual(130, initWidth)
end

function Tests:RefreshUpDownButtons_TogglesButtonState()
	SoundtrackUI.SelectedEventsTable = ST_MISC
	SoundtrackUI.SelectedEvent = "TestEvent"
	SoundtrackUI.SelectedTrack = "track2"
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	eventTable["TestEvent"] = { tracks = { "track1", "track2", "track3" } }
	MockFrame("SoundtrackFrameMoveUp")
	MockFrame("SoundtrackFrameMoveDown")

	SoundtrackUI.RefreshUpDownButtons()

	IsTrue(SoundtrackFrameMoveUp._enabled)
	IsTrue(SoundtrackFrameMoveDown._enabled)

	SoundtrackUI.SelectedTrack = "track1"
	SoundtrackUI.RefreshUpDownButtons()

	IsFalse(SoundtrackFrameMoveUp._enabled)
	IsTrue(SoundtrackFrameMoveDown._enabled)
end

function Tests:CopyPasteAndClearTracks_UsesClipboard()
	SoundtrackUI.SelectedEventsTable = ST_MISC
	SoundtrackUI.SelectedEvent = "CopyEvent"
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	eventTable["CopyEvent"] = { tracks = { "a.mp3", "b.mp3" } }
	local updated = 0
	Replace(SoundtrackUI, "UpdateEventsUI", function() updated = updated + 1 end)

	SoundtrackUI.OnCopyTracksButtonClick()
	AreEqual(1, updated)

	local added = {}
	Replace(Soundtrack.Events, "Add", function(_, _, track)
		table.insert(added, track)
	end)

	SoundtrackUI.OnPasteTracksButtonClick()
	IsTrue(#added >= 2)
	AreEqual("a.mp3", added[#added - 1])
	AreEqual("b.mp3", added[#added])
	AreEqual(2, updated)

	SoundtrackUI.OnClearCopiedTracksButtonClick()
	added = {}
	SoundtrackUI.OnPasteTracksButtonClick()
	AreEqual(0, #added)
end
