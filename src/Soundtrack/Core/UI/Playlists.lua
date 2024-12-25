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
	SoundtrackFrame.SelectedEvent = playlistName
	Soundtrack.SortEvents("Playlists")
	SoundtrackFrame.UpdateEventsUI()
end

function SoundtrackFrame.OnAddPlaylistButtonClick(_)
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

function SoundtrackFrame.OnDeletePlaylistButtonClick()
	Soundtrack.Chat.TraceFrame("Deleting " .. SoundtrackFrame.SelectedEvent)
	Soundtrack.Events.DeleteEvent(ST_PLAYLISTS, SoundtrackFrame.SelectedEvent)
	SoundtrackFrame.UpdateEventsUI()
end
