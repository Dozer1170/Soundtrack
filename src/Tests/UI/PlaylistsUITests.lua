if not Tests then
	return
end

local Tests = Tests("PlaylistsUI", "PLAYER_ENTERING_WORLD")

local function SetupUI()
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
end

local function TriggerAddPlaylistAccepted(name)
	Replace(_G, "StaticPopup_Show", function() end)
	SoundtrackUI.OnAddPlaylistButtonClick()
	-- Simulate accepting the popup with a custom edit box
	local dialog = StaticPopupDialogs["SOUNDTRACK_ADD_PLAYLIST_POPUP"]
	local mockSelf = {
		GetName = function() return "mockDialog" end,
	}
	_G["mockDialogEditBox"] = {
		GetText = function() return name end,
	}
	dialog.OnAccept(mockSelf)
end

local function TriggerDeletePlaylistConfirmed()
	Replace(_G, "StaticPopup_Show", function() end)
	SoundtrackUI.OnDeletePlaylistButtonClick()
end

-- Delete Playlist Tests

function Tests:OnDeletePlaylistButtonClick_RemovesSelectedPlaylist()
	SetupUI()
	Soundtrack.AddEvent(ST_PLAYLISTS, "My Playlist", ST_PLAYLIST_LVL, true)
	SoundtrackUI.SelectedEvent = "My Playlist"

	TriggerDeletePlaylistConfirmed()

	local eventTable = Soundtrack.Events.GetTable(ST_PLAYLISTS)
	IsTrue(eventTable["My Playlist"] == nil, "Playlist removed")
end

function Tests:OnDeletePlaylistButtonClick_CallsUpdateEventsUI()
	local called = false
	Replace(SoundtrackUI, "UpdateEventsUI", function() called = true end)
	Soundtrack.AddEvent(ST_PLAYLISTS, "My Playlist", ST_PLAYLIST_LVL, true)
	SoundtrackUI.SelectedEvent = "My Playlist"

	TriggerDeletePlaylistConfirmed()

	IsTrue(called, "UpdateEventsUI called after delete")
end

function Tests:OnDeletePlaylistButtonClick_DoesNotRemoveOtherPlaylists()
	SetupUI()
	Soundtrack.AddEvent(ST_PLAYLISTS, "Keep This", ST_PLAYLIST_LVL, true)
	Soundtrack.AddEvent(ST_PLAYLISTS, "Remove This", ST_PLAYLIST_LVL, true)
	SoundtrackUI.SelectedEvent = "Remove This"

	TriggerDeletePlaylistConfirmed()

	local eventTable = Soundtrack.Events.GetTable(ST_PLAYLISTS)
	IsTrue(eventTable["Keep This"] ~= nil, "Other playlist preserved")
	IsTrue(eventTable["Remove This"] == nil, "Selected playlist removed")
end

-- Add Playlist Tests

function Tests:AddPlaylist_AddsNamedPlaylist()
	SetupUI()
	if Soundtrack.SortEvents == nil then
		Soundtrack.SortEvents = function() end
	end

	TriggerAddPlaylistAccepted("My New Playlist")

	local eventTable = Soundtrack.Events.GetTable(ST_PLAYLISTS)
	IsTrue(eventTable["My New Playlist"] ~= nil, "Named playlist created")
end

function Tests:AddPlaylist_SetsSelectedEvent()
	SetupUI()
	if Soundtrack.SortEvents == nil then
		Soundtrack.SortEvents = function() end
	end

	SoundtrackUI.SelectedEvent = nil
	TriggerAddPlaylistAccepted("My New Playlist")

	AreEqual("My New Playlist", SoundtrackUI.SelectedEvent, "SelectedEvent set to new playlist name")
end

function Tests:AddPlaylist_WithEmptyName_CreatesDefaultName()
	SetupUI()
	if Soundtrack.SortEvents == nil then
		Soundtrack.SortEvents = function() end
	end

	TriggerAddPlaylistAccepted("")

	local eventTable = Soundtrack.Events.GetTable(ST_PLAYLISTS)
	IsTrue(eventTable["New Event 1"] ~= nil, "Default name 'New Event 1' created for empty input")
end

function Tests:AddPlaylist_WithEmptyName_IncrementsIndexIfNameExists()
	SetupUI()
	if Soundtrack.SortEvents == nil then
		Soundtrack.SortEvents = function() end
	end

	-- Pre-create "New Event 1"
	Soundtrack.AddEvent(ST_PLAYLISTS, "New Event 1", ST_PLAYLIST_LVL, true)

	TriggerAddPlaylistAccepted("")

	local eventTable = Soundtrack.Events.GetTable(ST_PLAYLISTS)
	IsTrue(eventTable["New Event 2"] ~= nil, "Incremented to 'New Event 2' when 'New Event 1' exists")
end

-- EditBoxOnEnterPressed / EscapePressed handler Tests

local function GetDialog()
	Replace(_G, "StaticPopup_Show", function() end)
	SoundtrackUI.OnAddPlaylistButtonClick()
	return StaticPopupDialogs["SOUNDTRACK_ADD_PLAYLIST_POPUP"]
end

function Tests:EditBoxOnEnterPressed_AddsPlaylist()
	SetupUI()
	if Soundtrack.SortEvents == nil then
		Soundtrack.SortEvents = function() end
	end

	local dialog = GetDialog()

	-- Simulate the EditBox: GetName() returns "mockEditBox", _G["mockEditBox"] holds itself
	local mockEditBox = {
		GetName = function() return "mockEditBox" end,
		GetParent = function()
			return { Hide = function() end }
		end,
	}
	mockEditBox.GetText = function() return "Pressed Playlist" end
	_G["mockEditBox"] = mockEditBox

	dialog.EditBoxOnEnterPressed(mockEditBox)

	local eventTable = Soundtrack.Events.GetTable(ST_PLAYLISTS)
	IsTrue(eventTable["Pressed Playlist"] ~= nil, "Playlist added via EditBoxOnEnterPressed")
end

function Tests:EditBoxOnEnterPressed_HidesParent()
	SetupUI()
	if Soundtrack.SortEvents == nil then
		Soundtrack.SortEvents = function() end
	end

	local dialog = GetDialog()
	local hidden = false
	local mockEditBox = {
		GetName = function() return "mockEditBox2" end,
		GetText = function() return "Another Playlist" end,
		GetParent = function()
			return { Hide = function() hidden = true end }
		end,
	}
	_G["mockEditBox2"] = mockEditBox

	dialog.EditBoxOnEnterPressed(mockEditBox)

	IsTrue(hidden, "Parent hidden after EditBoxOnEnterPressed")
end

function Tests:EditBoxOnEscapePressed_HidesParent()
	local dialog = GetDialog()
	local hidden = false
	local mockEditBox = {
		GetParent = function()
			return { Hide = function() hidden = true end }
		end,
	}

	dialog.EditBoxOnEscapePressed(mockEditBox)

	IsTrue(hidden, "Parent hidden after EditBoxOnEscapePressed")
end

function Tests:OnShow_SetsFocusAndClearsText()
	local dialog = GetDialog()
	local focusSet = false
	local textCleared = false

	local mockDialog = {
		GetName = function() return "mockPopupDialog" end,
	}
	_G["mockPopupDialogEditBox"] = {
		SetFocus = function() focusSet = true end,
		SetText  = function(_, t) textCleared = (t == "") end,
	}

	dialog.OnShow(mockDialog)

	IsTrue(focusSet,   "SetFocus called on edit box in OnShow")
	IsTrue(textCleared, "SetText('') called on edit box in OnShow")
end

-- PlaylistMenuInitialize Tests

function Tests:PlaylistMenuInitialize_AddsButtonForEachPlaylist()
	SetupUI()
	Soundtrack.AddEvent(ST_PLAYLISTS, "Jazz", ST_PLAYLIST_LVL, true)
	Soundtrack.AddEvent(ST_PLAYLISTS, "Rock", ST_PLAYLIST_LVL, true)

	local addedInfos = {}
	Replace(_G, "UIDropDownMenu_AddButton", function(info)
		table.insert(addedInfos, info)
	end)

	SoundtrackUI.PlaylistMenuInitialize()

	AreEqual(2, #addedInfos, "Two menu items added for two playlists")
end

function Tests:PlaylistMenuInitialize_ButtonFuncPlaysPlaylist()
	SetupUI()
	Soundtrack.AddEvent(ST_PLAYLISTS, "OnlyPlaylist", ST_PLAYLIST_LVL, true)

	local capturedTable, capturedEvent
	Replace(Soundtrack, "PlayEvent", function(tbl, evt)
		capturedTable = tbl
		capturedEvent = evt
	end)

	local capturedInfo
	Replace(_G, "UIDropDownMenu_AddButton", function(info)
		capturedInfo = info
	end)

	SoundtrackUI.PlaylistMenuInitialize()

	-- Call the menu item's func with an ID of 1
	local mockSelf = { GetID = function() return 1 end }
	capturedInfo.func(mockSelf)

	AreEqual(ST_PLAYLISTS, capturedTable, "PlayEvent called with ST_PLAYLISTS")
	AreEqual("OnlyPlaylist", capturedEvent, "PlayEvent called with the playlist name")
end
