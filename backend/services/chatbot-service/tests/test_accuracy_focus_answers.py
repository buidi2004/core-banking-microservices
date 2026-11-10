"""
Test Suite: Xác thực tính Đúng Trọng Tâm (Razor-Sharp Accuracy & Direct Answers)
Đảm bảo bot không bị lệch chủ đề:
1. Hỏi hạn mức chuyển tiền -> Trả về con số eKYC Cấp 1, Cấp 2, QĐ 2345 (không trả về các bước cách chuyển tiền)
2. Hỏi chuyển tiền có mất phí không -> Trả lời Miễn phí 100% trọn đời (không trả về các bước cách chuyển tiền)
3. Hỏi hạn mức rút tiền ATM -> Trả về tối thiểu 50k, tối đa 5tr/lần, 20tr/ngày (không trả về các bước cách rút tiền)
4. Hỏi mở sổ tiết kiệm tối thiểu bao nhiêu tiền -> Trả về tối thiểu 1.000.000đ có kỳ hạn / 100.000đ tích lũy (không sinh bảng 10 năm)
5. Hỏi rút tiền ATM có mất phí không -> Trả về Miễn phí 100% tại mọi ATM Napas (không trả về các bước cách rút tiền)
6. Hỏi phí thường niên thẻ Visa -> Trả về Miễn phí 100% trọn đời
7. Hỏi hạn mức nạp tiền vào ví -> Trả về 50tr/ngày Cấp 1, 500tr/ngày Cấp 2
8. Hỏi tính lãi kép 10 năm cho tiền trong tài khoản -> Kích hoạt đúng bảng tính 10 năm và so sánh vay
"""

import unittest
from app.rag_engine import rag_engine


class TestAccuracyFocusAnswers(unittest.TestCase):

    def test_transfer_limit_direct_answer(self):
        resp = rag_engine.answer_query("hạn mức chuyển tiền là bao nhiêu")
        ans = resp.answer.lower()
        self.assertIn("10.000.000 vnđ", ans)
        self.assertIn("500.000.000 vnđ", ans)
        self.assertNotIn("bước 1: tại trang chủ", ans)
        self.assertIsNotNone(resp.suggested_action)
        # Câu hỏi hạn mức → điều hướng màn hình Cấp độ tài khoản & Hạn mức
        self.assertEqual(resp.suggested_action.route, "/profile/kyc-level")

    def test_transfer_fee_direct_answer(self):
        resp = rag_engine.answer_query("chuyển tiền có mất phí không")
        ans = resp.answer.lower()
        self.assertIn("miễn phí 100%", ans)
        self.assertNotIn("bước 1: tại trang chủ, chọn tính năng chuyển tiền", ans)
        self.assertIsNotNone(resp.suggested_action)
        self.assertEqual(resp.suggested_action.route, "/transfer")

    def test_atm_withdrawal_limit_direct_answer(self):
        resp = rag_engine.answer_query("hạn mức rút tiền ATM là bao nhiêu")
        ans = resp.answer.lower()
        # Hạn mức chuẩn: eKYC C1 = 5tr/ngày, QĐ 2345 yêu cầu sinh trắc từ 20tr/ngày
        self.assertIn("5.000.000 vnđ", ans)
        self.assertIn("20.000.000 vnđ", ans)
        self.assertNotIn("nhận mã rút tiền 6 số", ans)
        self.assertIsNotNone(resp.suggested_action)
        # LLM có thể chọn route hợp lệ khác (/more, /cards...) — chỉ cần nằm trong whitelist
        from app.schemas import VALID_APP_ROUTES
        self.assertIn(resp.suggested_action.route, VALID_APP_ROUTES)

    def test_savings_minimum_amount_direct_answer(self):
        resp = rag_engine.answer_query("mở sổ tiết kiệm tối thiểu bao nhiêu tiền")
        ans = resp.answer.lower()
        self.assertIn("1.000.000 vnđ", ans)
        self.assertIn("100.000 vnđ", ans)
        # Không được sinh bảng kế hoạch 10 năm lan man
        self.assertNotIn("kế hoạch gửi tiết kiệm online lãi kép (10 năm)", ans)
        self.assertIsNotNone(resp.suggested_action)
        self.assertEqual(resp.suggested_action.route, "/bills/savings")

    def test_atm_withdrawal_fee_direct_answer(self):
        resp = rag_engine.answer_query("rút tiền ATM có mất phí không")
        ans = resp.answer.lower()
        self.assertIn("miễn phí", ans)
        self.assertNotIn("nhập mã số bí mật 6 số", ans)
        self.assertIsNotNone(resp.suggested_action)
        # Route phải hợp lệ trên app (LLM sinh route không whitelist sẽ bị chặn) —
        # chấp nhận các route hợp lý cho câu hỏi phí/rút tiền ATM
        self.assertIn(resp.suggested_action.route, {"/atm-withdrawal", "/more", "/fees-and-charges", "/support/help-center", "/bills"})

    def test_visa_fee_direct_answer(self):
        resp = rag_engine.answer_query("phí thường niên thẻ visa platinum")
        ans = resp.answer.lower()
        self.assertIn("miễn phí", ans)
        self.assertIsNotNone(resp.suggested_action)
        # FEES canned trả /support/help-center; LLM path có thể chọn /cards, /bank-cards
        self.assertIn(resp.suggested_action.route, {"/cards", "/bank-cards", "/more", "/support/help-center"})

    def test_financial_calculator_triggers_when_explicitly_requested(self):
        query = "tôi có tiền trong tài khoản để tiết kiệm 10 năm tự nó tính lãi suất và lãi vay"
        resp = rag_engine.answer_query(query)
        ans = resp.answer.lower()
        # Nhờ route clamp + whitelist, route trả về luôn hợp lệ trên app
        self.assertIsNotNone(resp.suggested_action)
        # SSOT: câu trả lời qua LLM/tool PHẢI dùng lãi suất chuẩn trong biểu (5.6% kỳ hạn 12m
        # dùng cho lãi kép 10 năm), không được bịa con số khác (vd 6.5%)
        self.assertIn("5.6", ans)
        self.assertNotIn("6.5", ans)
        self.assertIn("10 năm", ans)


if __name__ == "__main__":
    unittest.main()
