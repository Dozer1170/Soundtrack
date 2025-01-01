SoundtrackUI.MovingTitle = {}

-- Lunaqua: Moves the title
local MAX_TITLE_LENGTH = 30
local backwards = true
local hold = 0
local holdLimit = 4
local titleDelayTime = 0
local titleUpdateTime = 0.5

local function IsTimeToUpdate()
	local titleCurrentTime = GetTime()
	if titleCurrentTime < titleDelayTime then
		return false
	else
		titleDelayTime = titleCurrentTime + titleUpdateTime
		return true
	end
end

local function CreateNext(title, oldTitle)
	local titleClean = CleanString(title)
	if oldTitle == nil then
		backwards = false
		return string.sub(titleClean, 1, MAX_TITLE_LENGTH)
	end

	-- Check old title length
	if string.len(oldTitle) > MAX_TITLE_LENGTH then
		oldTitle = string.sub(oldTitle, 1, MAX_TITLE_LENGTH)
	end
	-- Check if oldTitle is part of title
	local oldTitleClean = CleanString(oldTitle)
	local arg1, arg2 = string.find(titleClean, oldTitleClean, 1, true)
	-- arg1 = starting position where string found
	-- arg2 = ending position of string found, inclusive

	if arg1 == nil then
		-- Different track name, start up a new title.
		backwards = false
		if string.len(titleClean) > MAX_TITLE_LENGTH then
			return string.sub(titleClean, 1, MAX_TITLE_LENGTH)
		else
			return titleClean
		end
	elseif IsTimeToUpdate() then
		if string.len(titleClean) > MAX_TITLE_LENGTH then
			if backwards == true then
				-- Going backwards, check if at front of string
				if arg1 == 1 then
					if hold < holdLimit then
						-- Hold at end until hold = holdLimit
						hold = hold + 1
						return oldTitleClean
					elseif hold >= holdLimit then
						-- hold = holdLimit, string goes forward
						hold = 0
						backwards = false
						return string.sub(titleClean, arg1 + 1, arg2 + 1)
					end
				else
					return string.sub(titleClean, arg1 - 1, arg2 - 1)
				end
			else
				-- Going forwards, check if at end of string
				if arg2 == string.len(titleClean) then
					if hold < holdLimit then
						-- Hold at end until hold = holdLimit
						hold = hold + 1
						return oldTitleClean
					elseif hold >= holdLimit then
						-- hold = holdLimit, string goes backwards now
						hold = 0
						backwards = true
						return string.sub(titleClean, arg1 - 1, arg2 - 1)
					end
				else
					return string.sub(titleClean, arg1 + 1, arg2 + 1)
				end
			end
		else
			return titleClean
		end
	else
		return oldTitleClean
	end
end

function SoundtrackUI.MovingTitle.Update()
	local currentTrack = Soundtrack.Library.CurrentlyPlayingTrack

	if not Soundtrack_Tracks then
		return
	end

	local track = Soundtrack_Tracks[currentTrack]
	if not track then
		SoundtrackFrame_StatusBarTrackText1:SetText(SOUNDTRACK_NO_TRACKS_PLAYING)
		SoundtrackFrame_StatusBarTrackText2:SetText("")
	else
		local oldTitle = SoundtrackFrame_StatusBarTrackText1:GetText()
		if SoundtrackUI.nameHeaderType == "filePath" then
			local text = CreateNext(track.title, oldTitle)
			SoundtrackFrame_StatusBarTrackText1:SetText(text)
		elseif SoundtrackUI.nameHeaderType == "fileName" then
			local text = CreateNext(track.title, oldTitle)
			SoundtrackFrame_StatusBarTrackText1:SetText(text)
		else
			if track.title == nil or track.title == "" then
				local text = CreateNext(currentTrack, oldTitle)
				SoundtrackFrame_StatusBarTrackText1:SetText(text)
			else
				local text = CreateNext(track.title, oldTitle)
				SoundtrackFrame_StatusBarTrackText1:SetText(text)
			end
		end
	end

	SoundtrackControlFrame_StatusBarTrackText2:SetText(SoundtrackFrame_StatusBarTrackText2:GetText())
	SoundtrackControlFrame_StatusBarTrackText1:SetText(SoundtrackFrame_StatusBarTrackText1:GetText())
end
