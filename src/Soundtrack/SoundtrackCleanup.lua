Soundtrack.Cleanup = {}

local function CleanupTableEvents(savedEventTable, liveEventTable)
	for key, _ in pairs(savedEventTable) do
		if liveEventTable[key] == nil and key ~= "Preview" then
			savedEventTable[key] = nil
			DEFAULT_CHAT_FRAME:AddMessage(
				"Soundtrack: Found obsolete event " .. key .. " removing from saved data.",
				1.0,
				0.0,
				0.0
			)
		end
	end
end

function Soundtrack.Cleanup.CleanupOldEvents()
	CleanupTableEvents(SoundtrackAddon.db.profile.events[ST_MISC], Soundtrack.RegisteredEvents[ST_MISC])

	SoundtrackFrame_RefreshEvents()
end
