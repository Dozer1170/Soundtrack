if not Tests then
	return
end

local Tests = Tests("MinimapUI", "PLAYER_ENTERING_WORLD")

local function SetupChat()
	Soundtrack.Chat.Debug = function() end
end

-- IconFrame OnClick Tests

function Tests:OnIconFrameClick_CallsSoundtrackUIToggle()
	SetupChat()
	local called = false
	Replace(SoundtrackUI, "Toggle", function() called = true end)

	SoundtrackMinimap_IconFrame_OnClick(nil, nil)

	IsTrue(called, "SoundtrackUI.Toggle was called")
end

-- OnTooltipShow Tests

function Tests:OnTooltipShow_AddsSoundtrackLine()
	local lines = {}
	local tooltip = {
		AddLine = function(_, text) table.insert(lines, text) end,
	}

	SoundtrackMinimap_OnTooltipShow(tooltip)

	AreEqual("Soundtrack", lines[1], "First line is 'Soundtrack'")
end

function Tests:OnTooltipShow_AddsMinimapHintLine()
	local lines = {}
	local tooltip = {
		AddLine = function(_, text) table.insert(lines, text) end,
	}

	SoundtrackMinimap_OnTooltipShow(tooltip)

	AreEqual(SOUNDTRACK_MINIMAP, lines[2], "Second line is the minimap localization string")
end

function Tests:OnTooltipShow_AddsClickToToggleLine()
	local lines = {}
	local tooltip = {
		AddLine = function(_, text) table.insert(lines, text) end,
	}

	SoundtrackMinimap_OnTooltipShow(tooltip)

	IsTrue(lines[3] ~= nil, "Third line exists (click to toggle hint)")
	IsTrue(lines[3]:find("toggle") ~= nil or lines[3]:find("Toggle") ~= nil, "Third line mentions toggle")
end

function Tests:OnTooltipShow_AddsThreeLines()
	local lines = {}
	local tooltip = {
		AddLine = function(_, text) table.insert(lines, text) end,
	}

	SoundtrackMinimap_OnTooltipShow(tooltip)

	AreEqual(3, #lines, "Exactly three lines added to tooltip")
end

-- Mainline layout fix (WoW Forever)

local function MockRegion(texture)
	local region = { texture = texture, points = {} }
	function region:GetTexture() return self.texture end
	function region:SetSize(w, h) self.width, self.height = w, h end
	function region:ClearAllPoints() self.points = {} end
	function region:SetPoint(point, _, _, x, y) table.insert(self.points, { point, x, y }) end
	return region
end

local function MockButton()
	local border = MockRegion(136430)
	local background = MockRegion(136467)
	local iconTexture = MockRegion("flute-icon")
	local btn = { icon = iconTexture, border = border, background = background }
	function btn:GetRegions() return border, background, iconTexture end
	return btn
end

function Tests:NeedsMainlineLayout_TrueOnForever()
	Replace("IsRetail", true)
	Replace("WOW_PROJECT_MAINLINE", 1)
	Replace("WOW_PROJECT_ID", 18)

	IsTrue(SoundtrackMinimap_NeedsMainlineLayout(), "Forever needs the Mainline layout applied")
end

function Tests:NeedsMainlineLayout_FalseOnRetail()
	Replace("IsRetail", true)
	Replace("WOW_PROJECT_MAINLINE", 1)
	Replace("WOW_PROJECT_ID", 1)

	IsFalse(SoundtrackMinimap_NeedsMainlineLayout(), "Retail already gets the Mainline layout")
end

function Tests:NeedsMainlineLayout_FalseOnClassic()
	Replace("IsRetail", false)
	Replace("WOW_PROJECT_MAINLINE", 1)
	Replace("WOW_PROJECT_ID", 2)

	IsFalse(SoundtrackMinimap_NeedsMainlineLayout(), "Classic keeps the Classic layout")
end

function Tests:ApplyMainlineLayout_CentersIconAndSizesRing()
	local btn = MockButton()

	SoundtrackMinimap_ApplyMainlineLayout(btn)

	AreEqual(50, btn.border.width, "ring uses the Mainline size")
	AreEqual("TOPLEFT", btn.border.points[1][1], "ring anchored top-left")
	AreEqual(24, btn.background.width, "background uses the Mainline size")
	AreEqual("CENTER", btn.background.points[1][1], "background centered")
	AreEqual(18, btn.icon.width, "icon uses the Mainline size")
	AreEqual(1, #btn.icon.points, "icon has a single anchor")
	AreEqual("CENTER", btn.icon.points[1][1], "icon centered")
end
