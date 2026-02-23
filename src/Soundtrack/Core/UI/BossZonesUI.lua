local function RemoveBossZone(eventName)
	Soundtrack.Events.DeleteEvent(ST_BOSS_ZONES, eventName)

	-- Also remove any child zones whose path is prefixed by this zone.
	local prefix = eventName .. "/"
	local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	if eventTable then
		local toRemove = {}
		for key in pairs(eventTable) do
			if key:sub(1, #prefix) == prefix then
				table.insert(toRemove, key)
			end
		end
		for _, key in ipairs(toRemove) do
			Soundtrack.Events.DeleteEvent(ST_BOSS_ZONES, key)
		end
	end
end

local function ToggleBossZoneExpansion(expanded)
	for _, eventNode in pairs(SoundtrackAddon.db.profile.events[ST_BOSS_ZONES]) do
		eventNode.expanded = expanded
	end
	Soundtrack.OnEventTreeChanged(ST_BOSS_ZONES)
	SoundtrackUI.UpdateEventsUI()
end

function SoundtrackUI.OnAddBossZoneButtonClick()
	Soundtrack.BossZoneEvents.AddCurrentZone()

	-- Select the newly added area.
	local zonePaths = Soundtrack.ZoneEvents.GetCurrentZonePaths()
	if zonePaths and zonePaths[1] then
		SoundtrackUI.SelectedEvent = zonePaths[1]
	else
		SoundtrackUI.SelectedEvent = GetRealZoneText()
	end

	SoundtrackUI.UpdateEventsUI()
end

function SoundtrackUI.OnCollapseAllBossZoneButtonClick()
	Soundtrack.Chat.TraceFrame("Collapsing all boss zone events")
	ToggleBossZoneExpansion(false)
end

function SoundtrackUI.OnExpandAllBossZoneButtonClick()
	Soundtrack.Chat.TraceFrame("Expanding all boss zone events")
	ToggleBossZoneExpansion(true)
end

function SoundtrackUI.OnFrameRemoveBossZoneButtonClick()
	StaticPopupDialogs["SOUNDTRACK_REMOVE_BOSS_ZONE_POPUP"] = {
		preferredIndex = 3,
		text = "Do you want to remove this boss zone?",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(self)
			RemoveBossZone(SoundtrackUI.SelectedEvent)
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopup_Show("SOUNDTRACK_REMOVE_BOSS_ZONE_POPUP")
end
