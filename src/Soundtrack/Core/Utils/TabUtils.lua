TabUtils = {}

function TabUtils.GetTabIndex(tableName)
	if tableName == "Battle" then
		return 1
	elseif tableName == "Boss" then
		return 2
	elseif tableName == "Zone" then
		return 3
	elseif tableName == "Pet Battles" then
		return 4
	elseif tableName == "Dance" then
		return 5
	elseif tableName == "Misc" then
		return 6
	elseif tableName == "Custom" then
		return 7
	elseif tableName == "Playlists" then
		return 8
	else
		return 0
	end
end
