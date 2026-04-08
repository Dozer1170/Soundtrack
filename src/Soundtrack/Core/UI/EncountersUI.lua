--[[
    Soundtrack addon for World of Warcraft

    Encounters tab UI functions.
    Encounter entries are auto-added when ENCOUNTER_START fires.
    Users assign tracks to encounters here and can remove entries they no longer need.
]]

function SoundtrackUI.OnRemoveEncounterButtonClick()
	if not SoundtrackUI.SelectedEvent then
		return
	end
	StaticPopupDialogs["SOUNDTRACK_REMOVE_ENCOUNTER_POPUP"] = {
		preferredIndex = 3,
		text = SOUNDTRACK_ENCOUNTER_REMOVE_TIP,
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function()
			Soundtrack.Events.DeleteEvent(ST_ENCOUNTER, SoundtrackUI.SelectedEvent, true)
			SoundtrackUI.UpdateEventsUI()
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}
	StaticPopup_Show("SOUNDTRACK_REMOVE_ENCOUNTER_POPUP")
end

local function ToggleEncounterExpansion(expanded)
	for _, eventNode in pairs(SoundtrackAddon.db.profile.events[ST_ENCOUNTER]) do
		eventNode.expanded = expanded
	end
	Soundtrack.OnEventTreeChanged(ST_ENCOUNTER)
	SoundtrackUI.UpdateEventsUI()
end

function SoundtrackUI.OnCollapseAllEncounterButtonClick()
	Soundtrack.Chat.TraceFrame("Collapsing all encounter events")
	ToggleEncounterExpansion(false)
end

function SoundtrackUI.OnExpandAllEncounterButtonClick()
	Soundtrack.Chat.TraceFrame("Expanding all encounter events")
	ToggleEncounterExpansion(true)
end
