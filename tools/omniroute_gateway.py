"""OmniRoute gateway helpers for ChatDev model onboarding.

OmniRoute (https://github.com/diegosouzapw/OmniRoute) is an OpenAI-compatible
local AI gateway. ChatDev agents already use BASE_URL + API_KEY, so pointing
those at OmniRoute is the integration surface.
"""

from __future__ import annotations

import json
import shutil
import subprocess
import urllib.error
import urllib.request
from dataclasses import dataclass
from typing import Any

DEFAULT_OMNIROUTE_HOST = "127.0.0.1"
DEFAULT_OMNIROUTE_PORT = 20128
DEFAULT_OMNIROUTE_BASE_URL = f"http://localhost:{DEFAULT_OMNIROUTE_PORT}/v1"
DEFAULT_OMNIROUTE_DASHBOARD = f"http://localhost:{DEFAULT_OMNIROUTE_PORT}"
DOCKER_IMAGE = "diegosouzapw/omniroute:latest"
# Used by `make omniroute-up` (python helper). compose.yml uses chatdev_omniroute.
# TODO(omniroute): align Docker container/volume names with compose.yml so
# `make omniroute-status` and `docker compose --profile omniroute` observe the same instance.
DOCKER_CONTAINER = "chatdev-omniroute"
DOCKER_VOLUME = "chatdev-omniroute-data"


@dataclass(frozen=True)
class GatewayStatus:
    reachable: bool
    base_url: str
    models_ok: bool
    model_count: int | None
    detail: str
    docker_running: bool


def omniroute_base_url(port: int = DEFAULT_OMNIROUTE_PORT) -> str:
    return f"http://localhost:{port}/v1"


def omniroute_dashboard_url(port: int = DEFAULT_OMNIROUTE_PORT) -> str:
    return f"http://localhost:{port}"


def _http_json(
    url: str,
    *,
    api_key: str | None = None,
    timeout: float = 5.0,
) -> tuple[int, Any]:
    headers = {"Accept": "application/json"}
    if api_key:
        headers["Authorization"] = f"Bearer {api_key}"
    req = urllib.request.Request(url, headers=headers, method="GET")
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            body = resp.read().decode("utf-8", errors="replace")
            status = getattr(resp, "status", 200)
            try:
                return status, json.loads(body) if body else None
            except json.JSONDecodeError:
                return status, body
    except urllib.error.HTTPError as exc:
        body = exc.read().decode("utf-8", errors="replace")
        try:
            payload: Any = json.loads(body) if body else None
        except json.JSONDecodeError:
            payload = body
        return exc.code, payload
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        raise ConnectionError(str(exc)) from exc


def docker_available() -> bool:
    return shutil.which("docker") is not None


def docker_container_running(name: str = DOCKER_CONTAINER) -> bool:
    if not docker_available():
        return False
    try:
        result = subprocess.run(
            [
                "docker",
                "inspect",
                "-f",
                "{{.State.Running}}",
                name,
            ],
            capture_output=True,
            text=True,
            check=False,
            timeout=10,
        )
    except (OSError, subprocess.TimeoutExpired):
        return False
    return result.returncode == 0 and result.stdout.strip().lower() == "true"


def probe_gateway(
    *,
    base_url: str = DEFAULT_OMNIROUTE_BASE_URL,
    api_key: str | None = None,
    timeout: float = 5.0,
) -> GatewayStatus:
    models_url = base_url.rstrip("/") + "/models"
    docker_running = docker_container_running()
    try:
        status, payload = _http_json(models_url, api_key=api_key, timeout=timeout)
    except ConnectionError as exc:
        return GatewayStatus(
            reachable=False,
            base_url=base_url,
            models_ok=False,
            model_count=None,
            detail=f"unreachable: {exc}",
            docker_running=docker_running,
        )

    if status in {401, 403}:
        return GatewayStatus(
            reachable=True,
            base_url=base_url,
            models_ok=False,
            model_count=None,
            detail=(
                f"gateway up but auth failed (HTTP {status}); "
                "set API_KEY from Dashboard → Endpoints"
            ),
            docker_running=docker_running,
        )

    if status >= 400:
        return GatewayStatus(
            reachable=True,
            base_url=base_url,
            models_ok=False,
            model_count=None,
            detail=f"HTTP {status}: {payload!r}",
            docker_running=docker_running,
        )

    model_count: int | None = None
    if isinstance(payload, dict) and isinstance(payload.get("data"), list):
        model_count = len(payload["data"])
    return GatewayStatus(
        reachable=True,
        base_url=base_url,
        models_ok=True,
        model_count=model_count,
        detail="ok",
        docker_running=docker_running,
    )


def start_gateway_docker(
    *,
    port: int = DEFAULT_OMNIROUTE_PORT,
    container: str = DOCKER_CONTAINER,
) -> str:
    if not docker_available():
        raise RuntimeError(
            "Docker not found. Install Docker, or run OmniRoute with: npx -y omniroute"
        )

    if docker_container_running(container):
        return f"OmniRoute container '{container}' already running on port {port}"

    # Reuse stopped container if it exists
    inspect = subprocess.run(
        ["docker", "inspect", container],
        capture_output=True,
        text=True,
        check=False,
        timeout=10,
    )
    if inspect.returncode == 0:
        start = subprocess.run(
            ["docker", "start", container],
            capture_output=True,
            text=True,
            check=False,
            timeout=60,
        )
        if start.returncode != 0:
            raise RuntimeError(start.stderr.strip() or start.stdout.strip() or "docker start failed")
        return f"Started existing OmniRoute container '{container}'"

    run = subprocess.run(
        [
            "docker",
            "run",
            "-d",
            "--name",
            container,
            "--restart",
            "unless-stopped",
            "--stop-timeout",
            "40",
            "-p",
            f"{port}:{DEFAULT_OMNIROUTE_PORT}",
            "-v",
            f"{DOCKER_VOLUME}:/app/data",
            DOCKER_IMAGE,
        ],
        capture_output=True,
        text=True,
        check=False,
        timeout=180,
    )
    if run.returncode != 0:
        raise RuntimeError(run.stderr.strip() or run.stdout.strip() or "docker run failed")
    return f"Started OmniRoute ({DOCKER_IMAGE}) as '{container}' on port {port}"


def stop_gateway_docker(container: str = DOCKER_CONTAINER) -> str:
    if not docker_available():
        raise RuntimeError("Docker not found")
    result = subprocess.run(
        ["docker", "stop", container],
        capture_output=True,
        text=True,
        check=False,
        timeout=60,
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or result.stdout.strip() or "docker stop failed")
    return f"Stopped OmniRoute container '{container}'"


if __name__ == "__main__":
    status = probe_gateway()
    print(
        json.dumps(
            {
                "reachable": status.reachable,
                "models_ok": status.models_ok,
                "model_count": status.model_count,
                "detail": status.detail,
                "docker_running": status.docker_running,
                "base_url": status.base_url,
            },
            indent=2,
        )
    )
