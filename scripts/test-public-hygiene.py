#!/usr/bin/env python3
"""Disposable, synthetic checks for the public hygiene gate."""
import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest

SCRIPT = Path(__file__).with_name("check-public-hygiene.py").resolve()
SPEC = importlib.util.spec_from_file_location("hygiene", SCRIPT)
HYGIENE = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(HYGIENE)


class HygieneChecks(unittest.TestCase):
    def test_private_patterns(self):
        for value in ["/Users/" + "fixture-person/file", "fixture" + ".fritz" + ".box", "fixture" + ".local", "person@" + "private.invalid"]:
            self.assertTrue(HYGIENE.violations(value.encode(), []))

    def test_generic_examples(self):
        data = b"fixture@example.invalid https://provider.example.local https://user@provider.example.com"
        self.assertFalse(HYGIENE.violations(data, []))

    def test_denylist_and_path_exception(self):
        self.assertTrue(HYGIENE.violations(b"PRIVATE-TERM", ["private-term"]))
        data = ("/Users/" + "private-user/fixture").encode()
        self.assertTrue(HYGIENE.violations(data, []))
        self.assertFalse(HYGIENE.violations(data, [], True))

    def test_repository_and_history(self):
        with tempfile.TemporaryDirectory(prefix="public-hygiene-") as folder:
            root = Path(folder)

            def git(*args):
                return subprocess.run(["git", "-C", folder, *args], check=True, capture_output=True)

            def scan(*args):
                return subprocess.run(["python3", str(SCRIPT), *args], cwd=folder, capture_output=True, text=True)

            git("init", "-q")
            git("config", "user.name", HYGIENE.PUBLIC_NAME)
            git("config", "user.email", HYGIENE.PUBLIC_EMAIL)
            git("config", "commit.gpgsign", "false")
            git("config", "core.hooksPath", "/dev/null")
            (root / ".gitignore").write_text(".env\n")
            (root / ".env").write_text("local-only-sentinel")
            (root / "example.txt").write_text("public example")
            (root / ".git/info/hygiene-denylist").write_text("local-only-sentinel\n")
            git("add", ".")
            git("commit", "-qm", "Synthetic fixture")
            git("tag", "-am", "Synthetic tag", "v0.0.1")
            self.assertEqual(scan("--history").returncode, 0)
            (root / "new.txt").write_text("local-only-sentinel")
            result = scan()
            self.assertEqual(result.returncode, 1)
            self.assertNotIn("local-only-sentinel", result.stdout)
            (root / "new.txt").unlink()
            git("-c", "user.name=Fixture", "-c", "user.email=fixture@example.invalid", "commit", "--allow-empty", "-qm", "Synthetic older identity")
            self.assertEqual(scan().returncode, 0)
            self.assertEqual(scan("--history").returncode, 1)
            git("config", "user.email", "fixture@example.invalid")
            self.assertEqual(scan().returncode, 1)


if __name__ == "__main__":
    unittest.main()
