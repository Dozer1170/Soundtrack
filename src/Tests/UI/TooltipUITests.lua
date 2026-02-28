if not Tests then
	return
end

local Tests = Tests("TooltipUI", "PLAYER_ENTERING_WORLD")

local function MockTooltip()
	local lines = {}
	local visible = false
	local obj = {
		_lines = lines,
		_visible = false,
		SetOwner = function() end,
		ClearLines = function(self) self._lines = {} lines = self._lines end,
		AddLine = function(self, text) table.insert(self._lines, text) end,
		Show = function(self) self._visible = true end,
		Hide = function(self) self._visible = false end,
	}
	return obj
end

local function SetupTooltip()
	local tooltip = MockTooltip()
	Soundtrack_Tooltip = tooltip
	return tooltip
end

-- ShowTip Tests

function Tests:ShowTip_AddsTitleLine()
	local tooltip = SetupTooltip()

	Soundtrack.ShowTip(nil, "My Song", nil, nil, nil)

	AreEqual("My Song", tooltip._lines[1], "Title added as first line")
end

function Tests:ShowTip_AddsTextLine_WhenProvided()
	local tooltip = SetupTooltip()

	Soundtrack.ShowTip(nil, "Title", "Description", nil, nil)

	AreEqual(2, #tooltip._lines, "Title and text lines added")
	AreEqual("Description", tooltip._lines[2], "Description added as second line")
end

function Tests:ShowTip_AddsAuthorLine_WhenProvided()
	local tooltip = SetupTooltip()

	Soundtrack.ShowTip(nil, "Title", nil, "Author Name", nil)

	AreEqual(2, #tooltip._lines, "Title and author lines added")
	AreEqual("Author Name", tooltip._lines[2], "Author added as second line")
end

function Tests:ShowTip_AddsAlbumLine_WhenProvided()
	local tooltip = SetupTooltip()

	Soundtrack.ShowTip(nil, "Title", nil, nil, "Album Name")

	AreEqual(2, #tooltip._lines, "Title and album lines added")
	AreEqual("Album Name", tooltip._lines[2], "Album added as second line")
end

function Tests:ShowTip_AddsAllFourLines()
	local tooltip = SetupTooltip()

	Soundtrack.ShowTip(nil, "Title", "Text", "Author", "Album")

	AreEqual(4, #tooltip._lines, "All four lines added")
	AreEqual("Title", tooltip._lines[1], "Title is first")
	AreEqual("Text", tooltip._lines[2], "Text is second")
	AreEqual("Author", tooltip._lines[3], "Author is third")
	AreEqual("Album", tooltip._lines[4], "Album is fourth")
end

function Tests:ShowTip_ShowsTooltip()
	local tooltip = SetupTooltip()

	Soundtrack.ShowTip(nil, "Title", nil, nil, nil)

	IsTrue(tooltip._visible, "Tooltip is shown")
end

function Tests:ShowTip_CreatesNewTooltip_WhenNil()
	Soundtrack_Tooltip = nil
	local createdType = nil
	Replace(_G, "CreateFrame", function(frameType, name, parent, template)
		createdType = frameType
		local t = MockTooltip()
		_G[name] = t
		return t
	end)

	Soundtrack.ShowTip(nil, "Title", nil, nil, nil)

	AreEqual("GameTooltip", createdType, "GameTooltip frame created when tooltip is nil")
end

-- HideTip Tests

function Tests:HideTip_HidesTooltip()
	local tooltip = SetupTooltip()

	Soundtrack.ShowTip(nil, "Title", nil, nil, nil) -- make it visible first
	Soundtrack.HideTip()

	IsFalse(tooltip._visible, "Tooltip is hidden")
end

function Tests:HideTip_CreatesTooltip_WhenNil()
	Soundtrack_Tooltip = nil
	local created = false
	Replace(_G, "CreateFrame", function(frameType, name)
		created = true
		local t = MockTooltip()
		_G[name] = t
		return t
	end)

	Soundtrack.HideTip()

	IsTrue(created, "Tooltip created when nil")
end
