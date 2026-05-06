# release.ps1 - build and publish typst-manager to PyPI
#
# Usage:
#   .\release.ps1            dry run (builds only, no upload)
#   .\release.ps1 publish    builds and uploads to PyPI

param(
    [string]$Mode = ""
)

$ErrorActionPreference = "Stop"

$Tool      = "typst-manager"
$PyProject = "pyproject.toml"

function Write-Green($msg)  { Write-Host $msg -ForegroundColor Green }
function Write-Red($msg)    { Write-Host $msg -ForegroundColor Red   }
function Write-Blue($msg)   { Write-Host $msg -ForegroundColor Cyan  }
function Write-Bold($msg)   { Write-Host $msg -ForegroundColor White }
function Abort($msg)        { Write-Red ("Error: " + $msg); exit 1  }

if (-not (Test-Path $PyProject)) {
    Abort "Run this script from the project root (pyproject.toml not found)."
}

if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
    Abort "python not found. Install it from https://python.org"
}

$VersionLine = Get-Content $PyProject | Where-Object { $_ -match '^version' } | Select-Object -First 1
if (-not $VersionLine) { Abort "Could not read version from $PyProject." }
$Version = $VersionLine -replace 'version = "(.+)"', '$1'

Write-Bold ("=== " + $Tool + " - release script ===")
Write-Host ("Version : " + $Version)
Write-Host ""

Write-Blue "Checking build tools..."
foreach ($pkg in @("build", "twine")) {
    $result = python -m $pkg --version 2>&1
    if ($LASTEXITCODE -ne 0) {
        Write-Host ("Installing " + $pkg + "...")
        python -m pip install --quiet $pkg
    }
}
Write-Host "build and twine are ready."
Write-Host ""

Write-Blue "Cleaning dist..."
foreach ($dir in @("dist", "build")) {
    if (Test-Path $dir) { Remove-Item $dir -Recurse -Force }
}
Get-ChildItem -Filter *.egg-info -Directory -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force
Write-Host "Done."
Write-Host ""

Write-Blue ("Building " + $Tool + " " + $Version + "...")
python -m build
if ($LASTEXITCODE -ne 0) { Abort "Build failed." }

Write-Host ""
Write-Host "Built:"
Get-ChildItem dist | ForEach-Object { Write-Host ("  " + $_.Name) }
Write-Host ""

if ($Mode -ne "publish") {
    Write-Green "Dry run complete - package built but NOT uploaded."
    Write-Host ""
    Write-Host "To upload to PyPI run:"
    Write-Host "  .\release.ps1 publish"
    Write-Host ""
    Write-Host "To install locally for testing:"
    $WheelName = $Tool + "-" + $Version + "-py3-none-any.whl"
    Write-Host ("  pipx install dist\" + $WheelName)
    exit 0
}

Write-Host ""
$answer = Read-Host ("About to upload " + $Tool + " " + $Version + " to PyPI. Continue? [y/N]")
if ($answer.ToLower() -ne "y") {
    Write-Host "Aborted."
    exit 0
}

Write-Blue "Uploading to PyPI..."
python -m twine upload dist\*
if ($LASTEXITCODE -ne 0) { Abort "Upload failed." }

Write-Host ""
Write-Green ($Tool + " " + $Version + " published to PyPI!")
Write-Host ""
Write-Host "Users can now install it with:"
Write-Host ("  pipx install " + $Tool)
Write-Host ("  pip install " + $Tool)
