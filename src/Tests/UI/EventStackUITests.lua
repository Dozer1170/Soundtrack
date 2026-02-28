if not Tests then
	return
end

local Tests = Tests("EventStackUI", "PLAYER_ENTERING_WORLD")

local function MockLabel(name)
	local obj = {
		_text = "",
		_visible = false,
		SetText = function(self, text) self._text = text or "" end,
		GetText = function(self) return self._text end,
		Show = function(self) self._visible = true end,
		Hide = function(self) self._visible = false end,
		IsVisible = function(self) return self._visible end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function SetupControlFrame()
	MockLabel("SoundtrackControlFrame")
	MockLabel("SoundtrackControlFrameStackTitle")
	for i = 1, 16 do
		MockLabel("SoundtrackControlFrameStack" .. i)
	end
end

-- UpdateEventStackUI Tests

function Tests:UpdateEventStackUI_ShowsNoneForEmptySlot()
	-- Stack slot 1 is empty
	Soundtrack.Events.Stack[1] = { tableName = nil, eventName = nil }

	SoundtrackUI.UpdateEventStackUI()

	AreEqual("1) None", SoundtrackControlFrameStack1:GetText(), "Empty slot shows 'None'")
end

function Tests:UpdateEventStackUI_ShowsEventName()
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true)
	Soundtrack.Events.Stack[1] = { tableName = ST_ZONE, eventName = "Eastern Kingdoms" }

	SoundtrackUI.UpdateEventStackUI()

	local text = SoundtrackControlFrameStack1:GetText()
	IsTrue(text:find("Eastern Kingdoms") ~= nil, "Event name appears in stack label")
end

function Tests:UpdateEventStackUI_ShowsLoopForContinuousEvent()
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, true) -- continuous = true
	Soundtrack.Events.Stack[1] = { tableName = ST_ZONE, eventName = "Eastern Kingdoms" }

	SoundtrackUI.UpdateEventStackUI()

	local text = SoundtrackControlFrameStack1:GetText()
	IsTrue(text:find("Loop") ~= nil, "Continuous event shows 'Loop'")
end

function Tests:UpdateEventStackUI_ShowsOnceForNonContinuousEvent()
	Soundtrack.AddEvent(ST_ZONE, "Eastern Kingdoms", ST_CONTINENT_LVL, false) -- continuous = false
	Soundtrack.Events.Stack[1] = { tableName = ST_ZONE, eventName = "Eastern Kingdoms" }

	SoundtrackUI.UpdateEventStackUI()

	local text = SoundtrackControlFrameStack1:GetText()
	IsTrue(text:find("Once") ~= nil, "Non-continuous event shows 'Once'")
end

function Tests:UpdateEventStackUI_IncludesSlotNumber()
	Soundtrack.AddEvent(ST_ZONE, "Kalimdor", ST_CONTINENT_LVL, true)
	Soundtrack.Events.Stack[3] = { tableName = ST_ZONE, eventName = "Kalimdor" }

	SoundtrackUI.UpdateEventStackUI()

	local text = SoundtrackControlFrameStack3:GetText()
	IsTrue(text:sub(1, 2) == "3)", "Stack label starts with slot number")
end

-- RefreshEventStack Tests

function Tests:RefreshEventStack_HidesControlFrame_WhenShowPlaybackControlsIsFalse()
	SetupControlFrame()
	SoundtrackAddon.db.profile.settings.ShowPlaybackControls = false

	SoundtrackUI.RefreshEventStack()

	IsFalse(SoundtrackControlFrame._visible, "Control frame is hidden")
end

function Tests:RefreshEventStack_ShowsControlFrame_WhenShowPlaybackControlsIsTrue()
	SetupControlFrame()
	SoundtrackAddon.db.profile.settings.ShowPlaybackControls = true

	SoundtrackUI.RefreshEventStack()

	IsTrue(SoundtrackControlFrame._visible, "Control frame is shown")
end

function Tests:RefreshEventStack_ShowsStackLabels_WhenShowEventStackIsTrue()
	SetupControlFrame()
	SoundtrackAddon.db.profile.settings.ShowPlaybackControls = true
	SoundtrackAddon.db.profile.settings.ShowEventStack = true

	SoundtrackUI.RefreshEventStack()

	IsTrue(SoundtrackControlFrameStack1._visible, "Stack label 1 is shown")
	IsTrue(SoundtrackControlFrameStackTitle._visible, "Stack title is shown")
end

function Tests:RefreshEventStack_HidesStackLabels_WhenShowEventStackIsFalse()
	SetupControlFrame()
	SoundtrackAddon.db.profile.settings.ShowPlaybackControls = true
	SoundtrackAddon.db.profile.settings.ShowEventStack = false

	SoundtrackUI.RefreshEventStack()

	IsFalse(SoundtrackControlFrameStack1._visible, "Stack label 1 is hidden")
	IsFalse(SoundtrackControlFrameStackTitle._visible, "Stack title is hidden")
end
