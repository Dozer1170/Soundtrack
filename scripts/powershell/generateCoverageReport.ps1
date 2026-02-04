[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Get-PerlExecutable {
    $perl = Get-Command perl -ErrorAction SilentlyContinue
    if ($perl) {
        return $perl.Source
    }

    $candidates = @()

    if ($env:ChocolateyInstall) {
        $chocoStrawberry = Join-Path $env:ChocolateyInstall "lib/StrawberryPerl/tools/perl/bin/perl.exe"
        $candidates += $chocoStrawberry
    }

    $candidates += @(
        "C:\ProgramData\chocolatey\lib\StrawberryPerl\tools\perl\bin\perl.exe",
        "C:\Strawberry\perl\bin\perl.exe",
        "C:\Strawberry\c\bin\perl.exe",
        "C:\Program Files\Strawberry Perl\perl\bin\perl.exe",
        "C:\Program Files\Strawberry Perl\c\bin\perl.exe",
        "C:\Program Files\Git\usr\bin\perl.exe",
        "C:\Program Files\Git\bin\perl.exe"
    )

    foreach ($candidate in $candidates) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw "Perl executable was not found. Install Strawberry Perl (https://strawberryperl.com/) via Chocolatey (choco install strawberryperl) or add perl.exe to PATH."
}

function Convert-LcovPaths {
    param(
        [Parameter(Mandatory = $true)]
        [string] $InputFile,

        [Parameter(Mandatory = $true)]
        [string] $OutputFile
    )

    $projectRoot = (Get-Location).Path

    $lines = Get-Content -LiteralPath $InputFile
    $converted = foreach ($line in $lines) {
        if ($line -like "SF:*") {
            $originalPath = $line.Substring(3)
            $pathCandidate = $originalPath

            if (-not [System.IO.Path]::IsPathRooted($pathCandidate)) {
                $normalized = $pathCandidate -replace '/', '\\'
                $combined = Join-Path $projectRoot $normalized
                $pathCandidate = [System.IO.Path]::GetFullPath($combined)
            }

            $posixPath = $pathCandidate -replace '\\', '/'
            "SF:$posixPath"
        }
        else {
            $line
        }
    }

    Set-Content -LiteralPath $OutputFile -Value $converted -Encoding UTF8
}

function Get-GenHtmlCommand {
    $genhtml = Get-Command genhtml -ErrorAction SilentlyContinue
    if ($genhtml) {
        $extension = [System.IO.Path]::GetExtension($genhtml.Source)
        $usePerl = [string]::IsNullOrWhiteSpace($extension) -or ($extension -ieq ".pl")
        return @{ Path = $genhtml.Source; UsePerl = $usePerl }
    }

    $fallbacks = @(
        "C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml.exe",
        "C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml.bat",
        "C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml"
    )

    foreach ($candidate in $fallbacks) {
        if (Test-Path $candidate) {
            $extension = [System.IO.Path]::GetExtension($candidate)
            $usePerl = [string]::IsNullOrWhiteSpace($extension) -or ($extension -ieq ".pl")
            return @{ Path = $candidate; UsePerl = $usePerl }
        }
    }

    throw "genhtml was not found. Install lcov or add genhtml to PATH."
}

function Invoke-GenHtml {
    param(
        [Parameter(Mandatory = $true)]
        [string] $CoverageFile,

        [Parameter(Mandatory = $true)]
        [string] $OutputDirectory
    )

    $command = Get-GenHtmlCommand
    $arguments = @($CoverageFile, "-o", $OutputDirectory)

    if ($command.UsePerl) {
        $perl = Get-PerlExecutable
        & $perl $command.Path @arguments
    }
    else {
        & $command.Path @arguments
    }
}

$coverageFile = Join-Path (Get-Location) "coverage/lcov.info"
if (-not (Test-Path $coverageFile)) {
    throw "Coverage data not found at '$coverageFile'. Run the unit tests with coverage first."
}

$normalizedCoverageFile = Join-Path (Get-Location) "coverage/lcov.windows.info"
Convert-LcovPaths -InputFile $coverageFile -OutputFile $normalizedCoverageFile

$coverageDir = Join-Path (Get-Location) "coverage/html"
if (-not (Test-Path $coverageDir)) {
    New-Item -ItemType Directory -Path $coverageDir -Force | Out-Null
}

Invoke-GenHtml -CoverageFile $normalizedCoverageFile -OutputDirectory $coverageDir
exit $LASTEXITCODE
