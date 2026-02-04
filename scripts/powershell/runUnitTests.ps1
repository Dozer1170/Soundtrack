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
        }
        else {
            $env:LUA_PATH = "$luaPath;" + $env:LUA_PATH
        }
    }

    $luaCPath = (& $luarocks.Source path --lr-cpath | Select-Object -Last 1).Trim()
    if (-not [string]::IsNullOrWhiteSpace($luaCPath)) {
        if ([string]::IsNullOrWhiteSpace($env:LUA_CPATH)) {
            $env:LUA_CPATH = $luaCPath
        }
        else {
            $env:LUA_CPATH = "$luaCPath;" + $env:LUA_CPATH
        }
    }

    $script:LuaRocksEnvironment = @{ Command = $luarocks.Source; BinPath = $binPath }
    return $script:LuaRocksEnvironment
}

function Get-LuaCovCommand {
    $envInfo = Initialize-LuaRocksEnvironment

    $luacov = Get-Command luacov -ErrorAction SilentlyContinue
    if ($luacov) {
        $path = $luacov.Source
        $extension = [System.IO.Path]::GetExtension($path)
        $requiresLua = [string]::IsNullOrWhiteSpace($extension)
        return @{ Path = $path; UseLua = $requiresLua }
    }

    $candidates = @(
        "luacov.bat",
        "luacov.cmd",
        "luacov.exe",
        "luacov.lua",
        "luacov"
    )

    foreach ($candidate in $candidates) {
        $fullPath = Join-Path $envInfo.BinPath $candidate
        if (Test-Path $fullPath) {
            $extension = [System.IO.Path]::GetExtension($fullPath)
            $requiresLua = [string]::IsNullOrWhiteSpace($extension) -or ($extension -ieq ".lua")
            return @{ Path = $fullPath; UseLua = $requiresLua }
        }
    }

    throw "luacov executable was not found even after adding '$($envInfo.BinPath)' to PATH."
}

function Invoke-LuaCov {
    param(
        [Parameter(Mandatory = $true)]
        [string[]] $Arguments
    )

    $command = Get-LuaCovCommand

    if ($command.UseLua) {
        & lua $command.Path @Arguments
    }
    else {
        & $command.Path @Arguments
    }
}

function Test-LuaCovReporter {
    try {
        & lua -e "require('luacov.reporter.lcov')" 1>$null 2>$null
        return $LASTEXITCODE -eq 0
    }
    catch {
        return $false
    }
}

function Ensure-LuaCovReporter {
    if (Test-LuaCovReporter) {
        return
    }

    $envInfo = Initialize-LuaRocksEnvironment
    Write-Host "luacov-reporter-lcov not found. Installing via LuaRocks..." -ForegroundColor Cyan
    & $envInfo.Command install luacov-reporter-lcov
    if ($LASTEXITCODE -ne 0) {
        throw "Failed to install luacov-reporter-lcov via LuaRocks."
    }

    if (-not (Test-LuaCovReporter)) {
        throw "luacov-reporter-lcov is still unavailable after installation."
    }
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

Ensure-LuaCovReporter
Invoke-LuaCov -Arguments @("-c", ".\.luacov", "-r", "lcov")
exit $LASTEXITCODE
