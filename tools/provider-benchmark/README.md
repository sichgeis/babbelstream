# Provider latency benchmark

This tool repeatedly calls the same OpenAI-compatible endpoints used by BabbelStream and measures transcription and cleanup independently. It reports success rate, errors, p50/p95/p99 latency, standard deviation, and median adjacent-request jitter. A 90-second benchmark timeout is used by default so requests near or beyond the app's 75-second overall transcription deadline can still be observed.

The JSON report contains timing, status/error categories, byte counts, model names, and the provider hostname. It never contains the API key, audio path/content, transcript, response body, or full endpoint URL. The real requests necessarily send the supplied audio and synthetic cleanup text to the configured provider.

## Setup

```bash
cd tools/provider-benchmark
cp .env.example .env
```

Set the same destination, key, and models as the app. `.env` is git-ignored.

## Run

Use a representative short recording. Reusing exactly the same file reduces input variability and makes provider jitter easier to see.

```bash
python3 benchmark.py /path/to/sample.m4a --iterations 20 --output results.json
```

Run either stage alone:

```bash
python3 benchmark.py /path/to/sample.m4a --stage transcription --iterations 20
python3 benchmark.py --stage cleanup --iterations 20
```

Useful investigation patterns:

```bash
# Observe responses beyond BabbelStream's current 75-second overall deadline.
python3 benchmark.py sample.m4a --timeout 120 --iterations 30 --output results.json

# Approximate the app's overall transcription deadline with one request.
python3 benchmark.py sample.m4a --timeout 75 --iterations 30 --output results-75s.json
```

Start with 10-20 iterations to avoid surprising provider cost. Runs are sequential and alternate transcription/cleanup when both are selected, avoiding artificial concurrency load. HTTP failures and timeouts produce a non-zero exit status while still writing the requested report.

The tool measures end-to-end client-observed request latency. Python's standard HTTP client does not expose reliable DNS/TCP/TLS/upload/first-byte sub-timings, so it does not pretend to distinguish those phases. Comparing 75-second and 90/120-second runs shows whether individual provider requests exceed the app's complete transcription deadline. The app itself may hedge Mini after 10 seconds, so this sequential benchmark does not reproduce the concurrent winner policy.
