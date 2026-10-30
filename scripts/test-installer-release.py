#!/usr/bin/env python3
"""Release-channel drift regressions, using synthetic metadata only."""
import copy
import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("installer_release", Path(__file__).with_name("check-installer-release.py"))
checker = importlib.util.module_from_spec(spec)
spec.loader.exec_module(checker)


class InstallerReleaseTests(unittest.TestCase):
    def setUp(self):
        url = checker.REPOSITORY + "/releases/download/v1.2.3/BabbelStream-1.2.3.dmg"
        self.pins = dict(VERSION="1.2.3", SHA256="a" * 64, RELEASE_URL=url)
        self.release = dict(tag_name="v1.2.3", draft=False, prerelease=False, assets=[
            dict(name="BabbelStream-1.2.3.dmg", digest="sha256:" + "a" * 64, browser_download_url=url),
            dict(name="BabbelStream-1.2.3.dmg.sha256")])

    def test_matching_release(self):
        checker.validate_release(self.release, self.pins)

    def test_new_release_requires_pin_refresh(self):
        self.release["tag_name"] = "v1.3.0"
        with self.assertRaisesRegex(ValueError, "stale"):
            checker.validate_release(self.release, self.pins)

    def test_unpublished_or_preview_release_rejected(self):
        for flag in ("draft", "prerelease"):
            with self.subTest(flag=flag):
                release = dict(self.release, **{flag: True})
                with self.assertRaises(ValueError):
                    checker.validate_release(release, self.pins)

    def test_changed_bytes_or_url_rejected(self):
        for field, value in (("digest", "sha256:" + "b" * 64),
                             ("digest", None), ("browser_download_url", "https://example.invalid/app.dmg")):
            with self.subTest(field=field, value=value):
                release = copy.deepcopy(self.release)
                release["assets"][0][field] = value
                with self.assertRaises(ValueError):
                    checker.validate_release(release, self.pins)

    def test_missing_or_parallel_installer_assets_rejected(self):
        for assets in (self.release["assets"][:1], self.release["assets"] + [dict(name="preview.dmg")]):
            with self.subTest(assets=assets):
                with self.assertRaises(ValueError):
                    checker.validate_release(dict(self.release, assets=assets), self.pins)


if __name__ == "__main__":
    unittest.main()
