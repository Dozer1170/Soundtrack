if not Tests then
	return
end

local Tests = Tests("Soundtrack", "PLAYER_ENTERING_WORLD")

-- ---------------------------------------------------------------------------
-- Encode / Decode round-trip helpers
-- ---------------------------------------------------------------------------

local function RoundTrip(data)
	-- Export using a temporary profile, then import into a fresh one.
	local saved = SoundtrackAddon.db.profile
	SoundtrackAddon.db.profile = {
		events   = data.events   or {},
		settings = data.settings or {},
	}
	local str = Soundtrack.ProfileSerializer.Export()

	-- Reset profile and import.
	SoundtrackAddon.db.profile = {
		events   = {},
		settings = {},
	}
	local ok, msg = Soundtrack.ProfileSerializer.Import(str)
	local result = SoundtrackAddon.db.profile
	SoundtrackAddon.db.profile = saved
	return ok, msg, result
end

-- ---------------------------------------------------------------------------
-- Decode tests (parse-only, no side effects)
-- ---------------------------------------------------------------------------

function Tests:Decode_ValidString_ReturnsData()
	local str = Soundtrack.ProfileSerializer.Export()
	local ok, data = Soundtrack.ProfileSerializer.Decode(str)
	IsTrue(ok, "Decode succeeds on valid string")
	IsTrue(type(data) == "table", "Returns a table")
end

function Tests:Decode_EmptyString_ReturnsFalse()
	local ok, _ = Soundtrack.ProfileSerializer.Decode("")
	IsFalse(ok, "Empty string returns false")
end

function Tests:Decode_WrongHeader_ReturnsFalse()
	local ok, msg = Soundtrack.ProfileSerializer.Decode("WRONG_HEADER:{}")
	IsFalse(ok, "Wrong header returns false")
	IsTrue(msg:find("Invalid") ~= nil, "Error mentions invalid")
end

function Tests:Decode_DoesNotWriteToProfile()
	local original = SoundtrackAddon.db.profile.events
	local str = Soundtrack.ProfileSerializer.Export()

	-- Modify profile after exporting, then decode.
	SoundtrackAddon.db.profile.events = { _sentinel = true }
	Soundtrack.ProfileSerializer.Decode(str)

	-- Profile should be unchanged (Decode must not write).
	IsTrue(SoundtrackAddon.db.profile.events._sentinel == true, "Decode did not overwrite profile")
	SoundtrackAddon.db.profile.events = original
end

-- ---------------------------------------------------------------------------
-- Apply tests
-- ---------------------------------------------------------------------------

function Tests:Apply_WritesEventsToProfile()
	local data = {
		events   = { [ST_ZONE] = { ["Elwynn"] = { tracks = { "x.mp3" }, priority = 2 } } },
		settings = {},
	}
	Soundtrack.ProfileSerializer.Apply(data)
	IsTrue(SoundtrackAddon.db.profile.events[ST_ZONE]["Elwynn"] ~= nil, "Events applied")
end

function Tests:Apply_WritesSettingsToProfile()
	SoundtrackAddon.db.profile.settings.BattleCooldown = 0
	local data = { events = {}, settings = { BattleCooldown = 99 } }
	Soundtrack.ProfileSerializer.Apply(data)
	AreEqual(99, SoundtrackAddon.db.profile.settings.BattleCooldown, "Setting applied")
end

function Tests:Apply_NilEvents_DoesNotClearProfile()
	SoundtrackAddon.db.profile.events[ST_ZONE] = { ["Keep"] = { tracks = {} } }
	local data = { settings = { Debug = false } }
	Soundtrack.ProfileSerializer.Apply(data)
	IsTrue(SoundtrackAddon.db.profile.events[ST_ZONE]["Keep"] ~= nil, "Events untouched when nil in data")
end

-- ---------------------------------------------------------------------------
-- Export tests
-- ---------------------------------------------------------------------------

function Tests:Export_ReturnsStringWithHeader()
	local header = "SOUNDTRACK_PROFILE_V1:"
	local str = Soundtrack.ProfileSerializer.Export()
	IsTrue(str:sub(1, #header) == header, "Header present")
end

function Tests:Export_NonEmptyString()
	local header = "SOUNDTRACK_PROFILE_V1:"
	local str = Soundtrack.ProfileSerializer.Export()
	IsTrue(#str > #header, "Export string is non-empty beyond header")
end

-- ---------------------------------------------------------------------------
-- Import error cases
-- ---------------------------------------------------------------------------

function Tests:Import_EmptyString_ReturnsFalse()
	local ok, msg = Soundtrack.ProfileSerializer.Import("")
	IsFalse(ok, "Empty string returns false")
	IsTrue(msg ~= nil and #msg > 0, "Error message provided")
end

function Tests:Import_NilString_ReturnsFalse()
	local ok, msg = Soundtrack.ProfileSerializer.Import(nil)
	IsFalse(ok, "Nil returns false")
end

function Tests:Import_WrongHeader_ReturnsFalse()
	local ok, msg = Soundtrack.ProfileSerializer.Import("NOT_A_SOUNDTRACK_STRING:{}")
	IsFalse(ok, "Wrong header returns false")
	IsTrue(msg:find("Invalid") ~= nil, "Error mentions invalid")
end

function Tests:Import_MalformedPayload_ReturnsFalse()
	local ok, msg = Soundtrack.ProfileSerializer.Import("SOUNDTRACK_PROFILE_V1:{malformed!!}")
	IsFalse(ok, "Malformed JSON returns false")
end

-- ---------------------------------------------------------------------------
-- Round-trip correctness
-- ---------------------------------------------------------------------------

function Tests:RoundTrip_StringEventName_Preserved()
	local ok, _, result = RoundTrip({
		events   = { [ST_ZONE] = { ["Eastern Kingdoms"] = { tracks = {}, priority = 2 } } },
		settings = {},
	})
	IsTrue(ok, "Import succeeded")
	IsTrue(result.events[ST_ZONE]["Eastern Kingdoms"] ~= nil, "Event name preserved")
end

function Tests:RoundTrip_TrackList_Preserved()
	local ok, _, result = RoundTrip({
		events = {
			[ST_BATTLE] = {
				["Normal Battle"] = {
					tracks = { "Music/Battle/fight1.mp3", "Music/Battle/fight2.mp3" },
					priority = 10,
					random = true,
					continuous = false,
				},
			},
		},
		settings = {},
	})
	IsTrue(ok, "Import succeeded")
	local event = result.events[ST_BATTLE]["Normal Battle"]
	IsTrue(event ~= nil, "Event present")
	AreEqual(2, #event.tracks, "Track count preserved")
	AreEqual("Music/Battle/fight1.mp3", event.tracks[1], "First track preserved")
	AreEqual("Music/Battle/fight2.mp3", event.tracks[2], "Second track preserved")
end

function Tests:RoundTrip_BooleanFields_Preserved()
	local ok, _, result = RoundTrip({
		events = {
			[ST_MISC] = {
				["Swimming"] = {
					tracks = {},
					priority = 7,
					random = false,
					continuous = true,
				},
			},
		},
		settings = {},
	})
	IsTrue(ok, "Import succeeded")
	local event = result.events[ST_MISC]["Swimming"]
	AreEqual(false, event.random,     "random=false preserved")
	AreEqual(true,  event.continuous, "continuous=true preserved")
end

function Tests:RoundTrip_NumberPriority_Preserved()
	local ok, _, result = RoundTrip({
		events = {
			[ST_BATTLE] = {
				["Boss"] = { tracks = {}, priority = 12 },
			},
		},
		settings = {},
	})
	IsTrue(ok, "Import succeeded")
	AreEqual(12, result.events[ST_BATTLE]["Boss"].priority, "Priority number preserved")
end

function Tests:RoundTrip_Settings_Preserved()
	local ok, _, result = RoundTrip({
		events = {},
		settings = {
			BattleCooldown  = 5,
			Silence         = 3,
			Debug           = false,
			AutoAddZones    = true,
		},
	})
	IsTrue(ok, "Import succeeded")
	AreEqual(5,     result.settings.BattleCooldown, "BattleCooldown preserved")
	AreEqual(3,     result.settings.Silence,        "Silence preserved")
	AreEqual(false, result.settings.Debug,          "Debug=false preserved")
	AreEqual(true,  result.settings.AutoAddZones,   "AutoAddZones=true preserved")
end

function Tests:RoundTrip_SpecialCharsInEventName_Preserved()
	local eventName = [[Instances/Naxx "Hard" Mode]]
	local ok, _, result = RoundTrip({
		events   = { [ST_ZONE] = { [eventName] = { tracks = {}, priority = 3 } } },
		settings = {},
	})
	IsTrue(ok, "Import succeeded")
	IsTrue(result.events[ST_ZONE][eventName] ~= nil, "Event with quotes in name preserved")
end

function Tests:RoundTrip_BackslashInTrackPath_Preserved()
	local trackPath = "Music\\Zone\\SomeTrack.mp3"
	local ok, _, result = RoundTrip({
		events = {
			[ST_ZONE] = {
				["Elwynn"] = { tracks = { trackPath }, priority = 2 },
			},
		},
		settings = {},
	})
	IsTrue(ok, "Import succeeded")
	AreEqual(trackPath, result.events[ST_ZONE]["Elwynn"].tracks[1], "Backslash path preserved")
end

function Tests:RoundTrip_MultipleEventTables_Preserved()
	local ok, _, result = RoundTrip({
		events = {
			[ST_ZONE]   = { ["Elwynn Forest"] = { tracks = { "a.mp3" }, priority = 2 } },
			[ST_BATTLE] = { ["Normal Battle"] = { tracks = { "b.mp3" }, priority = 10 } },
		},
		settings = {},
	})
	IsTrue(ok, "Import succeeded")
	IsTrue(result.events[ST_ZONE]["Elwynn Forest"]   ~= nil, "Zone event preserved")
	IsTrue(result.events[ST_BATTLE]["Normal Battle"]  ~= nil, "Battle event preserved")
end

function Tests:RoundTrip_EmptyProfile_Succeeds()
	local ok, msg, result = RoundTrip({ events = {}, settings = {} })
	IsTrue(ok, "Empty profile import succeeds: " .. tostring(msg))
end
