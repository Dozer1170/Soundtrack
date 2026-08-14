# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Soundtrack is a World of Warcraft addon (Lua 5.1, Ace3 framework) that lets players assign custom MP3 music/SFX to almost any in-game event (death, mounting, leveling, stealth, combat types, zone changes, pet battles, etc.) and doubles as a standalone media player with playlists.

- Two TOC targets built from the same `src/Soundtrack/` tree: `Soundtrack-Mainline.toc` (Retail, interface 120100/...) and `Soundtrack-Classic.toc` (interface 11505). Files differ per-flavor only via `Core/Retail.lua` vs `Core/Classic.lua` (sets global `IsRetail`) and `TabTemplateRetail.xml` vs `TabTemplateClassic.xml`.
- `src/BlizzardInterfaceCode` is a submodule of Blizzard's own addon source, vendored for reference/hooking. It can lag behind the live client — a brand-new API missing from it doesn't mean it doesn't exist in-game, only that the submodule pin is stale (`git submodule update --init` to refresh, or check the generated API docs under `Blizzard_APIDocumentationGenerated/` there for namespaces like `C_RestrictedActions`/`C_Secrets`).

## Commands

```bash
# Run the full Lua unit test suite + coverage (requires `lua` and `luarocks` on PATH)
python3 scripts/test.py

# Coverage report only (delegated to by test.py; reads luacov.stats.out per .luacov)
python3 scripts/coverage.py

# Validate localization completeness (all locales have the same keys as Localization.en.lua)
python3 scripts/checkLocalization.py

# Regenerate default track data
python3 scripts/generateDefaultTracks.py

# Build the distributable zip
python3 scripts/package.py

# Build, then install into a local WoW install (auto-detects WoW root per-OS;
# Linux/WSL default is /mnt/c/World of Warcraft — override with --wow-path)
python3 scripts/package.py --install --flavor retail   # or --flavor classic / classic-era
python3 scripts/package.py --skip-tests --skip-localization --install --flavor retail  # fast local iteration

# Publish to CurseForge (needs CF_API_TOKEN or --cf-token)
python3 scripts/package.py --publish --release-type release --changelog "..."
```

There is no `npm test`-style single-test filter — `src/Tests/TestRunner.lua` is a hand-rolled harness (no Busted/luaunit) that loads a fixed list of test files (see the `testFiles` table near the bottom of that file) and runs every function beginning with an uppercase letter inside each `Tests(...)` block. To run just one suite, temporarily trim that `testFiles` list, or add `os.exit()` after the suite of interest.

`package.py --install` fully deletes and re-extracts the `Soundtrack` (and `BlizzardInterfaceCode`) folder under the target `Interface/Addons`, so it's safe/idempotent but will wipe anything hand-edited directly in the installed copy.

## Test Harness Architecture

`src/Tests/TestRunner.lua` boots a **fake WoW client** entirely in pure Lua before loading any addon source:
- `SetWoWGlobals()` mocks all WoW frame/API globals it touches (`CreateFrame`, `C_UnitAuras`, `C_Map`, `UnitAffectingCombat`, etc.) — a not-yet-mocked global used by new code will error at load time, so extend this block when adding calls to a new WoW API.
- `SetupSoundtrack()` then loads real source files directly off disk in dependency order (Constants → Globals → Localization → Ace mocks → `Soundtrack.lua` → feature modules → UI) via `LoadSourceFile`, executing each as a real chunk against the mocked globals — there is no compiled build step, tests run the actual addon Lua.
- `ResetState()` (which does all of the above) reruns before **every single test function**, so tests are isolated but state cannot leak between them by design — don't rely on ordering.
- Custom assertions: `AreEqual`, `IsTrue`, `IsFalse`, `Exists`, and `Replace(target, name, replacement)` for monkey-patching a global/table field for one test.
- `SOUNDTRACK_COVERAGE=1` (set automatically by `scripts/test.py`) turns on `luacov` instrumentation.

## Architecture: the event stack

Everything the addon plays funnels through one priority stack, `Soundtrack.Events.Stack` (`Core/Events.lua`), sized `MaxStackLevel = 16`. Each level corresponds to a fixed category ordered lowest→highest priority (`Core/Constants.lua`, `ST_*_LVL`): Continent(1) → Zone(2) → Subzone(3) → Minimap(4) → Mount(5) → Aura/shapeshift(6) → Status(7) → NPC(8) → One-time(9) → Battle(10) → Buff(11) → Boss(12) → Death(13) → SFX(14) → Playlist(15) → Preview(16).

- Feature modules (`Core/Battle/`, `Core/Dance/`, `Core/MiscEvents/*`, `Core/PetBattle/`, `Core/Zones/`, `Core/Auras/`) each own a "dummy frame" (`*DummyFrame.xml`, loaded in the TOC) that registers for the relevant WoW events and calls into that module's `OnEvent`/`OnUpdate` handlers.
- Those handlers call `Soundtrack.Events.PlayEvent(tableName, eventName, stackLevel, forceRestart)` (or the `Soundtrack.Misc.PlayEvent`/`StopEvent` wrappers for the Misc table) to write into `Stack[stackLevel]`, then `OnStackChanged` picks the **highest occupied stack level that currently has assigned tracks** and plays it via `Soundtrack.Library.PlayTrack`, stopping/restarting only when the winning (table, event) pair actually changed — so lower-priority music automatically resumes when a higher-priority one ends.
- `ST_MISC` (`Core/MiscEvents/MiscEvents.lua`) is itself a mini-framework of three registration styles used by class/status modules (`ClassEvents.lua`, `DruidEvents.lua`, `LootEvents.lua`, `MountEvents.lua`, `NpcEvents.lua`, `PlayerStatusEvents.lua`, `StealthEvents.lua`): `RegisterEventScript` (fires on a raw WoW event), `RegisterUpdateScript` (polled every `Soundtrack.Misc.OnUpdate` tick), and `RegisterBuffEvent` (spellId-keyed — driven by `Soundtrack.Auras.IsAuraActive`, checked from `Soundtrack.Misc.OnPlayerAurasUpdated`). All registered Misc events are also just entries in the `ST_MISC` `Soundtrack.Events` table with a `priority` (stack level), so they compete on the same stack as everything else.
- User-configured event→track assignments live in `SoundtrackAddon.db.profile.events[tableName][eventName].tracks` (AceDB-managed, persisted to `WTF/Account/<User>/SavedVariables/Soundtrack.lua`). `Soundtrack.Events.GetTable`/`Add`/`Remove`/`DeleteEvent` are the CRUD surface over that structure; `Soundtrack.AddEvent` (`Core/Soundtrack.lua`) is what feature modules call at startup to register an event's *existence* (priority/continuous/soundEffect flags) independent of whether the user has assigned tracks yet.

## Aura scanning and WoW's Secret Values

`Core/Auras/Auras.lua` polls `C_UnitAuras.GetBuffDataByIndex`/`GetDebuffDataByIndex` on `UNIT_AURA` to populate `Soundtrack.Auras.ActiveAuras`, which many `RegisterBuffEvent` triggers and a couple of hardcoded checks (Druid Travel Form/Prowl, Rogue Stealth) key off via `IsAuraActive(spellId)`. This is retail-only code gated by the `IsRetail` global.

Since WoW 12.x, some auras are marked **secret** (anti-cheese/spoiler protection) while the player is in combat, an encounter, a challenge-mode/M+ dungeon, or a PvP match. Reading a secret aura's fields from addon code throws immediately — this **cannot be suppressed by `pcall`** (Blizzard logs the taint violation independent of whether the call was protected, by design, so addons can't silently probe secret data). `UpdateActiveAuras` therefore checks `C_RestrictedActions.IsAddOnRestrictionActive(Enum.AddOnRestrictionType.*)` for `Combat`/`Encounter`/`ChallengeMode`/`PvPMatch` up front and skips the scan (leaving `ActiveAuras` at its last-known state) while any is active, rather than trying to catch the error after the fact.
