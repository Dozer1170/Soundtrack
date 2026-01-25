# Package Soundtrack addon into a zip file

# Extract version from TOC file
$srcPath = Join-Path $PSScriptRoot "..\..\src"
$tocPath = Join-Path $srcPath "Soundtrack\Soundtrack-Mainline.toc"

if (-not (Test-Path $tocPath)) {
    Write-Host "Error: Could not find TOC file at $tocPath"
    exit 1
}

$tocContent = Get-Content $tocPath
$versionLine = $tocContent | Where-Object { $_ -match "^## Version:" }
if (-not $versionLine) {
    Write-Host "Error: Could not find Version in TOC file"
    exit 1
}

$version = $versionLine -replace "^## Version:\s*", ""
$OutFile = "Soundtrack.$version.zip"

# Remove existing zip file
if (Test-Path $OutFile) {
    Remove-Item $OutFile -Force
}

# Create zip file from src/Soundtrack
$soundtrackPath = Join-Path $srcPath "Soundtrack"
$rootPath = Split-Path $PSScriptRoot -Parent
$rootPath = Split-Path $rootPath -Parent
$zipPath = Join-Path $rootPath $OutFile

# Use native PowerShell compression (much faster than manual copying)
# Note: Compress-Archive doesn't support wildcards in -Exclude, so we filter with robocopy instead
$tempFolder = Join-Path $env:TEMP "SoundtrackPackage_$(Get-Random)"

try {
    # Use robocopy to copy only the Soundtrack folder while excluding patterns (matching bash behavior)
    $robocopyArgs = @(
        $soundtrackPath,
        (Join-Path $tempFolder "Soundtrack"),
        '/S',                          # Recurse subdirectories
        '/E',                          # Include empty directories
        '/XD', '.git',                 # Exclude directories
        '/XF', '*.iml', '*.hexdumptmp*', '*MyTracks.lua', '*.pyc', '.DS_Store', '.gitignore', '.gitattributes' # Exclude files
    )
    
    robocopy @robocopyArgs | Out-Null
    
    # Create the zip file containing the Soundtrack folder
    Compress-Archive -Path (Join-Path $tempFolder "Soundtrack") -DestinationPath $zipPath -Force -CompressionLevel Optimal
    
    Write-Host "Created zip file: $zipPath"
}
finally {
    # Clean up temp folder
    if (Test-Path $tempFolder) {
        Remove-Item $tempFolder -Recurse -Force
    }
}
