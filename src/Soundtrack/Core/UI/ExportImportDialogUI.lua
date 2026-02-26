Soundtrack.ExportImportDialog = {}

-- Called by the Export button on the Profiles tab.
function Soundtrack.ExportImportDialog.Open()
    SoundtrackExportImportFrame:Show()
    SoundtrackExportImportFrame:Raise()
    -- Pre-populate the EditBox with the current profile export string.
    local str = Soundtrack.ProfileSerializer.Export()
    SoundtrackExportImportEditBox:SetText(str)
    SoundtrackExportImportEditBox:HighlightText(0, #str)
    SoundtrackExportImportEditBox:SetFocus()
end

function Soundtrack.ExportImportDialog.Close()
    SoundtrackExportImportFrame:Hide()
end

-- Copies the EditBox text to the clipboard via SelectAll + Ctrl-C is the
-- standard WoW pattern. SelectAll highlights so the user can then Ctrl-C.
function Soundtrack.ExportImportDialog.SelectAll()
    SoundtrackExportImportEditBox:SetFocus()
    SoundtrackExportImportEditBox:HighlightText()
end

-- Reads the EditBox text and attempts to import it.
function Soundtrack.ExportImportDialog.Import()
    local str = SoundtrackExportImportEditBox:GetText()
    local ok, msg = Soundtrack.ProfileSerializer.Import(str)
    if ok then
        Soundtrack.Chat.Message("Soundtrack: " .. msg)
        Soundtrack.ExportImportDialog.Close()
        -- Reload the profile so the imported data takes effect.
        Soundtrack.ProfilesTab.ReloadProfile()
    else
        Soundtrack.Chat.Message("Soundtrack Import Error: " .. msg)
    end
end
