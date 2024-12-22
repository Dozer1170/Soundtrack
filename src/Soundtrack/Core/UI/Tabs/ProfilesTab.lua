Soundtrack.ProfilesTab = {}

local PROFILES_COPY_CONFIRM = "PROFILES_COPY_CONFIRM"
local PROFILES_DELETE_CONFIRM = "PROFILES_DELETE_CONFIRM"
local PROFILES_RESET_CONFIRM = "PROFILES_RESET_CONFIRM"
local PROFILE_ALREADY_EXISTS = "PROFILE_ALREADY_EXISTS"

function Soundtrack.ProfilesTab.OnLoad()
	LoadProfileDropDown.initialize = function()
		Soundtrack.ProfilesTab.InitDropDown(Soundtrack.ProfilesTab.LoadProfileDropDownItemSelected, false)
	end
	LoadProfileDropDownText:SetText("Load Profile")

	CopyFromProfileDropDown.initialize = function()
		Soundtrack.ProfilesTab.InitDropDown(Soundtrack.ProfilesTab.CopyFromProfileDropDownItemSelected, true)
	end
	CopyFromProfileDropDownText:SetText("Copy From")

	DeleteProfileDropDown.initialize = function()
		Soundtrack.ProfilesTab.InitDropDown(Soundtrack.ProfilesTab.DeleteProfileDropDownItemSelected, true)
	end
	DeleteProfileDropDownText:SetText("Delete Profile")
end

function Soundtrack.ProfilesTab.InitDropDown(func, skipCurrentProfile)
	local profiles = SoundtrackAddon.db:GetProfiles()
	local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
	local info = UIDropDownMenu_CreateInfo()
	info.func = func
	for _, profileName in pairs(profiles) do
		if not skipCurrentProfile or profileName ~= currentProfile then
			info.text = profileName
			info.arg1 = profileName
			info.checked = profileName == currentProfile
			UIDropDownMenu_AddButton(info)
		end
	end
end

function Soundtrack.ProfilesTab.LoadProfileDropDownItemSelected(_, profileName)
	Soundtrack.Chat.TraceProfiles("Selected profile to load: " .. profileName)
	SoundtrackAddon.db:SetProfile(profileName)
	Soundtrack.ProfilesTab.ReloadProfile()
end

function Soundtrack.ProfilesTab.CopyFromProfileDropDownItemSelected(_, profileName)
	Soundtrack.Chat.TraceProfiles("Selected profile to copy from: " .. profileName)

	local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
	StaticPopupDialogs[PROFILES_COPY_CONFIRM] = {
		text = "Are you sure you want to OVERRIDE the "
			.. currentProfile
			.. " profile with settings from "
			.. profileName
			.. "? You cannot undo this.",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			SoundtrackAddon.db:CopyProfile(profileName)
			Soundtrack.ProfilesTab.ReloadProfile()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show(PROFILES_COPY_CONFIRM)
end

function Soundtrack.ProfilesTab.DeleteProfileDropDownItemSelected(_, profileName)
	Soundtrack.Chat.TraceProfiles("Selected profile to delete: " .. profileName)

	StaticPopupDialogs[PROFILES_DELETE_CONFIRM] = {
		text = "Are you sure you want to DELETE the " .. profileName .. " profile? You cannot undo this.",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			SoundtrackAddon.db:DeleteProfile(profileName)
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show(PROFILES_DELETE_CONFIRM)
end

function Soundtrack.ProfilesTab.CreateNewProfile()
	local profileName = NewProfileEditBox:GetText()
	Soundtrack.Chat.TraceProfiles("Requested to create new profile: " .. profileName)

	local profiles = SoundtrackAddon.db:GetProfiles()
	if HasValue(profiles, profileName) then
		StaticPopupDialogs[PROFILE_ALREADY_EXISTS] = {
			text = "Profile already exists, not creating.",
			button1 = "Ok",
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show(PROFILE_ALREADY_EXISTS)
	end

	SoundtrackAddon.db:SetProfile(profileName)
	NewProfileEditBox:SetText("")
	Soundtrack.ProfilesTab.ReloadProfile()
end

function Soundtrack.ProfilesTab.ResetCurrentProfile()
	Soundtrack.Chat.TraceProfiles("Requested to reset current profile")
	local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
	StaticPopupDialogs[PROFILES_RESET_CONFIRM] = {
		text = "Are you sure you want to RESET the "
			.. currentProfile
			.. " profile to default values? You cannot undo this.",
		button1 = "Yes",
		button2 = "No",
		OnAccept = function()
			SoundtrackAddon.db:ResetProfile()
			Soundtrack.ProfilesTab.ReloadProfile()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show(PROFILES_RESET_CONFIRM)
end

function Soundtrack.ProfilesTab.ReloadProfile()
	_TracksLoaded = false
	SoundtrackAddon:VARIABLES_LOADED()
	Soundtrack.ProfilesTab.RefreshProfilesFrame()
end

function Soundtrack.ProfilesTab.RefreshProfilesFrame()
	local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
	CurrentProfileName:SetText(currentProfile)
end
