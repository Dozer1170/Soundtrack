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
