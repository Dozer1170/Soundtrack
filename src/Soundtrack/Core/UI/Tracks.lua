-- Plays a track using a temporary "preview" event on stack level 16
local function PlayPreviewTrack(trackName)
	-- Make sure the preview event exists
	Soundtrack.Events.DeleteEvent(ST_MISC, "Preview")
	Soundtrack.AddEvent(ST_MISC, "Preview", ST_PREVIEW_LVL, true)
	Soundtrack.AssignTrack("Preview", trackName)
	Soundtrack.PlayEvent(ST_MISC, "Preview", true)
end

function SoundtrackFrame.TrackMenuInitialize()
	-- Remove track
	local info = {}
	info.text = SOUNDTRACK_REMOVE_TRACK
	info.value = "RemoveTrack"
	info.func = function(_)
		Soundtrack.Library.RemoveTrackWithConfirmation()
	end
	info.notCheckable = 1
	UIDropDownMenu_AddButton(info, 1)
end

function SoundtrackFrame.OnTrackCheckBoxClick(self, _, _)
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameTrackScrollFrame)
	SoundtrackFrame.SelectedTrack = Soundtrack_SortedTracks[self:GetID() + listOffset] -- track file name

	if SoundtrackFrame.SelectedEvent then
		if Soundtrack.Library.IsTrackActive(SoundtrackFrame.SelectedTrack) then
			Soundtrack.Events.Remove(
				SoundtrackFrame.SelectedEventsTable,
				SoundtrackFrame.SelectedEvent,
				SoundtrackFrame.SelectedTrack
			)
		else
			-- Add the track to the events list.
			Soundtrack.AssignTrack(SoundtrackFrame.SelectedEvent, SoundtrackFrame.SelectedTrack)
		end
	end

	-- To refresh assigned track counts.
	SoundtrackFrame.UpdateEventsUI()
	SoundtrackFrame_RefreshTracks()
end

function SoundtrackFrame.OnAssignedTrackCheckBoxClick(self, _, _)
	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameAssignedTracksScrollFrame)

	local assignedTracks =
		SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][SoundtrackFrame.SelectedEvent].tracks
	SoundtrackFrame.SelectedTrack = assignedTracks[self:GetID() + listOffset] -- track file name

	if Soundtrack.Library.IsTrackActive(SoundtrackFrame.SelectedTrack) then
		Soundtrack.Events.Remove(
			SoundtrackFrame.SelectedEventsTable,
			SoundtrackFrame.SelectedEvent,
			SoundtrackFrame.SelectedTrack
		)
	else
		-- Add the track to the events list.
		Soundtrack.AssignTrack(SoundtrackFrame.SelectedEvent, SoundtrackFrame.SelectedTrack)
	end

	-- To refresh assigned track counts.
	SoundtrackFrame.UpdateEventsUI()
	SoundtrackFrame_RefreshTracks()
end

function SoundtrackFrame.OnTrackButtonClick(self, _, _)
	Soundtrack.Chat.TraceFrame("OnClick")

	Soundtrack.Events.Pause(false)

	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameTrackScrollFrame)
	SoundtrackFrame.SelectedTrack = Soundtrack_SortedTracks[self:GetID() + listOffset] -- track file name

	PlayPreviewTrack(SoundtrackFrame.SelectedTrack)

	SoundtrackFrame_RefreshTracks()
end

function SoundtrackFrame.OnAssignedTrackButtonClick(self, _, _)
	Soundtrack.Events.Pause(false)

	local listOffset = FauxScrollFrame_GetOffset(SoundtrackFrameAssignedTracksScrollFrame)

	local assignedTracks =
		SoundtrackAddon.db.profile.events[SoundtrackFrame.SelectedEventsTable][SoundtrackFrame.SelectedEvent].tracks

	SoundtrackFrame.SelectedTrack = assignedTracks[self:GetID() + listOffset] -- track file name

	PlayPreviewTrack(SoundtrackFrame.SelectedTrack)

	SoundtrackFrame_RefreshTracks()
end

function SoundtrackFrame.OnAllButtonClick()
	-- Start by clearing all tracks
	Soundtrack.Events.ClearEvent(SoundtrackFrame.SelectedEventsTable, SoundtrackFrame.SelectedEvent)

	-- The highlight all of them
	for i = 1, #Soundtrack_SortedTracks, 1 do
		Soundtrack.AssignTrack(SoundtrackFrame.SelectedEvent, Soundtrack_SortedTracks[i])
	end
	SoundtrackFrame.UpdateEventsUI()
end
