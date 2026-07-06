# LiteLLM STT Check

Tiny, isolated Python script to test whether a LiteLLM/OpenAI-compatible endpoint can transcribe an audio file.

## Which model?

Default: `gpt-4o-transcribe`.

This is the preferred model for the product because it has the best speech-to-text quality among the OpenAI transcription models we evaluated and works with the configured LiteLLM/OpenAI-compatible `.env` setup.

Fallbacks to try if access changes:

- `gpt-4o-mini-transcribe` for the likely cheaper modern transcription model.
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
LITELLM_STT_MODEL=gpt-4o-transcribe
# Optional: a single ISO 639-1 language code such as de or en.
# Leave empty for mixed German-English dictation.
LITELLM_LANGUAGE=
```

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
