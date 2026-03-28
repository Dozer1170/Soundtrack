-- SoundtrackNavigation.lua
-- Sidebar navigation system replacing the old 10-tab interface.
-- Organizes pages into sections: MUSIC (event categories), SETTINGS, INFO.

SoundtrackNav = {}

local NAV_ITEMS = {
	-- { id, label, section, eventTable, tabIndex (for backward compat) }
	{ id = "battle",     label = "Battle",      section = "MUSIC",    eventTable = "Battle",      tabIndex = 1 },
	{ id = "encounters", label = "Encounters",   section = "MUSIC",    eventTable = "Encounter",   tabIndex = 2 },
	{ id = "bosszones",  label = "Boss Zones",   section = "MUSIC",    eventTable = "Boss Zones",  tabIndex = 3 },
	{ id = "zones",      label = "Zones",        section = "MUSIC",    eventTable = "Zone",        tabIndex = 4 },
	{ id = "petbattles", label = "Pet Battles",  section = "MUSIC",    eventTable = "Pet Battles", tabIndex = 5 },
	{ id = "dances",     label = "Dances",       section = "MUSIC",    eventTable = "Dance",       tabIndex = 6 },
	{ id = "misc",       label = "Misc",         section = "MUSIC",    eventTable = "Misc",        tabIndex = 7 },
	{ id = "playlists",  label = "Playlists",    section = "MUSIC",    eventTable = "Playlists",   tabIndex = 8 },
	{ id = "options",    label = "Options",       section = "SETTINGS", eventTable = nil,           tabIndex = 9 },
	{ id = "profiles",   label = "Profiles",      section = "SETTINGS", eventTable = nil,           tabIndex = 10 },
	{ id = "about",      label = "About",         section = "INFO",     eventTable = nil,           tabIndex = 11 },
}

local SECTIONS = { "MUSIC", "SETTINGS", "INFO" }

local activeNavId = "battle"
local navButtons = {}

function SoundtrackNav.GetItems()
	return NAV_ITEMS
end

function SoundtrackNav.GetSections()
	return SECTIONS
end

function SoundtrackNav.GetActiveId()
	return activeNavId
end

function SoundtrackNav.GetItemById(id)
	for _, item in ipairs(NAV_ITEMS) do
		if item.id == id then
			return item
		end
	end
	return nil
end

function SoundtrackNav.GetItemByTabIndex(tabIndex)
	for _, item in ipairs(NAV_ITEMS) do
		if item.tabIndex == tabIndex then
			return item
		end
	end
	return nil
end

function SoundtrackNav.GetItemByEventTable(eventTableName)
	for _, item in ipairs(NAV_ITEMS) do
		if item.eventTable == eventTableName then
			return item
		end
	end
	return nil
end

-- Navigate to a page by nav item id.
-- skipAnimation: if true, content appears instantly (used on initial open).
function SoundtrackNav.NavigateTo(navId, skipAnimation)
	local item = SoundtrackNav.GetItemById(navId)
	if not item then return end

	activeNavId = navId
	SoundtrackNav.RefreshHighlight()

	-- Map to old tab system for backward compatibility
	SoundtrackFrame.selectedTab = item.tabIndex

	-- Let RefreshShowingTab handle the content switch and animation
	SoundtrackUI.RefreshShowingTab(skipAnimation)
end

-- Get the content frame for a nav item
function SoundtrackNav.GetContentFrame(item)
	if item.tabIndex <= 8 then
		return SoundtrackFrameEventFrame
	elseif item.tabIndex == 9 then
		return SoundtrackFrameOptionsTab
	elseif item.tabIndex == 10 then
		return SoundtrackFrameProfilesFrame
	elseif item.tabIndex == 11 then
		return SoundtrackFrameAboutFrame
	end
	return nil
end

-- Navigate to whatever is currently playing
function SoundtrackNav.NavigateToActive()
	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
	if stackLevel > 0 then
		local tableName = Soundtrack.Events.Stack[stackLevel].tableName
		local item = SoundtrackNav.GetItemByEventTable(tableName)
		if item then
			SoundtrackNav.NavigateTo(item.id)
		end
	end
end

-- Build the sidebar buttons (called from XML OnLoad)
function SoundtrackNav.BuildSidebar(sidebarFrame)
	local yOffset = -8
	local lastSection = nil

	for _, item in ipairs(NAV_ITEMS) do
		-- Add section header if we're in a new section
		if item.section ~= lastSection then
			lastSection = item.section
			local header = sidebarFrame:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
			header:SetPoint("TOPLEFT", sidebarFrame, "TOPLEFT", 12, yOffset)
			header:SetText("|cFF888888" .. item.section .. "|r")
			header:SetJustifyH("LEFT")
			yOffset = yOffset - 18
		end

		-- Create nav button
		local btn = CreateFrame("Button", "SoundtrackNavButton_" .. item.id, sidebarFrame)
		btn:SetSize(126, 22)
		btn:SetPoint("TOPLEFT", sidebarFrame, "TOPLEFT", 4, yOffset)

		-- Highlight texture
		local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
		highlight:SetAllPoints()
		highlight:SetColorTexture(1, 1, 1, 0.08)

		-- Selected texture
		local selected = btn:CreateTexture(nil, "BACKGROUND")
		selected:SetAllPoints()
		selected:SetColorTexture(0.2, 0.6, 1.0, 0.15)
		selected:Hide()
		btn._selectedBg = selected

		-- Active indicator bar (left edge)
		local activeBar = btn:CreateTexture(nil, "OVERLAY")
		activeBar:SetSize(3, 18)
		activeBar:SetPoint("LEFT", btn, "LEFT", 0, 0)
		activeBar:SetColorTexture(0.3, 0.7, 1.0, 1.0)
		activeBar:Hide()
		btn._activeBar = activeBar

		-- Label
		local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
		label:SetPoint("LEFT", btn, "LEFT", 16, 0)
		label:SetText(item.label)
		label:SetJustifyH("LEFT")
		label:SetWidth(108)
		btn._label = label

		-- Click handler
		btn.navId = item.id
		btn:SetScript("OnClick", function(self)
			SoundtrackNav.NavigateTo(self.navId)
		end)

		navButtons[item.id] = btn
		yOffset = yOffset - 22
	end
end

-- Update visual highlight to reflect activeNavId
function SoundtrackNav.RefreshHighlight()
	for id, btn in pairs(navButtons) do
		if id == activeNavId then
			btn._selectedBg:Show()
			btn._activeBar:Show()
			btn._label:SetTextColor(0.4, 0.8, 1.0)
		else
			btn._selectedBg:Hide()
			btn._activeBar:Hide()
			btn._label:SetTextColor(1, 1, 1)
		end
	end
end
