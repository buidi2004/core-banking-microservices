"""
Rate Limiter & User Identity Sanitizer (Production Hardening)
- Sliding-window in-memory limiter: đủ cho 1 worker uvicorn; khi scale multi-worker
  cần đổi sang Redis (đã có trong stack) — ghi chú để mở rộng.
- sanitize_user_id: X-User-Id do API Gateway tin cậy inject (đã verify JWT người dùng
  ở gateway). Chấp nhận đúng định danh dạng UUID/slug; giá trị lạ → bỏ (anonymous)
  thay vì 400 để không phá trải nghiệm khách vãng lai.
"""

import re
import threading
import time
from collections import defaultdict, deque
from typing import Deque, Dict, Optional

# X-User-Id hợp lệ: UUID (với/without gạch), hoặc slug chữ-số-ngạch dưới 64 ký tự
USER_ID_PATTERN = re.compile(r"^[A-Za-z0-9_-]{1,64}$")


class SlidingWindowRateLimiter:
    """
    Giới hạn tần suất theo key (user_id hoặc IP) với cửa sổ trượt in-memory:
    - allow(key) -> True nếu còn hạn mức trong window, False nếu vượt.
    - Thread-safe (uvicorn chạy sync endpoint trong threadpool).
    - Tự dọn key rỗng khi bảng phình > 10.000 entries (tránh memory leak dài hạn).
    """

    def __init__(self, max_requests: int, window_seconds: float = 60.0):
        self.max_requests = max(1, int(max_requests))
        self.window_seconds = window_seconds
        self._hits: Dict[str, Deque[float]] = defaultdict(deque)
        self._lock = threading.Lock()

    def allow(self, key: str) -> bool:
        now = time.time()
        with self._lock:
            q = self._hits[key]
            cutoff = now - self.window_seconds
            while q and q[0] <= cutoff:
                q.popleft()
            if len(q) >= self.max_requests:
                return False
            q.append(now)
            if len(self._hits) > 10_000:
                for k in [k for k, v in self._hits.items() if not v]:
                    self._hits.pop(k, None)
            return True

    def retry_after_seconds(self, key: str) -> int:
        """Số giây tối thiểu phải chờ để có slot trống (cho header Retry-After)."""
        now = time.time()
        with self._lock:
            q = self._hits.get(key)
            if not q:
                return 1
            oldest = q[0]
            return max(1, int(self.window_seconds - (now - oldest)) + 1)


def sanitize_user_id(raw: Optional[str]) -> Optional[str]:
    """Trả về user_id hợp lệ (UUID/slug) hoặc None nếu thiếu/sai định dạng."""
    if not raw:
        return None
    value = raw.strip()
    if USER_ID_PATTERN.match(value):
        return value
    return None
