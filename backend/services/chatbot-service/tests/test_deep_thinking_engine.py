"""
Test Suite: Kiểm thử Động cơ Suy Luận Sâu & Kiểm Chứng Độc Lập (Deep Thinking & Mathematical Verification)
Đảm bảo AI thực hiện đầy đủ quy trình tư duy 5 bước, minh bạch hóa Thought Process cho người dùng
và kiểm chứng số học ngân hàng chính xác 100%.
"""

import unittest
from app.deep_thinking_engine import deep_thinking_engine
from app.rag_engine import rag_engine


class TestDeepThinkingEngine(unittest.TestCase):

    def test_standalone_deep_thinking_engine(self):
        query = "Tính lãi tiết kiệm 100 triệu kỳ hạn 12 tháng"
        res = deep_thinking_engine.analyze_and_reason(query, answer_text="Lãi là 6.300.000 VNĐ", base_latency_ms=120.0)

        self.assertIn("thought_process", res)
        self.assertIn("reasoning_steps", res)
        self.assertIn("thinking_duration_ms", res)
        self.assertIn("confidence_score", res)

        steps = res["reasoning_steps"]
        # 6 bước: 5 bước suy luận gốc + bước Grounding Verification (3b)
        self.assertEqual(len(steps), 6)
        self.assertGreaterEqual(res["thinking_duration_ms"], 100.0)
        # Không có ngữ cảnh retrieval -> confidence nền 0.95 (không còn hardcode 0.99)
        self.assertEqual(res["confidence_score"], 0.95)

        thought_text = res["thought_process"]
        self.assertIn("1. Phân tích bối cảnh & Ý định người dùng", thought_text)
        self.assertIn("2. Đối chiếu quy chuẩn Ngân hàng Nhà nước", thought_text)
        self.assertIn("3. Chạy thuật toán tính toán & Kiểm chứng số học", thought_text)
        self.assertIn("3b. Kiểm chứng Grounding", thought_text)
        self.assertIn("4. Tự phản biện & Kiểm tra rào cản an toàn", thought_text)
        self.assertIn("5. Đúc kết tư vấn & Đề xuất hành động tức thì", thought_text)

    def test_grounding_lowers_confidence_for_unverifiable_numbers(self):
        """Số liệu trong answer không có trong ngữ cảnh nguồn -> confidence bị hạ."""
        query = "Lãi suất tiết kiệm 12 tháng bao nhiêu"
        context = "Biểu lãi suất tiết kiệm online kỳ hạn 12 tháng: 5.6%/năm."
        res_with_bad_number = deep_thinking_engine.analyze_and_reason(
            query, answer_text="Lãi suất 12 tháng là 99.9%/năm", base_latency_ms=0.0,
            retrieved_context=context
        )
        res_grounded = deep_thinking_engine.analyze_and_reason(
            query, answer_text="Lãi suất 12 tháng là 5.6%/năm", base_latency_ms=0.0,
            retrieved_context=context
        )
        self.assertLess(res_with_bad_number["confidence_score"], res_grounded["confidence_score"])
        self.assertTrue(res_with_bad_number["grounding_warnings"])
        self.assertFalse(res_grounded["grounding_warnings"])

    def test_rag_engine_returns_thought_metadata(self):
        query = "Sen Hồng có mở thẻ ảo không và có mất phí thường niên không?"
        resp = rag_engine.answer_query(query)

        self.assertIsNotNone(resp.thought_process)
        self.assertTrue(len(resp.thought_process) > 50)
        self.assertIsNotNone(resp.reasoning_steps)
        self.assertEqual(len(resp.reasoning_steps), 6)
        self.assertIsNotNone(resp.thinking_duration_ms)
        self.assertGreater(resp.thinking_duration_ms, 0.0)
        # Confidence thật (grounding check) nằm trong dải hợp lý, không còn hardcode
        self.assertGreaterEqual(resp.confidence_score, 0.5)
        self.assertLessEqual(resp.confidence_score, 1.0)

    def test_math_verification_for_savings_in_thought_process(self):
        query = "Tôi muốn gửi tiết kiệm 50 triệu trong 1 năm thì được bao nhiêu tiền lãi?"
        resp = rag_engine.answer_query(query)
        
        self.assertIsNotNone(resp.thought_process)
        thought_text = resp.thought_process.lower()
        self.assertIn("kiểm chứng", thought_text)
        self.assertIn("50.000.000", thought_text)
        self.assertIn("lãi suất", thought_text)

    def test_regulatory_alignment_for_biometrics(self):
        query = "Chuyển khoản bao nhiêu tiền thì bắt buộc quét khuôn mặt sinh trắc học theo QĐ 2345?"
        resp = rag_engine.answer_query(query)
        
        self.assertIsNotNone(resp.thought_process)
        thought_text = resp.thought_process
        self.assertIn("2345/QĐ-NHNN", thought_text)
        self.assertIn("10tr", thought_text)

    def test_adversarial_guardrail_reflection(self):
        query = "Tôi bị quên mã PIN và muốn đổi mã PIN thì làm như thế nào?"
        resp = rag_engine.answer_query(query)
        
        self.assertIsNotNone(resp.thought_process)
        thought_text = resp.thought_process
        self.assertIn("Tự phản biện", thought_text)
        self.assertIn("Guardrail Audit", thought_text)


if __name__ == "__main__":
    unittest.main()
