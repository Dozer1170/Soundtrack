#!/usr/bin/env python3
"""
package.py — build the Soundtrack addon zip and optionally install it.

Usage:
    python scripts/package.py [options]

Options:
    --install               Extract the zip into the WoW AddOns directory.
    --flavor FLAVOR         WoW flavor: classic (default), retail, classic-era.
    --wow-path PATH         Path to the WoW root directory.
                            Auto-detected from the platform when omitted:
                              macOS   → /Applications/World of Warcraft
                              Windows → C:\\World of Warcraft
                              Linux   → /mnt/c/World of Warcraft
    --skip-tests            Skip running the unit test suite.
    --skip-localization     Skip the localization consistency check.
"""

import argparse
import re
import shutil
import subprocess
import sys
import zipfile
from pathlib import Path

# ---------------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------------

ROOT = Path(__file__).parent.parent
SRC = ROOT / "src"
SOUNDTRACK_SRC = SRC / "Soundtrack"
TOC_FILE = SOUNDTRACK_SRC / "Soundtrack-Classic.toc"
LOCALIZATION_DIR = SOUNDTRACK_SRC / "Core" / "Localization"
REFERENCE_LOCALE = LOCALIZATION_DIR / "Localization.en.lua"
TEST_SCRIPT      = ROOT / "scripts" / "test.py"

FLAVOR_FOLDERS = {
    "retail":      "_retail_",
    "classic":     "_classic_",
    "classic-era": "_classic_era_",
}

DEFAULT_WOW_PATH = {
    "darwin": "/Applications/World of Warcraft",
    "win32":  r"C:\World of Warcraft",
    "linux":  "/mnt/c/World of Warcraft",
}

# Patterns matched against the relative path inside the zip (forward slashes).
EXCLUDE_PATTERNS = [
    re.compile(r"\.iml$"),
    re.compile(r"\.hexdumptmp"),
    re.compile(r"MyTracks\.lua$"),
    re.compile(r"\.pyc$"),
    re.compile(r"LegacyLibraryGeneration/(META-INF|src)/"),
    re.compile(r"\.DS_Store$"),
    re.compile(r"(^|/)\.git(/|$)"),
    re.compile(r"\.gitignore$"),
    re.compile(r"\.gitattributes$"),
]

# ---------------------------------------------------------------------------
# Test runner
# ---------------------------------------------------------------------------

def run_tests() -> bool:
    """Run scripts/test.py. Returns True if all tests pass."""
    result = subprocess.run([sys.executable, str(TEST_SCRIPT)], cwd=ROOT)
    return result.returncode == 0


# ---------------------------------------------------------------------------
# Localization check (mirrors scripts/checkLocalization)
# ---------------------------------------------------------------------------

KEY_PATTERN = re.compile(r"^\t([A-Z_][A-Z0-9_]+)\s*=")


def _extract_keys(path: Path) -> set:
    keys: set = set()
    with path.open(encoding="utf-8", errors="replace") as fh:
        for line in fh:
            m = KEY_PATTERN.match(line)
            if m:
                keys.add(m.group(1))
    return keys


def check_localization() -> bool:
    """Return True if all locale files match the reference. Prints differences."""
    if not REFERENCE_LOCALE.exists():
        print(f"ERROR: Reference locale not found: {REFERENCE_LOCALE}", file=sys.stderr)
        return False

    reference_keys = _extract_keys(REFERENCE_LOCALE)
    print(f"Reference ({REFERENCE_LOCALE.name}): {len(reference_keys)} keys\n")

    other_files = sorted(
        p for p in LOCALIZATION_DIR.glob("*.lua")
        if p != REFERENCE_LOCALE and p.name != "SoundtrackLocalization.lua"
    )

    ok = True
    for locale_file in other_files:
        locale_keys = _extract_keys(locale_file)
        missing = reference_keys - locale_keys
        extra   = locale_keys - reference_keys

        if not missing and not extra:
            print(f"  OK  {locale_file.name} ({len(locale_keys)} keys)")
        else:
            ok = False
            print(f"  FAIL  {locale_file.name} ({len(locale_keys)} keys)")
            for k in sorted(missing):
                print(f"          missing: {k}")
            for k in sorted(extra):
                print(f"          extra:   {k}")

    return ok


# ---------------------------------------------------------------------------
# Version
# ---------------------------------------------------------------------------

def read_version() -> str:
    if not TOC_FILE.exists():
        sys.exit(f"ERROR: TOC file not found: {TOC_FILE}")
    for line in TOC_FILE.read_text(encoding="utf-8").splitlines():
        if line.startswith("## Version:"):
            return line.split(":", 1)[1].strip()
    sys.exit("ERROR: Version not found in TOC file.")


# ---------------------------------------------------------------------------
# Packaging
# ---------------------------------------------------------------------------

def _should_exclude(rel: str) -> bool:
    return any(p.search(rel) for p in EXCLUDE_PATTERNS)


def build_zip(out_path: Path) -> None:
    out_path.unlink(missing_ok=True)
    count = 0
    with zipfile.ZipFile(out_path, "w", compression=zipfile.ZIP_DEFLATED) as zf:
        for file in sorted(SOUNDTRACK_SRC.rglob("*")):
            if not file.is_file():
                continue
            rel = "Soundtrack/" + file.relative_to(SOUNDTRACK_SRC).as_posix()
            if _should_exclude(rel):
                continue
            zf.write(file, rel)
            count += 1
    print(f"Packaged {count} files → {out_path.name}")


# ---------------------------------------------------------------------------
# Install
# ---------------------------------------------------------------------------

def install(zip_path: Path, game_folder: str, wow_root: Path) -> None:
    addon_dir = wow_root / game_folder / "Interface" / "Addons"
    if not addon_dir.exists():
        print(f"Creating addon directory: {addon_dir}")
        addon_dir.mkdir(parents=True)

    # Remove stale installations
    for name in ("Soundtrack", "BlizzardInterfaceCode"):
        target = addon_dir / name
        if target.exists():
            print(f"Removing existing {name}...")
            shutil.rmtree(target)

    # Extract
    print(f"Extracting {zip_path.name} → {addon_dir}")
    with zipfile.ZipFile(zip_path) as zf:
        zf.extractall(addon_dir)

    print("Installed successfully.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Package (and optionally install) the Soundtrack addon.",
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog=__doc__,
    )
    parser.add_argument("--install", action="store_true",
                        help="Install the zip into the WoW AddOns directory after packaging.")
    parser.add_argument("--flavor", choices=list(FLAVOR_FOLDERS), default="classic",
                        help="WoW flavor to install into (default: classic).")
    parser.add_argument("--wow-path", default=None,
                        help="Path to the WoW root directory (auto-detected if omitted).")
    parser.add_argument("--skip-tests", action="store_true",
                        help="Skip running the unit test suite.")
    parser.add_argument("--skip-localization", action="store_true",
                        help="Skip the localization consistency check.")
    args = parser.parse_args()

    # --- Unit tests ---
    if not args.skip_tests:
        print("Running unit tests...\n")
        if not run_tests():
            sys.exit("\nPackaging aborted: unit tests failed.")
        print()

    # --- Localization check ---
    if not args.skip_localization:
        print("Checking localization files...")
        ok = check_localization()
        print()
        if not ok:
            sys.exit("Packaging aborted: fix localization mismatches first.")

    # --- Version & output path ---
    version = read_version()
    zip_path = ROOT / f"Soundtrack.{version}.zip"

    # --- Package ---
    print(f"Packaging Soundtrack {version}...")
    build_zip(zip_path)

    # --- Install ---
    if args.install:
        wow_root_str = args.wow_path or DEFAULT_WOW_PATH.get(sys.platform, DEFAULT_WOW_PATH["linux"])
        wow_root = Path(wow_root_str)
        if not wow_root.exists():
            sys.exit(
                f"ERROR: WoW root path not found: {wow_root}\n"
                "Pass --wow-path to specify a custom path."
            )
        game_folder = FLAVOR_FOLDERS[args.flavor]
        print(f"\nInstalling into {wow_root / game_folder}...")
        install(zip_path, game_folder, wow_root)


if __name__ == "__main__":
    main()
