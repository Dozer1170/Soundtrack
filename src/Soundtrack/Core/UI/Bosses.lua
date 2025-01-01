local function AddNamedBoss(targetName)
	Soundtrack.AddEvent("Boss", targetName, ST_BOSS_LVL, true)
	local lowhealthbossname = targetName .. " " .. SOUNDTRACK_LOW_HEALTH
	Soundtrack.AddEvent("Boss", lowhealthbossname, ST_BOSS_LVL, true)
	SoundtrackFrame.SelectedEvent = targetName
	SoundtrackFrame.UpdateEventsUI()
end

local function AddNamedWorldBoss(targetName)
	Soundtrack.AddEvent("Boss", targetName, ST_BOSS_LVL, true)
	local bossTable = Soundtrack.Events.GetTable(ST_BOSS)
	local bossEvent = bossTable[targetName]
	bossEvent.worldboss = true
	local lowhealthbossname = targetName .. " " .. SOUNDTRACK_LOW_HEALTH
	Soundtrack.AddEvent("Boss", lowhealthbossname, ST_BOSS_LVL, true)
	local bossEvent = bossTable[lowhealthbossname]
	bossEvent.worldboss = true
	SoundtrackFrame.SelectedEvent = targetName
	SoundtrackFrame.UpdateEventsUI()
end

function SoundtrackFrame.OnAddBossTargetButtonClick()
	local targetName = UnitName("target")
	if targetName then
		AddNamedBoss(targetName)
	else
		StaticPopupDialogs["SOUNDTRACK_ADD_BOSS"] = {
			preferredIndex = 3,
			text = SOUNDTRACK_ADD_BOSS_TIP,
			button1 = ACCEPT,
			button2 = CANCEL,
			hasEditBox = 1,
			maxLetters = 100,
			OnAccept = function(self)
				local editBox = _G[self:GetName() .. "EditBox"]
				AddNamedBoss(editBox:GetText())
			end,
			OnShow = function(self)
				_G[self:GetName() .. "EditBox"]:SetFocus()
			end,
			OnHide = function(self)
				if ChatFrame1EditBox:IsVisible() then
					ChatFrame1EditBox:SetFocus()
				end
				_G[self:GetName() .. "EditBox"]:SetText("")
			end,
			EditBoxOnEnterPressed = function(self)
				local editBox = _G[self:GetName() .. "EditBox"]
				AddNamedBoss(editBox:GetText())
				self:Hide()
			end,
			EditBoxOnEscapePressed = function(self)
				self:Hide()
			end,
			timeout = 0,
			exclusive = 1,
			whileDead = 1,
			hideOnEscape = 1,
		}

		StaticPopup_Show("SOUNDTRACK_ADD_BOSS")
	end
end

function SoundtrackFrame.OnAddWorldBossTargetButtonClick()
	local targetName = UnitName("target")
	if targetName then
		AddNamedWorldBoss(targetName)
	else
		StaticPopupDialogs["SOUNDTRACK_ADD_WORLD_BOSS"] = {
			preferredIndex = 3,
			text = SOUNDTRACK_ADD_BOSS_TIP,
			button1 = ACCEPT,
			button2 = CANCEL,
			hasEditBox = 1,
			maxLetters = 100,
			OnAccept = function(self)
				local editBox = _G[self:GetName() .. "EditBox"]
				AddNamedWorldBoss(editBox:GetText())
			end,
			OnShow = function(self)
				_G[self:GetName() .. "EditBox"]:SetFocus()
			end,
			OnHide = function(self)
				if ChatFrame1EditBox:IsVisible() then
					ChatFrame1EditBox:SetFocus()
				end
				_G[self:GetName() .. "EditBox"]:SetText("")
			end,
			EditBoxOnEnterPressed = function(self)
				local editBox = _G[self:GetName() .. "EditBox"]
				AddNamedWorldBoss(editBox:GetText())
				self:Hide()
			end,
			EditBoxOnEscapePressed = function(self)
				self:Hide()
			end,
			timeout = 0,
			exclusive = 1,
			whileDead = 1,
			hideOnEscape = 0,
		}

		StaticPopup_Show("SOUNDTRACK_ADD_WORLD_BOSS")
	end
end
