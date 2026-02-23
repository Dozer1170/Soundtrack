local function RemoveZone(eventName)
	Soundtrack.Events.DeleteEvent(ST_ZONE, eventName)

	-- Also remove any child zones whose path is prefixed by this zone.
	local prefix = eventName .. "/"
	local eventTable = Soundtrack.Events.GetTable(ST_ZONE)
	if eventTable then
		local toRemove = {}
		for key in pairs(eventTable) do
			if key:sub(1, #prefix) == prefix then
				table.insert(toRemove, key)
			end
		end
		for _, key in ipairs(toRemove) do
			Soundtrack.Events.DeleteEvent(ST_ZONE, key)
		end
	end
end

local function ToggleZoneExpansion(expanded)
	for _, eventNode in pairs(SoundtrackAddon.db.profile.events[ST_ZONE]) do
		eventNode.expanded = expanded
	end
	Soundtrack.OnEventTreeChanged(ST_ZONE)
	SoundtrackUI.UpdateEventsUI()
end

function SoundtrackUI.OnAddZoneButtonClick()
	if SoundtrackUI.SelectedEventsTable == ST_BOSS_ZONES then
		SoundtrackUI.OnAddBossZoneButtonClick()
		return
	end

	Soundtrack_ZoneEvents_AddZones()

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
	if SoundtrackUI.SelectedEventsTable == ST_BOSS_ZONES then
		SoundtrackUI.OnCollapseAllBossZoneButtonClick()
		return
	end

	Soundtrack.Chat.TraceFrame("Collapsing all zone events")
	ToggleZoneExpansion(false)
end

function SoundtrackUI.OnExpandAllZoneButtonClick()
	if SoundtrackUI.SelectedEventsTable == ST_BOSS_ZONES then
		SoundtrackUI.OnExpandAllBossZoneButtonClick()
		return
	end

	Soundtrack.Chat.TraceFrame("Expanding all zone events")
	ToggleZoneExpansion(true)
end

function SoundtrackUI.OnFrameRemoveZoneButtonClick()
	if SoundtrackUI.SelectedEventsTable == ST_BOSS_ZONES then
		SoundtrackUI.OnFrameRemoveBossZoneButtonClick()
		return
	end

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
