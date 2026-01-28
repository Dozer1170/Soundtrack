if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

function Tests:SortTracks_ByFilePath_SortsAlphabetically()
	-- Setup tracks
	Soundtrack_Tracks = {
		["zebra.mp3"] = { title = "Zebra", artist = "Artist", album = "Album", filePath = "zebra.mp3" },
		["apple.mp3"] = { title = "Apple", artist = "Artist", album = "Album", filePath = "apple.mp3" },
		["middle.mp3"] = { title = "Middle", artist = "Artist", album = "Album", filePath = "middle.mp3" },
	}

	-- Sort by filePath (default)
	Soundtrack.SortTracks("filePath")

	-- Check order
	AreEqual(Soundtrack_SortedTracks[1], "apple.mp3")
	AreEqual("middle.mp3", Soundtrack_SortedTracks[2])
	AreEqual("zebra.mp3", Soundtrack_SortedTracks[3])
end

function Tests:SortTracks_ByTitle_SortsByTitleField()
	-- Setup tracks with different titles
	Soundtrack_Tracks = {
		["track1.mp3"] = { title = "Zebra Song", artist = "Artist", album = "Album", filePath = "track1.mp3" },
		["track2.mp3"] = { title = "Apple Song", artist = "Artist", album = "Album", filePath = "track2.mp3" },
		["track3.mp3"] = { title = "Middle Song", artist = "Artist", album = "Album", filePath = "track3.mp3" },
	}

	-- Sort by title
	Soundtrack.SortTracks("title")

	-- Check order
	AreEqual("Apple Song", Soundtrack_Tracks[Soundtrack_SortedTracks[1]].title)
	AreEqual("Middle Song", Soundtrack_Tracks[Soundtrack_SortedTracks[2]].title)
	AreEqual("Zebra Song", Soundtrack_Tracks[Soundtrack_SortedTracks[3]].title)
end

function Tests:SortTracks_ByArtist_SortsByArtistField()
	-- Setup tracks with different artists
	Soundtrack_Tracks = {
		["track1.mp3"] = { title = "Song", artist = "Zeppelin", album = "Album", filePath = "track1.mp3" },
		["track2.mp3"] = { title = "Song", artist = "Beatles", album = "Album", filePath = "track2.mp3" },
		["track3.mp3"] = { title = "Song", artist = "Metallica", album = "Album", filePath = "track3.mp3" },
	}

	-- Sort by artist
	Soundtrack.SortTracks("artist")

	-- Check order
	AreEqual("Beatles", Soundtrack_Tracks[Soundtrack_SortedTracks[1]].artist)
	AreEqual("Metallica", Soundtrack_Tracks[Soundtrack_SortedTracks[2]].artist)
	AreEqual("Zeppelin", Soundtrack_Tracks[Soundtrack_SortedTracks[3]].artist)
end

function Tests:SortTracks_ByAlbum_SortsByAlbumField()
	-- Setup tracks with different albums
	Soundtrack_Tracks = {
		["track1.mp3"] = { title = "Song", artist = "Artist", album = "Zulu", filePath = "track1.mp3" },
		["track2.mp3"] = { title = "Song", artist = "Artist", album = "Alpha", filePath = "track2.mp3" },
		["track3.mp3"] = { title = "Song", artist = "Artist", album = "Bravo", filePath = "track3.mp3" },
	}

	-- Sort by album
	Soundtrack.SortTracks("album")

	-- Check order
	AreEqual("Alpha", Soundtrack_Tracks[Soundtrack_SortedTracks[1]].album)
	AreEqual("Bravo", Soundtrack_Tracks[Soundtrack_SortedTracks[2]].album)
	AreEqual("Zulu", Soundtrack_Tracks[Soundtrack_SortedTracks[3]].album)
end

function Tests:SortTracks_ByFileName_SortsByFileNameOnly()
	-- Setup tracks with paths
	Soundtrack_Tracks = {
		["path/to/zebra.mp3"] = { title = "Song", artist = "Artist", album = "Album", filePath = "path/to/zebra.mp3" },
		["path/to/apple.mp3"] = { title = "Song", artist = "Artist", album = "Album", filePath = "path/to/apple.mp3" },
	}

	-- Sort by fileName (should ignore path)
	Soundtrack.SortTracks("fileName")

	-- Check order - should be sorted by filename only
	local firstName = GetPathFileName(Soundtrack_SortedTracks[1])
	local secondName = GetPathFileName(Soundtrack_SortedTracks[2])

	IsTrue(firstName < secondName, "Files sorted by name")
end

function Tests:SortTracks_RemembersCriteria_UsesLastSortWhenNoCriteriaProvided()
	-- Setup tracks
	Soundtrack_Tracks = {
		["track1.mp3"] = { title = "Zebra", artist = "Artist", album = "Album", filePath = "track1.mp3" },
		["track2.mp3"] = { title = "Apple", artist = "Artist", album = "Album", filePath = "track2.mp3" },
	}

	-- Sort by title first
	Soundtrack.SortTracks("title")
	local firstOrder = Soundtrack_SortedTracks[1]

	-- Sort again without criteria (should use last criteria)
	Soundtrack.SortTracks()
	local secondOrder = Soundtrack_SortedTracks[1]

	-- Should be the same order (both using title sort)
	AreEqual(firstOrder, secondOrder)
	AreEqual("title", Soundtrack.lastSortCriteria)
end

function Tests:SortTracks_WithFilter_OnlyIncludesMatchingTracks()
	-- Setup tracks
	Soundtrack_Tracks = {
		["battle1.mp3"] = { title = "Epic Battle", artist = "Composer", album = "OST", filePath = "battle1.mp3" },
		["peace1.mp3"] = { title = "Peaceful", artist = "Composer", album = "OST", filePath = "peace1.mp3" },
		["battle2.mp3"] = { title = "Final Fight", artist = "Composer", album = "OST", filePath = "battle2.mp3" },
	}

	-- Set filter
	Soundtrack.trackFilter = "battle"

	-- Sort
	Soundtrack.SortTracks("filePath")

	-- Should only include tracks matching filter
	AreEqual(2, #Soundtrack_SortedTracks)

	-- Clear filter
	Soundtrack.trackFilter = nil
end

function Tests:SortTracks_FilterMatchesTitle_IncludesTrack()
	-- Setup tracks
	Soundtrack_Tracks = {
		["track1.mp3"] = { title = "Battle Theme", artist = "Composer", album = "OST", filePath = "track1.mp3" },
		["track2.mp3"] = { title = "Peace Theme", artist = "Composer", album = "OST", filePath = "track2.mp3" },
	}

	-- Filter by title content
	Soundtrack.trackFilter = "battle"

	Soundtrack.SortTracks("filePath")

	-- Should find the battle track
	AreEqual(1, #Soundtrack_SortedTracks)
	AreEqual("track1.mp3", Soundtrack_SortedTracks[1])

	Soundtrack.trackFilter = nil
end

function Tests:SortTracks_FilterMatchesArtist_IncludesTrack()
	-- Setup tracks
	Soundtrack_Tracks = {
		["track1.mp3"] = { title = "Song", artist = "Beethoven", album = "Album", filePath = "track1.mp3" },
		["track2.mp3"] = { title = "Song", artist = "Mozart", album = "Album", filePath = "track2.mp3" },
	}

	-- Filter by artist
	Soundtrack.trackFilter = "beethoven"

	Soundtrack.SortTracks("filePath")

	-- Should find Beethoven track
	AreEqual(1, #Soundtrack_SortedTracks)
	AreEqual("track1.mp3", Soundtrack_SortedTracks[1])

	Soundtrack.trackFilter = nil
end

function Tests:SortTracks_FilterMatchesAlbum_IncludesTrack()
	-- Setup tracks
	Soundtrack_Tracks = {
		["track1.mp3"] = { title = "Song", artist = "Artist", album = "Greatest Hits", filePath = "track1.mp3" },
		["track2.mp3"] = { title = "Song", artist = "Artist", album = "B-Sides", filePath = "track2.mp3" },
	}

	-- Filter by album
	Soundtrack.trackFilter = "greatest"

	Soundtrack.SortTracks("filePath")

	-- Should find track by album
	AreEqual(1, #Soundtrack_SortedTracks)
	AreEqual("track1.mp3", Soundtrack_SortedTracks[1])

	Soundtrack.trackFilter = nil
end

function Tests:SortTracks_HidesDefaultTracks_WhenSettingDisabled()
	-- Setup: Mix of default and custom tracks
	Soundtrack_Tracks = {
		["custom.mp3"] = { title = "Custom", artist = "Artist", album = "Album", filePath = "custom.mp3", defaultTrack = false },
		["default.mp3"] = { title = "Default", artist = "Artist", album = "Album", filePath = "default.mp3", defaultTrack = true },
	}

	-- Disable showing default music
	SoundtrackAddon.db.profile.settings.ShowDefaultMusic = false

	Soundtrack.SortTracks("filePath")

	-- Should only show custom track
	AreEqual(1, #Soundtrack_SortedTracks)
	AreEqual("custom.mp3", Soundtrack_SortedTracks[1])

	-- Reset setting
	SoundtrackAddon.db.profile.settings.ShowDefaultMusic = true
end

function Tests:SortTracks_ShowsDefaultTracks_WhenSettingEnabled()
	-- Setup: Mix of default and custom tracks
	Soundtrack_Tracks = {
		["custom.mp3"] = { title = "Custom", artist = "Artist", album = "Album", filePath = "custom.mp3", defaultTrack = false },
		["default.mp3"] = { title = "Default", artist = "Artist", album = "Album", filePath = "default.mp3", defaultTrack = true },
	}

	-- Enable showing default music
	SoundtrackAddon.db.profile.settings.ShowDefaultMusic = true

	Soundtrack.SortTracks("filePath")

	-- Should show both tracks
	AreEqual(2, #Soundtrack_SortedTracks)
end

function Tests:SortEvents_BasicSort_SortsAlphabetically()
	-- Setup: Clear filters
	Soundtrack.eventFilter = nil
	Soundtrack.trackFilter = nil

	-- Setup events
	local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
	eventTable["Zebra"] = { tracks = {} }
	eventTable["Apple"] = { tracks = {} }
	eventTable["Middle"] = { tracks = {} }

	-- Sort events
	Soundtrack.SortEvents(ST_BATTLE)

	-- Check sorted order
	AreEqual("Apple", Soundtrack_FlatEvents[ST_BATTLE][1].tag)
	AreEqual("Middle", Soundtrack_FlatEvents[ST_BATTLE][2].tag)
	AreEqual("Zebra", Soundtrack_FlatEvents[ST_BATTLE][3].tag)
end

function Tests:SortEvents_HidesPreview_ExcludesPreviewEvent()
	-- Setup events including Preview
	local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
	eventTable["Preview"] = { tracks = {} }
	eventTable["NormalEvent"] = { tracks = {} }

	-- Sort events
	Soundtrack.SortEvents(ST_BATTLE)

	-- Preview should not be in sorted list
	local foundPreview = false
	for _, eventName in ipairs(Soundtrack_FlatEvents[ST_BATTLE]) do
		if eventName == "Preview" then
			foundPreview = true
		end
	end

	IsTrue(not foundPreview, "Preview event excluded")
	AreEqual(1, #Soundtrack_FlatEvents[ST_BATTLE])
end

function Tests:SortEvents_WithFilter_OnlyIncludesMatchingEvents()
	-- Setup events
	local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
	eventTable["Boss_Fight"] = { tracks = {} }
	eventTable["Trash_Mob"] = { tracks = {} }
	eventTable["Boss_Victory"] = { tracks = {} }

	-- Set filter
	Soundtrack.eventFilter = "boss"

	-- Sort events
	Soundtrack.SortEvents(ST_BATTLE)

	-- Should only include events matching filter
	AreEqual(2, #Soundtrack_FlatEvents[ST_BATTLE])

	-- Clear filter
	Soundtrack.eventFilter = nil
end

function Tests:SortEvents_WithEmptyFilter_IncludesAllEvents()
	-- Setup events
	local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
	eventTable["Event1"] = { tracks = {} }
	eventTable["Event2"] = { tracks = {} }

	-- Set empty filter
	Soundtrack.eventFilter = ""

	-- Sort events
	Soundtrack.SortEvents(ST_BATTLE)

	-- Should include all events (except Preview)
	AreEqual(2, #Soundtrack_FlatEvents[ST_BATTLE])

	Soundtrack.eventFilter = nil
end

function Tests:SortEvents_BuildsEventTree_CreatesHierarchy()
	-- Setup hierarchical events
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	eventTable["Continent/Zone/SubZone"] = { tracks = {} }
	eventTable["Continent/Zone"] = { tracks = {} }
	eventTable["Continent"] = { tracks = {} }

	-- Sort events (builds tree)
	Soundtrack.SortEvents(ST_ZONE)

	-- Check tree was created
	IsTrue(Soundtrack_EventNodes[ST_ZONE] ~= nil, "Event tree created")
	AreEqual(ST_ZONE, Soundtrack_EventNodes[ST_ZONE].name)
	IsTrue(#Soundtrack_EventNodes[ST_ZONE].nodes > 0, "Root has child nodes")
end

function Tests:SortEvents_TreeStructure_HasCorrectHierarchy()
	-- Setup simple hierarchy
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	eventTable["Parent/Child"] = { tracks = {} }

	-- Sort events
	Soundtrack.SortEvents(ST_ZONE)

	local rootNode = Soundtrack_EventNodes[ST_ZONE]

	-- Should have Parent node
	AreEqual(1, #rootNode.nodes)
	AreEqual("Parent", rootNode.nodes[1].name)

	-- Parent should have Child node
	local parentNode = rootNode.nodes[1]
	AreEqual(1, #parentNode.nodes)
	AreEqual("Child", parentNode.nodes[1].name)
end

function Tests:SortEvents_TreeTags_StoresFullPath()
	-- Setup event
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	eventTable["Continent/Zone"] = { tracks = {} }

	-- Sort events
	Soundtrack.SortEvents(ST_ZONE)

	local rootNode = Soundtrack_EventNodes[ST_ZONE]
	local continentNode = rootNode.nodes[1]
	local zoneNode = continentNode.nodes[1]

	-- Check that leaf node has full path tag
	AreEqual("Continent/Zone", zoneNode.tag)
end

function Tests:SortAllEvents_SortsAllTables_ProcessesAllEventTabs()
	-- Setup events in multiple tables
	local battleTable = Soundtrack.Events.GetTable(ST_BATTLE)
	battleTable["BattleEvent"] = { tracks = {} }

	local zoneTable = Soundtrack.Events.GetTable(ST_ZONE)
	zoneTable["ZoneEvent"] = { tracks = {} }

	-- Initialize all other event tables to avoid nil errors
	Soundtrack.Events.GetTable(ST_PETBATTLES)
	Soundtrack.Events.GetTable(ST_DANCE)
	Soundtrack.Events.GetTable(ST_MISC)
	Soundtrack.Events.GetTable(ST_PLAYLISTS)

	-- Sort all events
	Soundtrack.SortAllEvents()

	-- Check that all tables were sorted
	IsTrue(Soundtrack_FlatEvents[ST_BATTLE] ~= nil, "Battle events sorted")
	IsTrue(Soundtrack_FlatEvents[ST_ZONE] ~= nil, "Zone events sorted")
	IsTrue(#Soundtrack_FlatEvents[ST_BATTLE] > 0, "Battle has events")
	IsTrue(#Soundtrack_FlatEvents[ST_ZONE] > 0, "Zone has events")
end

function Tests:SortEvents_CaseInsensitiveFilter_MatchesRegardlessOfCase()
	-- Setup events
	local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
	eventTable["BOSS_FIGHT"] = { tracks = {} }
	eventTable["trash_mob"] = { tracks = {} }

	-- Set lowercase filter for uppercase event
	Soundtrack.eventFilter = "boss"

	-- Sort events
	Soundtrack.SortEvents(ST_BATTLE)

	-- Should match despite case difference
	AreEqual(1, #Soundtrack_FlatEvents[ST_BATTLE])
	AreEqual("BOSS_FIGHT", Soundtrack_FlatEvents[ST_BATTLE][1].tag)

	Soundtrack.eventFilter = nil
end

function Tests:SortTracks_CallsRefreshTracks_UpdatesUI()
	-- Setup tracks
	Soundtrack_Tracks = {
		["track.mp3"] = { title = "Song", artist = "Artist", album = "Album", filePath = "track.mp3" },
	}

	-- Mock RefreshTracks to track calls
	local refreshCalled = false
	Replace(SoundtrackUI, "RefreshTracks", function()
		refreshCalled = true
	end)

	-- Sort tracks
	Soundtrack.SortTracks("filePath")

	-- Check that UI refresh was called
	IsTrue(refreshCalled, "RefreshTracks was called")
end

function Tests:SortEvents_CallsUpdateEventsUI_UpdatesUI()
	-- Setup events
	local eventTable = Soundtrack.Events.GetTable(ST_BATTLE)
	eventTable["Event"] = { tracks = {} }

	-- Mock UpdateEventsUI to track calls
	local updateCalled = false
	Replace(SoundtrackUI, "UpdateEventsUI", function()
		updateCalled = true
	end)

	-- Sort events
	Soundtrack.SortEvents(ST_BATTLE)

	-- Check that UI update was called
	IsTrue(updateCalled, "UpdateEventsUI was called")
end
