if not Tests then
	return
end

local Tests = Tests("TabUtils", "PLAYER_ENTERING_WORLD")

-- GetTabIndex Tests

function Tests:GetTabIndex_Battle_Returns1()
	AreEqual(1, TabUtils.GetTabIndex(ST_BATTLE), "ST_BATTLE maps to tab 1")
end

function Tests:GetTabIndex_Boss_Returns2()
	AreEqual(2, TabUtils.GetTabIndex(ST_ENCOUNTER), "ST_ENCOUNTER maps to tab 2")
end

function Tests:GetTabIndex_Zone_Returns3()
	AreEqual(3, TabUtils.GetTabIndex(ST_ZONE), "ST_ZONE maps to tab 3")
end

function Tests:GetTabIndex_PetBattles_Returns4()
	AreEqual(4, TabUtils.GetTabIndex(ST_PETBATTLES), "ST_PETBATTLES maps to tab 4")
end

function Tests:GetTabIndex_Dance_Returns5()
	AreEqual(5, TabUtils.GetTabIndex(ST_DANCE), "ST_DANCE maps to tab 5")
end

function Tests:GetTabIndex_Misc_Returns6()
	AreEqual(6, TabUtils.GetTabIndex(ST_MISC), "ST_MISC maps to tab 6")
end

function Tests:GetTabIndex_Playlists_Returns7()
	AreEqual(7, TabUtils.GetTabIndex(ST_PLAYLISTS), "ST_PLAYLISTS maps to tab 7")
end

function Tests:GetTabIndex_UnknownTable_Returns0()
	AreEqual(0, TabUtils.GetTabIndex("SomeUnknownTable"), "Unknown table name returns 0")
end
