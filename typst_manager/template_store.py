"""
Template store — manages the templates directory.

Each template is a plain folder:

    <data_dir>/templates/<name>/
    ├── main.typ        ← required entry point
    ├── meta.toml       ← optional: description
    └── ...             ← any other files the user puts here

The folder name is the template's identity.
meta.toml schema:
    description = "Short description"
"""
import shutil
import sys
from pathlib import Path

if sys.version_info >= (3, 11):
    import tomllib
else:
    try:
        import tomllib
    except ImportError:
        import tomli as tomllib  # type: ignore[no-redef]

from typst_manager.platform import ensure_dir, safe_name

_BLANK_MAIN = """\
// {name} template
// Edit this file to define your template's styles and structure.

#let template(body) = {{
  set document(title: "Untitled")
  set page(paper: "a4", margin: (x: 2.5cm, y: 3cm))
  set text(font: "New Computer Modern", size: 11pt)
  set par(justify: true)

  body
}}
"""


# ---------------------------------------------------------------------------
# Template
# ---------------------------------------------------------------------------

class Template:
    """Represents a single template folder."""

    def __init__(self, path: Path):
        self.path = path
        self.name = path.name
        self._meta = self._load_meta()

    @property
    def main_file(self) -> Path:
        return self.path / "main.typ"

    @property
    def meta_file(self) -> Path:
        return self.path / "meta.toml"

    @property
    def description(self) -> str:
        return self._meta.get("description", "")

    def is_valid(self) -> bool:
        return self.main_file.exists()

    def _load_meta(self) -> dict:
        if not self.meta_file.exists():
            return {}
        with open(self.meta_file, "rb") as f:
            return tomllib.load(f)

    def __repr__(self) -> str:
        return f"Template(name={self.name!r})"


# ---------------------------------------------------------------------------
# TemplateStore
# ---------------------------------------------------------------------------

class TemplateStore:
    """CRUD operations on the templates directory."""

    def __init__(self, templates_dir: Path):
        self.templates_dir = templates_dir

    # ------------------------------------------------------------------
    # Create
    # ------------------------------------------------------------------

    def create_blank(self, name: str, description: str = "") -> Template:
        """
        Create a new template with an empty main.typ.
        Caller is responsible for opening the editor afterwards.
        """
        name = _validate_name(name)
        dest = self._dest(name)
        _assert_not_exists(dest, name)
        ensure_dir(dest)
        (dest / "main.typ").write_text(
            _BLANK_MAIN.format(name=name), encoding="utf-8"
        )
        _write_meta(dest, description)
        return Template(dest)

    def create_from_file(self, name: str, source: Path, description: str = "") -> Template:
        """
        Create a new template by importing an existing .typ file as main.typ.
        """
        name = _validate_name(name)
        source = source.expanduser().resolve()

        if not source.exists():
            raise FileNotFoundError(f"Source file not found: {source}")
        if source.suffix != ".typ":
            raise ValueError(f"Source must be a .typ file, got: {source.name}")

        dest = self._dest(name)
        _assert_not_exists(dest, name)
        ensure_dir(dest)
        shutil.copy2(source, dest / "main.typ")
        _write_meta(dest, description)
        return Template(dest)

    def create_from_template(self, name: str, source_name: str, description: str = "") -> Template:
        """
        Create a new template as a copy of an existing one.
        """
        name = _validate_name(name)
        source = self.get(source_name)  # raises KeyError if missing

        dest = self._dest(name)
        _assert_not_exists(dest, name)
        shutil.copytree(source.path, dest)

        # Update / create meta.toml with the new name
        _write_meta(dest, description or source.description)
        return Template(dest)

    # ------------------------------------------------------------------
    # Read
    # ------------------------------------------------------------------

    def get(self, name: str) -> Template:
        """Return a Template by name. Raises KeyError if not found."""
        name = safe_name(name)
        path = self.templates_dir / name
        if not path.exists() or not (path / "main.typ").exists():
            raise KeyError(
                f"Template '{name}' not found. "
                f"Run 'typst-manager template list' to see available templates."
            )
        return Template(path)

    def list(self) -> list[Template]:
        """Return all valid templates sorted by name."""
        if not self.templates_dir.exists():
            return []
        return sorted(
            (Template(p) for p in self.templates_dir.iterdir()
             if p.is_dir() and (p / "main.typ").exists()),
            key=lambda t: t.name,
        )

    def has(self, name: str) -> bool:
        try:
            self.get(name)
            return True
        except KeyError:
            return False

    # ------------------------------------------------------------------
    # Update
    # ------------------------------------------------------------------

    def rename(self, old_name: str, new_name: str) -> Template:
        """Rename a template folder. Updates meta.toml description is preserved."""
        old = self.get(old_name)
        new_name = _validate_name(new_name)
        new_path = self.templates_dir / new_name

        if new_path.exists():
            raise FileExistsError(
                f"A template named '{new_name}' already exists."
            )

        old.path.rename(new_path)
        # meta.toml description stays, no name field to update
        return Template(new_path)

    # ------------------------------------------------------------------
    # Delete
    # ------------------------------------------------------------------

    def delete(self, name: str) -> None:
        """Permanently remove a template folder."""
        template = self.get(name)  # raises KeyError if missing
        shutil.rmtree(template.path)

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    def _dest(self, name: str) -> Path:
        return self.templates_dir / name


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _validate_name(name: str) -> str:
    clean = safe_name(name)
    if not clean:
        raise ValueError(
            f"Invalid template name '{name}'. "
            "Use letters, numbers, hyphens, and underscores only."
        )
    return clean


def _assert_not_exists(path: Path, name: str) -> None:
    if path.exists():
        raise FileExistsError(
            f"Template '{name}' already exists. "
            "Choose a different name or delete the existing one first."
        )


def _write_meta(dest: Path, description: str) -> None:
    with open(dest / "meta.toml", "w", encoding="utf-8") as f:
        if description:
            f.write(f'description = "{description}"\n')
        else:
            f.write("# description = \"\"\n")
