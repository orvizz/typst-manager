"""
Configuration — stored at <data_dir>/config.toml

Schema:
  [core]
  editor = "system"     # system | vim | nvim | code

  [user]
  author = ""           # optional, for the user's reference
"""
import os
import sys
from pathlib import Path

if sys.version_info >= (3, 11):
    import tomllib
else:
    try:
        import tomllib
    except ImportError:
        import tomli as tomllib  # type: ignore[no-redef]

from typst_manager.platform import data_dir, ensure_dir

_DEFAULTS = {
    "core": {"editor": "system"},
    "user": {"author": ""},
}


class Config:
    def __init__(self):
        self._data_dir = data_dir()
        self._path = self._data_dir / "config.toml"
        self._data = self._load()

    # ------------------------------------------------------------------
    # Properties
    # ------------------------------------------------------------------

    @property
    def data_dir(self) -> Path:
        return self._data_dir

    @property
    def templates_dir(self) -> Path:
        return self._data_dir / "templates"

    @property
    def path(self) -> Path:
        return self._path

    @property
    def editor(self) -> str:
        return self._data["core"]["editor"]

    @property
    def author(self) -> str:
        return self._data["user"]["author"]

    # ------------------------------------------------------------------
    # Setters (each persists immediately)
    # ------------------------------------------------------------------

    def set_editor(self, value: str) -> None:
        self._data["core"]["editor"] = value
        self._save()

    def set_author(self, value: str) -> None:
        self._data["user"]["author"] = value
        self._save()

    # ------------------------------------------------------------------
    # Internals
    # ------------------------------------------------------------------

    def _load(self) -> dict:
        if not self._path.exists():
            return _deep_copy(_DEFAULTS)
        with open(self._path, "rb") as f:
            raw = tomllib.load(f)
        merged = _deep_copy(_DEFAULTS)
        for section, pairs in raw.items():
            if section in merged:
                merged[section].update(pairs)
            else:
                merged[section] = pairs
        return merged

    def _save(self) -> None:
        ensure_dir(self._data_dir)
        with open(self._path, "w", encoding="utf-8") as f:
            f.write(_to_toml(self._data))


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _deep_copy(d: dict) -> dict:
    return {k: dict(v) for k, v in d.items()}


def _to_toml(data: dict) -> str:
    lines = []
    for section, pairs in data.items():
        lines.append(f"[{section}]")
        for k, v in pairs.items():
            lines.append(f'{k} = "{v}"')
        lines.append("")
    return "\n".join(lines)


# ---------------------------------------------------------------------------
# Module-level loader
# ---------------------------------------------------------------------------

def load_config() -> Config:
    cfg = Config()
    ensure_dir(cfg.data_dir)
    ensure_dir(cfg.templates_dir)
    if not cfg.path.exists():
        cfg._save()
    return cfg
