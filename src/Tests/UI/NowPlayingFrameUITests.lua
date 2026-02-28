if not Tests then
	return
end

local Tests = Tests("NowPlayingFrameUI", "PLAYER_ENTERING_WORLD")

-- SetNowPlayingText Tests

function Tests:SetNowPlayingText_SetsTrackText_WhenShowTrackInformationIsTrue()
	SoundtrackAddon.db.profile.settings.ShowTrackInformation = true

	SoundtrackUI.NowPlayingFrame.SetNowPlayingText("My Song", "My Artist", "My Album")

	AreEqual("My Song", TrackTextString:GetText(), "Track title set")
end

function Tests:SetNowPlayingText_SetsAlbumText_WhenShowTrackInformationIsTrue()
	SoundtrackAddon.db.profile.settings.ShowTrackInformation = true

	SoundtrackUI.NowPlayingFrame.SetNowPlayingText("My Song", "My Artist", "My Album")

	AreEqual("My Album", AlbumTextString:GetText(), "Album set")
end

function Tests:SetNowPlayingText_SetsArtistText_WhenShowTrackInformationIsTrue()
	SoundtrackAddon.db.profile.settings.ShowTrackInformation = true

	SoundtrackUI.NowPlayingFrame.SetNowPlayingText("My Song", "My Artist", "My Album")

	AreEqual("My Artist", ArtistTextString:GetText(), "Artist set")
end

function Tests:SetNowPlayingText_DoesNotSetText_WhenShowTrackInformationIsFalse()
	SoundtrackAddon.db.profile.settings.ShowTrackInformation = false
	TrackTextString:SetText("Old Title")

	SoundtrackUI.NowPlayingFrame.SetNowPlayingText("New Song", "New Artist", "New Album")

	AreEqual("Old Title", TrackTextString:GetText(), "Track title unchanged when ShowTrackInformation is false")
end

function Tests:SetNowPlayingText_HandlesNilTitle_Gracefully()
	SoundtrackAddon.db.profile.settings.ShowTrackInformation = true

	SoundtrackUI.NowPlayingFrame.SetNowPlayingText(nil, "Artist", "Album")

	AreEqual("", TrackTextString:GetText(), "Empty string used for nil title")
end

function Tests:SetNowPlayingText_HandlesNilArtist_Gracefully()
	SoundtrackAddon.db.profile.settings.ShowTrackInformation = true

	SoundtrackUI.NowPlayingFrame.SetNowPlayingText("Title", nil, "Album")

	AreEqual("", ArtistTextString:GetText(), "Empty string used for nil artist")
end

function Tests:SetNowPlayingText_HandlesNilAlbum_Gracefully()
	SoundtrackAddon.db.profile.settings.ShowTrackInformation = true

	SoundtrackUI.NowPlayingFrame.SetNowPlayingText("Title", "Artist", nil)

	AreEqual("", AlbumTextString:GetText(), "Empty string used for nil album")
end

function Tests:SetNowPlayingText_SetsShadowText()
	SoundtrackAddon.db.profile.settings.ShowTrackInformation = true

	SoundtrackUI.NowPlayingFrame.SetNowPlayingText("My Song", "My Artist", "My Album")

	local bg1 = TrackTextBG1:GetText()
	IsTrue(bg1:find("My Song") ~= nil, "Shadow text includes title")
end
