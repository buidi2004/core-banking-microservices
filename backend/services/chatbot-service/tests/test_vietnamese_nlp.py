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
             "chuyển khoản Napas 247 bi treo tien bao chăm sóc khách hàng the nao"),
            ("tui có tiền trong tìa kharon vậy đẻ tiêt kiệm 10 năm hay vài nawkm thì tự nso tính lãi xuấy và tự nó tính lãi xuất vay lun vvvv",
             "tôi có tiền trong tài khoản vậy đẻ tiết kiệm 10 năm hay vài năm thì tự nó tính lãi suất và tự nó tính lãi suất vay luôn vân vân")
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

    def test_enrich_smart_quick_replies_multi_turn_loan_journey(self):
        # Turn 1: User hỏi hồ sơ vay
        history_t1 = []
        q1 = "Điều kiện hồ sơ vay tiêu dùng Quick Loan gồm những gì?"
        replies_t1 = enrich_smart_quick_replies(q1, history=history_t1)
        self.assertTrue(any("lãi suất" in r.lower() for r in replies_t1))
        # Không được chứa chính câu hỏi
        for r in replies_t1:
            self.assertFalse("điều kiện hồ sơ vay" in r.lower())

        # Turn 2: User hỏi tiếp về lãi suất vay (kèm history Turn 1)
        history_t2 = [
            {"role": "user", "content": q1},
            {"role": "assistant", "content": "Dạ điều kiện chỉ cần CCCD gắn chip..."}
        ]
        q2 = "Lãi suất vay Quick Loan bao nhiêu một tháng?"
        replies_t2 = enrich_smart_quick_replies(q2, history=history_t2)

        # TUYỆT ĐỐI không được gợi ý lại Hồ sơ vay (Turn 1) hay Lãi suất vay (Turn 2)
        for r in replies_t2:
            r_low = r.lower()
            self.assertFalse("điều kiện" in r_low and "vay" in r_low, f"Repeated Turn 1 doc inquiry: {r}")
            self.assertFalse("lãi suất vay" in r_low, f"Repeated Turn 2 query: {r}")

        # Phải gợi ý các bước logic tiếp theo: Bảng tính trả nợ, Thời gian giải ngân, Phí trả trước hạn
        self.assertTrue(any(any(k in r.lower() for k in ["bảng tính", "dư nợ giảm dần", "giải ngân", "trước hạn"]) for r in replies_t2))

    def test_enrich_smart_quick_replies_multi_turn_savings_journey(self):
        # Turn 1: User hỏi biểu lãi suất
        q1 = "Biểu lãi suất tiết kiệm trực tuyến các kỳ hạn"
        history_t1 = []
        replies_t1 = enrich_smart_quick_replies(q1, history=history_t1)
        self.assertTrue(len(replies_t1) >= 2)

        # Turn 2: User hỏi tính lãi gửi 100 triệu
        q2 = "Gửi 100 triệu 12 tháng tính lãi được bao nhiêu tiền?"
        history_t2 = [
            {"role": "user", "content": q1},
            {"role": "assistant", "content": "Dạ biểu lãi suất từ 3.8% đến 6.8%/năm..."}
        ]
        replies_t2 = enrich_smart_quick_replies(q2, history=history_t2)

        # Gợi ý Turn 2 không được lặp lại biểu lãi suất hay tính lãi
        for r in replies_t2:
            r_low = r.lower()
            self.assertFalse("biểu lãi suất" in r_low)
            self.assertFalse("100 triệu" in r_low)

        # Phải hướng tới rút trước hạn TT 04, tiết kiệm bậc thang hoặc mở sổ online
        self.assertTrue(any(any(k in r.lower() for k in ["rút tiền", "thông tư 04", "tt 04", "bậc thang", "mở sổ"]) for r in replies_t2))

    def test_enrich_smart_quick_replies_onboarding_nfc_journey(self):
        # Turn 1: User hỏi giấy tờ tạo app
        q1 = "Giấy tờ để tạo app cần những gì?"
        history_t1 = []
        replies_t1 = enrich_smart_quick_replies(q1, history=history_t1)
        self.assertTrue(any("nfc" in r.lower() for r in replies_t1))

        # Turn 2: User hỏi máy không có NFC
        q2 = "Điện thoại của tôi không có NFC có mở app được không?"
        history_t2 = [
            {"role": "user", "content": q1},
            {"role": "assistant", "content": "Dạ cần CCCD gắn chip chính chủ..."}
        ]
        replies_t2 = enrich_smart_quick_replies(q2, history=history_t2)

        # Gợi ý Turn 2 phải đưa ra giải pháp tiếp theo: Smart Lounge, VNeID, Hạn mức
        for r in replies_t2:
            r_low = r.lower()
            self.assertFalse("giấy tờ để tạo app" in r_low)
            self.assertFalse("không có nfc có mở app được không" in r_low)

        self.assertTrue(any(any(k in r.lower() for k in ["smart lounge", "vneid", "10 triệu", "tài khoản"]) for r in replies_t2))


if __name__ == "__main__":
    unittest.main()
