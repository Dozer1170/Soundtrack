Soundtrack.ChangelogDialog = {}

local CURRENT_VERSION = C_AddOns.GetAddOnMetadata("Soundtrack", "Version")

local CHANGELOG_TEXT = [[What's new in ]] .. CURRENT_VERSION .. [[:

- New themed UI with customizable color themes (Gold, Cosmic Blue, Class Color, Forest, Crimson, Arcane). Change your theme in the Options tab.
- New Encounters tab replaces Boss Zones. Encounters are automatically added when you enter a boss fight, and you can assign custom music to each one. Use the new Collapse All / Expand All buttons to manage the list.
]]

function Soundtrack.ChangelogDialog.CheckAndShow()
    local lastSeen = SoundtrackAddon.db.global.LastSeenVersion or ""
    if lastSeen ~= CURRENT_VERSION then
        SoundtrackAddon.db.global.LastSeenVersion = CURRENT_VERSION
        Soundtrack.ChangelogDialog.Open()
    end
end

function Soundtrack.ChangelogDialog.Open()
    SoundtrackChangelogText:SetText(CHANGELOG_TEXT)
    SoundtrackChangelogFrame:Show()
    SoundtrackChangelogFrame:Raise()
end

function Soundtrack.ChangelogDialog.Close()
    SoundtrackChangelogFrame:Hide()
end
