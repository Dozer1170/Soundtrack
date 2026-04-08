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
				fo:SetTextColor(1, 1, 1)
				fo:SetPoint("TOPLEFT", 20, 0)
				fo:SetText(GetLeafText(eventName))
				fo:SetWidth(180)
				fo:SetHeight(16)
				button:SetFontString(fo)

				button:SetNormalFontObject("GameFontHighlightSmall")
				button:SetHighlightFontObject("GameFontHighlightSmall")

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
						local ac = SoundtrackTheme.Colors.accent
					if event.expanded then
						collapserTexture:SetVertexColor(ac.r, ac.g, ac.b)
						collapserTexture:Show()
						fo:SetText(GetLeafText(eventName))
					else
						expanderTexture:SetVertexColor(ac.r, ac.g, ac.b)
						expanderTexture:Show()
						fo:SetText(GetLeafText(eventName))
					end
					button:UnlockHighlight()
				end

				local numAssignedTracks = table.getn(event.tracks or {})
				local tempText = button:GetText()
				fo:SetText(tempText .. " (" .. numAssignedTracks .. ")")

				local icon = _G["SoundtrackFrameEventButton" .. buttonIndex .. "Icon"]
				icon:Hide()

				-- Update the highlight if that track is active for the event.
				if eventName == SoundtrackUI.SelectedEvent then
					if not button._selectedBg then
						local bg = button:CreateTexture(nil, "BACKGROUND")
						bg:SetAllPoints()
						button._selectedBg = bg
						local bar = button:CreateTexture(nil, "OVERLAY")
						bar:SetSize(3, 14)
						bar:SetPoint("LEFT", button, "LEFT", 0, 0)
						button._activeBar = bar
					end
					local as = SoundtrackTheme.Colors.accentSubtle
					button._selectedBg:SetColorTexture(as.r, as.g, as.b, as.a)
					local ac = SoundtrackTheme.Colors.accent
					button._activeBar:SetColorTexture(ac.r, ac.g, ac.b, 1.0)
					button._selectedBg:Show()
					button._activeBar:Show()
					button:UnlockHighlight()
					local ta = SoundtrackTheme.Colors.textActive
					fo:SetTextColor(ta.r, ta.g, ta.b)
				else
					if button._selectedBg then button._selectedBg:Hide() end
					if button._activeBar then button._activeBar:Hide() end
					fo:SetTextColor(1, 1, 1)
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
end
