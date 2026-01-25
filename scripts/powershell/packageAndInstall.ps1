# Package addon and install it to World of Warcraft

param(
    [Parameter(Mandatory=$true)]
    [string]$GameFolder,
    
    [string]$WoWRootPath = "C:\World of Warcraft"
)

if (-not $GameFolder) {
    Write-Host "Provide game folder as first argument"
    exit 1
}

Write-Host "Game folder: $GameFolder"
Write-Host "WoW root path: $WoWRootPath"

# Paths
$addonPath = Join-Path -Path $WoWRootPath -ChildPath $GameFolder
$addonPath = Join-Path -Path $addonPath -ChildPath "Interface"
$addonPath = Join-Path -Path $addonPath -ChildPath "Addons"
$soundtrackPath = Join-Path -Path $addonPath -ChildPath "Soundtrack"
$legacyGenPath = Join-Path -Path $addonPath -ChildPath "SoundtrackMusic"
$legacyGenPath = Join-Path -Path $legacyGenPath -ChildPath "LegacyLibraryGeneration"
$zipFile = "SoundtrackTest.0.4.zip"

# Remove existing addon installation
if (Test-Path $soundtrackPath) {
    Write-Host "Removing existing Soundtrack addon..."
    Remove-Item $soundtrackPath -Recurse -Force
}

if (Test-Path $legacyGenPath) {
    Write-Host "Removing LegacyLibraryGeneration folder..."
    Remove-Item $legacyGenPath -Recurse -Force
}

# Package and install
$scriptPath = Split-Path -Parent $MyInvocation.MyCommand.Path
$rootPath = Split-Path -Parent (Split-Path -Parent $scriptPath)

Write-Host "Packaging addon..."
& (Join-Path $scriptPath "package.ps1") -OutFile $zipFile

Write-Host "Installing addon..."
& (Join-Path $scriptPath "installFromZip.ps1") -ZipFile $zipFile -GameFolder $GameFolder -WoWRootPath $WoWRootPath

Write-Host "Done!"
