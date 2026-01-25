local lastLootEventTime = 0
local lastLootEventQuality = -1
local playLootSoundEffectTime = 0
local playLootSoundEffectName

Soundtrack.LootEvents = {}

local function TryPlayLootSoundEffect(itemQuality, eventName)
	local currentTime = GetTime()
	local lootEventDebounceTime = 5
	if currentTime > lastLootEventTime + lootEventDebounceTime or itemQuality > lastLootEventQuality then
		lastLootEventTime = currentTime
		lastLootEventQuality = itemQuality
		local playLootSoundEffectDelay = 0.5
		playLootSoundEffectTime = currentTime + playLootSoundEffectDelay
		playLootSoundEffectName = eventName
	end
end

function Soundtrack.LootEvents.Register()
	SoundtrackMiscDUMMY:RegisterEvent("CHAT_MSG_LOOT")
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_ITEM_GET, ST_SFX_LVL, false, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_ITEM_GET_JUNK, ST_SFX_LVL, false, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_ITEM_GET_COMMON, ST_SFX_LVL, false, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_ITEM_GET_UNCOMMON, ST_SFX_LVL, false, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_ITEM_GET_RARE, ST_SFX_LVL, false, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_ITEM_GET_EPIC, ST_SFX_LVL, false, true)
	Soundtrack.AddEvent(ST_MISC, SOUNDTRACK_ITEM_GET_LEGENDARY, ST_SFX_LVL, false, true)
end

function Soundtrack.LootEvents.OnUpdate()
	if GetTime() > playLootSoundEffectTime and playLootSoundEffectName then
		Soundtrack.PlayEvent(ST_MISC, playLootSoundEffectName)
		playLootSoundEffectName = nil
	end
end

function Soundtrack.LootEvents.OnEvent(eventName, lootString, player)
	if eventName ~= "CHAT_MSG_LOOT" then
		return
	end

	local playerName = UnitName("player")
	Soundtrack.Chat.TraceMisc(
		"Loot message event: "
			.. tostring(lootString)
			.. " player: "
			.. tostring(player)
			.. " current player: "
			.. playerName
	)

	if issecretvalue(lootString) then
		return
	end

	local itemLink = string.match(lootString, "|%x+|Hitem:.-|h.-|h|r")
	if not itemLink then
		return
	end

	local itemString = string.match(itemLink, "item[%-?%d:]+")
	local _, _, quality, _, _, _, _, _, _, _, _, _, _ = GetItemInfo(itemString)

	if string.find(player, playerName) then
		if quality == 0 then
			TryPlayLootSoundEffect(0, SOUNDTRACK_ITEM_GET_JUNK)
		elseif quality == 1 then
			TryPlayLootSoundEffect(1, SOUNDTRACK_ITEM_GET_COMMON)
		elseif quality == 2 then
			TryPlayLootSoundEffect(2, SOUNDTRACK_ITEM_GET_UNCOMMON)
		elseif quality == 3 then
			TryPlayLootSoundEffect(3, SOUNDTRACK_ITEM_GET_RARE)
		elseif quality == 4 then
			TryPlayLootSoundEffect(4, SOUNDTRACK_ITEM_GET_EPIC)
		elseif quality == 5 then
			TryPlayLootSoundEffect(5, SOUNDTRACK_ITEM_GET_LEGENDARY)
		end
	end
end
