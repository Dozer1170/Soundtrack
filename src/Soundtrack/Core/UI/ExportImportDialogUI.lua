Soundtrack.ExportImportDialog       = {}

local IMPORT_PROFILE_ALREADY_EXISTS = "SOUNDTRACK_IMPORT_PROFILE_EXISTS"
local IMPORT_PROFILE_NAME_EMPTY     = "SOUNDTRACK_IMPORT_PROFILE_EMPTY"

local function GetEditBox()
    return SoundtrackExportImportScrollFrame.EditBox
end

-- Called by the Export / Import button on the Profiles tab.
function Soundtrack.ExportImportDialog.Open()
    SoundtrackExportImportFrame:Show()
    SoundtrackExportImportFrame:Raise()
    -- Pre-populate the EditBox with the current profile export string.
    local editBox = GetEditBox()
    local str = Soundtrack.ProfileSerializer.Export()
    -- Use Insert (not SetText) so InputScrollFrameTemplate's OnTextChanged
    -- fires and the scroll frame correctly measures the content height.
    editBox:SetText("")
    editBox:Insert(str)
    editBox:HighlightText()
    -- Clear the profile name field each time the dialog opens.
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
