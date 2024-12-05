StaticPopupDialogs["SOUNDTRACK_ADD_CUSTOM_POPUP"] = {
	preferredIndex = 3,
	text = SOUNDTRACK_ENTER_CUSTOM_NAME,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 100,
	OnAccept = function(self)
		local eventName = _G[self:GetName() .. "EditBox"]
		SoundtrackFrame_AddCustomEvent(eventName:GetText(), self)
	end,
	OnShow = function(self)
		_G[self:GetName() .. "EditBox"]:SetFocus()
		_G[self:GetName() .. "EditBox"]:SetText("")
	end,
	OnHide = function(_) end,
	EditBoxOnEnterPressed = function(self)
		local eventName = _G[self:GetName()]
		SoundtrackFrame_AddCustomEvent(eventName:GetText(), self)
		self:GetParent():Hide()
	end,
	EditBoxOnEscapePressed = function(self)
		self:GetParent():Hide()
	end,
	timeout = 0,
	exclusive = 1,
	whileDead = 1,
	hideOnEscape = 1,
}

StaticPopupDialogs["SOUNDTRACK_DELETE_CUSTOM_POPUP"] = {
	preferredIndex = 3,
	text = SOUNDTRACK_REMOVE_QUESTION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		SoundtrackFrame_DeleteCustom(SoundtrackFrame_SelectedEvent)
	end,
	enterClicksFirstButton = 1,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

function SoundtrackFrameAddCustomEventButton_OnClick(_)
	StaticPopup_Show("SOUNDTRACK_ADD_CUSTOM_POPUP")
end

function SoundtrackFrame_AddCustomEvent(eventName, self)
	_G["SoundtrackFrameRightPanelTracks"]:Hide()
	_G["SoundtrackFrameRightPanelEditEvent"]:Show()

	if eventName == "" then
		local name = "New Event"
		local index = 1

		local indexedName = name .. " " .. index

		while Soundtrack.GetEvent("Custom", indexedName) ~= nil do
			index = index + 1
			indexedName = name .. " " .. index
		end

		eventName = indexedName
	end

	local script = "-- Custom script\n"
		.. 'Soundtrack_Custom_PlayEvent("Custom", "'
		.. eventName
		.. '") \n'
		.. 'Soundtrack_Custom_StopEvent("Custom", "'
		.. eventName
		.. '") \n'

	Soundtrack.CustomEvents.RegisterEventScript(self, eventName, "Custom", "UNIT_AURA", 4, true, script)
	SoundtrackFrame_SelectedEvent = eventName
	SoundtrackFrame_RefreshEvents()
	SoundtrackFrame_RefreshCustomEvent()
end

function SoundtrackFrameEditCustomEventButton_OnClick()
	_G["SoundtrackFrameRightPanelTracks"]:Hide()
	_G["SoundtrackFrameRightPanelEditEvent"]:Show()

	SoundtrackFrame_RefreshCustomEvent()
end

function SoundtrackFrameSaveCustomEventButton_OnClick()
	Soundtrack.TraceFrame("Saving " .. SoundtrackFrame_SelectedEvent)
	local customEvent = SoundtrackAddon.db.profile.customEvents[SoundtrackFrame_SelectedEvent]

	customEvent.priority = tonumber(getglobal("SoundtrackFrame_Priority"):GetText())
	customEvent.continuous = getglobal("SoundtrackFrame_ContinuousCheckBox"):GetChecked()

	local eventTable = Soundtrack.Events.GetTable("Custom")
	if eventTable[SoundtrackFrame_SelectedEvent] ~= nil then
		eventTable[SoundtrackFrame_SelectedEvent].priority = customEvent.priority
		eventTable[SoundtrackFrame_SelectedEvent].continuous = customEvent.continuous
		eventTable[SoundtrackFrame_SelectedEvent].soundEffect = customEvent.soundEffect
	end

	local eventType = customEvent.type
	Soundtrack.TraceFrame(customEvent.type)
	if eventType == "Event Script" then
		customEvent.eventtype = "Event Script"
		customEvent.trigger = getglobal("SoundtrackFrame_EventTrigger"):GetText()
		Soundtrack.CustomEvents.RegisterTrigger(_G["SoundtrackCustomDUMMY"], customEvent.trigger)
	elseif eventType == "Buff" then
		customEvent.eventtype = "Buff"
		customEvent.spellId = tonumber(getglobal("SoundtrackFrame_EventTrigger"):GetText())
		Soundtrack.TraceFrame(customEvent.spellId)
	elseif eventType == "Debuff" then
		customEvent.eventtype = "Debuff"
		customEvent.spellId = tonumber(getglobal("SoundtrackFrame_EventTrigger"):GetText())
		Soundtrack.TraceFrame(customEvent.spellId)
	elseif eventType == "Update Script" then
		customEvent.eventtype = "Update Script"
	end
	customEvent.script = getglobal("SoundtrackFrame_EventScript"):GetText()

	getglobal("SoundtrackFrameRightPanelEditEvent"):Hide()
	getglobal("SoundtrackFrameRightPanelTracks"):Show()
end

function SoundtrackFrameDeleteCustomEventButton_OnClick()
	if SoundtrackFrame_SelectedEvent then
		StaticPopup_Show("SOUNDTRACK_DELETE_CUSTOM_POPUP")
	end
end

function SoundtrackFrame_DeleteCustom(eventName)
	SoundtrackAddon.db.profile.customEvents[SoundtrackFrame_SelectedEvent] = nil
	Soundtrack.Events.DeleteEvent("Custom", eventName)
	SoundtrackFrame_RefreshEvents()
end
