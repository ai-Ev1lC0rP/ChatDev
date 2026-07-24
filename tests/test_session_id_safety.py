"""Session ID path-safety regressions for AttachmentService.

Upload filename sanitization (#638) closed one traversal vector. session_id is
also interpolated into WareHouse paths and must reject separators / traversal
tokens the same way download routes already do.
"""

import pytest

from server.services.attachment_service import AttachmentService


@pytest.mark.parametrize(
    "raw, expected",
    [
        ("abc123", "abc123"),
        ("session_abc123", "abc123"),
        ("user-1_run", "user-1_run"),
    ],
)
def test_safe_session_id_accepts_opaque_tokens(raw, expected):
    assert AttachmentService._safe_session_id(raw) == expected


@pytest.mark.parametrize(
    "raw",
    [
        "",
        None,
        "../etc",
        "foo/bar",
        "foo\\bar",
        "sess with space",
        "session_../x",
        "session_",
    ],
)
def test_safe_session_id_rejects_unsafe_tokens(raw):
    with pytest.raises(ValueError):
        AttachmentService._safe_session_id(raw)


def test_prepare_session_workspace_stays_under_warehouse(tmp_path):
    service = AttachmentService(root=tmp_path / "WareHouse")
    path = service.prepare_session_workspace("run42")
    assert path.exists()
    assert (tmp_path / "WareHouse" / "session_run42").exists()
    assert ".." not in path.parts


def test_prepare_session_workspace_rejects_traversal(tmp_path):
    service = AttachmentService(root=tmp_path / "WareHouse")
    with pytest.raises(ValueError):
        service.prepare_session_workspace("../../evil")
