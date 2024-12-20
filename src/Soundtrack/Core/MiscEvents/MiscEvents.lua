--[[
    Soundtrack addon for World of Warcraft

    Misc events functions.
    Functions that manage misc. and custom events.
]]

local function debug(msg)
	Soundtrack.Chat.TraceCustom(msg)
end

Soundtrack.Misc = {}

function Soundtrack.Misc.RegisterUpdateScript(_, name, _priority, _continuous, _script, _soundEffect)
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

function Soundtrack.Misc.RegisterEventScript(self, name, _trigger, _priority, _continuous, _script, _soundEffect)
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

function Soundtrack.Misc.RegisterBuffEvent(eventName, _spellId, _priority, _continuous, _soundEffect)
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

function Soundtrack.Misc.PlayEvent(eventName)
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	if not eventTable then
		return
	end

	local currentEvent = Soundtrack.Events.Stack[eventTable[eventName].priority].eventName
	if eventName ~= currentEvent then
		Soundtrack.PlayEvent(ST_MISC, eventName)
	end
end

function Soundtrack.Misc.StopEvent(eventName)
	local eventTable = Soundtrack.Events.GetTable(ST_MISC)
	if not eventTable then
		return
	end

	local currentEvent = Soundtrack.Events.Stack[eventTable[eventName].priority].eventName
	if eventName == currentEvent then
		Soundtrack.StopEvent(ST_MISC, eventName)
	end
end

function Soundtrack.Misc.Initialize()
	debug("Initializing misc. events...")

	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_COMBAT_EVENTS, 0, 1, false, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_GROUP_EVENTS, 0, 1, false, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_NPC_EVENTS, 0, 1, false, false)
	Soundtrack.Misc.RegisterBuffEvent(SOUNDTRACK_STATUS_EVENTS, 0, 1, false, false)

	Soundtrack.LootEvents.Register()
	Soundtrack.ClassEvents.Register()
	Soundtrack.NpcEvents.Register()
	Soundtrack.PlayerStatusEvents.Register()
	Soundtrack.StealthEvents.Register()

	Soundtrack.SortEvents(ST_MISC)
end

function Soundtrack.Misc.OnUpdate(_, _)
	if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
		for k, v in pairs(Soundtrack_MiscEvents) do
			if v.eventtype == ST_UPDATE_SCRIPT and Soundtrack.Events.EventHasTracks(ST_MISC, k) then
				v.script()
			end
		end

		Soundtrack.LootEvents.OnUpdate()
		Soundtrack.MountEvents.OnUpdate()
	end
end

-- MiscEvents
function Soundtrack.Misc.OnEvent(_, event, ...)
	local st_arg1, _, _, _, st_arg5, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ = ...

	Soundtrack.PlayerStatusEvents.OnEvent(event)
	Soundtrack.LootEvents.OnEvent(event, st_arg1, st_arg5)
end

-- TODO: Make sure shapeshift events works this way
function Soundtrack.Misc.OnPlayerAurasUpdated()
	if SoundtrackAddon.db.profile.settings.EnableMiscMusic then
		for k, v in pairs(Soundtrack_MiscEvents) do
			if v.spellId ~= 0 and Soundtrack.Events.EventHasTracks(ST_MISC, k) then
				local isActive = Soundtrack.Auras.IsAuraActive(v.spellId)
				if not v.active and isActive then
					v.active = true
					Soundtrack.Misc.PlayEvent(k)
				elseif v.active and not isActive then
					v.active = false
					Soundtrack.Misc.StopEvent(k)
				end
			end
		end
	end
end
