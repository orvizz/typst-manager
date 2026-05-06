"""
typst-manager config show
typst-manager config set editor <vim|nvim|code|system>
typst-manager config set author "<name>"
"""
from typst_manager.config import Config
from typst_manager.platform import KNOWN_EDITORS

VALID_EDITORS = list(KNOWN_EDITORS.keys()) + ["system"]


def run_show(args, cfg: Config) -> int:
    print(f"Data directory : {cfg.data_dir}")
    print(f"Config file    : {cfg.path}")
    print(f"Templates dir  : {cfg.templates_dir}")
    print(f"editor         : {cfg.editor}")
    print(f"author         : {cfg.author or '(not set)'}")
    return 0


def run_set(args, cfg: Config) -> int:
    key = args.key.lower()
    value = args.value

    if key == "editor":
        if value not in VALID_EDITORS:
            print(
                f"Error: unknown editor '{value}'. "
                f"Valid options: {', '.join(VALID_EDITORS)}"
            )
            return 1
        cfg.set_editor(value)
        print(f"✓ editor = {value}")

    elif key == "author":
        cfg.set_author(value)
        print(f"✓ author = {value}")

    else:
        print(
            f"Error: unknown config key '{key}'. "
            "Valid keys: editor, author"
        )
        return 1

    return 0
