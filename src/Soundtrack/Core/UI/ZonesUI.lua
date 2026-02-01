local function GetSelectedZoneTableName()
	if SoundtrackUI.SelectedEventsTable == ST_BOSS_ZONES then
		return ST_BOSS_ZONES
	end

	return ST_ZONE
end

local function RemoveZone(eventName)
	Soundtrack.Events.DeleteEvent(GetSelectedZoneTableName(), eventName)
end

local function ToggleZoneExpansion(expanded)
	local tableName = GetSelectedZoneTableName()
	for _, eventNode in pairs(SoundtrackAddon.db.profile.events[tableName]) do
		eventNode.expanded = expanded
	end
	Soundtrack.OnEventTreeChanged(tableName)
	SoundtrackUI.UpdateEventsUI()
end

function SoundtrackUI.OnAddZoneButtonClick()
	Soundtrack_ZoneEvents_AddZones(GetSelectedZoneTableName())

	-- Select the newly added area.
	local zonePaths = Soundtrack.ZoneEvents.GetCurrentZonePaths()
	if zonePaths and zonePaths[1] then
		SoundtrackUI.SelectedEvent = zonePaths[1]
	else
		SoundtrackUI.SelectedEvent = GetRealZoneText()
	end

	SoundtrackUI.UpdateEventsUI()
end

function SoundtrackUI.OnCollapseAllZoneButtonClick()
	Soundtrack.Chat.TraceFrame("Collapsing all zone events")
	ToggleZoneExpansion(false)
end

function SoundtrackUI.OnExpandAllZoneButtonClick()
	Soundtrack.Chat.TraceFrame("Expanding all zone events")
	ToggleZoneExpansion(true)
end

function SoundtrackUI.OnFrameRemoveZoneButtonClick()
	StaticPopupDialogs["SOUNDTRACK_REMOVE_ZONE_POPUP"] = {
		preferredIndex = 3,
		text = "Do you want to remove this zone?",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(self)
			RemoveZone(SoundtrackUI.SelectedEvent)
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopup_Show("SOUNDTRACK_REMOVE_ZONE_POPUP")
end
