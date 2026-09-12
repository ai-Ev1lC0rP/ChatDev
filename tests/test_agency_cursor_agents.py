# Agency Cursor core-team install checks. No live LLM or agency-agents clone required.

from __future__ import annotations

from pathlib import Path

REPO = Path(__file__).resolve().parents[1]
CORE_TEAM = REPO / "agency-team" / "CORE_TEAM.txt"
AGENTS_DIR = REPO / ".cursor" / "agents"
INSTALLER = REPO / "tools" / "install_agency_cursor_agents.sh"
YAML_PATH = REPO / "yaml_instance" / "agency_core_team.yaml"
CATALOG = REPO / "agency-team" / "CATALOG.tsv"
OVERLAY = REPO / "agency-team" / "ORCHESTRATOR_OVERLAY.md"


def _core_slugs() -> list[str]:
    slugs: list[str] = []
    for line in CORE_TEAM.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#"):
            continue
        slugs.append(line)
    return slugs


def test_core_team_file_exists_and_nonempty() -> None:
    slugs = _core_slugs()
    assert "agents-orchestrator" in slugs
    assert slugs[0] == "agents-orchestrator"
    assert len(slugs) >= 20


def test_each_core_agent_has_valid_frontmatter() -> None:
    for slug in _core_slugs():
        path = AGENTS_DIR / f"{slug}.md"
        assert path.is_file(), f"missing core agent {path}"
        text = path.read_text(encoding="utf-8")
        assert text.startswith("---\n"), f"bad fence: {slug}"
        assert f"\nname: {slug}\n" in text or text.startswith(f"---\nname: {slug}\n")
        assert "\ndescription: " in text


def test_installer_core_slugs_match_manifest() -> None:
    script = INSTALLER.read_text(encoding="utf-8")
    start = script.index("CORE_SLUGS=(")
    end = script.index(")", start)
    block = script[start:end]
    installer_slugs = [
        line.strip()
        for line in block.splitlines()[1:]
        if line.strip() and not line.strip().startswith("#")
    ]
    assert installer_slugs == _core_slugs()


def test_promoted_specialists_are_core() -> None:
    slugs = set(_core_slugs())
    for slug in (
        "multi-agent-systems-architect",
        "ai-engineer",
        "technical-writer",
        "evidence-collector",
        "accessibility-auditor",
        "git-workflow-master",
    ):
        assert slug in slugs


def test_orchestrator_overlay_markers() -> None:
    text = OVERLAY.read_text(encoding="utf-8")
    assert "<!-- CHATDEV_CORE_TEAM_OVERLAY -->" in text
    assert "senior-project-manager" in text
    assert "project-manager-senior" not in text.split("Do not use")[0]


def test_orchestrator_agent_includes_overlay() -> None:
    text = (AGENTS_DIR / "agents-orchestrator.md").read_text(encoding="utf-8")
    assert "<!-- CHATDEV_CORE_TEAM_OVERLAY -->" in text
    assert "yaml_instance/agency_core_team.yaml" in text


def test_agency_core_yaml_exists() -> None:
    text = YAML_PATH.read_text(encoding="utf-8")
    assert "id: agency_core_team" in text
    assert "${BASE_URL}" in text
    assert "${API_KEY}" in text
    assert "${DEFAULT_MODEL}" in text
    for slug in (
        "agents-orchestrator",
        "senior-project-manager",
        "frontend-developer",
        "backend-architect",
        "reality-checker",
    ):
        assert f"id: {slug}" in text


def test_catalog_has_full_roster() -> None:
    rows = CATALOG.read_text(encoding="utf-8").splitlines()
    assert rows[0].startswith("slug")
    assert len(rows) - 1 >= 200
