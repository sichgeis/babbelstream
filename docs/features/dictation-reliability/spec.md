# Dictation routing, delivery and recovery

## Status and scope

The maintainer approved implementation and two feature-branch pushes on 2026-11-18. The changes are implemented for candidate 0.6.1, build 15. The public release is 0.6.0. This change covers the existing providers, clipboard delivery, Failed Recordings and setup instructions. The [implementation run](../../runs/active/dictation-reliability.md) records the development-Mac timings and pending pilot validation.

## Interaction and ownership

- At dictation start, capture the applied settings and current external application together. An unavailable or app-owned target makes the operation copy-only. A subsequent activation cannot supply a target. Explicit Paste Last Draft captures the current target again.
- A primary/Mini success can complete the work-provider phase. If both fail, switching accounts requires both failures to meet the existing reachability policy and the operation's explicit personal fallback opt-in. Completion order has no effect. Cancellation and the overall deadline end the phase.
- Failed Recordings identifies the originally selected transcription route independently of the currently applied retry destination. This describes routing policy at capture, not a receipt for a network transfer. Older records without reliable route information display an unknown route.
- Retry snapshots the current settings, registers Escape for the operation, preserves stopped audio on cancellation and only copies a successful draft. The menu and HUD provide cancellation if Escape registration fails.
- Save Audio As copies privately beside the destination and publishes the complete file atomically. A failed replacement preserves the previous export and recovery source.
- Operation state drives the HUD. Both local and remote cleanup show Cleaning up. Archive browsing and settings editing share the existing persistence contracts.
- Introduce local and remote setup together. Keep model preparation explicit. Measure fully local processing with short and long synthetic audio before considering other backends.

## Acceptance and manual smoke

Run `task check` with fixtures for mixed hedge failures in either order, capture and paste retry, export replacement, legacy and local route metadata, Escape during retry, and HUD phases. Keep transcript, audio and credentials out of diagnostics. Preserve the existing audio retention and permissions.

On the upgraded pilot Mac, time shortcut release to an unsent draft for short and long local dictations. Check permission and Keychain prompts, switching applications, failed-recording export and Escape during retry. A synthetic measurement covers processing and delivery preparation. Native keyboard delivery, microphone permissions and editor acceptance require the human smoke test.
