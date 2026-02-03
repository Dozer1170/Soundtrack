[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

function Get-GenHtmlExecutable {
    $genhtml = Get-Command genhtml -ErrorAction SilentlyContinue
    if ($genhtml) {
        return $genhtml.Source
    }

    $fallbacks = @(
        "C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml.exe",
        "C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml.bat",
        "C:\ProgramData\chocolatey\lib\lcov\tools\bin\genhtml"
    )

    foreach ($candidate in $fallbacks) {
        if (Test-Path $candidate) {
            return $candidate
        }
    }

    throw "genhtml was not found. Install lcov or add genhtml to PATH."
}

$coverageFile = Join-Path (Get-Location) "coverage/lcov.info"
if (-not (Test-Path $coverageFile)) {
    throw "Coverage data not found at '$coverageFile'. Run the unit tests with coverage first."
}

$coverageDir = Join-Path (Get-Location) "coverage/html"
if (-not (Test-Path $coverageDir)) {
    New-Item -ItemType Directory -Path $coverageDir -Force | Out-Null
}

$genhtmlPath = Get-GenHtmlExecutable
& $genhtmlPath $coverageFile -o $coverageDir
exit $LASTEXITCODE
