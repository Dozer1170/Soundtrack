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
