Soundtrack.OptionsTab = {}

function Soundtrack.OptionsTab.Initialize()
	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnLoad()
	Soundtrack.OptionsTab.SilenceDropDown_OnLoad()
	Soundtrack.OptionsTab.BattleCooldownDropDown_OnLoad()
end

function Soundtrack.OptionsTab.Refresh()
	local s = SoundtrackAddon.db.profile.settings

	OptionsTab_EnableMinimapButton:SetChecked(not SoundtrackAddon.db.profile.minimap.hide)
	OptionsTab_EnableDebugMode:SetChecked(s.Debug)
	OptionsTab_ShowTrackInformation:SetChecked(s.ShowTrackInformation)
	OptionsTab_LockNowPlayingFrame:SetChecked(s.LockNowPlayingFrame)
	OptionsTab_ShowDefaultMusic:SetChecked(s.ShowDefaultMusic)
	OptionsTab_ShowPlaybackControls:SetChecked(s.ShowPlaybackControls)
	OptionsTab_LockPlaybackControls:SetChecked(s.LockPlaybackControls)
	OptionsTab_ShowEventStack:SetChecked(s.ShowEventStack)
	OptionsTab_AutoAddZones:SetChecked(s.AutoAddZones)
	OptionsTab_AutoEscalateBattleMusic:SetChecked(s.EscalateBattleMusic)
	OptionsTab_YourEnemyLevelOnly:SetChecked(s.YourEnemyLevelOnly)

	OptionsTab_EnableZoneMusic:SetChecked(s.EnableZoneMusic)
	OptionsTab_EnableBattleMusic:SetChecked(s.EnableBattleMusic)
	OptionsTab_EnableMiscMusic:SetChecked(s.EnableMiscMusic)

	OptionsTab_HidePlaybackButtons:SetChecked(s.HideControlButtons)

	local cvar_LoopMusic = GetCVar("Sound_ZoneMusicNoDelay")
	Soundtrack.Chat.TraceFrame("Sound_ZoneMusicNoDelay: " .. cvar_LoopMusic)
	if cvar_LoopMusic == "0" then
		OptionsTab_LoopMusic:SetChecked(false)
	else
		OptionsTab_LoopMusic:SetChecked(true)
	end
end

-- General check boxes

function Soundtrack.OptionsTab.ToggleLoopMusic()
	if OptionsTab_LoopMusic:GetChecked() == 1 then
		SetCVar("Sound_ZoneMusicNoDelay", 1, "SoundtrackSound_ZoneMusicNoDelay_1")
		local cvar_LoopMusic = GetCVar("Sound_ZoneMusicNoDelay")
		Soundtrack.Chat.TraceFrame("Sound_ZoneMusicNoDelay: " .. cvar_LoopMusic)
	else
		SetCVar("Sound_ZoneMusicNoDelay", 0, "SoundtrackSound_ZoneMusicNoDelay_0")
		local cvar_LoopMusic = GetCVar("Sound_ZoneMusicNoDelay")
		Soundtrack.Chat.TraceFrame("Sound_ZoneMusicNoDelay: " .. cvar_LoopMusic)
	end
end

function Soundtrack.OptionsTab.ToggleShowPlaybackControls()
	SoundtrackAddon.db.profile.settings.ShowPlaybackControls =
		not SoundtrackAddon.db.profile.settings.ShowPlaybackControls
	SoundtrackFrame_RefreshPlaybackControls()
end

function Soundtrack.OptionsTab.ToggleMinimapButton()
	SoundtrackMinimap_ToggleMinimap()
end

function Soundtrack.OptionsTab.ToggleDebugMode()
	SoundtrackAddon.db.profile.settings.Debug = not SoundtrackAddon.db.profile.settings.Debug
	Soundtrack.Chat.InitDebugChatFrame()
end

function Soundtrack.OptionsTab.ToggleShowTrackInformation()
	SoundtrackAddon.db.profile.settings.ShowTrackInformation =
		not SoundtrackAddon.db.profile.settings.ShowTrackInformation
end

function Soundtrack.OptionsTab.ToggleShowEventStack()
	SoundtrackAddon.db.profile.settings.ShowEventStack = not SoundtrackAddon.db.profile.settings.ShowEventStack
	SoundtrackFrame_RefreshPlaybackControls()
end

function Soundtrack.OptionsTab.ToggleShowDefaultMusic()
	SoundtrackAddon.db.profile.settings.ShowDefaultMusic = not SoundtrackAddon.db.profile.settings.ShowDefaultMusic
	Soundtrack.TracksLoaded = false
	Soundtrack.LoadTracks()
end

-- Playback button locations

local locations = { "LEFT", "TOPLEFT", "TOPRIGHT", "RIGHT", "BOTTOMRIGHT", "BOTTOMLEFT" }

local function GetPlaybackButtonsLocations()
	return {
		"Left",
		"Top Left",
		"Top Right",
		"Right",
		"Bottom Right",
		"Bottom Left",
	}
end

local function GetCurrentPlaybackButtonsLocation()
	if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
		return 1
	end

	for i = 1, #locations, 1 do
		if SoundtrackAddon.db.profile.settings.PlaybackButtonsPosition == locations[i] then
			return i
		end
	end

	return 1
end

function Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnLoad()
	SoundtrackUI.selectedLocation = GetCurrentPlaybackButtonsLocation()
	UIDropDownMenu_Initialize(
		OptionsTab_PlaybackButtonsLocationDropDown,
		Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_Initialize
	)
end

function Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_Initialize()
	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_LoadLocations(GetPlaybackButtonsLocations())
	UIDropDownMenu_SetSelectedID(OptionsTab_PlaybackButtonsLocationDropDown, SoundtrackUI.selectedLocation)
	UIDropDownMenu_SetWidth(OptionsTab_PlaybackButtonsLocationDropDown, 160)
end

function Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_LoadLocations(locationsTexts)
	local currentLocation = SoundtrackUI.selectedLocation
	local info

	for i, locationText in ipairs(locationsTexts) do
		local checked = false
		if currentLocation == i then
			checked = true
			UIDropDownMenu_SetText(OptionsTab_PlaybackButtonsLocationDropDown, locationText)
		end

		info = {}
		info.text = locationText
		info.func = Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnClick
		UIDropDownMenu_AddButton(info)
	end
end

function Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(OptionsTab_PlaybackButtonsLocationDropDown, self:GetID())
	SoundtrackUI.selectedLocation = self:GetID()
	-- Save settings.
	SoundtrackAddon.db.profile.settings.PlaybackButtonsPosition = locations[SoundtrackUI.selectedLocation]
	SoundtrackFrame_RefreshPlaybackControls()
end

-- Battle cooldown

local cooldowns = { 0, 1, 2, 3, 5, 10, 15, 30 }

local function GetBattleCooldowns()
	return {
		"No cooldown",
		"1 second",
		"2 seconds",
		"3 seconds",
		"5 seconds",
		"10 seconds",
		"15 seconds",
		"30 seconds",
	}
end

local function GetCurrentBattleCooldown()
	if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
		return 1
	end

	for i, c in ipairs(cooldowns) do
		if SoundtrackAddon.db.profile.settings.BattleCooldown == c then
			return i
		end
	end

	return 1
end

function Soundtrack.OptionsTab.BattleCooldownDropDown_OnLoad()
	SoundtrackUI.selectedCooldown = GetCurrentBattleCooldown()
	UIDropDownMenu_Initialize(
		OptionsTab_BattleCooldownDropDown,
		Soundtrack.OptionsTab.BattleCooldownDropDown_Initialize
	)
end

function Soundtrack.OptionsTab.BattleCooldownDropDown_Initialize()
	Soundtrack.OptionsTab.BattleCooldownDropDown_LoadCooldowns(GetBattleCooldowns())
	UIDropDownMenu_SetSelectedID(OptionsTab_BattleCooldownDropDown, SoundtrackUI.selectedCooldown)
	UIDropDownMenu_SetWidth(OptionsTab_BattleCooldownDropDown, 130)
end

function Soundtrack.OptionsTab.BattleCooldownDropDown_LoadCooldowns(cooldownTexts)
	local currentCooldown = SoundtrackUI.selectedCooldown
	local info

	for i, cooldownText in ipairs(cooldownTexts) do
		local checked = nil
		if currentCooldown == i then
			checked = 1
			UIDropDownMenu_SetText(OptionsTab_BattleCooldownDropDown, cooldownText)
		end

		info = {}
		info.text = cooldownText
		info.func = Soundtrack.OptionsTab.BattleCooldownDropDown_OnClick
		info.checked = checked
		UIDropDownMenu_AddButton(info)
	end
end

function Soundtrack.OptionsTab.BattleCooldownDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(OptionsTab_BattleCooldownDropDown, self:GetID())
	SoundtrackUI.selectedCooldown = self:GetID()
	-- Save settings.
	SoundtrackAddon.db.profile.settings.BattleCooldown = cooldowns[SoundtrackUI.selectedCooldown]
end


-- Silence dropdown

local silences = { 0, 5, 10, 20, 30, 40, 60, 90, 120, 300 }

local function GetSilences()
	return {
		"No silence",
		"5 seconds",
		"10 seconds",
		"20 seconds",
		"30 seconds",
		"40 seconds",
		"1 minute",
		"1.5 minute",
		"2 minutes",
		"5 minutes",
	}
end

local function GetCurrentSilence()
	if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
		return 1
	end

	-- Replace with index of
	local savedSilenceSeconds = SoundtrackAddon.db.profile.settings.Silence
	for i = 1, #silences, 1 do
		if savedSilenceSeconds == silences[i] then
			return i
		end
	end

	return 1
end

function Soundtrack.OptionsTab.SilenceDropDown_OnLoad()
	SoundtrackUI.selectedSilence = GetCurrentSilence()
	UIDropDownMenu_Initialize(OptionsTab_SilenceDropDown, Soundtrack.OptionsTab.SilenceDropDown_Initialize)
	UIDropDownMenu_SetWidth(OptionsTab_SilenceDropDown, 130)
end

function Soundtrack.OptionsTab.SilenceDropDown_Initialize()
	Soundtrack.OptionsTab.SilenceDropDown_LoadSilences(GetSilences())
	UIDropDownMenu_SetSelectedID(OptionsTab_SilenceDropDown, SoundtrackUI.selectedSilence)
end

function Soundtrack.OptionsTab.SilenceDropDown_LoadSilences(silencesTexts)
	local currentSilence = SoundtrackUI.selectedSilence
	local info

	for i = 1, #silencesTexts, 1 do
		local checked = false
		if currentSilence == i then
			checked = true
		end

		info = UIDropDownMenu_CreateInfo()
		info.text = silencesTexts[i]
		info.func = Soundtrack.OptionsTab.SilenceDropDown_OnClick
		info.checked = checked
		UIDropDownMenu_AddButton(info)
	end
end

function Soundtrack.OptionsTab.SilenceDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(OptionsTab_SilenceDropDown, self:GetID())
	SoundtrackUI.selectedSilence = self:GetID()
	SoundtrackAddon.db.profile.settings.Silence = silences[SoundtrackUI.selectedSilence]
end
