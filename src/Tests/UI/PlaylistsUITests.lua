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
