# typst-manager

A command-line tool to manage [Typst](https://typst.app) templates and documents.

Create a personal library of reusable templates. Spin up new documents from
them in seconds. Everything lives in plain folders — no database, no lock-in.

---

## Installation

### Requirements

- Python 3.9 or higher
- `[pipx](https://pipx.pypa.io)` (recommended) or `pip`

### Linux / macOS

```bash
curl -sSL https://raw.githubusercontent.com/orvizz/typst-manager/main/install.sh | bash
```

Or manually with pipx:

```bash
pipx install typst-manager
```

### Windows

```powershell
irm https://raw.githubusercontent.com/orvizz/typst-manager/main/install.ps1 | iex
```

Or manually with pipx:

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

typst-manager stores all templates in a platform-appropriate directory:


| OS      | Default location                               |
| ------- | ---------------------------------------------- |
| Linux   | `~/.local/share/typst-manager/`                |
| macOS   | `~/Library/Application Support/typst-manager/` |
| Windows | `%APPDATA%\typst-manager\`                     |


You can override this at any time by setting the `TYPST_MANAGER_HOME`
environment variable:

```bash
export TYPST_MANAGER_HOME=/path/to/custom/dir   # Linux / macOS
set TYPST_MANAGER_HOME=C:\path\to\custom\dir    # Windows
```

---

## Quick start

```bash
# 1. Create a template from a .typ file you already have
typst-manager template create article --from my-style.typ

# 2. List your templates
typst-manager template list

# 3. Create a new document from it (lands in ./my-post/)
typst-manager new my-post --template article
```

---

## Commands

### `typst-manager new`

Create a new document from a template. The document is placed in a new folder
inside the current directory, or inside `--out` if specified.

```
typst-manager new <name> --template <template-name> [--out <dir>]
```

```bash
typst-manager new quarterly-report --template report
typst-manager new thesis --template academic --out ~/documents
```

The entire template folder is copied into `<name>/`, excluding `meta.toml`.
The result is a self-contained project folder you can edit freely — changes
to the template later will not affect existing documents.

---

### `typst-manager template`

#### `create`

Create a new template. Three modes:

```bash
# Start from scratch — opens the template folder in your editor
typst-manager template create <name>

# Import an existing .typ file as the template's main.typ
typst-manager template create <name> --from path/to/file.typ

# Copy an existing template as the starting point
typst-manager template create <name> --from <other-template-name>
```

Options:


| Option                | Description                                     |
| --------------------- | ----------------------------------------------- |
| `--from <source>`     | A `.typ` file path or an existing template name |
| `-d`, `--description` | Short description shown in `template list`      |


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


The `system` editor uses the OS default: `xdg-open` on Linux, `open` on
macOS, `start` on Windows.

---

## Template structure

A template is a folder with at least a `main.typ`:

```
~/.local/share/typst-manager/templates/
└── report/
    ├── main.typ        ← required entry point
    ├── meta.toml       ← optional metadata
    └── cover.typ       ← any other files you need
```

`meta.toml` is optional. If present:

```toml
description = "Formal report with cover page"
```

Everything in the template folder (except `meta.toml`) is copied into the
new document when you run `typst-manager new`.

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