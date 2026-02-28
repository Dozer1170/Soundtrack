if not Tests then
	return
end

local Tests = Tests("PetBattlesUI", "PLAYER_ENTERING_WORLD")

local function SetupUI()
	Replace(SoundtrackUI, "UpdateEventsUI", function() end)
end

local function TriggerRemovePetBattleConfirmed()
	Replace(_G, "StaticPopup_Show", function() end)
	SoundtrackUI.OnRemovePetBattleTargetButtonClick()
	StaticPopupDialogs["SOUNDTRACK_REMOVE_PETBATTLETARGET_POPUP"].OnAccept()
end

-- AddPetBattleTarget Tests

function Tests:OnAddPetBattleTargetButtonClick_AddsNpcTarget()
	SetupUI()
	Replace(_G, "UnitName", function() return "Lil' Bling" end)
	Replace(_G, "UnitIsPlayer", function() return false end)

	SoundtrackUI.OnAddPetBattleTargetButtonClick()

	local eventTable = Soundtrack.Events.GetTable(ST_PETBATTLES)
	local eventKey = SOUNDTRACK_PETBATTLES_NAMEDNPCS .. "/Lil' Bling"
	IsTrue(eventTable[eventKey] ~= nil, "NPC target added to pet battles")
end

function Tests:OnAddPetBattleTargetButtonClick_AddsPlayerTarget()
	SetupUI()
	Replace(_G, "UnitName", function() return "Arthuria" end)
	Replace(_G, "UnitIsPlayer", function() return true end)

	SoundtrackUI.OnAddPetBattleTargetButtonClick()

	local eventTable = Soundtrack.Events.GetTable(ST_PETBATTLES)
	local eventKey = SOUNDTRACK_PETBATTLES_PLAYERS .. "/Arthuria"
	IsTrue(eventTable[eventKey] ~= nil, "Player target added to pet battles")
end

function Tests:OnAddPetBattleTargetButtonClick_SetsSelectedEvent()
	SetupUI()
	Replace(_G, "UnitName", function() return "Nexus-Prince Shaffar" end)
	Replace(_G, "UnitIsPlayer", function() return false end)

	SoundtrackUI.SelectedEvent = nil
	SoundtrackUI.OnAddPetBattleTargetButtonClick()

	AreEqual("Nexus-Prince Shaffar", SoundtrackUI.SelectedEvent, "SelectedEvent set to target name")
end

function Tests:OnAddPetBattleTargetButtonClick_WithNoTarget_DoesNotAddEvent()
	SetupUI()
	Replace(_G, "UnitName", function() return nil end)

	local before = {}
	local eventTable = Soundtrack.Events.GetTable(ST_PETBATTLES)
	for k, _ in pairs(eventTable) do before[k] = true end

	SoundtrackUI.OnAddPetBattleTargetButtonClick()

	local after = Soundtrack.Events.GetTable(ST_PETBATTLES)
	local added = 0
	for k, _ in pairs(after) do
		if not before[k] then added = added + 1 end
	end
	AreEqual(0, added, "No event added when target is nil")
end

-- RemovePetBattleTarget Tests

function Tests:OnRemovePetBattleTargetButtonClick_RemovesSelectedEvent()
	SetupUI()
	local eventKey = SOUNDTRACK_PETBATTLES_NAMEDNPCS .. "/Lil' Bling"
	Soundtrack.AddEvent(ST_PETBATTLES, eventKey, ST_NPC_LVL, true)
	SoundtrackUI.SelectedEvent = eventKey

	TriggerRemovePetBattleConfirmed()

	local eventTable = Soundtrack.Events.GetTable(ST_PETBATTLES)
	IsTrue(eventTable[eventKey] == nil, "Selected pet battle event removed")
end
