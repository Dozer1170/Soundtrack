# Package and install Soundtrack addon for Classic

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptPath "packageAndInstall.ps1") -GameFolder "_classic_"
