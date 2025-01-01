local function AddPlaylist(playlistName)
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
	SoundtrackUI.SelectedEvent = playlistName
	Soundtrack.SortEvents("Playlists")
	SoundtrackUI.UpdateEventsUI()
end

local function OnPlaylistMenuClick(self)
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

function SoundtrackUI.OnAddPlaylistButtonClick(_)
	StaticPopupDialogs["SOUNDTRACK_ADD_PLAYLIST_POPUP"] = {
		preferredIndex = 3,
		text = SOUNDTRACK_ENTER_PLAYLIST_NAME,
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		maxLetters = 100,
		OnAccept = function(self)
			local playlistName = _G[self:GetName() .. "EditBox"]
			AddPlaylist(playlistName:GetText())
		end,
		OnShow = function(self)
			_G[self:GetName() .. "EditBox"]:SetFocus()
			_G[self:GetName() .. "EditBox"]:SetText("")
		end,
		OnHide = function(self) end,
		EditBoxOnEnterPressed = function(self)
			local playlistName = _G[self:GetName()]
			AddPlaylist(playlistName:GetText())
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

function SoundtrackUI.OnDeletePlaylistButtonClick()
	Soundtrack.Chat.TraceFrame("Deleting " .. SoundtrackUI.SelectedEvent)
	Soundtrack.Events.DeleteEvent(ST_PLAYLISTS, SoundtrackUI.SelectedEvent)
	SoundtrackUI.UpdateEventsUI()
end

function SoundtrackUI.PlaylistMenuInitialize()
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
		info.func = OnPlaylistMenuClick
		info.notCheckable = 1
		UIDropDownMenu_AddButton(info, 1)
	end
end
