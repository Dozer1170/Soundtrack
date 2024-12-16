function Soundtrack.IsNullOrEmpty(text)
	return not text or text == ""
end

local function GetPathFileNameRecursive(filePath)
	local index1 = string.find(filePath, "/")
	if not index1 then
		return filePath
	else
		return Soundtrack.GetPathFileName(string.sub(filePath, index1 + 1))
	end
end

-- Strips a path string from the path and returns the file name at the end.
-- Used to strip parent events or parent folders from event and track names.
function Soundtrack.GetPathFileName(filePath)
	local temp = string.gsub(filePath, "\\", "/")
	return GetPathFileNameRecursive(temp)
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

function StringSplit(str, delim, maxNb)
	-- Eliminate bad cases...
	if string.find(str, delim) == nil then
		return { str }
	end
	if maxNb == nil or maxNb < 1 then
		maxNb = 0 -- No limit
	end
	local result = {}
	local pat = "(.-)" .. delim .. "()"
	local nb = 0
	local lastPos
	for part, pos in string.gmatch(str, pat) do
		nb = nb + 1
		result[nb] = part
		lastPos = pos
		if nb == maxNb then
			break
		end
	end
	-- Handle the last field
	if nb ~= maxNb then
		result[nb + 1] = string.sub(str, lastPos)
	end
	return result
end
