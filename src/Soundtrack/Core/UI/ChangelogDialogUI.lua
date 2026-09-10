Soundtrack.ChangelogDialog = {}

local CURRENT_VERSION = C_AddOns.GetAddOnMetadata("Soundtrack", "Version")

-- The single source of truth for this release's notes: scripts/package.py reads
-- this block straight out of this file and uploads it as the CurseForge
-- changelog, so the popup and the CurseForge release notes cannot drift apart.
-- Keep the lines hard-wrapped to about 60 characters, which is what fits the
-- popup frame.
local CHANGELOG_BODY = [[
- Fixed the error you got opening Soundtrack for the first time
  after updating ("attempt to index local 'event'"). When the
  addon retired an event your saved data still had, it removed
  the event but left it in the list the window draws from, so the
  window hit an entry with nothing behind it. The list is now
  rebuilt whenever an old event is cleared out, and a leftover
  entry is skipped instead of erroring.
]]

local CHANGELOG_TEXT = "What's new in " .. CURRENT_VERSION .. ":\n\n" .. CHANGELOG_BODY

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
