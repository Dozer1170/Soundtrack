Soundtrack.DanceEvents = {}

function Soundtrack.DanceEvents.OnLoad(self)
	self:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
end

function Soundtrack.DanceEvents.OnEvent(_, event, ...)
	local arg1, arg2 = ...

	Soundtrack.Chat.TraceCustom(event)
	if not SoundtrackAddon.db.profile.settings.EnableMiscMusic then
		return
	end
	if event == "CHAT_MSG_TEXT_EMOTE" then
		for _, emote in ipairs(SOUNDTRACK_DANCE_EMOTES) do
			if string.find(arg1, emote) then
				-- Check if the dance is initated by the player
				if UnitName("player") == arg2 then
					local raceName = UnitRace("player")
					local sex = UnitSex("player")
					if sex == 2 then
						Soundtrack.PlayEvent(ST_DANCE, raceName .. " male")
					elseif sex == 3 then
						Soundtrack.PlayEvent(ST_DANCE, raceName .. " female")
					end
				end
				break
			end
		end
	end
end

function Soundtrack.DanceEvents.Initialize()
	Soundtrack.AddEvent(ST_DANCE, "Human male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Human female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Dwarf male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Dwarf female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Gnome male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Gnome female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Night Elf male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Night Elf female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Undead male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Undead female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Orc male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Orc female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Tauren male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Tauren female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Troll male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Troll female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Blood Elf male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Blood Elf female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Draenei male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Draenei female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Worgen male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Worgen female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Goblin male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Goblin female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Pandaren male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Pandaren female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Dracthyr male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Dracthyr female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Void Elf male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Void Elf female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Lightforged Draenei male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Lightforged Draenei female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Dark Iron Dwarf male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Dark Iron Dwarf female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Kul Tiran male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Kul Tiran female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Mechagnome male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Mechagnome female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Earthen male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Earthen female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Vulpera male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Vulpera female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Zandalari Troll male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Zandalari Troll female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Mag'har Orc male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Mag'har Orc female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Highmountain Tauren male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Highmountain Tauren female", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Nightborne male", ST_ONCE_LVL, false)
	Soundtrack.AddEvent(ST_DANCE, "Nightborne female", ST_ONCE_LVL, false)
end
