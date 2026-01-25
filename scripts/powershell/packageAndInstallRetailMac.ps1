# Package and install Soundtrack addon for Retail on Mac

$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
& (Join-Path $scriptPath "packageAndInstall.ps1") -GameFolder "_retail_" -WoWRootPath "/Applications/World of Warcraft"
