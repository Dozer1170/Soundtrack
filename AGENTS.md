# Soundtrack – Repository Guide for Agents

## Project Overview

**Soundtrack** is a [World of Warcraft](https://www.worldofwarcraft.com/) addon that lets players assign custom MP3 music and sound effects to nearly any in-game event (death, mounting, leveling, stealth, combat types, zone changes, pet battles, etc.). It also functions as a standalone media player with playlist support.

- **Language:** Lua 5.1 (WoW client)
- **Packaging format:** World of Warcraft addon (.toc / Interface/ folder structure)
- **External deps:** Ace3 libraries bundled vendored in `src/Soundtrack/Libs/`
- **Submodule:** `src/BlizzardInterfaceCode` – Blizzard's internal addon code (for reference/hooking)

## Directory Structure

```
.
├── src/
│   ├── Soundtrack/                 # Main addon source
│   │   ├── Core/                   # Addon logic
│   │   │   ├── UI/                 # UI frames, XML layouts, Lua handlers
│   │   │   │   └── Tabs/           # About, Options, Profiles tabs
│   │   │   ├── Zones/              # Zone-based music events
│   │   │   └── Utils/              # Chat, cleanup, sorting, string/table helpers
│   │   ├── Images/                 # .tga textures for UI buttons
│   │   └── Libs/                   # Vendored dependencies (Ace3, LibDataBroker, etc.)
│   ├── Tests/                      # Unit tests (Lua-based test framework)
│   │   ├── UI/                     # UI component tests
│   │   ├── Utils/                  # Utility function tests
│   │   └── [feature]/              # Feature-specific test modules
│   └── BlizzardInterfaceCode/      # Submodule – Blizzard addon source (read-only reference)
├── scripts/                        # Build / utility Python scripts
├── .gitignore
├── .gitmodules                     # Submodule definitions
├── FutureFeatures.md               # Planned features roadmap
└── README.md                       # User-facing documentation
```

## Key Files & Conventions

| File / Pattern | Purpose |
|---|---|
| `src/Soundtrack/` | Root of the addon. This is what gets copied into WoW's `Interface/Addons/` folder. |
| `src/Soundtrack/Libs/` | Vendored libraries (AceAddon-3.0, AceDB-3.0, AceEvent-3.0, CallbackHandler, LibDataBroker, LibDBIcon, LibStub). Do not modify these files; update via submodule or vendor script instead. |
| `src/Soundtrack/Core/` | Core addon logic: event handling, playback engine, UI management, zone events. |
| `src/Tests/` | Unit tests organized by feature area. Each subfolder mirrors a production module. |

### Lua Conventions

- Files use standard Lua 5.1 syntax (no coroutines, no modern LuaJIT extensions).
- The addon uses Ace3's OOP-style addon framework (`AceAddon:NewAddon`).
- UI is split between `.xml` frame definitions and `.lua` handler files.
- Settings are persisted via WoW's SavedVariables mechanism (`Soundtrack.lua` in `WTF/Account/<User>/SavedVariables/`).

## Development Workflow

### Setup

1. Clone with submodules:
   ```bash
   git clone --recurse-submodules git@github.com:Dozer1170/Soundtrack.git
   ```
2. If you already cloned without `--recurse`, run:
   ```bash
   git submodule update --init
   ```

### Running Tests

Tests are Lua-based and run via a custom test runner inside the addon's test framework. The project also includes Python scripts for coverage and CI-style testing:

```bash
python scripts/test.py          # Run the full test suite
python scripts/coverage.py      # Generate code coverage report
python scripts/generateDefaultTracks.py  # Generate default track data
```

### Building / Packaging

```bash
python scripts/package.py       # Package the addon for distribution
```

The `.toc` file and addon structure are generated/maintained by the packaging script. MP3 files and user-generated `SoundtrackMusic/` content are explicitly excluded from version control (see `.gitignore`).

### Code Style

- **Indentation:** 2 spaces (Lua standard).
- **Line length:** No hard limit, but keep lines readable (~120 chars max).
- **Naming:** `CamelCase` for modules/classes, `lowerCamelCase` for functions/variables, `UPPER_CASE` for constants.
- **Comments:** Inline comments explain *why*, not *what*. Docstrings on public API functions.

## Scripts Reference

| Script | Purpose |
|---|---|
| `scripts/checkLocalization.py` | Validate localization strings and completeness. |
| `scripts/coverage.py` | Generate `.luacov` coverage reports for the test suite. |
| `scripts/generateDefaultTracks.py` | Create default track assignments from bundled data. |
| `scripts/package.py` | Assemble the addon package (TOC generation, file filtering). |
| `scripts/test.py` | Run the Lua unit tests and report results. |

## Dependencies

### Vendored Libraries (in `src/Soundtrack/Libs/`)

- **AceAddon-3.0** – Addon framework / lifecycle management
- **AceDB-3.0** – Persistent data storage abstraction
- **AceEvent-3.0** – Event registration and dispatch
- **CallbackHandler-1.0** – Callback system used by Ace libraries
- **LibDataBroker-1.1** – Data broker protocol (for minimap / LDB display)
- **LibDBIcon-1.0** – Minimap icon wrapper around LibDataBroker
- **LibStub** – Library versioning stub

These are third-party libraries and should not be edited directly. If updates are needed, vendor the latest versions from their respective sources.

### Submodule

- `src/BlizzardInterfaceCode` – Blizzard's internal addon source code, used for reference to hook into or override Blizzard UI behavior. Do not commit changes here; update via submodule pointer.

## Testing Strategy

Tests mirror the production structure under `src/Tests/`:

```
src/Tests/
├── TestRunner.lua              # Entry point – runs all registered test suites
├── SoundtrackTests.lua         # Core addon integration tests
├── BattleSystemTests.lua       # Combat/battle event tests
├── PetBattle/                  # Pet battle specific tests
├── Zones/                      # Zone music tests
├── UI/                         # UI frame and interaction tests
└── Utils/                      # Utility function unit tests
```

Each test module registers itself with the framework and asserts behavior using a simple assertion pattern. Tests are designed to run in isolation where possible.

## Known Constraints

1. **Sound channel limits:** WoW caps concurrent sound playback (~20 channels). Heavy AOE or many SFX will cut off custom music until channels free up.
2. **File format:** Only `.mp3` files are supported for playback (WoW's `PlayMusic()` API limitation). Non-ASCII filenames may cause issues.
3. **SavedVariables:** Settings persist in `Soundtrack.lua` under `WTF/Account/<User>/SavedVariables/`. Transferring to another machine requires copying this file plus the `SoundtrackMusic/` folder.
4. **Dance detection:** WoW does not expose a "stopped dancing" event, so dance music only stops at track end.

## Future Directions

See [`FutureFeatures.md`](FutureFeatures.md) for planned features including time-of-day/weather-based music, quest events, per-event volume control, and more.
