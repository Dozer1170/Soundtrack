if not Tests then
	return
end

local Tests = Tests("OptionsTabUI", "PLAYER_ENTERING_WORLD")

-- Toggle setting helper
local function GetSetting(key)
	return SoundtrackAddon.db.profile.settings[key]
end

-- ToggleShowPlaybackControls Tests

function Tests:ToggleShowPlaybackControls_TogglesSettingToFalse()
	SoundtrackAddon.db.profile.settings.ShowPlaybackControls = true
	Replace(_G, "SoundtrackFrame_RefreshPlaybackControls", function() end)

	Soundtrack.OptionsTab.ToggleShowPlaybackControls()

	IsFalse(GetSetting("ShowPlaybackControls"), "Setting toggled to false")
end

function Tests:ToggleShowPlaybackControls_TogglesSettingToTrue()
	SoundtrackAddon.db.profile.settings.ShowPlaybackControls = false
	Replace(_G, "SoundtrackFrame_RefreshPlaybackControls", function() end)

	Soundtrack.OptionsTab.ToggleShowPlaybackControls()

	IsTrue(GetSetting("ShowPlaybackControls"), "Setting toggled to true")
end

function Tests:ToggleShowPlaybackControls_CallsRefreshPlaybackControls()
	local called = false
	Replace(_G, "SoundtrackFrame_RefreshPlaybackControls", function() called = true end)

	Soundtrack.OptionsTab.ToggleShowPlaybackControls()

	IsTrue(called, "SoundtrackFrame_RefreshPlaybackControls called")
end

-- ToggleDebugMode Tests

function Tests:ToggleDebugMode_TogglesSettingToTrue()
	SoundtrackAddon.db.profile.settings.Debug = false

	Soundtrack.OptionsTab.ToggleDebugMode()

	IsTrue(GetSetting("Debug"), "Debug toggled to true")
end

function Tests:ToggleDebugMode_TogglesSettingToFalse()
	SoundtrackAddon.db.profile.settings.Debug = true

	Soundtrack.OptionsTab.ToggleDebugMode()

	IsFalse(GetSetting("Debug"), "Debug toggled to false")
end

-- ToggleShowTrackInformation Tests

function Tests:ToggleShowTrackInformation_TogglesSettingToTrue()
	SoundtrackAddon.db.profile.settings.ShowTrackInformation = false

	Soundtrack.OptionsTab.ToggleShowTrackInformation()

	IsTrue(GetSetting("ShowTrackInformation"), "ShowTrackInformation toggled to true")
end

function Tests:ToggleShowTrackInformation_TogglesSettingToFalse()
	SoundtrackAddon.db.profile.settings.ShowTrackInformation = true

	Soundtrack.OptionsTab.ToggleShowTrackInformation()

	IsFalse(GetSetting("ShowTrackInformation"), "ShowTrackInformation toggled to false")
end

-- ToggleShowEventStack Tests

function Tests:ToggleShowEventStack_TogglesSettingToTrue()
	SoundtrackAddon.db.profile.settings.ShowEventStack = false
	Replace(_G, "SoundtrackFrame_RefreshPlaybackControls", function() end)

	Soundtrack.OptionsTab.ToggleShowEventStack()

	IsTrue(GetSetting("ShowEventStack"), "ShowEventStack toggled to true")
end

function Tests:ToggleShowEventStack_TogglesSettingToFalse()
	SoundtrackAddon.db.profile.settings.ShowEventStack = true
	Replace(_G, "SoundtrackFrame_RefreshPlaybackControls", function() end)

	Soundtrack.OptionsTab.ToggleShowEventStack()

	IsFalse(GetSetting("ShowEventStack"), "ShowEventStack toggled to false")
end

function Tests:ToggleShowEventStack_CallsRefreshPlaybackControls()
	local called = false
	Replace(_G, "SoundtrackFrame_RefreshPlaybackControls", function() called = true end)

	Soundtrack.OptionsTab.ToggleShowEventStack()

	IsTrue(called, "SoundtrackFrame_RefreshPlaybackControls called after toggling event stack")
end

-- ToggleAutoAddZones Tests

function Tests:ToggleAutoAddZones_TogglesSettingToTrue()
	SoundtrackAddon.db.profile.settings.AutoAddZones = false

	Soundtrack.OptionsTab.ToggleAutoAddZones()

	IsTrue(GetSetting("AutoAddZones"), "AutoAddZones toggled to true")
end

function Tests:ToggleAutoAddZones_TogglesSettingToFalse()
	SoundtrackAddon.db.profile.settings.AutoAddZones = true

	Soundtrack.OptionsTab.ToggleAutoAddZones()

	IsFalse(GetSetting("AutoAddZones"), "AutoAddZones toggled to false")
end

-- ToggleAutoEscalateBattleMusic Tests

function Tests:ToggleAutoEscalateBattleMusic_TogglesSettingToTrue()
	SoundtrackAddon.db.profile.settings.EscalateBattleMusic = false

	Soundtrack.OptionsTab.ToggleAutoEscalateBattleMusic()

	IsTrue(GetSetting("EscalateBattleMusic"), "EscalateBattleMusic toggled to true")
end

-- ToggleEnableZoneMusic Tests

function Tests:ToggleEnableZoneMusic_TogglesSettingToFalse()
	SoundtrackAddon.db.profile.settings.EnableZoneMusic = true

	Soundtrack.OptionsTab.ToggleEnableZoneMusic()

	IsFalse(GetSetting("EnableZoneMusic"), "EnableZoneMusic toggled to false")
end

-- ToggleEnableBattleMusic Tests

function Tests:ToggleEnableBattleMusic_TogglesSettingToFalse()
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	Soundtrack.OptionsTab.ToggleEnableBattleMusic()

	IsFalse(GetSetting("EnableBattleMusic"), "EnableBattleMusic toggled to false")
end

-- ToggleEnableMiscMusic Tests

function Tests:ToggleEnableMiscMusic_TogglesSettingToFalse()
	SoundtrackAddon.db.profile.settings.EnableMiscMusic = true

	Soundtrack.OptionsTab.ToggleEnableMiscMusic()

	IsFalse(GetSetting("EnableMiscMusic"), "EnableMiscMusic toggled to false")
end

-- ToggleLockNowPlayingFrame Tests

function Tests:ToggleLockNowPlayingFrame_TogglesSettingToTrue()
	SoundtrackAddon.db.profile.settings.LockNowPlayingFrame = false

	Soundtrack.OptionsTab.ToggleLockNowPlayingFrame()

	IsTrue(GetSetting("LockNowPlayingFrame"), "LockNowPlayingFrame toggled to true")
end

-- ToggleLockPlaybackControls Tests

function Tests:ToggleLockPlaybackControls_TogglesSettingToTrue()
	SoundtrackAddon.db.profile.settings.LockPlaybackControls = false

	Soundtrack.OptionsTab.ToggleLockPlaybackControls()

	IsTrue(GetSetting("LockPlaybackControls"), "LockPlaybackControls toggled to true")
end

-- ToggleHidePlaybackButtons Tests

function Tests:ToggleHidePlaybackButtons_TogglesSettingToTrue()
	SoundtrackAddon.db.profile.settings.HideControlButtons = false
	Replace(_G, "SoundtrackFrame_RefreshPlaybackControls", function() end)

	Soundtrack.OptionsTab.ToggleHidePlaybackButtons()

	IsTrue(GetSetting("HideControlButtons"), "HideControlButtons toggled to true")
end

function Tests:ToggleHidePlaybackButtons_CallsRefreshPlaybackControls()
	local called = false
	Replace(_G, "SoundtrackFrame_RefreshPlaybackControls", function() called = true end)

	Soundtrack.OptionsTab.ToggleHidePlaybackButtons()

	IsTrue(called, "SoundtrackFrame_RefreshPlaybackControls called after toggling hide buttons")
end

-- ToggleFadeTransition Tests

function Tests:ToggleFadeTransition_TogglesSettingToTrue()
	SoundtrackAddon.db.profile.settings.FadeTransition = false

	Soundtrack.OptionsTab.ToggleFadeTransition()

	IsTrue(GetSetting("FadeTransition"), "FadeTransition toggled to true")
end

function Tests:ToggleFadeTransition_TogglesSettingToFalse()
	SoundtrackAddon.db.profile.settings.FadeTransition = true

	Soundtrack.OptionsTab.ToggleFadeTransition()

	IsFalse(GetSetting("FadeTransition"), "FadeTransition toggled to false")
end

-- ToggleMinimapButton Tests

function Tests:ToggleMinimapButton_CallsToggleMinimap()
	local called = false
	Replace(_G, "SoundtrackMinimap_ToggleMinimap", function() called = true end)

	Soundtrack.OptionsTab.ToggleMinimapButton()

	IsTrue(called, "SoundtrackMinimap_ToggleMinimap called")
end

-- ToggleShowDefaultMusic Tests

function Tests:ToggleShowDefaultMusic_TogglesSettingToFalse()
	SoundtrackAddon.db.profile.settings.ShowDefaultMusic = true
	Replace(Soundtrack, "LoadTracks", function() end)

	Soundtrack.OptionsTab.ToggleShowDefaultMusic()

	IsFalse(GetSetting("ShowDefaultMusic"), "ShowDefaultMusic toggled to false")
end

function Tests:ToggleShowDefaultMusic_TogglesSettingToTrue()
	SoundtrackAddon.db.profile.settings.ShowDefaultMusic = false
	Replace(Soundtrack, "LoadTracks", function() end)

	Soundtrack.OptionsTab.ToggleShowDefaultMusic()

	IsTrue(GetSetting("ShowDefaultMusic"), "ShowDefaultMusic toggled to true")
end

function Tests:ToggleShowDefaultMusic_SetsTracksLoadedToFalse()
	Replace(Soundtrack, "LoadTracks", function() end)

	Soundtrack.OptionsTab.ToggleShowDefaultMusic()

	IsFalse(Soundtrack.TracksLoaded, "TracksLoaded set to false")
end

function Tests:ToggleShowDefaultMusic_CallsLoadTracks()
	local called = false
	Replace(Soundtrack, "LoadTracks", function() called = true end)

	Soundtrack.OptionsTab.ToggleShowDefaultMusic()

	IsTrue(called, "Soundtrack.LoadTracks called")
end

-- PlaybackButtonsLocationDropDown Tests

function Tests:PlaybackButtonsLocationDropDown_OnLoad_SetsSelectedLocation()
	SoundtrackAddon.db.profile.settings.PlaybackButtonsPosition = "TOPRIGHT"

	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnLoad()

	AreEqual(3, SoundtrackUI.selectedLocation, "selectedLocation set to index 3 for TOPRIGHT")
end

function Tests:PlaybackButtonsLocationDropDown_OnLoad_DefaultsToOneWhenNoMatch()
	SoundtrackAddon.db.profile.settings.PlaybackButtonsPosition = "UNKNOWN"

	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnLoad()

	AreEqual(1, SoundtrackUI.selectedLocation, "selectedLocation defaults to 1 when no match")
end

function Tests:PlaybackButtonsLocationDropDown_Initialize_AddsLocations()
	local buttonsAdded = 0
	Replace(_G, "UIDropDownMenu_AddButton", function() buttonsAdded = buttonsAdded + 1 end)
	SoundtrackUI.selectedLocation = 1

	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_Initialize()

	AreEqual(6, buttonsAdded, "6 location buttons added")
end

function Tests:PlaybackButtonsLocationDropDown_LoadLocations_AddsButtons()
	local buttonsAdded = 0
	Replace(_G, "UIDropDownMenu_AddButton", function() buttonsAdded = buttonsAdded + 1 end)
	SoundtrackUI.selectedLocation = 999

	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_LoadLocations({ "Left", "Top Left", "Top Right" })

	AreEqual(3, buttonsAdded, "3 buttons added")
end

function Tests:PlaybackButtonsLocationDropDown_LoadLocations_SetsTextForCurrentLocation()
	local textSet = nil
	Replace(_G, "UIDropDownMenu_SetText", function(_, text) textSet = text end)
	Replace(_G, "UIDropDownMenu_AddButton", function() end)
	SoundtrackUI.selectedLocation = 2

	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_LoadLocations({ "Left", "Top Left" })

	AreEqual("Top Left", textSet, "SetText called with current location text")
end

function Tests:PlaybackButtonsLocationDropDown_OnClick_UpdatesSelectedLocation()
	Replace(_G, "UIDropDownMenu_SetSelectedID", function() end)
	Replace(_G, "SoundtrackFrame_RefreshPlaybackControls", function() end)
	SoundtrackUI.selectedLocation = 1

	local self = { GetID = function() return 3 end }
	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnClick(self)

	AreEqual(3, SoundtrackUI.selectedLocation, "selectedLocation updated to 3")
end

function Tests:PlaybackButtonsLocationDropDown_OnClick_SavesPositionSetting()
	Replace(_G, "UIDropDownMenu_SetSelectedID", function() end)
	Replace(_G, "SoundtrackFrame_RefreshPlaybackControls", function() end)

	local self = { GetID = function() return 2 end }
	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnClick(self)

	AreEqual("TOPLEFT", SoundtrackAddon.db.profile.settings.PlaybackButtonsPosition, "Position saved as TOPLEFT")
end

function Tests:PlaybackButtonsLocationDropDown_OnClick_CallsRefreshPlaybackControls()
	local called = false
	Replace(_G, "UIDropDownMenu_SetSelectedID", function() end)
	Replace(_G, "SoundtrackFrame_RefreshPlaybackControls", function() called = true end)

	local self = { GetID = function() return 1 end }
	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnClick(self)

	IsTrue(called, "RefreshPlaybackControls called")
end

-- BattleCooldownDropDown Tests

function Tests:BattleCooldownDropDown_OnLoad_SetsSelectedCooldown()
	SoundtrackAddon.db.profile.settings.BattleCooldown = 5

	Soundtrack.OptionsTab.BattleCooldownDropDown_OnLoad()

	AreEqual(5, SoundtrackUI.selectedCooldown, "selectedCooldown set to index 5 (5 seconds)")
end

function Tests:BattleCooldownDropDown_OnLoad_DefaultsToOneWhenNoMatch()
	SoundtrackAddon.db.profile.settings.BattleCooldown = 999

	Soundtrack.OptionsTab.BattleCooldownDropDown_OnLoad()

	AreEqual(1, SoundtrackUI.selectedCooldown, "selectedCooldown defaults to 1 when no match")
end

function Tests:BattleCooldownDropDown_Initialize_AddsCooldowns()
	local buttonsAdded = 0
	Replace(_G, "UIDropDownMenu_AddButton", function() buttonsAdded = buttonsAdded + 1 end)
	SoundtrackUI.selectedCooldown = 1

	Soundtrack.OptionsTab.BattleCooldownDropDown_Initialize()

	AreEqual(8, buttonsAdded, "8 cooldown buttons added")
end

function Tests:BattleCooldownDropDown_LoadCooldowns_AddsButtons()
	local buttonsAdded = 0
	Replace(_G, "UIDropDownMenu_AddButton", function() buttonsAdded = buttonsAdded + 1 end)
	SoundtrackUI.selectedCooldown = 999

	Soundtrack.OptionsTab.BattleCooldownDropDown_LoadCooldowns({ "No cooldown", "1 second", "2 seconds" })

	AreEqual(3, buttonsAdded, "3 cooldown buttons added")
end

function Tests:BattleCooldownDropDown_LoadCooldowns_SetsTextForCurrentCooldown()
	local textSet = nil
	Replace(_G, "UIDropDownMenu_SetText", function(_, text) textSet = text end)
	Replace(_G, "UIDropDownMenu_AddButton", function() end)
	SoundtrackUI.selectedCooldown = 1

	Soundtrack.OptionsTab.BattleCooldownDropDown_LoadCooldowns({ "No cooldown", "1 second" })

	AreEqual("No cooldown", textSet, "SetText called with current cooldown text")
end

function Tests:BattleCooldownDropDown_OnClick_UpdatesSelectedCooldown()
	Replace(_G, "UIDropDownMenu_SetSelectedID", function() end)

	local self = { GetID = function() return 4 end }
	Soundtrack.OptionsTab.BattleCooldownDropDown_OnClick(self)

	AreEqual(4, SoundtrackUI.selectedCooldown, "selectedCooldown updated to 4")
end

function Tests:BattleCooldownDropDown_OnClick_SavesCooldownSetting()
	Replace(_G, "UIDropDownMenu_SetSelectedID", function() end)

	local self = { GetID = function() return 2 end }
	Soundtrack.OptionsTab.BattleCooldownDropDown_OnClick(self)

	AreEqual(1, SoundtrackAddon.db.profile.settings.BattleCooldown, "BattleCooldown saved as 1 second")
end

-- SilenceDropDown Tests

function Tests:SilenceDropDown_OnLoad_SetsSelectedSilence()
	SoundtrackAddon.db.profile.settings.Silence = 30

	Soundtrack.OptionsTab.SilenceDropDown_OnLoad()

	AreEqual(5, SoundtrackUI.selectedSilence, "selectedSilence set to index 5 (30 seconds)")
end

function Tests:SilenceDropDown_OnLoad_DefaultsToOneWhenNoMatch()
	SoundtrackAddon.db.profile.settings.Silence = 999

	Soundtrack.OptionsTab.SilenceDropDown_OnLoad()

	AreEqual(1, SoundtrackUI.selectedSilence, "selectedSilence defaults to 1 when no match")
end

function Tests:SilenceDropDown_Initialize_AddsSilences()
	local buttonsAdded = 0
	Replace(_G, "UIDropDownMenu_AddButton", function() buttonsAdded = buttonsAdded + 1 end)
	SoundtrackUI.selectedSilence = 1

	Soundtrack.OptionsTab.SilenceDropDown_Initialize()

	AreEqual(10, buttonsAdded, "10 silence buttons added")
end

function Tests:SilenceDropDown_LoadSilences_AddsButtons()
	local buttonsAdded = 0
	Replace(_G, "UIDropDownMenu_AddButton", function() buttonsAdded = buttonsAdded + 1 end)
	SoundtrackUI.selectedSilence = 999

	Soundtrack.OptionsTab.SilenceDropDown_LoadSilences({ "No silence", "5 seconds", "10 seconds" })

	AreEqual(3, buttonsAdded, "3 silence buttons added")
end

function Tests:SilenceDropDown_LoadSilences_SetsTextForCurrentSilence()
	local textSet = nil
	Replace(_G, "UIDropDownMenu_SetText", function(_, text) textSet = text end)
	Replace(_G, "UIDropDownMenu_AddButton", function() end)
	SoundtrackUI.selectedSilence = 2

	Soundtrack.OptionsTab.SilenceDropDown_LoadSilences({ "No silence", "5 seconds" })

	AreEqual("5 seconds", textSet, "SetText called with current silence text")
end

function Tests:SilenceDropDown_OnClick_UpdatesSelectedSilence()
	Replace(_G, "UIDropDownMenu_SetSelectedID", function() end)

	local self = { GetID = function() return 3 end }
	Soundtrack.OptionsTab.SilenceDropDown_OnClick(self)

	AreEqual(3, SoundtrackUI.selectedSilence, "selectedSilence updated to 3")
end

function Tests:SilenceDropDown_OnClick_SavesSilenceSetting()
	Replace(_G, "UIDropDownMenu_SetSelectedID", function() end)

	local self = { GetID = function() return 2 end }
	Soundtrack.OptionsTab.SilenceDropDown_OnClick(self)

	AreEqual(5, SoundtrackAddon.db.profile.settings.Silence, "Silence saved as 5 seconds")
end

-- FadeTransitionDurationDropDown Tests

function Tests:FadeTransitionDurationDropDown_OnLoad_SetsSelectedFadeDuration()
	SoundtrackAddon.db.profile.settings.FadeTransitionDuration = 2

	Soundtrack.OptionsTab.FadeTransitionDurationDropDown_OnLoad()

	AreEqual(3, SoundtrackUI.selectedFadeDuration, "selectedFadeDuration set to index 3 (2 seconds)")
end

function Tests:FadeTransitionDurationDropDown_OnLoad_DefaultsToThreeWhenNoMatch()
	SoundtrackAddon.db.profile.settings.FadeTransitionDuration = 999

	Soundtrack.OptionsTab.FadeTransitionDurationDropDown_OnLoad()

	AreEqual(3, SoundtrackUI.selectedFadeDuration, "selectedFadeDuration defaults to 3 when no match")
end

function Tests:FadeTransitionDurationDropDown_Initialize_AddsDurations()
	local buttonsAdded = 0
	Replace(_G, "UIDropDownMenu_AddButton", function() buttonsAdded = buttonsAdded + 1 end)
	SoundtrackUI.selectedFadeDuration = 1

	Soundtrack.OptionsTab.FadeTransitionDurationDropDown_Initialize()

	AreEqual(5, buttonsAdded, "5 fade duration buttons added")
end

function Tests:FadeTransitionDurationDropDown_LoadDurations_AddsButtons()
	local buttonsAdded = 0
	Replace(_G, "UIDropDownMenu_AddButton", function() buttonsAdded = buttonsAdded + 1 end)
	SoundtrackUI.selectedFadeDuration = 999

	Soundtrack.OptionsTab.FadeTransitionDurationDropDown_LoadDurations({ "0.5 seconds", "1 second", "2 seconds" })

	AreEqual(3, buttonsAdded, "3 fade duration buttons added")
end

function Tests:FadeTransitionDurationDropDown_LoadDurations_SetsTextForCurrentDuration()
	local textSet = nil
	Replace(_G, "UIDropDownMenu_SetText", function(_, text) textSet = text end)
	Replace(_G, "UIDropDownMenu_AddButton", function() end)
	SoundtrackUI.selectedFadeDuration = 2

	Soundtrack.OptionsTab.FadeTransitionDurationDropDown_LoadDurations({ "0.5 seconds", "1 second" })

	AreEqual("1 second", textSet, "SetText called with current fade duration text")
end
