"""
Test Suite: Xác thực Khả năng Xử lý Câu Hỏi Dài & Đa Ý Định (Long & Compound Query Engine)
Bảo vệ 5 kịch bản thực tế khi người dùng gõ câu dài:
1. Gói Vay Quick Loan dài (Điều kiện + Lãi suất + Giải ngân + Hạn mức).
2. Tiết kiệm dài (So sánh 12 tháng vs 24 tháng + Quy định rút một phần trước hạn theo TT 04/2022/TT-NHNN).
3. Chuyển tiền treo Napas dài (Bị trừ tiền nhưng chưa nhận, Bảo toàn tiền Saga Ledger, Quy trình tra soát).
4. Thẻ ảo Visa Platinum Virtual dài (Phí 0đ, Hạn mức 100tr, Netflix/Spotify/Apple Pay, Phí ngoại tệ).
5. Sinh trắc học QĐ 2345 dài (Hạn mức 10tr/20tr, Vị trí ăng-ten NFC iPhone).
"""

import unittest
from app.rag_engine import rag_engine


class TestLongQueryHandling(unittest.TestCase):

    def test_case_1_loan_comprehensive_long_query(self):
        query = (
            "Dạ em chào anh chị bên ngân hàng sen hồng, em là nhân viên văn phòng đi làm được 1 năm "
            "lương chuyển khoản 15 triệu một tháng, hiện tại em đang muốn tìm hiểu gói vay tiêu dùng Quick Loan "
            "tầm 30 triệu thì điều kiện thủ tục như thế nào, lãi suất bao nhiêu và giải ngân có nhanh không ạ?"
        )
        resp = rag_engine.answer_query(query)
        ans = resp.answer.lower()
        self.assertIn("điều kiện & thủ tục", ans)
        self.assertIn("18 đến 60 tuổi", ans)
        self.assertIn("1.2%", ans)
        self.assertIn("dư nợ giảm dần", ans)
        self.assertIn("giải ngân", ans)
        self.assertIn("1 phút", ans)
        self.assertIsNotNone(resp.suggested_action)
        self.assertEqual(resp.suggested_action.route, "/bills/quick-loan")

    def test_case_2_savings_term_compare_and_early_withdraw(self):
        query = (
            "Tôi đang có 200 triệu trong tài khoản, tôi muốn hỏi là gửi tiết kiệm online 12 tháng hay 24 tháng "
            "thì lãi suất cao hơn, và nếu giữa chừng tôi cần tiền rút ra một phần thì có bị mất hết tiền lãi "
            "của số tiền còn lại không?"
        )
        resp = rag_engine.answer_query(query)
        ans = resp.answer.lower()
        # Không được kích hoạt cảnh báo khẩn cấp / khóa thẻ giả
        self.assertNotIn("cảnh báo khẩn cấp", ans)
        self.assertNotIn("kẻ gian chiếm quyền", ans)
        self.assertIn("5.6%/năm", ans)
        self.assertIn("6.0%/năm", ans)
        self.assertIn("thông tư 04/2022/tt-nhnn", ans)
        self.assertIn("không bị mất hết tiền lãi", ans)
        self.assertIsNotNone(resp.suggested_action)
        self.assertEqual(resp.suggested_action.route, "/bills/savings")

    def test_case_3_transfer_dispute_and_saga_protection(self):
        query = (
            "Cho mình hỏi là trưa nay mình có chuyển khoản 15 triệu qua Napas 24/7 từ tài khoản Sen Hồng sang "
            "Vietcombank cho bạn nhưng bên kia bảo chưa nhận được, trong khi tài khoản ví của mình thì đã bị trừ tiền rồi, "
            "trường hợp này tiền có bị mất không và mình phải làm gì để tra soát ạ?"
        )
        resp = rag_engine.answer_query(query)
        ans = resp.answer.lower()
        # Không được nhầm sang tra cứu danh sách thẻ
        self.assertNotIn("tra cứu danh sách thẻ", ans)
        self.assertIn("bảo toàn", ans)
        self.assertIn("không thể bị mất", ans)
        self.assertIn("5 đến 30 phút", ans)
        self.assertIn("tra soát", ans)
        self.assertIsNotNone(resp.suggested_action)
        self.assertEqual(resp.suggested_action.route, "/history")

    def test_case_4_visa_virtual_global_usage_and_fees(self):
        query = (
            "Mình chuẩn bị đi công tác nước ngoài nên muốn mở thẻ ảo quốc tế Visa Platinum Virtual trên app, "
            "cho mình hỏi mở thẻ có mất phí không, phí thường niên hàng năm là bao nhiêu, hạn mức thanh toán "
            "một ngày là bao nhiêu và quẹt ở nước ngoài hay thanh toán Netflix Spotify có được không?"
        )
        resp = rag_engine.answer_query(query)
        ans = resp.answer.lower()
        self.assertIn("miễn phí 100%", ans)
        self.assertIn("100.000.000 vnđ/ngày", ans)
        self.assertIn("netflix", ans)
        self.assertIn("apple pay", ans)
        self.assertIn("1.5%", ans)
        self.assertIsNotNone(resp.suggested_action)
        self.assertEqual(resp.suggested_action.route, "/cards")

    def test_case_5_biometrics_nfc_iphone_placement(self):
        query = (
            "Em muốn hỏi về quy định sinh trắc học theo quyết định 2345 của ngân hàng nhà nước, "
            "em dùng điện thoại iPhone thì quét chip NFC CCCD ở vị trí nào và chuyển tiền từ bao nhiêu "
            "triệu một lần thì bắt buộc phải quét khuôn mặt ạ?"
        )
        resp = rag_engine.answer_query(query)
        ans = resp.answer.lower()
        self.assertIn("10.000.000 vnđ/lần", ans)
        self.assertIn("20.000.000 vnđ/ngày", ans)
        self.assertIn("mép đỉnh trên cùng", ans)
        self.assertIn("iphone", ans)
        self.assertIsNotNone(resp.suggested_action)
        self.assertEqual(resp.suggested_action.route, "/profile/nfc-reader")


if __name__ == "__main__":
    unittest.main()
