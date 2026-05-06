# typst-manager installer — Windows (PowerShell)
# Usage: irm https://raw.githubusercontent.com/orvizz/typst-manager/main/install.ps1 | iex

$ErrorActionPreference = "Stop"

$Tool       = "typst-manager"
$RepoUrl    = "https://github.com/orvizz/typst-manager"
$MinVersion = [Version]"3.9"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

function Write-Green($msg) { Write-Host $msg -ForegroundColor Green }
function Write-Red($msg)   { Write-Host $msg -ForegroundColor Red   }
function Write-Yellow($msg){ Write-Host $msg -ForegroundColor Yellow }
function Write-Bold($msg)  { Write-Host $msg -ForegroundColor White  }
function Abort($msg)       { Write-Red "Error: $msg"; exit 1 }

# ---------------------------------------------------------------------------
# Find Python 3.9+
# ---------------------------------------------------------------------------

Write-Bold "Installing $Tool on Windows..."
Write-Host ""

function Find-Python {
  $candidates = @("python", "python3", "py")
  foreach ($cmd in $candidates) {
    $found = Get-Command $cmd -ErrorAction SilentlyContinue
    if ($null -eq $found) { continue }
    try {
      $ver = & $cmd -c "import sys; print('%d.%d' % sys.version_info[:2])" 2>$null
      if ([Version]$ver -ge $MinVersion) { return $cmd }
    } catch {}
  }
  # Try py launcher with specific versions
  foreach ($minor in @(13,12,11,10,9)) {
    try {
      $ver = & py "-3.$minor" -c "print(1)" 2>$null
      if ($ver -eq "1") { return "py -3.$minor" }
    } catch {}
  }
  return $null
}

$Python = Find-Python
if ($null -eq $Python) {
  Abort "Python $MinVersion or higher is required but was not found.
Install it from https://python.org (check 'Add Python to PATH' during setup)."
}

$PyVersion = & $Python.Split()[0] --version 2>&1
Write-Host "Found: $PyVersion ($Python)"

# ---------------------------------------------------------------------------
# Install via pipx (preferred) or pip
# ---------------------------------------------------------------------------

$UsePipx = $null -ne (Get-Command "pipx" -ErrorAction SilentlyContinue)

if ($UsePipx) {
  Write-Host "Using pipx..."
  $installed = pipx list 2>$null | Select-String $Tool
  if ($installed) {
    pipx upgrade $Tool
  } else {
    pipx install $Tool
  }
  $InstallMethod = "pipx"
} else {
  Write-Yellow "pipx not found — installing with pip (user install)."
  Write-Host "Tip: install pipx for easier management: https://pipx.pypa.io"
  Write-Host ""
  & $Python.Split()[0] -m pip install --user --upgrade $Tool
  if ($LASTEXITCODE -ne 0) { Abort "pip install failed." }
  $InstallMethod = "pip"
}

# ---------------------------------------------------------------------------
# PATH check (pip user install only)
# ---------------------------------------------------------------------------

if ($InstallMethod -eq "pip") {
  # Python user Scripts directory
  $UserBase    = & $Python.Split()[0] -m site --user-base 2>$null
  $UserScripts = Join-Path $UserBase "Scripts"

  $currentPath = [System.Environment]::GetEnvironmentVariable("PATH", "User")
  if ($currentPath -notlike "*$UserScripts*") {
    Write-Host ""
    Write-Yellow "Warning: $UserScripts is not in your PATH."
    Write-Host "Adding it permanently for your user account..."
    $newPath = "$UserScripts;$currentPath"
    [System.Environment]::SetEnvironmentVariable("PATH", $newPath, "User")
    Write-Host "PATH updated. Restart your terminal for the change to take effect."
  }
}

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------

Write-Host ""
$found = Get-Command $Tool -ErrorAction SilentlyContinue
if ($null -ne $found) {
  Write-Green "✓ $Tool installed successfully!"
} else {
  Write-Yellow "Installation complete, but '$Tool' was not found in PATH yet."
  Write-Host "Restart your terminal and try again."
}

Write-Host ""
Write-Bold "Get started:"
Write-Host "  typst-manager template create my-template"
Write-Host "  typst-manager template list"
Write-Host "  typst-manager new my-doc --template my-template"
Write-Host ""
Write-Host "Documentation: $RepoUrl"
