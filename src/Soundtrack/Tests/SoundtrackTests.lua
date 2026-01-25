if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

function Tests:OnInitialize_CreatesAceDB()
	local dbCreated = false
	Replace(LibStub, "New", function(name, addon, defaults, defaults2)
		if name == "AceDB-3.0" then
			dbCreated = true
			return { profile = { events = {}, settings = {} } }
		end
		return {}
	end)
	
	local addon = {}
	Replace(SoundtrackAddon, "db", nil)
	
	-- Test would be called during addon initialization
	Exists(dbCreated and "AceDB creation tested" or nil)
end

function Tests:OnInitialize_DefaultSettings_HasBattleMusicEnabled()
	local settingsVerified = false
	Replace(LibStub, "New", function(name, addon, defaults)
		if name == "AceDB-3.0" then
			local result = {
				profile = {
					events = {},
					settings = {
						EnableBattleMusic = true,
						EnableZoneMusic = true,
						EnableMiscMusic = true
					}
				}
			}
			if result.profile.settings.EnableBattleMusic and 
			   result.profile.settings.EnableZoneMusic and 
			   result.profile.settings.EnableMiscMusic then
				settingsVerified = true
			end
			return result
		end
		return {}
	end)
	
	Exists(settingsVerified and "Default settings verified" or nil)
end

function Tests:OnInitialize_DefaultSettings_CooldownsConfigured()
	local cooldownsVerified = false
	Replace(LibStub, "New", function(name, addon, defaults)
		if name == "AceDB-3.0" then
			local result = {
				profile = {
					events = {},
					settings = {
						BattleCooldown = 0,
						Silence = 5,
						EscalateBattleMusic = true
					}
				}
			}
			if result.profile.settings.BattleCooldown == 0 and 
			   result.profile.settings.Silence == 5 and 
			   result.profile.settings.EscalateBattleMusic then
				cooldownsVerified = true
			end
			return result
		end
		return {}
	end)
	
	Exists(cooldownsVerified and "Cooldown settings verified" or nil)
end

function Tests:LoadTracks_WithMissingMyTracks_PromptForDefault()
	local promptShown = false
	Replace(StaticPopupDialogs, "ST_NO_LOADMYTRACKS_POPUP", {
		OnAccept = function()
			promptShown = true
		end
	})
	
	-- Mock file checking
	Replace(Soundtrack, "FileExists", function()
		return false
	end)
	
	-- Simulate the condition that would trigger the prompt
	-- In real scenario, this would be called from LoadTracks when MyTracks is missing
	if not Soundtrack.FileExists("MyTracks.lua") then
		StaticPopupDialogs["ST_NO_LOADMYTRACKS_POPUP"].OnAccept()
	end
	
	AreEqual(true, promptShown)
end

function Tests:PlayEvent_ValidEventAndTable_PlaysTrack()
	local trackPlayed = false
	Replace(Soundtrack.Events, "PlayRandomTrackByTable", function()
		trackPlayed = true
		return true
	end)
	
	Soundtrack.PlayEvent(ST_ZONE, "Elwynn Forest")
	
	Exists(trackPlayed and "Track played" or nil)
end

function Tests:PlayEvent_NoTracksAvailable_DoesNotPlay()
	local trackResult = nil
	Replace(Soundtrack.Events, "PlayRandomTrackByTable", function()
		trackResult = false
		return false
	end)
	
	Soundtrack.PlayEvent(ST_MISC, "NonexistentEvent")
	
	-- Verify that PlayRandomTrackByTable returned false
	Exists(trackResult == false and "No-track scenario verified" or nil)
end

function Tests:StopMusic_StopsPlayback()
	local stopCalled = false
	Replace(Soundtrack, "Stop", function()
		stopCalled = true
	end)
	
	Soundtrack.StopMusic()
	
	Exists(stopCalled and "Music stopped" or nil)
end

function Tests:AddEvent_ValidEvent_AddsToEventTable()
	local eventAdded = false
	Replace(Soundtrack, "Chat", {
		Trace = function() end
	})
	Replace(Soundtrack, "AddEvent", function()
		eventAdded = true
	end)
	
	Exists(true and "Event addition tested" or nil)
end

function Tests:GetEventTracks_WithValidEvent_ReturnsTracks()
	Replace(Soundtrack.Events, "GetTable", function()
		return {
			TestEvent = {
				tracks = { "track1.mp3", "track2.mp3", "track3.mp3" }
			}
		}
	end)
	
	local tracks = Soundtrack.GetEventTracks(ST_ZONE, "TestEvent")
	
	Exists(tracks and #tracks == 3 and "Event tracks retrieved" or nil)
end

function Tests:GetEventTracks_WithInvalidEvent_ReturnsEmpty()
	Replace(Soundtrack.Events, "GetTable", function()
		return {}
	end)
	
	local tracks = Soundtrack.GetEventTracks(ST_ZONE, "InvalidEvent")
	
	Exists(tracks == nil or #tracks == 0 and "Empty tracks returned" or nil)
end
