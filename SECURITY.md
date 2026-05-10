# Security policy

Thanks for taking the time to help keep `typst-manager` and its users safe.

## Supported versions

`typst-manager` is in active development. Only the **latest released version**
on PyPI receives security fixes. Pre-1.0 releases may introduce breaking
changes between minor versions; we will note any security implications in
the changelog.

| Version    | Supported          |
| ---------- | ------------------ |
| latest     | :white_check_mark: |
| < latest   | :x:                |

## Reporting a vulnerability

**Please do not open a public issue for security problems.**

The preferred channel is GitHub's private vulnerability reporting:

1. Go to <https://github.com/orvizz/typst-manager/security/advisories/new>.
2. Fill in the details. The report is visible only to the maintainers.

If for any reason you cannot use that channel, send an email to the
maintainer listed in `pyproject.toml`. Please include:

- A description of the issue and its impact.
- Steps to reproduce, ideally with a minimal proof of concept.
- The version of `typst-manager` you tested against.
- Any suggested mitigation, if you have one.

## What to expect

- Acknowledgement within **5 business days** of receiving the report.
- A short triage where we confirm the problem and assess its impact.
- A fix and a coordinated release; we aim to ship within **30 days** of
  acknowledgement for high-severity issues, sooner when feasible.
- Public disclosure after the fix is released, with credit to the
  reporter unless they prefer to remain anonymous.

## Scope

In-scope:

- The `typst-manager` Python package and its CLI entry point.
- The official installation scripts (`install.sh`, `install.ps1`).
- Any official template registry and its installation flow (`pull`,
  `publish`) once published.

Out of scope:

- Vulnerabilities in third-party dependencies — please report those
  upstream. We will track and bump versions as patches become available.
- Issues that require physical access to a user's machine, or that
  rely on the user running arbitrary attacker-supplied code.
- Social-engineering of maintainers.

## Hardening guidance for users

- Install `typst-manager` from PyPI or directly from this repository's
  release tags only. Do not install from forks unless you have audited
  them.
- Review templates pulled from third-party sources before compiling
  them. A Typst document can read local files via `read()` and `image()`
  paths.
- Keep `typst` and `typst-manager` up to date: `pipx upgrade typst-manager`.

Thank you for helping keep the ecosystem safe.
