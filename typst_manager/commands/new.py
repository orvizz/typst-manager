"""
typst-manager new <doc-name> --template <name> [--out <dir>]

Copies the entire template folder (excluding meta.toml) into:
  <out>/<doc-name>/        (--out defaults to current working directory)
"""
import shutil
from pathlib import Path

from typst_manager.config import Config
from typst_manager.platform import ensure_dir, safe_name
from typst_manager.template_store import TemplateStore


def run(args, cfg: Config) -> int:
    name = safe_name(args.name)
    if not name:
        print("Error: document name is empty or contains only invalid characters.")
        return 1

    store = TemplateStore(cfg.templates_dir)

    try:
        template = store.get(args.template)
    except KeyError as e:
        print(f"Error: {e}")
        return 1

    # Resolve output directory
    out_base = Path(getattr(args, "out", None) or ".").expanduser().resolve()
    doc_dir = out_base / name

    if doc_dir.exists():
        print(f"Error: '{doc_dir}' already exists.")
        return 1

    ensure_dir(doc_dir)

    # Copy everything from the template folder except meta.toml
    copied = 0
    for src in template.path.iterdir():
        if src.name == "meta.toml":
            continue
        dst = doc_dir / src.name
        if src.is_dir():
            shutil.copytree(src, dst)
        else:
            shutil.copy2(src, dst)
        copied += 1

    print(f"✓ Document '{name}' created at: {doc_dir}")
    print(f"  Template : {template.name}")
    print(f"  Files    : {copied} copied")
    return 0
