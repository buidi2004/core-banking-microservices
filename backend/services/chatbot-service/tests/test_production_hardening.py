"""
Test Production Hardening (thuần — không cần DB/model):
- SlidingWindowRateLimiter: cho đúng hạn mức, chặn khi vượt, mở lại sau window, retry_after
- sanitize_user_id: nhận UUID/slug hợp lệ, từ chối injection/độ dài vượt

Chạy: python -m unittest tests.test_production_hardening -v
"""

import sys
import time
import unittest
from pathlib import Path

SERVICE_ROOT = Path(__file__).resolve().parent.parent
if str(SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVICE_ROOT))

from app.rate_limiter import SlidingWindowRateLimiter, sanitize_user_id  # noqa: E402


class TestSlidingWindowRateLimiter(unittest.TestCase):

    def test_allows_up_to_limit_then_blocks(self):
        limiter = SlidingWindowRateLimiter(max_requests=3, window_seconds=60.0)
        self.assertTrue(limiter.allow("user-1"))
        self.assertTrue(limiter.allow("user-1"))
        self.assertTrue(limiter.allow("user-1"))
        self.assertFalse(limiter.allow("user-1"), "Lượt thứ 4 trong window phải bị chặn")

    def test_keys_are_isolated(self):
        limiter = SlidingWindowRateLimiter(max_requests=1, window_seconds=60.0)
        self.assertTrue(limiter.allow("user-a"))
        self.assertFalse(limiter.allow("user-a"))
        self.assertTrue(limiter.allow("user-b"), "User khác không bị trừ hạn mức của user-a")

    def test_window_slides_open_again(self):
        limiter = SlidingWindowRateLimiter(max_requests=1, window_seconds=0.2)
        self.assertTrue(limiter.allow("user-c"))
        self.assertFalse(limiter.allow("user-c"))
        time.sleep(0.3)
        self.assertTrue(limiter.allow("user-c"), "Sau khi window trượt qua phải mở lại")

    def test_retry_after_is_positive(self):
        limiter = SlidingWindowRateLimiter(max_requests=1, window_seconds=60.0)
        limiter.allow("user-d")
        limiter.allow("user-d")  # blocked
        retry = limiter.retry_after_seconds("user-d")
        self.assertGreaterEqual(retry, 1)
        self.assertLessEqual(retry, 61)

    def test_zero_or_negative_limit_still_sane(self):
        limiter = SlidingWindowRateLimiter(max_requests=0, window_seconds=60.0)
        # max_requests bị kẹp tối thiểu 1 — không crash
        self.assertIsInstance(limiter.allow("user-e"), bool)


class TestSanitizeUserId(unittest.TestCase):

    def test_accepts_uuid_and_slug(self):
        self.assertEqual(sanitize_user_id("550e8400-e29b-41d4-a716-446655440000"),
                         "550e8400-e29b-41d4-a716-446655440000")
        self.assertEqual(sanitize_user_id("user_123-XYZ"), "user_123-XYZ")

    def test_rejects_injection_and_overlong(self):
        self.assertIsNone(sanitize_user_id("1' OR '1'='1"))
        self.assertIsNone(sanitize_user_id("<script>alert(1)</script>"))
        self.assertIsNone(sanitize_user_id("a" * 65))
        self.assertIsNone(sanitize_user_id(None))
        self.assertIsNone(sanitize_user_id(""))
        self.assertIsNone(sanitize_user_id("   "))

    def test_strips_surrounding_whitespace(self):
        self.assertEqual(sanitize_user_id("  user-42  "), "user-42")

    def test_uuid_with_spaces_inside_is_rejected(self):
        self.assertIsNone(sanitize_user_id("550e8400 e29b 41d4"))


if __name__ == "__main__":
    unittest.main(verbosity=2)
