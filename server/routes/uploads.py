from fastapi import APIRouter, File, HTTPException, UploadFile

from server.state import ensure_known_session
from utils.exceptions import ValidationError
from utils.structured_logger import LogType, get_server_logger

router = APIRouter()


def _require_upload_session(session_id: str):
    """Resolve a known session for upload routes; map validation to HTTP 400."""
    try:
        return ensure_known_session(session_id, require_connection=False)
    except ValidationError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc


@router.post("/api/uploads/{session_id}")
async def upload_attachment(session_id: str, file: UploadFile = File(...)):
    manager = _require_upload_session(session_id)
    try:
        record = await manager.attachment_service.save_upload_file(session_id, file)
    except ValidationError as exc:
        raise HTTPException(status_code=400, detail="Session not connected") from exc
    except ValueError as exc:
        # Path-safety / session_id rejection from AttachmentService.
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    except Exception as exc:
        logger = get_server_logger()
        logger.error(
            "Failed to save attachment",
            log_type=LogType.REQUEST,
            session_id=session_id,
            error=str(exc),
        )
        raise HTTPException(status_code=500, detail="Failed to store attachment") from exc

    ref = record.ref
    return {
        "attachment_id": ref.attachment_id,
        "name": ref.name,
        "mime_type": ref.mime_type,
        "size": ref.size,
    }


@router.get("/api/uploads/{session_id}")
async def list_attachments(session_id: str):
    manager = _require_upload_session(session_id)
    try:
        manifest = manager.attachment_service.list_attachment_manifests(session_id)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc
    return {"attachments": manifest}
