#!/usr/bin/env python3
"""
coverage.py — run all coverage tasks for the Soundtrack project.

Steps:
  1. Locate luarocks and inject its bin/path/cpath into the environment.
  2. Ensure luacov-reporter-lcov is installed.
  3. Run luacov -c .luacov -r lcov  →  coverage/lcov.info  (if stats exist).
  4. Normalise SF: paths in lcov.info for genhtml compatibility.
  5. Run genhtml  →  coverage/html/

Can be run standalone after tests have produced luacov.stats.out, or is
called automatically by test.py at the end of a test run.

Usage (from project root):
    python3 scripts/coverage.py
"""

from __future__ import annotations

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT          = Path(__file__).parent.parent
STATS_FILE    = ROOT / "luacov.stats.out"
LUACOV_CFG    = ROOT / ".luacov"
COVERAGE_DIR  = ROOT / "coverage"
LCOV_INFO     = COVERAGE_DIR / "lcov.info"
LCOV_NORM     = COVERAGE_DIR / "lcov.norm.info"
HTML_DIR      = COVERAGE_DIR / "html"

# ---------------------------------------------------------------------------
# LuaRocks environment
# ---------------------------------------------------------------------------

def _run(cmd: list, **kwargs) -> subprocess.CompletedProcess:
    """Run a command and return its CompletedProcess."""
    return subprocess.run(cmd, **kwargs)


def find_luarocks() -> str:
    """Return the path to the luarocks executable, or raise."""
    lr = shutil.which("luarocks")
    if lr:
        return lr
    raise RuntimeError(
        "luarocks was not found on PATH. "
        "Install LuaRocks or add it to PATH to enable coverage reporting."
    )


def setup_luarocks_env(luarocks: str) -> dict:
    """
    Query luarocks for its lr-bin / lr-path / lr-cpath and merge them into
    a copy of the current environment dict, which is then returned.
    """
    env = os.environ.copy()

    def query(flag: str) -> str:
        result = _run([luarocks, "path", flag], capture_output=True, text=True)
        return result.stdout.strip().splitlines()[-1].strip() if result.stdout.strip() else ""

    bin_path  = query("--lr-bin")
    lua_path  = query("--lr-path")
    lua_cpath = query("--lr-cpath")

    if bin_path:
        sep = ";" if sys.platform == "win32" else ":"
        existing = env.get("PATH", "")
        if bin_path not in existing.split(sep):
            env["PATH"] = bin_path + sep + existing

    if lua_path:
        sep = ";"
        existing = env.get("LUA_PATH", "")
        env["LUA_PATH"] = (lua_path + sep + existing) if existing else lua_path

    if lua_cpath:
        sep = ";"
        existing = env.get("LUA_CPATH", "")
        env["LUA_CPATH"] = (lua_cpath + sep + existing) if existing else lua_cpath

    return env


# ---------------------------------------------------------------------------
# luacov helpers
# ---------------------------------------------------------------------------

def find_luacov(luarocks_bin: str) -> list:
    """
    Return a command list for invoking luacov.
    On most platforms it's just ['luacov']. On Windows it may be a .lua
    script that needs to be driven with lua.
    """
    luacov = shutil.which("luacov")
    if luacov:
        ext = Path(luacov).suffix.lower()
        if ext in ("", ".exe", ".bat", ".cmd"):
            return [luacov]
        return ["lua", luacov]

    for name in ("luacov.bat", "luacov.cmd", "luacov.exe", "luacov.lua", "luacov"):
        candidate = Path(luarocks_bin) / name
        if candidate.exists():
            if candidate.suffix.lower() in ("", ".exe", ".bat", ".cmd"):
                return [str(candidate)]
            return ["lua", str(candidate)]

    raise RuntimeError(
        "luacov was not found. "
        "Install it with: luarocks install luacov"
    )


def ensure_lcov_reporter(luarocks: str, env: dict) -> None:
    """Install luacov-reporter-lcov via luarocks if it isn't available."""
    check = _run(
        ["lua", "-e", "require('luacov.reporter.lcov')"],
        capture_output=True, env=env
    )
    if check.returncode == 0:
        return

    print("luacov-reporter-lcov not found — installing via luarocks...")
    result = _run([luarocks, "install", "luacov-reporter-lcov"], env=env)
    if result.returncode != 0:
        sys.exit("ERROR: Failed to install luacov-reporter-lcov.")

    verify = _run(
        ["lua", "-e", "require('luacov.reporter.lcov')"],
        capture_output=True, env=env
    )
    if verify.returncode != 0:
        sys.exit("ERROR: luacov-reporter-lcov still unavailable after installation.")


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
    # 1. Set up luarocks environment
    luarocks = find_luarocks()
    env = setup_luarocks_env(luarocks)
    luarocks_bin = env.get("PATH", "").split(";" if sys.platform == "win32" else ":")[0]

    COVERAGE_DIR.mkdir(exist_ok=True)

    # 2. Run luacov to produce lcov.info (only if fresh stats are available)
    if STATS_FILE.exists():
        ensure_lcov_reporter(luarocks, env)
        luacov_cmd = find_luacov(luarocks_bin)
        print("Running luacov to generate lcov.info...")
        result = _run(luacov_cmd + ["-c", str(LUACOV_CFG), "-r", "lcov"], env=env, cwd=ROOT)
        if result.returncode != 0:
            sys.exit(result.returncode)
    elif not LCOV_INFO.exists():
        sys.exit(
            f"ERROR: Neither {STATS_FILE.name} nor {LCOV_INFO.relative_to(ROOT)} found. "
            "Run 'python3 scripts/test.py' first."
        )

    # 3. Normalise SF: paths for genhtml
    print("Normalising lcov paths...")
    normalise_lcov(LCOV_INFO, LCOV_NORM)

    # 4. Generate HTML report
    print(f"Generating HTML report → {HTML_DIR.relative_to(ROOT)}/")
    rc = run_genhtml(LCOV_NORM, HTML_DIR)
    sys.exit(rc)


if __name__ == "__main__":
    main()
