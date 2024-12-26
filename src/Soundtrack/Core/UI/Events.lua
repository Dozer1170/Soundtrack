local function RefreshEventSettings()
	if SoundtrackFrame.SelectedEvent then
		suspendRenameEvent = true
		_G["SoundtrackFrame_EventName"]:SetText(SoundtrackFrame.SelectedEvent)
		suspendRenameEvent = false

		local eventTable = Soundtrack.Events.GetTable(SoundtrackFrame.SelectedEventsTable)
		local event = eventTable[SoundtrackFrame.SelectedEvent]
		if event then
			SoundtrackFrame_RandomCheckButton:SetChecked(event.random)
			SoundtrackFrame_ContinuousCheckBox:SetChecked(event.continuous)
			SoundtrackFrame_SoundEffectCheckBox:SetChecked(event.soundEffect)
		end
	end
end

function SoundtrackFrame.UpdateEventsUI()
	if not SoundtrackFrame:IsVisible() or not SoundtrackFrame.SelectedEventsTable then
		Soundtrack.Chat.TraceFrame("Skipping event refresh")
		return
	end

	Soundtrack.Chat.TraceFrame("SoundtrackFrame.SelectedEventsTable: " .. SoundtrackFrame.SelectedEventsTable)
	local flatEventsTable = GetFlatEventsTable()

	-- The selected event was deleted, activate another one if possible
	if SoundtrackFrame.SelectedEventsTable and SoundtrackFrame.SelectedEvent then
		if
			not SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][SoundtrackFrame.SelectedEvent]
		then
			if table.maxn(flatEventsTable) > 0 then
				SoundtrackFrame.SelectedEvent = flatEventsTable[1].tag
			else
				SoundtrackFrame.SelectedEvent = ""
			end
		end
	end

	SoundtrackFrame_DisableAllEventButtons()

	local numEvents = #flatEventsTable
	local button
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameEventScrollFrame)
	local buttonIndex
	local stackLevel = Soundtrack.Events.GetCurrentStackLevel()
	local currentEvent
	if stackLevel ~= 0 then
		currentEvent = Soundtrack.Events.Stack[stackLevel].eventName
	end

	for i, eventNode in ipairs(flatEventsTable) do
		local eventName = eventNode.tag or error("nil event!")

		if i > listOffset and i < listOffset + EVENTS_TO_DISPLAY then
			buttonIndex = i - listOffset
			if buttonIndex <= EVENTS_TO_DISPLAY then
				button = _G["SoundtrackFrameEventButton" .. buttonIndex]
				local fo = button:CreateFontString()
				fo:SetJustifyH("LEFT")
				fo:SetFont("Fonts/FRIZQT__.TTF", 10)
				fo:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
				fo:SetText(GetLeafText(eventName))
				fo:SetWidth(180)
				fo:SetHeight(16)
				button:SetFontString(fo)

				button:SetNormalFontObject("GameFontHighlightSmall")
				button:SetHighlightFontObject("GameFontNormalSmall")

				button:SetID(buttonIndex)
				button:Show()

				local event = SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][eventName]

				-- Add expandable (+ or -) texture
				local collapserTexture = _G["SoundtrackFrameEventButton" .. buttonIndex .. "CollapserTexture"]
				local expanderTexture = _G["SoundtrackFrameEventButton" .. buttonIndex .. "ExpanderTexture"]
				collapserTexture:Hide()
				expanderTexture:Hide()

				local eventDepth = GetEventDepth(eventName)
				local expandTextureIndent = 16 * eventDepth
				collapserTexture:SetPoint("TOPLEFT", expandTextureIndent, 0)
				expanderTexture:SetPoint("TOPLEFT", expandTextureIndent, 0)

				local expandable = eventNode.nodes and #eventNode.nodes >= 1
				if expandable then
					if event.expanded then
						collapserTexture:Show()
						fo:SetText("    " .. GetLeafText(eventName))
					else
						expanderTexture:Show()
						fo:SetText("    " .. GetLeafText(eventName))
					end
					button:UnlockHighlight()
				else
					button:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
					expanderTexture:Hide()
				end

				-- Show number of assigned tracks
				if event then
					local numAssignedTracks = table.maxn(event.tracks)
					if numAssignedTracks == 0 then
						local tempText = button:GetText()
						fo:SetText(tempText .. "   ")
					else
						local tempText = button:GetText()
						fo:SetText(tempText .. " (" .. numAssignedTracks .. ")")
					end
				end

				local icon = _G["SoundtrackFrameEventButton" .. buttonIndex .. "Icon"]
				icon:Hide()

				-- Update the highlight if that track is active for the event.
				if eventName == SoundtrackFrame.SelectedEvent then
					button:SetHighlightTexture("Interface/QuestFrame/UI-QuestTitleHighlight")
					button:LockHighlight()
				else
					button:UnlockHighlight()
				end

				-- Update the icon
				if currentEvent == eventName then
					icon:Show()
				end
			end
		end
		--i = i + 1
	end

	-- ScrollFrame stuff
	FauxScrollFrame_Update(SoundtrackFrameEventScrollFrame, numEvents + 1, EVENTS_TO_DISPLAY, EVENTS_ITEM_HEIGHT)

	SoundtrackFrame_RefreshTracks()
	--SoundtrackFrame_RefreshCurrentlyPlaying()
	RefreshEventSettings()
end

function SoundtrackFrame.UpdateCustomEventUI()
	local customEvent = SoundtrackAddon.db.profile.customEvents[SoundtrackFrame.SelectedEvent]

	if customEvent == nil then
		return
	end

	if customEvent then
		_G["SoundtrackFrame_Priority"]:SetText(tostring(customEvent.priority))
		if customEvent.type == ST_EVENT_SCRIPT then
			_G["SoundtrackFrame_FontStringTrigger"]:SetText("Trigger")
			_G["SoundtrackFrame_EventTrigger"]:SetText(customEvent.trigger)
			_G["SoundtrackFrame_EventScript"]:SetText(customEvent.script)
		elseif customEvent.type == ST_BUFF_SCRIPT then
			_G["SoundtrackFrame_FontStringTrigger"]:SetText("Spell ID")
			_G["SoundtrackFrame_EventTrigger"]:SetText(customEvent.spellId)
			_G["SoundtrackFrame_EventScript"]:SetText(
				"Buff events do not need a script.\nThey remain active while the specified buff is active."
			)
		elseif customEvent.type == ST_UPDATE_SCRIPT then
			_G["SoundtrackFrame_FontStringTrigger"]:SetText("Trigger")
			_G["SoundtrackFrame_EventTrigger"]:SetText("OnUpdate")
			_G["SoundtrackFrame_EventScript"]:SetText(customEvent.script)
		end
	end

	if customEvent.type == nil then
		Soundtrack.Chat.TraceFrame("Nil type on " .. SoundtrackFrame.SelectedEvent)
		customEvent.type = ST_UPDATE_SCRIPT
	end

	local eventTypeIndex = IndexOf(EVENT_TYPES, customEvent.type)
	UIDropDownMenu_SetSelectedID(SoundtrackFrame_EventTypeDropDown, eventTypeIndex)
	UIDropDownMenu_SetText(SoundtrackFrame_EventTypeDropDown, customEvent.type)
end

function SoundtrackFrame.OnEventButtonClick(self, mouseButton, _)
	Soundtrack.Chat.TraceFrame("EventButton_OnClick")

	Soundtrack.Events.Pause(false)

	local flatEventsTable = GetFlatEventsTable()
	local button = _G["SoundtrackFrameEventButton" .. self:GetID() .. "ButtonTextName"]
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameEventScrollFrame)
	SoundtrackFrame.SelectedEvent = flatEventsTable[self:GetID() + listOffset].tag -- The event name.

	local event = SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][SoundtrackFrame.SelectedEvent]
	if mouseButton == "RightButton" then
		-- Do nothing
	elseif event.expanded then
		event.expanded = false
		Soundtrack.Chat.TraceFrame(SoundtrackFrame.SelectedEvent .. " is now collapsed")
	else
		event.expanded = true
		Soundtrack.Chat.TraceFrame(SoundtrackFrame.SelectedEvent .. " is now expanded")
	end

	SoundtrackFrame.OnEventTreeChanged(SoundtrackFrame.SelectedEventsTable)

	SoundtrackFrame.UpdateEventsUI()

	if mouseButton == "RightButton" and SoundtrackFrame.SelectedEventsTable == "Zone" then
		-- Toggle menu
		local menu = _G["SoundtrackFrameEventMenu"]
		menu.point = "TOPRIGHT"
		menu.relativePoint = "CENTER"
		ToggleDropDownMenu(1, nil, menu, button, 0, 0)
	elseif SoundtrackFrame.SelectedEventsTable == "Playlists" then
		Soundtrack.PlayEvent(SoundtrackFrame.SelectedEventsTable, SoundtrackFrame.SelectedEvent)
	end

	if SoundtrackFrame.SelectedEventsTable == "Custom" then
		SoundtrackFrame.UpdateCustomEventUI()
	end
end

function SoundtrackFrame.EventMenuInitialize() end
