StaticPopupDialogs["SOUNDTRACK_DELETE_MISC_POPUP"] = {
	preferredIndex = 3,
	text = SOUNDTRACK_REMOVE_QUESTION,
	button1 = ACCEPT,
	button2 = CANCEL,
	OnAccept = function()
		SoundtrackFrame_DeleteMisc(SoundtrackFrame_SelectedEvent)
	end,
	enterClicksFirstButton = 1,
	timeout = 0,
	whileDead = 1,
	hideOnEscape = 1,
}

function SoundtrackFrameDeleteMiscEventButton_OnClick()
	if SoundtrackFrame_SelectedEvent then
		StaticPopup_Show("SOUNDTRACK_DELETE_MISC_POPUP")
	end
end

function SoundtrackFrame_DeleteMisc(eventName)
	Soundtrack.Events.DeleteEvent("Misc", eventName)
	SoundtrackFrame_RefreshEvents()
end