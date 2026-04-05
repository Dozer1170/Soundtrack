if not Tests then
	return
end

local Tests = Tests("SoundtrackNavigation")

-- ── Lookup tests ─────────────────────────────────────────────────────

function Tests:GetItemById_TopLevel_ReturnsItem()
	local item = SoundtrackNav.GetItemById("battle")
	IsTrue(item ~= nil, "Should find top-level item")
	AreEqual("Battle", item.label, "Label should be Battle")
end

function Tests:GetItemById_General_ReturnsChild()
	local item = SoundtrackNav.GetItemById("general")
	IsTrue(item ~= nil, "Should find general child item")
	AreEqual("General", item.label, "Label should be General")
	AreEqual(1, item.tabIndex, "tabIndex should be 1")
end

function Tests:GetItemById_Child_ReturnsItem()
	local item = SoundtrackNav.GetItemById("encounters")
	IsTrue(item ~= nil, "Should find child item")
	AreEqual("Encounters", item.label, "Label should be Encounters")
	AreEqual(2, item.tabIndex, "tabIndex should be 2")
end

function Tests:GetItemById_BossZones_ReturnsChild()
	local item = SoundtrackNav.GetItemById("bosszones")
	IsTrue(item ~= nil, "Should find Boss Zones child")
	AreEqual("Boss Zones", item.label)
	AreEqual(3, item.tabIndex)
end

function Tests:GetItemById_NonExistent_ReturnsNil()
	local item = SoundtrackNav.GetItemById("nonexistent")
	AreEqual(nil, item, "Should return nil for unknown id")
end

function Tests:GetItemByTabIndex_TopLevel_ReturnsItem()
	local item = SoundtrackNav.GetItemByTabIndex(1)
	IsTrue(item ~= nil)
	AreEqual("general", item.id)
end

function Tests:GetItemByTabIndex_Child_ReturnsItem()
	local item = SoundtrackNav.GetItemByTabIndex(2)
	IsTrue(item ~= nil)
	AreEqual("encounters", item.id)
end

function Tests:GetItemByTabIndex_OptionsTab_ReturnsItem()
	local item = SoundtrackNav.GetItemByTabIndex(9)
	IsTrue(item ~= nil)
	AreEqual("options", item.id)
end

function Tests:GetItemByTabIndex_AboutTab_ReturnsItem()
	local item = SoundtrackNav.GetItemByTabIndex(11)
	IsTrue(item ~= nil)
	AreEqual("about", item.id)
end

function Tests:GetItemByEventTable_Battle_ReturnsGeneral()
	local item = SoundtrackNav.GetItemByEventTable("Battle")
	IsTrue(item ~= nil)
	AreEqual("general", item.id)
end

function Tests:GetItemByEventTable_Encounter_ReturnsChild()
	local item = SoundtrackNav.GetItemByEventTable("Encounter")
	IsTrue(item ~= nil)
	AreEqual("encounters", item.id)
end

function Tests:GetItemByEventTable_BossZones_ReturnsChild()
	local item = SoundtrackNav.GetItemByEventTable("Boss Zones")
	IsTrue(item ~= nil)
	AreEqual("bosszones", item.id)
end

function Tests:GetItemByEventTable_Zone_ReturnsTopLevel()
	local item = SoundtrackNav.GetItemByEventTable("Zone")
	IsTrue(item ~= nil)
	AreEqual("zones", item.id)
end

-- ── Parent/child relationship tests ──────────────────────────────────

function Tests:GetParentId_Child_ReturnsParentId()
	AreEqual("battle", SoundtrackNav.GetParentId("general"),    "general parent should be battle")
	AreEqual("battle", SoundtrackNav.GetParentId("encounters"), "encounters parent should be battle")
	AreEqual("battle", SoundtrackNav.GetParentId("bosszones"),  "bosszones parent should be battle")
end

function Tests:GetParentId_TopLevel_ReturnsNil()
	AreEqual(nil, SoundtrackNav.GetParentId("battle"), "battle has no parent")
	AreEqual(nil, SoundtrackNav.GetParentId("zones"), "zones has no parent")
	AreEqual(nil, SoundtrackNav.GetParentId("options"), "options has no parent")
end

function Tests:GetParentId_NonExistent_ReturnsNil()
	AreEqual(nil, SoundtrackNav.GetParentId("nonexistent"), "unknown id has no parent")
end

-- ── Expand/collapse state tests ──────────────────────────────────────

function Tests:SetExpanded_True_IsExpanded()
	SoundtrackNav.SetExpanded("battle", true)
	IsTrue(SoundtrackNav.IsExpanded("battle"), "battle should be expanded")
end

function Tests:SetExpanded_False_IsNotExpanded()
	SoundtrackNav.SetExpanded("battle", false)
	IsFalse(SoundtrackNav.IsExpanded("battle"), "battle should be collapsed")
	-- Restore for other tests
	SoundtrackNav.SetExpanded("battle", true)
end

function Tests:ToggleExpanded_FromExpanded_Collapses()
	SoundtrackNav.SetExpanded("battle", true)
	SoundtrackNav.ToggleExpanded("battle")
	IsFalse(SoundtrackNav.IsExpanded("battle"), "toggle from expanded should collapse")
	-- Restore
	SoundtrackNav.SetExpanded("battle", true)
end

function Tests:ToggleExpanded_FromCollapsed_Expands()
	SoundtrackNav.SetExpanded("battle", false)
	SoundtrackNav.ToggleExpanded("battle")
	IsTrue(SoundtrackNav.IsExpanded("battle"), "toggle from collapsed should expand")
end

-- ── Content frame mapping tests ──────────────────────────────────────

function Tests:GetContentFrame_EventTabs_ReturnEventFrame()
	for tabIdx = 1, 8 do
		local item = SoundtrackNav.GetItemByTabIndex(tabIdx)
		IsTrue(item ~= nil, "Item for tabIndex " .. tabIdx .. " should exist")
		local frame = SoundtrackNav.GetContentFrame(item)
		AreEqual(SoundtrackFrameEventFrame, frame, "tabIndex " .. tabIdx .. " should use EventFrame")
	end
end

function Tests:GetContentFrame_Options_ReturnOptionsTab()
	local item = SoundtrackNav.GetItemById("options")
	AreEqual(SoundtrackFrameOptionsTab, SoundtrackNav.GetContentFrame(item))
end

function Tests:GetContentFrame_Profiles_ReturnProfilesFrame()
	local item = SoundtrackNav.GetItemById("profiles")
	AreEqual(SoundtrackFrameProfilesFrame, SoundtrackNav.GetContentFrame(item))
end

function Tests:GetContentFrame_About_ReturnAboutFrame()
	local item = SoundtrackNav.GetItemById("about")
	AreEqual(SoundtrackFrameAboutFrame, SoundtrackNav.GetContentFrame(item))
end

-- ── Data integrity tests ─────────────────────────────────────────────

function Tests:AllItemsHaveUniqueIds()
	local seen = {}
	local items = SoundtrackNav.GetItems()
	for _, item in ipairs(items) do
		IsFalse(seen[item.id] == true, "Duplicate id: " .. item.id)
		seen[item.id] = true
		if item.children then
			for _, child in ipairs(item.children) do
				IsFalse(seen[child.id] == true, "Duplicate child id: " .. child.id)
				seen[child.id] = true
			end
		end
	end
end

function Tests:AllItemsHaveUniqueTabIndices()
	local seen = {}
	local items = SoundtrackNav.GetItems()
	for _, item in ipairs(items) do
		if item.tabIndex ~= nil then
			IsFalse(seen[item.tabIndex] == true, "Duplicate tabIndex: " .. item.tabIndex)
			seen[item.tabIndex] = true
		end
		if item.children then
			for _, child in ipairs(item.children) do
				if child.tabIndex ~= nil then
					IsFalse(seen[child.tabIndex] == true, "Duplicate child tabIndex: " .. child.tabIndex)
					seen[child.tabIndex] = true
				end
			end
		end
	end
end

function Tests:ChildrenInheritNoSection()
	local items = SoundtrackNav.GetItems()
	for _, item in ipairs(items) do
		if item.children then
			for _, child in ipairs(item.children) do
				AreEqual(nil, child.section, "Child " .. child.id .. " should not have its own section")
			end
		end
	end
end
