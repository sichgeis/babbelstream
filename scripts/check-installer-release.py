#!/usr/bin/env python3
"""Maintainer-only online check; never selects or trusts new installer pins."""
import json
from pathlib import Path
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parent.parent
REPOSITORY = "https://github.com/sichgeis/babbelstream"
APP_INPUTS = ["Sources", "NativeSpeech", "NativeCleanup", "Resources",
              "Package.swift", "Package.resolved", "VERSION", "BUILD_NUMBER",
              "scripts/build-app.sh", "scripts/build-local-speech.sh",
              "scripts/build-local-cleanup.sh", "scripts/swift-project.sh",
              "scripts/release-preflight.sh", "scripts/package-dmg.sh"]


def validate_release(release, pins):
    version = pins["VERSION"]
    if release.get("draft") or release.get("prerelease"):
        raise ValueError("Expected a public stable release.")
    if release.get("tag_name") != f"v{version}":
        raise ValueError("Installer pins are stale: refresh them from the latest verified release.")
    filename = f"BabbelStream-{version}.dmg"
    assets = release.get("assets", [])
    if sorted(asset["name"] for asset in assets) != sorted([filename, filename + ".sha256"]):
        raise ValueError("Release must have exactly the canonical DMG/checksum pair.")
    dmg = next(asset for asset in assets if asset["name"] == filename)
    expected_url = f"{REPOSITORY}/releases/download/v{version}/{filename}"
    if pins["RELEASE_URL"] != expected_url or dmg.get("browser_download_url") != expected_url:
        raise ValueError("Installer URL does not match the release.")
    if dmg.get("digest") != "sha256:" + pins["SHA256"]:
        raise ValueError("Installer checksum does not match the public asset digest.")


def git(*args):
    return subprocess.check_output(["git", *args], cwd=ROOT, text=True).strip()


def main():
    # This request belongs to an explicit developer/release check, never to the
    # installation helper or the app. Metadata cannot replace verified pins.
    response = subprocess.check_output([
        "/usr/bin/curl", "--silent", "--show-error", "--fail", "--location",
        "--proto", "=https", "--proto-redir", "=https", "--tlsv1.2",
        "--connect-timeout", "20", "--max-time", "60",
        "https://api.github.com/repos/sichgeis/babbelstream/releases/latest"], text=True)
    pins = dict(re.findall(r"^(VERSION|BUILD|SOURCE|SHA256|CDHASH|RELEASE_URL)=(\S+)$",
                           (ROOT / "scripts/prepare-downloaded-install.sh").read_text(), re.M))
    release = json.loads(response)
    validate_release(release, pins)
    tag = release["tag_name"]
    source = git("rev-parse", f"{tag}^{{commit}}")
    if not re.fullmatch(r"[0-9a-f]{7,40}", pins["SOURCE"]) or not source.startswith(pins["SOURCE"]):
        raise ValueError("Installer source does not match the release tag; refresh tags and verify the payload.")
    if git("show", f"{tag}:VERSION") != pins["VERSION"] or git("show", f"{tag}:BUILD_NUMBER") != pins["BUILD"]:
        raise ValueError("Installer version/build does not match the release tag.")
    subprocess.run(["git", "merge-base", "--is-ancestor", source, "HEAD"], cwd=ROOT, check=True)
    if git("diff", "--name-only", tag, "--", *APP_INPUTS):
        raise ValueError("App/build inputs differ from the release: review and publish a new version before claiming current-source coverage.")
    print(f"Installer matches latest public release {tag} and current app/build inputs.")
    print("Also run the helper with --verify-only --download to verify the actual payload and CDHash.")


if __name__ == "__main__":
    try:
        main()
    except (ValueError, KeyError, OSError, subprocess.SubprocessError) as error:
        print(f"Installer release check failed: {error}", file=sys.stderr)
        sys.exit(1)
