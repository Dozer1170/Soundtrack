Soundtrack.OptionsTab = {}

function Soundtrack.OptionsTab.Initialize()
	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnLoad()
	Soundtrack.OptionsTab.SilenceDropDown_OnLoad()
	Soundtrack.OptionsTab.LowHealthPercentDropDown_OnLoad()
	Soundtrack.OptionsTab.BattleCooldownDropDown_OnLoad()
end

function Soundtrack.OptionsTab.Refresh()
	local s = SoundtrackAddon.db.profile.settings

	Soundtrack.OptionsTab.EnableMinimapButton:SetChecked(not SoundtrackAddon.db.profile.minimap.hide)
	Soundtrack.OptionsTab.EnableDebugMode:SetChecked(s.Debug)
	Soundtrack.OptionsTab.ShowTrackInformation:SetChecked(s.ShowTrackInformation)
	Soundtrack.OptionsTab.LockNowPlayingFrame:SetChecked(s.LockNowPlayingFrame)
	Soundtrack.OptionsTab.ShowDefaultMusic:SetChecked(s.ShowDefaultMusic)
	Soundtrack.OptionsTab.ShowPlaybackControls:SetChecked(s.ShowPlaybackControls)
	Soundtrack.OptionsTab.LockPlaybackControls:SetChecked(s.LockPlaybackControls)
	Soundtrack.OptionsTab.ShowEventStack:SetChecked(s.ShowEventStack)
	Soundtrack.OptionsTab.AutoAddZones:SetChecked(s.AutoAddZones)
	Soundtrack.OptionsTab.AutoEscalateBattleMusic:SetChecked(s.EscalateBattleMusic)
	Soundtrack.OptionsTab.YourEnemyLevelOnly:SetChecked(s.YourEnemyLevelOnly)

	Soundtrack.OptionsTab.EnableZoneMusic:SetChecked(s.EnableZoneMusic)
	Soundtrack.OptionsTab.EnableBattleMusic:SetChecked(s.EnableBattleMusic)
	Soundtrack.OptionsTab.EnableMiscMusic:SetChecked(s.EnableMiscMusic)
	Soundtrack.OptionsTab.EnableCustomMusic:SetChecked(s.EnableCustomMusic)

	Soundtrack.OptionsTab.HidePlaybackButtons:SetChecked(s.HideControlButtons)

	local cvar_LoopMusic = GetCVar("Sound_ZoneMusicNoDelay")
	Soundtrack.Chat.TraceFrame("Sound_ZoneMusicNoDelay: " .. cvar_LoopMusic)
	if cvar_LoopMusic == "0" then
		Soundtrack.OptionsTab.LoopMusic:SetChecked(false)
	else
		Soundtrack.OptionsTab.LoopMusic:SetChecked(true)
	end
end

-- General check boxes

function Soundtrack.OptionsTab.ToggleLoopMusic()
	if Soundtrack.OptionsTab.LoopMusic:GetChecked() == 1 then
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
	_TracksLoaded = false
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
	SoundtrackFrame.selectedLocation = GetCurrentPlaybackButtonsLocation()
	UIDropDownMenu_Initialize(
		Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown,
		Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_Initialize
	)
end

function Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_Initialize()
	Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_LoadLocations(GetPlaybackButtonsLocations())
	UIDropDownMenu_SetSelectedID(
		Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown,
		SoundtrackFrame.selectedLocation
	)
	UIDropDownMenu_SetWidth(Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown, 160)
end

function Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_LoadLocations(locationsTexts)
	local currentLocation = SoundtrackFrame.selectedLocation
	local info

	for i, locationText in ipairs(locationsTexts) do
		local checked = false
		if currentLocation == i then
			checked = true
			UIDropDownMenu_SetText(Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown, locationText)
		end

		info = {}
		info.text = locationText
		info.func = Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnClick
		UIDropDownMenu_AddButton(info)
	end
end

function Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(Soundtrack.OptionsTab.PlaybackButtonsLocationDropDown, self:GetID())
	SoundtrackFrame.selectedLocation = self:GetID()
	-- Save settings.
	SoundtrackAddon.db.profile.settings.PlaybackButtonsPosition = locations[SoundtrackFrame.selectedLocation]
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
	SoundtrackFrame.selectedCooldown = GetCurrentBattleCooldown()
	UIDropDownMenu_Initialize(
		Soundtrack.OptionsTab.BattleCooldownDropDown,
		Soundtrack.OptionsTab.BattleCooldownDropDown_Initialize
	)
end

function Soundtrack.OptionsTab.BattleCooldownDropDown_Initialize()
	Soundtrack.OptionsTab.BattleCooldownDropDown_LoadCooldowns(GetBattleCooldowns())
	UIDropDownMenu_SetSelectedID(Soundtrack.OptionsTab.BattleCooldownDropDown, SoundtrackFrame.selectedCooldown)
	UIDropDownMenu_SetWidth(Soundtrack.OptionsTab.BattleCooldownDropDown, 130)
end

function Soundtrack.OptionsTab.BattleCooldownDropDown_LoadCooldowns(cooldownTexts)
	local currentCooldown = SoundtrackFrame.selectedCooldown
	local info

	for i, cooldownText in ipairs(cooldownTexts) do
		local checked = nil
		if currentCooldown == i then
			checked = 1
			UIDropDownMenu_SetText(Soundtrack.OptionsTab.BattleCooldownDropDown, cooldownText)
		end

		info = {}
		info.text = cooldownText
		info.func = Soundtrack.OptionsTab.BattleCooldownDropDown_OnClick
		info.checked = checked
		UIDropDownMenu_AddButton(info)
	end
end

function Soundtrack.OptionsTab.BattleCooldownDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(Soundtrack.OptionsTab.BattleCooldownDropDown, self:GetID())
	SoundtrackFrame.selectedCooldown = self:GetID()
	-- Save settings.
	SoundtrackAddon.db.profile.settings.BattleCooldown = cooldowns[SoundtrackFrame.selectedCooldown]
end

-- Low health percent dropdown

local lowhealthpercents = { 0, 0.05, 0.1, 0.15, 0.20, 0.25, 0.3, 0.35, 0.4, 0.45, 0.5 }

local function GetLowHealthPercents()
	return {
		"0%",
		"5%",
		"10%",
		"15%",
		"20%",
		"25%",
		"30%",
		"35%",
		"40%",
		"45%",
		"50%",
	}
end

local function GetCurrentLowHealthPercent()
	if SoundtrackAddon == nil or SoundtrackAddon.db == nil then
		return 1
	end

	local i
	for i = 1, #lowhealthpercents, 1 do
		if SoundtrackAddon.db.profile.settings.LowHealthPercent == lowhealthpercents[i] then
			return i
		end
	end

	return 0
end

function Soundtrack.OptionsTab.LowHealthPercentDropDown_OnLoad()
	SoundtrackFrame.selectedLowHealthPercent = GetCurrentLowHealthPercent()
	UIDropDownMenu_SetSelectedID(
		Soundtrack.OptionsTab.LowHealthPercentDropDown,
		SoundtrackFrame.selectedLowHealthPercent
	)
	UIDropDownMenu_Initialize(
		Soundtrack.OptionsTab.LowHealthPercentDropDown,
		Soundtrack.OptionsTab.LowHealthPercentDropDown_Initialize
	)
	UIDropDownMenu_SetWidth(Soundtrack.OptionsTab.LowHealthPercentDropDown, 130)
end

function Soundtrack.OptionsTab.LowHealthPercentDropDown_LoadPercents(lowHealthTexts)
	local currentLowHealthPercent = SoundtrackFrame.selectedLowHealthPercent
	local info

	for i = 1, #lowHealthTexts, 1 do
		local checked = nil
		if currentLowHealthPercent == i then
			checked = 1
			UIDropDownMenu_SetText(Soundtrack.OptionsTab.LowHealthPercentDropDown, lowHealthTexts[i])
		end

		info = {}
		info.text = lowHealthTexts[i]
		info.func = Soundtrack.OptionsTab.LowHealthPercentDropDown_OnClick
		info.checked = checked
		UIDropDownMenu_AddButton(info)
	end
end

function Soundtrack.OptionsTab.LowHealthPercentDropDown_Initialize()
	Soundtrack.OptionsTab.LowHealthPercentDropDown_LoadPercents(GetLowHealthPercents())
end

function Soundtrack.OptionsTab.LowHealthPercentDropDown_OnClick(self)
	UIDropDownMenu_SetSelectedID(Soundtrack.OptionsTab.LowHealthPercentDropDown, self:GetID())
	SoundtrackFrame.selectedLowHealthPercent = self:GetID()
	-- Save settings.
	SoundtrackAddon.db.profile.settings.LowHealthPercent = lowhealthpercents[SoundtrackFrame.selectedLowHealthPercent]
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
	SoundtrackFrame.selectedSilence = GetCurrentSilence()
	UIDropDownMenu_Initialize(Soundtrack.OptionsTab.SilenceDropDown, Soundtrack.OptionsTab.SilenceDropDown_Initialize)
	UIDropDownMenu_SetWidth(Soundtrack.OptionsTab.SilenceDropDown, 130)
end

function Soundtrack.OptionsTab.SilenceDropDown_Initialize()
	Soundtrack.OptionsTab.SilenceDropDown_LoadSilences(GetSilences())
	UIDropDownMenu_SetSelectedID(Soundtrack.OptionsTab.SilenceDropDown, SoundtrackFrame.selectedSilence)
end

function Soundtrack.OptionsTab.SilenceDropDown_LoadSilences(silencesTexts)
	local currentSilence = SoundtrackFrame.selectedSilence
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
	UIDropDownMenu_SetSelectedID(Soundtrack.OptionsTab.SilenceDropDown, self:GetID())
	SoundtrackFrame.selectedSilence = self:GetID()
	SoundtrackAddon.db.profile.settings.Silence = silences[SoundtrackFrame.selectedSilence]
end
