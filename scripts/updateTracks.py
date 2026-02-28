#!/usr/bin/env python3
"""
updateTracks.py — match paths from TrackPaths.txt and append IDs to DefaultTracks.lua.

TrackPaths.txt format (one entry per line):
    sound/music/some/path.mp3;12345

The script strips the "sound/music/" prefix and ".mp3" extension, normalises
each path to lowercase with no spaces, then searches DefaultTracks.lua for
matching Soundtrack.Library.AddDefaultTrack("...") calls and appends the ID
as ////12345.

Usage (from project root):
    python3 scripts/updateTracks.py [--tracks PATH] [--lua PATH]

Options:
    --tracks PATH   Path to TrackPaths.txt (default: scripts/TrackPaths.txt)
    --lua    PATH   Path to DefaultTracks.lua
                    (default: src/Soundtrack/DefaultTracks.lua)
"""

import argparse
import re
import shutil
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent

DEFAULT_TRACKS_TXT = ROOT / "scripts" / "TrackPaths.txt"
DEFAULT_TRACKS_LUA = ROOT / "src" / "Soundtrack" / "DefaultTracks.lua"

ADD_TRACK_RE = re.compile(r'Soundtrack\.Library\.AddDefaultTrack\("([^"]+)"')


# ---------------------------------------------------------------------------
# Normalisation — must match between the two sources
# ---------------------------------------------------------------------------

def normalise(path: str) -> str:
    """Strip common prefix/suffix and reduce to a lowercase, space-free key."""
    p = path
    p = re.sub(r'^sound/music/', '', p, flags=re.IGNORECASE)
    p = re.sub(r'\.mp3$', '', p, flags=re.IGNORECASE)
    p = re.sub(r'////.*$', '', p)        # strip any existing ////id suffix
    p = p.lower().replace(' ', '')
    return p


# ---------------------------------------------------------------------------
# Parse TrackPaths.txt
# ---------------------------------------------------------------------------

def load_track_map(txt_path: Path) -> dict[str, str]:
    track_map: dict[str, str] = {}
    with txt_path.open(encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.rstrip("\n")
            m = re.match(r'^(.+);(\d+)$', line)
            if not m:
                continue
            full_path = m.group(1).replace(' ', '')
            track_id  = m.group(2)
            key = normalise(full_path)
            if key not in track_map:
                track_map[key] = track_id
    return track_map


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(description=__doc__,
                                     formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("--tracks", default=str(DEFAULT_TRACKS_TXT),
                        help="Path to TrackPaths.txt")
    parser.add_argument("--lua", default=str(DEFAULT_TRACKS_LUA),
                        help="Path to DefaultTracks.lua")
    args = parser.parse_args()

    tracks_path = Path(args.tracks)
    lua_path    = Path(args.lua)

    if not tracks_path.exists():
        sys.exit(f"ERROR: TrackPaths.txt not found: {tracks_path}")
    if not lua_path.exists():
        sys.exit(f"ERROR: DefaultTracks.lua not found: {lua_path}")

    # --- Load lookup table ---
    print("Reading TrackPaths.txt...")
    track_map = load_track_map(tracks_path)
    print(f"Found {len(track_map)} track paths in lookup table")
    for key in list(track_map)[:5]:
        print(f"  Sample key: {key}")

    # --- Read DefaultTracks.lua ---
    print("\nReading DefaultTracks.lua...")
    content = lua_path.read_text(encoding="utf-8")
    all_matches = list(ADD_TRACK_RE.finditer(content))
    print(f"Found {len(all_matches)} track entries in DefaultTracks.lua")
    for m in all_matches[:5]:
        key = normalise(m.group(1))
        print(f"  Sample lua path: {m.group(1)} -> normalized: {key}")

    # --- Match and collect replacements ---
    replacements: list[tuple[str, str]] = []   # (old_quoted, new_quoted)
    matched = 0
    unmatched: list[str] = []

    for m in all_matches:
        old_path    = m.group(1)
        path_clean  = re.sub(r'////.*$', '', old_path)   # strip existing id
        key         = normalise(path_clean)

        if key in track_map:
            track_id = track_map[key]
            new_path = f"{path_clean}////{track_id}"
            if matched < 10:
                print(f"  Match: {old_path} -> {new_path}")
            replacements.append((f'"{old_path}"', f'"{new_path}"'))
            matched += 1
        else:
            unmatched.append(path_clean)

    print(f"\nMatched {matched} of {len(all_matches)} entries")

    if unmatched:
        print(f"\nUnmatched paths ({len(unmatched)} total):")
        for p in unmatched:
            print(f"  {p}")

    # --- Apply replacements ---
    if not replacements:
        print("\nNo matching paths found. Check the format of TrackPaths.txt and DefaultTracks.lua.")
        return

    print("\nApplying replacements to DefaultTracks.lua...")
    updated = content
    for old, new in replacements:
        updated = updated.replace(old, new)

    backup_path = lua_path.with_suffix(".lua.backup")
    shutil.copy2(lua_path, backup_path)
    print(f"Backup written to: {backup_path}")

    lua_path.write_text(updated, encoding="utf-8")
    print("DefaultTracks.lua updated successfully!")
    print("Done!")


if __name__ == "__main__":
    main()
