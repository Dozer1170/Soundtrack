Soundtrack.ProfilesTab = {}

local PROFILES_DELETE_CONFIRM = "PROFILES_DELETE_CONFIRM"
local PROFILES_NEW = "PROFILES_NEW"
local PROFILES_RENAME = "PROFILES_RENAME"
local PROFILE_ALREADY_EXISTS = "PROFILE_ALREADY_EXISTS"

-- The profile currently highlighted in the left-column list (not necessarily active).
local selectedProfile = nil

-- Pool of dynamically-created profile list buttons, keyed by index.
local profileListButtons = {}

-- ─────────────────────────────────────────────────────────────
-- Initialisation
-- ─────────────────────────────────────────────────────────────

function Soundtrack.ProfilesTab.OnLoad()
	-- Nothing to initialise for dropdowns any more.
	-- The search box OnTextChanged handler is wired directly in XML.
end

-- ─────────────────────────────────────────────────────────────
-- Profile selection (left column)
-- ─────────────────────────────────────────────────────────────

--- Highlight a profile in the list and update the details panel.
function Soundtrack.ProfilesTab.SelectProfile(profileName)
	selectedProfile = profileName
	Soundtrack.Chat.TraceProfiles("Selected profile: " .. tostring(profileName))
	Soundtrack.ProfilesTab.RefreshProfileListHighlight()
	Soundtrack.ProfilesTab.RefreshDetailsPanel()
end

--- Returns the currently highlighted (selected) profile name.
function Soundtrack.ProfilesTab.GetSelectedProfile()
	return selectedProfile
end

-- ─────────────────────────────────────────────────────────────
-- Profile list (left column)
-- ─────────────────────────────────────────────────────────────

--- Rebuild the scrollable profile list.
function Soundtrack.ProfilesTab.PopulateProfileList()
	local scrollChild = ProfilesTab_ScrollChild
	if not scrollChild then
		return
	end

	local profiles = SoundtrackAddon.db:GetProfiles()
	local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
	local rowHeight = 24
	local yOffset = 0
	local visibleIndex = 0

	for _, profileName in ipairs(profiles) do
		visibleIndex = visibleIndex + 1

		-- Reuse or create a button for this row.
		-- Buttons must be named so $parent children become accessible globals.
		local btnName = "ProfilesTab_ListItem" .. visibleIndex
		if not profileListButtons[visibleIndex] then
			local btn = CreateFrame("Button", btnName, scrollChild, "ProfilesTab_ListItemTemplate")
			-- Cache child font string references on the button for fast access.
			btn.profileNameText = _G[btnName .. "ProfileNameText"]
			btn.activeArrow = _G[btnName .. "ActiveArrow"]
			profileListButtons[visibleIndex] = btn
		end

		local btn = profileListButtons[visibleIndex]
		btn.profileName = profileName
		btn:SetPoint("TOPLEFT", scrollChild, "TOPLEFT", 0, -yOffset)
		btn:Show()

		-- Label text
		if btn.profileNameText then
			btn.profileNameText:SetText(profileName)
		end

		-- Active arrow visibility
		if btn.activeArrow then
			btn.activeArrow:SetShown(profileName == currentProfile)
		end

		-- Selected highlight (colour the button text gold if selected)
		if btn.profileNameText then
			if profileName == selectedProfile then
				btn.profileNameText:SetTextColor(1, 0.82, 0, 1)
			else
				btn.profileNameText:SetTextColor(1, 1, 1, 1)
			end
		end

		yOffset = yOffset + rowHeight
	end

	-- Hide unused buttons
	for i = visibleIndex + 1, #profileListButtons do
		profileListButtons[i]:Hide()
	end

	-- Resize scroll child to fit content
	scrollChild:SetHeight(math.max(rowHeight, visibleIndex * rowHeight))
end

--- Update only the highlight / active-arrow state without rebuilding buttons.
function Soundtrack.ProfilesTab.RefreshProfileListHighlight()
	local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
	for _, btn in ipairs(profileListButtons) do
		if btn:IsShown() then
			if btn.activeArrow then
				btn.activeArrow:SetShown(btn.profileName == currentProfile)
			end
			if btn.profileNameText then
				if btn.profileName == selectedProfile then
					btn.profileNameText:SetTextColor(1, 0.82, 0, 1)
				else
					btn.profileNameText:SetTextColor(1, 1, 1, 1)
				end
			end
		end
	end
end

-- ─────────────────────────────────────────────────────────────
-- Right-column detail panel
-- ─────────────────────────────────────────────────────────────

--- Refresh the right-column detail panel to reflect `selectedProfile`.
function Soundtrack.ProfilesTab.RefreshDetailsPanel()
	local profile = selectedProfile or SoundtrackAddon.db:GetCurrentProfile()
	local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
	local isActive = (profile == currentProfile)

	if ProfilesTab_DetailName then
		ProfilesTab_DetailName:SetText(profile)
	end

	if ProfilesTab_ActiveBadge then
		ProfilesTab_ActiveBadge:SetShown(isActive)
	end

	-- "Set Active" is disabled when the profile is already active.
	if ProfilesTab_SetActiveButton then
		ProfilesTab_SetActiveButton:SetEnabled(not isActive)
	end

	-- Cannot delete the active profile.
	if ProfilesTab_DeleteButton then
		ProfilesTab_DeleteButton:SetEnabled(not isActive)
	end
end

-- ─────────────────────────────────────────────────────────────
-- Primary actions (right column)
-- ─────────────────────────────────────────────────────────────

--- Make the currently highlighted profile the active one.
function Soundtrack.ProfilesTab.SetActiveProfile()
	local profile = selectedProfile
	if not profile then
		return
	end
	Soundtrack.Chat.TraceProfiles("Setting active profile: " .. profile)
	SoundtrackAddon.db:SetProfile(profile)
	Soundtrack.ProfilesTab.ReloadProfile()
end

--- Duplicate the currently highlighted profile (appends " (Copy)" suffix).
function Soundtrack.ProfilesTab.DuplicateProfile()
	local profile = selectedProfile
	if not profile then
		return
	end

	local profiles = SoundtrackAddon.db:GetProfiles()
	local copyName = profile .. " (Copy)"

	-- Ensure the name is unique.
	if HasValue(profiles, copyName) then
		local i = 2
		while HasValue(profiles, copyName .. " " .. i) do
			i = i + 1
		end
		copyName = copyName .. " " .. i
	end

	Soundtrack.Chat.TraceProfiles("Duplicating profile '" .. profile .. "' as '" .. copyName .. "'")

	local activeProfile = SoundtrackAddon.db:GetCurrentProfile()

	-- Create the copy by switching to it and then copying settings from the original.
	SoundtrackAddon.db:SetProfile(copyName)
	SoundtrackAddon.db:CopyProfile(profile)

	-- Restore the previously active profile (no full event-reload needed).
	SoundtrackAddon.db:SetProfile(activeProfile)

	-- Refresh the list so the new copy appears.
	Soundtrack.ProfilesTab.RefreshProfilesFrame()
end

-- ─────────────────────────────────────────────────────────────
-- Rename profile dialog
-- ─────────────────────────────────────────────────────────────

--- Open a popup to rename the currently selected profile.
function Soundtrack.ProfilesTab.ShowRenameProfileDialog()
	local profile = selectedProfile
	if not profile then
		return
	end
	StaticPopupDialogs[PROFILES_RENAME] = {
		text = 'Rename "' .. profile .. '" to:',
		button1 = "Rename",
		button2 = "Cancel",
		hasEditBox = true,
		maxLetters = 50,
		OnShow = function(self)
			local eb = self:GetEditBox()
			if eb then
				eb:SetText(profile)
				eb:HighlightText()
			end
		end,
		OnAccept = function(self)
			local eb = self:GetEditBox()
			local newName = eb and eb:GetText() or ""
			Soundtrack.ProfilesTab.RenameSelectedProfile(newName)
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show(PROFILES_RENAME)
end

--- Rename the currently selected profile to `newName`.
function Soundtrack.ProfilesTab.RenameSelectedProfile(newName)
	local oldName = selectedProfile
	if not oldName or not newName or newName == "" then
		return
	end
	if newName == oldName then
		return
	end

	local profiles = SoundtrackAddon.db:GetProfiles()
	if HasValue(profiles, newName) then
		StaticPopupDialogs[PROFILE_ALREADY_EXISTS] = {
			text = "A profile named '" .. tostring(newName) .. "' already exists.",
			button1 = "Ok",
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show(PROFILE_ALREADY_EXISTS)
		return
	end

	Soundtrack.Chat.TraceProfiles("Renaming profile '" .. oldName .. "' to '" .. newName .. "'")

	local currentActive = SoundtrackAddon.db:GetCurrentProfile()
	local renamingActive = (oldName == currentActive)

	-- Create newName, copy oldName into it.
	SoundtrackAddon.db:SetProfile(newName)
	SoundtrackAddon.db:CopyProfile(oldName)

	if renamingActive then
		-- oldName was active; newName is now active. Just delete the old one.
		SoundtrackAddon.db:DeleteProfile(oldName)
		selectedProfile = newName
		Soundtrack.ProfilesTab.ReloadProfile()
	else
		-- Restore the real active profile, then delete the old name.
		SoundtrackAddon.db:SetProfile(currentActive)
		SoundtrackAddon.db:DeleteProfile(oldName)
		selectedProfile = newName
		Soundtrack.ProfilesTab.RefreshProfilesFrame()
	end
end

--- Open a native popup to name and create a new profile.
function Soundtrack.ProfilesTab.ShowNewProfileDialog()
	StaticPopupDialogs[PROFILES_NEW] = {
		text = "Enter a name for the new profile:",
		button1 = "Create",
		button2 = "Cancel",
		hasEditBox = true,
		maxLetters = 50,
		OnAccept = function(self)
			local editBox = self:GetEditBox()
			local name = editBox and editBox:GetText() or ""
			Soundtrack.ProfilesTab.CreateNewProfile(name)
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show(PROFILES_NEW)
end

--- Create a new profile with the given name and make it active.
function Soundtrack.ProfilesTab.CreateNewProfile(profileName)
	Soundtrack.Chat.TraceProfiles("Requested to create new profile: " .. tostring(profileName))

	local profiles = SoundtrackAddon.db:GetProfiles()
	if HasValue(profiles, profileName) then
		StaticPopupDialogs[PROFILE_ALREADY_EXISTS] = {
			text = "A profile named '" .. tostring(profileName) .. "' already exists.",
			button1 = "Ok",
			timeout = 0,
			whileDead = true,
			hideOnEscape = true,
		}
		StaticPopup_Show(PROFILE_ALREADY_EXISTS)
		return
	end

	SoundtrackAddon.db:SetProfile(profileName)
	selectedProfile = profileName
	Soundtrack.ProfilesTab.ReloadProfile()
end

-- ─────────────────────────────────────────────────────────────
-- Danger Zone
-- ─────────────────────────────────────────────────────────────

--- Confirm and permanently delete the currently highlighted profile.
--- The active profile cannot be deleted.
function Soundtrack.ProfilesTab.DeleteSelectedProfile()
	local profile = selectedProfile
	if not profile then
		return
	end
	local currentProfile = SoundtrackAddon.db:GetCurrentProfile()
	if profile == currentProfile then
		return
	end

	Soundtrack.Chat.TraceProfiles("Requesting delete of profile: " .. profile)
	StaticPopupDialogs[PROFILES_DELETE_CONFIRM] = {
		text = 'Delete "'
			.. profile
			.. '"? This cannot be undone.',
		button1 = "Delete",
		button2 = "Cancel",
		OnAccept = function()
			SoundtrackAddon.db:DeleteProfile(profile)
			selectedProfile = nil
			Soundtrack.ProfilesTab.RefreshProfilesFrame()
		end,
		timeout = 0,
		whileDead = true,
		hideOnEscape = true,
	}
	StaticPopup_Show(PROFILES_DELETE_CONFIRM)
end

-- ─────────────────────────────────────────────────────────────
-- Shared helpers
-- ─────────────────────────────────────────────────────────────

--- Export the selected profile via the Export/Import dialog.
function Soundtrack.ProfilesTab.ExportSelectedProfile()
	local profile = selectedProfile or SoundtrackAddon.db:GetCurrentProfile()
	Soundtrack.ExportImportDialog.OpenForExport(profile)
end

function Soundtrack.ProfilesTab.ReloadProfile()
	Soundtrack.TracksLoaded = false
	SoundtrackAddon:PLAYER_ENTERING_WORLD()
	Soundtrack.ProfilesTab.RefreshProfilesFrame()
end

function Soundtrack.ProfilesTab.RefreshProfilesFrame()
	-- Default selection to active profile when nothing is selected yet.
	if not selectedProfile then
		selectedProfile = SoundtrackAddon.db:GetCurrentProfile()
	end
	Soundtrack.ProfilesTab.PopulateProfileList()
	Soundtrack.ProfilesTab.RefreshDetailsPanel()
end
