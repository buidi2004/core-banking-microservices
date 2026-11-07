"""Mã hóa lai chuẩn ngân hàng cho payload eKYC.

Sơ đồ (Giai đoạn 1 —roadmap):
  Mobile SDK                              ekyc-ai-service
  ──────────                              ────────────────
  aes_key = random(32)                    (giữ RSA private)
  ciphertext = AES-256-GCM(aes_key, nonce, payload)
  wrapped_key = RSA-OAEP-SHA256(pub, aes_key)
  POST /verify {wrapped_key, nonce, tag, ciphertext}
                                          aes_key = RSA-OAEP unwrap
                                          plaintext = AES-GCM open

Wire format: base64 cho 4 trường. GCM tag gửi kèm (128-bit) hoặc gắn cuối
ciphertext (chuẩn cryptography: open() nhận ciphertext+tag nối đuôi).
Quy ước ở đây: ciphertext base64 ĐÃ chứa tag ở cuối (encryptor mặc định).
"""
from __future__ import annotations

import base64
from dataclasses import dataclass
from pathlib import Path

from cryptography.exceptions import InvalidTag
from cryptography.hazmat.primitives import hashes, serialization
from cryptography.hazmat.primitives.asymmetric import padding, rsa
from cryptography.hazmat.primitives.ciphers.aead import AESGCM


class EkycCryptoError(Exception):
    """Lỗi giải mã / xác thực tag — trả về HTTP 400, không lộ chi tiết key."""


@dataclass(frozen=True)
class HybridEnvelope:
    """Bốn trường base64 mà SDK gửi lên."""

    wrapped_key: bytes  # aes_key được RSA-OAEP bọc
    nonce: bytes        # 12 byte AES-GCM
    ciphertext: bytes   # payload + GCM tag (16 byte cuối)
    session_id: str


def generate_key_pair(private_path: Path, public_path: Path, key_size: int = 2048) -> None:
    """Sinh cặp khóa RSA-OAEP cho môi trường dev (từ khóa production do HSM cấp)."""
    key = rsa.generate_private_key(public_exponent=65537, key_size=key_size)
    private_path.write_bytes(
        key.private_bytes(
            serialization.Encoding.PEM,
            serialization.PrivateFormat.PKCS8,
            serialization.NoEncryption(),
        )
    )
    public_path.write_bytes(
        key.public_key().public_bytes(
            serialization.Encoding.PEM,
            serialization.PublicFormat.SubjectPublicKeyInfo,
        )
    )


def load_private_key(path: Path):
    key = serialization.load_pem_private_key(path.read_bytes(), password=None)
    if not isinstance(key, rsa.RSAPrivateKey):
        raise TypeError(f"Khóa tại {path} không phải RSA")
    return key


def unwrap_aes_key(private_key: rsa.RSAPrivateKey, wrapped_key_b64: str) -> bytes:
    """Giải bọc khóa AES bằng RSA-OAEP-SHA256 (chuẩn ngân hàng, không PKCS1v1.5)."""
    try:
        wrapped = base64.b64decode(wrapped_key_b64)
        if len(wrapped) != (private_key.key_size // 8):
            raise EkycCryptoError("Độ dài wrapped_key không khớp kích thước khóa RSA")
        return private_key.decrypt(
            wrapped,
            padding.OAEP(
                mgf=padding.MGF1(hashes.SHA256()),
                algorithm=hashes.SHA256(),
                label=None,
            ),
        )
    except (ValueError, TypeError) as exc:
        raise EkycCryptoError("Không thể giải bọc khóa phiên") from exc


def decrypt_payload(aes_key: bytes, nonce_b64: str, ciphertext_b64: str, aad: bytes | None = None) -> bytes:
    """Giải mã AES-256-GCM; tag sai hoặc key sai → EkycCryptoError."""
    try:
        nonce = base64.b64decode(nonce_b64)
        ciphertext = base64.b64decode(ciphertext_b64)
        if len(nonce) != 12:
            raise EkycCryptoError("Nonce phải 12 byte theo chuẩn GCM")
        if len(aes_key) != 32:
            raise EkycCryptoError("Khóa phiên phải là AES-256 (32 byte)")
        return AESGCM(aes_key).decrypt(nonce, ciphertext, aad)
    except InvalidTag as exc:
        raise EkycCryptoError("Xác thực GCM thất bại — payload bị thay đổi") from exc
    except (ValueError, TypeError) as exc:
        if isinstance(exc, EkycCryptoError):
            raise
        raise EkycCryptoError("Định dạng base64 không hợp lệ") from exc


def bind_session_aad(session_id: str) -> bytes:
    """AAD liên kết payload với session — chống chuyển payload giữa các phiên."""
    return f"ekyc-session:{session_id}".encode("utf-8")
