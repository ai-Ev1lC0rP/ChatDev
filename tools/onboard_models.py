#!/usr/bin/env python3
"""ChatDev model onboarding — configure LLM provider env for agents.

Primary path: OmniRoute as the multi-provider OpenAI-compatible gateway.
Also supports direct Ollama / OpenAI / Gemini / LM Studio / custom presets.

Usage:
  uv run python tools/onboard_models.py
  uv run python tools/onboard_models.py --provider omniroute --yes
  uv run python tools/onboard_models.py --provider omniroute --api-key YOUR_KEY --start --yes
  make onboard-models
"""

from __future__ import annotations

import argparse
import re
import sys
from dataclasses import dataclass
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
if str(ROOT) not in sys.path:
    sys.path.insert(0, str(ROOT))

from tools.omniroute_gateway import (  # noqa: E402
    DEFAULT_OMNIROUTE_BASE_URL,
    DEFAULT_OMNIROUTE_DASHBOARD,
    DEFAULT_OMNIROUTE_PORT,
    omniroute_base_url,
    omniroute_dashboard_url,
    probe_gateway,
    start_gateway_docker,
)

ENV_PATH = ROOT / ".env"
ENV_EXAMPLE_PATH = ROOT / ".env.example"

PLACEHOLDER_API_KEYS = {
    "",
    "ollama",
    "lm-studio",
    "omniroute",
    "YOUR_OMNIROUTE_API_KEY",
    "sk-your-openai-api-key-here",
    "your-gemini-api-key-here",
}


@dataclass(frozen=True)
class ProviderPreset:
    key: str
    label: str
    base_url: str
    default_api_key: str
    default_model: str
    notes: str


PROVIDERS: dict[str, ProviderPreset] = {
    "omniroute": ProviderPreset(
        key="omniroute",
        label="OmniRoute (recommended) — multi-provider gateway",
        base_url=DEFAULT_OMNIROUTE_BASE_URL,
        default_api_key="YOUR_OMNIROUTE_API_KEY",
        default_model="auto",
        notes=(
            "Start gateway: make omniroute-up  |  Dashboard: "
            f"{DEFAULT_OMNIROUTE_DASHBOARD}  |  Create API key under Endpoints, then re-run with --api-key"
        ),
    ),
    "ollama": ProviderPreset(
        key="ollama",
        label="Ollama (local)",
        base_url="http://localhost:11434/v1",
        default_api_key="ollama",
        default_model="gpt-oss:20b",
        notes="Requires Ollama running locally with a pulled model.",
    ),
    "openai": ProviderPreset(
        key="openai",
        label="OpenAI",
        base_url="https://api.openai.com/v1",
        default_api_key="sk-your-openai-api-key-here",
        default_model="gpt-4o",
        notes="Requires a real OpenAI API key.",
    ),
    "gemini": ProviderPreset(
        key="gemini",
        label="Google Gemini",
        base_url="https://generativelanguage.googleapis.com",
        default_api_key="your-gemini-api-key-here",
        default_model="gemini-2.0-flash",
        notes="Requires a Gemini API key.",
    ),
    "lmstudio": ProviderPreset(
        key="lmstudio",
        label="LM Studio (local)",
        base_url="http://localhost:1234/v1",
        default_api_key="lm-studio",
        default_model="local-model",
        notes="Requires LM Studio local server enabled.",
    ),
    "custom": ProviderPreset(
        key="custom",
        label="Custom OpenAI-compatible endpoint",
        base_url="http://localhost:8000/v1",
        default_api_key="YOUR_API_KEY",
        default_model="default",
        notes="Any OpenAI-compatible BASE_URL + API_KEY.",
    ),
}


_KEY_LINE = re.compile(
    r"^(?P<prefix>\s*(?:export\s+)?)(?P<key>[A-Za-z_][A-Za-z0-9_]*)\s*=\s*(?P<value>.*)$"
)


def upsert_env_vars(path: Path, updates: dict[str, str]) -> list[str]:
    """Insert or replace KEY=value lines in a .env file. Preserves other content."""
    changed: list[str] = []
    if path.exists():
        lines = path.read_text(encoding="utf-8").splitlines()
    else:
        lines = []

    seen: set[str] = set()
    new_lines: list[str] = []
    for line in lines:
        match = _KEY_LINE.match(line)
        if not match:
            new_lines.append(line)
            continue
        key = match.group("key")
        if key in updates:
            prefix = match.group("prefix")
            new_lines.append(f"{prefix}{key}={updates[key]}")
            seen.add(key)
            if match.group("value").strip().strip("\"'") != updates[key]:
                changed.append(key)
            else:
                changed.append(key)  # still report touched keys for clarity
        else:
            new_lines.append(line)

    for key, value in updates.items():
        if key not in seen:
            if new_lines and new_lines[-1].strip():
                new_lines.append("")
            new_lines.append(f"{key}={value}")
            changed.append(key)

    path.write_text("\n".join(new_lines) + "\n", encoding="utf-8")
    return changed


def ensure_env_file(path: Path = ENV_PATH, example: Path = ENV_EXAMPLE_PATH) -> None:
    if path.exists():
        return
    if example.exists():
        path.write_text(example.read_text(encoding="utf-8"), encoding="utf-8")
        print(f"Created {path} from {example.name}")
    else:
        path.write_text(
            "# ChatDev environment\nBASE_URL=\nAPI_KEY=\n",
            encoding="utf-8",
        )
        print(f"Created empty {path}")


def prompt_choice(prompt: str, options: list[str], default: str) -> str:
    print(prompt)
    for idx, opt in enumerate(options, start=1):
        marker = " (default)" if opt == default else ""
        print(f"  {idx}) {opt}{marker}")
    raw = input(f"Select [1-{len(options)}] (default={default}): ").strip()
    if not raw:
        return default
    if raw.isdigit():
        i = int(raw)
        if 1 <= i <= len(options):
            return options[i - 1]
    if raw in options:
        return raw
    print(f"Invalid choice; using default: {default}")
    return default


def prompt_value(label: str, default: str) -> str:
    raw = input(f"{label} [{default}]: ").strip()
    return raw if raw else default


def apply_provider(
    provider: ProviderPreset,
    *,
    base_url: str | None = None,
    api_key: str | None = None,
    model: str | None = None,
    env_path: Path = ENV_PATH,
) -> dict[str, str]:
    updates = {
        "BASE_URL": base_url or provider.base_url,
        "API_KEY": api_key or provider.default_api_key,
        "DEFAULT_MODEL": model or provider.default_model,
        "MODEL_PROVIDER": provider.key,
    }
    ensure_env_file(env_path)
    changed = upsert_env_vars(env_path, updates)
    print(f"Updated {env_path.name}: {', '.join(changed)}")
    return updates


def maybe_start_omniroute(*, start: bool, port: int) -> None:
    if not start:
        return
    try:
        msg = start_gateway_docker(port=port)
        print(msg)
    except RuntimeError as exc:
        print(f"Could not start OmniRoute via Docker: {exc}")
        print("Fallback: npx -y omniroute   (dashboard on port 20128)")


def verify_provider(
    provider_key: str,
    *,
    base_url: str,
    api_key: str,
) -> int:
    if provider_key != "omniroute":
        print("Skipping live probe for non-OmniRoute providers.")
        return 0

    key = None if api_key in PLACEHOLDER_API_KEYS else api_key
    status = probe_gateway(base_url=base_url, api_key=key)
    print(
        f"OmniRoute probe: reachable={status.reachable} models_ok={status.models_ok} "
        f"models={status.model_count} docker={status.docker_running} ({status.detail})"
    )
    if not status.reachable:
        print(
            "Gateway not reachable yet. Run: make omniroute-up\n"
            f"Then open {omniroute_dashboard_url()} → Endpoints to create an API key."
        )
        return 0  # env was still written; not a hard failure
    if not status.models_ok and key is None:
        print(
            "Gateway is up. Paste your OmniRoute API key:\n"
            f"  uv run python tools/onboard_models.py --provider omniroute --api-key <KEY> --yes"
        )
        return 0
    return 0 if status.models_ok or status.reachable else 1


def interactive(args: argparse.Namespace) -> int:
    print("ChatDev model onboarding")
    print("Configure BASE_URL / API_KEY used by agent YAML (${BASE_URL}, ${API_KEY}).\n")
    keys = list(PROVIDERS.keys())
    labels = [PROVIDERS[k].label for k in keys]
    choice_label = prompt_choice("Choose a model provider:", labels, PROVIDERS["omniroute"].label)
    provider_key = keys[labels.index(choice_label)]
    provider = PROVIDERS[provider_key]

    base_url = prompt_value("BASE_URL", provider.base_url)
    api_key = prompt_value("API_KEY", provider.default_api_key)
    model = prompt_value("DEFAULT_MODEL (for docs / reference)", provider.default_model)

    start = False
    if provider_key == "omniroute":
        start_ans = input("Start OmniRoute via Docker now? [y/N]: ").strip().lower()
        start = start_ans in {"y", "yes"}

    maybe_start_omniroute(start=start, port=args.port)
    if provider_key == "omniroute":
        base_url = omniroute_base_url(args.port) if "localhost:20128" in base_url else base_url

    apply_provider(
        provider,
        base_url=base_url,
        api_key=api_key,
        model=model,
        env_path=Path(args.env_file),
    )
    print(f"\nNotes: {provider.notes}")
    return verify_provider(provider_key, base_url=base_url, api_key=api_key)


def noninteractive(args: argparse.Namespace) -> int:
    if not args.provider:
        print("Error: --provider is required with --yes (non-interactive).", file=sys.stderr)
        return 2
    if args.provider not in PROVIDERS:
        print(f"Unknown provider: {args.provider}", file=sys.stderr)
        return 2

    provider = PROVIDERS[args.provider]
    base_url = args.base_url or (
        omniroute_base_url(args.port) if args.provider == "omniroute" else provider.base_url
    )
    api_key = args.api_key or provider.default_api_key
    model = args.model or provider.default_model

    maybe_start_omniroute(start=args.start, port=args.port)
    apply_provider(
        provider,
        base_url=base_url,
        api_key=api_key,
        model=model,
        env_path=Path(args.env_file),
    )
    print(f"Notes: {provider.notes}")
    if args.skip_verify:
        return 0
    return verify_provider(args.provider, base_url=base_url, api_key=api_key)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description="ChatDev model onboarding (OmniRoute-first)")
    parser.add_argument(
        "--provider",
        choices=sorted(PROVIDERS.keys()),
        help="Provider preset (required with --yes)",
    )
    parser.add_argument("--base-url", help="Override BASE_URL")
    parser.add_argument("--api-key", help="Override API_KEY")
    parser.add_argument("--model", help="Override DEFAULT_MODEL")
    parser.add_argument(
        "--env-file",
        default=str(ENV_PATH),
        help="Path to .env (default: project root .env)",
    )
    parser.add_argument(
        "--port",
        type=int,
        default=DEFAULT_OMNIROUTE_PORT,
        help="OmniRoute port (default 20128)",
    )
    parser.add_argument(
        "--start",
        action="store_true",
        help="Start OmniRoute via Docker when provider=omniroute",
    )
    parser.add_argument(
        "--yes",
        "-y",
        action="store_true",
        help="Non-interactive mode",
    )
    parser.add_argument(
        "--skip-verify",
        action="store_true",
        help="Skip live OmniRoute probe",
    )
    parser.add_argument(
        "--list",
        action="store_true",
        help="List provider presets and exit",
    )
    return parser


def main(argv: list[str] | None = None) -> int:
    parser = build_parser()
    args = parser.parse_args(argv)

    if args.list:
        for key, preset in PROVIDERS.items():
            print(f"{key}: {preset.label}")
            print(f"  BASE_URL={preset.base_url}")
            print(f"  DEFAULT_MODEL={preset.default_model}")
            print(f"  {preset.notes}")
        return 0

    if args.yes:
        return noninteractive(args)
    return interactive(args)


if __name__ == "__main__":
    raise SystemExit(main())
