# Backlog — typst-manager

This backlog turns `FUTURE_WORK.md` into a list of GitHub issues ready to be
filed. Each entry contains:

- **Title** — issue title (use as-is on GitHub).
- **Labels** — comma-separated list of labels to attach.
- **Milestone** — proposed milestone (epic).
- **User story** — `As a … I want … so that …`.
- **Description** — short context.
- **Acceptance criteria** — bullet list of done conditions.

The companion script `scripts/create_github_issues.sh` reads a derived form of
this file (encoded inline in the script) and creates the issues using the
official `gh` CLI.

---

## Milestones (epics)

| Milestone                       | Description                                            |
| ------------------------------- | ------------------------------------------------------ |
| `M1: Variables & placeholders`  | Substitute title/author/date and custom vars on `new`. |
| `M2: Compilation integration`   | Wrap `typst compile` / `typst watch` in the CLI.       |
| `M3: Templates registry`        | Public registry + `pull` / `publish` commands.         |
| `M4: Project website`           | Static site with docs, gallery and cookbook.           |
| `M5: CLI quality of life`       | Doctor, completions, more editors, tags, JSON output.  |
| `M6: Import / export / backup`  | Move templates around, take backups, restore.          |

## Labels

| Label             | Color hint | Purpose                                        |
| ----------------- | ---------- | ---------------------------------------------- |
| `enhancement`     | green      | New feature.                                   |
| `epic`            | purple     | Tracks a large area of work.                   |
| `cli`             | blue       | CLI-level change.                              |
| `core`            | blue       | Core library (template store, config…).        |
| `registry`        | orange     | Templates registry & `pull` / `publish`.       |
| `web`             | teal       | Project website / docs site.                   |
| `docs`            | grey       | Documentation, READMEs, man page.              |
| `ux`              | yellow     | Quality-of-life and ergonomics.                |
| `security`        | red        | Anything with security implications.           |
| `good first issue`| light blue | Approachable for new contributors.             |
| `needs design`    | pink       | Requires a design / proposal before coding.    |

---

## Issues

### M1: Variables & placeholders

#### #1 — Define placeholder syntax for templates

- **Labels:** `epic`, `core`, `needs design`
- **Milestone:** `M1: Variables & placeholders`
- **User story:** As a template author, I want a documented placeholder
  syntax I can sprinkle into my `.typ` and `.toml` files, so that
  documents created from my template are pre-filled with the user's data.
- **Description:** Decide and document the substitution syntax (proposed:
  `{{ name }}` with optional default `{{ name | default("…") }}`),
  which file types are eligible (`.typ`, `.toml`, `.md`, `.bib`…), and how
  to escape literal braces. This issue tracks the design write-up that
  unblocks the implementation tickets below. Output: short ADR /
  proposal merged into `docs/`.
- **Acceptance criteria:**
  - Proposal merged that defines syntax, escape rules, eligible file
    extensions, and built-in variable names.
  - Examples in proposal showing both substituted and skipped files.
  - Link from `FUTURE_WORK.md` updated to point to the proposal.

#### #2 — Substitute built-in variables on `new`

- **Labels:** `enhancement`, `core`, `cli`
- **Milestone:** `M1: Variables & placeholders`
- **User story:** As a user creating a new document, I want
  `title`, `author` and `date` to be filled in automatically so that I
  don't have to edit `metadata.typ` by hand every time.
- **Description:** Implement the engine that walks the copied document
  tree and substitutes the built-in variables. Skip binary files and
  honour the eligible extensions from issue #1.
- **Acceptance criteria:**
  - `typst-manager new my-doc -t article` substitutes `{{ title }}` with
    `my-doc` (default), `{{ author }}` with `cfg.author`, and
    `{{ date }}` with today's ISO date.
  - Files without placeholders are byte-identical to the source.
  - Unit tests cover: substitution, escape, missing variable, binary
    file skipped, very large file streamed (no full-load).

#### #3 — Add `--title`, `--author` and `--date` flags to `new`

- **Labels:** `enhancement`, `cli`
- **Milestone:** `M1: Variables & placeholders`
- **User story:** As a user, I want to override the built-in variables on
  the command line, so that I can set the document title without editing
  files afterwards.
- **Description:** Wire CLI flags into the substitution engine from #2.
  Precedence: CLI flag > custom default in `meta.toml` > config default
  > computed default (e.g. today for `date`, doc name for `title`).
- **Acceptance criteria:**
  - `--title`, `--author`, `--date` accepted on `new`.
  - Help text documents the precedence order.
  - Tests cover precedence and invalid date formats.

#### #4 — Interactive prompts for required variables

- **Labels:** `enhancement`, `cli`, `ux`
- **Milestone:** `M1: Variables & placeholders`
- **User story:** As a user creating a document, I want to be prompted
  for variables marked `required = true`, so that I never end up with a
  half-filled metadata block.
- **Description:** When stdin is a TTY and a required variable was not
  passed, prompt the user. If stdin is not a TTY, fail fast with a
  clear error.
- **Acceptance criteria:**
  - Required variables without a value trigger a prompt in TTY mode.
  - Non-TTY mode returns a non-zero exit code and prints the missing vars.
  - `--no-input` flag to force non-interactive behaviour.

#### #5 — Custom variables defined in `meta.toml`

- **Labels:** `enhancement`, `core`
- **Milestone:** `M1: Variables & placeholders`
- **User story:** As a template author, I want to declare arbitrary
  variables (e.g. `course`, `client`) in `meta.toml`, so that users of
  my template are guided to set them.
- **Description:** Extend `meta.toml` with a `[variables]` table. Each
  entry supports `prompt`, `default`, `required`, `choices`.
- **Acceptance criteria:**
  - `typst-manager new` prompts for all declared variables (respecting
    #4 rules).
  - `--var key=value` CLI flag passes arbitrary variables.
  - `meta.toml` schema validation rejects unknown keys with a useful
    message.

#### #6 — Version `meta.toml` schema

- **Labels:** `enhancement`, `core`, `needs design`
- **Milestone:** `M1: Variables & placeholders`
- **User story:** As a maintainer, I want `meta.toml` to declare a
  `schema` version, so that we can evolve the format without breaking
  existing user templates.
- **Description:** Add `schema = 1` to the file and refuse to load
  templates with an unknown future schema version. Existing templates
  without the field are treated as schema 1 for backwards compatibility.
- **Acceptance criteria:**
  - New blank templates write `schema = 1`.
  - Loader tolerates missing `schema` (treated as 1) but errors on
    `schema = 999`.
  - Migration policy documented in `docs/`.

---

### M2: Compilation integration

#### #7 — `typst-manager build` command

- **Labels:** `enhancement`, `cli`
- **Milestone:** `M2: Compilation integration`
- **User story:** As a user, I want a single command that compiles my
  document, so that I don't have to remember to `cd` and run `typst`.
- **Description:** Run `typst compile main.typ` in the target directory
  (current dir if omitted). Pass-through arguments after `--`.
- **Acceptance criteria:**
  - `typst-manager build` compiles the doc in `cwd`.
  - `typst-manager build path/to/doc` compiles in that path.
  - `typst-manager build -- --root /custom` forwards args to `typst`.
  - Helpful error if `typst` is not on `PATH`.

#### #8 — `typst-manager watch` command

- **Labels:** `enhancement`, `cli`
- **Milestone:** `M2: Compilation integration`
- **User story:** As a user, I want to start a watch loop with one
  command, so that the PDF refreshes as I edit.
- **Description:** Wraps `typst watch main.typ`, mirrors `build` flags.
- **Acceptance criteria:**
  - Equivalent flags / pass-through behaviour as #7.
  - Ctrl-C exits cleanly.

#### #9 — `--open` and `--compile` flags on `new`

- **Labels:** `enhancement`, `cli`, `ux`
- **Milestone:** `M2: Compilation integration`
- **User story:** As a user, I want `new` to optionally open my editor
  and/or compile right after creating the document, so that I land
  directly in my workflow.
- **Description:** `--open` opens the new doc folder in the configured
  editor. `--compile` runs `typst-manager build` on it. Both flags
  composable.
- **Acceptance criteria:**
  - Flags documented in `--help`.
  - `--compile` failure does not delete the created document.

#### #10 — Detect missing `typst` binary with friendly message

- **Labels:** `ux`, `cli`, `good first issue`
- **Milestone:** `M2: Compilation integration`
- **User story:** As a user without `typst` installed, I want a clear
  install hint instead of a cryptic error, so that I know what to do.
- **Description:** Centralise the `which typst` check, link to
  `https://typst.app/install` and the per-OS package managers in the
  error.
- **Acceptance criteria:**
  - `build`, `watch`, `template preview`, `new --compile` all use the
    same error path.
  - Tests assert the exit code (e.g. 127) and that the message includes
    the install URL.

---

### M3: Templates registry

#### #11 — Bootstrap public templates registry repository

- **Labels:** `epic`, `registry`, `needs design`
- **Milestone:** `M3: Templates registry`
- **User story:** As a maintainer, I want a public repo that hosts
  curated templates, so that users can `pull` them with one command.
- **Description:** Start with option A from `FUTURE_WORK.md`: a single
  repo `orvizz/typst-templates-registry` with `templates/<name>/` and a
  generated `registry.json`. Set up CONTRIBUTING.md and a PR template.
- **Acceptance criteria:**
  - Repository created and made public.
  - At least three seed templates committed (e.g. `article`, `letter`,
    `cv`) — can re-use the boilerplate already in
    `template_store.py`.
  - `registry.json` generated by CI on every push to `main`.
  - README explains scope and how to contribute.

#### #12 — Define registry `meta.toml` schema (license, version, typst-min)

- **Labels:** `registry`, `core`, `needs design`
- **Milestone:** `M3: Templates registry`
- **User story:** As a registry curator, I want a stricter schema for
  published templates, so that users can rely on consistent metadata.
- **Description:** Extend `meta.toml` for registry use:
  `name`, `description`, `author`, `license` (SPDX), `version` (semver),
  `tags`, `categories`, `typst-version-min`, `homepage`.
- **Acceptance criteria:**
  - Schema documented in the registry repo.
  - CLI validates registry metadata when running `pull`.
  - PR template in registry repo lists the required fields.

#### #13 — CI compiles every registry template

- **Labels:** `registry`, `security`, `enhancement`
- **Milestone:** `M3: Templates registry`
- **User story:** As a registry curator, I want every PR to be
  automatically compiled, so that broken templates never get merged.
- **Description:** GitHub Actions workflow: install `typst`, iterate
  `templates/*`, run `typst compile main.typ`. Fail the job on any error.
- **Acceptance criteria:**
  - Workflow runs on every PR and on `main`.
  - Pinned `typst` version (matrix optional later).
  - Job summary lists compiled templates and durations.

#### #14 — `typst-manager registry list / info / update`

- **Labels:** `enhancement`, `cli`, `registry`
- **Milestone:** `M3: Templates registry`
- **User story:** As a user, I want to browse the registry from the
  terminal, so that I can find a template before pulling it.
- **Description:** Three subcommands sharing the cached `registry.json`
  in `<data-dir>/cache/`. Network errors fall back to cache with a
  warning. `update` forces a refresh.
- **Acceptance criteria:**
  - `registry list [--tag] [--search]` prints a table.
  - `registry info <name>` prints metadata + README excerpt.
  - `registry update` refreshes the cache and reports diff (added /
    removed / updated).

#### #15 — `typst-manager pull <name>`

- **Labels:** `enhancement`, `cli`, `registry`, `security`
- **Milestone:** `M3: Templates registry`
- **User story:** As a user, I want to download a registry template into
  my local store with one command, so that I can use it like any other.
- **Description:** Resolve the template via `registry.json`, download
  the archive, verify the SHA-256 checksum, extract into
  `<data-dir>/templates/<name>/`, write `meta.toml`. Refuse to overwrite
  existing templates unless `--force` (with confirmation prompt).
- **Acceptance criteria:**
  - `pull` works for at least one seed template end-to-end.
  - Checksum mismatch aborts with clear error and no partial writes.
  - `--as <local-name>` allows installing under a different name.
  - Templates remote do not run any post-install hooks.

#### #16 — `typst-manager pull --upgrade`

- **Labels:** `enhancement`, `cli`, `registry`
- **Milestone:** `M3: Templates registry`
- **User story:** As a user with installed registry templates, I want to
  pull updates without losing my customisations, so that I can stay on
  the latest version safely.
- **Description:** Compare local `version` with registry. If different,
  back up the existing folder to
  `<data-dir>/templates/.backup/<name>-<timestamp>/` and replace.
- **Acceptance criteria:**
  - No upgrade if versions match.
  - Backup folder created on every upgrade.
  - `pull --upgrade` without args upgrades all installed registry
    templates.

#### #17 — `typst-manager publish` (long-term)

- **Labels:** `enhancement`, `cli`, `registry`, `needs design`
- **Milestone:** `M3: Templates registry`
- **User story:** As a template author, I want a guided flow to publish
  my local template to the registry, so that I don't have to
  hand-craft the PR.
- **Description:** Validate metadata, fork the registry repo via `gh`
  (or print clear manual steps), open a draft PR with the template
  contents. Out of scope for the MVP but worth scoping early.
- **Acceptance criteria:**
  - Design doc with the proposed UX merged.
  - Either implemented or explicitly deferred with rationale.

#### #18 — Adapter for Typst Universe (stretch)

- **Labels:** `registry`, `enhancement`, `needs design`
- **Milestone:** `M3: Templates registry`
- **User story:** As a user, I want `pull universe:<id>` to install a
  template from Typst Universe, so that I don't have to choose between
  ecosystems.
- **Description:** Investigate the Universe API and build a thin adapter
  that maps Universe entries onto our local model.
- **Acceptance criteria:**
  - Feasibility doc with API findings.
  - Prototype command behind a feature flag.

---

### M4: Project website

#### #19 — Pick stack and bootstrap site

- **Labels:** `epic`, `web`, `needs design`
- **Milestone:** `M4: Project website`
- **User story:** As a maintainer, I want a static site repository wired
  to GitHub Pages, so that we have a place to publish docs and the
  gallery.
- **Description:** Decide between Astro / MkDocs Material / Docusaurus,
  initialise the project, deploy a placeholder Home and Install page.
- **Acceptance criteria:**
  - Site reachable at the chosen URL.
  - CI auto-deploys on push to `main`.
  - At minimum: Home page and Install page live.

#### #20 — Auto-generate command reference from `--help`

- **Labels:** `web`, `docs`, `enhancement`
- **Milestone:** `M4: Project website`
- **User story:** As a user reading the website, I want the command
  reference to always match the installed CLI, so that I never see
  out-of-date docs.
- **Description:** Script in CI that parses `typst-manager <cmd> --help`
  for every command and emits markdown into `docs/commands/`.
- **Acceptance criteria:**
  - `make docs` regenerates the command pages.
  - CI fails if the generated output drifts from the committed copy.

#### #21 — Cookbook page with practical recipes

- **Labels:** `web`, `docs`
- **Milestone:** `M4: Project website`
- **User story:** As a new user, I want recipes (formal letter, two-column
  paper, thesis…) so that I can pick up the tool quickly with realistic
  examples.
- **Description:** Each recipe is a markdown page with: rendered
  preview, command sequence, and a `pull` link to the registry template.
- **Acceptance criteria:**
  - At least four recipes published at launch.
  - Each recipe includes the exact commands needed.

#### #22 — Gallery page consuming `registry.json`

- **Labels:** `web`, `registry`, `enhancement`
- **Milestone:** `M4: Project website`
- **User story:** As a user, I want a visual grid of all registry
  templates, so that I can pick one before I install it.
- **Description:** Generate the gallery at build time from the
  registry repo's `registry.json`. Each card shows thumbnail, name,
  description, and the `pull` command.
- **Acceptance criteria:**
  - Gallery built from the live `registry.json` on every site deploy.
  - Filterable by tag / category.
  - Empty registry gracefully shows a "Be the first to publish" card.

#### #23 — Browser playground with `typst.ts` (stretch)

- **Labels:** `web`, `enhancement`, `needs design`
- **Milestone:** `M4: Project website`
- **User story:** As a curious visitor, I want to compile a sample
  template in the browser, so that I can evaluate it without installing
  anything.
- **Description:** Embed `typst.ts` (WASM build) on selected gallery
  pages. Out of scope for MVP — design only.
- **Acceptance criteria:**
  - Spike report on bundle size and feasibility.
  - Decision merged: implement now / defer / drop.

---

### M5: CLI quality of life

#### #24 — `typst-manager doctor`

- **Labels:** `enhancement`, `cli`, `ux`
- **Milestone:** `M5: CLI quality of life`
- **User story:** As a user with a broken setup, I want one command that
  diagnoses common problems, so that I can fix them without filing an
  issue.
- **Description:** Check `typst` on PATH, configured editor is
  executable, data dir is writable, list invalid templates (no
  `main.typ`), check registry cache freshness.
- **Acceptance criteria:**
  - Exits 0 only if every check passes.
  - Each failure prints a remediation hint.

#### #25 — Shell completions

- **Labels:** `enhancement`, `cli`, `ux`, `good first issue`
- **Milestone:** `M5: CLI quality of life`
- **User story:** As a shell user, I want tab-completion for commands,
  template names and editors, so that I type less and discover faster.
- **Description:** `typst-manager completions <bash|zsh|fish|powershell>`
  prints the script. Document install instructions per shell.
- **Acceptance criteria:**
  - Four shells supported.
  - Dynamic completion for template names (calls
    `typst-manager template list --json`).
  - Smoke tests in CI on at least one shell.

#### #26 — Add more editors (`helix`, `subl`, `emacs`, `zed`)

- **Labels:** `enhancement`, `cli`, `ux`, `good first issue`
- **Milestone:** `M5: CLI quality of life`
- **User story:** As a user of $EDITOR, I want it recognised by
  `config set editor`, so that I don't have to fall back to `system`.
- **Description:** Extend `KNOWN_EDITORS` in `platform.py`. Document the
  command used per editor. Allow a free-form `editor = "/path/to/bin"`
  for unsupported cases.
- **Acceptance criteria:**
  - Each new editor opens the template folder reliably.
  - README and man page list the new options.

#### #27 — Tags, categories and filtered `template list`

- **Labels:** `enhancement`, `core`, `cli`
- **Milestone:** `M5: CLI quality of life`
- **User story:** As a user with many templates, I want to filter by tag
  or search by description, so that I find the right one quickly.
- **Description:** Add `tags = [...]` and `category = "..."` to
  `meta.toml`. Wire `--tag`, `--category`, `--search` and `--json` to
  `template list`.
- **Acceptance criteria:**
  - Filters compose with AND semantics.
  - `--json` output validated against a small JSON schema.

#### #28 — Global `--quiet` and `--verbose` flags

- **Labels:** `ux`, `cli`, `good first issue`
- **Milestone:** `M5: CLI quality of life`
- **User story:** As a user piping output, I want to silence non-error
  messages, so that downstream tools see clean output.
- **Description:** Centralise output through a small printer helper that
  honours the level. Keep `✓` / `⚠` / `✗` consistent.
- **Acceptance criteria:**
  - `--quiet` silences info and success lines but keeps errors.
  - `--verbose` adds debug-level output (paths, file counts).

#### #29 — `template show <name>` and `template preview <name>`

- **Labels:** `enhancement`, `cli`, `ux`
- **Milestone:** `M5: CLI quality of life`
- **User story:** As a user, I want to inspect a template before using
  it, so that I pick the right one without trial and error.
- **Description:** `show` prints metadata and a file listing. `preview`
  compiles to PDF in a tmp dir and opens it. `preview --thumbnail`
  saves a PNG of page 1 next to `meta.toml`.
- **Acceptance criteria:**
  - Both commands documented and tested.
  - Compilation failures surface the `typst` error verbatim.

---

### M6: Import / export / backup

#### #30 — `template export` and `template import`

- **Labels:** `enhancement`, `cli`, `core`
- **Milestone:** `M6: Import / export / backup`
- **User story:** As a user, I want to package and share a template as
  a single file, so that I can send it to a colleague or move it to
  another machine.
- **Description:** `export` writes a deterministic zip with a manifest.
  `import` validates the manifest, refuses overwrites, supports
  `--as <name>`.
- **Acceptance criteria:**
  - Round-trip export/import is byte-identical.
  - Manifest includes schema version (#6) and SHA-256 of the payload.

#### #31 — `backup` and `restore`

- **Labels:** `enhancement`, `cli`
- **Milestone:** `M6: Import / export / backup`
- **User story:** As a user, I want to back up my whole data dir to a
  single archive, so that I can move setups between machines and roll
  back from accidents.
- **Description:** `backup --out file.tar.gz` archives `<data-dir>`.
  `restore file.tar.gz` extracts it; refuses to overwrite a non-empty
  data dir without `--force`.
- **Acceptance criteria:**
  - Archive includes templates, config and a manifest.
  - Restore on an empty data dir reproduces the original setup.

#### #32 — Optional git tracking of the templates dir

- **Labels:** `enhancement`, `cli`, `needs design`
- **Milestone:** `M6: Import / export / backup`
- **User story:** As an advanced user, I want my templates dir to be a
  git repo, so that I get free history and remote sync.
- **Description:** Opt-in via `config set track-git true`. After every
  template-mutating command, auto-commit with a generated message.
  Document caveats: requires `git` installed, may surprise users with
  large repos.
- **Acceptance criteria:**
  - Off by default; clear opt-in flow.
  - Commits include the command name, e.g.
    `template create article: add boilerplate`.
  - Tests run with a stub git binary.

---

## Issue ordering (suggested)

Recommended order to actually file / work on:

1. M1 issues #1–#6 (variables, the highest impact-per-LOC).
2. M3 issues #11–#15 (registry MVP unblocks the gallery).
3. M4 issues #19–#22 (website that surfaces the registry).
4. M2 issues #7–#10 (compilation wraps; useful but not blocking).
5. M5 issues #24–#29 (polish once core stories land).
6. M6 issues #30–#32 (last; quality-of-life rather than features).

---

*Generated from `FUTURE_WORK.md`. Update both files when scope changes.*
