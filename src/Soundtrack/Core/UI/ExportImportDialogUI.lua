Soundtrack.ExportImportDialog       = {}

local IMPORT_PROFILE_ALREADY_EXISTS = "SOUNDTRACK_IMPORT_PROFILE_EXISTS"
local IMPORT_PROFILE_NAME_EMPTY     = "SOUNDTRACK_IMPORT_PROFILE_EMPTY"

local function GetEditBox()
    return SoundtrackExportImportScrollFrame.EditBox
end

-- Called by the Export / Import button on the Profiles tab.
function Soundtrack.ExportImportDialog.Open()
    Soundtrack.ExportImportDialog.OpenForExport(SoundtrackAddon.db:GetCurrentProfile())
end

-- Open the dialog pre-populated with the export string for a specific profile.
-- Temporarily switches to that profile to read its data, then switches back.
function Soundtrack.ExportImportDialog.OpenForExport(profileName)
    local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
    if profileName ~= currentProfile then
        SoundtrackAddon.db:SetProfile(profileName)
    end
    local str = Soundtrack.ProfileSerializer.Export()
    if profileName ~= currentProfile then
        SoundtrackAddon.db:SetProfile(currentProfile)
    end

    SoundtrackExportImportFrame:Show()
    SoundtrackExportImportFrame:Raise()
    local editBox = GetEditBox()
    editBox:SetText("")
    editBox:Insert(str)
    editBox:HighlightText()
    SoundtrackExportImportProfileNameEditBox:SetText(profileName)
    editBox:SetFocus()
end

-- Open the dialog cleared and ready for an import paste.
function Soundtrack.ExportImportDialog.OpenForImport()
    SoundtrackExportImportFrame:Show()
    SoundtrackExportImportFrame:Raise()
    local editBox = GetEditBox()
    editBox:SetText("")
    SoundtrackExportImportProfileNameEditBox:SetText("")
    editBox:SetFocus()
end

function Soundtrack.ExportImportDialog.Close()
    SoundtrackExportImportFrame:Hide()
end

-- Selects all export text and focuses the box so the user can press Ctrl+C.
-- (CopyToClipboard is a protected function addons cannot call directly.)
function Soundtrack.ExportImportDialog.Copy()
    local editBox = GetEditBox()
    editBox:SetFocus()
    editBox:HighlightText()
end

-- Reads the share string and the target profile name, creates a new profile,
-- applies the data into it, and reloads.
function Soundtrack.ExportImportDialog.Import()
    local str         = GetEditBox():GetText()
    local profileName = SoundtrackExportImportProfileNameEditBox:GetText()

    -- Validate profile name.
    if not profileName or profileName == "" then
        StaticPopupDialogs[IMPORT_PROFILE_NAME_EMPTY] = {
            text = "Please enter a name for the new profile before importing.",
            button1 = "OK",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show(IMPORT_PROFILE_NAME_EMPTY)
        return
    end

    -- Check the profile doesn't already exist.
    local profiles = SoundtrackAddon.db:GetProfiles()
    if HasValue(profiles, profileName) then
        StaticPopupDialogs[IMPORT_PROFILE_ALREADY_EXISTS] = {
            text = 'A profile named "' .. profileName .. '" already exists. Choose a different name.',
            button1 = "OK",
            timeout = 0,
            whileDead = true,
            hideOnEscape = true,
        }
        StaticPopup_Show(IMPORT_PROFILE_ALREADY_EXISTS)
        return
    end

    -- Validate + parse the share string before touching any state.
    local ok, data = Soundtrack.ProfileSerializer.Decode(str)
    if not ok then
        Soundtrack.Chat.Message("Soundtrack Import Error: " .. data)
        return
    end

    -- Create + switch to the new profile, then apply decoded data.
    SoundtrackAddon.db:SetProfile(profileName)
    Soundtrack.ProfileSerializer.Apply(data)

    Soundtrack.Chat.Message('Soundtrack: Imported into new profile "' .. profileName .. '".')
    Soundtrack.ExportImportDialog.Close()
    Soundtrack.ProfilesTab.ReloadProfile()
end
