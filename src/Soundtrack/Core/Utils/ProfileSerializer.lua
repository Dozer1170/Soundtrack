--[[
    Soundtrack addon for World of Warcraft

    Profile Serializer — converts profile data (events + settings) to a
    share string that can be copy-pasted between players, and restores it.

    Format V3: "SOUNDTRACK_PROFILE_V3:" followed by pretty-printed JSON.
    Format V2: "SOUNDTRACK_PROFILE_V2:" followed by a Base64-encoded payload (legacy, still decoded).
    Format V1: "SOUNDTRACK_PROFILE_V1:" followed by compact JSON (legacy, still decoded).
]]

Soundtrack.ProfileSerializer = {}

local HEADER_V1              = "SOUNDTRACK_PROFILE_V1:"
local HEADER_V2              = "SOUNDTRACK_PROFILE_V2:"
local HEADER_V3              = "SOUNDTRACK_PROFILE_V3:"
local HEADER                 = HEADER_V3 -- used when exporting

-- ---------------------------------------------------------------------------
-- Encoder
-- ---------------------------------------------------------------------------

local function Encode(val)
    local t = type(val)
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "number" then
        if val == math.floor(val) then
            return tostring(math.floor(val))
        end
        return tostring(val)
    elseif t == "string" then
        -- Escape backslashes first, then double-quotes
        local escaped = val:gsub("\\", "\\\\"):gsub('"', '\\"')
        return '"' .. escaped .. '"'
    elseif t == "table" then
        -- Detect whether the table is a pure sequence (array).
        -- A sequence has only consecutive integer keys starting at 1.
        local n = #val
        local isSeq = (n > 0)
        if isSeq then
            for k in pairs(val) do
                if type(k) ~= "number" or k ~= math.floor(k) or k < 1 or k > n then
                    isSeq = false
                    break
                end
            end
        end

        if isSeq then
            local parts = {}
            for i = 1, n do
                table.insert(parts, Encode(val[i]))
            end
            return "[" .. table.concat(parts, ",") .. "]"
        else
            local parts = {}
            -- Sort keys for deterministic output
            local keys = {}
            for k in pairs(val) do
                if type(k) == "string" then
                    table.insert(keys, k)
                end
            end
            table.sort(keys)
            for _, k in ipairs(keys) do
                local escapedKey = k:gsub("\\", "\\\\"):gsub('"', '\\"')
                table.insert(parts, '"' .. escapedKey .. '":' .. Encode(val[k]))
            end
            return "{" .. table.concat(parts, ",") .. "}"
        end
    end
    return "null"
end

-- Pretty-printing encoder (used for V3 export).
local function EncodePretty(val, indent)
    indent = indent or 0
    local t = type(val)
    if t == "nil" then
        return "null"
    elseif t == "boolean" then
        return val and "true" or "false"
    elseif t == "number" then
        if val == math.floor(val) then
            return tostring(math.floor(val))
        end
        return tostring(val)
    elseif t == "string" then
        local escaped = val:gsub("\\", "\\\\"):gsub('"', '\\"')
        return '"' .. escaped .. '"'
    elseif t == "table" then
        local n = #val
        local isSeq = (n > 0)
        if isSeq then
            for k in pairs(val) do
                if type(k) ~= "number" or k ~= math.floor(k) or k < 1 or k > n then
                    isSeq = false
                    break
                end
            end
        end
        local pad      = string.rep("  ", indent)
        local innerPad = string.rep("  ", indent + 1)
        if isSeq then
            if n == 0 then return "[]" end
            local parts = {}
            for i = 1, n do
                table.insert(parts, innerPad .. EncodePretty(val[i], indent + 1))
            end
            return "[\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "]"
        else
            local keys = {}
            for k in pairs(val) do
                if type(k) == "string" then table.insert(keys, k) end
            end
            if #keys == 0 then return "{}" end
            table.sort(keys)
            local parts = {}
            for _, k in ipairs(keys) do
                local escapedKey = k:gsub("\\", "\\\\"):gsub('"', '\\"')
                table.insert(parts, innerPad .. '"' .. escapedKey .. '": ' .. EncodePretty(val[k], indent + 1))
            end
            return "{\n" .. table.concat(parts, ",\n") .. "\n" .. pad .. "}"
        end
    end
    return "null"
end

-- ---------------------------------------------------------------------------
-- Decoder — recursive descent parser
-- ---------------------------------------------------------------------------

-- Parser state (module-level to avoid closure overhead on every call)
local _src, _pos

local function Peek()
    return _src:sub(_pos, _pos)
end

local function Advance()
    local c = _src:sub(_pos, _pos)
    _pos = _pos + 1
    return c
end

local function Expect(c)
    local got = Advance()
    if got ~= c then
        error("Expected '" .. c .. "' got '" .. got .. "' at position " .. (_pos - 1))
    end
end

local function SkipWS()
    while _pos <= #_src do
        local c = _src:sub(_pos, _pos)
        if c == ' ' or c == '\t' or c == '\n' or c == '\r' then
            _pos = _pos + 1
        else
            break
        end
    end
end

local DecodeValue -- forward declaration

local function DecodeString()
    Expect('"')
    local parts = {}
    while true do
        local c = Advance()
        if c == '"' then
            break
        elseif c == '\\' then
            local esc = Advance()
            if esc == '"' then
                table.insert(parts, '"')
            elseif esc == '\\' then
                table.insert(parts, '\\')
            elseif esc == 'n' then
                table.insert(parts, '\n')
            elseif esc == 't' then
                table.insert(parts, '\t')
            else
                table.insert(parts, esc)
            end
        elseif c == '' then
            error("Unterminated string at position " .. _pos)
        else
            table.insert(parts, c)
        end
    end
    return table.concat(parts)
end

local function DecodeNumber()
    local start = _pos
    if Peek() == '-' then Advance() end
    while Peek():match('%d') do Advance() end
    if Peek() == '.' then
        Advance()
        while Peek():match('%d') do Advance() end
    end
    local e = Peek()
    if e == 'e' or e == 'E' then
        Advance()
        local s = Peek()
        if s == '+' or s == '-' then Advance() end
        while Peek():match('%d') do Advance() end
    end
    return tonumber(_src:sub(start, _pos - 1))
end

local function DecodeObject()
    Expect('{')
    local obj = {}
    SkipWS()
    if Peek() == '}' then
        Advance()
        return obj
    end
    while true do
        local key = DecodeString()
        SkipWS()
        Expect(':')
        SkipWS()
        obj[key] = DecodeValue()
        SkipWS()
        local c = Peek()
        if c == '}' then
            Advance()
            break
        end
        Expect(',')
        SkipWS()
    end
    return obj
end

local function DecodeArray()
    Expect('[')
    local arr = {}
    SkipWS()
    if Peek() == ']' then
        Advance()
        return arr
    end
    while true do
        table.insert(arr, DecodeValue())
        SkipWS()
        local c = Peek()
        if c == ']' then
            Advance()
            break
        end
        Expect(',')
        SkipWS()
    end
    return arr
end

DecodeValue = function()
    SkipWS()
    local c = Peek()
    if c == '"' then
        return DecodeString()
    elseif c == '{' then
        return DecodeObject()
    elseif c == '[' then
        return DecodeArray()
    elseif c == 't' then
        Expect('t'); Expect('r'); Expect('u'); Expect('e')
        return true
    elseif c == 'f' then
        Expect('f'); Expect('a'); Expect('l'); Expect('s'); Expect('e')
        return false
    elseif c == 'n' then
        Expect('n'); Expect('u'); Expect('l'); Expect('l')
        return nil
    elseif c:match('[%d%-]') then
        return DecodeNumber()
    end
    error("Unexpected character '" .. c .. "' at position " .. _pos)
end

-- ---------------------------------------------------------------------------
-- Public API
-- ---------------------------------------------------------------------------

-- Returns the full export string for the current profile.
function Soundtrack.ProfileSerializer.Export()
    local profile = SoundtrackAddon.db.profile
    local data = {
        events   = profile.events,
        settings = profile.settings,
    }
    return HEADER .. "\n" .. EncodePretty(data)
end

-- Parses an export string and returns the decoded table WITHOUT writing
-- anything to the current profile.
-- Returns true, data    on success.
-- Returns false, errorMsg on failure.
function Soundtrack.ProfileSerializer.Decode(str)
    if not str or str == "" then
        return false, "Empty import string."
    end

    local payload
    if str:sub(1, #HEADER_V3) == HEADER_V3 then
        -- V3: pretty-printed JSON (may start with a newline)
        payload = str:sub(#HEADER_V3 + 1)
    elseif str:sub(1, #HEADER_V2) == HEADER_V2 then
        -- V2 legacy: base64-encoded payload
        payload = Base64Decode(str:sub(#HEADER_V2 + 1))
    elseif str:sub(1, #HEADER_V1) == HEADER_V1 then
        -- V1 legacy: compact JSON payload
        payload = str:sub(#HEADER_V1 + 1)
    else
        return false, "Invalid profile string - make sure you copied the full export."
    end

    local ok, result = pcall(function()
        _src = payload
        _pos = 1
        return DecodeValue()
    end)

    if not ok then
        return false, "Failed to parse profile: " .. tostring(result)
    end

    if type(result) ~= "table" then
        return false, "Unexpected data format."
    end

    return true, result
end

-- Applies previously decoded profile data to the current profile.
-- Expects the table returned by Decode().
function Soundtrack.ProfileSerializer.Apply(data)
    if data.events then
        SoundtrackAddon.db.profile.events = data.events
    end
    if data.settings then
        for k, v in pairs(data.settings) do
            SoundtrackAddon.db.profile.settings[k] = v
        end
    end
end

-- Parses an export string and applies it to the current profile.
-- Returns true, message  on success.
-- Returns false, errorMsg on failure.
function Soundtrack.ProfileSerializer.Import(str)
    local ok, result = Soundtrack.ProfileSerializer.Decode(str)
    if not ok then
        return false, result
    end
    Soundtrack.ProfileSerializer.Apply(result)
    return true, "Profile imported successfully."
end
