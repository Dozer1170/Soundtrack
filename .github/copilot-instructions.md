# Copilot Instructions for Soundtrack

## Test-Driven Workflow

When making code changes to the Soundtrack addon, always follow this workflow:

1. **Run Tests First**: Execute the test suite using `lua TestRunner.lua` from the project root
   - All 256 tests must pass before proceeding
   - If tests fail, fix the issues before continuing

2. **Package and Install**: After successful test completion, package and install the addon when possible
   - On Windows, run `.\scripts\powershell\packageAndInstallRetail.ps1` from the project root
   - On macOS, packaging is optional—only run `./scripts/packageAndInstallRetailMac` if your WoW installation is available, otherwise skip without blocking the workflow
   - These scripts create the zip file and install it to the WoW AddOns directory

## Project Structure

- **Production Code**: `src/Soundtrack/` contains the addon implementation
- **Tests**: `src/Tests/` contains unit test files
- **Scripts**: `scripts/powershell/` contains packaging and installation scripts

## Testing Notes

- The test framework is a custom unit test implementation
- Test files follow the pattern `*Tests.lua`
- All tests run via `TestRunner.lua` in the project root
- Tests mock WoW API functions as needed

## Naming Conventions

- Functions use PascalCase (e.g., `AnalyzeBattleSituation`)
- Events use SCREAMING_SNAKE_CASE (e.g., `SOUNDTRACK_BATTLE`)
- Files use PascalCase (e.g., `BattleEvents.lua`)

## Critical Systems

- **Battle System**: `src/Soundtrack/Core/Battle/BattleEvents.lua` handles boss detection and music escalation
- **Event System**: Events are organized hierarchically with priority-based selection
- **Classification Levels**: 1-7 (minus, normal, rare, elite, rareelite, worldboss, boss)

## After Making Changes

Always conclude work sessions by running the test suite. Package/install afterward when the platform scripts and game installation are available.
