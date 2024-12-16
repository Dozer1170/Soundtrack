-- Sort functions
local function CompareTracksByAlbum(i1, i2)
	return Soundtrack_Tracks[i1].album < Soundtrack_Tracks[i2].album
end

local function CompareTracksByArtist(i1, i2)
	return Soundtrack_Tracks[i1].artist < Soundtrack_Tracks[i2].artist
end

local function CompareTracksByTitle(i1, i2)
	return Soundtrack_Tracks[i1].title < Soundtrack_Tracks[i2].title
end

local function CompareTracksByFileName(i1, i2)
	return Soundtrack.GetPathFileName(i1) < Soundtrack.GetPathFileName(i2)
end

local function MatchTrack(trackName, track, filter)
	local lowerFilter = string.lower(filter)
	local index = string.find(string.lower(trackName), lowerFilter)
	if index then
		return true
	end
	index = string.find(string.lower(track.artist), lowerFilter)
	if index then
		return true
	end
	index = string.find(string.lower(track.album), lowerFilter)
	if index then
		return true
	end
	index = string.find(string.lower(track.title), lowerFilter)
	if index then
		return true
	end

	return nil
end

-- Sorts the list of tracks using the passed criteria, or uses
-- the last used sorting criteria
function Soundtrack.SortTracks(sortCriteria)
	if sortCriteria then
		Soundtrack.lastSortCriteria = sortCriteria
	else
		if Soundtrack.lastSortCriteria == nil then
			Soundtrack.lastSortCriteria = "filePath"
			sortCriteria = "filePath"
		else
			sortCriteria = Soundtrack.lastSortCriteria
		end
	end

	Soundtrack_SortedTracks = {}
	for k, v in pairs(Soundtrack_Tracks) do
		if not v.defaultTrack or SoundtrackAddon.db.profile.settings.ShowDefaultMusic then
			if not Soundtrack.trackFilter then
				table.insert(Soundtrack_SortedTracks, k)
			elseif MatchTrack(k, v, Soundtrack.trackFilter) then
				table.insert(Soundtrack_SortedTracks, k)
			end
		end
	end

	if sortCriteria == "album" then
		table.sort(Soundtrack_SortedTracks, CompareTracksByAlbum)
	elseif sortCriteria == "artist" then
		table.sort(Soundtrack_SortedTracks, CompareTracksByArtist)
	elseif sortCriteria == "filePath" then
		table.sort(Soundtrack_SortedTracks)
	elseif sortCriteria == "fileName" then
		table.sort(Soundtrack_SortedTracks, CompareTracksByFileName)
	elseif sortCriteria == "title" then
		table.sort(Soundtrack_SortedTracks, CompareTracksByTitle)
	end

	SoundtrackFrame_RefreshTracks()
end
