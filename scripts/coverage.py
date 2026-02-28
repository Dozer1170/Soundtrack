#!/usr/bin/env python3
"""
coverage.py — generate an HTML coverage report from coverage/lcov.info.

The lcov.info file is produced by test.py. This script normalises the SF:
path entries to absolute POSIX paths (needed when genhtml runs on Windows),
then invokes genhtml. On Windows it also searches common Strawberry Perl /
Chocolatey locations if genhtml is not on PATH.

Usage (from project root):
    python3 scripts/coverage.py
"""

import re
import shutil
import subprocess
import sys
from pathlib import Path, PurePosixPath

ROOT          = Path(__file__).parent.parent
LCOV_INFO     = ROOT / "coverage" / "lcov.info"
LCOV_NORM     = ROOT / "coverage" / "lcov.norm.info"
HTML_DIR      = ROOT / "coverage" / "html"

# ---------------------------------------------------------------------------
# Path normalisation
# ---------------------------------------------------------------------------

def normalise_lcov(src: Path, dst: Path) -> None:
    """
    Rewrite SF: lines so that relative paths become absolute POSIX paths.
    Needed on Windows where genhtml can't resolve project-relative paths.
    """
    lines = src.read_text(encoding="utf-8").splitlines()
    out = []
    for line in lines:
        if line.startswith("SF:"):
            raw = line[3:]
            p = Path(raw)
            if not p.is_absolute():
                p = (ROOT / p).resolve()
            out.append("SF:" + p.as_posix())
        else:
            out.append(line)
    dst.write_text("\n".join(out) + "\n", encoding="utf-8")


# ---------------------------------------------------------------------------
# Perl (Windows fallback)
# ---------------------------------------------------------------------------

PERL_CANDIDATES_WIN = [
    r"C:\ProgramData\chocolatey\lib\StrawberryPerl\tools\perl\bin\perl.exe",
    r"C:\Strawberry\perl\bin\perl.exe",
    r"C:\Program Files\Strawberry Perl\perl\bin\perl.exe",
    r"C:\Program Files\Git\usr\bin\perl.exe",
    r"C:\Program Files\Git\bin\perl.exe",
]


def find_perl() -> str | None:
    perl = shutil.which("perl")
    if perl:
        return perl
    if sys.platform == "win32":
        for c in PERL_CANDIDATES_WIN:
            if Path(c).exists():
                return c
    return None


# ---------------------------------------------------------------------------
# genhtml
# ---------------------------------------------------------------------------

GENHTML_CANDIDATES_WIN = [
    r"C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml",
    r"C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml.bat",
    r"C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml.exe",
]


def find_genhtml() -> tuple[str, bool]:
    """Return (path, needs_perl)."""
    gh = shutil.which("genhtml")
    if gh:
        ext = Path(gh).suffix.lower()
        return gh, ext in ("", ".pl")

    if sys.platform == "win32":
        for c in GENHTML_CANDIDATES_WIN:
            if Path(c).exists():
                ext = Path(c).suffix.lower()
                return c, ext in ("", ".pl")

    raise RuntimeError(
        "genhtml was not found. "
        "Install lcov (brew install lcov / choco install lcov) or add genhtml to PATH."
    )


def run_genhtml(lcov_file: Path, output_dir: Path) -> int:
    genhtml_path, needs_perl = find_genhtml()
    output_dir.mkdir(parents=True, exist_ok=True)

    cmd: list
    if needs_perl:
        perl = find_perl()
        if not perl:
            sys.exit(
                "ERROR: genhtml requires Perl but perl was not found. "
                "Install Strawberry Perl or add perl to PATH."
            )
        cmd = [perl, genhtml_path, str(lcov_file), "-o", str(output_dir)]
    else:
        cmd = [genhtml_path, str(lcov_file), "-o", str(output_dir)]

    return subprocess.run(cmd, cwd=ROOT).returncode


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    if not LCOV_INFO.exists():
        sys.exit(
            f"ERROR: {LCOV_INFO.relative_to(ROOT)} not found. "
            "Run 'python3 scripts/test.py' first."
        )

    print("Normalising lcov paths...")
    normalise_lcov(LCOV_INFO, LCOV_NORM)

    print(f"Generating HTML report → {HTML_DIR.relative_to(ROOT)}/")
    rc = run_genhtml(LCOV_NORM, HTML_DIR)
    sys.exit(rc)


if __name__ == "__main__":
    main()
