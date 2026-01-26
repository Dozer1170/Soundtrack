if not WoWUnit then
	return
end

local Tests = WoWUnit("Soundtrack", "PLAYER_ENTERING_WORLD")

function Tests:GetPathFileName_WithWindowsPath_ReturnsFileName()
	local result = GetPathFileName("Interface\\AddOns\\Soundtrack\\Music\\track.mp3")
	
	AreEqual("track.mp3", result)
end

function Tests:GetPathFileName_WithUnixPath_ReturnsFileName()
	local result = GetPathFileName("Interface/AddOns/Soundtrack/Music/track.mp3")
	
	AreEqual("track.mp3", result)
end

function Tests:GetPathFileName_WithMixedPath_ReturnsFileName()
	local result = GetPathFileName("Interface\\AddOns/Soundtrack\\Music/track.ogg")
	
	AreEqual("track.ogg", result)
end

function Tests:GetPathFileName_WithNoPath_ReturnsInput()
	local result = GetPathFileName("simpletrack.mp3")
	
	AreEqual("simpletrack.mp3", result)
end

function Tests:GetPathFileName_WithEmptyString_ReturnsEmpty()
	local result = GetPathFileName("")
	
	AreEqual("", result)
end

function Tests:GetPathFileName_WithTrailingSlash_ReturnsEmpty()
	local result = GetPathFileName("Interface/AddOns/Soundtrack/")
	
	AreEqual("", result)
end

function Tests:IsNullOrEmpty_WithNil_ReturnsTrue()
	local result = IsNullOrEmpty(nil)
	
	AreEqual(true, result)
end

function Tests:IsNullOrEmpty_WithEmptyString_ReturnsTrue()
	local result = IsNullOrEmpty("")
	
	AreEqual(true, result)
end

function Tests:IsNullOrEmpty_WithWhitespace_ReturnsFalse()
	local result = IsNullOrEmpty("   ")
	
	AreEqual(false, result)
end

function Tests:IsNullOrEmpty_WithNonEmptyString_ReturnsFalse()
	local result = IsNullOrEmpty("test")
	
	AreEqual(false, result)
end

function Tests:StringSplit_WithCommaDelimiter_SplitsParts()
	local result = StringSplit("one,two,three", ",")
	
	AreEqual(3, #result)
	AreEqual("one", result[1])
	AreEqual("two", result[2])
	AreEqual("three", result[3])
end

function Tests:StringSplit_WithSlashDelimiter_SplitsParts()
	local result = StringSplit("path/to/file", "/")
	
	AreEqual(3, #result)
	AreEqual("path", result[1])
	AreEqual("to", result[2])
	AreEqual("file", result[3])
end

function Tests:StringSplit_WithNoDelimiter_ReturnsOriginalString()
	local result = StringSplit("nodelimiter", ",")
	
	AreEqual(1, #result)
	AreEqual("nodelimiter", result[1])
end

function Tests:StringSplit_WithEmptyString_ReturnsEmptyElement()
	local result = StringSplit("", ",")
	
	AreEqual(1, #result)
	AreEqual("", result[1])
end

function Tests:StringSplit_WithConsecutiveDelimiters_CreatesEmptyElements()
	local result = StringSplit("one,,three", ",")
	
	AreEqual(3, #result)
	AreEqual("one", result[1])
	AreEqual("", result[2])
	AreEqual("three", result[3])
end

function Tests:StringSplit_WithTrailingDelimiter_CreatesEmptyElement()
	local result = StringSplit("one,two,", ",")
	
	AreEqual(3, #result)
	AreEqual("one", result[1])
	AreEqual("two", result[2])
	AreEqual("", result[3])
end

function Tests:CleanString_RemovesCurlyBraces()
	local result = CleanString("text{with}braces")
	
	AreEqual("textwithbraces", result)
end

function Tests:CleanString_RemovesDoubleQuotes()
	local result = CleanString('text"with"quotes')
	
	AreEqual("textwithquotes", result)
end

function Tests:CleanString_RemovesSingleQuotes()
	local result = CleanString("text'with'quotes")
	
	AreEqual("textwithquotes", result)
end

function Tests:CleanString_RemovesBackslashes()
	local result = CleanString("text\\with\\backslashes")
	
	AreEqual("textwithbackslashes", result)
end

function Tests:CleanString_RemovesAllOffenders()
	local result = CleanString("{test\"string'with\\chars}")
	
	AreEqual("teststringwithchars", result)
end

function Tests:CleanString_WithCleanString_ReturnsUnchanged()
	local result = CleanString("cleanstring")
	
	AreEqual("cleanstring", result)
end

function Tests:FormatDuration_WithZeroSeconds_ReturnsZeroZero()
	local result = FormatDuration(0)
	
	AreEqual("0:00", result)
end

function Tests:FormatDuration_WithLessThanMinute_ReturnsSecondsOnly()
	local result = FormatDuration(45)
	
	AreEqual("0:45", result)
end

function Tests:FormatDuration_WithExactMinute_ReturnsMinuteZero()
	local result = FormatDuration(60)
	
	AreEqual("1:00", result)
end

function Tests:FormatDuration_WithMinutesAndSeconds_ReturnsFormatted()
	local result = FormatDuration(125)
	
	AreEqual("2:05", result)
end

function Tests:FormatDuration_WithLongDuration_ReturnsFormatted()
	local result = FormatDuration(3661)
	
	AreEqual("61:01", result)
end

function Tests:FormatDuration_WithNil_ReturnsEmptyString()
	local result = FormatDuration(nil)
	
	AreEqual("", result)
end

function Tests:FormatDuration_WithSingleDigitSeconds_PadsWithZero()
	local result = FormatDuration(67)
	
	AreEqual("1:07", result)
end

function Tests:FormatDuration_WithDoubleDigitSeconds_NoPadding()
	local result = FormatDuration(75)
	
	AreEqual("1:15", result)
end
