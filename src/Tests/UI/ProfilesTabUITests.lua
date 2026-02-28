if not Tests then
	return
end

local Tests = Tests("ProfilesTabUI", "PLAYER_ENTERING_WORLD")

local function SetupChat()
	Soundtrack.Chat.TraceProfiles = function() end
end

local function SetupProfileDb(profiles, currentProfile)
	profiles = profiles or { "Default", "Raid" }
	currentProfile = currentProfile or "Default"
	local copiedFrom = nil
	local deletedProfile = nil
	local loadedProfile = nil
	local resetCalled = false

	SoundtrackAddon.db.GetProfiles = function(self) return profiles end
	SoundtrackAddon.db.GetCurrentProfile = function(self) return currentProfile end
	SoundtrackAddon.db.SetProfile = function(self, name) loadedProfile = name; currentProfile = name end
	SoundtrackAddon.db.CopyProfile = function(self, name) copiedFrom = name end
	SoundtrackAddon.db.DeleteProfile = function(self, name) deletedProfile = name end
	SoundtrackAddon.db.ResetProfile = function(self) resetCalled = true end

	-- Expose for test assertions
	SoundtrackAddon.db._copiedFrom = function() return copiedFrom end
	SoundtrackAddon.db._deletedProfile = function() return deletedProfile end
	SoundtrackAddon.db._loadedProfile = function() return loadedProfile end
	SoundtrackAddon.db._resetCalled = function() return resetCalled end
end

local function MockReloadProfile()
	Replace(Soundtrack.ProfilesTab, "ReloadProfile", function() end)
end

local function MockRefreshProfilesFrame()
	Replace(Soundtrack.ProfilesTab, "RefreshProfilesFrame", function() end)
end

-- CopyFromProfileDropDownItemSelected Tests

function Tests:CopyFromProfileDropDownItemSelected_ShowsConfirmDialog()
	SetupChat()
	SetupProfileDb()
	MockReloadProfile()
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	Soundtrack.ProfilesTab.CopyFromProfileDropDownItemSelected(nil, "Raid")

	AreEqual("PROFILES_COPY_CONFIRM", shown, "Confirm dialog shown with correct key")
end

function Tests:CopyFromProfileDropDownItemSelected_CopiesProfileOnAccept()
	SetupChat()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	MockReloadProfile()
	Replace(_G, "StaticPopup_Show", function() end)

	Soundtrack.ProfilesTab.CopyFromProfileDropDownItemSelected(nil, "Raid")
	StaticPopupDialogs["PROFILES_COPY_CONFIRM"].OnAccept()

	AreEqual("Raid", SoundtrackAddon.db._copiedFrom(), "Profile copied from 'Raid' on accept")
end

-- DeleteProfileDropDownItemSelected Tests

function Tests:DeleteProfileDropDownItemSelected_ShowsConfirmDialog()
	SetupChat()
	SetupProfileDb()
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	Soundtrack.ProfilesTab.DeleteProfileDropDownItemSelected(nil, "Raid")

	AreEqual("PROFILES_DELETE_CONFIRM", shown, "Delete confirm dialog shown")
end

function Tests:DeleteProfileDropDownItemSelected_DeletesProfileOnAccept()
	SetupChat()
	SetupProfileDb()
	Replace(_G, "StaticPopup_Show", function() end)

	Soundtrack.ProfilesTab.DeleteProfileDropDownItemSelected(nil, "Raid")
	StaticPopupDialogs["PROFILES_DELETE_CONFIRM"].OnAccept()

	AreEqual("Raid", SoundtrackAddon.db._deletedProfile(), "Profile deleted on accept")
end

-- LoadProfileDropDownItemSelected Tests

function Tests:LoadProfileDropDownItemSelected_LoadsSelectedProfile()
	SetupChat()
	SetupProfileDb()
	MockReloadProfile()

	Soundtrack.ProfilesTab.LoadProfileDropDownItemSelected(nil, "Raid")

	AreEqual("Raid", SoundtrackAddon.db._loadedProfile(), "Profile loaded via SetProfile")
end

-- CreateNewProfile Tests

function Tests:CreateNewProfile_CreatesProfileWithGivenName()
	SetupChat()
	local profiles = { "Default" }
	SetupProfileDb(profiles, "Default")
	MockReloadProfile()
	Replace(_G, "StaticPopup_Show", function() end)

	_G["NewProfileEditBox"] = {
		GetText = function() return "MyNewProfile" end,
		SetText = function() end,
	}

	-- HasValue needs to be available
	if not _G.HasValue then
		_G.HasValue = function(t, v)
			for _, val in ipairs(t) do
				if val == v then return true end
			end
			return false
		end
	end

	Soundtrack.ProfilesTab.CreateNewProfile()

	AreEqual("MyNewProfile", SoundtrackAddon.db._loadedProfile(), "New profile set as current")
end

function Tests:CreateNewProfile_ShowsErrorWhenProfileAlreadyExists()
	SetupChat()
	local profiles = { "Default", "Existing" }
	SetupProfileDb(profiles, "Default")
	MockReloadProfile()
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	_G["NewProfileEditBox"] = {
		GetText = function() return "Existing" end,
		SetText = function() end,
	}

	if not _G.HasValue then
		_G.HasValue = function(t, v)
			for _, val in ipairs(t) do
				if val == v then return true end
			end
			return false
		end
	end

	Soundtrack.ProfilesTab.CreateNewProfile()

	AreEqual("PROFILE_ALREADY_EXISTS", shown, "Error dialog shown for existing profile name")
end

-- ResetCurrentProfile Tests

function Tests:ResetCurrentProfile_ShowsConfirmDialog()
	SetupChat()
	SetupProfileDb({ "Default" }, "Default")
	local shown = nil
	Replace(_G, "StaticPopup_Show", function(key) shown = key end)

	Soundtrack.ProfilesTab.ResetCurrentProfile()

	AreEqual("PROFILES_RESET_CONFIRM", shown, "Reset confirm dialog shown")
end

function Tests:ResetCurrentProfile_ResetsProfileOnAccept()
	SetupChat()
	SetupProfileDb({ "Default" }, "Default")
	MockReloadProfile()
	Replace(_G, "StaticPopup_Show", function() end)

	Soundtrack.ProfilesTab.ResetCurrentProfile()
	StaticPopupDialogs["PROFILES_RESET_CONFIRM"].OnAccept()

	IsTrue(SoundtrackAddon.db._resetCalled(), "ResetProfile called on accept")
end

-- ReloadProfile Tests

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

-- RefreshProfilesFrame Tests

function Tests:RefreshProfilesFrame_SetsCurrentProfileName()
	SetupProfileDb({ "Default", "Raid" }, "Raid")
	local textSet = nil
	_G["CurrentProfileName"] = { SetText = function(_, text) textSet = text end }

	Soundtrack.ProfilesTab.RefreshProfilesFrame()

	AreEqual("Raid", textSet, "CurrentProfileName set to current profile")
end

-- InitDropDown Tests

function Tests:InitDropDown_AddsAllProfilesWhenNotSkipping()
	SetupProfileDb({ "Default", "Raid", "Casual" }, "Default")
	local added = {}
	Replace(_G, "UIDropDownMenu_CreateInfo", function() return {} end)
	Replace(_G, "UIDropDownMenu_AddButton", function(info) table.insert(added, info.text) end)

	Soundtrack.ProfilesTab.InitDropDown(function() end, false)

	AreEqual(3, #added, "All 3 profiles added when not skipping current")
end

function Tests:InitDropDown_SkipsCurrentProfileWhenRequested()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	local added = {}
	Replace(_G, "UIDropDownMenu_CreateInfo", function() return {} end)
	Replace(_G, "UIDropDownMenu_AddButton", function(info) table.insert(added, info.text) end)

	Soundtrack.ProfilesTab.InitDropDown(function() end, true)

	AreEqual(1, #added, "Only non-current profile added when skipping current")
	AreEqual("Raid", added[1], "Raid added (Default skipped)")
end

function Tests:InitDropDown_ChecksCurrentProfile()
	SetupProfileDb({ "Default", "Raid" }, "Default")
	local checkedStates = {}
	Replace(_G, "UIDropDownMenu_CreateInfo", function() return {} end)
	Replace(_G, "UIDropDownMenu_AddButton", function(info)
		table.insert(checkedStates, { name = info.text, checked = info.checked })
	end)

	Soundtrack.ProfilesTab.InitDropDown(function() end, false)

	local defaultEntry = nil
	local raidEntry = nil
	for _, entry in ipairs(checkedStates) do
		if entry.name == "Default" then defaultEntry = entry end
		if entry.name == "Raid" then raidEntry = entry end
	end
	IsTrue(defaultEntry and defaultEntry.checked, "Default profile is checked")
	IsFalse(raidEntry and raidEntry.checked, "Raid profile is not checked")
end

-- OnLoad Tests

function Tests:OnLoad_SetsDropDownTexts()
	_G["LoadProfileDropDown"] = { initialize = nil }
	_G["LoadProfileDropDownText"] = { SetText = function(self, t) self._text = t end, _text = "" }
	_G["CopyFromProfileDropDown"] = { initialize = nil }
	_G["CopyFromProfileDropDownText"] = { SetText = function(self, t) self._text = t end, _text = "" }
	_G["DeleteProfileDropDown"] = { initialize = nil }
	_G["DeleteProfileDropDownText"] = { SetText = function(self, t) self._text = t end, _text = "" }

	Soundtrack.ProfilesTab.OnLoad()

	AreEqual("Load Profile", _G["LoadProfileDropDownText"]._text, "Load Profile text set")
	AreEqual("Copy From", _G["CopyFromProfileDropDownText"]._text, "Copy From text set")
	AreEqual("Delete Profile", _G["DeleteProfileDropDownText"]._text, "Delete Profile text set")
end
