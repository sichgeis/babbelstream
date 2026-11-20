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

Run one harmless unsent dictation with the installed candidate and confirm that the direct OpenAI cleanup completes without HTTP 400.

## Candidate Evidence

- 0.6.1 build 18 from `a5b22d0`, packaged as `BabbelStream-0.6.1-candidate.18-a5b22d0.dmg`.
- SHA-256 `c43e3952fcc497002da5617e5d8dcb62721fb268742bdb1856fd597f70949466`.
- DMG checksum and integrity, mounted and installed bundle signatures, and running installed version verified. The saved cleanup model is `gpt-6-luna`.
- The live probe stopped at Keychain access. No live cleanup validation has been recorded. Public 0.6.1 remains build 17.
