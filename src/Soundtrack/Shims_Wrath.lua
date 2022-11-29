PanelTabButtonMixin = {};

function PanelTabButtonMixin:OnLoad()
    self:SetFrameLevel(self:GetFrameLevel() + 4);
    self:RegisterEvent("DISPLAY_SIZE_CHANGED");
end

function PanelTabButtonMixin:OnEvent(event, ...)
    if self:IsVisible() then
        PanelTemplates_TabResize(self, self:GetParent().tabPadding, nil, self:GetParent().minTabWidth, self:GetParent().maxTabWidth);
    end
end

function PanelTabButtonMixin:OnShow()
    PanelTemplates_TabResize(self, self:GetParent().tabPadding, nil, self:GetParent().minTabWidth, self:GetParent().maxTabWidth);
end

function PanelTabButtonMixin:OnEnter()
    if self.Text:IsTruncated() then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
        GameTooltip:SetText(self.Text:GetText());
    end
end

function PanelTabButtonMixin:OnLeave()
    GameTooltip_Hide();
end
