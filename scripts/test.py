#!/usr/bin/env python3
"""
test.py — run the Soundtrack unit tests with luacov coverage.

Steps:
  1. Locate luarocks and inject its bin/path/cpath into the environment.
  2. Delete any stale luacov.stats.out.
  3. Run lua src/Tests/TestRunner.lua with SOUNDTRACK_COVERAGE=1.
  4. Delegate all coverage tasks to coverage.py (luacov → lcov.info → HTML).

Usage (from project root):
    python3 scripts/test.py
"""

import os
import shutil
import subprocess
import sys
from pathlib import Path

ROOT        = Path(__file__).parent.parent
STATS_FILE  = ROOT / "luacov.stats.out"
COVERAGE_DIR = ROOT / "coverage"
TEST_RUNNER = ROOT / "src" / "Tests" / "TestRunner.lua"

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
# Main
# ---------------------------------------------------------------------------

def main() -> None:
    # 1. Find & configure luarocks
    luarocks = find_luarocks()
    env = setup_luarocks_env(luarocks)
    env["SOUNDTRACK_COVERAGE"] = "1"

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

    # 5. Delegate all coverage tasks to coverage.py
    coverage_script = Path(__file__).parent / "coverage.py"
    result = _run([sys.executable, str(coverage_script)], cwd=ROOT)
    sys.exit(result.returncode)


if __name__ == "__main__":
    main()
