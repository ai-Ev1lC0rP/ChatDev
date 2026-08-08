# ChatDev model onboarding tests (OmniRoute-first). No live secrets required.

from __future__ import annotations

from pathlib import Path

import pytest

from tools.onboard_models import PROVIDERS, apply_provider, upsert_env_vars
from tools.omniroute_gateway import GatewayStatus, probe_gateway


def test_upsert_env_vars_creates_and_updates(tmp_path: Path) -> None:
    env = tmp_path / ".env"
    env.write_text("# header\nFOO=1\nBASE_URL=old\n", encoding="utf-8")

    changed = upsert_env_vars(
        env,
        {"BASE_URL": "http://localhost:20128/v1", "API_KEY": "k", "NEW": "x"},
    )
    text = env.read_text(encoding="utf-8")
    assert "BASE_URL=http://localhost:20128/v1" in text
    assert "API_KEY=k" in text
    assert "NEW=x" in text
    assert "FOO=1" in text
    assert "# header" in text
    assert "BASE_URL" in changed
    assert "API_KEY" in changed
    assert "NEW" in changed


def test_upsert_preserves_export_prefix(tmp_path: Path) -> None:
    env = tmp_path / ".env"
    env.write_text("export API_KEY=old\n", encoding="utf-8")
    upsert_env_vars(env, {"API_KEY": "new"})
    assert env.read_text(encoding="utf-8").strip() == "export API_KEY=new"


def test_omniroute_preset() -> None:
    preset = PROVIDERS["omniroute"]
    assert preset.base_url.endswith("/v1")
    assert "20128" in preset.base_url
    assert preset.default_model == "auto"


def test_apply_provider_writes_env(tmp_path: Path) -> None:
    env = tmp_path / ".env"
    updates = apply_provider(PROVIDERS["omniroute"], env_path=env, api_key="test-key")
    text = env.read_text(encoding="utf-8")
    assert updates["BASE_URL"] == PROVIDERS["omniroute"].base_url
    assert "API_KEY=test-key" in text
    assert "MODEL_PROVIDER=omniroute" in text
    assert "DEFAULT_MODEL=auto" in text


def test_probe_gateway_unreachable() -> None:
    status = probe_gateway(base_url="http://127.0.0.1:1/v1", timeout=0.5)
    assert isinstance(status, GatewayStatus)
    assert status.reachable is False
    assert status.models_ok is False


def test_onboard_cli_list(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    from tools import onboard_models

    monkeypatch.setattr(onboard_models, "ENV_PATH", tmp_path / ".env")
    code = onboard_models.main(["--list"])
    assert code == 0


def test_onboard_cli_noninteractive(tmp_path: Path, monkeypatch: pytest.MonkeyPatch) -> None:
    from tools import onboard_models

    env = tmp_path / ".env"
    monkeypatch.setattr(onboard_models, "ENV_PATH", env)
    code = onboard_models.main(
        [
            "--provider",
            "omniroute",
            "--yes",
            "--skip-verify",
            "--env-file",
            str(env),
            "--api-key",
            "placeholder-key",
        ]
    )
    assert code == 0
    text = env.read_text(encoding="utf-8")
    assert "BASE_URL=http://localhost:20128/v1" in text
    assert "API_KEY=placeholder-key" in text
