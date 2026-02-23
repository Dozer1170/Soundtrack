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
	-- Copy any zones from the zones table into the boss zones table if they are missing.
	-- Also ensure all parent path segments exist so the UI tree renders correctly.
	local zoneTable = Soundtrack.Events.GetTable(ST_ZONE)
	if zoneTable then
		local bossZoneTable = Soundtrack.Events.GetTable(ST_BOSS_ZONES)
		for zonePath, _ in pairs(zoneTable) do
			-- Ensure all ancestor paths (e.g. "Instances" for "Instances/Amirdrassil") exist.
			local parts = StringSplit(zonePath, "/")
			local cumulativePath = ""
			for i, part in ipairs(parts) do
				cumulativePath = i == 1 and part or (cumulativePath .. "/" .. part)
				if bossZoneTable[cumulativePath] == nil then
					Soundtrack.AddEvent(ST_BOSS_ZONES, cumulativePath, ST_BOSS_LVL, true)
				end
			end
		end
	end
end
