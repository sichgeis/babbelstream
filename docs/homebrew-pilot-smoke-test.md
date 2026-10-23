# Download And Launch Quality Gate

Run this on the other Apple Silicon Mac before public rollout. Sign into GitHub
as `sichgeis` (or an account authorized to view draft releases). The release is
still a draft; a logged-out browser or ordinary colleague cannot see it yet.

[Open the draft release](https://github.com/sichgeis/babbelstream/releases/tag/untagged-f78f4e549aca8f0b9aea)

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

After a pass, the agent publishes the release, verifies the anonymous download,
and advances the cask into the tap default branch. Then test the actual public
`brew install --cask sichgeis/tap/babbelstream` path, including handling a preexisting
manual app. Until then the normal install command is intentionally unavailable.
First real upgrade, uninstall retention and rollback remain separate pilot checks.
