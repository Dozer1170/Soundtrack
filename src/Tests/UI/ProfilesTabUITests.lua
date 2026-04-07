if not Tests then
	return
end

local Tests = Tests("ProfilesTabUI", "PLAYER_ENTERING_WORLD")

-- ─────────────────────────────────────────────────────────────
-- Shared helpers
-- ─────────────────────────────────────────────────────────────

local function SetupChat()
	Soundtrack.Chat.TraceProfiles = function() end
end

local function SetupProfileDb(profiles, currentProfile)
	profiles = profiles or { "Default", "Raid" }
	currentProfile = currentProfile or "Default"
	local copiedFrom = nil
	local deletedProfile = nil
	local loadedProfile = nil
	SoundtrackAddon.db.GetProfiles = function(self) return profiles end
	SoundtrackAddon.db.GetCurrentProfile = function(self) return currentProfile end
	SoundtrackAddon.db.SetProfile = function(self, name)
		loadedProfile = name
		currentProfile = name
	end
	SoundtrackAddon.db.CopyProfile = function(self, name) copiedFrom = name end
	SoundtrackAddon.db.DeleteProfile = function(self, name) deletedProfile = name end
	-- Expose for test assertions
	SoundtrackAddon.db._copiedFrom = function() return copiedFrom end
	SoundtrackAddon.db._deletedProfile = function() return deletedProfile end
	SoundtrackAddon.db._loadedProfile = function() return loadedProfile end
end

local function MockReloadProfile()
	Replace(Soundtrack.ProfilesTab, "ReloadProfile", function() end)
end

local function MockRefreshProfilesFrame()
	Replace(Soundtrack.ProfilesTab, "RefreshProfilesFrame", function() end)
end

local function MockRenderFunctions()
	Replace(Soundtrack.ProfilesTab, "PopulateProfileList", function() end)
	Replace(Soundtrack.ProfilesTab, "RefreshDetailsPanel", function() end)
	Replace(Soundtrack.ProfilesTab, "RefreshProfileListHighlight", function() end)
end

-- ─────────────────────────────────────────────────────────────
-- SelectProfile / GetSelectedProfile
-- ─────────────────────────────────────────────────────────────

function Tests:SelectProfile_SetsSelectedProfile()
	SetupChat()
	SetupProfileDb()
	MockRenderFunctions()

	Soundtrack.ProfilesTab.SelectProfile("Raid")

	AreEqual("Raid", Soundtrack.ProfilesTab.GetSelectedProfile(), "GetSelectedProfile returns the selected profile")
end

function Tests:SelectProfile_CallsRefreshDetailsPanel()
	SetupChat()
	SetupProfileDb()
	local called = false
	Replace(Soundtrack.ProfilesTab, "RefreshDetailsPanel", function() called = true end)
	Replace(Soundtrack.ProfilesTab, "RefreshProfileListHighlight", function() end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")

	IsTrue(called, "RefreshDetailsPanel called after SelectProfile")
end

function Tests:SelectProfile_CallsRefreshProfileListHighlight()
	SetupChat()
	SetupProfileDb()
	local called = false
	Replace(Soundtrack.ProfilesTab, "RefreshProfileListHighlight", function() called = true end)
	Replace(Soundtrack.ProfilesTab, "RefreshDetailsPanel", function() end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")

	IsTrue(called, "RefreshProfileListHighlight called after SelectProfile")
end

-- ─────────────────────────────────────────────────────────────
-- SetActiveProfile
-- ─────────────────────────────────────────────────────────────

function Tests:SetActiveProfile_CallsSetProfileOnDb()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	MockRenderFunctions()
	MockReloadProfile()

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.SetActiveProfile()

	AreEqual("Raid", SoundtrackAddon.db._loadedProfile(), "SetProfile called with selected profile")
end

function Tests:SetActiveProfile_CallsReloadProfile()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	MockRenderFunctions()
	local called = false
	Replace(Soundtrack.ProfilesTab, "ReloadProfile", function() called = true end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.SetActiveProfile()

	IsTrue(called, "ReloadProfile called after SetActiveProfile")
end

function Tests:SetActiveProfile_DoesNothingIfNoProfileSelected()
	SetupChat()
	SetupProfileDb()
	MockRenderFunctions()
	MockReloadProfile()

	-- Force selectedProfile to nil by selecting then clearing
	-- We can do this by calling SelectProfile with nil (even though that's unusual)
	-- Actually we can just test the guard: if selectedProfile is nil, db:SetProfile should not be called
	-- We reset via a fresh SetupProfileDb and trust the previous test set something.
	-- Instead, call SetActiveProfile when we know selectedProfile won't match anything:
	Soundtrack.ProfilesTab.SelectProfile(nil)
	Soundtrack.ProfilesTab.SetActiveProfile()

	AreEqual(nil, SoundtrackAddon.db._loadedProfile(), "SetProfile not called when no profile selected")
end

-- ─────────────────────────────────────────────────────────────
-- DuplicateProfile
-- ─────────────────────────────────────────────────────────────

function Tests:DuplicateProfile_CreatesCopyWithSuffix()
	SetupChat()
	local profiles = { "Default", "Raid" }
	SetupProfileDb(profiles, "Default")
	MockRenderFunctions()
	MockRefreshProfilesFrame()

	if not _G.HasValue then
		_G.HasValue = function(t, v)
			for _, val in ipairs(t) do
				if val == v then return true end
			end
			return false
		end
	end

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.DuplicateProfile()

	-- db:SetProfile("Raid (Copy)") then db:CopyProfile("Raid") then db:SetProfile("Default")
	AreEqual("Raid", SoundtrackAddon.db._copiedFrom(), "CopyProfile called with original profile name")
end

function Tests:DuplicateProfile_RestoresActiveProfile()
	SetupChat()
	local profiles = { "Default", "Raid" }
	SetupProfileDb(profiles, "Default")
	MockRenderFunctions()
	MockRefreshProfilesFrame()

	if not _G.HasValue then
		_G.HasValue = function(t, v)
			for _, val in ipairs(t) do
				if val == v then return true end
			end
			return false
		end
	end

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.DuplicateProfile()

	-- After duplicate, SetProfile should have been called last with the original active profile
	AreEqual("Default", SoundtrackAddon.db._loadedProfile(), "Active profile restored after duplicate")
end

function Tests:DuplicateProfile_DoesNothingIfNoProfileSelected()
	SetupChat()
	SetupProfileDb()
	MockRenderFunctions()
	MockRefreshProfilesFrame()

	Soundtrack.ProfilesTab.SelectProfile(nil)
	Soundtrack.ProfilesTab.DuplicateProfile()

	AreEqual(nil, SoundtrackAddon.db._copiedFrom(), "CopyProfile not called when no profile selected")
end

-- ─────────────────────────────────────────────────────────────
-- ShowRenameProfileDialog
-- ─────────────────────────────────────────────────────────────

function Tests:ShowRenameProfileDialog_ShowsStaticPopup()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	MockRenderFunctions()
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.ShowRenameProfileDialog()

	AreEqual("PROFILES_RENAME", shown, "PROFILES_RENAME popup shown")
end

function Tests:ShowRenameProfileDialog_DoesNothingIfNoProfileSelected()
	SetupChat()
	SetupProfileDb()
	MockRenderFunctions()
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	Soundtrack.ProfilesTab.ShowRenameProfileDialog()

	AreEqual(nil, shown, "No popup when nothing is selected")
end

function Tests:ShowRenameProfileDialog_OnAccept_RenamesProfile()
	SetupChat()
	local profiles = { "Default", "Raid" }
	SetupProfileDb(profiles, "Default")
	MockRenderFunctions()
	MockReloadProfile()
	Replace(_G, "StaticPopup_Show", function() end)
	if not _G.HasValue then
		_G.HasValue = function(t, v)
			for _, val in ipairs(t) do
				if val == v then return true end
			end
			return false
		end
	end

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.ShowRenameProfileDialog()

	local mockDialog = {
		GetEditBox = function() return { GetText = function() return "PvP" end } end,
	}
	StaticPopupDialogs["PROFILES_RENAME"].OnAccept(mockDialog)

	-- Should have switched to "PvP", copied from "Raid", restored "Default", deleted "Raid"
	AreEqual("Default", SoundtrackAddon.db._loadedProfile(), "Active profile restored after rename")
	AreEqual("Raid", SoundtrackAddon.db._copiedFrom(), "CopyProfile called with old profile name")
	AreEqual("Raid", SoundtrackAddon.db._deletedProfile(), "Old profile deleted")
end

-- ─────────────────────────────────────────────────────────────
-- RenameSelectedProfile
-- ─────────────────────────────────────────────────────────────

local function SetupHasValue()
	_G.HasValue = function(t, v)
		for _, val in ipairs(t) do
			if val == v then return true end
		end
		return false
	end
end

function Tests:RenameSelectedProfile_DoesNothingIfNoSelection()
	SetupChat()
	SetupProfileDb({ "Default" }, "Default")
	MockRenderFunctions()
	MockReloadProfile()
	SetupHasValue()
	Replace(_G, "StaticPopup_Show", function() end)

	Soundtrack.ProfilesTab.RenameSelectedProfile("NewName")

	AreEqual(nil, SoundtrackAddon.db._loadedProfile(), "SetProfile not called when nothing selected")
end

function Tests:RenameSelectedProfile_DoesNothingIfNewNameEmpty()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	MockRenderFunctions()
	MockReloadProfile()
	SetupHasValue()
	Replace(_G, "StaticPopup_Show", function() end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.RenameSelectedProfile("")

	AreEqual(nil, SoundtrackAddon.db._loadedProfile(), "SetProfile not called for empty name")
end

function Tests:RenameSelectedProfile_DoesNothingIfNameUnchanged()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	MockRenderFunctions()
	MockReloadProfile()
	SetupHasValue()
	Replace(_G, "StaticPopup_Show", function() end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.RenameSelectedProfile("Raid")

	AreEqual(nil, SoundtrackAddon.db._loadedProfile(), "SetProfile not called when name unchanged")
end

function Tests:RenameSelectedProfile_ShowsErrorIfNameAlreadyExists()
	SetupChat()
	SetupProfileDb({ "Default", "Raid", "PvP" }, "Default")
	MockRenderFunctions()
	MockReloadProfile()
	SetupHasValue()
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.RenameSelectedProfile("PvP")

	AreEqual("PROFILE_ALREADY_EXISTS", shown, "Error dialog shown for existing name")
end

function Tests:RenameSelectedProfile_NonActiveProfile_CopiesAndRestoresActive()
	SetupChat()
	local profiles = { "Default", "Raid" }
	SetupProfileDb(profiles, "Default")
	MockRenderFunctions()
	MockRefreshProfilesFrame()
	SetupHasValue()
	Replace(_G, "StaticPopup_Show", function() end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.RenameSelectedProfile("PvP")

	AreEqual("Default", SoundtrackAddon.db._loadedProfile(), "Active profile restored after rename")
	AreEqual("Raid", SoundtrackAddon.db._copiedFrom(), "CopyProfile called with old name")
	AreEqual("Raid", SoundtrackAddon.db._deletedProfile(), "Old profile deleted")
end

function Tests:RenameSelectedProfile_NonActiveProfile_SetsSelectedToNewName()
	SetupChat()
	local profiles = { "Default", "Raid" }
	SetupProfileDb(profiles, "Default")
	MockRenderFunctions()
	MockRefreshProfilesFrame()
	SetupHasValue()
	Replace(_G, "StaticPopup_Show", function() end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.RenameSelectedProfile("PvP")

	AreEqual("PvP", Soundtrack.ProfilesTab.GetSelectedProfile(), "selectedProfile updated to new name")
end

function Tests:RenameSelectedProfile_ActiveProfile_SwitchesToNewNameAndReloads()
	SetupChat()
	local profiles = { "Default" }
	SetupProfileDb(profiles, "Default")
	MockRenderFunctions()
	MockReloadProfile()
	SetupHasValue()
	Replace(_G, "StaticPopup_Show", function() end)

	Soundtrack.ProfilesTab.SelectProfile("Default")
	Soundtrack.ProfilesTab.RenameSelectedProfile("MyDefault")

	AreEqual("Default", SoundtrackAddon.db._deletedProfile(), "Old active profile deleted")
	AreEqual("MyDefault", Soundtrack.ProfilesTab.GetSelectedProfile(), "selectedProfile updated to new name")
end

-- ─────────────────────────────────────────────────────────────
-- ShowNewProfileDialog
-- ─────────────────────────────────────────────────────────────

function Tests:ShowNewProfileDialog_ShowsStaticPopup()
	SetupChat()
	SetupProfileDb()
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	Soundtrack.ProfilesTab.ShowNewProfileDialog()

	AreEqual("PROFILES_NEW", shown, "PROFILES_NEW popup shown")
end

function Tests:ShowNewProfileDialog_OnAccept_ReadsProfileNameFromGetEditBox()
	SetupChat()
	local profiles = { "Default" }
	SetupProfileDb(profiles, "Default")
	MockRenderFunctions()
	MockReloadProfile()
	Replace(_G, "StaticPopup_Show", function() end)
	if not _G.HasValue then
		_G.HasValue = function(t, v)
			for _, val in ipairs(t) do
				if val == v then return true end
			end
			return false
		end
	end

	-- Call ShowNewProfileDialog to register the dialog definition
	Soundtrack.ProfilesTab.ShowNewProfileDialog()

	-- Simulate WoW calling OnAccept(dialog, ...) with a dialog frame that has GetEditBox()
	local mockDialog = {
		GetEditBox = function() return { GetText = function() return "Yo" end } end,
	}
	StaticPopupDialogs["PROFILES_NEW"].OnAccept(mockDialog)

	AreEqual("Yo", SoundtrackAddon.db._loadedProfile(), "New profile created with the name from GetEditBox()")
end

-- ─────────────────────────────────────────────────────────────
-- CreateNewProfile
-- ─────────────────────────────────────────────────────────────

function Tests:CreateNewProfile_CreatesProfileWithGivenName()
	SetupChat()
	local profiles = { "Default" }
	SetupProfileDb(profiles, "Default")
	MockRenderFunctions()
	MockReloadProfile()
	Replace(_G, "StaticPopup_Show", function() end)

	if not _G.HasValue then
		_G.HasValue = function(t, v)
			for _, val in ipairs(t) do
				if val == v then return true end
			end
			return false
		end
	end

	Soundtrack.ProfilesTab.CreateNewProfile("MyNewProfile")

	AreEqual("MyNewProfile", SoundtrackAddon.db._loadedProfile(), "New profile set as current")
end

function Tests:CreateNewProfile_ShowsErrorWhenProfileAlreadyExists()
	SetupChat()
	local profiles = { "Default", "Existing" }
	SetupProfileDb(profiles, "Default")
	MockRenderFunctions()
	MockReloadProfile()
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	if not _G.HasValue then
		_G.HasValue = function(t, v)
			for _, val in ipairs(t) do
				if val == v then return true end
			end
			return false
		end
	end

	Soundtrack.ProfilesTab.CreateNewProfile("Existing")

	AreEqual("PROFILE_ALREADY_EXISTS", shown, "Error dialog shown for existing profile name")
end

-- ─────────────────────────────────────────────────────────────
-- DeleteSelectedProfile
-- ─────────────────────────────────────────────────────────────

function Tests:DeleteSelectedProfile_ShowsConfirmDialog()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	MockRenderFunctions()
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.DeleteSelectedProfile()

	AreEqual("PROFILES_DELETE_CONFIRM", shown, "Delete confirm dialog shown")
end

function Tests:DeleteSelectedProfile_DeletesProfileOnAccept()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	MockRenderFunctions()
	MockRefreshProfilesFrame()
	Replace(_G, "StaticPopup_Show", function() end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.DeleteSelectedProfile()
	StaticPopupDialogs["PROFILES_DELETE_CONFIRM"].OnAccept()

	AreEqual("Raid", SoundtrackAddon.db._deletedProfile(), "Profile deleted on accept")
end

function Tests:DeleteSelectedProfile_DoesNothingWhenNoProfileSelected()
	SetupChat()
	SetupProfileDb()
	MockRenderFunctions()
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	Soundtrack.ProfilesTab.SelectProfile(nil)
	Soundtrack.ProfilesTab.DeleteSelectedProfile()

	AreEqual(nil, shown, "No dialog shown when no profile is selected")
end

function Tests:DeleteSelectedProfile_DoesNothingForActiveProfile()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	MockRenderFunctions()
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	-- Try to delete the active profile
	Soundtrack.ProfilesTab.SelectProfile("Default")
	Soundtrack.ProfilesTab.DeleteSelectedProfile()

	AreEqual(nil, shown, "No dialog shown when attempting to delete the active profile")
end

-- ─────────────────────────────────────────────────────────────
-- ReloadProfile
-- ─────────────────────────────────────────────────────────────

function Tests:ReloadProfile_SetsTracksLoadedToFalse()
	Soundtrack.TracksLoaded = true
	Replace(SoundtrackAddon, "PLAYER_ENTERING_WORLD", function() end)
	MockRefreshProfilesFrame()

	Soundtrack.ProfilesTab.ReloadProfile()

	IsFalse(Soundtrack.TracksLoaded, "TracksLoaded set to false")
end

function Tests:ReloadProfile_CallsPlayerEnteringWorld()
	local called = false
	Replace(SoundtrackAddon, "PLAYER_ENTERING_WORLD", function() called = true end)
	MockRefreshProfilesFrame()

	Soundtrack.ProfilesTab.ReloadProfile()

	IsTrue(called, "PLAYER_ENTERING_WORLD called on SoundtrackAddon")
end

function Tests:ReloadProfile_CallsRefreshProfilesFrame()
	local called = false
	Replace(SoundtrackAddon, "PLAYER_ENTERING_WORLD", function() end)
	Replace(Soundtrack.ProfilesTab, "RefreshProfilesFrame", function() called = true end)

	Soundtrack.ProfilesTab.ReloadProfile()

	IsTrue(called, "RefreshProfilesFrame called after reload")
end

-- ─────────────────────────────────────────────────────────────
-- RefreshProfilesFrame
-- ─────────────────────────────────────────────────────────────

function Tests:RefreshProfilesFrame_CallsPopulateProfileList()
	SetupProfileDb({ "Default" }, "Default")
	local called = false
	Replace(Soundtrack.ProfilesTab, "PopulateProfileList", function() called = true end)
	Replace(Soundtrack.ProfilesTab, "RefreshDetailsPanel", function() end)

	Soundtrack.ProfilesTab.RefreshProfilesFrame()

	IsTrue(called, "PopulateProfileList called by RefreshProfilesFrame")
end

function Tests:RefreshProfilesFrame_CallsRefreshDetailsPanel()
	SetupProfileDb({ "Default" }, "Default")
	local called = false
	Replace(Soundtrack.ProfilesTab, "PopulateProfileList", function() end)
	Replace(Soundtrack.ProfilesTab, "RefreshDetailsPanel", function() called = true end)

	Soundtrack.ProfilesTab.RefreshProfilesFrame()

	IsTrue(called, "RefreshDetailsPanel called by RefreshProfilesFrame")
end

-- ─────────────────────────────────────────────────────────────
-- RefreshDetailsPanel
-- ─────────────────────────────────────────────────────────────

function Tests:RefreshDetailsPanel_SetsDetailNameText()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	-- Set up UI globals that the real RefreshDetailsPanel reads
	local textSet = nil
	_G["ProfilesTab_DetailName"] = { SetText = function(_, text) textSet = text end }
	_G["ProfilesTab_ActiveBadge"] = { SetShown = function() end, SetTextColor = function() end }
	Replace(Soundtrack.ProfilesTab, "PopulateProfileList", function() end)
	Replace(Soundtrack.ProfilesTab, "RefreshProfileListHighlight", function() end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")

	AreEqual("Raid", textSet, "ProfilesTab_DetailName set to selected profile")
end

function Tests:RefreshDetailsPanel_DisablesSetActiveButtonForActiveProfile()
	SetupChat()
	SetupProfileDb({ "Default" }, "Default")
	local enabledValue = nil
	_G["ProfilesTab_DetailName"] = { SetText = function() end }
	_G["ProfilesTab_ActiveBadge"] = { SetShown = function() end, SetTextColor = function() end }
	_G["ProfilesTab_SetActiveButton"] = { SetEnabled = function(_, val) enabledValue = val end }
	_G["ProfilesTab_DeleteButton"] = { SetEnabled = function() end }
	Replace(Soundtrack.ProfilesTab, "PopulateProfileList", function() end)
	Replace(Soundtrack.ProfilesTab, "RefreshProfileListHighlight", function() end)

	Soundtrack.ProfilesTab.SelectProfile("Default")

	IsFalse(enabledValue, "Set Active button disabled when selected profile is the active profile")
end

function Tests:RefreshDetailsPanel_EnablesSetActiveButtonForNonActiveProfile()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	local enabledValue = nil
	_G["ProfilesTab_DetailName"] = { SetText = function() end }
	_G["ProfilesTab_ActiveBadge"] = { SetShown = function() end, SetTextColor = function() end }
	_G["ProfilesTab_SetActiveButton"] = { SetEnabled = function(_, val) enabledValue = val end }
	_G["ProfilesTab_DeleteButton"] = { SetEnabled = function() end }
	Replace(Soundtrack.ProfilesTab, "PopulateProfileList", function() end)
	Replace(Soundtrack.ProfilesTab, "RefreshProfileListHighlight", function() end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")

	IsTrue(enabledValue, "Set Active button enabled for non-active profile")
end

-- ─────────────────────────────────────────────────────────────
-- ExportSelectedProfile
-- ─────────────────────────────────────────────────────────────

function Tests:ExportSelectedProfile_CallsOpenForExportWithSelectedProfile()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	MockRenderFunctions()

	local exportedProfile = nil
	Replace(Soundtrack.ExportImportDialog, "OpenForExport", function(name) exportedProfile = name end)

	Soundtrack.ProfilesTab.SelectProfile("Raid")
	Soundtrack.ProfilesTab.ExportSelectedProfile()

	AreEqual("Raid", exportedProfile, "OpenForExport called with the selected profile")
end

function Tests:ExportSelectedProfile_FallsBackToActiveProfileWhenNothingSelected()
	SetupChat()
	SetupProfileDb({ "Default" }, "Default")
	MockRenderFunctions()

	local exportedProfile = nil
	Replace(Soundtrack.ExportImportDialog, "OpenForExport", function(name) exportedProfile = name end)

	-- Do not call SelectProfile so selectedProfile stays nil
	Soundtrack.ProfilesTab.ExportSelectedProfile()

	AreEqual("Default", exportedProfile, "Falls back to active profile when nothing is selected")
end
