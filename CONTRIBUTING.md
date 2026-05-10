# Contributing to typst-manager

Thanks for taking the time to contribute! This document describes how to
get a development environment up, the conventions we follow, and the
process for proposing changes.

If you are looking for ideas on what to work on, see
[`BACKLOG.md`](./BACKLOG.md) or browse the
[open issues](https://github.com/orvizz/typst-manager/issues) — anything
labelled `good first issue` is a friendly entry point.

---

## Code of Conduct

By participating in this project you agree to abide by the
[Code of Conduct](./CODE_OF_CONDUCT.md).

## Reporting bugs and proposing features

- **Bugs:** open an issue using the *Bug report* template. Please
  include the version (`typst-manager --version` once exposed, or the
  PyPI version), your OS, and a minimal reproduction.
- **Features:** open an issue using the *Feature request* template.
  Describe the user problem first, the proposed solution second, and
  any alternatives you considered.
- **Security issues:** **do not** open a public issue. Follow the
  process described in [`SECURITY.md`](./SECURITY.md).
- **Open questions and design discussions:** prefer GitHub Discussions
  if enabled, otherwise an issue with the `needs design` label.

---

## Development setup

### Prerequisites

- Python 3.9 or higher.
- Git.
- (Optional) `typst` on `PATH` if you want to compile sample documents
  end-to-end.

### Clone and install

```bash
git clone https://github.com/orvizz/typst-manager
cd typst-manager
python -m venv .venv

# Activate the virtual environment
# Linux / macOS
source .venv/bin/activate
# Windows (PowerShell)
.\.venv\Scripts\Activate.ps1

# Install the package in editable mode together with dev dependencies
pip install -e ".[dev]"
```

### Running the CLI

```bash
typst-manager --help
```

Because the package is installed editable, edits to the source tree are
picked up immediately.

### Running the tests

```bash
pytest tests/
```

Add the `-v` flag for verbose output. Coverage is available via
`pytest --cov=typst_manager`.

The test suite isolates itself from your real data directory by setting
`TYPST_MANAGER_HOME` to a temporary path — your local templates are
never touched.

---

## Branch model

- `main` is the integration branch. It is **protected**: no direct
  pushes; PRs and a code-owner review are required.
- Feature work happens on short-lived branches off `main`. Suggested
  naming:
  - `feat/<short-description>` for new features.
  - `fix/<short-description>` for bug fixes.
  - `docs/<short-description>` for documentation-only changes.
  - `chore/<short-description>` for tooling, CI, refactors with no
    behaviour change.
- Once a `dev` branch is introduced (see backlog), feature work will
  target `dev` and `dev` will be promoted to `main` on release.

## Commit messages

We follow a light-touch convention loosely based on
[Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <short imperative summary>

<optional longer body explaining the why, not the what>

<optional footer with "Refs #N" / "Closes #N">
```

Common types: `feat`, `fix`, `docs`, `refactor`, `test`, `chore`,
`build`, `ci`. Scope is optional but useful — `cli`, `core`,
`registry`, `web`. Examples:

- `feat(cli): add typst-manager build command (closes #7)`
- `fix(core): skip binary files when substituting placeholders`
- `docs: clarify --out behaviour in README`

Squash-merging on GitHub will collapse commits, so feel free to commit
freely on your branch — only the squashed message ends up in `main`.

## Pull request process

1. Fork the repository (or create a branch if you have push access).
2. Make your changes on a feature branch.
3. Add or update tests for any changed behaviour.
4. Run `pytest tests/` locally and make sure it is green.
5. Update documentation that the change touches:
   - The `--help` text of any new flag (it is auto-rendered by
     `argparse`).
   - The `man` page (`typst_manager/man/typst-manager.1`) when
     applicable.
   - The `README.md` if user-visible behaviour changes.
6. Open a pull request against `main`. The PR template will guide you
   through the rest.
7. Wait for the CI checks to pass and for a code-owner review. The
   maintainer (`@orvizz`) is the required reviewer.
8. Address review comments by pushing more commits to the same branch.
   Avoid force-pushing during review unless asked, since it makes
   incremental review harder.

### What gets merged

PRs are more likely to be merged quickly when they:

- **Stay focused.** One change per PR. Refactors and renames belong in
  separate PRs from feature work.
- **Include tests.** Especially for `core` and `cli` changes.
- **Preserve the "no lock-in" promise.** Templates remain plain folders
  on disk; new features should not require a database, daemon, or
  external service to work locally.
- **Are friendly to all supported platforms** (Linux, macOS, Windows).
  Use `pathlib.Path`, avoid hard-coded path separators, keep shell
  invocations cross-platform or guard them.

## Style

- Python is formatted as standard PEP 8 — 4-space indentation, snake
  case, docstrings on public functions and classes.
- Prefer `pathlib.Path` over `os.path`.
- Type hints are appreciated on new public functions.
- Avoid adding heavy dependencies; the project deliberately stays close
  to the standard library.
- For user-visible CLI output, keep the `✓` / `⚠` / `✗` markers and the
  tone consistent with the rest of the codebase.

## Releasing

Releases are cut by the maintainer. The high-level steps are:

1. Bump the version in `pyproject.toml` following SemVer.
2. Update `CHANGELOG.md` (when introduced) and any version-specific
   docs.
3. Tag the release: `git tag -s vX.Y.Z -m "Release vX.Y.Z"`.
4. Push the tag and let the release workflow build and publish to PyPI.

If you would like to help with releases, open an issue and we can
discuss what that looks like.

---

## Recognition

Every contributor is welcome and appreciated. Significant contributions
will be acknowledged in the release notes.

Thank you for helping make `typst-manager` better!
