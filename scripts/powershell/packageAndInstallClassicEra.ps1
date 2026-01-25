# Package and install Soundtrack addon for Classic Era

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptPath "packageAndInstall.ps1") -GameFolder "_classic_era_"
