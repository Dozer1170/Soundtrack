# Install addon from zip file

param(
    [Parameter(Mandatory = $true)]
    [string]$ZipFile,
    
    [Parameter(Mandatory = $true)]
    [string]$GameFolder,
    
    [string]$WoWRootPath = "C:\World of Warcraft"
)

$addonPath = Join-Path -Path $WoWRootPath -ChildPath $GameFolder
$addonPath = Join-Path -Path $addonPath -ChildPath "Interface"
$addonPath = Join-Path -Path $addonPath -ChildPath "Addons"

if (-not (Test-Path $addonPath)) {
    Write-Host "Creating addon path: $addonPath"
    New-Item -ItemType Directory -Path $addonPath -Force | Out-Null
}

Write-Host "Extracting addon from $ZipFile to $addonPath"

Add-Type -AssemblyName System.IO.Compression.FileSystem

# Remove existing addon folders to avoid conflicts with files like .git
$soundtrackPath = Join-Path -Path $addonPath -ChildPath "Soundtrack"
$blizzardPath = Join-Path -Path $addonPath -ChildPath "BlizzardInterfaceCode"

if (Test-Path $soundtrackPath) {
    Remove-Item $soundtrackPath -Recurse -Force
}
if (Test-Path $blizzardPath) {
    Remove-Item $blizzardPath -Recurse -Force
}

[System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $addonPath)

Write-Host "Addon installed successfully!"
