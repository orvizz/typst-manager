"""
typst-manager man

Opens the bundled man page using man(1) on Linux/macOS, or prints it
rendered as plain text on Windows (or when man is not available).
"""
import subprocess
import sys
from pathlib import Path


def run_man() -> int:
    man_file = Path(__file__).parent.parent / "man" / "typst-manager.1"

    if not man_file.exists():
        print("Error: man page not found. This is a packaging issue.")
        return 1

    if sys.platform == "win32":
        return _render_text(man_file)

    # Linux / macOS — prefer man(1)
    try:
        result = subprocess.run(["man", "-l", str(man_file)])
        return result.returncode
    except FileNotFoundError:
        # man not available (e.g. minimal Docker image) — fall back to text
        return _render_text(man_file)


def _render_text(man_file: Path) -> int:
    """Render the groff man page as plain text using groff or nroff, or
    fall back to printing the raw source with a short notice."""
    for cmd in (["groff", "-man", "-Tascii"], ["nroff", "-man"]):
        try:
            result = subprocess.run(
                cmd + [str(man_file)],
                capture_output=True,
                text=True,
            )
            if result.returncode == 0:
                # Page through it if possible
                _page(result.stdout)
                return 0
        except FileNotFoundError:
            continue

    # Last resort: print the raw .1 source with a notice
    print(
        "Note: install 'man' or 'groff' for formatted output.\n"
        "Showing raw man page source:\n"
    )
    print(man_file.read_text(encoding="utf-8"))
    return 0


def _page(text: str) -> None:
    """Send text through a pager if available, otherwise print directly."""
    for pager in ("less", "more"):
        try:
            proc = subprocess.Popen([pager], stdin=subprocess.PIPE)
            proc.communicate(input=text.encode())
            return
        except FileNotFoundError:
            continue
    print(text)
