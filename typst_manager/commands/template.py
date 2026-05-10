"""
typst-manager template <subcommand>

  create <name> [--from <file.typ|template-name>] [--description "..."]
  edit   <name>
  rename <name> <new-name>
  delete <name>
  list
"""
from pathlib import Path

from typst_manager.config import Config
from typst_manager.platform import open_in_editor
from typst_manager.template_store import TemplateStore


def run_create(args, cfg: Config) -> int:
    store = TemplateStore(cfg.templates_dir)
    name = args.name
    description = getattr(args, "description", "") or ""
    from_arg = getattr(args, "from_", None)  # argparse uses from_ (from is reserved)

    try:
        if from_arg is None:
            # Blank template — create then open in editor
            t = store.create_blank(name, description)
            print(f"✓ Template '{t.name}' created.")
            print(f"  Location: {t.path}")
            _open(t.path, cfg)

        elif Path(from_arg).is_dir():
            # From an existing document directory
            t = store.create_from_dir(name, Path(from_arg), description)
            print(f"✓ Template '{t.name}' created from directory: {from_arg}")
            print(f"  Location: {t.path}")

        elif Path(from_arg).exists() and Path(from_arg).suffix == ".typ":
            # From an existing .typ file
            t = store.create_from_file(name, Path(from_arg), description)
            print(f"✓ Template '{t.name}' created from file: {from_arg}")
            print(f"  Location: {t.path}")

        else:
            # From another template
            t = store.create_from_template(name, from_arg, description)
            print(f"✓ Template '{t.name}' created from template: {from_arg}")
            print(f"  Location: {t.path}")

        return 0

    except (FileNotFoundError, FileExistsError, ValueError, KeyError) as e:
        print(f"Error: {e}")
        return 1


def run_edit(args, cfg: Config) -> int:
    store = TemplateStore(cfg.templates_dir)
    try:
        t = store.get(args.name)
        print(f"Opening template '{t.name}': {t.path}")
        _open(t.path, cfg)
        return 0
    except KeyError as e:
        print(f"Error: {e}")
        return 1


def run_rename(args, cfg: Config) -> int:
    store = TemplateStore(cfg.templates_dir)
    try:
        t = store.rename(args.name, args.new_name)
        print(f"✓ Template renamed: '{args.name}' → '{t.name}'")
        return 0
    except (KeyError, FileExistsError, ValueError) as e:
        print(f"Error: {e}")
        return 1


def run_delete(args, cfg: Config) -> int:
    store = TemplateStore(cfg.templates_dir)
    try:
        store.get(args.name)  # confirm it exists first
    except KeyError as e:
        print(f"Error: {e}")
        return 1

    # Require confirmation unless --yes is passed
    if not getattr(args, "yes", False):
        answer = input(f"Delete template '{args.name}'? This cannot be undone. [y/N] ")
        if answer.strip().lower() != "y":
            print("Aborted.")
            return 0

    store.delete(args.name)
    print(f"✓ Template '{args.name}' deleted.")
    return 0


def run_list(args, cfg: Config) -> int:
    store = TemplateStore(cfg.templates_dir)
    templates = store.list()

    if not templates:
        print("No templates found.")
        print("Create one with: typst-manager template create <name>")
        return 0

    col = 20
    print(f"{'NAME':<{col}} DESCRIPTION")
    print("-" * 60)
    for t in templates:
        desc = t.description or "(no description)"
        print(f"{t.name:<{col}} {desc}")

    return 0


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

def _open(path: Path, cfg: Config) -> None:
    editor = cfg.editor
    try:
        open_in_editor(path, editor)
    except ValueError as e:
        print(f"Warning: {e} — falling back to system default.")
        open_in_editor(path, "system")
