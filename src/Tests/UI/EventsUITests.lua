if not Tests then
	return
end

local Tests = Tests("EventsUI", "PLAYER_ENTERING_WORLD")

if not table.maxn then
	function table.maxn(t)
		return #t
	end
end

local function MockFontString(name)
	local obj = {
		_text = "",
		SetText = function(self, text) self._text = text or "" end,
		GetText = function(self) return self._text end,
		SetWidth = function() end,
		SetHeight = function() end,
		SetPoint = function() end,
		SetFont = function() end,
		SetJustifyH = function() end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function MockFrame(name)
	local obj = {
		_visible = false,
		_id = 1,
		_fontString = nil,
		Show = function(self) self._visible = true end,
		Hide = function(self) self._visible = false end,
		IsVisible = function(self) return self._visible end,
		SetPoint = function() end,
		SetWidth = function() end,
		SetHeight = function() end,
		SetNormalFontObject = function() end,
		SetHighlightFontObject = function() end,
		SetHighlightTexture = function() end,
		LockHighlight = function() end,
		UnlockHighlight = function() end,
		SetFontString = function(self, fs) self._fontString = fs end,
		CreateFontString = function() return MockFontString() end,
		SetID = function(self, id) self._id = id end,
		GetID = function(self) return self._id end,
		GetText = function(self)
			if self._fontString and self._fontString.GetText then
				return self._fontString:GetText()
			end
			return ""
		end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function MockCheckButton(name)
	local obj = {
		_checked = false,
		SetChecked = function(self, value) self._checked = value and true or false end,
		GetChecked = function(self) return self._checked end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function MockEditBox(name)
	local obj = {
		_text = "",
		SetText = function(self, value) self._text = value or "" end,
		GetText = function(self) return self._text end,
	}
	if name then
		_G[name] = obj
	end
	return obj
end

local function SetupEventListButtons(count)
	for i = 1, count, 1 do
		MockFrame("SoundtrackFrameEventButton" .. i)
		MockFrame("SoundtrackFrameEventButton" .. i .. "CollapserTexture")
		MockFrame("SoundtrackFrameEventButton" .. i .. "ExpanderTexture")
		MockFrame("SoundtrackFrameEventButton" .. i .. "Icon")
	end
end

function Tests:UpdateEventsUI_SkipsWhenHidden()
	SoundtrackUI.SelectedEventsTable = ST_MISC
	SoundtrackFrame:Hide()
	local traced = false
	Replace(Soundtrack.Chat, "TraceFrame", function()
		traced = true
	end)
	local disabled = false
	Replace(SoundtrackUI, "DisableAllEventButtons", function() disabled = true end)

	SoundtrackUI.UpdateEventsUI()

	IsTrue(traced)
	IsFalse(disabled)
end

function Tests:UpdateEventsUI_ChoosesFirstWhenSelectedDeleted()
	SoundtrackUI.SelectedEventsTable = ST_MISC
	SoundtrackUI.SelectedEvent = "Missing"
	SoundtrackFrame:Show()
	EVENTS_TO_DISPLAY = 3
	EVENTS_ITEM_HEIGHT = 16
	SetupEventListButtons(EVENTS_TO_DISPLAY)
	MockFrame("SoundtrackFrameEventScrollFrame")
	MockEditBox("SoundtrackFrame_EventName")
	MockCheckButton("SoundtrackFrame_RandomCheckButton")
	MockCheckButton("SoundtrackFrame_ContinuousCheckBox")
	MockCheckButton("SoundtrackFrame_SoundEffectCheckBox")
	Replace(_G, "FauxScrollFrame_GetOffset", function() return 0 end)
	Replace(_G, "FauxScrollFrame_Update", function() end)
	Replace(_G, "GetFlatEventsTableForCurrentTab", function()
		return { { tag = "Event1" } }
	end)
	Replace(_G, "GetLeafText", function(text) return text end)
	Replace(_G, "GetEventDepth", function() return 0 end)
	Replace(SoundtrackUI, "RefreshTracks", function() end)

	Soundtrack.Events.GetTable(ST_MISC)["Event1"] = { tracks = {}, expanded = true }

	SoundtrackUI.UpdateEventsUI()

	AreEqual("Event1", SoundtrackUI.SelectedEvent)
end

function Tests:UpdateEventsUI_PopulatesButtonsAndSettings()
	SoundtrackUI.SelectedEventsTable = ST_MISC
	SoundtrackUI.SelectedEvent = "Event1"
	SoundtrackFrame:Show()
	EVENTS_TO_DISPLAY = 3
	EVENTS_ITEM_HEIGHT = 16
	SetupEventListButtons(EVENTS_TO_DISPLAY)
	MockFrame("SoundtrackFrameEventScrollFrame")
	MockEditBox("SoundtrackFrame_EventName")
	MockCheckButton("SoundtrackFrame_RandomCheckButton")
	MockCheckButton("SoundtrackFrame_ContinuousCheckBox")
	MockCheckButton("SoundtrackFrame_SoundEffectCheckBox")
	Replace(_G, "FauxScrollFrame_GetOffset", function() return 0 end)
	Replace(_G, "FauxScrollFrame_Update", function() end)
	Replace(_G, "GetLeafText", function(text) return text end)
	Replace(_G, "GetEventDepth", function() return 1 end)
	Replace(_G, "GetFlatEventsTableForCurrentTab", function()
		return {
			{ tag = "Event1", nodes = { { tag = "Child" } } },
			{ tag = "Event2" },
		}
	end)
	Replace(Soundtrack.Events, "GetCurrentStackLevel", function() return 1 end)
	Soundtrack.Events.Stack = { { eventName = "Event1", tableName = ST_MISC } }

	local refreshCalled = false
	Replace(SoundtrackUI, "RefreshTracks", function() refreshCalled = true end)

	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	eventTable["Event1"] = { tracks = { "a", "b" }, expanded = true, random = true, continuous = false, soundEffect = true }
	eventTable["Event2"] = { tracks = {}, expanded = false, random = false, continuous = true, soundEffect = false }

	SoundtrackUI.UpdateEventsUI()

	local event1Text = _G["SoundtrackFrameEventButton1"]:GetText()

	IsTrue(refreshCalled)
	IsTrue(_G["SoundtrackFrameEventButton1"]:IsVisible())
	IsTrue(_G["SoundtrackFrameEventButton1CollapserTexture"]:IsVisible())
	IsFalse(_G["SoundtrackFrameEventButton1ExpanderTexture"]:IsVisible())
	IsTrue(_G["SoundtrackFrameEventButton1Icon"]:IsVisible())
	IsTrue(_G["SoundtrackFrameEventButton2"]:IsVisible())
	IsFalse(_G["SoundtrackFrameEventButton2ExpanderTexture"]:IsVisible())
	IsTrue(string.find(event1Text, "Event1") ~= nil, "Expanded event text should include name")
	IsTrue(string.find(event1Text, "%(2%)") ~= nil, "Expanded event text should include track count")
	IsTrue(SoundtrackFrame_RandomCheckButton:GetChecked())
	IsTrue(SoundtrackFrame_SoundEffectCheckBox:GetChecked())
	IsFalse(SoundtrackFrame_ContinuousCheckBox:GetChecked())
	AreEqual("Event1", SoundtrackFrame_EventName:GetText())
end

function Tests:OnEventButtonClick_TogglesExpandAndUpdates()
	SoundtrackUI.SelectedEventsTable = ST_MISC
	SoundtrackFrame:Show()
	EVENTS_TO_DISPLAY = 3
	SetupEventListButtons(EVENTS_TO_DISPLAY)
	MockFrame("SoundtrackFrameEventScrollFrame")
	Replace(_G, "FauxScrollFrame_GetOffset", function() return 0 end)
	Replace(_G, "GetFlatEventsTableForCurrentTab", function()
		return { { tag = "Event1" } }
	end)
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	eventTable["Event1"] = { expanded = true, tracks = {} }
	local paused
	Replace(Soundtrack.Events, "Pause", function(value) paused = value end)
	local treeChanged
	Replace(Soundtrack, "OnEventTreeChanged", function(tableName) treeChanged = tableName end)
	local updated = false
	Replace(SoundtrackUI, "UpdateEventsUI", function() updated = true end)

	local button = _G["SoundtrackFrameEventButton1"]
	button:SetID(1)
	SoundtrackUI.OnEventButtonClick(button, "LeftButton")

	IsFalse(eventTable["Event1"].expanded)
	AreEqual(false, paused)
	AreEqual(ST_MISC, treeChanged)
	IsTrue(updated)
end

function Tests:OnEventButtonClick_PlaylistsRightClickPlaysEvent()
	SoundtrackUI.SelectedEventsTable = "Playlists"
	SoundtrackFrame:Show()
	EVENTS_TO_DISPLAY = 3
	SetupEventListButtons(EVENTS_TO_DISPLAY)
	MockFrame("SoundtrackFrameEventScrollFrame")
	Replace(_G, "FauxScrollFrame_GetOffset", function() return 0 end)
	Replace(_G, "GetFlatEventsTableForCurrentTab", function()
		return { { tag = "Playlist1" } }
	end)
	local eventTable = Soundtrack.Events.GetTable("Playlists")
	eventTable["Playlist1"] = { expanded = false, tracks = {} }
	local played
	Replace(Soundtrack, "PlayEvent", function(tableName, eventName)
		played = tableName .. ":" .. eventName
	end)
	Replace(Soundtrack.Events, "Pause", function() end)
	Replace(Soundtrack, "OnEventTreeChanged", function() end)
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)

	local button = _G["SoundtrackFrameEventButton1"]
	button:SetID(1)
	SoundtrackUI.OnEventButtonClick(button, "RightButton")

	AreEqual("Playlists:Playlist1", played)
	IsFalse(eventTable["Playlist1"].expanded)
end
