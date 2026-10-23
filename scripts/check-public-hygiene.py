#!/usr/bin/env python3
"""Scan public inputs without printing private matches or opening ignored files."""
import argparse
import collections
from pathlib import Path
import re
import subprocess

PUBLIC_NAME = "sichgeis"
PUBLIC_EMAIL = "25384988+sichgeis@users.noreply.github.com"
SYNTHETIC_PATH_FILE = "Sources/BabbelStreamChecks/PilotReadinessChecks.swift"


def git(*args):
    return subprocess.check_output(["git", *args])


def violations(data, denylist, allow_synthetic_path=False):
    text = data.decode("utf-8", errors="replace")
    if allow_synthetic_path:
        text = text.replace("/Users/" + "private-user/", "/fixture/")
    findings = collections.Counter()
    if re.search(r"/Users/[\w.-]+", text):
        findings["private home path"] += 1
    for host in re.findall(r"\b[\w-]+(?:\.[\w-]+)*\.(?:local|fritz\.box)\b", text, re.I):
        if not re.search(r"(?:^|\.)example\.local$", host, re.I):
            findings["private hostname"] += 1
    for email in re.findall(r"[\w.+-]+@[\w.-]+\.[A-Za-z]{2,}", text):
        domain = email.rsplit("@", 1)[1].lower()
        if domain not in {"users.noreply.github.com", "noreply.github.com", "anthropic.com"} and not re.search(r"(?:^|\.)example\.(?:com|org|net|invalid)$", domain):
            findings["non-public email"] += 1
        elif domain == "anthropic.com" and email != "noreply@anthropic.com":
            findings["non-public email"] += 1
    lowered = text.casefold()
    for term in denylist:
        if term.casefold() in lowered:
            findings["local denylist match"] += 1
    return findings


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--history", action="store_true", help="Also audit all reachable blobs, commit/tag messages and identities")
    parser.add_argument("--binary", type=Path, action="append", default=[], help="Scan strings from a specified optimized executable")
    args = parser.parse_args()
    root = Path(git("rev-parse", "--show-toplevel").decode().strip())
    common = Path(git("rev-parse", "--git-common-dir").decode().strip())
    deny_path = common / "info" / "hygiene-denylist"
    denylist = [line.strip() for line in deny_path.read_text().splitlines() if line.strip() and not line.startswith("#")] if deny_path.exists() else []
    findings = collections.Counter()
    for key, expected in [("user.name", PUBLIC_NAME), ("user.email", PUBLIC_EMAIL)]:
        actual = subprocess.run(["git", "config", key], capture_output=True, text=True)
        if actual.returncode or actual.stdout.strip() != expected:
            findings["effective Git identity"] += 1
    paths = set(git("ls-files", "-z", "--cached", "--others", "--exclude-standard").decode().split("\0")) - {""}
    for name in paths:
        path = root / name
        if path.is_symlink():
            findings["unreviewed symlink"] += 1
        elif path.is_file():
            findings.update(violations(path.read_bytes(), denylist, name == SYNTHETIC_PATH_FILE))
    if args.history:
        identities = git("log", "--all", "--format=%an%x00%ae%x00%cn%x00%ce").decode().splitlines()
        expected = [PUBLIC_NAME, PUBLIC_EMAIL, PUBLIC_NAME, PUBLIC_EMAIL]
        findings["historical commit identity"] += sum(row.split("\0") != expected for row in identities)
        findings.update(violations(git("log", "--all", "--format=%B"), denylist))
        for ref in git("for-each-ref", "--format=%(refname)", "refs/tags").decode().splitlines():
            if git("cat-file", "-t", ref).strip() == b"tag":
                tag = git("cat-file", "tag", ref)
                header, _, message = tag.partition(b"\n\n")
                expected_tagger = f"tagger {PUBLIC_NAME} <{PUBLIC_EMAIL}> ".encode()
                if not any(line.startswith(expected_tagger) for line in header.splitlines()):
                    findings["historical tag identity"] += 1
                findings.update(violations(message, denylist))
        objects = git("rev-list", "--objects", "--all", "--no-object-names").decode().splitlines()
        # Stream objects through one process rather than spawning per historical blob.
        with subprocess.Popen(["git", "cat-file", "--batch"], stdin=subprocess.PIPE, stdout=subprocess.PIPE) as batch:
            for oid in objects:
                batch.stdin.write((oid + "\n").encode())
                batch.stdin.flush()
                header = batch.stdout.readline().split()
                size = int(header[2])
                data = batch.stdout.read(size)
                assert batch.stdout.read(1) == b"\n"
                if header[1] == b"blob":
                    synthetic = data.startswith(b"import Foundation") and b"func runPilotReadinessChecks()" in data
                    findings.update(violations(data, denylist, synthetic))
            batch.stdin.close()
            if batch.wait() != 0:
                raise RuntimeError("History object scan failed")
    for binary in args.binary:
        findings.update(violations(subprocess.check_output(["strings", str(binary)]), denylist))
    findings = +findings
    if findings:
        print("Public hygiene failed (counts only):")
        for category, count in sorted(findings.items()):
            print(f"  {category}: {count}")
        return 1
    print(f"Public hygiene passed: {len(paths)} files; {'local denylist loaded' if denylist else 'generic checks only'}.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
