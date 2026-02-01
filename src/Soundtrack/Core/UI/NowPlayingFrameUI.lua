SoundtrackUI.NowPlayingFrame = {}

function SoundtrackUI.NowPlayingFrame.SetNowPlayingText(title, artist, album)
	local safeTitle = title or ""
	local safeArtist = artist or ""
	local safeAlbum = album or ""
	if SoundtrackAddon.db.profile.settings.ShowTrackInformation then
		TrackTextString:SetText(safeTitle)
		AlbumTextString:SetText(safeAlbum)
		ArtistTextString:SetText(safeArtist)
		TrackTextBG1:SetText("|cff444444" .. safeTitle)
		AlbumTextBG1:SetText("|cff444444" .. safeAlbum)
		ArtistTextBG1:SetText("|cff444444" .. safeArtist)
		UIFrameFlashStop(NowPlayingTextFrame)
		UIFrameFlash(NowPlayingTextFrame, 1, 1, 10, false, 8, 0)
	end
end
