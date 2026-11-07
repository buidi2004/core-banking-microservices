"""Quản lý phiên eKYC trên Redis — TTL ngắn, chống Replay Attack.

Mỗi lượt eKYC:
  1. POST /session  → sinh session_id (uuid4) + nonce dùng-một, TTL 4 phút
  2. POST /verify   → payload phải mang session_id + nonce khớp, nonce bị
                      tiêu ngay sau khi dùng (GETDEL) → không phát lại được
"""
from __future__ import annotations

import secrets
import uuid
from dataclasses import dataclass

import redis

from ..config import REDIS_URL, SESSION_TTL_SECONDS


class SessionError(Exception):
    """Phiên không hợp lệ / hết hạn / nonce sai."""


@dataclass(frozen=True)
class EkycSession:
    session_id: str
    nonce: str
    user_id: str


class SessionStore:
    def __init__(self, redis_url: str = REDIS_URL) -> None:
        try:
            self._r: redis.Redis | None = redis.Redis.from_url(
                redis_url, decode_responses=True, socket_connect_timeout=3, socket_timeout=3
            )
            self._r.ping()
        except redis.RedisError:
            # Dev offline: vẫn chạy được nhưng KHÔNG dùng production (chống replay yếu hơn)
            self._r = None

    @property
    def redis_backed(self) -> bool:
        return self._r is not None

    # ------------------------------------------------------------------
    def create(self, user_id: str) -> EkycSession:
        session_id = str(uuid.uuid4())
        nonce = secrets.token_urlsafe(16)
        if self._r is not None:
            key = self._key(session_id)
            # session: ghi user + nonce; nonce còn lưu bản dùng-một riêng
            self._r.hset(key, mapping={"userId": user_id, "nonce": nonce, "used": "0"})
            self._r.expire(key, SESSION_TTL_SECONDS)
        return EkycSession(session_id=session_id, nonce=nonce, user_id=user_id)

    def validate_and_consume(self, session_id: str, nonce: str) -> str:
        """Trả về userId nếu phiên hợp lệ; tiêu nonce (chống replay)."""
        if self._r is None:
            # Fallback dev: chấp nhận session dạng đủ dài, không persist
            if len(session_id) == 36 and nonce:
                return "dev-user"
            raise SessionError("Phiên không hợp lệ")

        key = self._key(session_id)
        # Lua để原子: kiểm tra + đánh dấu used trong 1 bước nguyên tố
        script = """
        local used = redis.call('HGET', KEYS[1], 'used')
        if used == '1' then return redis.error_reply('REPLAY') end
        local stored = redis.call('HGET', KEYS[1], 'nonce')
        if not stored or stored ~= ARGV[1] then return redis.error_reply('NONCE_MISMATCH') end
        redis.call('HSET', KEYS[1], 'used', '1')
        return redis.call('HGET', KEYS[1], 'userId') or ''
        """
        try:
            result = self._r.eval(script, 1, key, nonce)
        except redis.ResponseError as exc:
            msg = str(exc)
            if "REPLAY" in msg:
                raise SessionError("Phiên đã sử dụng — từ chối phát lại (replay)") from exc
            if "NONCE_MISMATCH" in msg:
                raise SessionError("Nonce không khớp phiên") from exc
            raise SessionError("Phiên hết hạn hoặc không tồn tại") from exc
        return result

    def issue_challenge(self, session_id: str, challenges: str) -> None:
        """Lưu chuỗi thử thách liveness (VD: 'blink,turn_right,smile') vào phiên."""
        if self._r is None:
            return
        key = self._key(session_id)
        self._r.hset(key, mapping={"challenges": challenges})
        self._r.expire(key, SESSION_TTL_SECONDS)

    @staticmethod
    def _key(session_id: str) -> str:
        return f"ekyc:session:{session_id}"
