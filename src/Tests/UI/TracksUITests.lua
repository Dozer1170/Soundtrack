if not Tests then
	return
end

local Tests = Tests("TracksUI", "PLAYER_ENTERING_WORLD")

local function MockTrackButton(name)
	local obj = {
		_visible = false,
		_id = 1,
		_locked = false,
		Show = function(self) self._visible = true end,
		Hide = function(self) self._visible = false end,
		IsVisible = function(self) return self._visible end,
		SetID = function(self, id) self._id = id end,
		GetID = function(self) return self._id end,
		LockHighlight = function(self) self._locked = true end,
		UnlockHighlight = function(self) self._locked = false end,
		CreateTexture = function(self)
			return {
				_visible = false,
				Show = function(self) self._visible = true end,
				Hide = function(self) self._visible = false end,
				IsShown = function(self) return self._visible end,
				SetAllPoints = function() end,
				SetColorTexture = function() end,
				SetSize = function() end,
				SetPoint = function() end,
			}
		end,
		SetPoint = function() end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function MockTrackButtonFontString(name)
	local obj = {
		_text = "",
		SetText = function(self, text) self._text = text or "" end,
		GetText = function(self) return self._text end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function MockCheckBox(name)
	local obj = {
		_checked = false,
		SetChecked = function(self, v) self._checked = v and true or false end,
		GetChecked = function(self) return self._checked end,
		SetID = function(self, id) self._id = id end,
		GetID = function(self) return self._id or 1 end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function SetupTracksUIFrames()
	for i = 1, 16 do
		MockTrackButton("SoundtrackFrameTrackButton" .. i)
		MockCheckBox("SoundtrackFrameTrackButton" .. i .. "CheckBox")
		MockTrackButtonFontString("SoundtrackFrameTrackButton" .. i .. "ButtonTextName")
		MockTrackButtonFontString("SoundtrackFrameTrackButton" .. i .. "ButtonTextAlbum")
		MockTrackButtonFontString("SoundtrackFrameTrackButton" .. i .. "ButtonTextArtist")
		MockTrackButtonFontString("SoundtrackFrameTrackButton" .. i .. "ButtonTextDuration")
		MockTrackButton("SoundtrackFrameTrackButton" .. i .. "Icon")
	end
	_G["SoundtrackFrameTrackScrollFrame"] = {}
	_G["FauxScrollFrame_GetOffset"] = function() return 0 end
end

-- PlayPreviewTrack (via OnTrackButtonClick) Tests

function Tests:OnTrackButtonClick_PlaysPreviewTrack()
	local playedEvent = nil
	Replace(Soundtrack, "PlayEvent", function(tableName, eventName)
		playedEvent = eventName
	end)
	if Soundtrack.SortEvents == nil then
		Soundtrack.SortEvents = function() end
	end
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
	Replace(SoundtrackUI, "RefreshTracks", function() end)

	Soundtrack_Tracks["Sound/Music/Test.mp3"] = { title = "Test", artist = "", album = "", length = 120 }
	Soundtrack_SortedTracks = { "Sound/Music/Test.mp3" }
	SoundtrackUI.SelectedEventsTable = ST_ZONE

	local btn = { _id = 1, GetID = function(self) return self._id end }
	SoundtrackUI.OnTrackButtonClick(btn, nil, nil)

	AreEqual("Preview", playedEvent, "Preview event played on track button click")
end

-- OnAllButtonClick Tests

function Tests:OnAllButtonClick_AssignsAllTracksToEvent()
	if Soundtrack.SortEvents == nil then
		Soundtrack.SortEvents = function() end
	end
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)

	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	Soundtrack_Tracks["Sound/Music/Track1.mp3"] = { title = "Track 1", artist = "", album = "", length = 100 }
	Soundtrack_Tracks["Sound/Music/Track2.mp3"] = { title = "Track 2", artist = "", album = "", length = 200 }
	Soundtrack_SortedTracks = { "Sound/Music/Track1.mp3", "Sound/Music/Track2.mp3" }

	SoundtrackUI.OnAllButtonClick()

	local event = Soundtrack.GetEvent(ST_ZONE, "Eastern Kingdoms")
	local tracks = event and event.tracks or {}
	local hasTrack1 = false
	local hasTrack2 = false
	for _, t in ipairs(tracks) do
		if t == "Sound/Music/Track1.mp3" then hasTrack1 = true end
		if t == "Sound/Music/Track2.mp3" then hasTrack2 = true end
	end
	IsTrue(hasTrack1, "Track1 assigned to event")
	IsTrue(hasTrack2, "Track2 assigned to event")
end

function Tests:OnAllButtonClick_ClearsExistingTracksFirst()
	if Soundtrack.SortEvents == nil then
		Soundtrack.SortEvents = function() end
	end
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)

	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	Soundtrack_Tracks["Sound/Music/OldTrack.mp3"] = { title = "Old", artist = "", album = "", length = 100 }
	Soundtrack.AssignTrack(ST_ZONE, "Eastern Kingdoms", "Sound/Music/OldTrack.mp3")

	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	Soundtrack_Tracks["Sound/Music/NewTrack.mp3"] = { title = "New", artist = "", album = "", length = 150 }
	Soundtrack_SortedTracks = { "Sound/Music/NewTrack.mp3" }

	SoundtrackUI.OnAllButtonClick()

	local event = Soundtrack.GetEvent(ST_ZONE, "Eastern Kingdoms")
	local tracks = event and event.tracks or {}
	local hasOldTrack = false
	for _, t in ipairs(tracks) do
		if t == "Sound/Music/OldTrack.mp3" then hasOldTrack = true end
	end
	IsFalse(hasOldTrack, "Old track not in list after OnAllButtonClick")
end

-- RefreshTracks Tests

function Tests:RefreshTracks_DoesNotError_WhenFrameIsNotVisible()
	SoundtrackFrame._visible = false

	-- Should return early without error
	SoundtrackUI.RefreshTracks()

	IsTrue(true, "RefreshTracks completes without error when frame not visible")
end

function Tests:RefreshTracks_DoesNotError_WhenNoEventsTableSelected()
	SoundtrackFrame._visible = true
	SoundtrackUI.SelectedEventsTable = nil

	-- Should return early without error
	SoundtrackUI.RefreshTracks()

	IsTrue(true, "RefreshTracks completes without error when no events table selected")
end

-- Helpers for rendering-path tests ------------------------------------------

local function SetupAssignedTrackFrames()
	for i = 1, 7 do
		MockTrackButton("SoundtrackAssignedTrackButton" .. i)
		MockCheckBox("SoundtrackAssignedTrackButton" .. i .. "CheckBox")
		MockTrackButtonFontString("SoundtrackAssignedTrackButton" .. i .. "ButtonTextName")
		MockTrackButtonFontString("SoundtrackAssignedTrackButton" .. i .. "ButtonTextAlbum")
		MockTrackButtonFontString("SoundtrackAssignedTrackButton" .. i .. "ButtonTextArtist")
		MockTrackButtonFontString("SoundtrackAssignedTrackButton" .. i .. "ButtonTextDuration")
		MockTrackButton("SoundtrackAssignedTrackButton" .. i .. "Icon")
	end
	_G["SoundtrackFrameAssignedTracksScrollFrame"] = {}
end

local function SetupAllFrames()
	SetupTracksUIFrames()
	SetupAssignedTrackFrames()
	SoundtrackFrame._visible = true
	_G["FauxScrollFrame_GetOffset"] = function() return 0 end
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
end

local function AddOneTrack(path)
	path = path or "Sound/Music/Test.mp3"
	Soundtrack_Tracks[path] = { title = "My Title", artist = "My Artist", album = "My Album", length = 120 }
	Soundtrack_SortedTracks = { path }
	return path
end

-- RefreshTracks rendering-path Tests -----------------------------------------

function Tests:RefreshTracks_ShowsButtonForTrackInViewport()
	SetupAllFrames()
	Replace(SoundtrackUI, "RefreshAssignedTracks", function() end)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = nil
	AddOneTrack()

	SoundtrackUI.RefreshTracks()

	IsTrue(_G["SoundtrackFrameTrackButton1"]._visible, "First track button is shown")
end

function Tests:RefreshTracks_SetsNameText_FilePath()
	SetupAllFrames()
	Replace(SoundtrackUI, "RefreshAssignedTracks", function() end)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = nil
	SoundtrackUI.nameHeaderType = "filePath"
	local path = AddOneTrack("Sound/Music/Village.mp3")

	SoundtrackUI.RefreshTracks()

	AreEqual(path, _G["SoundtrackFrameTrackButton1ButtonTextName"]._text, "Name text set to full path")
end

function Tests:RefreshTracks_SetsNameText_FileName()
	SetupAllFrames()
	Replace(SoundtrackUI, "RefreshAssignedTracks", function() end)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = nil
	SoundtrackUI.nameHeaderType = "fileName"
	AddOneTrack("Sound/Music/Village.mp3")

	SoundtrackUI.RefreshTracks()

	AreEqual("Village.mp3", _G["SoundtrackFrameTrackButton1ButtonTextName"]._text, "Name text set to filename only")
end

function Tests:RefreshTracks_SetsNameText_Title()
	SetupAllFrames()
	Replace(SoundtrackUI, "RefreshAssignedTracks", function() end)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = nil
	SoundtrackUI.nameHeaderType = "title"
	AddOneTrack()

	SoundtrackUI.RefreshTracks()

	AreEqual("My Title", _G["SoundtrackFrameTrackButton1ButtonTextName"]._text, "Name text set to track title")
end

function Tests:RefreshTracks_SetsAlbumAndArtistText()
	SetupAllFrames()
	Replace(SoundtrackUI, "RefreshAssignedTracks", function() end)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = nil
	AddOneTrack()

	SoundtrackUI.RefreshTracks()

	AreEqual("My Album", _G["SoundtrackFrameTrackButton1ButtonTextAlbum"]._text, "Album text set")
	AreEqual("My Artist", _G["SoundtrackFrameTrackButton1ButtonTextArtist"]._text, "Artist text set")
end

function Tests:RefreshTracks_SelectedTrack_LocksHighlight()
	SetupAllFrames()
	Replace(SoundtrackUI, "RefreshAssignedTracks", function() end)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = nil
	local path = AddOneTrack()
	SoundtrackUI.SelectedTrack = path

	SoundtrackUI.RefreshTracks()

	local btn = _G["SoundtrackFrameTrackButton1"]
	IsTrue(btn._selectedBg ~= nil, "Selected bg created for selected track")
	IsTrue(btn._selectedBg._visible, "Highlight visible for selected track")
end

function Tests:RefreshTracks_UnselectedTrack_UnlocksHighlight()
	SetupAllFrames()
	Replace(SoundtrackUI, "RefreshAssignedTracks", function() end)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = nil
	AddOneTrack()
	SoundtrackUI.SelectedTrack = "some/other/track.mp3"

	SoundtrackUI.RefreshTracks()

	IsFalse(_G["SoundtrackFrameTrackButton1"]._selectedBg, "No selected bg for unselected track")
end

function Tests:RefreshTracks_ActiveTrack_ChecksCheckBox()
	SetupAllFrames()
	Replace(SoundtrackUI, "RefreshAssignedTracks", function() end)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"
	local path = AddOneTrack()
	Replace(Soundtrack.Library, "IsTrackActive", function(t) return t == path end)

	SoundtrackUI.RefreshTracks()

	IsTrue(_G["SoundtrackFrameTrackButton1CheckBox"]._checked, "CheckBox checked for active track")
end

function Tests:RefreshTracks_InactiveTrack_UnchecksCheckBox()
	SetupAllFrames()
	Replace(SoundtrackUI, "RefreshAssignedTracks", function() end)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"
	AddOneTrack()
	Replace(Soundtrack.Library, "IsTrackActive", function() return false end)

	SoundtrackUI.RefreshTracks()

	IsFalse(_G["SoundtrackFrameTrackButton1CheckBox"]._checked, "CheckBox unchecked for inactive track")
end

function Tests:RefreshTracks_CurrentlyPlayingTrack_ShowsIcon()
	SetupAllFrames()
	Replace(SoundtrackUI, "RefreshAssignedTracks", function() end)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"
	local path = AddOneTrack()
	Replace(Soundtrack.Library, "IsTrackActive", function() return false end)
	Soundtrack.Library.CurrentlyPlayingTrack = path

	SoundtrackUI.RefreshTracks()

	IsTrue(_G["SoundtrackFrameTrackButton1Icon"]._visible, "Icon shown for currently playing track")
end

-- RefreshAssignedTracks Tests -------------------------------------------------

function Tests:RefreshAssignedTracks_WithNoSelectedEvent_ReturnsEarlyWithoutError()
	SetupAllFrames()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = nil

	SoundtrackUI.RefreshAssignedTracks()

	IsTrue(true, "RefreshAssignedTracks returns early without error when no selected event")
end

function Tests:RefreshAssignedTracks_WithMissingEvent_ReturnsEarlyWithoutError()
	SetupAllFrames()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = "NonExistentEvent"

	SoundtrackUI.RefreshAssignedTracks()

	IsTrue(true, "RefreshAssignedTracks returns early when event does not exist")
end

function Tests:RefreshAssignedTracks_ShowsButtonForAssignedTrack()
	SetupAllFrames()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	Soundtrack.AddEvent(ST_ZONE, "Elwynn Forest", ST_ZONE_LVL, true)
	local path = AddOneTrack()
	Soundtrack.AssignTrack(ST_ZONE, "Elwynn Forest", path)
	SoundtrackUI.SelectedEvent = "Elwynn Forest"
	Replace(Soundtrack.Library, "IsTrackActive", function() return false end)

	SoundtrackUI.RefreshAssignedTracks()

	IsTrue(_G["SoundtrackAssignedTrackButton1"]._visible, "Assigned track button shown")
end

function Tests:RefreshAssignedTracks_SetsNameText_FilePath()
	SetupAllFrames()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.nameHeaderType = "filePath"
	Soundtrack.AddEvent(ST_ZONE, "Elwynn Forest", ST_ZONE_LVL, true)
	local path = AddOneTrack("Sound/Music/Assigned.mp3")
	Soundtrack.AssignTrack(ST_ZONE, "Elwynn Forest", path)
	SoundtrackUI.SelectedEvent = "Elwynn Forest"
	Replace(Soundtrack.Library, "IsTrackActive", function() return false end)

	SoundtrackUI.RefreshAssignedTracks()

	AreEqual(path, _G["SoundtrackAssignedTrackButton1ButtonTextName"]._text, "Name text is full path")
end

function Tests:RefreshAssignedTracks_SetsNameText_FileName()
	SetupAllFrames()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.nameHeaderType = "fileName"
	Soundtrack.AddEvent(ST_ZONE, "Elwynn Forest", ST_ZONE_LVL, true)
	local path = AddOneTrack("Sound/Music/Assigned.mp3")
	Soundtrack.AssignTrack(ST_ZONE, "Elwynn Forest", path)
	SoundtrackUI.SelectedEvent = "Elwynn Forest"
	Replace(Soundtrack.Library, "IsTrackActive", function() return false end)

	SoundtrackUI.RefreshAssignedTracks()

	AreEqual("Assigned.mp3", _G["SoundtrackAssignedTrackButton1ButtonTextName"]._text, "Name text is filename")
end

function Tests:RefreshAssignedTracks_SetsNameText_Title()
	SetupAllFrames()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.nameHeaderType = "title"
	Soundtrack.AddEvent(ST_ZONE, "Elwynn Forest", ST_ZONE_LVL, true)
	local path = AddOneTrack()
	Soundtrack.AssignTrack(ST_ZONE, "Elwynn Forest", path)
	SoundtrackUI.SelectedEvent = "Elwynn Forest"
	Replace(Soundtrack.Library, "IsTrackActive", function() return false end)

	SoundtrackUI.RefreshAssignedTracks()

	AreEqual("My Title", _G["SoundtrackAssignedTrackButton1ButtonTextName"]._text, "Name text is track title")
end

function Tests:RefreshAssignedTracks_SelectedTrack_LocksHighlight()
	SetupAllFrames()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	Soundtrack.AddEvent(ST_ZONE, "Elwynn Forest", ST_ZONE_LVL, true)
	local path = AddOneTrack()
	Soundtrack.AssignTrack(ST_ZONE, "Elwynn Forest", path)
	SoundtrackUI.SelectedEvent = "Elwynn Forest"
	SoundtrackUI.SelectedTrack = path
	Replace(Soundtrack.Library, "IsTrackActive", function() return false end)

	SoundtrackUI.RefreshAssignedTracks()

	local btn = _G["SoundtrackAssignedTrackButton1"]
	IsTrue(btn._selectedBg ~= nil, "Selected bg created for assigned button")
	IsTrue(btn._selectedBg._visible, "Highlight visible for assigned selected track")
end

function Tests:RefreshAssignedTracks_ActiveTrack_ChecksCheckBox()
	SetupAllFrames()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	Soundtrack.AddEvent(ST_ZONE, "Elwynn Forest", ST_ZONE_LVL, true)
	local path = AddOneTrack()
	Soundtrack.AssignTrack(ST_ZONE, "Elwynn Forest", path)
	SoundtrackUI.SelectedEvent = "Elwynn Forest"
	Replace(Soundtrack.Library, "IsTrackActive", function(t) return t == path end)

	SoundtrackUI.RefreshAssignedTracks()

	IsTrue(_G["SoundtrackAssignedTrackButton1CheckBox"]._checked, "CheckBox checked for active assigned track")
end

function Tests:RefreshAssignedTracks_CurrentlyPlayingTrack_ShowsIcon()
	SetupAllFrames()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	Soundtrack.AddEvent(ST_ZONE, "Elwynn Forest", ST_ZONE_LVL, true)
	local path = AddOneTrack()
	Soundtrack.AssignTrack(ST_ZONE, "Elwynn Forest", path)
	SoundtrackUI.SelectedEvent = "Elwynn Forest"
	Replace(Soundtrack.Library, "IsTrackActive", function() return false end)
	Soundtrack.Library.CurrentlyPlayingTrack = path

	SoundtrackUI.RefreshAssignedTracks()

	IsTrue(_G["SoundtrackAssignedTrackButton1Icon"]._visible, "Icon shown for currently playing assigned track")
end

-- OnTrackCheckBoxClick Tests --------------------------------------------------

function Tests:OnTrackCheckBoxClick_WithActiveTrack_RemovesTrack()
	SetupAllFrames()
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
	Replace(SoundtrackUI, "RefreshTracks", function() end)

	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	local path = AddOneTrack()
	Soundtrack.AssignTrack(ST_ZONE, "Eastern Kingdoms", path)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	Replace(Soundtrack.Library, "IsTrackActive", function(t) return t == path end)

	local btn = { _id = 1, GetID = function(self) return self._id end }
	SoundtrackUI.OnTrackCheckBoxClick(btn, nil, nil)

	local event = Soundtrack.GetEvent(ST_ZONE, "Eastern Kingdoms")
	local tracks = event and event.tracks or {}
	local found = false
	for _, t in ipairs(tracks) do
		if t == path then found = true end
	end
	IsFalse(found, "Active track removed via checkbox click")
end

function Tests:OnTrackCheckBoxClick_WithInactiveTrack_AssignsTrack()
	SetupAllFrames()
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
	Replace(SoundtrackUI, "RefreshTracks", function() end)

	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	local path = AddOneTrack()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	Replace(Soundtrack.Library, "IsTrackActive", function() return false end)

	local btn = { _id = 1, GetID = function(self) return self._id end }
	SoundtrackUI.OnTrackCheckBoxClick(btn, nil, nil)

	local event = Soundtrack.GetEvent(ST_ZONE, "Eastern Kingdoms")
	local tracks = event and event.tracks or {}
	local found = false
	for _, t in ipairs(tracks) do
		if t == path then found = true end
	end
	IsTrue(found, "Inactive track assigned via checkbox click")
end

function Tests:OnTrackCheckBoxClick_WithNoSelectedEvent_DoesNotModifyTracks()
	SetupAllFrames()
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
	Replace(SoundtrackUI, "RefreshTracks", function() end)

	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	AddOneTrack()
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = nil

	local removeCalled = false
	Replace(Soundtrack.Events, "Remove", function() removeCalled = true end)
	local assignCalled = false
	Replace(Soundtrack, "AssignTrack", function() assignCalled = true end)

	local btn = { _id = 1, GetID = function(self) return self._id end }
	SoundtrackUI.OnTrackCheckBoxClick(btn, nil, nil)

	IsFalse(removeCalled, "Remove not called when no event selected")
	IsFalse(assignCalled, "AssignTrack not called when no event selected")
end

-- OnAssignedTrackCheckBoxClick Tests -----------------------------------------

function Tests:OnAssignedTrackCheckBoxClick_WithActiveTrack_RemovesTrack()
	SetupAllFrames()
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
	Replace(SoundtrackUI, "RefreshTracks", function() end)

	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	local path = AddOneTrack()
	Soundtrack.AssignTrack(ST_ZONE, "Eastern Kingdoms", path)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	Replace(Soundtrack.Library, "IsTrackActive", function(t) return t == path end)

	local btn = { _id = 1, GetID = function(self) return self._id end }
	SoundtrackUI.OnAssignedTrackCheckBoxClick(btn, nil, nil)

	local event = Soundtrack.GetEvent(ST_ZONE, "Eastern Kingdoms")
	local tracks = event and event.tracks or {}
	local found = false
	for _, t in ipairs(tracks) do
		if t == path then found = true end
	end
	IsFalse(found, "Active track removed via assigned checkbox click")
end

function Tests:OnAssignedTrackCheckBoxClick_WithInactiveTrack_AssignsTrack()
	SetupAllFrames()
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
	Replace(SoundtrackUI, "RefreshTracks", function() end)

	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	local path = AddOneTrack()
	Soundtrack.AssignTrack(ST_ZONE, "Eastern Kingdoms", path)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	Replace(Soundtrack.Library, "IsTrackActive", function() return false end)

	local assignCalled = false
	local assignedTrack = nil
	Replace(Soundtrack, "AssignTrack", function(tbl, evt, trk)
		assignCalled = true
		assignedTrack = trk
	end)

	local btn = { _id = 1, GetID = function(self) return self._id end }
	SoundtrackUI.OnAssignedTrackCheckBoxClick(btn, nil, nil)

	IsTrue(assignCalled, "AssignTrack called for inactive assigned track")
	AreEqual(path, assignedTrack, "Correct track re-assigned")
end

-- OnAssignedTrackButtonClick Tests --------------------------------------------

function Tests:OnAssignedTrackButtonClick_PlaysPreviewTrack()
	SetupAllFrames()
	Replace(SoundtrackUI, "RefreshTracks", function() end)
	if Soundtrack.SortEvents == nil then
		Soundtrack.SortEvents = function() end
	end

	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	local path = AddOneTrack()
	Soundtrack.AssignTrack(ST_ZONE, "Eastern Kingdoms", path)
	SoundtrackUI.SelectedEventsTable = ST_ZONE
	SoundtrackUI.SelectedEvent = "Eastern Kingdoms"

	local playedEvent = nil
	Replace(Soundtrack, "PlayEvent", function(tbl, evt)
		playedEvent = evt
	end)

	local btn = { _id = 1, GetID = function(self) return self._id end }
	SoundtrackUI.OnAssignedTrackButtonClick(btn, nil, nil)

	AreEqual("Preview", playedEvent, "Preview event played for assigned track button click")
end
