--[[
    Soundtrack addon for World of Warcraft

    Boss phase (stage) events.

    WoW itself only tells addons when an encounter starts and ends -- it never
    announces that a boss moved from stage 1 to stage 2. Boss mods do know,
    because every encounter script calls a SetStage function of its own and
    broadcasts the result. This module listens for that broadcast and turns it
    into a Soundtrack event nested under the encounter, e.g.

        Encounter: "Void Spire/Vaelgor/Stage 2"

    so users can assign a different track to each phase of a fight. Stages with
    no tracks assigned fall back to the encounter's own music (see
    Soundtrack.BattleEvents.PlayEncounterEvent), so adding this changes nothing
    for users who never configure a stage.

    Two boss mods are supported and they report the same thing:
      * DBM      -- DBM:RegisterCallback("DBM_SetStage", f), f(event, mod, modId, stage, ...)
      * BigWigs  -- BigWigsLoader.RegisterMessage(target, "BigWigs_SetStage", f),
                    f(event, module, stage)

    Both are subscribed when present, but DBM wins while it is attached, so a
    user running both does not get the same phase applied twice from two
    sources that can disagree. Precedence is resolved at dispatch rather than at
    subscribe time because BigWigs_Core is load-on-demand: the two can attach in
    either order.
]]

Soundtrack.BossPhases = {}

local attachedToDBM = false
local attachedToBigWigs = false
local currentStageKey = nil

-- Table used purely as BigWigs' callback identity; the loader keys its callback
-- map on it, so it must be stable and must not be a BigWigs module itself.
local bigWigsListener = {}

-- Formats a DBM/BigWigs stage number for display. Boss mods use whole numbers
-- for stages and halves (1.5, 2.5) for intermissions, so "2" must not become
-- "2.0" while "1.5" must stay "1.5".
function Soundtrack.BossPhases.FormatStageName(stage)
	local number = tonumber(stage)
	if not number then
		return nil
	end

	local label
	if number == math.floor(number) then
		label = tostring(math.floor(number))
	else
		label = tostring(number)
	end

	return SOUNDTRACK_BOSS_STAGE .. " " .. label
end

-- Best-effort localized boss name from a DBM mod object, used when the fight
-- did not fire ENCOUNTER_START (Classic-era raids, world bosses).
local function GetDBMModName(mod, modId)
	if type(mod) == "table" then
		if mod.combatInfo and mod.combatInfo.name then
			return mod.combatInfo.name
		end
		if mod.localization and mod.localization.general and mod.localization.general.name then
			return mod.localization.general.name
		end
	end
	return modId
end

-- Core logic, independent of which boss mod reported the change.
-- encounterName is only used when no ENCOUNTER_START key is active.
function Soundtrack.BossPhases.OnStageChanged(encounterName, stage)
	local stageName = Soundtrack.BossPhases.FormatStageName(stage)
	if not stageName then
		Soundtrack.Chat.TraceBattle("Boss phase: ignoring non-numeric stage " .. tostring(stage))
		return
	end

	-- Prefer the key ENCOUNTER_START already established, so stage nodes appear
	-- underneath the encounter the user has been assigning tracks to.
	local encounterKey = Soundtrack.BattleEvents.GetCurrentEncounterKey()
	local stageKey
	if encounterKey then
		stageKey = encounterKey .. "/" .. stageName
		Soundtrack.AddEvent(ST_ENCOUNTER, stageKey, ST_BOSS_LVL, true)
	else
		stageKey = Soundtrack.BattleEvents.RegisterEncounterKey(encounterName, stageName)
	end

	if not stageKey then
		return
	end

	currentStageKey = stageKey
	Soundtrack.Chat.TraceBattle("Boss phase changed: " .. stageKey)

	if SoundtrackAddon.db.profile.settings.EnableBattleMusic then
		Soundtrack.BattleEvents.PlayEncounterEvent(stageKey)
	end
end

-- The stage event key currently playing, or nil outside a boss phase.
function Soundtrack.BossPhases.GetCurrentStageKey()
	return currentStageKey
end

-- Called when the encounter ends (kill, wipe, or ENCOUNTER_END). Only clears
-- this module's bookkeeping; BattleEvents owns stopping the music.
function Soundtrack.BossPhases.Reset()
	currentStageKey = nil
end

-- DBM fires callbacks as (event, mod, modId, stage, encounterId, stageTotality).
function Soundtrack.BossPhases.OnDBMSetStage(_, mod, modId, stage)
	Soundtrack.BossPhases.OnStageChanged(GetDBMModName(mod, modId), stage)
end

function Soundtrack.BossPhases.IsAttachedToDBM()
	return attachedToDBM
end

-- Subscribes to DBM's stage callbacks. Safe to call repeatedly; returns true
-- once Soundtrack is listening.
function Soundtrack.BossPhases.AttachToDBM()
	if attachedToDBM then
		return true
	end

	local dbm = _G.DBM
	if not dbm or type(dbm.RegisterCallback) ~= "function" then
		return false
	end

	dbm:RegisterCallback("DBM_SetStage", Soundtrack.BossPhases.OnDBMSetStage)
	-- Non-instanced fights (Classic raids, world bosses) never fire ENCOUNTER_END.
	dbm:RegisterCallback("DBM_Kill", Soundtrack.BossPhases.Reset)
	dbm:RegisterCallback("DBM_Wipe", Soundtrack.BossPhases.Reset)

	attachedToDBM = true
	Soundtrack.Chat.TraceBattle("Boss phase support attached to DBM")
	return true
end

-- Best-effort localized boss name from a BigWigs module. displayName comes from
-- EJ_GetEncounterInfo, i.e. the same source as ENCOUNTER_START's name.
local function GetBigWigsModuleName(module)
	if type(module) == "table" then
		return module.displayName or module.moduleName
	end
	return nil
end

-- BigWigs sends messages as (event, module, stage).
function Soundtrack.BossPhases.OnBigWigsSetStage(_, module, stage)
	-- DBM outranks BigWigs: with both installed the two would report the same
	-- phase and fight over the stack, so only one drives the music.
	if attachedToDBM then
		return
	end
	Soundtrack.BossPhases.OnStageChanged(GetBigWigsModuleName(module), stage)
end

function Soundtrack.BossPhases.IsAttachedToBigWigs()
	return attachedToBigWigs
end

-- Which boss mod is currently driving phase changes, or nil if none is attached.
function Soundtrack.BossPhases.GetStageSource()
	if attachedToDBM then
		return "DBM"
	end
	if attachedToBigWigs then
		return "BigWigs"
	end
	return nil
end

-- Subscribes to BigWigs' stage messages. Safe to call repeatedly; returns true
-- once Soundtrack is listening.
function Soundtrack.BossPhases.AttachToBigWigs()
	if attachedToBigWigs then
		return true
	end

	local loader = _G.BigWigsLoader
	if not loader or type(loader.RegisterMessage) ~= "function" then
		return false
	end

	-- Called with '.' and our own table: passing BigWigsLoader itself is an error,
	-- and the loader keys callbacks on the table it is handed.
	loader.RegisterMessage(bigWigsListener, "BigWigs_SetStage", Soundtrack.BossPhases.OnBigWigsSetStage)
	-- Non-instanced fights never fire ENCOUNTER_END.
	loader.RegisterMessage(bigWigsListener, "BigWigs_OnBossWin", Soundtrack.BossPhases.Reset)
	loader.RegisterMessage(bigWigsListener, "BigWigs_OnBossWipe", Soundtrack.BossPhases.Reset)

	attachedToBigWigs = true
	Soundtrack.Chat.TraceBattle("Boss phase support attached to BigWigs")
	return true
end

-- Attaches to every supported boss mod that is loaded. Returns true only once
-- both are attached, since either can still show up later (BigWigs_Core is
-- load-on-demand, and DBM takes over as the source whenever it appears).
function Soundtrack.BossPhases.AttachToBossMods()
	local dbm = Soundtrack.BossPhases.AttachToDBM()
	local bigWigs = Soundtrack.BossPhases.AttachToBigWigs()
	return dbm and bigWigs
end

function Soundtrack.BossPhases.OnLoad(self)
	-- Boss mod cores can load after Soundtrack, so retry on every addon load.
	self:RegisterEvent("ADDON_LOADED")
end

function Soundtrack.BossPhases.OnEvent(self, event)
	if event == "ADDON_LOADED" then
		if Soundtrack.BossPhases.AttachToBossMods() and self then
			self:UnregisterEvent("ADDON_LOADED")
		end
	end
end

function Soundtrack.BossPhases.Initialize()
	Soundtrack.BossPhases.Reset()
	Soundtrack.BossPhases.AttachToBossMods()
end
