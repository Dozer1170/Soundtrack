Soundtrack.ChangelogDialog = {}

local CURRENT_VERSION = C_AddOns.GetAddOnMetadata("Soundtrack", "Version")

local CHANGELOG_TEXT = [[What's new in ]] .. CURRENT_VERSION .. [[:

- IMPORTANT: Midnight tracks were added to the default tracks, and the names of the existing default tracks were changed. You may get the dialog indicating that some tracks no longer exist if you had tracks mapped to the old default tracks names. Apologies for any inconvenience this may cause. You will need to purge old tracks and reassign them. This is a one-time inconvenience that will allow for better track organization in the future.
- Add tooltips to tracks if their name is truncated in the track list
- Fix to hopefully prevent Instances being added to the wrong parent zone
- Fix bug where music would fade to the wrong value
- Fix combat music not triggering correctly during fade out
- Add this changelog dialog you are currently reading
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
