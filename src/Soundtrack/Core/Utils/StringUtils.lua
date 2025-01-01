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
	cleanstr = string.gsub(cleanstr, '"', "")
	cleanstr = string.gsub(cleanstr, "'", "")
	cleanstr = string.gsub(cleanstr, "\\", "")
	return cleanstr
end

-- Returns the number of seconds in "mm.ss" format
function FormatDuration(seconds)
	if not seconds then
		return ""
	else
		return string.format("%i:%02i", math.floor(seconds / 60), seconds % 60)
	end
end
