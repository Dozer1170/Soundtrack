# Package and install Soundtrack addon for Retail

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptPath "packageAndInstall.ps1") -GameFolder "_retail_"
