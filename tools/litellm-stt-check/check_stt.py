#!/usr/bin/env python3
"""Check an OpenAI-compatible LiteLLM speech-to-text endpoint.

This script intentionally uses only the Python standard library so it can run
without disturbing the Swift/macOS app work happening elsewhere in the repo.
"""

from __future__ import annotations

import argparse
import json
import mimetypes
import os
import secrets
import sys
import urllib.error
import urllib.parse
import urllib.request
from pathlib import Path


SCRIPT_DIR = Path(__file__).resolve().parent
DEFAULT_ENV_PATH = SCRIPT_DIR / ".env"


def load_env(path: Path) -> dict[str, str]:
    values: dict[str, str] = {}
    if not path.exists():
        return values

    for raw_line in path.read_text(encoding="utf-8").splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip('"').strip("'")
    return values


def config_value(env_file: dict[str, str], key: str, default: str = "") -> str:
    return os.environ.get(key, env_file.get(key, default)).strip()


def require(value: str, key: str) -> str:
    if not value:
        raise SystemExit(f"Missing {key}. Fill it in .env or export it.")
    return value


def endpoint_url(base_url: str, path: str) -> str:
    return urllib.parse.urljoin(base_url.rstrip("/") + "/", path.lstrip("/"))


def multipart_body(fields: dict[str, str], file_field: str, file_path: Path) -> tuple[bytes, str]:
    boundary = f"----babbelstream-{secrets.token_hex(16)}"
    content_type = mimetypes.guess_type(file_path.name)[0] or "application/octet-stream"
    chunks: list[bytes] = []

    for name, value in fields.items():
        if value == "":
            continue
        chunks.extend(
            [
                f"--{boundary}\r\n".encode(),
                f'Content-Disposition: form-data; name="{name}"\r\n\r\n'.encode(),
                value.encode(),
                b"\r\n",
            ]
        )

    chunks.extend(
        [
            f"--{boundary}\r\n".encode(),
            (
                f'Content-Disposition: form-data; name="{file_field}"; '
                f'filename="{file_path.name}"\r\n'
            ).encode(),
            f"Content-Type: {content_type}\r\n\r\n".encode(),
            file_path.read_bytes(),
            b"\r\n",
            f"--{boundary}--\r\n".encode(),
        ]
    )

    return b"".join(chunks), f"multipart/form-data; boundary={boundary}"


def request_json_or_text(request: urllib.request.Request, timeout: float) -> tuple[int, str, str]:
    try:
        with urllib.request.urlopen(request, timeout=timeout) as response:
            body = response.read().decode("utf-8", errors="replace")
            return response.status, response.headers.get("content-type", ""), body
    except urllib.error.HTTPError as error:
        body = error.read().decode("utf-8", errors="replace")
        return error.code, error.headers.get("content-type", ""), body


def pretty_print_response(status: int, content_type: str, body: str) -> int:
    print(f"HTTP {status}")
    if content_type:
        print(f"Content-Type: {content_type}")
    print()

    try:
        parsed = json.loads(body)
    except json.JSONDecodeError:
        print(body)
    else:
        print(json.dumps(parsed, indent=2, ensure_ascii=False))

    return 0 if 200 <= status < 300 else 1


def list_models(base_url: str, api_key: str, timeout: float) -> int:
    url = endpoint_url(base_url, "/v1/models")
    request = urllib.request.Request(
        url,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Accept": "application/json",
        },
        method="GET",
    )
    print(f"GET {url}")
    status, content_type, body = request_json_or_text(request, timeout)
    return pretty_print_response(status, content_type, body)


def transcribe(args: argparse.Namespace, env_file: dict[str, str]) -> int:
    base_url = require(config_value(env_file, "LITELLM_BASE_URL"), "LITELLM_BASE_URL")
    api_key = require(config_value(env_file, "LITELLM_API_KEY"), "LITELLM_API_KEY")
    model = config_value(env_file, "LITELLM_STT_MODEL", "gpt-4o-transcribe")
    path = config_value(env_file, "LITELLM_TRANSCRIPTION_PATH", "/v1/audio/transcriptions")
    response_format = config_value(env_file, "LITELLM_RESPONSE_FORMAT", "json")
    language = config_value(env_file, "LITELLM_LANGUAGE")
    prompt = config_value(env_file, "LITELLM_PROMPT")
    timeout = float(config_value(env_file, "REQUEST_TIMEOUT_SECONDS", "60"))

    audio_path = Path(args.audio_file).expanduser().resolve()
    if not audio_path.exists():
        raise SystemExit(f"Audio file does not exist: {audio_path}")
    if not audio_path.is_file():
        raise SystemExit(f"Audio path is not a file: {audio_path}")

    fields = {
        "model": model,
        "response_format": response_format,
        "language": language,
        "prompt": prompt,
    }
    body, content_type = multipart_body(fields, "file", audio_path)
    url = endpoint_url(base_url, path)

    request = urllib.request.Request(
        url,
        data=body,
        headers={
            "Authorization": f"Bearer {api_key}",
            "Content-Type": content_type,
            "Accept": "application/json, text/plain;q=0.9, */*;q=0.1",
        },
        method="POST",
    )

    print(f"POST {url}")
    print(f"model={model}")
    print(f"file={audio_path}")
    print(f"response_format={response_format}")
    print()

    status, response_content_type, response_body = request_json_or_text(request, timeout)
    return pretty_print_response(status, response_content_type, response_body)


def main() -> int:
    parser = argparse.ArgumentParser(description="Test LiteLLM/OpenAI-compatible STT.")
    parser.add_argument("audio_file", nargs="?", help="Path to an audio file to transcribe.")
    parser.add_argument("--env", default=str(DEFAULT_ENV_PATH), help="Path to .env file.")
    parser.add_argument("--models", action="store_true", help="List /v1/models instead of transcribing.")
    args = parser.parse_args()

    env_file = load_env(Path(args.env).expanduser().resolve())
    base_url = require(config_value(env_file, "LITELLM_BASE_URL"), "LITELLM_BASE_URL")
    api_key = require(config_value(env_file, "LITELLM_API_KEY"), "LITELLM_API_KEY")
    timeout = float(config_value(env_file, "REQUEST_TIMEOUT_SECONDS", "60"))

    if args.models:
        return list_models(base_url, api_key, timeout)
    if not args.audio_file:
        parser.error("audio_file is required unless --models is used")
    return transcribe(args, env_file)


if __name__ == "__main__":
    sys.exit(main())
