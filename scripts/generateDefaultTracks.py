#!/usr/bin/env python3
"""
generateDefaultTracks.py — generate DefaultTracks.lua from a wow.export music folder.

For each MP3 found under the export folder:
  - Reads the actual duration from the file using mutagen
  - Looks up the resource ID from TrackPaths.txt in the same folder
  - Optionally preserves artist/album from an existing DefaultTracks.lua
  - Writes a fresh Soundtrack_LoadDefaultTracks() function

New AddDefaultTrack call format (6th param is the numeric resource ID):
    Soundtrack.Library.AddDefaultTrack("folder\\name", <seconds>, "name", "artist", "expansion", <id>)

Usage (from project root):
    python3 scripts/generateDefaultTracks.py [--music PATH] [--lua PATH]

Options:
    --music PATH   Path to the wow.export music folder
                   (default: C:/Users/<user>/wow.export/sound/music)
    --lua   PATH   Path to the output DefaultTracks.lua
                   (default: src/Soundtrack/DefaultTracks.lua)
"""

import argparse
import os
import re
import sys
from pathlib import Path

try:
    from mutagen.mp3 import MP3
except ImportError:
    sys.exit("ERROR: mutagen is required. Install it with: pip install mutagen")

ROOT = Path(__file__).parent.parent

DEFAULT_MUSIC_DIR = Path.home() / "wow.export" / "sound" / "music"
DEFAULT_TRACKS_LUA = ROOT / "src" / "Soundtrack" / "DefaultTracks.lua"

EXISTING_TRACK_RE = re.compile(
    r'Soundtrack\.Library\.AddDefaultTrack\("([^"]+)",\s*\d+,\s*"([^"]*)",\s*"([^"]*)",\s*"([^"]*)"'
)


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def normalise_key(path: str) -> str:
    """Lowercase, no spaces, forward slashes, no leading sound/music/, no .mp3."""
    p = path.replace('\\', '/')
    p = re.sub(r'^sound/music/', '', p, flags=re.IGNORECASE)
    p = re.sub(r'\.mp3$', '', p, flags=re.IGNORECASE)
    return p.lower().replace(' ', '')


def infer_expansion(rel_path: str) -> str:
    """Extract a version number from the path and return e.g. 'WoW12.0'."""
    m = re.search(r'(\d+\.\d+(?:\.\d+)?)', rel_path)
    return f"WoW{m.group(1)}" if m else "None"


def load_track_ids(music_dir: Path) -> dict[str, int]:
    """Load TrackPaths.txt -> normalised_key: resource_id."""
    txt = music_dir / "TrackPaths.txt"
    if not txt.exists():
        print(f"WARNING: TrackPaths.txt not found at {txt}. Resource IDs will be 0.")
        return {}
    ids: dict[str, int] = {}
    with txt.open(encoding="utf-8", errors="replace") as fh:
        for line in fh:
            line = line.rstrip("\n")
            m = re.match(r'^(.+);(\d+)$', line)
            if not m:
                continue
            key = normalise_key(m.group(1))
            if key not in ids:
                ids[key] = int(m.group(2))
    return ids


def load_existing_metadata(lua_path: Path) -> dict[str, tuple[str, str, str]]:
    """
    Parse existing DefaultTracks.lua for artist/album/title metadata to preserve.
    Returns: normalised_key -> (title, artist, album)
    """
    if not lua_path.exists():
        return {}
    meta: dict[str, tuple[str, str, str]] = {}
    content = lua_path.read_text(encoding="utf-8")
    for m in EXISTING_TRACK_RE.finditer(content):
        raw_name = m.group(1)
        # Strip ////id suffix if present
        raw_name = re.sub(r'////.*$', '', raw_name)
        key = normalise_key(raw_name)
        meta[key] = (m.group(2), m.group(3), m.group(4))
    return meta


def escape_lua_string(s: str) -> str:
    """Escape characters incompatible with Lua double-quoted strings."""
    s = s.replace('\\', '\\\\')  # Must be first
    s = s.replace('"', '\\"')
    s = s.replace('\n', '\\n')
    s = s.replace('\r', '\\r')
    s = s.replace('\0', '\\0')
    return s


def mp3_duration(path: Path) -> int:
    """Return duration in whole seconds, or 0 on error."""
    try:
        audio = MP3(str(path))
        return max(0, round(audio.info.length))
    except Exception:
        return 0


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    parser.add_argument("--music", default=str(DEFAULT_MUSIC_DIR),
                        help="Path to the wow.export sound/music folder")
    parser.add_argument("--lua", default=str(DEFAULT_TRACKS_LUA),
                        help="Output path for DefaultTracks.lua")
    args = parser.parse_args()

    music_dir = Path(args.music)
    lua_path  = Path(args.lua)

    if not music_dir.exists():
        sys.exit(f"ERROR: Music folder not found: {music_dir}")

    # --- Load supporting data ---
    print(f"Loading resource IDs from TrackPaths.txt...")
    track_ids = load_track_ids(music_dir)
    print(f"  {len(track_ids)} entries")

    print(f"Loading existing metadata from DefaultTracks.lua...")
    existing_meta = load_existing_metadata(lua_path)
    print(f"  {len(existing_meta)} entries")

    # --- Walk all MP3 files ---
    print(f"\nScanning MP3 files in {music_dir}...")
    entries: list[tuple[str, int, str, str, str, int]] = []  # (lua_key, duration, title, artist, album, res_id)

    for root, dirs, files in os.walk(music_dir):
        dirs.sort()
        for fname in sorted(files):
            if not fname.lower().endswith(".mp3"):
                continue
            abs_path = Path(root) / fname
            # Relative path from the music folder (forward slashes, no .mp3)
            rel = abs_path.relative_to(music_dir)
            rel_no_ext = rel.with_suffix("")
            # Lua-style key: escaped backslashes
            lua_key = str(rel_no_ext).replace(os.sep, "\\\\")
            # Normalised key for lookups
            norm_key = normalise_key(str(rel_no_ext))

            duration  = mp3_duration(abs_path)
            res_id    = track_ids.get(norm_key, 0)
            expansion = infer_expansion(str(rel))

            if norm_key in existing_meta:
                title, artist, album = existing_meta[norm_key]
                if album == "None":
                    album = expansion
            else:
                # Derive title from filename: strip trailing _<digits> resource suffix if present
                stem = rel_no_ext.name
                stem = re.sub(r'_\d+$', '', stem)
                title  = stem
                artist = "None"
                album  = expansion

            entries.append((lua_key, duration, title, artist, album, res_id))

    print(f"Found {len(entries)} MP3 files")

    # --- Write DefaultTracks.lua ---
    print(f"\nWriting {lua_path}...")
    lines = ["function Soundtrack_LoadDefaultTracks()"]
    for lua_key, duration, title, artist, album, res_id in entries:
        # Escape characters incompatible with Lua double-quoted strings
        title  = escape_lua_string(title)
        artist = escape_lua_string(artist)
        album  = escape_lua_string(album)
        lines.append(
            f'    Soundtrack.Library.AddDefaultTrack("{lua_key}", {duration}, "{title}", "{artist}", "{album}", {res_id})'
        )
    lines.append("end")
    lines.append("")

    lua_path.write_text("\n".join(lines), encoding="utf-8")
    print(f"Written {len(entries)} entries to {lua_path}")
    print("Done!")


if __name__ == "__main__":
    main()
