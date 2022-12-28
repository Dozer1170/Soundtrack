$workingDir = Get-Location

Write-Output "-- This file is automatically generated" | Out-File -Encoding ASCII -FilePath .\MyTracks.lua
Write-Output "-- Please do not edit it" | Out-File -Encoding ASCII -Append -FilePath .\MyTracks.lua
$currentDate = Get-Date
Write-Output "SMP3_PL_VERSION =`"$currentDate`"" | Out-File -Encoding ASCII -Append -FilePath .\MyTracks.lua
Write-Output "function Soundtrack_LoadMyTracks()" | Out-File -Encoding ASCII -Append -FilePath .\MyTracks.lua
Write-Output "   if SoundtrackAddon.db.profile.settings.MyTracksVersion == nil or SoundtrackAddon.db.profile.settings.MyTracksVersion ~= SMP3_PL_VERSION then" | Out-File -Encoding ASCII -Append -FilePath .\MyTracks.lua
Write-Output "      SoundtrackAddon.db.profile.settings.MyTracksVersion = SMP3_PL_VERSION" | Out-File -Encoding ASCII -Append -FilePath .\MyTracks.lua
Write-Output "      SoundtrackAddon.db.profile.settings.MyTracksVersionSame = false" | Out-File -Encoding ASCII -Append -FilePath .\MyTracks.lua
Write-Output "   else" | Out-File -Encoding ASCII -Append -FilePath .\MyTracks.lua
Write-Output "      SoundtrackAddon.db.profile.settings.MyTracksVersionSame = true" | Out-File -Encoding ASCII -Append -FilePath .\MyTracks.lua
Write-Output "   end" | Out-File -Encoding ASCII -Append -FilePath .\MyTracks.lua

Get-ChildItem . -Filter *.mp3 -name -Recurse | Foreach-Object {
    $relativeFolderPath = Split-Path $_
    $escapedRelativeFolderPath = $relativeFolderPath.Replace("\", "\\")
    $fileName = Split-Path -Leaf $_
    $folderPath = "$workingDir\$relativeFolderPath"
    $fullFilePath = "$workingDir\$_".Replace("``", "````")

    $shell = New-Object -COMObject Shell.Application
    $shellFolder = $shell.Namespace($folderPath)
    $shellFile = $shellFolder.ParseName($fileName)
    $basename = (Get-Item Microsoft.PowerShell.Core\FileSystem::$fullFilePath).Basename.Replace("\", "\\")
    $pathWithoutExtension = "$escapedRelativeFolderPath\\$basename"

    $lengthHMS = $shellFolder.GetDetailsOf($shellFile, 27)
    $length = ([timespan]$lengthHMS).TotalSeconds
    $author = $shellFolder.GetDetailsOf($shellFile, 20).Replace("\", "\\")
    if (!$author) {
        $author = "None"
    }

    $album = $shellFolder.GetDetailsOf($shellFile, 14).Replace("\", "\\")
    if (!$album) {
        $album = "None"
    }

    $trackTitle = $shellFolder.GetDetailsOf($shellFile, 21).Replace("\", "\\")
    if (!$trackTitle) {
        $trackTitle = $fileName.Replace(".mp3", "")
    }

    Write-Host "$pathWithoutExtension, Length ($length), Author ($author)"
    Write-Output "    Soundtrack.Library.AddTrack(`"$pathWithoutExtension`", $length, `"$trackTitle`", `"$author`", `"$album`")" | Out-File -Encoding ASCII -Append -FilePath .\MyTracks.lua
}

Write-Output "end" | Out-File -Encoding ASCII -Append -FilePath .\MyTracks.lua
Write-Host "Press enter to close..."
Read-Host