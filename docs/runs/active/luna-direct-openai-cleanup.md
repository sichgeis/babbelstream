# Direct OpenAI Luna Cleanup Implementation Run

## Outcome

Restore GPT-6 Luna cleanup on the official OpenAI endpoint with reasoning disabled.

## Baseline

- Clean, pushed `main` at `49728b1`. Implementation branch `codex/luna-direct-openai-cleanup`.
- Installed release 0.6.1 build 17. Candidate build 18.
- The last baseline `task check` passed using the documented public Git identity for the command.

## Scope And Authority

- The maintainer requested a fix that preserves GPT-6 Luna and reasoning disabled.
- The existing [Luna specification](../../features/luna-cleanup/spec.md) covers the request contract. Leave the proxy request, other models, provider settings and recovery behavior intact.
- The maintainer approved two synthetic requests to the existing official OpenAI endpoint and local candidate installation. Public release changes are outside this run.

## Diagnosis And Validation

- Three direct OpenAI cleanup attempts returned HTTP 400 with identical 245-byte responses after successful transcription. The logs omit provider response bodies.
- The response size matches the standard unsupported-temperature error encoding. This is the leading diagnosis. Keychain access from the diagnostic process failed before any synthetic request was sent.
- Proxy validation for 0.6.1 succeeded with temperature zero. The direct request now leaves temperature at the provider default and still explicitly disables reasoning.
- Exercise the production request builder with the official origin and a URLSession stub. Exercise both compatible proxy Luna IDs and one custom model with the existing loopback fixture.
- `task check` passed with the documented public Git identity and no live requests.

## Next Action

Package and verify the candidate for the approved local installation.
