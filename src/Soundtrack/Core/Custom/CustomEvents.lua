--[[
    Soundtrack addon for World of Warcraft

    Custom events functions.
    Functions that manage misc. and custom events.
]]

Soundtrack.CustomEvents = {}

local function debug(msg)
	Soundtrack.TraceCustom(msg)
end

function Soundtrack.CustomEvents.RenameEvent(tableName, oldEventName, newEventName)
	if Soundtrack.IsNullOrEmpty(tableName) then
		Soundtrack.Error("Custom RenameEvent: Nil table")
		return
	end
	if Soundtrack.IsNullOrEmpty(oldEventName) then
		Soundtrack.Error("Custom RenmeEvent: Nil old event")
		return
	end
	if Soundtrack.IsNullOrEmpty(newEventName) then
		Soundtrack.Error("Custom RenameEvent: Nil new event " .. oldEventName)
		return
	end

	local eventTable = Soundtrack.Events.GetTable(tableName)

	if not eventTable then
		Soundtrack.Error("Custom RenameEvent: Cannot find table : " .. tableName)
		return
	end

	if eventTable[oldEventName] == nil then
		return -- old event DNE
	end

	debug("RenameEvent: " .. tableName .. ": " .. oldEventName .. " to " .. newEventName)
	eventTable[newEventName] = eventTable[oldEventName]

	-- Now that we changed the name of the event, delete the old event
	Soundtrack.CustomEvents.DeleteEvent(tableName, oldEventName)
end

function Soundtrack.CustomEvents.DeleteEvent(tableName, eventName)
	local eventTable = Soundtrack.Events.GetTable(tableName)
	if eventTable then
		if eventTable[eventName] then
			debug("Removing event: " .. eventName)
			eventTable[eventName] = nil
		end
	end
end

function Soundtrack.CustomEvents.RegisterUpdateScript(_, name, _priority, _continuous, _script, _soundEffect)
	if not name then
		return
	end

	SoundtrackAddon.db.profile.customEvents[name] = {
		script = _script,
		eventtype = ST_UPDATE_SCRIPT,
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	Soundtrack.AddEvent(ST_CUSTOM, name, _priority, _continuous, _soundEffect)
end

function Soundtrack.CustomEvents.RegisterEventScript(name, _trigger, _priority, _continuous, _script, _soundEffect)
	if not name then
		return
	end

	SoundtrackAddon.db.profile.customEvents[name] = {
		trigger = _trigger,
		script = _script,
		eventtype = ST_EVENT_SCRIPT,
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	SoundtrackCustomDUMMY:RegisterEvent(_trigger)
	Soundtrack.AddEvent(ST_CUSTOM, name, _priority, _continuous, _soundEffect)
end

function Soundtrack.CustomEvents.RegisterBuffEvent(eventName, _spellId, _priority, _continuous, _soundEffect)
	if not eventName then
		return
	end

	SoundtrackAddon.db.profile.customEvents[eventName] = {
		spellId = _spellId,
		stackLevel = _priority,
		active = false,
		eventtype = ST_BUFF_SCRIPT,
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	Soundtrack.AddEvent(ST_CUSTOM, eventName, _priority, _continuous, _soundEffect)
end

function Soundtrack_Custom_PlayEvent(eventName)
	local eventTable = Soundtrack.Events.GetTable(ST_CUSTOM)
	if not eventTable then
		return
	end

	local currentEvent = Soundtrack.Events.Stack[eventTable[eventName].priority].eventName
	if eventName ~= currentEvent then
		Soundtrack.PlayEvent(ST_CUSTOM, eventName)
	end
end

function Soundtrack_Custom_StopEvent(eventName)
	local eventTable = Soundtrack.Events.GetTable(ST_CUSTOM)
	if not eventTable then
		return
	end

	local currentEvent = Soundtrack.Events.Stack[eventTable[eventName].priority].eventName
	if eventName == currentEvent then
		Soundtrack.StopEvent(ST_CUSTOM, eventName)
	end
end

-- CustomEvents
function Soundtrack.CustomEvents.CustomInitialize()
	-- Register events for custom events
	for k, v in pairs(SoundtrackAddon.db.profile.customEvents) do
		-- Fix for buff or debuff events that have the spellId stored as string
		if (v.eventtype == ST_BUFF_SCRIPT or v.eventtype == ST_DEBUFF_SCRIPT) and type(v.spellId) == "string" then
			local parsedSpellId = tonumber(v.spellId)
			if parsedSpellId then
				v.spellId = parsedSpellId
			end
		end

		Soundtrack.AddEvent(ST_CUSTOM, k, v.priority, v.continuous, v.soundEffect)
		if v.eventtype == ST_EVENT_SCRIPT then
			SoundtrackCustomDUMMY:RegisterEvent(v.trigger)
		end
	end

	Soundtrack_SortEvents(ST_CUSTOM)
end

-- CustomEvents
function Soundtrack.CustomEvents.CustomOnUpdate(_, _)
	if SoundtrackAddon.db.profile.settings.EnableCustomMusic then
		for k, v in pairs(SoundtrackAddon.db.profile.customEvents) do
			if v.eventtype == ST_UPDATE_SCRIPT and SoundtrackEvents_EventHasTracks(ST_CUSTOM, k) then
				v.script()
			end
		end
	end
end

-- CustomEvents
function Soundtrack.CustomEvents.CustomOnEvent(_, event)
	if SoundtrackAddon.db.profile.settings.EnableCustomMusic then
		for k, v in pairs(SoundtrackAddon.db.profile.customEvents) do
			if
				v.eventtype == ST_EVENT_SCRIPT
				and event == v.trigger
				and SoundtrackEvents_EventHasTracks(ST_CUSTOM, k)
			then
				RunScript(v.script)
			end
		end
	end
end

function Soundtrack.CustomEvents.OnPlayerAurasUpdated()
	if SoundtrackAddon.db.profile.settings.EnableCustomMusic then
		for k, v in pairs(SoundtrackAddon.db.profile.customEvents) do
			if v.spellId ~= 0 and SoundtrackEvents_EventHasTracks(ST_CUSTOM, k) then
				local isActive = Soundtrack.Auras.IsAuraActive(v.spellId)
				if not v.active and isActive then
					v.active = true
					Soundtrack_Custom_PlayEvent(k)
				elseif v.active and not isActive then
					v.active = false
					Soundtrack_Custom_StopEvent(k)
				end
			end
		end
	end
end
