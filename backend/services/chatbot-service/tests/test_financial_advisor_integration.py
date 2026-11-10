"""
Integration Test for End-to-End Financial Advisory & Robo-Advisor AI Flow
"""

import unittest
from unittest.mock import MagicMock, patch
from app.rag_engine import AdvancedRAGEngine
from app.schemas import MessageItem


class TestFinancialAdvisorIntegration(unittest.TestCase):

    def setUp(self):
        # Khởi tạo instance của AdvancedRAGEngine với các mock cần thiết
        self.engine = AdvancedRAGEngine()

    def test_end_to_end_financial_advisory_query(self):
        user_query = "tui có tiền trong tìa kharon vậy đẻ tiêt kiệm 10 năm hay vài nawkm thì tự nso tính lãi xuấy và tự nó tính lãi xuất vay lun vvvv"
        
        # Mock ví người dùng có 30.000.000 VNĐ
        mock_wallet = {
            "balance": 30_000_000.0,
            "status": "ACTIVE",
            "dailyLimit": 50_000_000.0
        }

        with patch.object(self.engine, "_fetch_user_wallet_balance", return_value=mock_wallet):
            response = self.engine.answer_query(user_query, history=[], user_id="user-123456")

            self.assertIsNotNone(response)
            self.assertTrue(len(response.answer) > 50)
            
            # Kiểm tra xem có nhận biết ngữ cảnh số dư ví 30 triệu không
            self.assertTrue(
                "30.000.000" in response.answer or "30 triệu" in response.answer or "Tiết Kiệm" in response.answer,
                f"Answer did not contain financial calculation: {response.answer[:300]}"
            )

            # Kiểm tra xem có tính toán lãi kép tiết kiệm dài hạn (10 năm) không
            self.assertTrue(
                "10 năm" in response.answer or "Lãi Kép" in response.answer or "6.3%" in response.answer
            )

            # Kiểm tra xem có tính toán khoản vay Quick Loan tương ứng không
            self.assertTrue(
                "vay" in response.answer.lower() or "dư nợ giảm dần" in response.answer.lower() or "1.2%" in response.answer
            )

            # Kiểm tra nút điều hướng suggested_action
            self.assertIsNotNone(response.suggested_action)
            self.assertIn(response.suggested_action.route, ["/bills/savings", "/bills/quick-loan", "/loan/schedule", "/savings"])

            # Kiểm tra quick replies
            self.assertTrue(len(response.quick_replies) >= 2)


if __name__ == "__main__":
    unittest.main()
