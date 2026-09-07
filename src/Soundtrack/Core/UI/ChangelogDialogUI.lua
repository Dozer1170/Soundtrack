Soundtrack.ChangelogDialog = {}

local CURRENT_VERSION = C_AddOns.GetAddOnMetadata("Soundtrack", "Version")

-- The single source of truth for this release's notes: scripts/package.py reads
-- this block straight out of this file and uploads it as the CurseForge
-- changelog, so the popup and the CurseForge release notes cannot drift apart.
-- Keep the lines hard-wrapped to about 60 characters, which is what fits the
-- popup frame.
local CHANGELOG_BODY = [[
- Boss phase music! You can now assign a different track to
  each phase of a boss fight. Phases show up under the boss on
  the Encounters tab as "Stage 1", "Stage 2", and so on, once
  that phase has been reached in combat.

- This needs either Deadly Boss Mods or BigWigs installed. World
  of Warcraft never tells addons when a boss changes phase, so
  the phase has to come from a boss mod. If you run both, Deadly
  Boss Mods is used.

- Phases you leave empty fall back to the boss's own music, so
  nothing changes until you assign tracks to one.

- Added support for the latest version of World of Warcraft.
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
