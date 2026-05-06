"""
Cross-platform utilities: data directory resolution, editor launching, path helpers.

Data directory per OS:
  Linux   → $XDG_DATA_HOME/typst-manager     (default ~/.local/share/typst-manager)
  macOS   → ~/Library/Application Support/typst-manager
  Windows → %APPDATA%/typst-manager

Override any of the above with the TYPST_MANAGER_HOME environment variable.
"""
import os
import subprocess
import sys
from pathlib import Path


# ---------------------------------------------------------------------------
# OS detection
# ---------------------------------------------------------------------------

def current_os() -> str:
    """Return 'linux', 'macos', or 'windows'."""
    if sys.platform.startswith("win"):
        return "windows"
    if sys.platform == "darwin":
        return "macos"
    return "linux"


# ---------------------------------------------------------------------------
# Data directory
# ---------------------------------------------------------------------------

def data_dir() -> Path:
    """
    Return the platform-appropriate data directory for typst-manager.
    Respects TYPST_MANAGER_HOME env override.
    """
    override = os.environ.get("TYPST_MANAGER_HOME", "").strip()
    if override:
        return Path(override).expanduser().resolve()

    os_name = current_os()

    if os_name == "windows":
        base = Path(os.environ.get("APPDATA", Path.home() / "AppData" / "Roaming"))
        return base / "typst-manager"

    if os_name == "macos":
        return Path.home() / "Library" / "Application Support" / "typst-manager"

    # Linux — honour XDG_DATA_HOME
    xdg = os.environ.get("XDG_DATA_HOME", "").strip()
    base = Path(xdg) if xdg else Path.home() / ".local" / "share"
    return base / "typst-manager"


# ---------------------------------------------------------------------------
# Editor launching
# ---------------------------------------------------------------------------

KNOWN_EDITORS = {
    "vim":   ["vim"],
    "nvim":  ["nvim"],
    "code":  ["code"],
}


def open_in_editor(path: Path, editor: str = "system") -> None:
    """
    Open *path* (file or directory) in the requested editor.

    Parameters
    ----------
    path:   target to open
    editor: 'system' for OS default, or one of KNOWN_EDITORS keys
    """
    path = path.resolve()

    if editor == "system":
        _open_with_system(path)
        return

    if editor not in KNOWN_EDITORS:
        raise ValueError(
            f"Unknown editor '{editor}'. "
            f"Valid options: {', '.join(KNOWN_EDITORS)} or 'system'."
        )

    subprocess.run(KNOWN_EDITORS[editor] + [str(path)], check=False)


def _open_with_system(path: Path) -> None:
    os_name = current_os()
    if os_name == "windows":
        os.startfile(str(path))          # type: ignore[attr-defined]
    elif os_name == "macos":
        subprocess.run(["open", str(path)], check=False)
    else:
        subprocess.run(["xdg-open", str(path)], check=False)


# ---------------------------------------------------------------------------
# Path helpers
# ---------------------------------------------------------------------------

def ensure_dir(path: Path) -> Path:
    """Create directory (and parents) if it doesn't exist. Return path."""
    path.mkdir(parents=True, exist_ok=True)
    return path


def safe_name(name: str) -> str:
    """
    Sanitise a user-supplied name for use as a filesystem folder name.
    Spaces → hyphens. Only [a-zA-Z0-9_-] kept.
    """
    name = name.strip().replace(" ", "-")
    allowed = frozenset(
        "abcdefghijklmnopqrstuvwxyz"
        "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
        "0123456789_-"
    )
    return "".join(c for c in name if c in allowed)
