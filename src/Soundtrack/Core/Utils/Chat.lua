Soundtrack.Chat = {}

local debugChatFrameIndex = 1
local function FindChatFrameIndex()
	for i = 1, 10 do
		local name = GetChatWindowInfo(i)
		if name == "Soundtrack" then
			debugChatFrameIndex = i
			return
		end
	end
end

local function ChatPrint(text, cRed, cGreen, cBlue, _, _)
	if cRed and cGreen and cBlue then
		local frame = _G["ChatFrame" .. debugChatFrameIndex]
		if frame then
			frame:AddMessage(text, cRed, cGreen, cBlue)
		elseif DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage(text, cRed, cGreen, cBlue)
		end
	else
		local frame = _G["ChatFrame" .. debugChatFrameIndex]
		if frame then
			frame:AddMessage(text, 0.0, 1.0, 0.25)
		elseif DEFAULT_CHAT_FRAME then
			DEFAULT_CHAT_FRAME:AddMessage(text, 0.0, 1.0, 0.25)
		end
	end
end

function Soundtrack.Chat.InitDebugChatFrame()
	FindChatFrameIndex()
end

function Soundtrack.Chat.Debug(text, cRed, cGreen, cBlue)
	if SoundtrackAddon.db.profile.settings.Debug then
		ChatPrint(text, cRed, cGreen, cBlue)
	end
end

function Soundtrack.Chat.Message(text)
	ChatPrint("Soundtrack: " .. text)
end

function Soundtrack.Chat.Error(text)
	ChatPrint("Soundtrack: Error: " .. text, 1, 0.25, 0.0)
end

function Soundtrack.Chat.Warning(text)
	Soundtrack.Chat.Debug("Soundtrack: Warning: " .. text, 0.75, 0.75, 0.0)
end

function Soundtrack.Chat.Trace(text)
	Soundtrack.Chat.Debug("[Trace]: " .. text, 0.75, 0.75, 0.75)
end

function Soundtrack.Chat.TraceLibrary(text)
	Soundtrack.Chat.Debug("[Library]: " .. text, 0.25, 0.25, 1.0)
end

function Soundtrack.Chat.TraceBattle(text)
	Soundtrack.Chat.Debug("[Battle]: " .. text, 1.0, 0.0, 0.0)
end

function Soundtrack.Chat.TracePetBattles(text)
	Soundtrack.Chat.Debug("[Pet Battles]: " .. text, 0.5, 1.0, 0.0)
end

function Soundtrack.Chat.TraceZones(text)
	Soundtrack.Chat.Debug("[Zones]: " .. text, 0.0, 0.50, 0.0)
end

function Soundtrack.Chat.TraceFrame(text)
	Soundtrack.Chat.Debug("[Frame]: " .. text, 0.75, 0.75, 0.0)
end

function Soundtrack.Chat.TraceEvents(text)
	Soundtrack.Chat.Debug("[Events]: " .. text, 0.0, 1.0, 1.0)
end

function Soundtrack.Chat.TraceCustom(text)
	Soundtrack.Chat.Debug("[Custom]: " .. text, 1.0, 0.0, 0.5)
end

function Soundtrack.Chat.TraceProfiles(text)
	Soundtrack.Chat.Debug("[Profiles]: " .. text, 0.75, 1.0, 0.25)
end
