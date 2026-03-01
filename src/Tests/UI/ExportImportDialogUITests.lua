if not Tests then
    return
end

local Tests          = Tests("ExportImportDialogUI", "PLAYER_ENTERING_WORLD")

-- ─────────────────────────────────────────────────────────────
-- Shared helpers
-- ─────────────────────────────────────────────────────────────

local editBoxText    = ""
local editBoxFocused = false
local frameShown     = false

local function SetupFrameMocks()
    editBoxText                              = ""
    editBoxFocused                           = false
    frameShown                               = false

    local editBox                            = {
        text          = "",
        highlighted   = false,
        SetText       = function(self, t) self.text = t end,
        Insert        = function(self, t) self.text = self.text .. t end,
        GetText       = function(self) return self.text end,
        HighlightText = function(self) self.highlighted = true end,
        SetFocus      = function(self) editBoxFocused = true end,
    }

    SoundtrackExportImportScrollFrame        = { EditBox = editBox }
    SoundtrackExportImportFrame              = {
        shown  = false,
        raised = false,
        Show   = function(self) self.shown = true end,
        Hide   = function(self) self.shown = false end,
        Raise  = function(self) self.raised = true end,
    }
    SoundtrackExportImportProfileNameEditBox = {
        text    = "",
        SetText = function(self, t) self.text = t end,
        GetText = function(self) return self.text end,
    }

    -- WoW globals used by Import()
    _G.StaticPopupDialogs                    = _G.StaticPopupDialogs or {}
    _G.StaticPopup_Show                      = _G.StaticPopup_Show or function() end
    _G.HasValue                              = function(t, v)
        for _, val in ipairs(t) do
            if val == v then return true end
        end
        return false
    end
end

local function SetupProfileDb(profiles, currentProfile)
    profiles                             = profiles or { "Default", "Raid" }
    currentProfile                       = currentProfile or "Default"
    SoundtrackAddon.db.GetCurrentProfile = function(self) return currentProfile end
    SoundtrackAddon.db.SetProfile        = function(self, name) currentProfile = name end
    SoundtrackAddon.db.GetProfiles       = function(self) return profiles end
end

local function SetupSerializer(exportStr)
    exportStr = exportStr or "V1:abc123"
    Replace(Soundtrack.ProfileSerializer, "Export", function() return exportStr end)
    Replace(Soundtrack.ProfileSerializer, "Decode", function(str)
        if str == "INVALID" then return false, "bad string" end
        return true, { events = {}, settings = {} }
    end)
    Replace(Soundtrack.ProfileSerializer, "Apply", function() end)
end

local function SetupChat()
    Soundtrack.Chat = Soundtrack.Chat or {}
    Soundtrack.Chat.Message = function() end
end

local function SetupReload()
    Replace(Soundtrack.ProfilesTab, "ReloadProfile", function() end)
end

-- ─────────────────────────────────────────────────────────────
-- Open
-- ─────────────────────────────────────────────────────────────

function Tests:Open_DelegatesToOpenForExportWithCurrentProfile()
    SetupFrameMocks()
    SetupProfileDb({ "Default" }, "Default")
    SetupSerializer("V1:exportdata")

    Soundtrack.ExportImportDialog.Open()

    IsTrue(SoundtrackExportImportFrame.shown, "Frame is shown after Open()")
    AreEqual("V1:exportdata", SoundtrackExportImportScrollFrame.EditBox.text,
        "EditBox populated with export string")
end

-- ─────────────────────────────────────────────────────────────
-- OpenForExport
-- ─────────────────────────────────────────────────────────────

function Tests:OpenForExport_ShowsFrame()
    SetupFrameMocks()
    SetupProfileDb({ "Default" }, "Default")
    SetupSerializer()

    Soundtrack.ExportImportDialog.OpenForExport("Default")

    IsTrue(SoundtrackExportImportFrame.shown, "Frame is shown")
end

function Tests:OpenForExport_PopulatesEditBoxWithExportString()
    SetupFrameMocks()
    SetupProfileDb({ "Default" }, "Default")
    SetupSerializer("V1:teststring")

    Soundtrack.ExportImportDialog.OpenForExport("Default")

    AreEqual("V1:teststring", SoundtrackExportImportScrollFrame.EditBox.text,
        "EditBox contains the export string")
end

function Tests:OpenForExport_SetsProfileNameInNameBox()
    SetupFrameMocks()
    SetupProfileDb({ "Default", "Raid" }, "Default")
    SetupSerializer()

    Soundtrack.ExportImportDialog.OpenForExport("Raid")

    AreEqual("Raid", SoundtrackExportImportProfileNameEditBox.text,
        "Profile name box shows selected profile name")
end

function Tests:OpenForExport_ActiveProfile_DoesNotSwitchProfile()
    SetupFrameMocks()
    local switched = false
    SetupProfileDb({ "Default" }, "Default")
    local originalSet = SoundtrackAddon.db.SetProfile
    SoundtrackAddon.db.SetProfile = function(self, name)
        switched = true
        originalSet(self, name)
    end
    SetupSerializer()

    Soundtrack.ExportImportDialog.OpenForExport("Default")

    IsFalse(switched, "SetProfile not called when exporting the active profile")
end

function Tests:OpenForExport_NonActiveProfile_SwitchesAndRestores()
    SetupFrameMocks()
    local switchLog = {}
    SetupProfileDb({ "Default", "Raid" }, "Default")
    SoundtrackAddon.db.SetProfile = function(self, name)
        table.insert(switchLog, name)
    end
    -- GetCurrentProfile must always return the original active profile for the restore check
    SoundtrackAddon.db.GetCurrentProfile = function(self) return "Default" end
    SetupSerializer()

    Soundtrack.ExportImportDialog.OpenForExport("Raid")

    AreEqual(2, #switchLog, "SetProfile called twice (switch + restore)")
    AreEqual("Raid", switchLog[1], "First switch goes to the selected profile")
    AreEqual("Default", switchLog[2], "Second switch restores the original active profile")
end

function Tests:OpenForExport_HighlightsEditBoxText()
    SetupFrameMocks()
    SetupProfileDb({ "Default" }, "Default")
    SetupSerializer()

    Soundtrack.ExportImportDialog.OpenForExport("Default")

    IsTrue(SoundtrackExportImportScrollFrame.EditBox.highlighted, "EditBox text is highlighted")
end

-- ─────────────────────────────────────────────────────────────
-- OpenForImport
-- ─────────────────────────────────────────────────────────────

function Tests:OpenForImport_ShowsFrame()
    SetupFrameMocks()

    Soundtrack.ExportImportDialog.OpenForImport()

    IsTrue(SoundtrackExportImportFrame.shown, "Frame is shown for import")
end

function Tests:OpenForImport_ClearsEditBox()
    SetupFrameMocks()
    SoundtrackExportImportScrollFrame.EditBox.text = "stale"

    Soundtrack.ExportImportDialog.OpenForImport()

    AreEqual("", SoundtrackExportImportScrollFrame.EditBox.text, "EditBox cleared on OpenForImport")
end

function Tests:OpenForImport_ClearsProfileNameBox()
    SetupFrameMocks()
    SoundtrackExportImportProfileNameEditBox.text = "OldName"

    Soundtrack.ExportImportDialog.OpenForImport()

    AreEqual("", SoundtrackExportImportProfileNameEditBox.text, "Profile name box cleared on OpenForImport")
end

function Tests:OpenForImport_FocusesEditBox()
    SetupFrameMocks()

    Soundtrack.ExportImportDialog.OpenForImport()

    IsTrue(editBoxFocused, "EditBox focused on OpenForImport")
end

-- ─────────────────────────────────────────────────────────────
-- Close
-- ─────────────────────────────────────────────────────────────

function Tests:Close_HidesFrame()
    SetupFrameMocks()
    SoundtrackExportImportFrame.shown = true

    Soundtrack.ExportImportDialog.Close()

    IsFalse(SoundtrackExportImportFrame.shown, "Frame hidden by Close()")
end

-- ─────────────────────────────────────────────────────────────
-- Copy
-- ─────────────────────────────────────────────────────────────

function Tests:Copy_HighlightsText()
    SetupFrameMocks()

    Soundtrack.ExportImportDialog.Copy()

    IsTrue(SoundtrackExportImportScrollFrame.EditBox.highlighted, "Text highlighted by Copy()")
end

-- ─────────────────────────────────────────────────────────────
-- Import
-- ─────────────────────────────────────────────────────────────

function Tests:Import_ShowsDialogWhenProfileNameEmpty()
    SetupFrameMocks()
    SetupProfileDb()
    SetupSerializer()
    SetupChat()
    SoundtrackExportImportScrollFrame.EditBox.text = "V1:abc"
    SoundtrackExportImportProfileNameEditBox.text  = ""
    local popupShown                               = nil
    StaticPopup_Show                               = function(key) popupShown = key end

    Soundtrack.ExportImportDialog.Import()

    AreEqual("SOUNDTRACK_IMPORT_PROFILE_EMPTY", popupShown,
        "Shows empty-name popup when profile name is blank")
end

function Tests:Import_ShowsDialogWhenProfileAlreadyExists()
    SetupFrameMocks()
    SetupProfileDb({ "Default", "Existing" })
    SetupSerializer()
    SetupChat()
    SoundtrackExportImportScrollFrame.EditBox.text = "V1:abc"
    SoundtrackExportImportProfileNameEditBox.text  = "Existing"
    local popupShown                               = nil
    StaticPopup_Show                               = function(key) popupShown = key end

    Soundtrack.ExportImportDialog.Import()

    AreEqual("SOUNDTRACK_IMPORT_PROFILE_EXISTS", popupShown,
        "Shows exists popup when profile name taken")
end

function Tests:Import_ShowsChatMessageWhenDecodeFailsf()
    SetupFrameMocks()
    SetupProfileDb({ "Default" })
    SetupSerializer()
    SetupChat()
    local chatMsg                                  = nil
    Soundtrack.Chat.Message                        = function(msg) chatMsg = msg end
    SoundtrackExportImportScrollFrame.EditBox.text = "INVALID"
    SoundtrackExportImportProfileNameEditBox.text  = "NewProfile"

    Soundtrack.ExportImportDialog.Import()

    Exists(chatMsg, "Chat error shown when decode fails")
end

function Tests:Import_CreatesProfileAndApplies()
    SetupFrameMocks()
    SetupProfileDb({ "Default" })
    SetupSerializer()
    SetupChat()
    SetupReload()
    local createdProfile          = nil
    local applyCalled             = false
    SoundtrackAddon.db.SetProfile = function(self, name) createdProfile = name end
    Replace(Soundtrack.ProfileSerializer, "Apply", function() applyCalled = true end)
    SoundtrackExportImportScrollFrame.EditBox.text = "V1:valid"
    SoundtrackExportImportProfileNameEditBox.text  = "Imported"

    Soundtrack.ExportImportDialog.Import()

    AreEqual("Imported", createdProfile, "SetProfile called with the new profile name")
    IsTrue(applyCalled, "Apply called to write decoded data into new profile")
end
