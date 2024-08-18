# Soundtrack

Soundtrack is a World of Warcraft addon that allows you to assign music and sound effects to nearly any event in the game.

## Disclaimer 

IMPORTANT - Always back up your SoundtrackMusic folder and MyTracks.lua before upgrading. Some addon clients will delete and re-extract the directories which will wipe any previous songs you had.

## Introduction

Ever get tired of World of Warcraft's default music? Wish you could inject a little bit of aural life into your game, but on your own terms? Soundtrack is the mod for you! Soundtrack allows you to assign any music you own from your own personal music library to almost any event in the game, including death, getting on your mount, leveling up, entering stealth, and various forms of combat that can distinguish between world mobs, PvP, boss battles, and more! When the event occurs, Soundtrack will play the music you have assigned to that event, almost as if the music were a part of the game itself!


## Features

- Play your own mp3s inside the game.
- Assign music to entire zones or specific sub zones. The default music still plays in zones for which you do not assign music.
- Assign music when battling various levels of mobs, specific named monsters, or elite mobs. Set a different track to trigger at low enemy health for those intense final moments!
- Assign music to your pet battles based on battle type, continent, and enemy player or NPC name.
- A plethora of events that you can assign music: Victory, Flight, Dance, Stealth, Swimming, Level Up, etc.
- Expose the full World of Warcraft score in your library to assign Blizzard's music to your own events.
- Can be used as a standard media player. You can create playlists and play them using mini floating playback controls.
- Interface to assign music to events. See all your tracks, sortable or filterable by track title, album or artist names.
- Custom events allows you to create your own events through lua scripting. Only for very advanced users with scripting knowledge.

## Installation

Soundtrack requires extra installation steps to gather your music information, so please follow these steps:


1. Download and Install: Curse Client or manual install, Soundtrack must be extracted in World of Warcraft/Interface/Addons.
2. Get some MP3s: You can copy your mp3s to Interface\Addons\SoundtrackMusic. You can put your mp3s into subdirectories or subfolders for organization.
3. Generate your library. Follow the instructions in the Interface\Addons\Soundtrack\README.txt.  Keep MyTracks.lua in the SoundtrackMusic folder. You used to have to move it back to Soundtrack DO NOT DO THIS.
4. Play World of Warcraft: Start up World of Warcraft. When you go to the character screen, open up the Addons and make sure that Soundtrack is checked.

## Known Issues

- Zone and battle music sometimes gets interrupted in instances or battlegrounds. It will come back on once the number of sound effects drops.
- Dance music does not stop when your character stops dancing. This is because there is currently no way to detect that you have stopped dancing, so the track stops when it reaches its end.

## Feature Requests and Bug Reports

Please leave a comment or leave a ticket on CurseForge.


## Frequently Asked Questions

- Why does my music cut off in the middle of battles or a lot of AOE? World of Warcraft has a limited number of sound channels available for it to use. When all the sound channels fill up, WoW will cut off the music being played by PlayMusic(), which is Soundtrack's music. When the number of sound effects drop, the music will play normally again.
- Why does my playlist stop when I close the main window? If you select a playlist from the Playlist tab in the main window, when you close it, the playlist will continue to play. If you leave the tab, the playlist will stop.
- How do I find out the icon name for a buff or debuff? If the buff or debuff is on you, you can use the following macros. They will tell you the name and icon texture of every buff (or debuff) on your character. For a buff, copy this macro: /script for i=1,40 do name,_,icon = UnitBuff("player", i) if icon then print(name," = ",icon) end end For a debuff, copy this macro: /script for i=1,40 do name,_,icon = UnitDebuff("player", i) if icon then print(name," = ",icon) end end Other sites, such as Wowhead, have the icon name. If you get the icon texture name from there, add "Interface\Icons\" before it and it should work. Capitalization does not matter.
- What types of music files are supported? MP3s and, if you run GenerateMyLibraryWindows.jar, Ogg audio files (.ogg). Other formats are not supported by Blizzard. Files with Japanese or other non-ASCII characters in their names can cause problems, so I suggest renaming them. There are a lot of programs to convert various music formats to mp3. I personally use iTunes for that. In iTunes, Edit->Preferences, select the Importing tab, and make sure you Import using: MP3 Encoder. Then you'll be able to convert any tracks to an mp3 file.
- Why do I need to copy my music to the SoundtrackMusic folder? The only files that can be played by WoW are files placed under the World of Warcraft folder when the game is started.
- How do I transfer my assignments to another machine?

    1. Exit WoW on the target machine.
    2. Copy your Interface/Addons/SoundtrackMusic folder to the target machine. If you only copy partial music files, it will still work, but the events that are missing tracks will be fixed automatically and you will lose the track assignments (since the tracks don't exist).
    3. Regenerate the library on the target machine. You do this the usual way, by running GenerateMyLibrary.py. You can also copy MyTracks.lua directly if you want to skip this step.
    4. Copy the settings. All of Soundtrack settings are stored in World of Warcraft\WTF\Account\<UserName>\SavedVariables\Soundtrack.lua. So copy this file to the same location on the target machine.
    5. Start WoW on the target machine!
How do I transfer my assignments to another machine?
Exit WoW on the target machine.Copy your Interface/Addons/SoundtrackMusic folder to the target machine. If you only copy partial music files, it will still work, but the events that are missing tracks will be fixed automatically and you will lose the track assignments (since the tracks dont exist).
Regenerate the library on the target machine. You do this the usual way, by running GenerateMyLibrary.py. You can also copy MyTracks.lua directly if you want to skip this step.
Copy the settings. All of Soundtrack settings are stored in World of Warcraft\WTF\Account\<UserName>\SavedVariables\Soundtrack.lua. So copy this file to the same location on the target machine.
Start WoW on the target machine!