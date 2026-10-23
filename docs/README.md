# BabbelStream Documentation

Start with the [app README](../README.md) for a short introduction. Version 0.5.2
is publicly available through the non-notarized own-tap pilot; its initial
installation and dictation validation is complete. Deferred lifecycle checks
remain in the implementation plan. [Project status](project-status.md) owns the current
state and the single next action.

## Use the app

| Guide | Use it for |
| --- | --- |
| [Get started](getting-started.md) | Installation, onboarding, providers, dictation, recovery and removal |
| [Pilot support](pilot-support.md) | Company setup, connection states, credentials and support reports |
| [Download/launch checklist](homebrew-pilot-smoke-test.md) | The required other-Mac test before public rollout |
| [Changelog](../CHANGELOG.md) | User-visible changes by version |

## Maintain and release

| Guide | Use it for |
| --- | --- |
| [Local development](development.md) | Build commands, toolchain, local install and canonical validation |
| [Homebrew operations](homebrew-release.md) | Draft/public release order, cask updates, upgrades and rollback |
| [Release guide](release.md) | Versions, clean-source packaging, signing channels and provenance |
| [Test plan](test-plan.md) | Automated evidence and manual checks that remain necessary |
| [Implementation plan](implementation-plan.md) | Candidate work and deferred delivery dependencies |
| [Provider lifecycle](provider-lifecycle.md) | Model compatibility follow-ups and deadlines |

## Understand the contracts

- [Product](product-spec.md): workflow, scope and acceptance.
- [Privacy and security](security-privacy.md): data, providers, permissions and retention.
- [Architecture](architecture.md): native components, state and delivery boundaries.
- [Homebrew feature](features/homebrew-distribution/spec.md): the approved non-notarized pilot contract.
- [Onboarding feature](features/onboarding-and-updates/spec.md): setup and local paste behavior.
- [Project playbook](spec-driven-development.md) and [AGENTS.md](../AGENTS.md): how changes are specified, checked and released.

Feature contracts live in `features/`. Current execution evidence lives in
`runs/active/`; completed runs live in `runs/archive/`. A proposal or archived test
record does not imply that a current distribution path has passed its own gate.
