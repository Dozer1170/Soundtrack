#!/usr/bin/env python3
"""
test.py — run the Soundtrack unit tests with luacov coverage.

Steps:
  1. Locate luarocks and inject its bin/path/cpath into the environment.
  2. Delete any stale luacov.stats.out.
  3. Run lua src/Tests/TestRunner.lua with SOUNDTRACK_COVERAGE=1.
  4. Ensure luacov-reporter-lcov is installed.
  5. Run luacov -c .luacov -r lcov  →  coverage/lcov.info.

Usage (from project root):
    python3 scripts/test.py
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).parent.parent
STATS_FILE   = ROOT / "luacov.stats.out"
COVERAGE_DIR = ROOT / "coverage"
TEST_RUNNER  = ROOT / "src" / "Tests" / "TestRunner.lua"
LUACOV_CFG   = ROOT / ".luacov"

# ---------------------------------------------------------------------------
# LuaRocks environment
# ---------------------------------------------------------------------------

def _run(cmd: list, **kwargs) -> subprocess.CompletedProcess:
    """Run a command and return its CompletedProcess (raises on non-zero by default)."""
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
        sep = ";" if sys.platform == "win32" else ";"
        existing = env.get("LUA_PATH", "")
        env["LUA_PATH"] = (lua_path + sep + existing) if existing else lua_path

    if lua_cpath:
        sep = ";" if sys.platform == "win32" else ";"
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
        # .lua file — needs lua
        return ["lua", luacov]

    # Fall back: look inside the luarocks bin directory
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

    # Verify again
    verify = _run(
        ["lua", "-e", "require('luacov.reporter.lcov')"],
        capture_output=True, env=env
    )
    if verify.returncode != 0:
        sys.exit("ERROR: luacov-reporter-lcov still unavailable after installation.")


# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    # 1. Find & configure luarocks
    luarocks = find_luarocks()
    env = setup_luarocks_env(luarocks)
    env["SOUNDTRACK_COVERAGE"] = "1"

    luarocks_bin = env.get("PATH", "").split(";" if sys.platform == "win32" else ":")[0]

    # 2. Remove stale stats
    if STATS_FILE.exists():
        STATS_FILE.unlink()

    # 3. Ensure coverage dir exists
    COVERAGE_DIR.mkdir(exist_ok=True)

    # 4. Run tests
    print(f"Running tests: {TEST_RUNNER.relative_to(ROOT)}\n")
    result = _run(["lua", str(TEST_RUNNER)], env=env, cwd=ROOT)
    if result.returncode != 0:
        sys.exit(result.returncode)

    # 5. Ensure reporter installed
    ensure_lcov_reporter(luarocks, env)

    # 6. Generate lcov report
    luacov_cmd = find_luacov(luarocks_bin)
    luacov_args = luacov_cmd + ["-c", str(LUACOV_CFG), "-r", "lcov"]
    print(f"\nGenerating coverage report...")
    result = _run(luacov_args, env=env, cwd=ROOT)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
