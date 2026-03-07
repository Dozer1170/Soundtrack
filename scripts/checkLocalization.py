#!/usr/bin/env python3
"""
checkLocalization — validate that all localization files define the same set
of global string keys as the English reference file.

Usage (from project root):
    ./scripts/checkLocalization

Exit codes:
    0  All locale files have exactly the same keys as the English reference.
    1  One or more locale files are missing keys or have unexpected extras.
"""

import re
import sys
from pathlib import Path

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------

LOCALIZATION_DIR = Path(__file__).parent.parent / "src" / "Soundtrack" / "Core" / "Localization"

# The English file is the canonical reference.
REFERENCE_FILE = LOCALIZATION_DIR / "Localization.en.lua"

# Pattern: a tab-indented ALL_CAPS global assignment.
#   e.g.  \tSOUNDTRACK_CLOSE = "..."
#         \tBINDING_HEADER_SOUNDTRACK = ...
KEY_PATTERN = re.compile(r"^\t([A-Z_][A-Z0-9_]+)\s*=")


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def extract_keys(path: Path) -> set[str]:
    """Return the set of global variable names assigned in *path*."""
    keys: set[str] = set()
    with path.open(encoding="utf-8", errors="replace") as fh:
        for line in fh:
            m = KEY_PATTERN.match(line)
            if m:
                keys.add(m.group(1))
    return keys


def locale_label(path: Path) -> str:
    return path.name


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> int:
    if not REFERENCE_FILE.exists():
        print(f"ERROR: Reference file not found: {REFERENCE_FILE}", file=sys.stderr)
        return 1

    reference_keys = extract_keys(REFERENCE_FILE)
    print(f"Reference ({REFERENCE_FILE.name}): {len(reference_keys)} keys\n")

    # Collect every other localization Lua file in the same directory.
    other_files = sorted(
        p for p in LOCALIZATION_DIR.glob("*.lua")
        if p != REFERENCE_FILE and p.name != "SoundtrackLocalization.lua"
    )

    if not other_files:
        print("No other localization files found — nothing to compare.")
        return 0

    failures = 0

    for locale_file in other_files:
        locale_keys = extract_keys(locale_file)
        missing = reference_keys - locale_keys   # in EN but not in this locale
        extra   = locale_keys - reference_keys   # in this locale but not in EN

        label = locale_label(locale_file)

        if not missing and not extra:
            print(f"  OK  {label} ({len(locale_keys)} keys)")
        else:
            failures += 1
            print(f"  FAIL  {label} ({len(locale_keys)} keys)")
            if missing:
                print(f"        Missing keys ({len(missing)}):")
                for k in sorted(missing):
                    print(f"          - {k}")
            if extra:
                print(f"        Extra keys not in reference ({len(extra)}):")
                for k in sorted(extra):
                    print(f"          + {k}")

    print()
    if failures:
        print(f"FAILED: {failures} locale file(s) have mismatched keys.")
        print("Fix the issues above before packaging.")
        return 1

    print("All locale files match the English reference. OK to package.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
