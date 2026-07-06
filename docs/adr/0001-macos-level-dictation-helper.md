# ADR 0001: Build A macOS-Level Dictation Helper

## Context

The user wants to dictate Slack messages quickly from a MacBook using a push-to-talk flow. The desired experience is local and app-level: focus Slack, hold a hotkey, speak, release, and receive a draft in the current text field. The solution should also work in other macOS text fields later.

## Decision

Build a native macOS-level push-to-talk helper instead of a Slack app, Slack bot, browser extension, or Electron app.

## Consequences

- The MVP can work in Slack desktop, browser Slack, and other focused text fields.
- The app must handle macOS permissions, hotkeys, audio capture, provider calls, clipboard paste, and privacy controls.
- Slack-specific APIs are avoided for MVP, reducing integration complexity and preventing the product from becoming a bot workflow.
- Clipboard and Accessibility behavior become important implementation and privacy risks.

## Alternatives Considered

- Slack bot: easier to post messages, but wrong UX because the user wants to draft in the focused composer.
- Slack app/API integration: useful later for channel/thread targeting, but unnecessary and riskier for MVP.
- Browser extension: would not cover Slack desktop or other native apps.
- Electron desktop app: faster for web UI but unnecessary for a small permission-heavy macOS utility.
- Local Whisper-first app: strong privacy, but too much packaging and performance complexity for the first milestone.

## Reversibility

The decision is reversible. The provider and cleanup architecture can later feed a Slack API integration, browser extension, email workflow, or local Whisper backend. The MVP should avoid coupling core dictation logic to Slack-specific APIs so future pivots remain cheap.
