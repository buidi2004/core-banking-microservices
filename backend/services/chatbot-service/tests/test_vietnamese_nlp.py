"""
Unit Tests for Vietnamese Banking NLP Engine & Smart Suggestion Engine
"""

import unittest
from app.vietnamese_nlp import (
    normalize_vietnamese_query,
    strip_vietnamese_accents,
    detect_query_topic,
    enrich_smart_quick_replies
)


class TestVietnameseNLP(unittest.TestCase):

    def test_telex_typo_normalization(self):
        cases = [
            ("keirm tra tối ưu gợi ý kiểm tra chữu tiếng việt cho chát bot",
             "kiểm tra tối ưu gợi ý kiểm tra chữ tiếng việt cho chatbot"),
            ("hoafn tieefn chuyeenr nhaamf stk khac",
             "hoàn tiền chuyển nhầm số tài khoản khac"),
            ("tieets kieemj 12 thaasng laix suats bao nhieu",
             "tiết kiệm 12 tháng lãi suất bao nhieu"),
            ("ddoori pin vi o dau",
             "đổi pin vi o dau"),
            ("bieeur phis napas 247",
             "biểu phí Napas 247"),
            ("khoanr vay quick loan can cccd gi",
             "khoản vay quick loan can căn cước công dân gi"),
            ("ck napas bi treo tien bao cskh the nao",
             "chuyển khoản Napas 247 bi treo tien bao chăm sóc khách hàng the nao")
        ]
        for raw, expected in cases:
            norm = normalize_vietnamese_query(raw)
            self.assertEqual(norm.lower(), expected.lower(), f"Failed on: {raw}")

    def test_strip_accents(self):
        text = "Ngân hàng Số Sen Hồng - Đổi mã PIN và Tiết kiệm Online"
        expected = "ngan hang so sen hong - doi ma pin va tiet kiem online"
        self.assertEqual(strip_vietnamese_accents(text), expected)

    def test_detect_topic(self):
        self.assertEqual(detect_query_topic("Lãi suất gửi tiết kiệm 6 tháng"), "SAVINGS")
        self.assertEqual(detect_query_topic("Điều kiện vay tiêu dùng Quick Loan"), "LOANS")
        self.assertEqual(detect_query_topic("Chuyển tiền Napas 247 sang Vietcombank"), "TRANSFER")
        self.assertEqual(detect_query_topic("Cách mở thẻ Visa Platinum"), "CARDS")
        self.assertEqual(detect_query_topic("Quên mã PIN bị khóa thì làm sao"), "SECURITY")
        self.assertEqual(detect_query_topic("Định danh sinh trắc học theo QĐ 2345 CCCD"), "BIOMETRICS")
        self.assertEqual(detect_query_topic("Chuyển nhầm tiền cần hoàn lại tra soát"), "DISPUTE")
        self.assertEqual(detect_query_topic("Nạp thẻ điện thoại Viettel"), "BILLS_TOPUP")
        self.assertEqual(detect_query_topic("Mã giảm giá voucher khuyến mãi"), "PROMOTIONS")

    def test_enrich_smart_quick_replies_fallback(self):
        # Empty input -> fallback to topic
        replies = enrich_smart_quick_replies("Lãi suất tiết kiệm 12 tháng là bao nhiêu", raw_replies=[])
        self.assertTrue(len(replies) >= 2)
        for r in replies:
            self.assertTrue(len(r) >= 6)
            self.assertNotEqual(r.lower(), "lãi suất tiết kiệm 12 tháng là bao nhiêu")

    def test_enrich_smart_quick_replies_cleaning(self):
        # Cleans short or identical replies
        raw = ["Vay", "Lãi", "Điều kiện vay tiêu dùng Quick Loan", "ok"]
        replies = enrich_smart_quick_replies("Tôi muốn vay vốn", raw_replies=raw)
        self.assertIn("Điều kiện vay tiêu dùng Quick Loan", replies)
        self.assertNotIn("Vay", replies)
        self.assertNotIn("ok", replies)


if __name__ == "__main__":
    unittest.main()
