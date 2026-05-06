"""
typst-manager — CLI entry point

Commands:
  new      <name> --template <t> [--out <dir>]
  template create <name> [--from <file|template>] [--description "..."]
  template edit   <name>
  template rename <name> <new-name>
  template delete <name> [--yes]
  template list
  config   show
  config   set <key> <value>
"""
import argparse
import sys

from typst_manager.config import load_config


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="typst-manager",
        description="Manage Typst templates and documents.",
    )
    sub = parser.add_subparsers(dest="command", metavar="<command>")
    sub.required = True

    # ------------------------------------------------------------------
    # new
    # ------------------------------------------------------------------
    p_new = sub.add_parser("new", help="Create a new document from a template.")
    p_new.add_argument("name", help="Document name (used as the folder name).")
    p_new.add_argument(
        "-t", "--template", required=True,
        help="Template name to use.",
    )
    p_new.add_argument(
        "-o", "--out", default=None,
        help="Output directory (default: current directory).",
    )

    # ------------------------------------------------------------------
    # template
    # ------------------------------------------------------------------
    p_tmpl = sub.add_parser("template", help="Manage templates.")
    tsub = p_tmpl.add_subparsers(dest="template_command", metavar="<subcommand>")
    tsub.required = True

    # template create
    t_create = tsub.add_parser("create", help="Create a new template.")
    t_create.add_argument("name", help="Template name.")
    t_create.add_argument(
        "--from", dest="from_", default=None, metavar="SOURCE",
        help=(
            "Source to create from: a path to a .typ file, "
            "or the name of an existing template. "
            "Omit to start from a blank template."
        ),
    )
    t_create.add_argument(
        "-d", "--description", default="",
        help="Short description of the template.",
    )

    # template edit
    t_edit = tsub.add_parser("edit", help="Open a template folder in your editor.")
    t_edit.add_argument("name", help="Template name.")

    # template rename
    t_rename = tsub.add_parser("rename", help="Rename a template.")
    t_rename.add_argument("name", help="Current template name.")
    t_rename.add_argument("new_name", help="New template name.")

    # template delete
    t_delete = tsub.add_parser("delete", help="Delete a template.")
    t_delete.add_argument("name", help="Template name.")
    t_delete.add_argument(
        "-y", "--yes", action="store_true",
        help="Skip confirmation prompt.",
    )

    # template list
    tsub.add_parser("list", help="List all templates.")

    # ------------------------------------------------------------------
    # config
    # ------------------------------------------------------------------
    p_cfg = sub.add_parser("config", help="View or change configuration.")
    csub = p_cfg.add_subparsers(dest="config_command", metavar="<subcommand>")
    csub.required = True

    csub.add_parser("show", help="Print current configuration.")

    c_set = csub.add_parser("set", help="Set a configuration value.")
    c_set.add_argument("key", help="Key to set: editor | author")
    c_set.add_argument("value", help="New value.")

    return parser


def main(argv=None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    cfg = load_config()

    if args.command == "new":
        from typst_manager.commands.new import run
        return run(args, cfg)

    if args.command == "template":
        from typst_manager.commands.template import (
            run_create, run_edit, run_rename, run_delete, run_list,
        )
        dispatch = {
            "create": run_create,
            "edit":   run_edit,
            "rename": run_rename,
            "delete": run_delete,
            "list":   run_list,
        }
        return dispatch[args.template_command](args, cfg)

    if args.command == "config":
        from typst_manager.commands.config_cmd import run_show, run_set
        if args.config_command == "show":
            return run_show(args, cfg)
        if args.config_command == "set":
            return run_set(args, cfg)

    return 0


if __name__ == "__main__":
    sys.exit(main())
