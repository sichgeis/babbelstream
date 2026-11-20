# Dictation reliability implementation run

## Baseline and authority

Started from clean, pushed main at `decbc10`. Branch `codex/dictation-reliability`. The maintainer requested implementation, a first push, a cleanup pass and a second push. See [the approved contract](../../features/dictation-reliability/spec.md). The previous review passed the full baseline check using CMake 4.4.4.

## Stages

1. Pushed `bb513f7` with the provider, delivery, export, recovery metadata and cancellation fixes. The complete `task check` passed.
2. Replaced HUD text matching with typed operation state, extracted the settings draft and archive browser, and aligned the setup guides and specifications. The executable suite covers local cleanup presentation and archive load, export and clear. The final full check passed, including both native helper builds, 26 installer fixtures, five release-alignment fixtures and four hygiene fixtures. Relative file links in the changed documentation were checked.
3. Built candidate 0.6.1, build 15, from clean commit `795cc76`. On 2026-11-18 the maintainer requested installation on the development Mac. The DMG checksum and installed app signature passed. The installed files matched the read-only mounted image. Launch Services confirmed one running Applications copy at 0.6.1/build 15/`795cc76`. The previous 0.6.0/build 14 bundle is available under the ignored `dist/rollback/0.6.0-build14-before-0.6.1-build15/` directory. The public installer and tap still serve 0.6.0.

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

## Closeout

The maintainer waived the microphone-to-editor and focus-switch checks for
0.6.1. This change shipped in build 17. See the
[release evidence](release-v0.6.1.md).
