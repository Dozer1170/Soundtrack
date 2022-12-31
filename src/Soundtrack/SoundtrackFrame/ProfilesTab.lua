
function ProfilesTab_OnLoad()
    LoadProfileDropDown.initialize = ProfilesTab_InitLoadProfileDropdown
    LoadProfileDropDownText:SetText("Load Profile")
end

function ProfilesTab_InitLoadProfileDropdown()
    local profiles = SoundtrackAddon.db:GetProfiles()
    local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
    local info = UIDropDownMenu_CreateInfo()
    info.func = ProfilesTab_LoadProfileDropDownItemSelected
    for k, profileName in pairs(profiles) do
        info.text = profileName
        info.arg1 = profileName
        info.checked = profileName == currentProfile
        UIDropDownMenu_AddButton(info)
    end
end

function ProfilesTab_LoadProfileDropDownItemSelected(self, profileName)
    Soundtrack.TraceProfiles("Selected: " .. profileName)
    SoundtrackAddon.db:SetProfile(profileName)
    _TracksLoaded = false
    SoundtrackAddon:VARIABLES_LOADED()
end

function ProfilesTab_RefreshProfilesFrame()

end
