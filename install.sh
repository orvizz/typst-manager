#!/usr/bin/env bash
# typst-manager installer — Linux / macOS
# Usage: curl -sSL https://raw.githubusercontent.com/orvizz/typst-manager/main/install.sh | bash

set -euo pipefail

TOOL="typst-manager"
MIN_PYTHON_MINOR=9
REPO_URL="https://github.com/orvizz/typst-manager"

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

red()   { printf '\033[31m%s\033[0m\n' "$*"; }
green() { printf '\033[32m%s\033[0m\n' "$*"; }
blue()  { printf '\033[34m%s\033[0m\n' "$*"; }
bold()  { printf '\033[1m%s\033[0m\n'  "$*"; }

die() { red "Error: $*"; exit 1; }

# ---------------------------------------------------------------------------
# Detect OS
# ---------------------------------------------------------------------------

OS="$(uname -s)"
case "$OS" in
  Linux*)  OS_NAME="linux" ;;
  Darwin*) OS_NAME="macos" ;;
  *)       die "Unsupported OS: $OS" ;;
esac

bold "Installing $TOOL on $OS_NAME..."
echo ""

# ---------------------------------------------------------------------------
# Find Python 3.9+
# ---------------------------------------------------------------------------

find_python() {
  for cmd in python3 python python3.13 python3.12 python3.11 python3.10 python3.9; do
    if command -v "$cmd" &>/dev/null; then
      version=$("$cmd" -c "import sys; print(sys.version_info[:2] >= (3,$MIN_PYTHON_MINOR))" 2>/dev/null || echo "False")
      if [ "$version" = "True" ]; then
        echo "$cmd"
        return 0
      fi
    fi
  done
  return 1
}

PYTHON=$(find_python) || die "Python 3.$MIN_PYTHON_MINOR or higher is required but was not found.
Install it from https://python.org or via your package manager:
  Linux (apt):    sudo apt install python3
  Linux (dnf):    sudo dnf install python3
  macOS (brew):   brew install python3"

PYTHON_VERSION=$("$PYTHON" --version)
echo "Found: $PYTHON_VERSION ($PYTHON)"

# ---------------------------------------------------------------------------
# Install via pipx (preferred) or pip
# ---------------------------------------------------------------------------

if command -v pipx &>/dev/null; then
  echo "Using pipx..."
  if pipx list 2>/dev/null | grep -q "$TOOL"; then
    pipx upgrade "$TOOL"
  else
    pipx install "$TOOL"
  fi
  INSTALL_METHOD="pipx"

else
  echo "pipx not found — installing with pip (user install)..."
  echo "Tip: install pipx for easier management: https://pipx.pypa.io"
  echo ""
  "$PYTHON" -m pip install --user --upgrade "$TOOL"
  INSTALL_METHOD="pip"
fi

# ---------------------------------------------------------------------------
# PATH check (pip user install only)
# ---------------------------------------------------------------------------

if [ "$INSTALL_METHOD" = "pip" ]; then
  if [ "$OS_NAME" = "macos" ]; then
    USER_BIN="$("$PYTHON" -m site --user-base)/bin"
  else
    USER_BIN="${HOME}/.local/bin"
  fi

  if ! echo "$PATH" | grep -q "$USER_BIN"; then
    echo ""
    printf '\033[33mWarning: %s is not in your PATH.\033[0m\n' "$USER_BIN"
    echo "Add this line to your shell profile (~/.bashrc, ~/.zshrc, etc.):"
    echo ""
    echo "  export PATH=\"$USER_BIN:\$PATH\""
    echo ""
    echo "Then restart your shell or run: source ~/.bashrc"
  fi
fi

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------

echo ""
if command -v "$TOOL" &>/dev/null; then
  green "✓ $TOOL installed successfully!"
else
  printf '\033[33m%s\033[0m\n' "Installation complete, but '$TOOL' was not found in PATH yet."
  echo "You may need to restart your terminal or update your PATH (see above)."
fi

echo ""
bold "Get started:"
echo "  typst-manager template create my-template"
echo "  typst-manager template list"
echo "  typst-manager new my-doc --template my-template"
echo ""
echo "Documentation: $REPO_URL"
