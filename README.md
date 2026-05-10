# typst-manager

A command-line tool to manage [Typst](https://typst.app) templates and documents.

Create a personal library of reusable templates. Spin up new documents from
them in seconds. Everything lives in plain folders — no database, no lock-in.

---

## Installation

**Requirements:** Python 3.9 or higher.

### Linux / macOS

```bash
curl -sSL https://raw.githubusercontent.com/orvizz/typst-manager/main/install.sh | bash
```

Or with pipx:

```bash
pipx install typst-manager
```

### Windows

```powershell
irm https://raw.githubusercontent.com/orvizz/typst-manager/main/install.ps1 | iex
```

Or with pipx:

```powershell
pipx install typst-manager
```

### From source

```bash
git clone https://github.com/orvizz/typst-manager
cd typst-manager
pip install -e .
```

### Verify

```bash
typst-manager --help
```

---

## Where files are stored

| OS      | Default location                               |
| ------- | ---------------------------------------------- |
| Linux   | `~/.local/share/typst-manager/`                |
| macOS   | `~/Library/Application Support/typst-manager/` |
| Windows | `%APPDATA%\typst-manager\`                     |

Override at any time with the `TYPST_MANAGER_HOME` environment variable:

```bash
export TYPST_MANAGER_HOME=/path/to/custom/dir   # Linux / macOS
set TYPST_MANAGER_HOME=C:\path\to\custom\dir    # Windows
```

---

## Quick start

```bash
# 1. Create a blank template (opens in your editor)
typst-manager template create article

# 2. Or save a document you're already working on as a template
typst-manager template create letter --from ~/docs/my-letter/

# 3. List your templates
typst-manager template list

# 4. Create a new document from a template
typst-manager new my-report --template article
```

---

## Commands

### `typst-manager new`

Create a new document from a template. The template is copied into a new
folder inside the current directory (or `--out` if given).

```
typst-manager new <name> --template <template-name> [--out <dir>]
```

```bash
typst-manager new quarterly-report --template report
typst-manager new thesis --template academic --out ~/documents
```

---

### `typst-manager template`

#### `create`

Create a new template. Four modes:

```bash
# Start from a boilerplate (main.typ, template.typ, metadata.typ, sources.bib)
typst-manager template create <name>

# Save an existing document folder as a template (compiled .pdf files excluded)
typst-manager template create <name> --from path/to/document/

# Import a single .typ file as the template's main.typ
typst-manager template create <name> --from path/to/file.typ

# Duplicate an existing template
typst-manager template create <name> --from <other-template-name>
```

| Option                | Description                                            |
| --------------------- | ------------------------------------------------------ |
| `--from <source>`     | Directory, `.typ` file, or existing template name      |
| `-d`, `--description` | Short description shown in `template list`             |

#### `edit`

Open a template's folder in your configured editor.

```bash
typst-manager template edit <name>
```

#### `rename`

Rename a template.

```bash
typst-manager template rename <name> <new-name>
```

#### `delete`

Delete a template permanently.

```bash
typst-manager template delete <name>
typst-manager template delete <name> --yes   # skip confirmation
```

#### `list`

List all templates with their descriptions.

```bash
typst-manager template list
```

```
NAME                 DESCRIPTION
------------------------------------------------------------
academic             Two-column academic paper
article              Clean article with header
report               Formal report with cover page
```

---

### `typst-manager config`

#### `show`

Print current configuration and storage paths.

```bash
typst-manager config show
```

#### `set`

Change a configuration value.

```bash
typst-manager config set editor nvim
typst-manager config set author "Jane Doe"
```

| Key      | Values                          | Description                          |
| -------- | ------------------------------- | ------------------------------------ |
| `editor` | `system`, `vim`, `nvim`, `code` | Editor used to open template folders |
| `author` | any string                      | Stored for your reference            |

---

### `typst-manager man`

Open the full reference manual.

```bash
typst-manager man
```

On Linux and macOS the man page is opened with `man(1)`. On Windows it is
printed to the terminal.

---

## Template structure

When you create a blank template, typst-manager generates a ready-to-use
boilerplate:

```
<data-dir>/templates/<name>/
├── main.typ        entry point — imports template.typ and metadata.typ
├── template.typ    page layout and typographic styles
├── metadata.typ    document metadata (title, author, date…)
├── sources.bib     BibTeX bibliography with a sample entry
└── meta.toml       template name and description (not copied to documents)
```

---

## Configuration file

Stored at `<data-dir>/config.toml`:

```toml
[core]
editor = "nvim"

[user]
author = "Jane Doe"
```

---

## Development

```bash
git clone https://github.com/orvizz/typst-manager
cd typst-manager
pip install -e ".[dev]"
pytest tests/
```

---

## License

MIT
