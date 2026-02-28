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
