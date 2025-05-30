--------------------------------------------------
-- localization.lua (English)
--------------------------------------------------

local function RegisterGeneralStrings()
	SOUNDTRACK_DANCE_EMOTES = {
		" burst into dance.",
		" dance with ",
		" bursts into dance.",
		" dances with ",
	}

	SOUNDTRACK_TITLE = "Soundtrack"
	BINDING_HEADER_SOUNDTRACK = SOUNDTRACK_TITLE

	-- Main Frame
	SOUNDTRACK_CLOSE = "Close Window"
	SOUNDTRACK_CLOSE_TIP =
		"Closes Soundtrack's main window. If a track was being previewed it will be stopped, and the active events are resumed."
	--"If a playlist was started, it will continue to play."   -- Currently not functioning.

	SOUNDTRACK_TRACK_FILTER = "Track Filter"
	SOUNDTRACK_TRACK_FILTER_TIP =
		"Allows filtering of the tracks. The filter is compared against the track file names, paths, title, artist and album name. Clear the box to show the full list of tracks again."

	SOUNDTRACK_EVENT_FILTER = "Event Filter"
	SOUNDTRACK_EVENT_FILTER_TIP =
		"Allows filtering of the events. The filter is compared against the event name. Clear the box to show the full list of events again."

	SOUNDTRACK_EVENT_SETTINGS = "Event Settings"
	SOUNDTRACK_EVENT_SETTINGS_TIP =
		"Allows editing of the selected event's settings such as its name, and playback behavior."

	SOUNDTRACK_ALL = "All Tracks"
	SOUNDTRACK_ALL_TIP =
		"Adds all available tracks to this event's assigned tracks. Useful if you want to create a playlist or other event which will play any of your songs."

	SOUNDTRACK_CLEAR = "Clear Tracks"
	SOUNDTRACK_CLEAR_TIP = "Removes all assigned tracks from this event's tracks."

	SOUNDTRACK_DOWN = "Move Track Down"
	SOUNDTRACK_DOWN_TIP =
		"Moves the selected assigned track down in the list. This allows you to set a specific order to your event's tracks."

	SOUNDTRACK_UP = "Move Track Up"
	SOUNDTRACK_UP_TIP =
		"Moves the selected assigned track up in the list. This allows you to set a specific order to your event's tracks."

	SOUNDTRACK_NAME = "Event Name"
	SOUNDTRACK_NAME_TIP = "This is the name of the selected event. You can rename your event. Press Enter to confirm."

	SOUNDTRACK_RANDOM = "Shuffle"
	SOUNDTRACK_RANDOM_TIP = "Toggles shuffle for the selected event."

	SOUNDTRACK_SOUND_EFFECT = "Sound Effect"
	SOUNDTRACK_SOUND_EFFECT_TIP =
		"Plays the music track once as a sound effect, without stopping other music. This is useful for short sound-effects like victory music or a quest complete sound."

	SOUNDTRACK_CONTINUOUS = "Repeat"
	SOUNDTRACK_CONTINUOUS_TIP =
		"Plays the tracks continuously in a loop. If you turn this off, the track is played once, and then is removed from the stack."

	SOUNDTRACK_REMOVE_TRACK = "Remove Track"

	-- Button Names
	SOUNDTRACK_ADD_BUTTON = "Add"
	SOUNDTRACK_REMOVE_BUTTON = "Remove"
	SOUNDTRACK_COLLAPSE_ALL_BUTTON = "Collapse All"
	SOUNDTRACK_EXPAND_ALL_BUTTON = "Expand All"
	SOUNDTRACK_EDIT_BUTTON = "Edit"
	SOUNDTRACK_RENAME_BUTTON = "Rename"

	-- Minimap
	SOUNDTRACK_MINIMAP =
		"Assign your own music to various events in the game or play your own playlists. You can drag this icon around the minimap."

	-- Battle Tab
	SOUNDTRACK_UNKNOWN_BATTLE = "Unknown Battle"
	SOUNDTRACK_NORMAL_MOB = "Normal Mob"
	SOUNDTRACK_ELITE_MOB = "Elite Mob"
	-- Added 1/22/2010
	SOUNDTRACK_CRITTER = "Critter"

	SOUNDTRACK_RARE = "Rare"
	SOUNDTRACK_BOSS_BATTLE = "Boss Battle"
	SOUNDTRACK_BOSS_LOW_HEALTH = "Boss Low Health"
	SOUNDTRACK_LOW_HEALTH = "Low Health"
	SOUNDTRACK_WORLD_BOSS_BATTLE = "World Boss Battle"
	SOUNDTRACK_WORLD_BOSS_LOW_HEALTH = "World Boss Low Health"
	SOUNDTRACK_PVP_BATTLE = "PvP Battle"

	SOUNDTRACK_REMOVE_BATTLE = "Remove Battle Event"
	SOUNDTRACK_REMOVE_BATTLE_TIP = "Removes the selected battle event."

	-- Bosses Tab
	SOUNDTRACK_ADD_TARGET_PARTY_BUTTON = "Add Party"
	SOUNDTRACK_ADD_TARGET_RAID_BUTTON = "Add Raid"
	SOUNDTRACK_ADD_TARGET_PARTY = "Add Target as Party Boss"
	SOUNDTRACK_ADD_TARGET_RAID = "Add Target as Raid Boss"
	SOUNDTRACK_ADD_TARGET_TIP =
		"Add the currently targeted mob to the list, or enter the name of a mob to add to the list."
	SOUNDTRACK_ADD_BOSS_TIP = "Add named mob:"

	SOUNDTRACK_REMOVE_TARGET = "Remove Target"
	SOUNDTRACK_REMOVE_TARGET_TIP = "Removes the selected mob from the list."

	-- Zones Tab
	SOUNDTRACK_ADD_ZONE = "Add Zone"
	SOUNDTRACK_ADD_ZONE_TIP =
		"Adds your current locations to the zone list so that you can assign tracks to them. This can be done automatically with the 'Automatically Add New Zones' option."

	SOUNDTRACK_REMOVE_ZONE = "Remove Zone"
	SOUNDTRACK_REMOVE_ZONE_TIP = "Removes the selected zone."

	SOUNDTRACK_COLLAPSE_ALL_ZONE_TIP = "Collapses all collapsable zone nodes."
	SOUNDTRACK_EXPAND_ALL_ZONE_TIP = "Expands all expandable zone nodes."

	SOUNDTRACK_INSTANCES = "Instances"
	SOUNDTRACK_PVP = "PvP"
	SOUNDTRACK_UNCATEGORIZED = "Uncategorized"
	SOUNDTRACK_UNKNOWN = "Unknown"

	-- Pet Battles Tab
	SOUNDTRACK_WILD_BATTLE = "Wild Battle"
	SOUNDTRACK_NPC_BATTLE = "NPC Battle"
	SOUNDTRACK_PVP_MATCHMAKING = "PVP Random Match"
	SOUNDTRACK_PVP_DUEL = "PVP Duel"
	SOUNDTRACK_PETBATTLES_VICTORY = "Victory"
	SOUNDTRACK_PETBATTLES_NAMEDNPCS = "Named NPCs"
	SOUNDTRACK_PETBATTLES_PLAYERS = "Players"
	SOUNDTRACK_PETBATTLES_ADD_TARGET = "Add Target"
	SOUNDTRACK_PETBATTLES_ADD_TARGET_TIP = "Adds the currently selected NPC or player to the list."
	SOUNDTRACK_PETBATTLES_REMOVE_TARGET = "Remove Target"
	SOUNDTRACK_PETBATTLES_REMOVE_TARGET_TIP = "Removes the currently selected event from the list."

	-- Misc Tab
	SOUNDTRACK_MYTHIC_PLUS_EVENTS = "Mythic Plus"
	SOUNDTRACK_MYTHIC_PLUS_START = SOUNDTRACK_MYTHIC_PLUS_EVENTS .. "/Key Started"
	SOUNDTRACK_MYTHIC_PLUS_COMPLETE_TIMED = SOUNDTRACK_MYTHIC_PLUS_EVENTS .. "/Key Timed"
	SOUNDTRACK_MYTHIC_PLUS_COMPLETE_OVER_TIME = SOUNDTRACK_MYTHIC_PLUS_EVENTS .. "/Key Over Time"
	SOUNDTRACK_STATUS_EVENTS = "Status"
	SOUNDTRACK_DEATH = "Status/Death"
	SOUNDTRACK_DRAGONRIDING_RACE = "Status/Dragonriding Race"
	SOUNDTRACK_FLIGHT = "Status/Flight Path"
	SOUNDTRACK_GHOST = "Status/Ghost"
	SOUNDTRACK_MOUNT_FLYING = "Status/Mount, Flying"
	SOUNDTRACK_MOUNT_GROUND = "Status/Mount, Ground"
	SOUNDTRACK_STEALTHED = "Status/Stealthed"
	SOUNDTRACK_SWIMMING = "Status/Swimming"
	-- Added 1/17/2011
	SOUNDTRACK_CINEMATIC = "Status/Cinematic"

	SOUNDTRACK_GROUP_EVENTS = "Group & Self"
	SOUNDTRACK_ACHIEVEMENT = "Group & Self/Achievement"
	SOUNDTRACK_JOIN_PARTY = "Group & Self/Join Party"
	SOUNDTRACK_JOIN_RAID = "Group & Self/Join Raid"
	SOUNDTRACK_JUMP = "Group & Self/Jump"
	SOUNDTRACK_LEVEL_UP = "Group & Self/Level Up"
	SOUNDTRACK_LFG_COMPLETE = "Group & Self/LFG Complete"
	SOUNDTRACK_QUEST_COMPLETE = "Group & Self/Quest Complete"
	SOUNDTRACK_RESTING = "Group & Self/Resting"
	SOUNDTRACK_DUEL_REQUESTED = "Group & Self/Duel Requested"

	-- Item Get
	SOUNDTRACK_ITEM_GET = "Item Get"
	SOUNDTRACK_ITEM_GET_JUNK = SOUNDTRACK_ITEM_GET .. "/Junk"
	SOUNDTRACK_ITEM_GET_COMMON = SOUNDTRACK_ITEM_GET .. "/Common"
	SOUNDTRACK_ITEM_GET_UNCOMMON = SOUNDTRACK_ITEM_GET .. "/Uncommon"
	SOUNDTRACK_ITEM_GET_RARE = SOUNDTRACK_ITEM_GET .. "/Rare"
	SOUNDTRACK_ITEM_GET_EPIC = SOUNDTRACK_ITEM_GET .. "/Epic"
	SOUNDTRACK_ITEM_GET_LEGENDARY = SOUNDTRACK_ITEM_GET .. "/Legendary"

	SOUNDTRACK_NPC_EVENTS = "NPC"
	SOUNDTRACK_AUCTION_HOUSE = "NPC/Auction House"
	SOUNDTRACK_BANK = "NPC/Bank"
	SOUNDTRACK_MERCHANT = "NPC/Merchant"
	-- Added 1/17/2011
	SOUNDTRACK_BARBERSHOP = "NPC/Barbershop"
	SOUNDTRACK_NPC_EMOTE = "NPC/Emote"
	SOUNDTRACK_NPC_SAY = "NPC/Say"
	SOUNDTRACK_NPC_WHISPER = "NPC/Whisper"
	SOUNDTRACK_NPC_YELL = "NPC/Yell"
	--Added 02/16/2015
	SOUNDTRACK_FLIGHTMASTER = "NPC/FlightMaster"
	SOUNDTRACK_TRAINER = "NPC/Trainer"

	SOUNDTRACK_COMBAT_EVENTS = "Combat"
	SOUNDTRACK_RANGE_CRIT = "Combat/Range Crit"
	SOUNDTRACK_RANGE_HIT = "Combat/Range"
	SOUNDTRACK_HEAL_CRIT = "Combat/Spell Heal Crit"
	SOUNDTRACK_HEAL_HIT = "Combat/Spell Heal"
	SOUNDTRACK_HOT_CRIT = "Combat/Spell HoT Crit"
	SOUNDTRACK_HOT_HIT = "Combat/Spell HoT"
	SOUNDTRACK_SPELL_CRIT = "Combat/Spell Damage Crit"
	SOUNDTRACK_SPELL_HIT = "Combat/Spell Damage"
	SOUNDTRACK_DOT_CRIT = "Combat/Spell DoT Crit"
	SOUNDTRACK_DOT_HIT = "Combat/Spell DoT"
	SOUNDTRACK_SWING_CRIT = "Combat/Swing Crit"
	SOUNDTRACK_SWING_HIT = "Combat/Swing"
	SOUNDTRACK_VICTORY = "Combat/Victory"
	SOUNDTRACK_VICTORY_BOSS = "Combat/Victory, Boss"

	SOUNDTRACK_REMOVE_MISC = "Remove Misc. Event"
	SOUNDTRACK_REMOVE_MISC_TIP = "Removes the selected misc. event."

	-- Custom Event Tab
	SOUNDTRACK_ADD_CUSTOM = "Add Custom Event"
	SOUNDTRACK_ADD_CUSTOM_TIP =
		"Creates a new custom event. Custom events are events that you can define yourself through a variety of methods including scripting."

	SOUNDTRACK_EDIT_CUSTOM = "Edit Custom Event"
	SOUNDTRACK_EDIT_CUSTOM_TIP =
		"Switches to the custom event editing interface so you can adjust the selected custom event."

	SOUNDTRACK_REMOVE_CUSTOM = "Remove Custom Event"
	SOUNDTRACK_REMOVE_CUSTOM_TIP = "Removes the selected custom event."

	SOUNDTRACK_RANDOM = "Shuffle"
	SOUNDTRACK_SOUND_EFFECT = "Sound Effect"
	SOUNDTRACK_CUSTOM_CONTINUOUS = "Continuous"
	SOUNDTRACK_CUSTOM_CONTINUOUS_TIP =
		"Determines if this event will loop or play once. When an event plays continuously, it can be stopped by its own script, or through another event replacing it."

	SOUNDTRACK_EVENT_TYPE = "Event Type"
	SOUNDTRACK_EVENT_TYPE_TIP = "The type of event affects how the custom event is edited."

	SOUNDTRACK_ENTER_CUSTOM_NAME = "Enter Custom Event Name:"

	-- Playlists Tab
	SOUNDTRACK_ADD_PLAYLIST = "Add Playlist"
	SOUNDTRACK_ADD_PLAYLIST_TIP =
		"Adds a new playlist. Playlists override all other events, so they never get interrupted by other events."

	SOUNDTRACK_REMOVE_PLAYLIST = "Remove Playlist"
	SOUNDTRACK_REMOVE_PLAYLIST_TIP = "Removes the selected playlist."

	SOUNDTRACK_RENAME_PLAYLIST = "Rename Playlist"
	SOUNDTRACK_RENAME_PLAYLIST_TIP = "Rename the selected playlist."

	SOUNDTRACK_ENTER_PLAYLIST_NAME = "Enter Playlist Name:"

	-- Playback Controls
	SOUNDTRACK_PREVIOUS = "Previous Track"
	SOUNDTRACK_PREVIOUS_TIP = "Skips to the previous track in this event."

	SOUNDTRACK_PLAY = "Play"
	SOUNDTRACK_PLAY_TIP = "Click to resume this event."

	SOUNDTRACK_PAUSE = "Pause"
	SOUNDTRACK_PAUSE_TIP = "Click to pause this event."

	SOUNDTRACK_NEXT = "Next Track"
	SOUNDTRACK_NEXT_TIP = "Skips to the next track in this event."

	SOUNDTRACK_STOP = "Stop"
	SOUNDTRACK_STOP_TIP = "Stops the event."

	SOUNDTRACK_INFO = "Info"
	SOUNDTRACK_INFO_TIP = "Gives information on the currently playing track."

	-- Options Tab
	SOUNDTRACK_SHOW_MINIMAP_BUTTON = "Show Minimap Button"
	SOUNDTRACK_SHOW_MINIMAP_BUTTON_TIP =
		"Displays the Soundtrack icon on the minimap. The icon can be repositioned by dragging it around the minimap. If you turn off this button, you can open Soundtrack's main window with a keybinding or with the /soundtrack command."

	SOUNDTRACK_SHOW_PLAYBACK_CONTROLS = "Playback Controls"
	SOUNDTRACK_SHOW_PLAYBACK_CONTROLS_TIP =
		"Displays a mini toolbar with a previous, pause, and next button to control the playback. The controls can be repositioned by dragging the name area."

	SOUNDTRACK_LOCK_PLAYBACK_CONTROLS = "Lock Playback Controls"
	SOUNDTRACK_LOCK_PLAYBACK_CONTROLS_TIP = "Makes the Playback Controls unmovable."

	SOUNDTRACK_HIDE_PLAYBACK_BUTTONS = "Hide Playback Buttons"
	SOUNDTRACK_HIDE_PLAYBACK_BUTTONS_TIP = "Hides the buttons on the Playback Controls"

	SOUNDTRACK_BUTTONS_PLAYBACK_CONTROLS = "Playback Controls Buttons"
	SOUNDTRACK_BUTTONS_PLAYBACK_CONTROLS_TIP =
		"Change location of the Playback Controls buttons around Playback Controls frame."

	SOUNDTRACK_SHOW_TRACK_INFO = "Show Track Information"
	SOUNDTRACK_SHOW_TRACK_INFO_TIP =
		"When track changes, the track's title, album and artist are shortly displayed on the screen. The track information frame can be repositioned by dragging it when it appears."

	SOUNDTRACK_SHOW_DEFAULT_MUSIC = "Show Default Music"
	SOUNDTRACK_SHOW_DEFAULT_MUSIC_TIP =
		"Adds all the available music tracks included with the game to your music library."

	SOUNDTRACK_LOCK_NOW_PLAYING = "Lock Track Info. Frame"
	SOUNDTRACK_LOCK_NOW_PLAYING_TIP = "Locks the track information frame so it cannot be moved or clicked."

	SOUNDTRACK_SHOW_DEBUG = "Output Debug Information"
	SOUNDTRACK_SHOW_DEBUG_TIP =
		"Outputs verbose debug information to the chat frame. Output is sent to default chat frame or the frame named 'Soundtrack' if available."

	SOUNDTRACK_SHOW_EVENT_STACK = "Event Stack"
	SOUNDTRACK_SHOW_EVENT_STACK_TIP =
		"Displays the currently active events in the stack, below the minimap (useful for debugging)."

	SOUNDTRACK_AUTO_ADD_ZONES = "Automatically Add Zones"
	SOUNDTRACK_AUTO_ADD_ZONES_TIP =
		"Adds new zones to the list of zone events as you travel. Zones are added hierarchically at all levels (e.g. continents, major areas, cities, towns, inns, etc."

	SOUNDTRACK_ESCALATE_BATTLE = "Escalate Battle Music"
	SOUNDTRACK_ESCALATE_BATTLE_TIP =
		"If during a battle a stronger enemy is detected, allows the music to switch to the higher battle music."

	SOUNDTRACK_YOUR_ENEMY_LEVEL = "Your Enemy Level Only"
	SOUNDTRACK_YOUR_ENEMY_LEVEL_TIP = "Only use you and your pet's target to calculate current enemy level."

	SOUNDTRACK_BATTLE_CD = "Battle Cooldown"
	SOUNDTRACK_BATTLE_CD_TIP = "The time it takes for battle music to stop when disengaged from battle."

	SOUNDTRACK_LOW_HEALTH_PERCENT = "Boss Low Health %"
	SOUNDTRACK_LOW_HEALTH_PERCENT_TIP =
		"The amount of health when Boss and World Boss events switch to Boss Low Health."

	SOUNDTRACK_LOOP_MUSIC = "Loop Music"
	SOUNDTRACK_LOOP_MUSIC_TIP =
		"Enable to continuously play background music. This is the same setting exposed in the default Sound options."

	SOUNDTRACK_MAX_SILENCE = "Maximum Silence"
	SOUNDTRACK_MAX_SILENCE_TIP =
		"The maximum amount of silence to insert between tracks for zone music. Increase this value if you wish the music would take a break once in a while."

	SOUNDTRACK_ENABLE_MUSIC = "Enable Music"
	SOUNDTRACK_ENABLE_MUSIC_TIP =
		"Master toggle to turn off all music. Use this to temporarily disable all of Soundtrack's music."

	SOUNDTRACK_ENABLE_ZONE_MUSIC = "Enable Zone Music"
	SOUNDTRACK_ENABLE_ZONE_MUSIC_TIP = "Enable zone music. Use this to temporarily stop all zone music from playing."

	SOUNDTRACK_ENABLE_BATTLE_MUSIC = "Enable Battle Music"
	SOUNDTRACK_ENABLE_BATTLE_MUSIC_TIP = "Enable battle music. Use this to temporarily stop all battle music."

	SOUNDTRACK_ENABLE_MISC_MUSIC = "Enable Misc Music"
	SOUNDTRACK_ENABLE_MISC_MUSIC_TIP = "Enable misc music. Use this to temporarily turn off all misc music."

	SOUNDTRACK_ENABLE_CUSTOM_MUSIC = "Enable Custom Music"
	SOUNDTRACK_ENABLE_CUSTOM_MUSIC_TIP = "Enable custom music. Use this to temporarily turn off all custom music."

	-- Other
	SOUNDTRACK_NO_TRACKS_PLAYING = "No tracks playing"
	SOUNDTRACK_NO_EVENT_PLAYING = "No event playing"
	SOUNDTRACK_NOW_PLAYING = "Now playing"
	SOUNDTRACK_MINIMAP_BUTTON_HIDDEN =
		"The minimap button was hidden. You can access Soundtrack's UI by using the /soundtrack command."

	SOUNDTRACK_REMOVE_QUESTION = "Do you want to remove this?"
	SOUNDTRACK_PURGE_EVENTS_QUESTION =
		"MyTracks.lua changed.\n\nWARNING!!!!! THIS WILL REMOVE TRACK ASSIGNMENTS FOR TRACKS YOU REMOVED FROM YOUR LIBRARY!!! YOU PROBABLY DON'T WANT TO DO THIS IF ALL YOUR TRACKS ARE MISSING FORM THE LIST. \n\nPurge obsolete tracks?"
	SOUNDTRACK_GEN_LIBRARY =
		"Exit the game, run GenerateMyLibrary, and reenter game to create MyTracks.lua for Soundtrack to work properly."
	SOUNDTRACK_NO_MYTRACKS = "MyTracks.lua not found.\n\nRun Soundtrack without MyTracks.lua?"
	SOUNDTRACK_ERROR_LOADING =
		"Cannot load MyTracks.lua. You probably forgot to run GenerateMyLibrary. Read the setup instructions for more details."

	SOUNDTRACK_COPY_BUTTON = "Copy"
	SOUNDTRACK_COPY_TRACKS = "Copy Tracks"
	SOUNDTRACK_COPY_TRACKS_TIP = "Copy the tracks from the selected event."

	SOUNDTRACK_PASTE_BUTTON = "Paste"
	SOUNDTRACK_PASTE_TRACKS = "Paste Copied Tracks"
	SOUNDTRACK_PASTE_TRACKS_TIP = "Paste the tracks that you copied to the selected event."

	SOUNDTRACK_CLEAR_BUTTON = "Clear"
	SOUNDTRACK_CLEAR_TRACKS = "Clear Copied Tracks"
	SOUNDTRACK_CLEAR_TRACKS_TIP = "Clear the tracks that you copied."

	SOUNDTRACK_CLEAR_SELECTED_EVENT_QUESTION = "Are you sure you want to clear the selected event?"
end

function LoadEnglish()
	if not LOCALIZATION_LOADED then
		LOCALIZATION_LOADED = true

		RegisterGeneralStrings()
		SoundtrackLocalization.RegisterDruidStrings("Druid", "Change Form")
		SoundtrackLocalization.RegisterHunterStrings("Hunter")
		SoundtrackLocalization.RegisterDeathKnightStrings("Death Knight", "Change Presence")
		SoundtrackLocalization.RegisterEvokerStrings("Evoker")
		SoundtrackLocalization.RegisterPaladinStrings("Paladin", "Change Aura")
		SoundtrackLocalization.RegisterPriestStrings("Priest", "Change Form")
		SoundtrackLocalization.RegisterRogueStrings("Rogue", "Enter Stealth")
		SoundtrackLocalization.RegisterShamanStrings("Shaman", "Change Form")
		SoundtrackLocalization.RegisterWarriorStrings("Warrior", "Change Stance")
		SoundtrackLocalization.RegisterMageStrings("Mage")
		SoundtrackLocalization.RegisterMonkStrings("Monk")
		SoundtrackLocalization.RegisterWarlockStrings("Warlock")
	end
end

LoadEnglish()
