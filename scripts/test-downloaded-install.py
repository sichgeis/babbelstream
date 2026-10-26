#!/usr/bin/env python3
"""Exercise the helper with synthetic bundles and fake macOS commands only."""
import hashlib
import os
from pathlib import Path
import plistlib
import pty
import select
import subprocess
import tempfile
import time
import unittest


ROOT = Path(__file__).resolve().parent.parent
MOCK = r'''#!/bin/bash
set -euo pipefail
name="${0##*/}"
printf '%s\n' "$name $*" >> "$FIXTURE_ROOT/events"
case "$name" in
  uname) if [[ "$1" == -s ]]; then echo Darwin; else echo arm64; fi ;;
  sw_vers) echo 26.7.1 ;;
  curl)
    [[ "${FAULT:-}" != download ]] || exit 1
    while [[ "$1" != --output ]]; do shift; done
    /bin/cp "$FIXTURE_ROOT/synthetic download \$(never execute); example.dmg" "$2" ;;
  pgrep) [[ "${FAULT:-}" == running ]] ;;
  hdiutil)
    case "$1" in
      verify) [[ "${FAULT:-}" != image ]] ;;
      attach)
        [[ "${FAULT:-}" != attach ]] || exit 1
        shadow=false
        for arg in "$@"; do [[ "$arg" != -shadow ]] || shadow=true; done
        if $shadow; then
          [[ "${FAULT:-}" != shadow ]] || exit 1
          /usr/bin/touch "$FIXTURE_ROOT/shadow-mounted"
        fi
        while [[ "$1" != -mountpoint ]]; do shift; done
        /usr/bin/ditto "$FIXTURE_ROOT/source.app" "$2/BabbelStream.app"
        /usr/bin/touch "$2/.DS_Store"
        /bin/mkdir -p "$2/.background"
        /usr/bin/touch "$2/.background/installer-background.png"
        if [[ "${FAULT:-}" != shortcut ]]; then /bin/ln -s /Applications "$2/Applications"; fi
        /usr/bin/touch "$FIXTURE_ROOT/quarantine" ;;
      detach) /bin/rm -rf "$2/BabbelStream.app" "$2/Applications" "$2/.DS_Store" "$2/.background" ;;
    esac ;;
  lipo) if [[ "${FAULT:-}" == arch ]]; then echo x86_64; else echo arm64; fi ;;
  codesign)
    case "$*" in
      *--verify*)
        [[ "${FAULT:-}" != signature ]] || exit 1
        if [[ "${FAULT:-}" == copied && -e "$FIXTURE_ROOT/shadow-mounted" ]]; then exit 1; fi ;;
      *--entitlements*) /bin/cat "$FIXTURE_ROOT/entitlements.plist" ;;
      *)
        echo 'CDHash=8ae6266b8ce2389dd4b6f356fc8a66c120b7c85c' >&2
        echo 'Signature=adhoc' >&2
        echo 'CodeDirectory flags=0x10002(adhoc,runtime)' >&2 ;;
    esac ;;
  ditto) /usr/bin/ditto "$1" "$2"; /usr/bin/touch "$FIXTURE_ROOT/quarantine" ;;
  xattr)
    [[ "${FAULT:-}" != attributes ]] || exit 1
    if [[ "$1" == -dr ]]; then
      [[ "$2" == com.apple.quarantine && "$3" == "$TMPDIR"/babbelstream-install.*/mounted/BabbelStream.app ]] || exit 9
      [[ "${FAULT:-}" != remove ]] || exit 1
      /bin/rm -f "$FIXTURE_ROOT/quarantine"
    else
      if [[ -e "$FIXTURE_ROOT/quarantine" ]]; then echo 'com.apple.quarantine'; fi
      echo 'com.apple.provenance'
    fi ;;
  open) : ;;
esac
'''


class DownloadedInstallTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="babbelstream-helper-fixture.")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.bin = self.root / "bin"
        self.bin.mkdir()
        self.staging = self.root / "staging"
        self.staging.mkdir()
        self.dmg = self.root / 'synthetic download $(never execute); example.dmg'
        self.dmg.write_bytes(b"synthetic installer fixture\n")
        self.digest = hashlib.sha256(self.dmg.read_bytes()).hexdigest()
        self.app = self.root / "source.app"
        (self.app / "Contents/MacOS").mkdir(parents=True)
        (self.app / "Contents/MacOS/BabbelStream").write_text("synthetic executable")
        self.info = dict(CFBundleIdentifier="com.sichgeis.babbelstream",
                         CFBundleExecutable="BabbelStream", CFBundleShortVersionString="0.5.3",
                         CFBundleVersion="11", BabbelStreamGitCommit="b9c0641")
        self.write_info()
        (self.root / "entitlements.plist").write_bytes(plistlib.dumps({
            "com.apple.security.device.audio-input": True}))
        mock = self.bin / "mock"
        mock.write_text(MOCK)
        mock.chmod(0o755)
        for name in ("uname", "sw_vers", "curl", "pgrep", "hdiutil", "lipo", "codesign", "ditto", "xattr", "open"):
            (self.bin / name).symlink_to(mock)
        source = (ROOT / "scripts/prepare-downloaded-install.sh").read_text()
        source = source.replace("export PATH=/usr/bin:/bin:/usr/sbin:/sbin",
                                f"export PATH='{self.bin}':/usr/bin:/bin:/usr/sbin:/sbin")
        source = source.replace("41b8aed841824c66862b65a11c576364300e3cbd07760370e81f76b77a6a99a2", self.digest)
        # Isolate receipt detection from any actual installed software.
        source = source.replace("/opt/homebrew/Caskroom/babbelstream", str(self.root / "receipt"))
        source = source.replace("/usr/local/Caskroom/babbelstream", str(self.root / "receipt-other"))
        source = source.replace("/Applications/BabbelStream.app", str(self.root / "Installed.app"))
        self.helper = self.root / "helper.sh"
        self.helper.write_text(source)
        self.env = dict(os.environ, FIXTURE_ROOT=str(self.root), TMPDIR=str(self.staging), FAULT="")

    def write_info(self):
        (self.app / "Contents/Info.plist").write_bytes(plistlib.dumps(self.info))

    def run_helper(self, *, interactive=False, consent="", fault="", verify=False, mode=None):
        command = ["/bin/bash", str(self.helper)] + (["--verify-only"] if verify else []) + ([mode] if mode else [str(self.dmg)])
        env = dict(self.env, FAULT=fault)
        if not interactive:
            result = subprocess.run(command, env=env, capture_output=True, text=True, timeout=15)
            return result.returncode, result.stdout + result.stderr
        master, slave = pty.openpty()
        process = subprocess.Popen(command, env=env, stdin=slave, stdout=slave, stderr=slave)
        os.close(slave)
        output = b""
        deadline = time.monotonic() + 15
        sent = False
        try:
            while time.monotonic() < deadline:
                if select.select([master], [], [], 0.1)[0]:
                    try:
                        chunk = os.read(master, 65536)
                    except OSError:
                        break
                    if not chunk:
                        break
                    output += chunk
                    if b"Type PREPARE" in output and not sent:
                        os.write(master, (consent + "\n").encode())
                        sent = True
            if process.poll() is None:
                process.wait(timeout=2)
        finally:
            if process.poll() is None:
                process.kill()
            process.wait()
            os.close(master)
        return process.returncode, output.decode()

    def events(self):
        path = self.root / "events"
        return path.read_text() if path.exists() else ""

    def assert_untouched(self):
        self.assertEqual(hashlib.sha256(self.dmg.read_bytes()).hexdigest(), self.digest)
        self.assertNotIn("xattr -dr", self.events())
        self.assertNotIn("\nopen ", self.events())
        self.assertEqual(list(self.staging.iterdir()), [])

    def test_verify_only_has_no_mutation(self):
        code, output = self.run_helper(verify=True)
        self.assertEqual(code, 0, output)
        self.assertIn("Verification only", output)
        self.assert_untouched()

    def test_noninteractive_cannot_consent(self):
        code, _ = self.run_helper()
        self.assertNotEqual(code, 0)
        self.assert_untouched()

    def test_cancel_cleans_staging(self):
        code, output = self.run_helper(interactive=True)
        self.assertEqual(code, 0, output)
        self.assertIn("Cancelled", output)
        self.assert_untouched()

    def test_prepare_scopes_mutation_and_retains_app(self):
        code, output = self.run_helper(interactive=True, consent="PREPARE")
        self.assertEqual(code, 0, output)
        self.assertIn("NOT notarized", output)
        self.assertEqual(hashlib.sha256(self.dmg.read_bytes()).hexdigest(), self.digest)
        self.assertEqual(self.events().count("xattr -dr com.apple.quarantine"), 1)
        self.assertIn("\nopen ", self.events())
        self.assertNotIn("open -R", self.events())
        self.assertIn("hdiutil attach -shadow", self.events())
        directories = list(self.staging.iterdir())
        self.assertEqual(len(directories), 1)
        mounted = directories[0] / "mounted"
        self.assertTrue((mounted / "BabbelStream.app").is_dir())
        self.assertEqual(os.readlink(mounted / "Applications"), "/Applications")
        self.assertTrue((mounted / ".DS_Store").exists())
        self.assertTrue((mounted / ".background/installer-background.png").exists())
        self.assertTrue((directories[0] / "release.dmg").exists())
        # Only the verification mount was detached; Finder retains the shadow view.
        self.assertEqual(self.events().count("hdiutil detach"), 1)

    def test_corrupt_download_stops_before_mount(self):
        self.dmg.write_bytes(b"corrupt")
        code, output = self.run_helper(verify=True)
        self.assertNotEqual(code, 0)
        self.assertIn("Checksum mismatch", output)
        self.assertNotIn("hdiutil attach", self.events())
        self.assertEqual(list(self.staging.iterdir()), [])

    def test_wrong_metadata_rejected(self):
        for key in self.info:
            with self.subTest(key=key):
                original = self.info[key]
                self.info[key] = "unexpected"
                self.write_info()
                code, _ = self.run_helper(verify=True)
                self.assertNotEqual(code, 0)
                self.assert_untouched()
                self.info[key] = original

    def test_failures_never_reveal_or_leave_unverified_app(self):
        for fault in ("image", "attach", "shadow", "shortcut", "arch", "signature", "copied", "attributes", "remove", "running"):
            with self.subTest(fault=fault):
                (self.root / "events").write_text("")
                (self.root / "shadow-mounted").unlink(missing_ok=True)
                code, output = self.run_helper(interactive=True, consent="PREPARE", fault=fault)
                self.assertNotEqual(code, 0, output)
                self.assertNotIn("\nopen ", self.events())
                self.assertEqual(list(self.staging.iterdir()), [])
                self.assertEqual(hashlib.sha256(self.dmg.read_bytes()).hexdigest(), self.digest)

    def test_homebrew_receipt_rejected(self):
        (self.root / "receipt").mkdir()
        code, output = self.run_helper(interactive=True, consent="PREPARE")
        self.assertNotEqual(code, 0)
        self.assertIn("Homebrew", output)
        self.assert_untouched()

    def test_debug_entitlement_rejected(self):
        (self.root / "entitlements.plist").write_bytes(plistlib.dumps({
            "com.apple.security.device.audio-input": True, "com.apple.security.get-task-allow": True}))
        code, _ = self.run_helper(verify=True)
        self.assertNotEqual(code, 0)
        self.assert_untouched()

    def test_download_verifies_without_mutation(self):
        code, output = self.run_helper(verify=True, mode="--download")
        self.assertEqual(code, 0, output)
        self.assertIn("curl --fail --location --proto =https --proto-redir =https", self.events())
        self.assert_untouched()

    def test_failed_download_cleans_up(self):
        code, _ = self.run_helper(verify=True, mode="--download", fault="download")
        self.assertNotEqual(code, 0)
        self.assertNotIn("hdiutil attach", self.events())
        self.assert_untouched()

    def install_fixture(self, version, build):
        self.info["CFBundleShortVersionString"] = version
        self.info["CFBundleVersion"] = build
        self.write_info()
        import shutil
        shutil.copytree(self.app, self.root / "Installed.app")

    def test_update_current_version_is_noop(self):
        self.install_fixture("0.5.3", "11")
        code, output = self.run_helper(interactive=True, mode="--update")
        self.assertEqual(code, 0, output)
        self.assertIn("already installed", output)
        self.assertNotIn("curl", self.events())
        self.assert_untouched()

    def test_update_rejects_downgrade(self):
        self.install_fixture("0.6.0", "12")
        code, output = self.run_helper(interactive=True, mode="--update")
        self.assertNotEqual(code, 0)
        self.assertIn("newer", output)
        self.assert_untouched()

    def test_update_older_version_prepares_without_replacing(self):
        self.install_fixture("0.5.1", "8")
        # Downloaded release remains 0.5.3; installed copy is the older fixture.
        self.info["CFBundleShortVersionString"] = "0.5.3"
        self.info["CFBundleVersion"] = "11"
        self.write_info()
        code, output = self.run_helper(interactive=True, consent="PREPARE", mode="--update")
        self.assertEqual(code, 0, output)
        info = plistlib.loads((self.root / "Installed.app/Contents/Info.plist").read_bytes())
        self.assertEqual(info["CFBundleShortVersionString"], "0.5.1")
        self.assertIn("\nopen ", self.events())


if __name__ == "__main__":
    unittest.main()
