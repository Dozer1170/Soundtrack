Soundtrack.ChangelogDialog = {}

local CURRENT_VERSION = C_AddOns.GetAddOnMetadata("Soundtrack", "Version")

-- The release the notes below were written for. scripts/package.py refuses to
-- publish when this is not the version being uploaded, so a version bump cannot
-- ship the previous release's notes. Bump it in the same edit as the notes.
local CHANGELOG_VERSION = "7.0.1"

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

-- Headed with the version the notes are for rather than the version installed:
-- the two only differ on a working copy mid-bump, and there the notes' own
-- version is the honest label.
local CHANGELOG_TEXT = "What's new in " .. CHANGELOG_VERSION .. ":\n\n" .. CHANGELOG_BODY

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
