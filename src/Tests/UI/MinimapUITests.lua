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
