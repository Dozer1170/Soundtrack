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
$srcPath = Join-Path $PSScriptRoot "..\..\src"
$soundtrackPath = Join-Path $srcPath "Soundtrack"
$rootPath = Split-Path $PSScriptRoot -Parent
$rootPath = Split-Path $rootPath -Parent
$zipPath = Join-Path $rootPath $OutFile

# Use native compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
$compression = [System.IO.Compression.CompressionLevel]::Optimal

# Create the zip file from src directory so that Soundtrack folder is included in the zip
[System.IO.Compression.ZipFile]::CreateFromDirectory($srcPath, $zipPath, $compression, $false)

Write-Host "Created zip file: $zipPath"
