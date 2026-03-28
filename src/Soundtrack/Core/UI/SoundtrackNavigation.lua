-- SoundtrackNavigation.lua
-- Sidebar navigation system replacing the old 10-tab interface.
-- Organizes pages into sections: MUSIC (event categories), SETTINGS, INFO.
-- Supports collapsible parent items with children for grouping related pages.

SoundtrackNav = {}

local NAV_ITEMS = {
	-- Items may have a `children` array for collapsible sub-navigation.
	-- Children inherit the parent's section and are indented in the sidebar.
	{
		id = "battle", label = "Battle", section = "MUSIC", eventTable = "Battle", tabIndex = 1,
		children = {
			{ id = "encounters", label = "Encounters",  eventTable = "Encounter",  tabIndex = 2 },
			{ id = "bosszones",  label = "Boss Zones",   eventTable = "Boss Zones", tabIndex = 3 },
		},
	},
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
local navButtons = {}          -- all buttons keyed by id (parents and children)
local expandedState = {}       -- tracks which parents are expanded, keyed by parent id
local childButtons = {}        -- child buttons grouped by parent id for show/hide
local sidebarFrameRef = nil    -- stored reference for relayout

-- Iterator that yields every item (parents and children) in display order
local function FlatIterator()
	local result = {}
	for _, item in ipairs(NAV_ITEMS) do
		table.insert(result, { item = item, isChild = false, parentId = nil })
		if item.children then
			for _, child in ipairs(item.children) do
				table.insert(result, { item = child, isChild = true, parentId = item.id })
			end
		end
	end
	return result
end

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
		if item.id == id then return item end
		if item.children then
			for _, child in ipairs(item.children) do
				if child.id == id then return child end
			end
		end
	end
	return nil
end

function SoundtrackNav.GetItemByTabIndex(tabIndex)
	for _, item in ipairs(NAV_ITEMS) do
		if item.tabIndex == tabIndex then return item end
		if item.children then
			for _, child in ipairs(item.children) do
				if child.tabIndex == tabIndex then return child end
			end
		end
	end
	return nil
end

function SoundtrackNav.GetItemByEventTable(eventTableName)
	for _, item in ipairs(NAV_ITEMS) do
		if item.eventTable == eventTableName then return item end
		if item.children then
			for _, child in ipairs(item.children) do
				if child.eventTable == eventTableName then return child end
			end
		end
	end
	return nil
end

-- Find the parent id for a given nav id, or nil if it's a top-level item.
function SoundtrackNav.GetParentId(navId)
	for _, item in ipairs(NAV_ITEMS) do
		if item.children then
			for _, child in ipairs(item.children) do
				if child.id == navId then return item.id end
			end
		end
	end
	return nil
end

function SoundtrackNav.IsExpanded(parentId)
	return expandedState[parentId] == true
end

function SoundtrackNav.SetExpanded(parentId, expanded)
	expandedState[parentId] = expanded
	SoundtrackNav.RelayoutSidebar()
end

function SoundtrackNav.ToggleExpanded(parentId)
	SoundtrackNav.SetExpanded(parentId, not SoundtrackNav.IsExpanded(parentId))
end

-- Navigate to a page by nav item id.
-- skipAnimation: if true, content appears instantly (used on initial open).
function SoundtrackNav.NavigateTo(navId, skipAnimation)
	local item = SoundtrackNav.GetItemById(navId)
	if not item then return end

	activeNavId = navId

	-- Auto-expand parent when navigating to a child
	local parentId = SoundtrackNav.GetParentId(navId)
	if parentId and not SoundtrackNav.IsExpanded(parentId) then
		expandedState[parentId] = true
		SoundtrackNav.RelayoutSidebar()
	end

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

-- ─── Sidebar construction ───────────────────────────────────────────

local CHEVRON_RIGHT = "\226\150\184 "  -- ▸
local CHEVRON_DOWN  = "\226\150\190 "  -- ▾
local CHILD_INDENT  = 28
local PARENT_INDENT = 16
local BUTTON_HEIGHT = 22
local SECTION_GAP   = 18
local TOP_PADDING   = -8

local function CreateNavButton(sidebarFrame, item, isChild, parentId)
	local btn = CreateFrame("Button", "SoundtrackNavButton_" .. item.id, sidebarFrame)
	btn:SetSize(126, BUTTON_HEIGHT)

	-- Highlight texture (hover)
	local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
	highlight:SetAllPoints()
	highlight:SetColorTexture(1, 1, 1, 0.08)

	-- Selected texture (active background)
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
	local indent = isChild and CHILD_INDENT or PARENT_INDENT
	local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
	label:SetPoint("LEFT", btn, "LEFT", indent, 0)
	label:SetJustifyH("LEFT")
	label:SetWidth(126 - indent - 4)
	btn._label = label
	btn._isChild = isChild
	btn._parentId = parentId
	btn._navItem = item

	return btn
end

-- Build the sidebar buttons (called from XML OnLoad)
function SoundtrackNav.BuildSidebar(sidebarFrame)
	sidebarFrameRef = sidebarFrame
	local lastSection = nil

	-- Default: expand any parent whose child is active
	for _, item in ipairs(NAV_ITEMS) do
		if item.children then
			expandedState[item.id] = true  -- start expanded
		end
	end

	for _, entry in ipairs(FlatIterator()) do
		local item = entry.item
		local isChild = entry.isChild
		local parentId = entry.parentId
		local section = isChild and nil or item.section

		-- Section headers (only for top-level items)
		if section and section ~= lastSection then
			lastSection = section
			local header = sidebarFrame:CreateFontString("SoundtrackNavHeader_" .. section, "OVERLAY", "GameFontNormalSmall")
			header:SetText("|cFF888888" .. section .. "|r")
			header:SetJustifyH("LEFT")
		end

		local btn = CreateNavButton(sidebarFrame, item, isChild, parentId)

		-- Set label text (with chevron for parents that have children)
		if not isChild and item.children then
			local chevron = expandedState[item.id] and CHEVRON_DOWN or CHEVRON_RIGHT
			btn._label:SetText(chevron .. item.label)
		else
			btn._label:SetText(item.label)
		end

		-- Click handler
		btn.navId = item.id
		if not isChild and item.children then
			btn:SetScript("OnClick", function(self)
				SoundtrackNav.ToggleExpanded(self.navId)
				SoundtrackNav.NavigateTo(self.navId)
			end)
		else
			btn:SetScript("OnClick", function(self)
				SoundtrackNav.NavigateTo(self.navId)
			end)
		end

		navButtons[item.id] = btn

		-- Track child buttons by parent for visibility toggling
		if isChild then
			if not childButtons[parentId] then
				childButtons[parentId] = {}
			end
			table.insert(childButtons[parentId], btn)
		end
	end

	SoundtrackNav.RelayoutSidebar()
end

-- Reposition all buttons based on current expanded/collapsed state
function SoundtrackNav.RelayoutSidebar()
	if not sidebarFrameRef then return end

	local yOffset = TOP_PADDING
	local lastSection = nil

	for _, entry in ipairs(FlatIterator()) do
		local item = entry.item
		local isChild = entry.isChild
		local parentId = entry.parentId
		local section = isChild and nil or item.section
		local btn = navButtons[item.id]
		if not btn then return end -- safety: sidebar not yet built

		-- Skip hidden children
		if isChild and not SoundtrackNav.IsExpanded(parentId) then
			btn:Hide()
		else
			-- Section header
			if section and section ~= lastSection then
				lastSection = section
				local header = _G["SoundtrackNavHeader_" .. section]
				if header then
					header:SetPoint("TOPLEFT", sidebarFrameRef, "TOPLEFT", 12, yOffset)
				end
				yOffset = yOffset - SECTION_GAP
			end

			btn:SetPoint("TOPLEFT", sidebarFrameRef, "TOPLEFT", 4, yOffset)
			btn:Show()

			-- Update chevron text for parent buttons
			if not isChild and item.children then
				local chevron = expandedState[item.id] and CHEVRON_DOWN or CHEVRON_RIGHT
				btn._label:SetText(chevron .. item.label)
			end

			yOffset = yOffset - BUTTON_HEIGHT
		end
	end
end

-- Update visual highlight to reflect activeNavId
function SoundtrackNav.RefreshHighlight()
	local activeParentId = SoundtrackNav.GetParentId(activeNavId)

	for id, btn in pairs(navButtons) do
		local isActive = (id == activeNavId)
		-- Parent gets a subtle highlight when one of its children is active
		local isActiveParent = (id == activeParentId)

		if isActive then
			btn._selectedBg:Show()
			btn._activeBar:Show()
			btn._label:SetTextColor(0.4, 0.8, 1.0)
		elseif isActiveParent then
			btn._selectedBg:Show()
			btn._activeBar:Hide()
			btn._label:SetTextColor(0.6, 0.8, 0.9)
		else
			btn._selectedBg:Hide()
			btn._activeBar:Hide()
			if btn._isChild then
				btn._label:SetTextColor(0.8, 0.8, 0.8)
			else
				btn._label:SetTextColor(1, 1, 1)
			end
		end
	end
end
