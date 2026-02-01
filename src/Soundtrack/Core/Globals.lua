Soundtrack = {
	RegisteredEvents = {},
	Settings = {},
}

SoundtrackUI = {}

Soundtrack_EventTabs = {
	ST_BATTLE,
	ST_ZONE,
	ST_BOSS_ZONES,
	ST_PETBATTLES,
	ST_DANCE,
	ST_MISC,
	ST_PLAYLISTS,
}

Soundtrack_BattleEvents = {}
Soundtrack_MiscEvents = {}
Soundtrack_FlatEvents = {} -- Event nodes, but with collapsed events removed. used to match scrolling lists
Soundtrack_EventNodes = {} -- Like sorted events, except its in a tree structure
Soundtrack_Profiles = {}
Soundtrack_Tracks = nil
Soundtrack_SortedTracks = {}
Soundtrack_Tooltip = nil
