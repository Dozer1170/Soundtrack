if not Tests then
	return
end

local Tests = Tests("Soundtrack", "BossPhases")

local function InInstance(instanceName)
	Replace(Soundtrack.ZoneEvents, "GetCurrentZonePaths", function()
		return { "Instances/" .. instanceName, "Instances" }
	end)
end

-- Puts BattleEvents into an active encounter so BossPhases nests under it.
local function StartEncounter(instanceName, encounterName)
	InInstance(instanceName)
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	Soundtrack.BattleEvents.OnEvent(nil, "ENCOUNTER_START", nil, encounterName)
end

-- Boss mod mocks. `registered` collects event -> handler so tests can fire them.
local function MockDBM(registered)
	registered = registered or {}
	return {
		registered = registered,
		RegisterCallback = function(_, event, handler)
			registered[event] = handler
		end,
	}
end

local function MockBigWigs(registered)
	registered = registered or {}
	return {
		registered = registered,
		-- BigWigs' loader is called with '.', so the listener table is arg #1
		RegisterMessage = function(listener, event, handler)
			registered[event] = handler
			registered.listener = listener
		end,
	}
end

local function ClearBossMods()
	_G.DBM = nil
	_G.BigWigsLoader = nil
end

local function CapturePlayEvent()
	local played = {}
	Replace(Soundtrack, "PlayEvent", function(tableName, eventName)
		played.tableName = tableName
		played.eventName = eventName
	end)
	return played
end

-- FormatStageName ------------------------------------------------------

function Tests:FormatStageName_WholeNumber_HasNoDecimals()
	AreEqual("Stage 2", Soundtrack.BossPhases.FormatStageName(2), "Whole stages should not render a decimal")
end

function Tests:FormatStageName_Intermission_KeepsHalf()
	AreEqual("Stage 1.5", Soundtrack.BossPhases.FormatStageName(1.5), "Intermissions should keep the .5 suffix")
end

function Tests:FormatStageName_NumericString_IsAccepted()
	-- DBM sends the stage as a string when recovering state from another player
	AreEqual("Stage 3", Soundtrack.BossPhases.FormatStageName("3"), "Numeric strings should be parsed")
end

function Tests:FormatStageName_NonNumeric_ReturnsNil()
	AreEqual(nil, Soundtrack.BossPhases.FormatStageName("bogus"), "Non-numeric stages should be rejected")
end

-- OnStageChanged -------------------------------------------------------

function Tests:OnStageChanged_RegistersStageUnderActiveEncounter()
	StartEncounter("Void Spire", "Vaelgor")
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)

	IsTrue(
		Soundtrack.Events.EventExists(ST_ENCOUNTER, "Void Spire/Vaelgor/Stage 2"),
		"Stage event should be registered under the encounter key"
	)
	AreEqual(
		"Void Spire/Vaelgor/Stage 2",
		Soundtrack.BossPhases.GetCurrentStageKey(),
		"Current stage key should be tracked"
	)
end

function Tests:OnStageChanged_PlaysStageTracksWhenAssigned()
	StartEncounter("Void Spire", "Vaelgor")
	local stageKey = "Void Spire/Vaelgor/Stage 2"
	Soundtrack.AddEvent(ST_ENCOUNTER, stageKey, ST_BOSS_LVL, true)
	Soundtrack.Events.Add(ST_ENCOUNTER, stageKey, "Sound/Music/stage2.mp3")

	local played = CapturePlayEvent()
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)

	AreEqual(ST_ENCOUNTER, played.tableName, "Stage music should come from the Encounter table")
	AreEqual(stageKey, played.eventName, "Assigned stage tracks should play")
end

function Tests:OnStageChanged_FallsBackToEncounterTracks()
	StartEncounter("Void Spire", "Vaelgor")
	-- Encounter has tracks, the stage does not
	Soundtrack.Events.Add(ST_ENCOUNTER, "Void Spire/Vaelgor", "Sound/Music/vaelgor.mp3")

	local played = CapturePlayEvent()
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)

	AreEqual(ST_ENCOUNTER, played.tableName, "Fallback should stay in the Encounter table")
	AreEqual("Void Spire/Vaelgor", played.eventName, "Encounter tracks should play when the stage has none")
end

function Tests:OnStageChanged_FallsBackToInstanceTracks()
	StartEncounter("Void Spire", "Vaelgor")
	Soundtrack.Events.Add(ST_ENCOUNTER, "Void Spire", "Sound/Music/voidspire.mp3")

	local played = CapturePlayEvent()
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)

	AreEqual("Void Spire", played.eventName, "Instance-level tracks should play when nothing more specific has any")
end

function Tests:OnStageChanged_FallsBackToBossBattleWhenNothingAssigned()
	StartEncounter("Void Spire", "Vaelgor")

	local played = CapturePlayEvent()
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)

	AreEqual(ST_BATTLE, played.tableName, "Generic boss battle should be the last resort")
	AreEqual(SOUNDTRACK_BOSS_BATTLE, played.eventName, "Generic boss battle event should play")
end

function Tests:OnStageChanged_WithoutEncounterStart_UsesBossName()
	-- Classic-era raids and world bosses never fire ENCOUNTER_START
	InInstance("Molten Core")
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	Soundtrack.BossPhases.OnStageChanged("Ragnaros", 2)

	IsTrue(
		Soundtrack.Events.EventExists(ST_ENCOUNTER, "Molten Core/Ragnaros/Stage 2"),
		"Stage key should be built from the boss mod's name"
	)
	IsTrue(
		Soundtrack.Events.EventExists(ST_ENCOUNTER, "Molten Core/Ragnaros"),
		"Parent encounter node should be created so the tree renders"
	)
end

function Tests:OnStageChanged_NonNumericStage_IsIgnored()
	StartEncounter("Void Spire", "Vaelgor")
	Soundtrack.BossPhases.Reset()

	Soundtrack.BossPhases.OnStageChanged("Vaelgor", "bogus")

	AreEqual(nil, Soundtrack.BossPhases.GetCurrentStageKey(), "A non-numeric stage should not be tracked")
end

function Tests:OnStageChanged_UnnamedBossOutsideEncounter_IsIgnored()
	-- No ENCOUNTER_START key and no usable boss name: nothing to key the event on
	InInstance("Molten Core")
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	local played = CapturePlayEvent()
	Soundtrack.BossPhases.OnStageChanged(nil, 2)

	AreEqual(nil, Soundtrack.BossPhases.GetCurrentStageKey(), "An unnamed boss should not produce a stage key")
	AreEqual(nil, played.eventName, "Nothing should play for an unnamed boss")
end

function Tests:OnStageChanged_BattleMusicDisabled_RegistersButDoesNotPlay()
	StartEncounter("Void Spire", "Vaelgor")
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = false

	local played = CapturePlayEvent()
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)

	AreEqual(nil, played.eventName, "No music should play while battle music is disabled")
	IsTrue(
		Soundtrack.Events.EventExists(ST_ENCOUNTER, "Void Spire/Vaelgor/Stage 2"),
		"Stage event should still be registered so it can be configured"
	)
end

-- Precedence over encounter-level music --------------------------------

function Tests:ActiveStage_TakesPrecedenceOverEncounterMusic()
	StartEncounter("Void Spire", "Vaelgor")
	local stageKey = "Void Spire/Vaelgor/Stage 2"
	Soundtrack.AddEvent(ST_ENCOUNTER, stageKey, ST_BOSS_LVL, true)
	Soundtrack.Events.Add(ST_ENCOUNTER, stageKey, "Sound/Music/stage2.mp3")
	Soundtrack.Events.Add(ST_ENCOUNTER, "Void Spire/Vaelgor", "Sound/Music/vaelgor.mp3")
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)

	-- Something re-requests the encounter's own music while the stage is active
	local played = CapturePlayEvent()
	Soundtrack.BattleEvents.PlayEncounterEvent("Void Spire/Vaelgor")

	AreEqual(stageKey, played.eventName, "The active stage should win over encounter-level music")
end

function Tests:StageBeforeEncounterStart_SurvivesEncounterStart()
	-- Boss mods can report stage 1 before Blizzard fires ENCOUNTER_START
	InInstance("Void Spire")
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	local stageKey = "Void Spire/Vaelgor/Stage 1"
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 1)
	Soundtrack.Events.Add(ST_ENCOUNTER, stageKey, "Sound/Music/stage1.mp3")
	Soundtrack.Events.Add(ST_ENCOUNTER, "Void Spire/Vaelgor", "Sound/Music/vaelgor.mp3")

	local played = CapturePlayEvent()
	Soundtrack.BattleEvents.OnEvent(nil, "ENCOUNTER_START", nil, "Vaelgor")

	AreEqual(stageKey, played.eventName, "ENCOUNTER_START should not clobber an already-active stage")
end

function Tests:ActiveStage_DoesNotHijackAnUnrelatedEncounter()
	StartEncounter("Void Spire", "Vaelgor")
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)
	Soundtrack.Events.Add(ST_ENCOUNTER, "Void Spire/Ezzorak", "Sound/Music/ezzorak.mp3")

	local played = CapturePlayEvent()
	Soundtrack.BattleEvents.PlayEncounterEvent("Void Spire/Ezzorak")

	AreEqual("Void Spire/Ezzorak", played.eventName, "A stage should only outrank its own encounter")
end

-- UI tree --------------------------------------------------------------

function Tests:StageEvent_NestsUnderItsEncounterInTheEventTree()
	StartEncounter("Void Spire", "Vaelgor")
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)

	local function FindNode(parent, name)
		for _, node in ipairs(parent.nodes) do
			if node.name == name then
				return node
			end
		end
		return nil
	end

	local instanceNode = FindNode(Soundtrack_EventNodes[ST_ENCOUNTER], "Void Spire")
	Exists(instanceNode, "Instance node should exist in the Encounters tree")
	local encounterNode = instanceNode and FindNode(instanceNode, "Vaelgor")
	Exists(encounterNode, "Encounter node should be nested under the instance")
	local stageNode = encounterNode and FindNode(encounterNode, "Stage 2")
	Exists(stageNode, "Stage node should be nested under the encounter")
	AreEqual("Void Spire/Vaelgor/Stage 2", stageNode and stageNode.tag, "Stage node should tag the full event key")
end

-- Reset ----------------------------------------------------------------

function Tests:Reset_ClearsCurrentStage()
	StartEncounter("Void Spire", "Vaelgor")
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)
	Soundtrack.BossPhases.Reset()

	AreEqual(nil, Soundtrack.BossPhases.GetCurrentStageKey(), "Reset should clear the tracked stage")
end

function Tests:EncounterEnd_ClearsCurrentStage()
	StartEncounter("Void Spire", "Vaelgor")
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)

	Soundtrack.BattleEvents.OnEvent(nil, "ENCOUNTER_END", nil, "Vaelgor")

	AreEqual(nil, Soundtrack.BossPhases.GetCurrentStageKey(), "ENCOUNTER_END should clear the tracked stage")
end

-- DBM attachment -------------------------------------------------------

function Tests:AttachToDBM_WithoutDBM_ReturnsFalse()
	ClearBossMods()
	IsFalse(Soundtrack.BossPhases.AttachToDBM(), "Attaching should fail when DBM is not installed")
	IsFalse(Soundtrack.BossPhases.IsAttachedToDBM(), "Should not report being attached")
	AreEqual(nil, Soundtrack.BossPhases.GetStageSource(), "No boss mod means no stage source")
end

function Tests:AttachToDBM_RegistersStageAndCombatEndCallbacks()
	local registered = {}
	_G.DBM = MockDBM(registered)

	IsTrue(Soundtrack.BossPhases.AttachToDBM(), "Attaching should succeed when DBM is present")
	IsTrue(Soundtrack.BossPhases.IsAttachedToDBM(), "Should report being attached")
	Exists(registered["DBM_SetStage"], "DBM_SetStage should be subscribed")
	Exists(registered["DBM_Kill"], "DBM_Kill should be subscribed to clear state")
	Exists(registered["DBM_Wipe"], "DBM_Wipe should be subscribed to clear state")
	AreEqual("DBM", Soundtrack.BossPhases.GetStageSource(), "DBM should be reported as the source")

	ClearBossMods()
end

function Tests:AttachToDBM_CalledTwice_SubscribesOnce()
	local callCount = 0
	_G.DBM = {
		RegisterCallback = function()
			callCount = callCount + 1
		end,
	}

	Soundtrack.BossPhases.AttachToDBM()
	Soundtrack.BossPhases.AttachToDBM()

	AreEqual(3, callCount, "Repeated attach calls should not re-subscribe")

	ClearBossMods()
end

-- BigWigs attachment ---------------------------------------------------

function Tests:AttachToBigWigs_WithoutBigWigs_ReturnsFalse()
	ClearBossMods()
	IsFalse(Soundtrack.BossPhases.AttachToBigWigs(), "Attaching should fail when BigWigs is not installed")
	IsFalse(Soundtrack.BossPhases.IsAttachedToBigWigs(), "Should not report being attached")
end

function Tests:AttachToBigWigs_RegistersStageAndCombatEndMessages()
	local registered = {}
	_G.BigWigsLoader = MockBigWigs(registered)

	IsTrue(Soundtrack.BossPhases.AttachToBigWigs(), "Attaching should succeed when BigWigs is present")
	IsTrue(Soundtrack.BossPhases.IsAttachedToBigWigs(), "Should report being attached")
	Exists(registered["BigWigs_SetStage"], "BigWigs_SetStage should be subscribed")
	Exists(registered["BigWigs_OnBossWin"], "BigWigs_OnBossWin should be subscribed to clear state")
	Exists(registered["BigWigs_OnBossWipe"], "BigWigs_OnBossWipe should be subscribed to clear state")
	AreEqual("BigWigs", Soundtrack.BossPhases.GetStageSource(), "BigWigs should be reported as the source")

	ClearBossMods()
end

function Tests:AttachToBigWigs_UsesOwnListenerTableNotTheLoader()
	-- BigWigsLoader.RegisterMessage errors if handed the loader itself
	local registered = {}
	local loader = MockBigWigs(registered)
	_G.BigWigsLoader = loader

	Soundtrack.BossPhases.AttachToBigWigs()

	Exists(registered.listener, "A listener table should be passed to the loader")
	IsTrue(registered.listener ~= loader, "The listener must not be BigWigsLoader itself")

	ClearBossMods()
end

function Tests:AttachToBigWigs_CalledTwice_SubscribesOnce()
	local callCount = 0
	_G.BigWigsLoader = {
		RegisterMessage = function()
			callCount = callCount + 1
		end,
	}

	Soundtrack.BossPhases.AttachToBigWigs()
	Soundtrack.BossPhases.AttachToBigWigs()

	AreEqual(3, callCount, "Repeated attach calls should not re-subscribe")

	ClearBossMods()
end

function Tests:OnBigWigsSetStage_UsesModuleDisplayName()
	ClearBossMods()
	InInstance("Molten Core")
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true
	Soundtrack.BossPhases.AttachToBigWigs()

	Soundtrack.BossPhases.OnBigWigsSetStage("BigWigs_SetStage", { displayName = "Ragnaros" }, 2)

	AreEqual(
		"Molten Core/Ragnaros/Stage 2",
		Soundtrack.BossPhases.GetCurrentStageKey(),
		"The module's localized displayName should be used for the encounter key"
	)
end

function Tests:OnBigWigsSetStage_FallsBackToModuleName()
	ClearBossMods()
	InInstance("Molten Core")
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	Soundtrack.BossPhases.OnBigWigsSetStage("BigWigs_SetStage", { moduleName = "Garr" }, 3)

	AreEqual(
		"Molten Core/Garr/Stage 3",
		Soundtrack.BossPhases.GetCurrentStageKey(),
		"moduleName should be used when the module has no displayName"
	)
end

function Tests:OnBigWigsSetStage_HandlesIntermissions()
	ClearBossMods()
	StartEncounter("The Venomous Abyss", "Nekzali")

	Soundtrack.BossPhases.OnBigWigsSetStage("BigWigs_SetStage", { displayName = "Nekzali" }, 1.5)

	AreEqual(
		"The Venomous Abyss/Nekzali/Stage 1.5",
		Soundtrack.BossPhases.GetCurrentStageKey(),
		"BigWigs intermissions should nest like any other stage"
	)
end

-- DBM precedence -------------------------------------------------------

function Tests:BothInstalled_DBMWinsAndBigWigsIsIgnored()
	_G.DBM = MockDBM()
	_G.BigWigsLoader = MockBigWigs()
	Soundtrack.BossPhases.AttachToBossMods()
	StartEncounter("Void Spire", "Vaelgor")

	Soundtrack.BossPhases.OnDBMSetStage("DBM_SetStage", { combatInfo = { name = "Vaelgor" } }, "Vaelgor", 2, 3178, 2)
	-- BigWigs reports a different stage for the same fight; DBM's must stand
	Soundtrack.BossPhases.OnBigWigsSetStage("BigWigs_SetStage", { displayName = "Vaelgor" }, 3)

	AreEqual("DBM", Soundtrack.BossPhases.GetStageSource(), "DBM should be the reported source")
	AreEqual(
		"Void Spire/Vaelgor/Stage 2",
		Soundtrack.BossPhases.GetCurrentStageKey(),
		"BigWigs should not overwrite the stage DBM reported"
	)

	ClearBossMods()
end

function Tests:BigWigsDrivesWhenDBMIsAbsent()
	ClearBossMods()
	_G.BigWigsLoader = MockBigWigs()
	Soundtrack.BossPhases.AttachToBossMods()
	StartEncounter("Void Spire", "Vaelgor")

	Soundtrack.BossPhases.OnBigWigsSetStage("BigWigs_SetStage", { displayName = "Vaelgor" }, 3)

	AreEqual("BigWigs", Soundtrack.BossPhases.GetStageSource(), "BigWigs should be the reported source")
	AreEqual(
		"Void Spire/Vaelgor/Stage 3",
		Soundtrack.BossPhases.GetCurrentStageKey(),
		"BigWigs should drive phases when DBM is not installed"
	)

	ClearBossMods()
end

function Tests:DBMAttachingLater_TakesOverFromBigWigs()
	-- BigWigs_Core is load-on-demand, so it can attach before DBM does
	ClearBossMods()
	_G.BigWigsLoader = MockBigWigs()
	Soundtrack.BossPhases.AttachToBigWigs()
	StartEncounter("Void Spire", "Vaelgor")
	Soundtrack.BossPhases.OnBigWigsSetStage("BigWigs_SetStage", { displayName = "Vaelgor" }, 2)

	_G.DBM = MockDBM()
	Soundtrack.BossPhases.AttachToDBM()
	Soundtrack.BossPhases.OnBigWigsSetStage("BigWigs_SetStage", { displayName = "Vaelgor" }, 3)

	AreEqual("DBM", Soundtrack.BossPhases.GetStageSource(), "DBM should take over once it attaches")
	AreEqual(
		"Void Spire/Vaelgor/Stage 2",
		Soundtrack.BossPhases.GetCurrentStageKey(),
		"BigWigs updates should stop once DBM is attached"
	)

	ClearBossMods()
end

function Tests:OnLoad_ListensForLateLoadingBossMods()
	local registered = {}
	local frame = {
		RegisterEvent = function(_, event)
			registered[event] = true
		end,
	}

	Soundtrack.BossPhases.OnLoad(frame)

	IsTrue(registered["ADDON_LOADED"], "ADDON_LOADED should be registered so a late DBM is still picked up")
end

function Tests:OnEvent_AddonLoaded_AttachesAndStopsListeningOnceBothAreFound()
	_G.DBM = MockDBM()
	_G.BigWigsLoader = MockBigWigs()
	local unregistered = {}
	local frame = {
		UnregisterEvent = function(_, event)
			unregistered[event] = true
		end,
	}

	Soundtrack.BossPhases.OnEvent(frame, "ADDON_LOADED")

	IsTrue(Soundtrack.BossPhases.IsAttachedToDBM(), "ADDON_LOADED should attach to DBM once it exists")
	IsTrue(Soundtrack.BossPhases.IsAttachedToBigWigs(), "ADDON_LOADED should attach to BigWigs once it exists")
	IsTrue(unregistered["ADDON_LOADED"], "Listening should stop once both boss mods are attached")

	ClearBossMods()
end

function Tests:OnEvent_AddonLoaded_KeepsListeningWhileBigWigsIsStillLoading()
	-- BigWigs_Core is load-on-demand, so DBM alone is not the end of the story
	_G.DBM = MockDBM()
	_G.BigWigsLoader = nil
	local unregistered = false
	local frame = {
		UnregisterEvent = function()
			unregistered = true
		end,
	}

	Soundtrack.BossPhases.OnEvent(frame, "ADDON_LOADED")

	IsTrue(Soundtrack.BossPhases.IsAttachedToDBM(), "DBM should still attach")
	IsFalse(unregistered, "Should keep listening while a load-on-demand boss mod could still appear")

	ClearBossMods()
end

function Tests:OnEvent_AddonLoaded_KeepsListeningWhileNoBossModIsPresent()
	ClearBossMods()
	local unregistered = false
	local frame = {
		UnregisterEvent = function()
			unregistered = true
		end,
	}

	Soundtrack.BossPhases.OnEvent(frame, "ADDON_LOADED")

	IsFalse(unregistered, "Should keep listening until a supported boss mod shows up")
end

function Tests:Initialize_ClearsStateAndAttaches()
	_G.DBM = MockDBM()
	_G.BigWigsLoader = MockBigWigs()
	StartEncounter("Void Spire", "Vaelgor")
	Soundtrack.BossPhases.OnStageChanged("Vaelgor", 2)

	Soundtrack.BossPhases.Initialize()

	AreEqual(nil, Soundtrack.BossPhases.GetCurrentStageKey(), "Initialize should start from a clean stage")
	IsTrue(Soundtrack.BossPhases.IsAttachedToDBM(), "Initialize should attach to DBM when it is installed")
	IsTrue(Soundtrack.BossPhases.IsAttachedToBigWigs(), "Initialize should attach to BigWigs when it is installed")

	ClearBossMods()
end

function Tests:OnDBMSetStage_UsesModCombatInfoName()
	InInstance("Molten Core")
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	local mod = { combatInfo = { name = "Ragnaros" } }
	Soundtrack.BossPhases.OnDBMSetStage("DBM_SetStage", mod, "Ragnaros1", 2, 663, 2)

	AreEqual(
		"Molten Core/Ragnaros/Stage 2",
		Soundtrack.BossPhases.GetCurrentStageKey(),
		"The mod's localized name should be used for the encounter key"
	)
end

function Tests:OnDBMSetStage_FallsBackToLocalizationName()
	InInstance("Molten Core")
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	local mod = { localization = { general = { name = "Majordomo Executus" } } }
	Soundtrack.BossPhases.OnDBMSetStage("DBM_SetStage", mod, "Majordomo", 2, 664, 2)

	AreEqual(
		"Molten Core/Majordomo Executus/Stage 2",
		Soundtrack.BossPhases.GetCurrentStageKey(),
		"localization.general.name should be used when combatInfo is absent"
	)
end

function Tests:OnDBMSetStage_FallsBackToModId()
	InInstance("Molten Core")
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	Soundtrack.BossPhases.OnDBMSetStage("DBM_SetStage", {}, "Garr", 3, 665, 3)

	AreEqual(
		"Molten Core/Garr/Stage 3",
		Soundtrack.BossPhases.GetCurrentStageKey(),
		"The mod id should be used when the mod exposes no name"
	)
end

function Tests:OnDBMSetStage_PrefersActiveEncounterKeyOverModName()
	-- DBM's mod name and Blizzard's encounter name can differ; the ENCOUNTER_START
	-- key wins so stages nest under the node the user already configured.
	StartEncounter("Void Spire", "Vaelgor and Ezzorak")

	Soundtrack.BossPhases.OnDBMSetStage("DBM_SetStage", { combatInfo = { name = "Vaelgor" } }, "Vaelgor", 2, 3178, 2)

	AreEqual(
		"Void Spire/Vaelgor and Ezzorak/Stage 2",
		Soundtrack.BossPhases.GetCurrentStageKey(),
		"The active ENCOUNTER_START key should take precedence"
	)
end

function Tests:OnBigWigsSetStage_WithoutAModule_IsIgnored()
	ClearBossMods()
	InInstance("Molten Core")
	SoundtrackAddon.db.profile.settings.EnableBattleMusic = true

	Soundtrack.BossPhases.OnBigWigsSetStage("BigWigs_SetStage", nil, 2)

	AreEqual(nil, Soundtrack.BossPhases.GetCurrentStageKey(), "A stage with no module should be ignored")
end
