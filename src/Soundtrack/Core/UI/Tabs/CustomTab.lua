StaticPopupDialogs["SOUNDTRACK_ADD_CUSTOM_POPUP"] = {
	preferredIndex = 3,
	text = SOUNDTRACK_ENTER_CUSTOM_NAME,
	button1 = ACCEPT,
	button2 = CANCEL,
	hasEditBox = 1,
	maxLetters = 100,
	OnAccept = function(self)
		local eventName = _G[self:GetName() .. "EditBox"]
		SoundtrackFrame_AddCustomEvent(eventName:GetText())
	end,
	OnShow = function(self)
		_G[self:GetName() .. "EditBox"]:SetFocus()
		_G[self:GetName() .. "EditBox"]:SetText("")
	end,
	OnHide = function(_) end,
	EditBoxOnEnterPressed = function(self)
		local eventName = _G[self:GetName()]
		SoundtrackFrame_AddCustomEvent(eventName:GetText())
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
		SoundtrackFrame_DeleteCustom(SoundtrackFrame.SelectedEvent)
	end,
	enterClicksFirstButton = 1,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

function SoundtrackFrameAddCustomEventButton_OnClick(_)
	StaticPopup_Show("SOUNDTRACK_ADD_CUSTOM_POPUP")
end

function SoundtrackFrame_AddCustomEvent(eventName)
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

	Soundtrack.CustomEvents.RegisterEventScript(eventName, "UNIT_AURA", 4, true, script)
	SoundtrackFrame.SelectedEvent = eventName
	SoundtrackFrame_RefreshEvents()
	SoundtrackFrame_RefreshCustomEvent()
end

function SoundtrackFrameEditCustomEventButton_OnClick()
	_G["SoundtrackFrameRightPanelTracks"]:Hide()
	_G["SoundtrackFrameRightPanelEditEvent"]:Show()

	SoundtrackFrame_RefreshCustomEvent()
end

function SoundtrackFrameSaveCustomEventButton_OnClick()
	Soundtrack.Chat.TraceFrame("Saving " .. SoundtrackFrame.SelectedEvent)
	local customEvent = SoundtrackAddon.db.profile.customEvents[SoundtrackFrame.SelectedEvent]

	customEvent.priority = tonumber(getglobal("SoundtrackFrame_Priority"):GetText())
	customEvent.continuous = getglobal("SoundtrackFrame_ContinuousCheckBox"):GetChecked()

	local eventTable = Soundtrack.Events.GetTable("Custom")
	if eventTable[SoundtrackFrame.SelectedEvent] ~= nil then
		eventTable[SoundtrackFrame.SelectedEvent].priority = customEvent.priority
		eventTable[SoundtrackFrame.SelectedEvent].continuous = customEvent.continuous
		eventTable[SoundtrackFrame.SelectedEvent].soundEffect = customEvent.soundEffect
	end

	local eventType = customEvent.type
	Soundtrack.Chat.TraceFrame(customEvent.type)
	if eventType == ST_EVENT_SCRIPT then
		customEvent.eventtype = ST_EVENT_SCRIPT
		customEvent.trigger = getglobal("SoundtrackFrame_EventTrigger"):GetText()
		Soundtrack.CustomEvents.RegisterTrigger(_G["SoundtrackCustomDUMMY"], customEvent.trigger)
	elseif eventType == ST_BUFF_SCRIPT then
		customEvent.eventtype = ST_BUFF_SCRIPT
		customEvent.spellId = tonumber(getglobal("SoundtrackFrame_EventTrigger"):GetText())
		Soundtrack.Chat.TraceFrame(customEvent.spellId)
	elseif eventType == ST_DEBUFF_SCRIPT then
		customEvent.eventtype = ST_DEBUFF_SCRIPT
		customEvent.spellId = tonumber(getglobal("SoundtrackFrame_EventTrigger"):GetText())
		Soundtrack.Chat.TraceFrame(customEvent.spellId)
	elseif eventType == ST_UPDATE_SCRIPT then
		customEvent.eventtype = ST_UPDATE_SCRIPT
	end
	customEvent.script = getglobal("SoundtrackFrame_EventScript"):GetText()

	getglobal("SoundtrackFrameRightPanelEditEvent"):Hide()
	getglobal("SoundtrackFrameRightPanelTracks"):Show()
end

function SoundtrackFrameDeleteCustomEventButton_OnClick()
	if SoundtrackFrame.SelectedEvent then
		StaticPopup_Show("SOUNDTRACK_DELETE_CUSTOM_POPUP")
	end
end

function SoundtrackFrame_DeleteCustom(eventName)
	SoundtrackAddon.db.profile.customEvents[SoundtrackFrame.SelectedEvent] = nil
	Soundtrack.Events.DeleteEvent("Custom", eventName)
	SoundtrackFrame_RefreshEvents()
end
