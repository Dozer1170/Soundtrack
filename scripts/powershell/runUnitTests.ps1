[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$script:LuaRocksEnvironment = $null

function Initialize-LuaRocksEnvironment {
    if ($script:LuaRocksEnvironment) {
        return $script:LuaRocksEnvironment
    }

    $luarocks = Get-Command luarocks -ErrorAction SilentlyContinue
    if (-not $luarocks) {
        throw "LuaRocks was not found on PATH. Install LuaRocks or add it to PATH to enable coverage reporting."
    }

    $binPath = (& $luarocks.Source path --lr-bin | Select-Object -Last 1).Trim()
    if ([string]::IsNullOrWhiteSpace($binPath)) {
        throw "LuaRocks did not return a bin directory. Unable to locate luacov."
    }

    if (-not (Test-Path $binPath)) {
        throw "LuaRocks bin directory '$binPath' does not exist."
    }

    if (-not (($env:Path -split ";") -contains $binPath)) {
        $env:Path = "$binPath;" + $env:Path
    }

    $luaPath = (& $luarocks.Source path --lr-path | Select-Object -Last 1).Trim()
    if (-not [string]::IsNullOrWhiteSpace($luaPath)) {
        if ([string]::IsNullOrWhiteSpace($env:LUA_PATH)) {
            $env:LUA_PATH = $luaPath
        } else {
            $env:LUA_PATH = "$luaPath;" + $env:LUA_PATH
        }
    }

    $luaCPath = (& $luarocks.Source path --lr-cpath | Select-Object -Last 1).Trim()
    if (-not [string]::IsNullOrWhiteSpace($luaCPath)) {
        if ([string]::IsNullOrWhiteSpace($env:LUA_CPATH)) {
            $env:LUA_CPATH = $luaCPath
        } else {
            $env:LUA_CPATH = "$luaCPath;" + $env:LUA_CPATH
        }
    }

    $script:LuaRocksEnvironment = @{ Command = $luarocks.Source; BinPath = $binPath }
    return $script:LuaRocksEnvironment
}

function Get-LuaCovExecutable {
    $envInfo = Initialize-LuaRocksEnvironment

    $luacov = Get-Command luacov -ErrorAction SilentlyContinue
    if ($luacov) {
        return $luacov.Source
    }

    throw "luacov executable was not found even after adding '$($envInfo.BinPath)' to PATH."
}

$statsFile = Join-Path (Get-Location) "luacov.stats.out"
if (Test-Path $statsFile) {
    Remove-Item $statsFile -Force
}

$coverageDir = Join-Path (Get-Location) "coverage"
if (-not (Test-Path $coverageDir)) {
    New-Item -ItemType Directory -Path $coverageDir | Out-Null
}

$env:SOUNDTRACK_COVERAGE = "1"

Initialize-LuaRocksEnvironment | Out-Null

lua .\src\Tests\TestRunner.lua
if ($LASTEXITCODE -ne 0) {
    exit $LASTEXITCODE
}

$luacovPath = Get-LuaCovExecutable
& $luacovPath -c .\.luacov -r lcov
exit $LASTEXITCODE
