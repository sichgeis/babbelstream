# Download And Launch Quality Gate

Run this on an Apple Silicon pilot Mac before broader rollout. The 0.5.1 release
is now public; GitHub sign-in is not required. Its prepublication download/launch
gate passed on macOS 27.0.1 after the documented Keychain access repair. Public
Homebrew installation/reinstall also passed, followed by successful launch and
dictation without a Keychain prompt. A further Homebrew-copy restart and a real
upgrade to a later version remain separately untested.

[Open the release](https://github.com/sichgeis/babbelstream/releases/tag/v0.5.1)

1. In your browser, download both `BabbelStream-0.5.1.dmg` and its `.sha256` asset.
   Use the browser for the actual downloaded/quarantined launch test; a CLI download
   and local signature check alone do not prove this path.
2. In Terminal, change to the folder containing both downloads and run:

   ```sh
   shasum -a 256 -c BabbelStream-0.5.1.dmg.sha256
   ```

   Expect `BabbelStream-0.5.1.dmg: OK`. Stop if the checksum differs.
3. Finish any dictation/recovery and quit old BabbelStream copies normally. Keep a
   backup of the existing app if present. Open the DMG, copy the app to Applications,
   eject the DMG, and launch the Applications copy. Keep user data/Keychain intact.
4. Record any macOS warning. For an unidentified/unnotarized-app warning, follow
   Apple's supported Privacy & Security > Open Anyway flow if device policy allows.
   If unavailable, stop and report the IT restriction. Do not disable Gatekeeper,
   remove quarantine, reset permissions or grant Full Disk Access as a workaround.
5. Confirm **0.5.1 / build 7 / commit 8f229fe** in Settings/Diagnostics. In setup,
   explicitly approve microphone and Accessibility if desired. Run the local paste
   test: its sample must actually appear, without a provider call or recording.
6. Only with your authorized provider/key and harmless sample content, dictate into
   an unsent TextEdit or Slack field. Confirm one insertion, no auto-send, normal
   tap/hold behavior, and retained settings after quit/relaunch. No work data or
   key should be included in the report.

Reply with:

- Mac architecture and macOS version.
- Checksum OK or failure.
- Launch result and exact warning/approval steps (or IT block).
- Version/build/commit.
- Permission and local paste results; authorized dictation result or explicitly skipped.
- Any unexpected behavior.

For a new release, a pass gates publication, anonymous-download verification and
advancing the cask into the tap default branch. For published 0.5.1, test the public
`brew install --cask sichgeis/tap/babbelstream` path, including handling a preexisting
manual app: quit it, preserve/move its bundle aside, then run the ordinary install.
First real upgrade, uninstall retention and rollback remain separate pilot checks.
