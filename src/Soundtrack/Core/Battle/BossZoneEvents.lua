--[[
    Soundtrack addon for World of Warcraft

    Boss Zone events functions.
    Allows users to assign boss-fight music per zone.
    Zones are auto-discovered when boss fights occur.
]]

Soundtrack.BossZoneEvents = {}

-- Reuses zone path logic from ZoneEvents to build hierarchical zone paths.
-- Returns zone paths from most specific to least specific.
function Soundtrack.BossZoneEvents.GetCurrentZonePaths()
	return Soundtrack.ZoneEvents.GetCurrentZonePaths()
end

-- Add the current zone to the Boss Zones event table.
function Soundtrack.BossZoneEvents.AddCurrentZone()
	local zonePaths = Soundtrack.BossZoneEvents.GetCurrentZonePaths()
	if not zonePaths or #zonePaths == 0 then
		return
	end

	for _, zonePath in ipairs(zonePaths) do
		local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
		if eventTable[zonePath] == nil then
			Soundtrack.AddEvent(ST_BOSS_ZONES, zonePath, ST_BOSS_LVL, true)
		end
	end
end

-- Returns the most specific boss zone event for the current location
-- that has tracks assigned, or nil if none found.
function Soundtrack.BossZoneEvents.GetCurrentBossZoneEvent()
	local zonePaths = Soundtrack.BossZoneEvents.GetCurrentZonePaths()
	if not zonePaths or #zonePaths == 0 then
		return nil
	end

	local eventTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
	if not eventTable then
		return nil
	end

	-- zonePaths is ordered most specific to least specific
	for _, zonePath in ipairs(zonePaths) do
		local event = eventTable[zonePath]
		if event and event.tracks and #event.tracks > 0 then
			return zonePath
		end
	end

	return nil
end

function Soundtrack.BossZoneEvents.Initialize()
	-- No pre-populated events. Users discover zones as they encounter boss fights.
end
