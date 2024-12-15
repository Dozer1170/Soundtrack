--[[
    Soundtrack addon for World of Warcraft

    Misc events functions.
    Functions that manage misc. and custom events.
]]

local function debug(msg)
	Soundtrack.TraceCustom(msg)
end

Soundtrack.MiscEvents = {}

function Soundtrack.MiscEvents.RegisterUpdateScript(_, name, _priority, _continuous, _script, _soundEffect)
	if not name then
		return
	end

	Soundtrack_MiscEvents[name] = {
		script = _script,
		eventtype = ST_UPDATE_SCRIPT,
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	Soundtrack.AddEvent(ST_MISC, name, _priority, _continuous, _soundEffect)
end

function Soundtrack.MiscEvents.RegisterEventScript(self, name, _trigger, _priority, _continuous, _script, _soundEffect)
	if not name then
		return
	end

	Soundtrack_MiscEvents[name] = {
		trigger = _trigger,
		script = _script,
		eventtype = ST_EVENT_SCRIPT,
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	self:RegisterEvent(_trigger)
	Soundtrack.AddEvent(ST_MISC, name, _priority, _continuous, _soundEffect)
end

function Soundtrack.MiscEvents.RegisterBuffEvent(eventName, _spellId, _priority, _continuous, _soundEffect)
	if not eventName then
		return
	end

	Soundtrack_MiscEvents[eventName] = {
		spellId = _spellId,
		stackLevel = _priority,
		active = false,
		eventtype = ST_BUFF_SCRIPT,
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	Soundtrack.AddEvent(ST_MISC, eventName, _priority, _continuous, _soundEffect)
end

function Soundtrack.MiscEvents.PlayEvent(eventName)
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	if not eventTable then
		return
	end

	local currentEvent = Soundtrack.Events.Stack[eventTable[eventName].priority].eventName
	if eventName ~= currentEvent then
		Soundtrack.PlayEvent(ST_MISC, eventName)
	end
end

function Soundtrack.MiscEvents.StopEvent(eventName)
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	if not eventTable then
		return
	end

	local currentEvent = Soundtrack.Events.Stack[eventTable[eventName].priority].eventName
	if eventName == currentEvent then
		Soundtrack.StopEvent(ST_MISC, eventName)
	end
end

function Soundtrack.MiscEvents.MiscInitialize()
	debug("Initializing misc. events...")

	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_COMBAT_EVENTS, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_GROUP_EVENTS, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_NPC_EVENTS, 0, 1, false, false)
	Soundtrack.MiscEvents.RegisterBuffEvent(SOUNDTRACK_STATUS_EVENTS, 0, 1, false, false)

	Soundtrack.LootEvents.Register()
	Soundtrack.ClassEvents.Register()
	Soundtrack.NpcEvents.Register()
	Soundtrack.PlayerStatusEvents.Register()
	Soundtrack.StealthEvents.Register()

	Soundtrack_SortEvents(ST_MISC)
end

function Soundtrack.MiscEvents.MiscOnUpdate(_, _)
	if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
		for k, v in pairs(Soundtrack_MiscEvents) do
			if v.eventtype == ST_UPDATE_SCRIPT and SoundtrackEvents_EventHasTracks(ST_MISC, k) then
				v.script()
			end
		end

		Soundtrack.LootEvents.OnUpdate()
	end
end

-- MiscEvents
function Soundtrack.MiscEvents.MiscOnEvent(_, event, ...)
	local st_arg1, _, _, _, st_arg5, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ = ...

	Soundtrack.PlayerStatusEvents.OnEvent(event)
	Soundtrack.LootEvents.OnEvent(event, st_arg1, st_arg5)
end

-- TODO: Make sure shapeshift events works this way
function Soundtrack.MiscEvents.OnPlayerAurasUpdated()
	if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
		for k, v in pairs(Soundtrack_MiscEvents) do
			if v.spellId ~= 0 and SoundtrackEvents_EventHasTracks(ST_MISC, k) then
				local isActive = Soundtrack.Auras.IsAuraActive(v.spellId)
				if not v.active and isActive then
					v.active = true
					Soundtrack.MiscEvents.PlayEvent(k)
				elseif v.active and not isActive then
					v.active = false
					Soundtrack.MiscEvents.StopEvent(k)
				end
			end
		end
	end
end