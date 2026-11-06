-- Minimap Button Handling

local function Debug(msg)
	Soundtrack.Chat.Debug(msg)
end

local icon = LibStub("LibDBIcon-1.0")

local MINIMAP_BORDER_TEXTURE = 136430 -- Interface\Minimap\MiniMap-TrackingBorder
local MINIMAP_BACKGROUND_TEXTURE = 136467 -- Interface\Minimap\UI-Minimap-Background

-- LibDBIcon picks its button layout with WOW_PROJECT_ID == WOW_PROJECT_MAINLINE
-- and otherwise falls back to the Classic one. WoW Forever runs the Mainline
-- UI (it loads our _Mainline TOC, so IsRetail is set) but reports its own
-- project ID, so it gets the Classic layout: a 53px ring with the icon pinned
-- top-left, which looks offset on the modern minimap. Every LibDBIcon version
-- does this, and LibStub hands us whichever copy has the highest minor, so the
-- fix has to be applied to our button rather than to our embedded library.
function SoundtrackMinimap_NeedsMainlineLayout()
	return IsRetail == true and WOW_PROJECT_MAINLINE ~= nil and WOW_PROJECT_ID ~= WOW_PROJECT_MAINLINE
end

-- Re-applies LibDBIcon's Mainline sizes and anchors to an already-built button.
function SoundtrackMinimap_ApplyMainlineLayout(btn)
	for _, region in next, { btn:GetRegions() } do
		local texture = region.GetTexture and region:GetTexture()
		if texture == MINIMAP_BORDER_TEXTURE then
			region:SetSize(50, 50)
			region:ClearAllPoints()
			region:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
		elseif texture == MINIMAP_BACKGROUND_TEXTURE then
			region:SetSize(24, 24)
			region:ClearAllPoints()
			region:SetPoint("CENTER", btn, "CENTER", 0, 0)
		end
	end
	if btn.icon then
		btn.icon:SetSize(18, 18)
		btn.icon:ClearAllPoints()
		btn.icon:SetPoint("CENTER", btn, "CENTER", 0, 0)
	end
end

function SoundtrackMinimap_Initialize()
	if icon:IsRegistered("SoundtrackAddon") then
		icon:Refresh("SoundtrackAddon", SoundtrackAddon.db.profile.minimap)
		return
	end

	local soundtrackMinimapLDB = LibStub("LibDataBroker-1.1"):NewDataObject("SoundtrackMinimap", {
		type = "data source",
		text = "Soundtrack",
		icon = "Interface\\Icons\\INV_Misc_Flute_01",
		OnClick = function(self, button)
			SoundtrackMinimap_IconFrame_OnClick(self, button)
		end,
		OnTooltipShow = function(tooltip)
			SoundtrackMinimap_OnTooltipShow(tooltip)
		end,
	})

	icon:Register("SoundtrackAddon", soundtrackMinimapLDB, SoundtrackAddon.db.profile.minimap)
	local btn = icon.objects and icon.objects["SoundtrackAddon"]
	if btn then
		if SoundtrackMinimap_NeedsMainlineLayout() then
			SoundtrackMinimap_ApplyMainlineLayout(btn)
		end
		-- Replace the default yellow tracking-border with a themed circle border
		for _, child in next, { btn:GetRegions() } do
			if child.GetTexture and child:GetTexture() == MINIMAP_BORDER_TEXTURE then
				SoundtrackTheme.StyleMinimapBorder(child)
				break
			end
		end
	end
end

function SoundtrackMinimap_IconFrame_OnClick(_, _)
	Debug("Minimap button OnClick")
	SoundtrackUI.Toggle()
end

function SoundtrackMinimap_OnTooltipShow(tooltip)
	tooltip:AddLine("Soundtrack")
	tooltip:AddLine(SOUNDTRACK_MINIMAP)
	tooltip:AddLine("|cffeda55fClick|r to toggle Soundtrack")
end

function SoundtrackMinimap_ToggleMinimap()
	SoundtrackAddon.db.profile.minimap.hide = not SoundtrackAddon.db.profile.minimap.hide
	if SoundtrackAddon.db.profile.minimap.hide then
		Soundtrack.Chat.TraceFrame(SOUNDTRACK_MINIMAP_BUTTON_HIDDEN)
		icon:Hide("SoundtrackAddon")
	else
		icon:Show("SoundtrackAddon")
	end
end
