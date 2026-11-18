# Dictation reliability implementation run

## Baseline and authority

Started from clean, pushed main at `decbc10`. Branch `codex/dictation-reliability`. The maintainer requested implementation, a first push, a cleanup pass and a second push. See [the approved contract](../../features/dictation-reliability/spec.md). The previous review passed the full baseline check using CMake 4.4.4.

## Stages

1. Pushed `bb513f7` with the provider, delivery, export, recovery metadata and cancellation fixes. The complete `task check` passed.
2. Replaced HUD text matching with typed operation state, extracted the settings draft and archive browser, and aligned the setup guides and specifications. The executable suite covers local cleanup presentation and archive load, export and clear. The final full check passed, including both native helper builds, 26 installer fixtures, five release-alignment fixtures and four hygiene fixtures. Relative file links in the changed documentation were checked.
3. Candidate version 0.6.1, build 15. Build the local ad-hoc DMG from the clean second milestone with `task app:candidate`. The filename embeds the source commit and the adjacent checksum identifies the image. The published installer and tap still serve 0.6.0.

## Local processing measurement

On 2026-11-18, the development Mac (Apple M5, 16 GiB, macOS 26.7.3) ran Parakeet Ultra transcription and Qwen3.5-4B cleanup on six synthetic inputs. The coordinator at the first milestone used the real local model stores and optimized, network-denied helper processes with disposable copies of the prepared models. The recorder, provider, credentials and insertion adapters were fixtures. The short input was the repository's synthetic benchmark clip. The long input repeated that clip to 60 seconds.

| Run order | Audio duration | Stop to prepared draft |
| --- | ---: | ---: |
| 1 | 7.08 s | 22.18 s |
| 2 | 60 s | 5.29 s |
| 3 | 7.08 s | 3.93 s |
| 4 | 60 s | 4.38 s |
| 5 | 7.08 s | 4.03 s |
| 6 | 60 s | 4.36 s |

Timing starts at the coordinator's Stop call and ends when it hands the draft to insertion. All six runs completed local cleanup and released the stopped audio. The first invocation took longest. OS caches were uncontrolled. Shortcut delivery, physical microphone input, editor acceptance, recognition quality and the upgraded pilot Mac require separate measurement.

## Next action

On the upgraded pilot Mac, run the [manual smoke test](../../features/dictation-reliability/spec.md#acceptance-and-manual-smoke) against the 0.6.1 candidate and record the results before promoting the release.
