Soundtrack.NpcEvents = {}

function Soundtrack.NpcEvents.Register()
	Soundtrack.MiscEvents.RegisterEventScript( -- NPC Emote
		SoundtrackMiscDUMMY,
		SOUNDTRACK_NPC_EMOTE,
		"CHAT_MSG_MONSTER_EMOTE",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack.MiscEvents.PlayEvent(SOUNDTRACK_NPC_EMOTE)
		end,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- NPC Say
		SoundtrackMiscDUMMY,
		SOUNDTRACK_NPC_SAY,
		"CHAT_MSG_MONSTER_SAY",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack.MiscEvents.PlayEvent(SOUNDTRACK_NPC_SAY)
		end,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- NPC Whisper
		SoundtrackMiscDUMMY,
		SOUNDTRACK_NPC_WHISPER,
		"CHAT_MSG_MONSTER_WHISPER",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack.MiscEvents.PlayEvent(SOUNDTRACK_NPC_WHISPER)
		end,
		true
	)

	Soundtrack.MiscEvents.RegisterEventScript( -- NPC Yell
		SoundtrackMiscDUMMY,
		SOUNDTRACK_NPC_YELL,
		"CHAT_MSG_MONSTER_YELL",
		ST_SFX_LVL,
		false,
		function()
			Soundtrack.MiscEvents.PlayEvent(SOUNDTRACK_NPC_YELL)
		end,
		true
	)
end
