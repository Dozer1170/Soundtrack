# Script to match paths from TrackPaths.txt and append IDs to DefaultTracks.lua

# Read TrackPaths.txt and create a hashtable mapping paths to IDs
$trackPathsFile = Join-Path $PSScriptRoot "TrackPaths.txt"
$defaultTracksFile = Join-Path $PSScriptRoot "src\Soundtrack\DefaultTracks.lua"

Write-Host "Reading TrackPaths.txt..."
$trackIdMap = @{}

Get-Content $trackPathsFile | ForEach-Object {
    if ($_ -match '^(.+);(\d+)$') {
        $fullPath = $matches[1].Trim() -replace ' ', ''  # Remove spaces from path
        $id = $matches[2]
        
        # Remove "sound/music/" prefix and .mp3 extension
        $relativePath = $fullPath -replace '^sound/music/', '' -replace '\.mp3$', ''
        
        # Use the same logic for all paths: normalize to lowercase with backslashes, no spaces
        $normalizedKey = $relativePath.ToLower() -replace ' ', '' -replace '/', '\\'
        
        if (-not $trackIdMap.ContainsKey($normalizedKey)) {
            $trackIdMap[$normalizedKey] = $id
        }
    }
}

Write-Host "Found $($trackIdMap.Count) track paths in lookup table"

# Show first 5 keys for debugging
$count = 0
$trackIdMap.Keys | ForEach-Object {
    if ($count -lt 5) {
        Write-Host "Sample key: $_"
        $count++
    }
}

# Read DefaultTracks.lua
Write-Host "Reading DefaultTracks.lua..."
$content = Get-Content $defaultTracksFile -Raw

# Find all AddDefaultTrack calls with the first parameter (the path)
$pattern = 'Soundtrack\.Library\.AddDefaultTrack\("([^"]+)"'
$matches = [regex]::Matches($content, $pattern)

Write-Host "Found $($matches.Count) track entries in DefaultTracks.lua"

# Show first 5 lua paths for debugging
$count = 0
$matches | ForEach-Object {
    if ($count -lt 5) {
        $oldPath = $_.Groups[1].Value
        $normalizedLookupPath = $oldPath -replace '\\', '/' -replace '\.mp3$', ''
        $normalizedLookupPath = $normalizedLookupPath.ToLower() -replace ' ', ''
        Write-Host "Sample lua path: $oldPath -> normalized: $normalizedLookupPath"
        $count++
    }
}

# Process each match
$replacements = @()
$matchedCount = 0
$unmatchedPaths = @()

foreach ($match in $matches) {
    $oldPath = $match.Groups[1].Value
    
    # Remove any previously appended IDs (////number)
    $pathForLookup = $oldPath -replace '////.*$', ''
    
    # Use the same logic for all paths: normalize to lowercase with no spaces
    $normalizedLookupPath = $pathForLookup.ToLower() -replace ' ', ''
    
    if ($trackIdMap.ContainsKey($normalizedLookupPath)) {
        $id = $trackIdMap[$normalizedLookupPath]
        $newPath = "$pathForLookup////$id"
        
        if ($matchedCount -lt 10) {
            Write-Host "Match: $oldPath -> $newPath (ID: $id)"
        }
        $matchedCount++
        
        $replacements += @{
            Old = "`"$oldPath`""
            New = "`"$newPath`""
        }
    } else {
        $unmatchedPaths += $pathForLookup
    }
}

Write-Host "Matched $($matchedCount) paths out of $($matches.Count) entries"

# Show unmatched paths
if ($unmatchedPaths.Count -gt 0) {
    Write-Host "`nUnmatched paths ($($unmatchedPaths.Count) total):"
    $unmatchedPaths | ForEach-Object {
        Write-Host "  $_"
    }
}

# Apply replacements
if ($replacements.Count -gt 0) {
    Write-Host "Applying replacements to DefaultTracks.lua..."
    $updatedContent = $content
    
    foreach ($replacement in $replacements) {
        $updatedContent = $updatedContent -replace [regex]::Escape($replacement.Old), $replacement.New
    }
    
    # Backup original file
    $backupFile = "$defaultTracksFile.backup"
    Copy-Item $defaultTracksFile $backupFile
    Write-Host "Backup created at: $backupFile"
    
    # Write updated content
    Set-Content $defaultTracksFile $updatedContent -Encoding UTF8
    Write-Host "DefaultTracks.lua updated successfully!"
} else {
    Write-Host "No matching paths found. Please check the format of TrackPaths.txt and DefaultTracks.lua"
}

Write-Host "Done!"
