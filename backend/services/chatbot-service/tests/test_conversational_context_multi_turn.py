"""
Unit & Integration Test Suite: Multi-Turn Conversational Context & Screen Context
Kiểm tra khả năng lưu giữ ngữ cảnh hội thoại đa lượt, kế thừa thực thể và nhận thức màn hình Mobile App:
1. Loan Purpose Continuation: Hỏi vay -> Chọn mục đích 'tiêu dùng' -> Tự động tính toán trả góp Quick Loan
2. Attribute Inheritance: Thảo luận thẻ Visa -> Hỏi 'có mất phí không?' -> Trả lời chính xác phí thẻ Visa
3. Client Screen Awareness: Đang ở màn hình /bills/quick-loan -> Hỏi 'hạn mức bao nhiêu?' -> Trả lời hạn mức Quick Loan
4. Cross-product Pivot: Đang tính tiết kiệm 50tr -> Hỏi 'thế nếu vay thì sao?' -> Chuyển sang tính khoản vay 50tr
5. Term Continuation: Tính tiết kiệm 50tr 1 năm -> Hỏi 'thế còn 2 năm?' -> Kế thừa 50tr và tính lãi 2 năm
"""

import unittest
from app.disambiguation_handler import (
    extract_context_from_history,
    enrich_query_with_context
)
from app.guided_flow_handler import (
    classify_question_archetype,
    INTENT_LEAD_ACTION,
    INTENT_HOW_TO_ACTION
)


class TestConversationalContext(unittest.TestCase):

    def test_loan_purpose_continuation(self):
        """Khách hỏi vay -> Bot hỏi mục đích -> Khách đáp 'tiêu dùng'"""
        history = [
            {"role": "user", "content": "tôi muốn vay"},
            {"role": "assistant", "content": "Dạ, để em tư vấn phương án trả nợ tối ưu nhất, Quý khách dự định vay cho mục đích gì ạ?"}
        ]
        ctx = extract_context_from_history(history)
        self.assertEqual(ctx["last_topic"], "LOANS")
        self.assertEqual(ctx["pending_clarification"], "WAITING_FOR_LOAN_PURPOSE")

        enriched = enrich_query_with_context("tiêu dùng", ctx)
        self.assertIn("Quick Loan", enriched)
        self.assertIn("tiêu dùng", enriched.lower())

        arch = classify_question_archetype(enriched, history)
        self.assertEqual(arch, INTENT_LEAD_ACTION)

    def test_card_fee_attribute_inheritance(self):
        """Khách thảo luận thẻ Visa -> Hỏi 'có mất phí không?' -> Kế thừa thẻ Visa"""
        history = [
            {"role": "user", "content": "thẻ visa"},
            {"role": "assistant", "content": "Dạ Quý khách đang quan tâm đến dòng thẻ ảo Visa Platinum Virtual..."}
        ]
        ctx = extract_context_from_history(history)
        self.assertEqual(ctx["last_topic"], "CARDS")

        enriched = enrich_query_with_context("có mất phí không?", ctx)
        self.assertIn("visa", enriched.lower())
        self.assertIn("phí", enriched.lower())

    def test_client_screen_context_loan_limits(self):
        """Khách đứng ở màn hình /bills/quick-loan -> Hỏi cụt 'hạn mức bao nhiêu?'"""
        client_ctx = {
            "current_screen": "/bills/quick-loan",
            "platform": "flutter_mobile"
        }
        ctx = extract_context_from_history([], client_context=client_ctx)
        self.assertEqual(ctx["last_topic"], "LOANS")

        enriched = enrich_query_with_context("hạn mức bao nhiêu?", ctx)
        self.assertIn("Quick Loan", enriched)
        self.assertIn("hạn mức", enriched.lower())

    def test_cross_product_savings_to_loan(self):
        """Khách đang tính tiết kiệm 50 triệu -> Hỏi 'thế nếu vay thì sao?'"""
        history = [
            {"role": "user", "content": "tôi có 50 triệu muốn gửi tiết kiệm 2 năm"},
            {"role": "assistant", "content": "Dạ Sen Hồng xin gợi ý giải pháp Gửi Tiết Kiệm Online Lãi Kép..."}
        ]
        ctx = extract_context_from_history(history)
        self.assertEqual(ctx["last_topic"], "SAVINGS")
        self.assertEqual(ctx["last_amount"], 50_000_000.0)

        enriched = enrich_query_with_context("thế nếu vay thì sao?", ctx)
        self.assertIn("Quick Loan", enriched)
        self.assertIn("50.000.000", enriched)

    def test_term_continuation_savings(self):
        """Khách tính tiết kiệm 50 triệu -> Hỏi 'thế còn 2 năm?' -> Kế thừa 50 triệu"""
        history = [
            {"role": "user", "content": "tôi có 50 triệu muốn gửi tiết kiệm"},
            {"role": "assistant", "content": "Dạ Sen Hồng xin gợi ý giải pháp Gửi Tiết Kiệm Online Lãi Kép..."}
        ]
        ctx = extract_context_from_history(history)
        self.assertEqual(ctx["last_amount"], 50_000_000.0)

        enriched = enrich_query_with_context("thế còn 2 năm?", ctx)
        self.assertIn("50.000.000", enriched)
        self.assertIn("2 năm", enriched.lower())


if __name__ == "__main__":
    unittest.main()
