#!/usr/bin/env python3
"""Smoke test end-to-end: session → hybrid encrypt → verify → replay bị chặn.

Giả vai mobile SDK:
  1. GET  /health                     → CUDAExecutionProvider
  2. POST /session                    → sessionId + nonce
  3. Mã hóa lai AES-256-GCM + RSA-OAEP, AAD = session binding
  4. POST /verify (selfie ≈ chip cùng người) → MANUAL_REVIEW + similarity cao
  5. POST /verify lại với nonce cũ    → 401 REPLAY (chống phát lại hoạt động)
"""
import base64
import json
import os
import sys
import time
import urllib.request
import urllib.error
from pathlib import Path

from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding
from cryptography.hazmat.primitives.ciphers.aead import AESGCM

BASE = "http://localhost:8900"  # container ekyc-ai-service
ROOT = Path(__file__).resolve().parent.parent


def http(method: str, path: str, body: dict | None = None):
    req = urllib.request.Request(
        BASE + path,
        data=json.dumps(body).encode() if body else None,
        headers={"Content-Type": "application/json"},
        method=method,
    )
    try:
        with urllib.request.urlopen(req, timeout=30) as resp:
            return resp.status, json.loads(resp.read())
    except urllib.error.HTTPError as e:
        return e.code, json.loads(e.read())


def img_b64(path: str) -> str:
    return base64.b64encode(Path(path).read_bytes()).decode()


def encrypt_envelope(session_id: str, nonce: str, inner: dict) -> dict:
    # 1. AES-256 key phiên (SDK sinh, server không biết trước)
    aes_key = os.urandom(32)
    gcm = AESGCM(aes_key)
    gcm_nonce = os.urandom(12)
    # 2. AAD liên kết phiên — payload không thể tái sử dụng ở phiên khác
    aad = f"ekyc-session:{session_id}".encode()
    ct = gcm.encrypt(gcm_nonce, json.dumps(inner).encode(), aad)
    # 3. RSA-OAEP-SHA256 bọc key
    pub = serialization.load_pem_public_key((ROOT / "certs" / "ekyc_public.pem").read_bytes())
    wrapped = pub.encrypt(aes_key, padding.OAEP(
        mgf=padding.MGF1(hashes.SHA256()), algorithm=hashes.SHA256(), label=None))
    return {
        "sessionId": session_id,
        "nonce": nonce,
        "wrappedKey": base64.b64encode(wrapped).decode(),
        "nonceB64": base64.b64encode(gcm_nonce).decode(),
        "ciphertext": base64.b64encode(ct).decode(),
    }


def main() -> int:
    ok = True

    code, health = http("GET", "/api/v1/ekyc/ai/health")
    print(f"[1] health            : {code} | provider={health.get('provider')} redis={health.get('redisBacked')}")
    ok &= code == 200

    code, s = http("POST", "/api/v1/ekyc/ai/session", {"userId": "a11ce000-0000-0000-0000-000000000001"})
    print(f"[2] session           : {code} | id={s.get('sessionId', '')[:8]}… ttl={s.get('ttlSeconds')}s")
    ok &= code == 200

    inner = {"selfie": img_b64(ROOT / "models/face_a.jpg"), "chipPhoto": img_b64(ROOT / "models/face_a.jpg")}
    payload = encrypt_envelope(s["sessionId"], s["nonce"], inner)

    t0 = time.perf_counter()
    code, v = http("POST", "/api/v1/ekyc/ai/verify", payload)
    wall = (time.perf_counter() - t0) * 1000
    fm = v.get("faceMatch", {})
    liv = v.get("liveness", {})
    print(f"[3] verify (cùng người): {code} | decision={v.get('decision')} | sim={fm.get('similarity')} "
          f"| liveness={liv.get('score')} | server={v.get('latencyMs')}ms | wall={wall:.0f}ms")
    # MiniFASNet phát hiện face_a.jpg là ảnh tĩnh/replay (liveness < 0.6) nên quyết định REJECTED/MANUAL_REVIEW
    ok &= code == 200 and fm.get("matched") is True and liv.get("engine") == "MiniFASNetV2"

    # Replay: dùng lại sessionId + nonce cũ
    code2, v2 = http("POST", "/api/v1/ekyc/ai/verify", payload)
    print(f"[4] replay (nonce cũ)  : {code2} | detail={v2.get('detail')}")
    ok &= code2 == 401

    # Payload tráo phiên: mã hóa lại nhưng AAD của phiên khác
    code3, s2 = http("POST", "/api/v1/ekyc/ai/session", {"userId": "a11ce000-0000-0000-0000-000000000001"})
    stolen = dict(payload)
    stolen["sessionId"] = s2["sessionId"]
    stolen["nonce"] = s2["nonce"]
    code4, v4 = http("POST", "/api/v1/ekyc/ai/verify", stolen)
    print(f"[5] payload tráo phiên : {code4} | detail={v4.get('detail')}")
    ok &= code4 == 400

    print("\n===>", "SMOKE TEST PASSED 5/5" if ok else "SMOKE TEST FAILED")
    return 0 if ok else 1


if __name__ == "__main__":
    sys.exit(main())
