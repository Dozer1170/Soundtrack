# Package Soundtrack addon into a zip file

param(
    [Parameter(Mandatory = $true)]
    [string]$OutFile
)

# Remove existing zip file
if (Test-Path $OutFile) {
    Remove-Item $OutFile -Force
}

# Create zip file from src/Soundtrack
$srcPath = Join-Path $PSScriptRoot "..\..\src\Soundtrack"
$zipPath = Join-Path (Split-Path $PSScriptRoot -Parent) $OutFile

# Use native compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$compression = [System.IO.Compression.CompressionLevel]::Optimal

# Get all files and filter out excluded ones
$excludedPatterns = @("*.iml", "*.hexdumptmp*", "*MyTracks.lua*", "*.pyc*", "LegacyLibraryGeneration")

$filesToZip = Get-ChildItem -Path $srcPath -Recurse -File | Where-Object {
    $relativePath = $_.FullName.Substring($srcPath.Length + 1)
    -not ($excludedPatterns | Where-Object { $relativePath -like $_ })
}

# Create the zip file
[System.IO.Compression.ZipFile]::CreateFromDirectory($srcPath, $zipPath, $compression, $false)

Write-Host "Created zip file: $zipPath"
