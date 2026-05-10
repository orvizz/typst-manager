# -----------------------------------------------------------------------------
# scripts/create_github_issues.ps1
#
# Bulk-create labels, milestones and issues for typst-manager from BACKLOG.md.
# Idempotent: re-running it skips items that already exist (matched by name).
#
# Requirements:
#   - GitHub CLI (gh) installed and authenticated:  gh auth login
#   - PowerShell 5.1+ (Windows PowerShell or PowerShell 7+)
#
# Usage (from the repo root):
#   .\scripts\create_github_issues.ps1
#   .\scripts\create_github_issues.ps1 -DryRun
#   .\scripts\create_github_issues.ps1 -Repo "orvizz/typst-manager"
#
# If you get a script-execution policy error, run once in the same session:
#   Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
# -----------------------------------------------------------------------------

[CmdletBinding()]
param(
    [string]$Repo = "orvizz/typst-manager",
    [switch]$DryRun
)

$ErrorActionPreference = "Stop"

function Require-Cmd($name) {
    if (-not (Get-Command $name -ErrorAction SilentlyContinue)) {
        Write-Host "Missing dependency: $name" -ForegroundColor Red
        exit 1
    }
}
Require-Cmd "gh"

Write-Host "Repo:    $Repo"
Write-Host "Dry run: $DryRun"
Write-Host ""

function Invoke-OrLog {
    param([scriptblock]$Action, [string]$Description)
    if ($DryRun) {
        Write-Host "   [dry-run] $Description" -ForegroundColor DarkGray
    } else {
        & $Action | Out-Null
    }
}

# -----------------------------------------------------------------------------
# 1) Labels
# -----------------------------------------------------------------------------
Write-Host "-> Ensuring labels exist..." -ForegroundColor Cyan

$existingLabels = @()
try {
    $existingLabels = gh label list --repo $Repo --json name --jq '.[].name' 2>$null |
                      ForEach-Object { $_.Trim() } |
                      Where-Object { $_ -ne "" }
} catch {
    $existingLabels = @()
}

function Ensure-Label {
    param([string]$Name, [string]$Color, [string]$Description)
    if ($existingLabels -contains $Name) {
        Write-Host "   = $Name (already exists)" -ForegroundColor DarkGray
        return
    }
    Write-Host "   + $Name"
    Invoke-OrLog `
        -Description "gh label create '$Name' --color $Color" `
        -Action { gh label create $Name --repo $Repo --color $Color --description $Description }
}

Ensure-Label "enhancement"      "0e8a16" "New feature or improvement"
Ensure-Label "epic"             "5319e7" "Tracks a large area of work"
Ensure-Label "cli"              "1d76db" "CLI surface change"
Ensure-Label "core"             "0366d6" "Core library (template store, config, platform)"
Ensure-Label "registry"         "f9a825" "Templates registry, pull / publish"
Ensure-Label "web"              "0e7c66" "Project website / docs site"
Ensure-Label "docs"             "c5def5" "Documentation, READMEs, man page"
Ensure-Label "ux"               "fbca04" "Quality-of-life and ergonomics"
Ensure-Label "security"         "b60205" "Has security implications"
Ensure-Label "good first issue" "7057ff" "Approachable for new contributors"
Ensure-Label "needs design"     "d93f0b" "Requires a proposal before coding"

Write-Host ""

# -----------------------------------------------------------------------------
# 2) Milestones
# -----------------------------------------------------------------------------
Write-Host "-> Ensuring milestones exist..." -ForegroundColor Cyan

$existingMilestonesJson = gh api "repos/$Repo/milestones?state=all" 2>$null
$existingMilestones = @()
if ($existingMilestonesJson) {
    $existingMilestones = ($existingMilestonesJson | ConvertFrom-Json) |
                          ForEach-Object { $_.title }
}

function Ensure-Milestone {
    param([string]$Title, [string]$Description)
    if ($existingMilestones -contains $Title) {
        Write-Host "   = $Title (already exists)" -ForegroundColor DarkGray
        return
    }
    Write-Host "   + $Title"
    Invoke-OrLog `
        -Description "gh api repos/$Repo/milestones -f title='$Title'" `
        -Action { gh api "repos/$Repo/milestones" -f "title=$Title" -f "description=$Description" --silent }
}

Ensure-Milestone "M1: Variables & placeholders"  "Substitute title/author/date and custom vars on new"
Ensure-Milestone "M2: Compilation integration"   "Wrap typst compile / typst watch in the CLI"
Ensure-Milestone "M3: Templates registry"        "Public registry plus pull / publish commands"
Ensure-Milestone "M4: Project website"           "Static site with docs, gallery and cookbook"
Ensure-Milestone "M5: CLI quality of life"       "Doctor, completions, more editors, tags, JSON output"
Ensure-Milestone "M6: Import / export / backup"  "Move templates around, take backups, restore"

Write-Host ""

# -----------------------------------------------------------------------------
# 3) Issues
# -----------------------------------------------------------------------------
Write-Host "-> Creating issues..." -ForegroundColor Cyan

# Collect existing issue titles once for O(1) lookups
$existingIssueTitles = @()
$page = 1
do {
    $batch = gh issue list --repo $Repo --state all --limit 100 --json title 2>$null
    if ($batch) {
        $titles = ($batch | ConvertFrom-Json) | ForEach-Object { $_.title }
        $existingIssueTitles += $titles
    }
    break  # gh issue list with --limit 100 already returns enough; bail loop
} while ($true)

function New-Issue {
    param(
        [string]$Milestone,
        [string[]]$Labels,
        [string]$Title,
        [string]$Body
    )

    if ($existingIssueTitles -contains $Title) {
        Write-Host "   = $Title (already exists)" -ForegroundColor DarkGray
        return
    }

    Write-Host "   + $Title"

    if ($DryRun) {
        $labelArg = ($Labels | ForEach-Object { "--label `"$_`"" }) -join " "
        Write-Host "     [dry-run] gh issue create --title `"$Title`" --milestone `"$Milestone`" $labelArg" -ForegroundColor DarkGray
        return
    }

    # Write body to a temp file to avoid quoting hell with --body
    $tmp = New-TemporaryFile
    try {
        Set-Content -Path $tmp -Value $Body -Encoding UTF8

        $args = @(
            "issue", "create",
            "--repo", $Repo,
            "--title", $Title,
            "--milestone", $Milestone,
            "--body-file", $tmp
        )
        foreach ($l in $Labels) { $args += "--label"; $args += $l }

        & gh @args | Out-Null
    } finally {
        Remove-Item -Force $tmp -ErrorAction SilentlyContinue
    }
}

# -----------------------------------------------------------------------------
# M1 — Variables & placeholders
# -----------------------------------------------------------------------------

New-Issue "M1: Variables & placeholders" @("epic","core","needs design") `
"Define placeholder syntax for templates" @"
**User story.** As a template author, I want a documented placeholder syntax I can sprinkle into my ``.typ`` and ``.toml`` files, so that documents created from my template are pre-filled with the user's data.

**Description.** Decide and document the substitution syntax (proposed: ``{{ name }}`` with optional default ``{{ name | default("...") }}``), which file types are eligible (``.typ``, ``.toml``, ``.md``, ``.bib``...), and how to escape literal braces. Output: short ADR / proposal merged into ``docs/``.

**Acceptance criteria.**
- Proposal merged that defines syntax, escape rules, eligible file extensions, and built-in variable names.
- Examples in proposal showing both substituted and skipped files.
- ``FUTURE_WORK.md`` updated to point to the proposal.
"@

New-Issue "M1: Variables & placeholders" @("enhancement","core","cli") `
"Substitute built-in variables on new" @"
**User story.** As a user creating a new document, I want ``title``, ``author`` and ``date`` to be filled in automatically so that I don't have to edit ``metadata.typ`` by hand every time.

**Description.** Implement the engine that walks the copied document tree and substitutes the built-in variables. Skip binary files and honour the eligible extensions defined in the syntax proposal.

**Acceptance criteria.**
- ``typst-manager new my-doc -t article`` substitutes ``{{ title }}`` with ``my-doc`` (default), ``{{ author }}`` with ``cfg.author``, and ``{{ date }}`` with today's ISO date.
- Files without placeholders are byte-identical to the source.
- Unit tests cover: substitution, escape, missing variable, binary file skipped, large file streamed.
"@

New-Issue "M1: Variables & placeholders" @("enhancement","cli") `
"Add --title, --author and --date flags to new" @"
**User story.** As a user, I want to override the built-in variables on the command line, so that I can set the document title without editing files afterwards.

**Description.** Wire CLI flags into the substitution engine. Precedence: CLI flag > custom default in ``meta.toml`` > config default > computed default.

**Acceptance criteria.**
- ``--title``, ``--author``, ``--date`` accepted on ``new``.
- Help text documents the precedence order.
- Tests cover precedence and invalid date formats.
"@

New-Issue "M1: Variables & placeholders" @("enhancement","cli","ux") `
"Interactive prompts for required variables" @"
**User story.** As a user creating a document, I want to be prompted for variables marked ``required = true``, so that I never end up with a half-filled metadata block.

**Description.** When stdin is a TTY and a required variable was not passed, prompt the user. If stdin is not a TTY, fail fast with a clear error.

**Acceptance criteria.**
- Required variables without a value trigger a prompt in TTY mode.
- Non-TTY mode returns a non-zero exit code and prints the missing vars.
- ``--no-input`` flag forces non-interactive behaviour.
"@

New-Issue "M1: Variables & placeholders" @("enhancement","core") `
"Custom variables defined in meta.toml" @"
**User story.** As a template author, I want to declare arbitrary variables (e.g. ``course``, ``client``) in ``meta.toml``, so that users of my template are guided to set them.

**Description.** Extend ``meta.toml`` with a ``[variables]`` table. Each entry supports ``prompt``, ``default``, ``required``, ``choices``.

**Acceptance criteria.**
- ``typst-manager new`` prompts for all declared variables.
- ``--var key=value`` CLI flag passes arbitrary variables.
- Schema validation rejects unknown keys with a useful message.
"@

New-Issue "M1: Variables & placeholders" @("enhancement","core","needs design") `
"Version meta.toml schema" @"
**User story.** As a maintainer, I want ``meta.toml`` to declare a ``schema`` version, so that we can evolve the format without breaking existing user templates.

**Description.** Add ``schema = 1``. Refuse to load templates with an unknown future schema version. Existing files without the field are treated as schema 1.

**Acceptance criteria.**
- New blank templates write ``schema = 1``.
- Loader tolerates missing ``schema`` (treated as 1) but errors on ``schema = 999``.
- Migration policy documented in ``docs/``.
"@

# -----------------------------------------------------------------------------
# M2 — Compilation integration
# -----------------------------------------------------------------------------

New-Issue "M2: Compilation integration" @("enhancement","cli") `
"typst-manager build command" @"
**User story.** As a user, I want a single command that compiles my document, so that I don't have to remember to ``cd`` and run ``typst``.

**Description.** Run ``typst compile main.typ`` in the target directory (cwd if omitted). Pass-through arguments after ``--``.

**Acceptance criteria.**
- ``typst-manager build`` compiles the doc in ``cwd``.
- ``typst-manager build path/to/doc`` compiles in that path.
- ``typst-manager build -- --root /custom`` forwards args to ``typst``.
- Helpful error if ``typst`` is not on ``PATH``.
"@

New-Issue "M2: Compilation integration" @("enhancement","cli") `
"typst-manager watch command" @"
**User story.** As a user, I want to start a watch loop with one command, so that the PDF refreshes as I edit.

**Description.** Wraps ``typst watch main.typ``, mirrors ``build`` flags.

**Acceptance criteria.**
- Equivalent flags / pass-through behaviour as ``build``.
- Ctrl-C exits cleanly.
"@

New-Issue "M2: Compilation integration" @("enhancement","cli","ux") `
"Add --open and --compile flags to new" @"
**User story.** As a user, I want ``new`` to optionally open my editor and/or compile right after creating the document, so that I land directly in my workflow.

**Description.** ``--open`` opens the new doc folder in the configured editor. ``--compile`` runs ``typst-manager build`` on it. Both flags composable.

**Acceptance criteria.**
- Flags documented in ``--help``.
- A failing ``--compile`` does not delete the created document.
"@

New-Issue "M2: Compilation integration" @("ux","cli","good first issue") `
"Detect missing typst binary with friendly message" @"
**User story.** As a user without ``typst`` installed, I want a clear install hint instead of a cryptic error, so that I know what to do.

**Description.** Centralise the ``which typst`` check; link to ``https://typst.app/install`` and per-OS package managers in the error.

**Acceptance criteria.**
- ``build``, ``watch``, ``template preview``, ``new --compile`` use the same error path.
- Tests assert exit code (e.g. 127) and that the message includes the install URL.
"@

# -----------------------------------------------------------------------------
# M3 — Templates registry
# -----------------------------------------------------------------------------

New-Issue "M3: Templates registry" @("epic","registry","needs design") `
"Bootstrap public templates registry repository" @"
**User story.** As a maintainer, I want a public repo that hosts curated templates, so that users can ``pull`` them with one command.

**Description.** Single repo ``orvizz/typst-templates-registry`` with ``templates/<name>/`` and a generated ``registry.json``. Set up CONTRIBUTING.md and a PR template.

**Acceptance criteria.**
- Repository created and made public.
- At least three seed templates committed (e.g. ``article``, ``letter``, ``cv``).
- ``registry.json`` generated by CI on every push to ``main``.
- README explains scope and how to contribute.
"@

New-Issue "M3: Templates registry" @("registry","core","needs design") `
"Define registry meta.toml schema (license, version, typst-min)" @"
**User story.** As a registry curator, I want a stricter schema for published templates, so that users can rely on consistent metadata.

**Description.** Extend ``meta.toml`` for registry use: ``name``, ``description``, ``author``, ``license`` (SPDX), ``version`` (semver), ``tags``, ``categories``, ``typst-version-min``, ``homepage``.

**Acceptance criteria.**
- Schema documented in the registry repo.
- CLI validates registry metadata when running ``pull``.
- PR template lists the required fields.
"@

New-Issue "M3: Templates registry" @("registry","security","enhancement") `
"CI compiles every registry template" @"
**User story.** As a registry curator, I want every PR to be automatically compiled, so that broken templates never get merged.

**Description.** GitHub Actions workflow: install ``typst``, iterate ``templates/*``, run ``typst compile main.typ``. Fail the job on any error.

**Acceptance criteria.**
- Workflow runs on every PR and on ``main``.
- Pinned ``typst`` version (matrix optional later).
- Job summary lists compiled templates and durations.
"@

New-Issue "M3: Templates registry" @("enhancement","cli","registry") `
"typst-manager registry list / info / update" @"
**User story.** As a user, I want to browse the registry from the terminal, so that I can find a template before pulling it.

**Description.** Three subcommands sharing the cached ``registry.json`` in ``<data-dir>/cache/``. Network errors fall back to cache with a warning. ``update`` forces a refresh.

**Acceptance criteria.**
- ``registry list [--tag] [--search]`` prints a table.
- ``registry info <name>`` prints metadata + README excerpt.
- ``registry update`` refreshes the cache and reports diff.
"@

New-Issue "M3: Templates registry" @("enhancement","cli","registry","security") `
"typst-manager pull <name>" @"
**User story.** As a user, I want to download a registry template into my local store with one command, so that I can use it like any other.

**Description.** Resolve the template via ``registry.json``, download the archive, verify the SHA-256 checksum, extract into ``<data-dir>/templates/<name>/``, write ``meta.toml``. Refuse to overwrite existing templates unless ``--force`` (with confirmation prompt).

**Acceptance criteria.**
- ``pull`` works for at least one seed template end-to-end.
- Checksum mismatch aborts with a clear error and no partial writes.
- ``--as <local-name>`` allows installing under a different name.
- Remote templates do not run any post-install hooks.
"@

New-Issue "M3: Templates registry" @("enhancement","cli","registry") `
"typst-manager pull --upgrade" @"
**User story.** As a user with installed registry templates, I want to pull updates without losing my customisations, so that I can stay on the latest version safely.

**Description.** Compare local ``version`` with registry. If different, back up the existing folder to ``<data-dir>/templates/.backup/<name>-<timestamp>/`` and replace.

**Acceptance criteria.**
- No upgrade if versions match.
- Backup folder created on every upgrade.
- ``pull --upgrade`` without args upgrades all installed registry templates.
"@

New-Issue "M3: Templates registry" @("enhancement","cli","registry","needs design") `
"typst-manager publish (long-term)" @"
**User story.** As a template author, I want a guided flow to publish my local template to the registry, so that I don't have to hand-craft the PR.

**Description.** Validate metadata, fork the registry repo via ``gh`` (or print clear manual steps), open a draft PR with the template contents.

**Acceptance criteria.**
- Design doc with the proposed UX merged.
- Either implemented or explicitly deferred with rationale.
"@

New-Issue "M3: Templates registry" @("registry","enhancement","needs design") `
"Adapter for Typst Universe (stretch)" @"
**User story.** As a user, I want ``pull universe:<id>`` to install a template from Typst Universe, so that I don't have to choose between ecosystems.

**Description.** Investigate the Universe API and build a thin adapter that maps Universe entries onto our local model.

**Acceptance criteria.**
- Feasibility doc with API findings.
- Prototype command behind a feature flag.
"@

# -----------------------------------------------------------------------------
# M4 — Project website
# -----------------------------------------------------------------------------

New-Issue "M4: Project website" @("epic","web","needs design") `
"Pick stack and bootstrap the website" @"
**User story.** As a maintainer, I want a static site repository wired to GitHub Pages, so that we have a place to publish docs and the gallery.

**Description.** Decide between Astro / MkDocs Material / Docusaurus, initialise the project, deploy a placeholder Home and Install page.

**Acceptance criteria.**
- Site reachable at the chosen URL.
- CI auto-deploys on push to ``main``.
- Home page and Install page live.
"@

New-Issue "M4: Project website" @("web","docs","enhancement") `
"Auto-generate command reference from --help" @"
**User story.** As a user reading the website, I want the command reference to always match the installed CLI, so that I never see out-of-date docs.

**Description.** Script in CI that parses ``typst-manager <cmd> --help`` for every command and emits markdown into ``docs/commands/``.

**Acceptance criteria.**
- ``make docs`` regenerates the command pages.
- CI fails if generated output drifts from the committed copy.
"@

New-Issue "M4: Project website" @("web","docs") `
"Cookbook page with practical recipes" @"
**User story.** As a new user, I want recipes (formal letter, two-column paper, thesis...) so that I can pick up the tool quickly with realistic examples.

**Description.** Each recipe is a markdown page with: rendered preview, command sequence, and a ``pull`` link to the registry template.

**Acceptance criteria.**
- At least four recipes published at launch.
- Each recipe includes the exact commands needed.
"@

New-Issue "M4: Project website" @("web","registry","enhancement") `
"Gallery page consuming registry.json" @"
**User story.** As a user, I want a visual grid of all registry templates, so that I can pick one before I install it.

**Description.** Generate the gallery at build time from the registry repo's ``registry.json``. Each card shows thumbnail, name, description, and the ``pull`` command.

**Acceptance criteria.**
- Gallery built from the live ``registry.json`` on every site deploy.
- Filterable by tag / category.
- Empty registry gracefully shows a 'Be the first to publish' card.
"@

New-Issue "M4: Project website" @("web","enhancement","needs design") `
"Browser playground with typst.ts (stretch)" @"
**User story.** As a curious visitor, I want to compile a sample template in the browser, so that I can evaluate it without installing anything.

**Description.** Embed ``typst.ts`` (WASM build) on selected gallery pages.

**Acceptance criteria.**
- Spike report on bundle size and feasibility.
- Decision merged: implement now / defer / drop.
"@

# -----------------------------------------------------------------------------
# M5 — CLI quality of life
# -----------------------------------------------------------------------------

New-Issue "M5: CLI quality of life" @("enhancement","cli","ux") `
"typst-manager doctor" @"
**User story.** As a user with a broken setup, I want one command that diagnoses common problems, so that I can fix them without filing an issue.

**Description.** Check ``typst`` on PATH, configured editor is executable, data dir is writable, list invalid templates (no ``main.typ``), check registry cache freshness.

**Acceptance criteria.**
- Exits 0 only if every check passes.
- Each failure prints a remediation hint.
"@

New-Issue "M5: CLI quality of life" @("enhancement","cli","ux","good first issue") `
"Shell completions" @"
**User story.** As a shell user, I want tab-completion for commands, template names and editors, so that I type less and discover faster.

**Description.** ``typst-manager completions <bash|zsh|fish|powershell>`` prints the script. Document install instructions per shell.

**Acceptance criteria.**
- Four shells supported.
- Dynamic completion for template names (calls ``typst-manager template list --json``).
- Smoke tests in CI on at least one shell.
"@

New-Issue "M5: CLI quality of life" @("enhancement","cli","ux","good first issue") `
"Add more editors (helix, subl, emacs, zed)" @"
**User story.** As a user of `$EDITOR, I want it recognised by ``config set editor``, so that I don't have to fall back to ``system``.

**Description.** Extend ``KNOWN_EDITORS`` in ``platform.py``. Document the command used per editor. Allow free-form ``editor = '/path/to/bin'`` for unsupported cases.

**Acceptance criteria.**
- Each new editor opens the template folder reliably.
- README and man page list the new options.
"@

New-Issue "M5: CLI quality of life" @("enhancement","core","cli") `
"Tags, categories and filtered template list" @"
**User story.** As a user with many templates, I want to filter by tag or search by description, so that I find the right one quickly.

**Description.** Add ``tags = [...]`` and ``category = '...'`` to ``meta.toml``. Wire ``--tag``, ``--category``, ``--search`` and ``--json`` to ``template list``.

**Acceptance criteria.**
- Filters compose with AND semantics.
- ``--json`` output validated against a small JSON schema.
"@

New-Issue "M5: CLI quality of life" @("ux","cli","good first issue") `
"Global --quiet and --verbose flags" @"
**User story.** As a user piping output, I want to silence non-error messages, so that downstream tools see clean output.

**Description.** Centralise output through a small printer helper that honours the level. Keep ``OK`` / ``WARN`` / ``FAIL`` markers consistent.

**Acceptance criteria.**
- ``--quiet`` silences info and success lines but keeps errors.
- ``--verbose`` adds debug-level output (paths, file counts).
"@

New-Issue "M5: CLI quality of life" @("enhancement","cli","ux") `
"template show and template preview" @"
**User story.** As a user, I want to inspect a template before using it, so that I pick the right one without trial and error.

**Description.** ``show`` prints metadata and a file listing. ``preview`` compiles to PDF in a tmp dir and opens it. ``preview --thumbnail`` saves a PNG of page 1 next to ``meta.toml``.

**Acceptance criteria.**
- Both commands documented and tested.
- Compilation failures surface the ``typst`` error verbatim.
"@

# -----------------------------------------------------------------------------
# M6 — Import / export / backup
# -----------------------------------------------------------------------------

New-Issue "M6: Import / export / backup" @("enhancement","cli","core") `
"template export and template import" @"
**User story.** As a user, I want to package and share a template as a single file, so that I can send it to a colleague or move it to another machine.

**Description.** ``export`` writes a deterministic zip with a manifest. ``import`` validates the manifest, refuses overwrites, supports ``--as <name>``.

**Acceptance criteria.**
- Round-trip export/import is byte-identical.
- Manifest includes schema version and SHA-256 of the payload.
"@

New-Issue "M6: Import / export / backup" @("enhancement","cli") `
"backup and restore" @"
**User story.** As a user, I want to back up my whole data dir to a single archive, so that I can move setups between machines and roll back from accidents.

**Description.** ``backup --out file.tar.gz`` archives ``<data-dir>``. ``restore file.tar.gz`` extracts it; refuses to overwrite a non-empty data dir without ``--force``.

**Acceptance criteria.**
- Archive includes templates, config and a manifest.
- Restore on an empty data dir reproduces the original setup.
"@

New-Issue "M6: Import / export / backup" @("enhancement","cli","needs design") `
"Optional git tracking of the templates dir" @"
**User story.** As an advanced user, I want my templates dir to be a git repo, so that I get free history and remote sync.

**Description.** Opt-in via ``config set track-git true``. After every template-mutating command, auto-commit with a generated message.

**Acceptance criteria.**
- Off by default; clear opt-in flow.
- Commits include the command name (e.g. ``template create article: add boilerplate``).
- Tests run with a stub git binary.
"@

Write-Host ""
Write-Host "Done." -ForegroundColor Green
