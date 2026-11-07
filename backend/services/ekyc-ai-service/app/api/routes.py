"""API contract của ekyc-ai-service (Giai đoạn 1 — chốt sớm cho mobile SDK).

  POST /api/v1/ekyc/session  → {sessionId, nonce, ttlSeconds}
  POST /api/v1/ekyc/verify   → payload mã hóa lai; kết quả face match (+ liveness tuần 6)
  GET  /api/v1/ekyc/health   → trạng thái GPU/model/redis

Flow bảo mật: SDK gọi /session trước, dùng (sessionId, nonce) làm AAD khi
mã hóa AES-256-GCM → payload mã hóa cho phiên nào chỉ giải được ở phiên đó,
nonce tiêu một lần trên Redis → chống Replay Attack.
"""
from __future__ import annotations

import base64
import json
import logging
import time

import cv2
import numpy as np
from fastapi import APIRouter, HTTPException
from pydantic import BaseModel, Field

from ..config import FACE_MATCH_THRESHOLD, SESSION_TTL_SECONDS
from ..core.crypto import (
    EkycCryptoError,
    bind_session_aad,
    decrypt_payload,
    load_private_key,
    unwrap_aes_key,
)
from ..core.session_store import SessionError, SessionStore
from ..services.face_pipeline import FacePipeline
from ..services.metrics import EkycMetricsRecorder
from ..services.image_quality import ImageQualityAssessment

logger = logging.getLogger("ekyc.api")

router = APIRouter(prefix="/api/v1/ekyc/ai")

# Được main.py gán lúc startup (scope service nhỏ, không cần DI framework)
session_store: SessionStore
pipeline: FacePipeline
metrics: EkycMetricsRecorder = EkycMetricsRecorder()
_private_key = None


def init_state(store: SessionStore, pl: FacePipeline, private_key_path) -> None:
    global session_store, pipeline, _private_key
    session_store = store
    pipeline = pl
    _private_key = load_private_key(private_key_path)


# ---------------------------------------------------------------------------
# Request / Response models
# ---------------------------------------------------------------------------


class SessionRequest(BaseModel):
    userId: str = Field(min_length=6, max_length=64, description="userId từ JWT của app")


class SessionResponse(BaseModel):
    sessionId: str
    nonce: str
    ttlSeconds: int
    cryptoScheme: str = "RSA-OAEP-SHA256 + AES-256-GCM"


class HybridPayload(BaseModel):
    sessionId: str
    nonce: str
    wrappedKey: str  # base64 — khóa AES-256 bọc RSA-OAEP-SHA256
    nonceB64: str  # base64 — nonce GCM 12 byte
    ciphertext: str  # base64 — JSON {selfie, chipPhoto} + GCM tag; AAD = session binding


class VerifyResult(BaseModel):
    sessionId: str
    liveness: dict
    faceMatch: dict
    decision: str  # APPROVED / REJECTED / MANUAL_REVIEW
    latencyMs: int
    errorCode: str | None = None
    errorMessage: str | None = None
    retryStep: str | None = None


@router.post("/session", response_model=SessionResponse)
def create_session(body: SessionRequest):
    session = session_store.create(body.userId)
    return SessionResponse(
        sessionId=session.session_id, nonce=session.nonce, ttlSeconds=SESSION_TTL_SECONDS
    )


@router.post("/verify", response_model=VerifyResult)
def verify(body: HybridPayload):
    t_start = time.perf_counter()
    try:
        user_id = session_store.validate_and_consume(body.sessionId, body.nonce)
    except SessionError as exc:
        raise HTTPException(status_code=401, detail=str(exc)) from exc

    aad = bind_session_aad(body.sessionId)
    try:
        aes_key = unwrap_aes_key(_private_key, body.wrappedKey)
        plaintext = decrypt_payload(aes_key, body.nonceB64, body.ciphertext, aad)
        if len(plaintext) > 8 * 1024 * 1024:
            raise EkycCryptoError("Payload vượt giới hạn dung lượng 8MB")
    except EkycCryptoError as exc:
        raise HTTPException(status_code=400, detail=str(exc)) from exc

    # Envelope JSON: selfie (khung chính) + chipPhoto (DG2/CCCD) + auxFrames
    # (2-3 khung hình phụ bắt trong lúc cử động liveness — chống đánh tráo người)
    try:
        inner = json.loads(plaintext.decode("utf-8"))
        selfie = _decode_image(inner.get("selfie", ""))
        chip = _decode_image(inner.get("chipPhoto", ""))
        aux_frames = [
            _decode_image(b64)
            for b64 in (inner.get("auxFrames") or [])[:3]
            if isinstance(b64, str) and b64
        ]
    except (ValueError, UnicodeDecodeError, json.JSONDecodeError) as exc:
        raise HTTPException(status_code=400, detail=f"Payload nội bộ không hợp lệ: {exc}") from exc

    # 1. Phân tích khuôn mặt selfie (1 lần duy nhất: SCRFD detect + ArcFace embed)
    #    tái sử dụng FaceAnalysis cho cả Liveness, IQA và Match (không chạy lại inference 2 lần)
    selfie_analysis = pipeline.analyze(selfie)
    selfie_primary = selfie_analysis.face

    if selfie_primary is None:
        liveness = {
            "engine": "MiniFASNetV2",
            "is_live": False,
            "score": 0.0,
            "reason": "Không tìm thấy khuôn mặt trong ảnh selfie",
            "latency_ms": 0.0,
        }
    else:
        liveness_raw = pipeline.detect_liveness(selfie, selfie_primary)
        liveness = {
            "engine": "MiniFASNetV2",
            "is_live": liveness_raw["is_live"],
            "score": liveness_raw["score"],
            "threshold": liveness_raw["threshold"],
            "details": liveness_raw,
            "latency_ms": liveness_raw["latency_ms"],
        }

    # 2. Đánh giá chất lượng ảnh sinh trắc học (IQA - Image Quality Assessment)
    quality = None
    if selfie_primary is not None:
        quality = ImageQualityAssessment.assess_face(selfie, selfie_primary.bbox)

    # 3. Kiểm tra hạn sử dụng CCCD (nếu có trường expiryDate trong payload)
    is_doc_expired = False
    expiry_str = inner.get("expiryDate")
    if expiry_str:
        try:
            clean_exp = expiry_str.replace("/", "").replace("-", "").strip()
            if len(clean_exp) == 6:
                exp_year = 2000 + int(clean_exp[:2])
                exp_month = int(clean_exp[2:4])
                exp_day = int(clean_exp[4:6])
                from datetime import datetime
                if datetime.now() > datetime(exp_year, exp_month, exp_day):
                    is_doc_expired = True
        except Exception:
            pass

    # 4. So khớp khuôn mặt ArcFace (Selfie ↔ Thẻ/Chip CCCD) + SO KHỚP CHÉO
    #    Tái sử dụng selfie_analysis đã có -> tiết kiệm 50% thời gian inference GPU
    result = pipeline.match_multi(selfie, chip, aux_frames, selfie_analysis=selfie_analysis)
    latency_ms = int((time.perf_counter() - t_start) * 1000)

    # 5. Ra quyết định chuẩn ngân hàng & phân loại mã lỗi nghiệp vụ (Error Contract)
    error_code = None
    error_message = None
    retry_step = None

    if selfie_primary is None:
        decision = "REJECTED"
        error_code = "EKYC_NO_FACE"
        error_message = "Không tìm thấy khuôn mặt trong ảnh selfie. Vui lòng nhìn thẳng và giữ đủ sáng."
        retry_step = "SELFIE"
    elif quality and not quality.get("passed"):
        decision = "REJECTED"
        error_code = quality.get("error_code") or "EKYC_POOR_QUALITY"
        error_message = quality.get("error_message") or "Chất lượng ảnh không đạt tiêu chuẩn sinh trắc học."
        retry_step = "SELFIE"
    elif is_doc_expired:
        decision = "REJECTED"
        error_code = "EKYC_EXPIRED_DOCUMENT"
        error_message = "Thẻ Căn cước công dân của bạn đã hết hạn sử dụng theo quy định của pháp luật."
        retry_step = "NONE"
    elif not liveness.get("is_live") and (liveness.get("score") or 0) <= 0.4:
        decision = "REJECTED"
        error_code = "EKYC_SPOOF_DETECTED"
        error_message = "Cảnh báo bảo mật: Phát hiện dấu hiệu giả mạo màn hình hoặc ảnh in."
        retry_step = "SELFIE"
    elif not result.get("matched"):
        decision = "REJECTED"
        # Phân biệt: khung phụ lệch (nghi đánh tráo) vs khớp chính lệch thường
        aux_failed = any(not a.get("matched") for a in (result.get("auxFrames") or []))
        if aux_failed:
            error_code = "EKYC_IDENTITY_SWAP_SUSPECTED"
            error_message = result.get("reason") or "Phát hiện khung hình phụ không khớp chủ thể."
        else:
            error_code = "EKYC_FACE_MISMATCH"
            sim = result.get("similarity", 0)
            error_message = f"Khuôn mặt selfie không trùng khớp với ảnh chip CCCD (Độ tương đồng: {sim:.2f})."
        retry_step = "SELFIE"
    elif result.get("matched") and liveness.get("is_live") and (result.get("similarity", 0) >= 0.70):
        decision = "APPROVED"
    else:
        # Ngưỡng 3 vùng: 0.60 <= similarity < 0.70 chuyển sang hậu kiểm nhân viên
        decision = "MANUAL_REVIEW"
        error_code = "EKYC_MANUAL_REVIEW"
        error_message = "Hồ sơ chuyển sang chuyên viên hậu kiểm do tín hiệu sinh trắc ở mức ranh giới."
        retry_step = "NONE"

    # 4. Giai đoạn 4: Tự động kích hoạt KYC tại identity-service khi đạt chuẩn
    auto_approved = False
    if decision == "APPROVED":
        try:
            import urllib.request
            from ..config import IDENTITY_SERVICE_URL, INTERNAL_API_KEY
            cb_payload = json.dumps({
                "userId": user_id,
                "sessionId": body.sessionId,
                "livenessScore": liveness.get("score"),
                "similarity": result.get("similarity"),
                "documentNumber": inner.get("documentNumber", "NFC_VERIFIED"),
                "verifiedBy": "AI_EKYC_PIPELINE",
            }).encode("utf-8")
            req = urllib.request.Request(
                f"{IDENTITY_SERVICE_URL}/api/v1/kyc/internal/auto-approve",
                data=cb_payload,
                headers={
                    "Content-Type": "application/json",
                    "X-Internal-Key": INTERNAL_API_KEY,
                },
                method="POST",
            )
            with urllib.request.urlopen(req, timeout=5) as cb_resp:
                if cb_resp.status in (200, 201):
                    auto_approved = True
                    logger.info("Đã tự động nâng hạng KYC tại identity-service cho userId=%s", user_id)
        except Exception as exc:
            logger.warning("Không thể gọi callback auto-approve sang identity-service: %s", exc)

    logger.info(
        "eKYC verify session=%s user=%s matched=%s sim=%s is_live=%s liveness_score=%s decision=%s err=%s retry=%s auto_approved=%s latency=%dms",
        body.sessionId,
        user_id,
        result.get("matched"),
        result.get("similarity"),
        liveness.get("is_live"),
        liveness.get("score"),
        decision,
        error_code,
        retry_step,
        auto_approved,
        latency_ms,
    )
    metrics.record_verify(
        decision=decision,
        latency_ms=latency_ms,
        similarity=result.get("similarity"),
        liveness_score=liveness.get("score"),
        error_code=error_code,
        auto_approved=auto_approved,
    )
    return VerifyResult(
        sessionId=body.sessionId,
        liveness=liveness,
        faceMatch=result,
        decision=decision,
        latencyMs=latency_ms,
        errorCode=error_code,
        errorMessage=error_message,
        retryStep=retry_step,
    )


@router.get("/health")
def health():
    return {
        "service": "ekyc-ai-service",
        "status": "UP",
        "provider": pipeline.provider_used,
        "redisBacked": session_store.redis_backed,
        "faceMatchThreshold": FACE_MATCH_THRESHOLD,
        "sessionTtlSeconds": SESSION_TTL_SECONDS,
    }


@router.get("/metrics")
def get_metrics():
    """Dashboard log Giai đoạn 5: latency p50/p95, quyết định, điểm sinh trắc."""
    return {"service": "ekyc-ai-service", **metrics.snapshot()}


def _decode_image(b64: str) -> np.ndarray:
    """Giải mã ảnh an toàn từ base64:
    1. Bảo vệ chống Decompression Bomb (giới hạn tối đa 4096x4096px / 10MP).
    2. Thử giải mã bằng cv2.imdecode (trả về hệ màu BGR chuẩn OpenCV/InsightFace).
    3. Fallback qua Pillow để xử lý định dạng JPEG 2000 (.jp2 / J2K) từ chip CCCD DG2,
       sau đó chuyển hệ màu RGB -> BGR để không làm tụt điểm so khớp ArcFace.
    """
    if not b64:
        raise ValueError("Thiếu ảnh (selfie/chipPhoto)")
    raw = base64.b64decode(b64)
    if len(raw) > 6 * 1024 * 1024:
        raise ValueError("Dung lượng file ảnh vượt quá 6MB")

    # 1. Thử giải mã OpenCV BGR
    img = cv2.imdecode(np.frombuffer(raw, np.uint8), cv2.IMREAD_COLOR)
    if img is not None:
        h, w = img.shape[:2]
        if h > 4096 or w > 4096 or (h * w) > 10_000_000:
            raise ValueError(f"Kích thước ảnh ({w}x{h}px) vượt giới hạn an toàn 4096x4096px (Image Bomb Protection)")
        return img

    # 2. Fallback sang Pillow (xử lý JPEG 2000 từ vùng nhớ chip CCCD DG2)
    try:
        from PIL import Image
        import io
        Image.MAX_IMAGE_PIXELS = 10_000_000
        pil_img = Image.open(io.BytesIO(raw))
        if pil_img.width > 4096 or pil_img.height > 4096:
            raise ValueError(f"Kích thước ảnh ({pil_img.width}x{pil_img.height}px) vượt giới hạn an toàn 4096x4096px (Image Bomb Protection)")
        if pil_img.mode != "RGB":
            pil_img = pil_img.convert("RGB")
        # QUAN TRỌNG: Đổi RGB (Pillow) sang BGR (InsightFace)
        return cv2.cvtColor(np.array(pil_img), cv2.COLOR_RGB2BGR)
    except Exception as exc:
        raise ValueError(f"Ảnh không giải mã được (JPEG/PNG/JP2 hỏng): {exc}") from exc
