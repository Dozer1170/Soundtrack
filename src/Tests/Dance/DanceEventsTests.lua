if not Tests then
	return
end

local Tests = Tests("Soundtrack", "CHAT_MSG_TEXT_EMOTE")

function Tests:OnLoad_RegistersChatEmoteEvent()
	local eventRegistered = false
	local eventName = nil
	Replace(Soundtrack.DanceEvents, "OnLoad", function(self)
		self:RegisterEvent("CHAT_MSG_TEXT_EMOTE")
		eventRegistered = true
		eventName = "CHAT_MSG_TEXT_EMOTE"
	end)

	local frame = {}
	Soundtrack.DanceEvents.OnLoad(frame)

	AreEqual(true, eventRegistered)
	AreEqual("CHAT_MSG_TEXT_EMOTE", eventName)
end

function Tests:OnEvent_DanceEmoteByPlayer_PlaysCorrectGender()
	Replace("UnitName", function(unit)
		if unit == "player" then
			return "TestPlayer"
		end
		return nil
	end)
	Replace("UnitRace", function()
		return "Human"
	end)
	Replace("UnitSex", function()
		return 2 -- Male
	end)
	Replace(Soundtrack, "PlayEvent", function(eventType, eventName)
		AreEqual("Human male", eventName)
	end)
	Replace(SoundtrackAddon.db, "profile", {
		settings = {
			EnableMiscMusic = true
		}
	})

	Soundtrack.DanceEvents.OnEvent(nil, "CHAT_MSG_TEXT_EMOTE", "TestPlayer dances.", "TestPlayer")
end

function Tests:OnEvent_DanceEmoteByOtherPlayer_DoesNotPlay()
	local eventPlayed = false
	Replace("UnitName", function(unit)
		if unit == "player" then
			return "PlayerOne"
		end
		return nil
	end)
	Replace(Soundtrack, "PlayEvent", function()
		eventPlayed = true
	end)
	Replace(SoundtrackAddon.db, "profile", {
		settings = {
			EnableMiscMusic = true
		}
	})

	Soundtrack.DanceEvents.OnEvent(nil, "CHAT_MSG_TEXT_EMOTE", "PlayerTwo dances.", "PlayerTwo")

	IsFalse(eventPlayed)
end

function Tests:OnEvent_MiscMusicDisabled_DoesNotPlayEvent()
	local eventPlayed = false
	Replace(Soundtrack, "PlayEvent", function()
		eventPlayed = true
	end)
	Replace(SoundtrackAddon.db, "profile", {
		settings = {
			EnableMiscMusic = false
		}
	})

	Soundtrack.DanceEvents.OnEvent(nil, "CHAT_MSG_TEXT_EMOTE", "TestPlayer dances.", "TestPlayer")

	IsFalse(eventPlayed)
end

function Tests:OnEvent_FemalePlayerDance_PlaysFemaleMusic()
	Replace("UnitName", function(unit)
		if unit == "player" then
			return "TestPlayer"
		end
		return nil
	end)
	Replace("UnitRace", function()
		return "Night Elf"
	end)
	Replace("UnitSex", function()
		return 3 -- Female
	end)
	Replace(Soundtrack, "PlayEvent", function(eventType, eventName)
		AreEqual("Night Elf female", eventName)
	end)
	Replace(SoundtrackAddon.db, "profile", {
		settings = {
			EnableMiscMusic = true
		}
	})

	Soundtrack.DanceEvents.OnEvent(nil, "CHAT_MSG_TEXT_EMOTE", "TestPlayer dances.", "TestPlayer")
end

function Tests:Initialize_AddsAllRaceGenderCombinations()
	local eventCount = 0
	Replace(Soundtrack, "AddEvent", function()
		eventCount = eventCount + 1
	end)

	Soundtrack.DanceEvents.Initialize()

	-- Should add 24 races * 2 genders = 48 events
	IsTrue(eventCount > 40, "multiple race/gender dance events should be added")
end
