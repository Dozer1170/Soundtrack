function SoundtrackFrame.NowPlayingFrame.SetNowPlayingText(title, artist, album)
	if SoundtrackAddon.db.profile.settings.ShowTrackInformation then
		TrackTextString:SetText(title)
		AlbumTextString:SetText(album)
		ArtistTextString:SetText(artist)
		TrackTextBG1:SetText("|cff444444" .. title)
		AlbumTextBG1:SetText("|cff444444" .. album)
		ArtistTextBG1:SetText("|cff444444" .. artist)
		UIFrameFlashStop(NowPlayingTextFrame)
		UIFrameFlash(NowPlayingTextFrame, 1, 1, 10, false, 8, 0)
	end
end
