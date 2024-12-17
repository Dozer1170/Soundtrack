-- Chat print functions
function Soundtrack.Message(text)
	Soundtrack.Util.ChatPrint("Soundtrack: " .. text)
end

function Soundtrack.Error(text)
	Soundtrack.Util.ChatPrint("Soundtrack: Error: " .. text, 1, 0.25, 0.0)
end

function Soundtrack.Warning(text)
	Soundtrack.Util.DebugPrint("Soundtrack: Warning: " .. text, 0.75, 0.75, 0.0)
end

function Soundtrack.Trace(text)
	Soundtrack.Util.DebugPrint("[Trace]: " .. text, 0.75, 0.75, 0.75)
end

function Soundtrack.TraceLibrary(text)
	Soundtrack.Util.DebugPrint("[Library]: " .. text, 0.25, 0.25, 1.0)
end

function Soundtrack.TraceBattle(text)
	Soundtrack.Util.DebugPrint("[Battle]: " .. text, 1.0, 0.0, 0.0)
end

function Soundtrack.TracePetBattles(text)
	Soundtrack.Util.DebugPrint("[Pet Battles]: " .. text, 0.5, 1.0, 0.0)
end

function Soundtrack.TraceZones(text)
	Soundtrack.Util.DebugPrint("[Zones]: " .. text, 0.0, 0.50, 0.0)
end

function Soundtrack.TraceFrame(text)
	Soundtrack.Util.DebugPrint("[Frame]: " .. text, 0.75, 0.75, 0.0)
end

function Soundtrack.TraceEvents(text)
	Soundtrack.Util.DebugPrint("[Events]: " .. text, 0.0, 1.0, 1.0)
end

function Soundtrack.TraceCustom(text)
	Soundtrack.Util.DebugPrint("[Custom]: " .. text, 1.0, 0.0, 0.5)
end

function Soundtrack.TraceProfiles(text)
	Soundtrack.Util.DebugPrint("[Profiles]: " .. text, 0.75, 1.0, 0.25)
end
