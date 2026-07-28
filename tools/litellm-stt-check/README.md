# LiteLLM STT Check

Tiny, isolated Python script to test whether a LiteLLM/OpenAI-compatible endpoint can transcribe an audio file.

## Which model?

Default: `gpt-transcribe`.

This is OpenAI's current high-accuracy file-transcription model and the preferred
model for BabbelStream. The configured LiteLLM/OpenAI-compatible endpoint must
expose it; use the script to confirm deployment compatibility before relying on
it.

Alternative probes:

- `gpt-4o-mini-transcribe`, which the app uses as its one-shot transient-failure fallback.
- `whisper-1` for the most conservative legacy compatibility probe.

The script does not assume the proxy supports any specific model; it prints the raw response so we can see exactly what the proxy allows.

## Setup

```bash
cd tools/litellm-stt-check
cp .env.example .env
```

Edit `.env`:

```dotenv
LITELLM_BASE_URL=https://your-litellm-host
LITELLM_API_KEY=your-token
LITELLM_STT_MODEL=gpt-transcribe
# Optional: a single ISO 639-1 language code such as de or en.
# Leave empty for mixed German-English dictation.
LITELLM_LANGUAGE=
```

For `gpt-transcribe`, the script sends the optional language as `languages[]`,
matching OpenAI's current API contract. Older model selections receive the
singular `language` field.

## Run

Use any short audio file (`.m4a`, `.mp3`, `.wav`, `.webm`, `.flac`):

```bash
python3 check_stt.py /path/to/audio.m4a
```

Optional model list probe:

```bash
python3 check_stt.py --models
```

Model listing support depends on your LiteLLM deployment, so a failed `--models` call does not necessarily mean transcription will fail.
