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
FLEET_MAP = REPO / "agency-team" / "PERSONAL_FLEET_MAP.md"

NEW_FLEET_SLUGS = (
    "tradbot",
    "home-assistant-master",
    "credit-card-max",
    "signal",
)


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
        *NEW_FLEET_SLUGS,
    ):
        assert slug in slugs


def test_personal_fleet_map_documents_remap() -> None:
    assert FLEET_MAP.is_file()
    text = FLEET_MAP.read_text(encoding="utf-8")
    assert "MissFortune" in text
    assert "Tradbot" in text
    assert "Signal" in text
    for slug in NEW_FLEET_SLUGS:
        assert slug in text


def test_installer_generates_personal_fleet_only_slugs() -> None:
    script = INSTALLER.read_text(encoding="utf-8")
    assert "PERSONAL_FLEET_ONLY_SLUGS=(" in script
    assert "write_personal_fleet_agent" in script
    for slug in NEW_FLEET_SLUGS:
        assert slug in script


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
        *NEW_FLEET_SLUGS,
    ):
        assert f"id: {slug}" in text
    orch_role = text.split("id: agents-orchestrator", 1)[1]
    for slug in NEW_FLEET_SLUGS:
        assert slug in orch_role.split("id: senior-project-manager", 1)[0]


def test_catalog_has_full_roster() -> None:
    rows = CATALOG.read_text(encoding="utf-8").splitlines()
    assert rows[0].startswith("slug")
    assert len(rows) - 1 >= 200
    catalog = CATALOG.read_text(encoding="utf-8")
    for slug in NEW_FLEET_SLUGS:
        assert slug in catalog


def test_personal_fleet_profiles_match_new_slugs() -> None:
    profiles = REPO / "agency-team" / "personal-fleet"
    for slug in NEW_FLEET_SLUGS:
        path = profiles / f"{slug}.md"
        assert path.is_file(), f"missing fleet profile {path}"
        text = path.read_text(encoding="utf-8")
        assert text.startswith("---\n")
        assert f"name: {slug}\n" in text
        assert "\ndescription: " in text
