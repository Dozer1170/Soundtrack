local function GetPathFileNameRecursive(filePath)
	local index1 = string.find(filePath, "/")
	if not index1 then
		return filePath
	else
		return GetPathFileName(string.sub(filePath, index1 + 1))
	end
end

-- Strips a path string from the path and returns the file name at the end.
-- Used to strip parent events or parent folders from event and track names.
function GetPathFileName(filePath)
	local temp = string.gsub(filePath, "\\", "/")
	return GetPathFileNameRecursive(temp)
end

function IsNullOrEmpty(text)
	return not text or text == ""
end

function StringSplit(text, delimiter)
	local list = {}
	local pos = 1
	if strfind("", delimiter, 1) then
		error("delimiter matches empty string!")
	end

	while 1 do
		local first, last = strfind(text, delimiter, pos)
		if first then -- found?
			tinsert(list, strsub(text, pos, first - 1))
			pos = last + 1
		else
			tinsert(list, strsub(text, pos))
			break
		end
	end
	return list
end

-- Removes string.find offenders from a string
function CleanString(str)
	local cleanstr = string.gsub(str, "{", "")
	cleanstr = string.gsub(cleanstr, "}", "")
	cleanstr = string.gsub(cleanstr, '"', "")
	cleanstr = string.gsub(cleanstr, "'", "")
	cleanstr = string.gsub(cleanstr, "\\", "")
	return cleanstr
end

-- ---------------------------------------------------------------------------
-- Base64 encode / decode
-- ---------------------------------------------------------------------------

local B64_CHARS = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'

function Base64Encode(data)
	local result = {}
	local pad = 0
	for i = 1, #data, 3 do
		local b1, b2, b3 = data:byte(i, i + 2)
		b2 = b2 or 0; b3 = b3 or 0
		if i + 1 > #data then
			pad = 2
		elseif i + 2 > #data then
			pad = 1
		end
		local n = b1 * 65536 + b2 * 256 + b3
		table.insert(result, B64_CHARS:sub(math.floor(n / 262144) + 1, math.floor(n / 262144) + 1))
		table.insert(result, B64_CHARS:sub(math.floor(n / 4096) % 64 + 1, math.floor(n / 4096) % 64 + 1))
		table.insert(result, pad < 2 and B64_CHARS:sub(math.floor(n / 64) % 64 + 1, math.floor(n / 64) % 64 + 1) or '=')
		table.insert(result, pad < 1 and B64_CHARS:sub(n % 64 + 1, n % 64 + 1) or '=')
	end
	return table.concat(result)
end

function Base64Decode(data)
	local lookup = {}
	for i = 1, #B64_CHARS do
		lookup[B64_CHARS:sub(i, i)] = i - 1
	end
	local result = {}
	data = data:gsub('[^%w%+%/%=]', '') -- strip whitespace/newlines
	for i = 1, #data, 4 do
		local c1 = lookup[data:sub(i, i)] or 0
		local c2 = lookup[data:sub(i + 1, i + 1)] or 0
		local c3 = lookup[data:sub(i + 2, i + 2)]
		local c4 = lookup[data:sub(i + 3, i + 3)]
		local n  = c1 * 262144 + c2 * 4096
		table.insert(result, string.char(math.floor(n / 65536) % 256))
		if c3 then
			n = n + c3 * 64
			table.insert(result, string.char(math.floor(n / 256) % 256))
		end
		if c4 then
			n = n + c4
			table.insert(result, string.char(n % 256))
		end
	end
	return table.concat(result)
end

-- Returns the number of seconds in "mm.ss" format
function FormatDuration(seconds)
	if not seconds then
		return ""
	else
		return string.format("%i:%02i", math.floor(seconds / 60), seconds % 60)
	end
end
