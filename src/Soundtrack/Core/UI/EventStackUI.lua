function SoundtrackUI.UpdateEventStackUI()
	for i = 1, Soundtrack.Events.MaxStackLevel, 1 do
		local tableName = Soundtrack.Events.Stack[i].tableName
		local eventName = Soundtrack.Events.Stack[i].eventName
		local label = _G["SoundtrackControlFrameStack" .. i]
		if not eventName then
			label:SetText(i .. ") None")
		else
			local playOnceText
			local event = Soundtrack.GetEvent(tableName, eventName)
			if event.continuous then
				playOnceText = "Loop"
			else
				playOnceText = "Once"
			end
			local eventText = GetPathFileName(eventName)
			label:SetText(i .. ") " .. eventText .. " (" .. playOnceText .. ")")
		end
	end
end

function SoundtrackUI.RefreshEventStack()
	local controlFrame = _G["SoundtrackControlFrame"]
	if controlFrame then
		if SoundtrackAddon.db.profile.settings.ShowPlaybackControls then
			controlFrame:Show()

			if SoundtrackAddon.db.profile.settings.ShowEventStack then
				SoundtrackControlFrameStackTitle:Show()
				SoundtrackControlFrameStack1:Show()
				SoundtrackControlFrameStack2:Show()
				SoundtrackControlFrameStack3:Show()
				SoundtrackControlFrameStack4:Show()
				SoundtrackControlFrameStack5:Show()
				SoundtrackControlFrameStack6:Show()
				SoundtrackControlFrameStack7:Show()
				SoundtrackControlFrameStack8:Show()
				SoundtrackControlFrameStack9:Show()
				SoundtrackControlFrameStack10:Show()
				SoundtrackControlFrameStack11:Show()
				SoundtrackControlFrameStack12:Show()
				SoundtrackControlFrameStack13:Show()
				SoundtrackControlFrameStack14:Show()
				SoundtrackControlFrameStack15:Show()
				SoundtrackControlFrameStack16:Show()
			else
				SoundtrackControlFrameStackTitle:Hide()
				SoundtrackControlFrameStack1:Hide()
				SoundtrackControlFrameStack2:Hide()
				SoundtrackControlFrameStack3:Hide()
				SoundtrackControlFrameStack4:Hide()
				SoundtrackControlFrameStack5:Hide()
				SoundtrackControlFrameStack6:Hide()
				SoundtrackControlFrameStack7:Hide()
				SoundtrackControlFrameStack8:Hide()
				SoundtrackControlFrameStack9:Hide()
				SoundtrackControlFrameStack10:Hide()
				SoundtrackControlFrameStack11:Hide()
				SoundtrackControlFrameStack12:Hide()
				SoundtrackControlFrameStack13:Hide()
				SoundtrackControlFrameStack14:Hide()
				SoundtrackControlFrameStack15:Hide()
				SoundtrackControlFrameStack16:Hide()
			end
		else
			controlFrame:Hide()
		end
	end
end
