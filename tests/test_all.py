"""
Tests for typst-manager (copy model, no placeholders).
Run with: pytest tests/
"""
import shutil
from pathlib import Path
from datetime import date
import pytest


# ---------------------------------------------------------------------------
# Fixtures
# ---------------------------------------------------------------------------

@pytest.fixture
def home(tmp_path, monkeypatch):
    """Isolated data directory for each test."""
    monkeypatch.setenv("TYPST_MANAGER_HOME", str(tmp_path))
    return tmp_path


@pytest.fixture
def cfg(home):
    from typst_manager.config import load_config
    return load_config()


@pytest.fixture
def store(cfg):
    from typst_manager.template_store import TemplateStore
    return TemplateStore(cfg.templates_dir)


@pytest.fixture
def typ_file(tmp_path):
    f = tmp_path / "sample.typ"
    f.write_text("#set text(size: 12pt)\n= Hello\n")
    return f


@pytest.fixture
def template_with_assets(tmp_path):
    """A .typ file plus a sibling image to simulate a multi-file template."""
    f = tmp_path / "rich.typ"
    f.write_text("#set page(paper: \"a4\")\n")
    (tmp_path / "logo.png").write_bytes(b"\x89PNG")
    return f


# ---------------------------------------------------------------------------
# platform
# ---------------------------------------------------------------------------

class TestPlatform:
    def test_current_os_known(self):
        from typst_manager.platform import current_os
        assert current_os() in ("linux", "macos", "windows")

    def test_data_dir_from_env(self, home):
        from typst_manager.platform import data_dir
        assert data_dir() == home

    def test_safe_name_spaces(self):
        from typst_manager.platform import safe_name
        assert safe_name("my template") == "my-template"

    def test_safe_name_strips_invalid(self):
        from typst_manager.platform import safe_name
        assert safe_name("hello/world!") == "helloworld"

    def test_safe_name_empty_after_strip(self):
        from typst_manager.platform import safe_name
        assert safe_name("!!!") == ""

    def test_ensure_dir(self, tmp_path):
        from typst_manager.platform import ensure_dir
        d = tmp_path / "a" / "b" / "c"
        result = ensure_dir(d)
        assert result.is_dir()


# ---------------------------------------------------------------------------
# Config
# ---------------------------------------------------------------------------

class TestConfig:
    def test_defaults(self, cfg):
        assert cfg.editor == "system"
        assert cfg.author == ""

    def test_data_dir_from_env(self, cfg, home):
        assert cfg.data_dir == home

    def test_templates_dir_created(self, cfg):
        assert cfg.templates_dir.is_dir()

    def test_config_file_created(self, cfg):
        assert cfg.path.exists()

    def test_set_editor(self, cfg):
        cfg.set_editor("nvim")
        assert cfg.editor == "nvim"

    def test_set_author(self, cfg):
        cfg.set_author("Ada Lovelace")
        assert cfg.author == "Ada Lovelace"

    def test_persists_across_reload(self, home):
        from typst_manager.config import load_config
        cfg1 = load_config()
        cfg1.set_editor("vim")
        cfg1.set_author("Turing")
        cfg2 = load_config()
        assert cfg2.editor == "vim"
        assert cfg2.author == "Turing"


# ---------------------------------------------------------------------------
# TemplateStore — create
# ---------------------------------------------------------------------------

class TestTemplateStoreCreate:
    def test_create_blank(self, store):
        t = store.create_blank("mytemplate")
        assert t.name == "mytemplate"
        assert t.main_file.exists()
        assert t.is_valid()

    def test_create_blank_with_description(self, store):
        t = store.create_blank("described", description="A great template")
        assert t.description == "A great template"

    def test_create_from_file(self, store, typ_file):
        t = store.create_from_file("fromfile", typ_file, description="From file")
        assert t.is_valid()
        assert t.main_file.read_text() == typ_file.read_text()
        assert t.description == "From file"

    def test_create_from_file_missing(self, store, tmp_path):
        with pytest.raises(FileNotFoundError):
            store.create_from_file("x", tmp_path / "ghost.typ")

    def test_create_from_file_wrong_extension(self, store, tmp_path):
        f = tmp_path / "file.txt"
        f.write_text("hello")
        with pytest.raises(ValueError, match=".typ"):
            store.create_from_file("x", f)

    def test_create_from_template(self, store, typ_file):
        store.create_from_file("original", typ_file, description="Original")
        copy = store.create_from_template("mycopy", "original", description="Copy")
        assert copy.is_valid()
        assert copy.main_file.read_text() == typ_file.read_text()

    def test_create_from_template_missing(self, store):
        with pytest.raises(KeyError):
            store.create_from_template("x", "nonexistent")

    def test_create_duplicate_raises(self, store):
        store.create_blank("dup")
        with pytest.raises(FileExistsError):
            store.create_blank("dup")

    def test_create_invalid_name(self, store):
        with pytest.raises(ValueError):
            store.create_blank("!!!")


# ---------------------------------------------------------------------------
# TemplateStore — read
# ---------------------------------------------------------------------------

class TestTemplateStoreRead:
    def test_get_existing(self, store):
        store.create_blank("readable")
        t = store.get("readable")
        assert t.name == "readable"

    def test_get_missing_raises(self, store):
        with pytest.raises(KeyError):
            store.get("ghost")

    def test_has_true(self, store):
        store.create_blank("present")
        assert store.has("present")

    def test_has_false(self, store):
        assert not store.has("absent")

    def test_list_empty(self, store):
        assert store.list() == []

    def test_list_multiple(self, store, typ_file):
        store.create_blank("alpha")
        store.create_from_file("beta", typ_file)
        store.create_blank("gamma")
        names = [t.name for t in store.list()]
        assert names == ["alpha", "beta", "gamma"]  # sorted

    def test_list_excludes_invalid(self, store):
        # A directory without main.typ should not appear
        bad = store.templates_dir / "bad"
        bad.mkdir(parents=True)
        assert store.list() == []


# ---------------------------------------------------------------------------
# TemplateStore — rename
# ---------------------------------------------------------------------------

class TestTemplateStoreRename:
    def test_rename(self, store):
        store.create_blank("old-name")
        t = store.rename("old-name", "new-name")
        assert t.name == "new-name"
        assert not store.has("old-name")
        assert store.has("new-name")

    def test_rename_missing_raises(self, store):
        with pytest.raises(KeyError):
            store.rename("ghost", "whatever")

    def test_rename_to_existing_raises(self, store):
        store.create_blank("a")
        store.create_blank("b")
        with pytest.raises(FileExistsError):
            store.rename("a", "b")

    def test_rename_invalid_new_name(self, store):
        store.create_blank("valid")
        with pytest.raises(ValueError):
            store.rename("valid", "!!!")


# ---------------------------------------------------------------------------
# TemplateStore — delete
# ---------------------------------------------------------------------------

class TestTemplateStoreDelete:
    def test_delete(self, store):
        store.create_blank("todelete")
        store.delete("todelete")
        assert not store.has("todelete")

    def test_delete_missing_raises(self, store):
        with pytest.raises(KeyError):
            store.delete("ghost")


# ---------------------------------------------------------------------------
# new command
# ---------------------------------------------------------------------------

class TestNew:
    def test_creates_folder_in_cwd(self, home, tmp_path, monkeypatch, typ_file):
        monkeypatch.setenv("TYPST_MANAGER_HOME", str(home))
        from typst_manager.config import load_config
        from typst_manager.template_store import TemplateStore
        cfg = load_config()
        TemplateStore(cfg.templates_dir).create_from_file("rep", typ_file)

        from typst_manager.cli import main
        monkeypatch.chdir(tmp_path)
        rc = main(["new", "my-doc", "--template", "rep"])
        assert rc == 0
        assert (tmp_path / "my-doc" / "main.typ").exists()

    def test_creates_folder_with_out(self, home, tmp_path, typ_file):
        from typst_manager.config import load_config
        from typst_manager.template_store import TemplateStore
        cfg = load_config()
        TemplateStore(cfg.templates_dir).create_from_file("rep", typ_file)

        from typst_manager.cli import main
        out = tmp_path / "output"
        out.mkdir()
        rc = main(["new", "my-doc", "--template", "rep", "--out", str(out)])
        assert rc == 0
        assert (out / "my-doc" / "main.typ").exists()

    def test_missing_template(self, home):
        from typst_manager.cli import main
        rc = main(["new", "doc", "--template", "ghost"])
        assert rc == 1

    def test_duplicate_doc_fails(self, home, tmp_path, monkeypatch, typ_file):
        monkeypatch.setenv("TYPST_MANAGER_HOME", str(home))
        from typst_manager.config import load_config
        from typst_manager.template_store import TemplateStore
        cfg = load_config()
        TemplateStore(cfg.templates_dir).create_from_file("rep", typ_file)

        from typst_manager.cli import main
        monkeypatch.chdir(tmp_path)
        main(["new", "dup", "--template", "rep"])
        rc = main(["new", "dup", "--template", "rep"])
        assert rc == 1

    def test_meta_toml_not_copied(self, home, tmp_path, monkeypatch, typ_file):
        monkeypatch.setenv("TYPST_MANAGER_HOME", str(home))
        from typst_manager.config import load_config
        from typst_manager.template_store import TemplateStore
        cfg = load_config()
        TemplateStore(cfg.templates_dir).create_from_file("rep", typ_file)

        from typst_manager.cli import main
        monkeypatch.chdir(tmp_path)
        main(["new", "clean-doc", "--template", "rep"])
        assert not (tmp_path / "clean-doc" / "meta.toml").exists()


# ---------------------------------------------------------------------------
# CLI — template subcommands
# ---------------------------------------------------------------------------

class TestCLITemplate:
    def test_list_empty(self, home, capsys):
        from typst_manager.cli import main
        rc = main(["template", "list"])
        assert rc == 0
        assert "No templates found" in capsys.readouterr().out

    def test_create_and_list(self, home, typ_file, capsys):
        from typst_manager.cli import main
        main(["template", "create", "mytest", "--from", str(typ_file), "--description", "Test"])
        rc = main(["template", "list"])
        assert rc == 0
        out = capsys.readouterr().out
        assert "mytest" in out
        assert "Test" in out

    def test_rename(self, home, typ_file):
        from typst_manager.cli import main
        main(["template", "create", "old", "--from", str(typ_file)])
        rc = main(["template", "rename", "old", "new"])
        assert rc == 0

    def test_delete_with_yes(self, home, typ_file):
        from typst_manager.cli import main
        main(["template", "create", "todel", "--from", str(typ_file)])
        rc = main(["template", "delete", "todel", "--yes"])
        assert rc == 0

    def test_delete_missing(self, home):
        from typst_manager.cli import main
        rc = main(["template", "delete", "ghost", "--yes"])
        assert rc == 1


# ---------------------------------------------------------------------------
# CLI — config subcommands
# ---------------------------------------------------------------------------

class TestCLIConfig:
    def test_show(self, home, capsys):
        from typst_manager.cli import main
        rc = main(["config", "show"])
        assert rc == 0
        out = capsys.readouterr().out
        assert "editor" in out
        assert "Templates dir" in out

    def test_set_editor_valid(self, home):
        from typst_manager.cli import main
        rc = main(["config", "set", "editor", "vim"])
        assert rc == 0

    def test_set_editor_invalid(self, home):
        from typst_manager.cli import main
        rc = main(["config", "set", "editor", "emacs"])
        assert rc == 1

    def test_set_author(self, home):
        from typst_manager.cli import main
        rc = main(["config", "set", "author", "Grace Hopper"])
        assert rc == 0

    def test_set_unknown_key(self, home):
        from typst_manager.cli import main
        rc = main(["config", "set", "unknown", "value"])
        assert rc == 1
