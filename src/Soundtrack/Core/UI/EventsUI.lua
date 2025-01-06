local function RefreshEventSettings()
	if SoundtrackUI.SelectedEvent then
		suspendRenameEvent = true
		_G["SoundtrackFrame_EventName"]:SetText(SoundtrackUI.SelectedEvent)
		suspendRenameEvent = false

		local eventTable = Soundtrack.Events.GetTable(SoundtrackUI.SelectedEventsTable)
		local event = eventTable[SoundtrackUI.SelectedEvent]
		if event then
			SoundtrackFrame_RandomCheckButton:SetChecked(event.random)
			SoundtrackFrame_ContinuousCheckBox:SetChecked(event.continuous)
			SoundtrackFrame_SoundEffectCheckBox:SetChecked(event.soundEffect)
		end
	end
end

function SoundtrackUI.UpdateEventsUI()
	if not SoundtrackFrame:IsVisible() or not SoundtrackUI.SelectedEventsTable then
		Soundtrack.Chat.TraceFrame("Skipping event refresh")
		return
	end

	Soundtrack.Chat.TraceFrame("SoundtrackUI.SelectedEventsTable: " .. SoundtrackUI.SelectedEventsTable)
	local flatEventsTable = GetFlatEventsTableForCurrentTab()

	-- The selected event was deleted, activate another one if possible
	if SoundtrackUI.SelectedEventsTable and SoundtrackUI.SelectedEvent then
		if not SoundtrackAddon.db.profile.events[SoundtrackUI.SelectedEventsTable][SoundtrackUI.SelectedEvent] then
			if table.maxn(flatEventsTable) > 0 then
				SoundtrackUI.SelectedEvent = flatEventsTable[1].tag
			else
				SoundtrackUI.SelectedEvent = ""
			end
		end
	end

	SoundtrackUI.DisableAllEventButtons()

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
				fo:SetPoint("TOPLEFT", 20, 0)
				fo:SetText(GetLeafText(eventName))
				fo:SetWidth(180)
				fo:SetHeight(16)
				button:SetFontString(fo)

				button:SetNormalFontObject("GameFontHighlightSmall")
				button:SetHighlightFontObject("GameFontNormalSmall")

				button:SetID(buttonIndex)
				button:Show()

				-- Add expandable (+ or -) texture
				local collapserTexture = _G["SoundtrackFrameEventButton" .. buttonIndex .. "CollapserTexture"]
				local expanderTexture = _G["SoundtrackFrameEventButton" .. buttonIndex .. "ExpanderTexture"]
				collapserTexture:Hide()
				expanderTexture:Hide()

				-- Set expandable (+ or -) indent
				local eventDepth = GetEventDepth(eventName)
				local expandTextureIndent = 12 * eventDepth + 2
				collapserTexture:SetPoint("TOPLEFT", expandTextureIndent, 0)
				expanderTexture:SetPoint("TOPLEFT", expandTextureIndent, 0)

				local event = SoundtrackAddon.db.profile.events[SoundtrackUI.SelectedEventsTable][eventName]
				local expandable = eventNode.nodes and #eventNode.nodes >= 1
				if expandable then
					if event.expanded then
						collapserTexture:Show()
						fo:SetText(GetLeafText(eventName))
					else
						expanderTexture:Show()
						fo:SetText(GetLeafText(eventName))
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
				if eventName == SoundtrackUI.SelectedEvent then
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

	SoundtrackUI.RefreshTracks()
	--SoundtrackFrame_RefreshCurrentlyPlaying()
	RefreshEventSettings()
end

function SoundtrackUI.UpdateCustomEventUI()
	local customEvent = SoundtrackAddon.db.profile.customEvents[SoundtrackUI.SelectedEvent]

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
		Soundtrack.Chat.TraceFrame("Nil type on " .. SoundtrackUI.SelectedEvent)
		customEvent.type = ST_UPDATE_SCRIPT
	end

	local eventTypeIndex = IndexOf(EVENT_TYPES, customEvent.type)
	UIDropDownMenu_SetSelectedID(SoundtrackFrame_EventTypeDropDown, eventTypeIndex)
	UIDropDownMenu_SetText(SoundtrackFrame_EventTypeDropDown, customEvent.type)
end

function SoundtrackUI.OnEventButtonClick(self, mouseButton, _)
	Soundtrack.Chat.TraceFrame("EventButton_OnClick")

	Soundtrack.Events.Pause(false)

	local flatEventsTable = GetFlatEventsTableForCurrentTab()
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameEventScrollFrame)
	SoundtrackUI.SelectedEvent = flatEventsTable[self:GetID() + listOffset].tag -- The event name.

	local event = SoundtrackAddon.db.profile.events[SoundtrackUI.SelectedEventsTable][SoundtrackUI.SelectedEvent]
	if mouseButton == "RightButton" then
		-- Do nothing
	elseif event.expanded then
		event.expanded = false
		Soundtrack.Chat.TraceFrame(SoundtrackUI.SelectedEvent .. " is now collapsed")
	else
		event.expanded = true
		Soundtrack.Chat.TraceFrame(SoundtrackUI.SelectedEvent .. " is now expanded")
	end

	Soundtrack.OnEventTreeChanged(SoundtrackUI.SelectedEventsTable)

	SoundtrackUI.UpdateEventsUI()

	if mouseButton == "RightButton" and SoundtrackUI.SelectedEventsTable == "Playlists" then
		Soundtrack.PlayEvent(SoundtrackUI.SelectedEventsTable, SoundtrackUI.SelectedEvent)
	end

	if SoundtrackUI.SelectedEventsTable == "Custom" then
		SoundtrackUI.UpdateCustomEventUI()
	end
end
