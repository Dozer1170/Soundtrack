local TRACKS_TO_DISPLAY = 16
local ASSIGNED_TRACKS_TO_DISPLAY = 7

-- Plays a track using a temporary "preview" event on stack level 16
local function PlayPreviewTrack(trackName)
	-- Make sure the preview event exists
	Soundtrack.Events.DeleteEvent(ST_MISC, "Preview")
	Soundtrack.AddEvent(ST_MISC, "Preview", ST_PREVIEW_LVL, true)
	Soundtrack.AssignTrack("Preview", trackName)
	Soundtrack.PlayEvent(ST_MISC, "Preview", true)
end

local function DisableAllTrackButtons()
	for i = 1, TRACKS_TO_DISPLAY, 1 do
		local button = _G["SoundtrackFrameTrackButton" .. i]
		button:Hide()
	end
end

local function DisableAllAssignedTrackButtons()
	for i = 1, ASSIGNED_TRACKS_TO_DISPLAY, 1 do
		local button = _G["SoundtrackAssignedTrackButton" .. i]
		button:Hide()
	end
end

function SoundtrackUI.OnTrackCheckBoxClick(self, _, _)
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameTrackScrollFrame)
	SoundtrackUI.SelectedTrack = Soundtrack_SortedTracks[self:GetID() + listOffset] -- track file name

	if SoundtrackUI.SelectedEvent then
		if Soundtrack.Library.IsTrackActive(SoundtrackUI.SelectedTrack) then
			Soundtrack.Events.Remove(
				SoundtrackUI.SelectedEventsTable,
				SoundtrackUI.SelectedEvent,
				SoundtrackUI.SelectedTrack
			)
		else
			-- Add the track to the events list.
			Soundtrack.AssignTrack(SoundtrackUI.SelectedEvent, SoundtrackUI.SelectedTrack)
		end
	end

	-- To refresh assigned track counts.
	SoundtrackUI.UpdateEventsUI()
	SoundtrackUI.RefreshTracks()
end

function SoundtrackUI.OnAssignedTrackCheckBoxClick(self, _, _)
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameAssignedTracksScrollFrame)

	local assignedTracks =
		SoundtrackAddon.db.profile.events[SoundtrackUI.SelectedEventsTable][SoundtrackUI.SelectedEvent].tracks
	SoundtrackUI.SelectedTrack = assignedTracks[self:GetID() + listOffset] -- track file name

	if Soundtrack.Library.IsTrackActive(SoundtrackUI.SelectedTrack) then
		Soundtrack.Events.Remove(
			SoundtrackUI.SelectedEventsTable,
			SoundtrackUI.SelectedEvent,
			SoundtrackUI.SelectedTrack
		)
	else
		-- Add the track to the events list.
		Soundtrack.AssignTrack(SoundtrackUI.SelectedEvent, SoundtrackUI.SelectedTrack)
	end

	-- To refresh assigned track counts.
	SoundtrackUI.UpdateEventsUI()
	SoundtrackUI.RefreshTracks()
end

function SoundtrackUI.OnTrackButtonClick(self, _, _)
	Soundtrack.Chat.TraceFrame("OnClick")

	Soundtrack.Events.Pause(false)

	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameTrackScrollFrame)
	SoundtrackUI.SelectedTrack = Soundtrack_SortedTracks[self:GetID() + listOffset] -- track file name

	PlayPreviewTrack(SoundtrackUI.SelectedTrack)

	SoundtrackUI.RefreshTracks()
end

function SoundtrackUI.OnAssignedTrackButtonClick(self, _, _)
	Soundtrack.Events.Pause(false)

	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameAssignedTracksScrollFrame)

	local assignedTracks =
		SoundtrackAddon.db.profile.events[SoundtrackUI.SelectedEventsTable][SoundtrackUI.SelectedEvent].tracks

	SoundtrackUI.SelectedTrack = assignedTracks[self:GetID() + listOffset] -- track file name

	PlayPreviewTrack(SoundtrackUI.SelectedTrack)

	SoundtrackUI.RefreshTracks()
end

function SoundtrackUI.OnAllButtonClick()
	-- Start by clearing all tracks
	Soundtrack.Events.ClearEvent(SoundtrackUI.SelectedEventsTable, SoundtrackUI.SelectedEvent)

	-- The highlight all of them
	for i = 1, #Soundtrack_SortedTracks, 1 do
		Soundtrack.AssignTrack(SoundtrackUI.SelectedEvent, Soundtrack_SortedTracks[i])
	end
	SoundtrackUI.UpdateEventsUI()
end

function SoundtrackUI.RefreshTracks()
	if not SoundtrackFrame:IsVisible() or SoundtrackUI.SelectedEventsTable == nil then
		return
	end

	DisableAllTrackButtons()
	local numTracks = table.maxn(Soundtrack_SortedTracks)
	local icon
	local button
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameTrackScrollFrame)
	local buttonIndex
	for i = 1, numTracks, 1 do
		if i > listOffset and i < listOffset + TRACKS_TO_DISPLAY then
			buttonIndex = i - listOffset
			if buttonIndex <= TRACKS_TO_DISPLAY then
				local nameText = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextName"]

				if SoundtrackUI.nameHeaderType == "filePath" or SoundtrackUI.nameHeaderType == nil then
					nameText:SetText(Soundtrack_SortedTracks[i])
				elseif SoundtrackUI.nameHeaderType == "fileName" then
					nameText:SetText(GetPathFileName(Soundtrack_SortedTracks[i]))
				elseif SoundtrackUI.nameHeaderType == "title" then
					nameText:SetText(Soundtrack_Tracks[Soundtrack_SortedTracks[i]].title)
				end

				local albumText = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextAlbum"]
				albumText:SetText(Soundtrack_Tracks[Soundtrack_SortedTracks[i]].album)

				local artistText = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextArtist"]
				artistText:SetText(Soundtrack_Tracks[Soundtrack_SortedTracks[i]].artist)

				button = _G["SoundtrackFrameTrackButton" .. buttonIndex]

				button:SetID(buttonIndex)

				button:Show()

				-- Show duration of track
				local durationLabel = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "ButtonTextDuration"]
				local duration = Soundtrack_Tracks[Soundtrack_SortedTracks[i]].length
				durationLabel:SetText(FormatDuration(duration))

				icon = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "Icon"]
				icon:Hide()

				local checkBox = _G["SoundtrackFrameTrackButton" .. buttonIndex .. "CheckBox"]
				checkBox:SetID(buttonIndex)

				if Soundtrack_SortedTracks[i] == SoundtrackUI.SelectedTrack then
					button:LockHighlight()
				else
					button:UnlockHighlight()
				end

				if SoundtrackUI.SelectedEvent ~= nil then
					-- Update the highlight if that track is active for the event.
					if Soundtrack.Library.IsTrackActive(Soundtrack_SortedTracks[i]) then
						checkBox:SetChecked(true)
					else
						checkBox:SetChecked(false)
					end

					-- Update the icon
					if Soundtrack.Library.CurrentlyPlayingTrack == Soundtrack_SortedTracks[i] then
						icon:Show()
					end
				end
			end
		end
	end

	-- ScrollFrame stuff
	FauxScrollFrame_Update(SoundtrackFrameTrackScrollFrame, numTracks + 1, TRACKS_TO_DISPLAY, EVENTS_ITEM_HEIGHT)

	SoundtrackUI.RefreshAssignedTracks()
end

function SoundtrackUI.RefreshAssignedTracks()
	if not SoundtrackFrame:IsVisible() or SoundtrackUI.SelectedEventsTable == nil then
		return
	end

	DisableAllAssignedTrackButtons()

	if SoundtrackUI.SelectedEvent == nil then
		return
	end

	local event = SoundtrackAddon.db.profile.events[SoundtrackUI.SelectedEventsTable][SoundtrackUI.SelectedEvent]
	if event == nil then
		return
	end

	local icon
	local button
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameAssignedTracksScrollFrame)
	local buttonIndex
	local assignedTracks = event.tracks
	for i = 1, #assignedTracks, 1 do
		if i > listOffset and i < listOffset + ASSIGNED_TRACKS_TO_DISPLAY then
			buttonIndex = i - listOffset
			if buttonIndex <= ASSIGNED_TRACKS_TO_DISPLAY then
				local nameText = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextName"]

				if SoundtrackUI.nameHeaderType == "filePath" or SoundtrackUI.nameHeaderType == nil then
					nameText:SetText(assignedTracks[i])
				elseif SoundtrackUI.nameHeaderType == "fileName" then
					nameText:SetText(GetPathFileName(assignedTracks[i]))
				elseif SoundtrackUI.nameHeaderType == "title" then
					nameText:SetText(Soundtrack_Tracks[assignedTracks[i]].title)
				end

				local albumText = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextAlbum"]
				albumText:SetText(Soundtrack_Tracks[assignedTracks[i]].album)

				local artistText = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextArtist"]
				artistText:SetText(Soundtrack_Tracks[assignedTracks[i]].artist)

				button = _G["SoundtrackAssignedTrackButton" .. buttonIndex]
				button:SetID(buttonIndex)
				button:Show()

				-- Show duration of track
				local durationLabel = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "ButtonTextDuration"]
				local duration = Soundtrack_Tracks[assignedTracks[i]].length
				durationLabel:SetText(FormatDuration(duration))

				icon = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "Icon"]
				icon:Hide()

				local checkBox = _G["SoundtrackAssignedTrackButton" .. buttonIndex .. "CheckBox"]
				checkBox:SetID(buttonIndex)

				if assignedTracks[i] == SoundtrackUI.SelectedTrack then
					button:LockHighlight()
				else
					button:UnlockHighlight()
				end

				if SoundtrackUI.SelectedEvent ~= nil then
					-- Update the highlight if that track is active for the event.
					if Soundtrack.Library.IsTrackActive(assignedTracks[i]) then
						checkBox:SetChecked(true)
					else
						checkBox:SetChecked(false)
					end

					-- Update the icon
					if Soundtrack.Library.CurrentlyPlayingTrack == assignedTracks[i] then
						icon:Show()
					end
				end
			end
		end
	end

	-- ScrollFrame stuff
	FauxScrollFrame_Update(
		SoundtrackFrameAssignedTracksScrollFrame,
		table.getn(assignedTracks) + 1,
		ASSIGNED_TRACKS_TO_DISPLAY,
		EVENTS_ITEM_HEIGHT
	)
end
