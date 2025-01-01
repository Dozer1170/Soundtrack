local function RemoveZone(eventName)
	Soundtrack.Events.DeleteEvent("Zone", eventName)
end

local function ToggleZoneExpansion(expanded)
	for _, eventNode in pairs(SoundtrackAddon.db.profile.events["Zone"]) do
		eventNode.expanded = expanded
	end
	SoundtrackFrame.OnEventTreeChanged("Zone")
	SoundtrackFrame.UpdateEventsUI()
end

function SoundtrackFrame.OnAddZoneButtonClick()
	Soundtrack_ZoneEvents_AddZones()

	-- Select the newly added area.
	if GetSubZoneText() ~= nil then
		SoundtrackFrame.SelectedEvent = GetSubZoneText()
	else
		SoundtrackFrame.SelectedEvent = GetRealZoneText()
	end

	SoundtrackFrame.UpdateEventsUI()
end

function SoundtrackFrame.OnCollapseAllZoneButtonClick()
	Soundtrack.Chat.TraceFrame("Collapsing all zone events")
	ToggleZoneExpansion(false)
end

function SoundtrackFrame.OnExpandAllZoneButtonClick()
	Soundtrack.Chat.TraceFrame("Expanding all zone events")
	ToggleZoneExpansion(true)
end

function SoundtrackFrame.OnFrameRemoveZoneButtonClick()
	StaticPopupDialogs["SOUNDTRACK_REMOVE_ZONE_POPUP"] = {
		preferredIndex = 3,
		text = "Do you want to remove this zone?",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(self)
			RemoveZone(SoundtrackFrame.SelectedEvent)
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopup_Show("SOUNDTRACK_REMOVE_ZONE_POPUP")
end
