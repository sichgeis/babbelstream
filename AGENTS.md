## Project Guidance

This project is spec-driven. Start each implementation session by reading the relevant files in `docs/`, especially `docs/product-spec.md`, `docs/architecture.md`, `docs/security-privacy.md`, and `docs/implementation-plan.md`.

## Product Direction

- Build a native macOS push-to-talk dictation helper for Slack first, while keeping generic macOS text fields in scope.
- Keep the MVP as a local macOS-level helper, not a Slack app, Slack bot, browser extension, subscription product, or cloud service.
- Do not implement Slack API integration unless explicitly requested.
- Preserve the German, English, and mixed German-English technical dictation use case.
- The user reviews pasted drafts manually; the MVP must not auto-send Slack messages.

## Engineering Rules

- Prefer Swift, SwiftUI, AppKit/macOS APIs, AVFoundation, URLSession, Keychain, and XCTest when the local Xcode/CLT setup exposes it cleanly.
- Until XCTest/Swift Testing is available through SwiftPM in this environment, keep `BabbelStreamChecks` as the lightweight executable scaffold check.
- Do not introduce Electron.
- Do not add dependencies without documenting why they are needed and why native APIs are insufficient.
- Prefer small, testable milestones over broad feature batches.
- Keep provider configuration explicit and visible to the user.
- Do not silently send audio or text to unexpected providers.

## Privacy Rules

- Do not log transcripts or audio by default.
- Do not persist transcript history by default.
- Delete temporary audio immediately after processing unless explicit debug mode is enabled.
- Store API keys in macOS Keychain, not in files or `UserDefaults`.
- Ask before adding telemetry, analytics, cloud databases, paid services, or background sync.
- Keep Accessibility, microphone, and any input-monitoring implications explicit in UI copy, docs, and tests.
