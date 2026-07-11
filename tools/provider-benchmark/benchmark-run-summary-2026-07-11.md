# Provider Benchmark Run Summary - 2026-07-11

> Historical v0.2.5 investigation record. BabbelStream v0.3.0 replaced the serial 30-second-per-model policy described below with a 10-second Mini hedge and one 75-second overall transcription deadline.

## Purpose

This report summarizes the 5-minute scheduled provider benchmark run used to investigate BabbelStream dictation timeouts and unusually slow dictations.

The benchmark used the local fixture `tools/provider-benchmark/audio-fixture.m4a` and the provider configuration in `tools/provider-benchmark/.env`. Each scheduled tick ran one transcription request and one cleanup request, then wrote a privacy-safe JSON report under `/private/tmp/babbelstream-provider-benchmarks/`.

The reports intentionally exclude API keys, URLs, request bodies, response bodies, raw audio, transcripts, and cleanup text. They include only timing, status, byte counts, model labels, and sanitized error categories.

## Run Window

- Report files analyzed: 68
- First measured request: 2026-07-11 02:46:46 Europe/Berlin
- Last measured request: 2026-07-11 08:22:06 Europe/Berlin
- Provider host: `api.openai.com`
- Transcription model: `gpt-4o-transcribe`
- Cleanup model: `gpt-5.4-nano`
- Audio fixture size: 124,957 bytes
- Benchmark timeout: 90 seconds per request
- BabbelStream app transcription timeout for comparison: 30 seconds per model

## Headline Finding

The run recorded one clear provider-side transcription latency spike:

- At 2026-07-11 07:41:42 Europe/Berlin, the transcription request took 61,715.8 ms and still returned HTTP 200.
- The paired cleanup request in the same benchmark report took 718.7 ms.
- The adjacent scheduled samples recovered immediately: the next transcription sample at 07:46:27 Europe/Berlin took 1,064.6 ms.

This spike exceeds BabbelStream's configured 30-second per-model transcription timeout. In the app, the same provider behavior would be expected to time out the primary `gpt-4o-transcribe` attempt before the provider eventually returns successfully to the benchmark's longer 90-second request.

## Aggregate Results

| Stage | Requests | Successes | Failures | Min ms | Mean ms | P50 ms | P95 ms | P99 ms | Max ms | Stdev ms |
| --- | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: | ---: |
| Transcription | 68 | 68 | 0 | 891.9 | 2,129.3 | 1,198.8 | 1,790.2 | 21,711.8 | 61,715.8 | 7,338.1 |
| Cleanup | 68 | 68 | 0 | 718.7 | 1,093.9 | 1,026.4 | 1,711.1 | 1,811.2 | 1,826.4 | 272.3 |

The transcription mean, p99, max, and stdev are dominated by the single 61.7-second spike. Excluding requests over 30 seconds, transcription looked normal:

| Stage | Requests Included | Mean ms | P50 ms | Max ms | Stdev ms |
| --- | ---: | ---: | ---: | ---: | ---: |
| Transcription, excluding >30s outlier | 67 | 1,240.0 | 1,195.0 | 2,008.3 | 252.7 |
| Cleanup | 68 | 1,093.9 | 1,026.4 | 1,826.4 | 272.3 |

## Spike Evidence

| Local time | Stage | Latency ms | HTTP status | Error category | Report |
| --- | --- | ---: | ---: | --- | --- |
| 2026-07-11 07:41:42 Europe/Berlin | transcription | 61,715.8 | 200 | none | `/private/tmp/babbelstream-provider-benchmarks/provider-benchmark-20260711T074124+0200.json` |
| 2026-07-11 07:42:43 Europe/Berlin | cleanup | 718.7 | 200 | none | `/private/tmp/babbelstream-provider-benchmarks/provider-benchmark-20260711T074124+0200.json` |

Adjacent samples:

| Local time | Transcription ms | Cleanup ms | Report |
| --- | ---: | ---: | --- |
| 2026-07-11 07:36:23 Europe/Berlin | 1,009.0 | 984.6 | `/private/tmp/babbelstream-provider-benchmarks/provider-benchmark-20260711T073623+0200.json` |
| 2026-07-11 07:41:42 Europe/Berlin | 61,715.8 | 718.7 | `/private/tmp/babbelstream-provider-benchmarks/provider-benchmark-20260711T074124+0200.json` |
| 2026-07-11 07:46:27 Europe/Berlin | 1,064.6 | 1,440.3 | `/private/tmp/babbelstream-provider-benchmarks/provider-benchmark-20260711T074627+0200.json` |
| 2026-07-11 07:51:24 Europe/Berlin | 1,223.5 | 976.0 | `/private/tmp/babbelstream-provider-benchmarks/provider-benchmark-20260711T075124+0200.json` |

## Interpretation

The benchmark provides direct evidence that `gpt-4o-transcribe` can occasionally take longer than BabbelStream's 30-second per-model timeout while still eventually succeeding. The paired cleanup model did not show a corresponding stall, and normal transcription latency resumed on the next scheduled sample.

That pattern supports a provider-side intermittent transcription stall as at least one real contributor to today's dictation failures and long waits. It does not rule out app-side issues, but it gives us a concrete external spike that matches the failure shape seen in diagnostics: transcription requests timing out around 30 seconds, with cleanup usually normal when reached.

## Practical Implications

- A 30-second app timeout can convert a slow-but-eventually-successful transcription into an app-side timeout.
- Because fallback currently sends the same audio to `gpt-4o-mini-transcribe` after the primary timeout, a provider-side stall window can produce a long user-visible failure: roughly 30 seconds primary plus up to 30 seconds fallback.
- Cleanup latency was stable enough that cleanup is unlikely to explain the long dictation waits observed during this run.

## Suggested Next Steps

1. Keep the 5-minute benchmark running until the user is done investigating, because the spike was intermittent and short-lived.
2. Compare any future user-visible dictation timeout timestamps against the benchmark report files around the same time.
3. Add or keep app-side diagnostics that preserve the complete per-dictation timeline, especially recording stop, audio file size, request-prepared timestamps, upload/request start, primary/fallback start, timeout, response, cleanup, paste, archive, and temp-delete events.
4. Consider whether the app should make timeout behavior more explicit in the UI or settings, since the benchmark shows 30 seconds can be too short during intermittent provider stalls.
5. Preserve privacy boundaries: continue recording timings, statuses, byte counts, and categories only; do not log audio, transcripts, cleanup input/output, request bodies, response bodies, API keys, or clipboard contents.
