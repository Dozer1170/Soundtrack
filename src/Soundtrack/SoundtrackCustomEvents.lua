--[[
    Soundtrack addon for World of Warcraft

    Custom events functions.
    Functions that manage misc. and custom events.
]]

-- TODO: Actually split misc into its own file
Soundtrack.CustomEvents = {}
Soundtrack.ActiveAuras = {}

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

-- table can be Custom or Misc.
function Soundtrack.CustomEvents.RegisterUpdateScript(_, name, _priority, _continuous, _script, _soundEffect)
	if not name then
		return
	end

	SoundtrackAddon.db.profile.customEvents[name] = {
		script = _script,
		eventtype = "Update Script",
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	Soundtrack.AddEvent(ST_CUSTOM, name, _priority, _continuous, _soundEffect)
end

-- table can be Custom or Misc.
function Soundtrack.CustomEvents.RegisterEventScript(
	self,
	name,
	_trigger,
	_priority,
	_continuous,
	_script,
	_soundEffect
)
	if not name then
		return
	end

	SoundtrackAddon.db.profile.customEvents[name] = {
		trigger = _trigger,
		script = _script,
		eventtype = "Event Script",
		priority = _priority,
		continuous = _continuous,
		soundEffect = _soundEffect,
	}

	self:RegisterEvent(_trigger)
	Soundtrack.AddEvent(ST_CUSTOM, name, _priority, _continuous, _soundEffect)
end

function Soundtrack.CustomEvents.UpdateActiveAuras()
	Soundtrack.ActiveAuras = {}
	for i = 1, 40 do
		local buff = C_UnitAuras.GetBuffDataByIndex("player", i)
		if buff ~= nil then
			Soundtrack.ActiveAuras[buff.spellId] = buff.spellId
		end
		local debuff = C_UnitAuras.GetDebuffDataByIndex("player", i)
		if debuff ~= nil then
			Soundtrack.ActiveAuras[debuff.spellId] = debuff.spellId
		end
	end
end --]]

-- Returns the spellID of the buff, else nil
function Soundtrack.CustomEvents.IsAuraActive(spellId)
	return Soundtrack.ActiveAuras[spellId]
end

function Soundtrack.CustomEvents.RegisterBuffEvent(eventName, _spellId, _priority, _continuous, _soundEffect)
	if not eventName then
		return
	end

	SoundtrackAddon.db.profile.customEvents[eventName] = {
		spellId = _spellId,
		stackLevel = _priority,
		active = false,
		eventtype = "Buff",
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
	SoundtrackCustomDUMMY:RegisterEvent("UNIT_AURA")

	-- Register events for custom events
	for k, v in pairs(SoundtrackAddon.db.profile.customEvents) do
		-- Fix for buff or debuff events that have the spellId stored as string
		if (v.eventtype == "Buff" or v.eventtype == "Debuff") and type(v.spellId) == "string" then
			local parsedSpellId = tonumber(v.spellId)
			if parsedSpellId then
				v.spellId = parsedSpellId
			end
		end

		Soundtrack.AddEvent(ST_CUSTOM, k, v.priority, v.continuous, v.soundEffect)
		if v.eventtype == "Event Script" then
			SoundtrackCustomDUMMY:RegisterEvent(v.trigger)
		end
	end

	Soundtrack_SortEvents(ST_CUSTOM)
end

-- CustomEvents
function Soundtrack.CustomEvents.CustomOnUpdate(_, _)
	if SoundtrackAddon.db.profile.settings.EnableCustomMusic then
		for k, v in pairs(SoundtrackAddon.db.profile.customEvents) do
			if v.eventtype == "Update Script" and SoundtrackEvents_EventHasTracks(ST_CUSTOM, k) then
				v.script()
			end
		end
	end
end

-- CustomEvents
function Soundtrack.CustomEvents.CustomOnEvent(_, event, ...)
	local st_arg1, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _, _ = ...

	Soundtrack.CustomEvents.UpdateActiveAuras()

	if event == "UNIT_AURA" and st_arg1 == "player" then
		if SoundtrackAddon.db.profile.settings.EnableCustomMusic then
			for k, v in pairs(SoundtrackAddon.db.profile.customEvents) do
				if v.spellId ~= 0 and SoundtrackEvents_EventHasTracks(ST_CUSTOM, k) then
					local isActive = Soundtrack.CustomEvents.IsAuraActive(v.spellId)
					if not v.active and isActive then
						v.active = true
						Soundtrack_Custom_PlayEvent(ST_CUSTOM, k)
					elseif v.active and not isActive then
						v.active = false
						Soundtrack_Custom_StopEvent(ST_CUSTOM, k)
					end
				end
			end
		end
	end

	-- Handle custom events
	if SoundtrackAddon.db.profile.settings.EnableCustomMusic then
		for k, v in pairs(SoundtrackAddon.db.profile.customEvents) do
			if
				v.eventtype == "Event Script"
				and event == v.trigger
				and SoundtrackEvents_EventHasTracks(ST_CUSTOM, k)
			then
				RunScript(v.script)
			end
		end
	end
end
