Soundtrack.ChangelogDialog = {}

local CURRENT_VERSION = C_AddOns.GetAddOnMetadata("Soundtrack", "Version")

-- The release the notes below were written for. scripts/package.py refuses to
-- publish when this is not the version being uploaded, so a version bump cannot
-- ship the previous release's notes. Bump it in the same edit as the notes.
local CHANGELOG_VERSION = "7.1.1"

-- The single source of truth for this release's notes: scripts/package.py reads
-- this block straight out of this file and uploads it as the CurseForge
-- changelog, so the popup and the CurseForge release notes cannot drift apart.
-- Keep the lines hard-wrapped to about 60 characters, which is what fits the
-- popup frame.
local CHANGELOG_BODY = [[
- Marked as compatible with retail patch 12.1.5.
- The About tab now shows the version you have installed
  instead of always saying 7.0.0.
- Soundtrack now runs on WoW Forever. Copy your SoundtrackMusic
  folder into the Forever AddOns folder to bring your music
  library along.
- Loot sounds no longer error on Forever, where the game no
  longer offers the old way of looking up an item's quality.
- The minimap button on Forever now sits centred in its ring
  like it does on retail, instead of being offset to one side.
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
