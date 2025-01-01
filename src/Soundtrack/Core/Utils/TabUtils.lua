TabUtils = {}

function TabUtils.GetTabIndex(tableName)
	if tableName == ST_BATTLE then
		return 1
	elseif tableName == ST_BOSS then
		return 2
	elseif tableName == ST_ZONE then
		return 3
	elseif tableName == ST_PETBATTLES then
		return 4
	elseif tableName == ST_DANCE then
		return 5
	elseif tableName == ST_MISC then
		return 6
	elseif tableName == ST_CUSTOM then
		return 7
	elseif tableName == ST_PLAYLISTS then
		return 8
	else
		return 0
	end
end
