"""
typst-manager — CLI entry point

Commands:
  new      <name> --template <t> [--out <dir>]
  template create <name> [--from <dir|file|template>] [-d <description>]
  template edit   <name>
  template rename <name> <new-name>
  template delete <name> [--yes]
  template list
  config   show
  config   set <key> <value>
  man
"""
import argparse
import sys

from typst_manager.config import load_config


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="typst-manager",
        description="Manage Typst templates and documents from the command line.",
        epilog=(
            "Examples:\n"
            "  typst-manager template create article\n"
            "  typst-manager template create letter --from ~/docs/my-letter/\n"
            "  typst-manager new my-report --template article\n"
            "\n"
            "Run 'typst-manager man' for the full reference manual."
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    sub = parser.add_subparsers(dest="command", metavar="<command>")
    sub.required = True

    # ------------------------------------------------------------------
    # new
    # ------------------------------------------------------------------
    p_new = sub.add_parser(
        "new",
        help="Create a new document from a template.",
        description=(
            "Copy a template into a new document folder.\n\n"
            "All files from the template are copied into <name>/, "
            "ready to edit. Changes to the template later will not affect "
            "existing documents."
        ),
        epilog=(
            "Examples:\n"
            "  typst-manager new my-report --template article\n"
            "  typst-manager new thesis --template academic --out ~/documents"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    p_new.add_argument("name", help="Name of the new document (used as the folder name).")
    p_new.add_argument(
        "-t", "--template", required=True,
        metavar="NAME",
        help="Name of the template to use.",
    )
    p_new.add_argument(
        "-o", "--out",
        default=None,
        metavar="DIR",
        help="Directory where the document folder is created (default: current directory).",
    )

    # ------------------------------------------------------------------
    # template
    # ------------------------------------------------------------------
    p_tmpl = sub.add_parser(
        "template",
        help="Create, edit, rename, delete, and list templates.",
        description="Manage your template library.",
    )
    tsub = p_tmpl.add_subparsers(dest="template_command", metavar="<subcommand>")
    tsub.required = True

    # template create
    t_create = tsub.add_parser(
        "create",
        help="Create a new template.",
        description=(
            "Create a new template. Three modes are available:\n\n"
            "  No --from      Start from a boilerplate (main.typ, template.typ,\n"
            "                 metadata.typ, sources.bib) and open in your editor.\n\n"
            "  --from <dir>   Save an existing document folder as a template.\n"
            "                 Compiled .pdf files are excluded automatically.\n\n"
            "  --from <file>  Import a single .typ file as the template's main.typ.\n\n"
            "  --from <name>  Duplicate an existing template."
        ),
        usage="typst-manager template create <name> [--from <source>] [-d <description>]",
        epilog=(
            "Examples:\n"
            "  typst-manager template create article\n"
            "  typst-manager template create letter --from ~/docs/my-letter/\n"
            "  typst-manager template create report --from my-style.typ\n"
            "  typst-manager template create report-v2 --from report"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    t_create.add_argument("name", help="Name for the new template.")
    t_create.add_argument(
        "--from", dest="from_", default=None, metavar="SOURCE",
        help=(
            "Where to create the template from: a document directory, "
            "a .typ file, or an existing template name. "
            "Omit to start from a blank boilerplate."
        ),
    )
    t_create.add_argument(
        "-d", "--description", default="", metavar="TEXT",
        help="Short description shown in 'template list'.",
    )

    # template edit
    t_edit = tsub.add_parser(
        "edit",
        help="Open a template in your editor.",
        description="Open the template folder in the configured editor.",
        epilog="Examples:\n  typst-manager template edit article",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    t_edit.add_argument("name", help="Template name.")

    # template rename
    t_rename = tsub.add_parser(
        "rename",
        help="Rename a template.",
        description="Rename a template. The template contents are not changed.",
        epilog="Examples:\n  typst-manager template rename article article-v2",
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    t_rename.add_argument("name", help="Current template name.")
    t_rename.add_argument("new_name", help="New template name.")

    # template delete
    t_delete = tsub.add_parser(
        "delete",
        help="Delete a template.",
        description=(
            "Permanently delete a template. "
            "You will be asked to confirm unless --yes is given."
        ),
        epilog=(
            "Examples:\n"
            "  typst-manager template delete old-report\n"
            "  typst-manager template delete old-report --yes"
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    t_delete.add_argument("name", help="Template name.")
    t_delete.add_argument(
        "-y", "--yes", action="store_true",
        help="Skip the confirmation prompt.",
    )

    # template list
    tsub.add_parser(
        "list",
        help="List all templates.",
        description="Print all templates with their names and descriptions.",
    )

    # ------------------------------------------------------------------
    # config
    # ------------------------------------------------------------------
    p_cfg = sub.add_parser(
        "config",
        help="Show or change configuration.",
        description="View and update typst-manager settings.",
    )
    csub = p_cfg.add_subparsers(dest="config_command", metavar="<subcommand>")
    csub.required = True

    csub.add_parser(
        "show",
        help="Print current configuration and storage paths.",
        description="Print the active configuration and the path to the config file.",
    )

    c_set = csub.add_parser(
        "set",
        help="Set a configuration value.",
        description=(
            "Set a configuration value. Available keys:\n\n"
            "  editor   Editor used to open template folders.\n"
            "           Values: system, code, vim, nvim  (default: system)\n\n"
            "  author   Your name, stored for reference.\n"
        ),
        epilog=(
            "Examples:\n"
            "  typst-manager config set editor nvim\n"
            "  typst-manager config set author \"Jane Doe\""
        ),
        formatter_class=argparse.RawDescriptionHelpFormatter,
    )
    c_set.add_argument("key", help="Key to set: editor | author")
    c_set.add_argument("value", help="New value.")

    # ------------------------------------------------------------------
    # man
    # ------------------------------------------------------------------
    sub.add_parser(
        "man",
        help="Open the full reference manual.",
        description=(
            "Display the typst-manager man page.\n\n"
            "On Linux and macOS the man page is opened with man(1).\n"
            "On Windows the manual is printed to the terminal."
        ),
    )

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

    if args.command == "man":
        from typst_manager.commands.man_cmd import run_man
        return run_man()

    return 0


if __name__ == "__main__":
    sys.exit(main())
