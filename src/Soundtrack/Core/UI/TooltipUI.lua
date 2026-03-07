function Soundtrack.ShowTip(self, tipTitle, tipText, tipTextAuthor, tipTextAlbum, anchor, minWidth)
	if Soundtrack_Tooltip == nil then
		Soundtrack_Tooltip = CreateFrame("GameTooltip", "SoundtrackTooltip", UIParent, "GameTooltipTemplate")
	end
	Soundtrack_Tooltip:SetOwner(self or UIParent, anchor or "ANCHOR_TOPRIGHT")
	Soundtrack_Tooltip:ClearLines()
	if minWidth then
		Soundtrack_Tooltip:SetMinimumWidth(minWidth)
	end
	Soundtrack_Tooltip:AddLine(tipTitle, 1, 1, 1, true)

	if tipText ~= nil then
		Soundtrack_Tooltip:AddLine(tipText, nil, nil, nil, true)
	end
	if tipTextAuthor ~= nil then
		Soundtrack_Tooltip:AddLine(tipTextAuthor, 1, 0.9, 0, true)
	end
	if tipTextAlbum ~= nil then
		Soundtrack_Tooltip:AddLine(tipTextAlbum, 1, 0.5, 0, true)
	end
	Soundtrack_Tooltip:Show()
end

function Soundtrack.HideTip()
	if Soundtrack_Tooltip == nil then
		Soundtrack_Tooltip = CreateFrame("GameTooltip", "SoundtrackTooltip", UIParent, "GameTooltipTemplate")
	end
	Soundtrack_Tooltip:Hide()
end
