# Troubleshooting

[Back to BabbelStream](../README.md) · [Setup guide](getting-started.md)


### Dictation copies the draft but does not paste into Codex or another app

First open **Set Up BabbelStream…** and check **Automatic paste**, or check
**Accessibility** in General Settings. Microphone permission lets recording work;
Accessibility is separately required to post the paste shortcut.

If BabbelStream says **Not allowed** while System Settings shows its switch on,
the enabled row may refer to an older app identity. We observed this exact
mismatch with the installed 0.5.1 build. Removing and re-adding the current
Applications copy restored its live **Allowed** status, and the local sample-paste
test then passed. The maintainer also confirmed direct insertion into the Codex input
afterward. To repair this mismatch:

1. Finish active work and quit BabbelStream normally.
2. Open **System Settings → Privacy & Security → Accessibility**. Select only
   **BabbelStream** and remove its entry with the minus button. Authenticate in
   the macOS dialog yourself if requested.
3. Add `/Applications/BabbelStream.app` with the plus button and enable its switch.
   Leave other applications' permissions unchanged.
4. Reopen the Applications copy. In setup, choose **Check Again** and confirm
   **Automatic paste — Allowed**. The running app's result matters more than an
   enabled System Settings row.
5. Run the optional local paste test (it replaces the clipboard with a harmless
   sample), then focus the Codex input and try harmless dictation while keeping
   Codex frontmost. Confirm the draft appears once and remains unsent.

This repairs an OS permission entry; it does not require a new app build, a paid
Apple membership, Keychain changes or a permission reset for every application.
Ad-hoc rebuilds may require reapproval again. The exact reason an old grant stops
matching is not established by the toggle alone.

If Accessibility is **Allowed** but insertion still fails, check the app's result:
**active application changed** means it deliberately avoided pasting into another
app; **paste shortcut sent** means it posted Command-V but cannot prove the editor
accepted it. Use manual paste for recovery and report that distinction. Do not
repeat automatic paste blindly, which could duplicate text.

### Homebrew says installed, but the app is missing

Homebrew's installed record can remain when the Applications bundle is missing.
Quit any remaining BabbelStream copy, then restore the app without deleting its
settings or keys:

```sh
brew reinstall --cask sichgeis/tap/babbelstream
```

Open **Finder → Applications → BabbelStream**. If macOS displays the
non-notarized-app warning, choose **Done**, then use **Privacy & Security → Open
Anyway** where device policy permits. **Move to Trash** removes the app bundle;
it is not the approval action. The pilot encountered a missing bundle despite a
Homebrew installed record; its disappearance cause was not established. Reinstall
restored the verified 0.5.1 bundle successfully.

### Keychain asks for your password after every restart

**Symptom:** dictation works, but the first transcription after quitting and
reopening BabbelStream asks for your login Keychain password again, even after
choosing **Always Allow**.

This occurred on macOS 27.0.1 when upgrading a manual 0.4.5 installation to the
ad-hoc-signed 0.5.1 pilot. The saved key remained, but repeated approval did not
resolve access. A signing/trust mismatch is suspected; the root cause is not
confirmed. The following per-item repair resolved the reported restart test:

1. Open **Keychain Access** (choose it rather than Passwords if macOS offers both).
2. Select the **login** keychain and search for `com.sichgeis.babbelstream`.
3. Open the application-password item with account **provider-api-key**, then
   select **Access Control**. Leave **Show password** unchecked.
4. Keep **Confirm before allowing access** selected. Under **Always allow access
   by these applications**, click **+** and add `/Applications/BabbelStream.app`.
   Existing BabbelStream entries may refer to older builds; in the reported case,
   adding the current Applications copy worked without removing those entries.
5. Choose **Save Changes** and authenticate in the macOS dialog if requested.
6. Quit and reopen BabbelStream, then dictate harmless text into an unsent draft.
   Confirm the text appears once without a Keychain prompt; repeat the restart
   test to check that access persists.

Do not enable **Allow all applications to access this item**, reveal/share the
key, or delete the Keychain item as a repair. If saving is blocked or the prompt
returns, report the macOS version, BabbelStream version/commit and reproduction
steps without including passwords or private dictation.

This repair was confirmed for the installed 0.5.1 build; it does not establish
that trust survives a future Homebrew upgrade. Ad-hoc builds can change identity
between versions. See [Apple's Keychain access guidance](https://support.apple.com/en-gb/guide/mac-help/kychn002/mac).

