# Install addon from zip file

param(
    [Parameter(Mandatory=$true)]
    [string]$ZipFile,
    
    [Parameter(Mandatory=$true)]
    [string]$GameFolder,
    
    [string]$WoWRootPath = "C:\World of Warcraft"
)

$addonPath = Join-Path $WoWRootPath $GameFolder "Interface\Addons"

if (-not (Test-Path $addonPath)) {
    Write-Host "Creating addon path: $addonPath"
    New-Item -ItemType Directory -Path $addonPath -Force | Out-Null
}

Write-Host "Extracting addon from $ZipFile to $addonPath"

Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::ExtractToDirectory($ZipFile, $addonPath, $true)

Write-Host "Addon installed successfully!"
