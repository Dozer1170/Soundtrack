if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_REGEN_DISABLED")

local function MockUnit(unitId, classification, isPlayer, isAlive, isEnemy, isBoss)
	Replace("UnitExists", function(unit)
		return unit == unitId or string.match(unitId, unit)
	end)
	Replace("UnitClassification", function(unit)
		if unit == unitId then
			return classification
		end
		return "normal"
	end)
	Replace("UnitIsPlayer", function(unit)
		return unit == unitId and isPlayer or false
	end)
	Replace("UnitIsDeadOrGhost", function(unit)
		return unit == unitId and not isAlive or false
	end)
	Replace("UnitIsFriend", function(_, unit)
		if unit == unitId then
			return not isEnemy
		end
		return true
	end)
	Replace("UnitCanAttack", function(_, unit)
		return unit == unitId and isEnemy or false
	end)
	Replace("UnitIsBossMob", function(unit)
		return unit == unitId and isBoss or false
	end)
	Replace("UnitCreatureType", function(unit)
		return unit == unitId and "Humanoid" or nil
	end)
end

function Tests:GetClassificationLevel_Minus_ReturnsIndex()
	-- Minus should be at index 1
	AreEqual(1, Soundtrack.BattleEvents.GetClassificationLevel("minus"))
end

function Tests:GetClassificationLevel_Normal_ReturnsIndex()
	-- Normal should be at index 2
	AreEqual(2, Soundtrack.BattleEvents.GetClassificationLevel("normal"))
end

function Tests:GetClassificationLevel_Elite_ReturnsIndex()
	-- Elite should be at index 4
	AreEqual(4, Soundtrack.BattleEvents.GetClassificationLevel("elite"))
end

function Tests:GetClassificationLevel_RareElite_ReturnsIndex()
	-- RareElite should be at index 5
	AreEqual(5, Soundtrack.BattleEvents.GetClassificationLevel("rareelite"))
end

function Tests:GetClassificationLevel_Boss_ReturnsIndex()
	-- Boss should be at index 7
	AreEqual(7, Soundtrack.BattleEvents.GetClassificationLevel("boss"))
end

function Tests:GetClassificationLevel_InvalidClassification_ReturnsZero()
	AreEqual(0, Soundtrack.BattleEvents.GetClassificationLevel("unknowntype"))
end

function Tests:GetClassificationLevel_InvalidClassification_LogsTrace()
	local traceLogged = false
	Replace(Soundtrack.Chat, "TraceBattle", function(msg)
		if string.match(msg, "Cannot find classification : unknowntype") then
			traceLogged = true
		end
	end)
	
	Soundtrack.BattleEvents.GetClassificationLevel("unknowntype")
	
	Exists(traceLogged and "Trace logged" or nil)
end

function Tests:GetGroupEnemyClassification_WithMinusEnemy_ReturnsMinus()
	MockUnit("playertarget", "minus", false, true, true, false)
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player" or unit == "playertarget"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual("minus", classification)
	IsFalse(pvpEnabled)
end

function Tests:GetGroupEnemyClassification_WithNormalEnemy_ReturnsNormal()
	MockUnit("playertarget", "normal", false, true, true, false)
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player" or unit == "playertarget"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual("normal", classification)
	IsFalse(pvpEnabled)
end

function Tests:GetGroupEnemyClassification_WithEliteEnemy_ReturnsElite()
	MockUnit("playertarget", "elite", false, true, true, false)
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player" or unit == "playertarget"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual("elite", classification)
	IsFalse(pvpEnabled)
end

function Tests:GetGroupEnemyClassification_WithBoss_ReturnsBossFlag()
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player" or unit == "boss1"
	end)
	Replace("UnitClassification", function(unit)
		if unit == "boss1" then
			return "elite"
		end
		return "normal"
	end)
	Replace("UnitIsFriend", function(_, unit)
		return unit ~= "boss1"
	end)
	Replace("UnitIsDeadOrGhost", function(unit)
		return false
	end)
	Replace("UnitIsPlayer", function(unit)
		return false
	end)
	Replace("UnitCanAttack", function(_, unit)
		return unit == "boss1"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual("boss", classification)
	IsFalse(pvpEnabled)
end

function Tests:GetGroupEnemyClassification_WithPlayerEnemy_ReturnsPvPFlag()
	MockUnit("playertarget", "normal", true, true, true, false)
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player" or unit == "playertarget"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual(true, pvpEnabled)
end

function Tests:GetGroupEnemyClassification_WithNoEnemies_ReturnsNone()
	Replace("GetNumGroupMembers", function()
		return 0
	end)
	Replace("GetNumSubgroupMembers", function()
		return 0
	end)
	Replace("UnitExists", function(unit)
		return unit == "player"
	end)
	
	local classification, pvpEnabled = Soundtrack.BattleEvents.GetGroupEnemyClassification()
	
	AreEqual("minus", classification)
	IsFalse(pvpEnabled)
end
