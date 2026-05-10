# -----------------------------------------------------------------------------
# scripts/setup_repo_security.ps1
#
# Configures repository-level security and PR policy:
#   1. Enables private vulnerability reporting.
#   2. Enables automated security & dependency alerts (Dependabot).
#   3. Enforces branch protection on main / master / dev:
#        - Direct pushes are blocked (PRs required).
#        - At least one approving review is needed.
#        - Code owner review is required (CODEOWNERS file).
#        - Stale reviews are dismissed when new commits land.
#        - Conversation resolution is required before merge.
#        - Force-push and branch deletion are disabled.
#        - Linear history is required.
#   4. (Optional) tightens repo merge settings.
#
# Branches that don't yet exist are skipped with a warning, so you can run
# this safely today and re-run it after `dev` is created.
#
# Requirements:
#   - GitHub CLI (gh) installed and authenticated as the repo admin.
#
# Usage (from the repo root):
#   .\scripts\setup_repo_security.ps1
#   .\scripts\setup_repo_security.ps1 -DryRun
#   .\scripts\setup_repo_security.ps1 -Repo "orvizz/typst-manager"
#   .\scripts\setup_repo_security.ps1 -EnforceAdmins   # also block yourself
#
# If you get an execution-policy error, run once in the same session:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# -----------------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$Repo = "orvizz/typst-manager",
    [string[]]$Branches = @("main", "master", "dev"),
    [switch]$EnforceAdmins,
    [switch]$SkipMergeSettings,
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

if (-not (Get-Command gh -ErrorAction SilentlyContinue)) {
    Write-Host "Missing dependency: gh (GitHub CLI). Install from https://cli.github.com/" -ForegroundColor Red
    exit 1
}

Write-Host "Repo:           $Repo"
Write-Host "Branches:       $($Branches -join ', ')"
Write-Host "Enforce admins: $EnforceAdmins"
Write-Host "Dry run:        $DryRun"
Write-Host ""

function Invoke-GhApi {
    param(
        [string]$Method,
        [string]$Endpoint,
        [string]$JsonBody = $null,
        [string]$Description
    )

    if ($DryRun) {
        Write-Host "   [dry-run] $Method $Endpoint" -ForegroundColor DarkGray
        if ($JsonBody) {
            Write-Host "             body: $JsonBody" -ForegroundColor DarkGray
        }
        return
    }

    $args = @("api", "-X", $Method, $Endpoint, "-H", "Accept: application/vnd.github+json")

    if ($JsonBody) {
        # Pipe the body in via stdin so we don't fight quoting.
        $tmp = New-TemporaryFile
        try {
            Set-Content -Path $tmp -Value $JsonBody -Encoding UTF8 -NoNewline
            $args += @("--input", $tmp)
            & gh @args | Out-Null
        } finally {
            Remove-Item -Force $tmp -ErrorAction SilentlyContinue
        }
    } else {
        & gh @args | Out-Null
    }

    if ($LASTEXITCODE -ne 0) {
        throw "gh api $Method $Endpoint failed (exit $LASTEXITCODE)."
    }
}

function Test-BranchExists {
    param([string]$Branch)
    $null = gh api "repos/$Repo/branches/$Branch" 2>$null
    return ($LASTEXITCODE -eq 0)
}

# -----------------------------------------------------------------------------
# 1) Private vulnerability reporting
# -----------------------------------------------------------------------------
Write-Host "-> Enabling private vulnerability reporting..." -ForegroundColor Cyan
try {
    Invoke-GhApi -Method "PUT" `
        -Endpoint "repos/$Repo/private-vulnerability-reporting" `
        -Description "Enable private vulnerability reporting"
    Write-Host "   ok" -ForegroundColor Green
} catch {
    Write-Host "   warn: $($_.Exception.Message)" -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# 2) Vulnerability alerts (Dependabot)
# -----------------------------------------------------------------------------
Write-Host "-> Enabling Dependabot vulnerability alerts..." -ForegroundColor Cyan
try {
    Invoke-GhApi -Method "PUT" `
        -Endpoint "repos/$Repo/vulnerability-alerts" `
        -Description "Enable Dependabot alerts"
    Write-Host "   ok" -ForegroundColor Green
} catch {
    Write-Host "   warn: $($_.Exception.Message)" -ForegroundColor Yellow
}

# -----------------------------------------------------------------------------
# 3) Branch protection
# -----------------------------------------------------------------------------
Write-Host "-> Applying branch protection..." -ForegroundColor Cyan

$enforceAdminsBool = if ($EnforceAdmins) { $true } else { $false }

# JSON body for the protection rule. Keep it small and explicit.
$protectionBody = @{
    required_status_checks         = $null
    enforce_admins                 = $enforceAdminsBool
    required_pull_request_reviews  = @{
        required_approving_review_count = 1
        require_code_owner_reviews      = $true
        dismiss_stale_reviews           = $true
        require_last_push_approval      = $true
    }
    restrictions                   = $null
    required_linear_history        = $true
    allow_force_pushes             = $false
    allow_deletions                = $false
    required_conversation_resolution = $true
    lock_branch                    = $false
    allow_fork_syncing             = $true
} | ConvertTo-Json -Depth 5 -Compress

foreach ($branch in $Branches) {
    Write-Host "   $branch" -NoNewline

    if (-not (Test-BranchExists -Branch $branch)) {
        Write-Host " ... skipped (branch does not exist)" -ForegroundColor DarkGray
        continue
    }

    try {
        Invoke-GhApi -Method "PUT" `
            -Endpoint "repos/$Repo/branches/$branch/protection" `
            -JsonBody $protectionBody `
            -Description "Protect $branch"
        Write-Host " ... protected" -ForegroundColor Green
    } catch {
        Write-Host " ... failed: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# -----------------------------------------------------------------------------
# 4) Repo-level merge settings (optional)
# -----------------------------------------------------------------------------
if (-not $SkipMergeSettings) {
    Write-Host "-> Tightening merge settings..." -ForegroundColor Cyan

    $mergeBody = @{
        allow_merge_commit       = $true
        allow_squash_merge       = $true
        allow_rebase_merge       = $true
        delete_branch_on_merge   = $true
        allow_auto_merge         = $true
        allow_update_branch      = $true
    } | ConvertTo-Json -Compress

    try {
        Invoke-GhApi -Method "PATCH" `
            -Endpoint "repos/$Repo" `
            -JsonBody $mergeBody `
            -Description "Repo merge settings"
        Write-Host "   ok" -ForegroundColor Green
    } catch {
        Write-Host "   warn: $($_.Exception.Message)" -ForegroundColor Yellow
    }
}

Write-Host ""
Write-Host "Done." -ForegroundColor Green
Write-Host ""
Write-Host "What this means in practice:" -ForegroundColor Cyan
Write-Host "  - main / master / dev cannot receive direct pushes (PR required)."
Write-Host "  - Every PR needs at least one approving review."
Write-Host "  - Because CODEOWNERS lists @orvizz, your approval is the one that counts."
if (-not $EnforceAdmins) {
    Write-Host "  - You (admin) can still bypass these rules in emergencies."
    Write-Host "    Re-run with -EnforceAdmins to remove that escape hatch."
} else {
    Write-Host "  - Admins are NOT exempt: you'll have to use PRs too."
}
Write-Host "  - Force-push and branch deletion are disabled on protected branches."
