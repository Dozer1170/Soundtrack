#!/usr/bin/env python3
"""
package.py — build the Soundtrack addon zip and optionally install it.

Usage:
    python scripts/package.py [options]

Options:
    --install               Extract the zip into the WoW AddOns directory.
    --flavor FLAVOR         WoW flavor: classic (default), retail, classic-era, anniversary.
    --wow-path PATH         Path to the WoW root directory.
                            Auto-detected from the platform when omitted:
                              macOS   → /Applications/World of Warcraft
                              Windows → C:\\World of Warcraft
                              Linux   → /mnt/c/World of Warcraft
"""

import argparse
import re
import shutil
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

FLAVOR_FOLDERS = {
    "retail":      "_retail_",
    "classic":     "_classic_",
    "classic-era": "_classic_era_",
    "anniversary": "_classic_era_anniversary_",
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
    args = parser.parse_args()

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
