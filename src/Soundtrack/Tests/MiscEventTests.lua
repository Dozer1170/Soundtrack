if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

function Tests:RegisterUpdateScript_ValidName_RegistersScript()
	Soundtrack_MiscEvents = {}
	local registered = false
	Replace(Soundtrack, "AddEvent", function()
		registered = true
	end)
	
	Soundtrack.Misc.RegisterUpdateScript(nil, "TestScript", ST_ONCE_LVL, false, "test_function", false)
	
	AreEqual(true, Soundtrack_MiscEvents["TestScript"] ~= nil)
	AreEqual(true, registered)
end

function Tests:RegisterUpdateScript_ValidName_SetCorrectEventType()
	Soundtrack_MiscEvents = {}
	
	Soundtrack.Misc.RegisterUpdateScript(nil, "TestScript", ST_ONCE_LVL, false, "test_function", false)
	
	AreEqual(ST_UPDATE_SCRIPT, Soundtrack_MiscEvents["TestScript"].eventtype)
end

function Tests:RegisterUpdateScript_NoName_DoesNotRegister()
	Soundtrack_MiscEvents = {}
	
	Soundtrack.Misc.RegisterUpdateScript(nil, nil, ST_ONCE_LVL, false, "test_function", false)
	
	IsFalse(Soundtrack_MiscEvents["nil"])
end

function Tests:RegisterEventScript_ValidName_RegistersScript()
	Soundtrack_MiscEvents = {}
	local registered = false
	Replace(Soundtrack, "AddEvent", function()
		registered = true
	end)
	
	Soundtrack.Misc.RegisterEventScript({RegisterEvent = function() end}, "TestEvent", "UNIT_SPELLCAST_SUCCEEDED", ST_ONCE_LVL, false, "test_function", false)
	
	AreEqual(true, Soundtrack_MiscEvents["TestEvent"] ~= nil)
	AreEqual(true, registered)
end

function Tests:RegisterEventScript_ValidName_SetCorrectEventType()
	Soundtrack_MiscEvents = {}
	local self = {RegisterEvent = function() end}
	
	Soundtrack.Misc.RegisterEventScript(self, "TestEvent", "UNIT_SPELLCAST_SUCCEEDED", ST_ONCE_LVL, false, "test_function", false)
	
	AreEqual(ST_EVENT_SCRIPT, Soundtrack_MiscEvents["TestEvent"].eventtype)
end

function Tests:RegisterBuffEvent_ValidName_RegistersBuffEvent()
	Soundtrack_MiscEvents = {}
	local registered = false
	Replace(Soundtrack, "AddEvent", function()
		registered = true
	end)
	
	Soundtrack.Misc.RegisterBuffEvent("TestBuff", 1234, ST_ONCE_LVL, false, false)
	
	AreEqual(true, Soundtrack_MiscEvents["TestBuff"] ~= nil)
	AreEqual(true, registered)
end

function Tests:RegisterDebuffEvent_ValidName_RegistersDebuffEvent()
	Soundtrack_MiscEvents = {}
	local registered = false
	Replace(Soundtrack, "AddEvent", function()
		registered = true
	end)
	
	Soundtrack.Misc.RegisterDebuffEvent("TestDebuff", 1234, ST_ONCE_LVL, false, false)
	
	AreEqual(true, Soundtrack_MiscEvents["TestDebuff"] ~= nil)
	AreEqual(true, registered)
end

function Tests:Initialize_AddsAllMiscEventsToDatabase()
	local eventCount = 0
	Replace(Soundtrack, "AddEvent", function()
		eventCount = eventCount + 1
	end)
	Replace(SoundtrackAddon.db, "profile", {
		settings = {
			EnableMiscMusic = true
		}
	})
	Soundtrack_MiscEvents = {}
	
	Soundtrack.Misc.Initialize()
	
	AreEqual(true, eventCount > 0)
end
