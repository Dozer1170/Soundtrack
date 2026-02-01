local function AddPetBattleTarget(targetName, isPlayer)
	if isPlayer then
		Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_PLAYERS .. "/" .. targetName, ST_NPC_LVL, true)
	else
		Soundtrack.AddEvent(ST_PETBATTLES, SOUNDTRACK_PETBATTLES_NAMEDNPCS .. "/" .. targetName, ST_NPC_LVL, true)
	end
	SoundtrackUI.SelectedEvent = targetName
	SoundtrackUI.UpdateEventsUI()
end

local function RemovePetBattleTarget(eventName)
	Soundtrack.Events.DeleteEvent(ST_PETBATTLES, eventName)
end

function SoundtrackUI.OnAddPetBattleTargetButtonClick()
	local targetName = UnitName("target")
	local isPlayer
	if UnitIsPlayer("target") then
		isPlayer = true
	else
		isPlayer = false
	end
	if targetName then
		AddPetBattleTarget(targetName, isPlayer)
	end
end

function SoundtrackUI.OnRemovePetBattleTargetButtonClick()
	StaticPopupDialogs["SOUNDTRACK_REMOVE_PETBATTLETARGET_POPUP"] = {
		preferredIndex = 3,
		text = "Do you want to remove this pet battle event?",
		button1 = ACCEPT,
		button2 = CANCEL,
		OnAccept = function(_)
			RemovePetBattleTarget(SoundtrackUI.SelectedEvent)
		end,
		timeout = 0,
		whileDead = 1,
		hideOnEscape = 1,
	}

	StaticPopup_Show("SOUNDTRACK_REMOVE_PETBATTLETARGET_POPUP")
end
