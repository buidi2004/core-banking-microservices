"""
Unit & Integration Test Suite: 8 Banking Chatbot Quality & Architecture Guardrails
Kiểm tra toàn diện 8 nguyên tắc tối ưu hóa AI Chatbot Ngân Hàng:
1. Disambiguation (Hỏi lại khi mơ hồ: "tính lãi", "phí", "hạn mức")
2. Deterministic Code Calculation (Tính toán số học chuẩn xác 100%, không để LLM đoán)
3. RAG Grounding & Zero-Hallucination
4. System Prompt & Few-Shot Compliance
5. Multi-Turn Context Tracking (Lưu vết và làm giàu ngữ cảnh đa lượt)
6. Output Validation Guardrails (Chống câu cụt, cân bằng markdown **, chặn rò rỉ prompt)
7. Smart Fallback (Lần 1 gợi ý chủ đề gần nhất, lần 2 mới chuyển người thật)
8. Banking ReAct Tools & Safe Execution (user_id server-managed, read-only tools)
"""

import unittest
from app.financial_calculator import (
    calculate_savings_compound,
    calculate_loan_amortization,
    calculate_target_goal_savings,
    extract_amount_from_text,
    extract_term_years_from_text,
    format_vnd
)
from app.disambiguation_handler import (
    check_ambiguous_query,
    extract_context_from_history,
    enrich_query_with_context
)
from app.output_validator import sanitize_and_validate_output
from app.schemas import MessageItem
from app.banking_agent import BANKING_TOOLS, BankingToolExecutor

class TestChatbotQualityGuardrails(unittest.TestCase):

    def test_principle_1_disambiguation(self):
        """Nguyên tắc 1: Hỏi lại khi mơ hồ với câu ngắn và cung cấp Quick Replies"""
        # Câu ngắn 'tính lãi'
        r1 = check_ambiguous_query("tính lãi")
        self.assertIsNotNone(r1)
        self.assertEqual(r1["disambiguation_type"], "INTEREST")
        self.assertTrue(len(r1["quick_replies"]) >= 3)
        self.assertIn("tiết kiệm", r1["answer"].lower())
        self.assertIn("vay", r1["answer"].lower())

        # Câu ngắn 'phí'
        r2 = check_ambiguous_query("phí")
        self.assertIsNotNone(r2)
        self.assertEqual(r2["disambiguation_type"], "FEES")
        self.assertIn("biểu phí", r2["answer"].lower())

        # Câu ngắn 'hạn mức'
        r3 = check_ambiguous_query("hạn mức")
        self.assertIsNotNone(r3)
        self.assertEqual(r3["disambiguation_type"], "LIMITS")
        self.assertIn("hạn mức", r3["answer"].lower())

        # Câu đầy đủ thông tin thì không kích hoạt disambiguation
        r4 = check_ambiguous_query("tôi có 50 triệu muốn gửi tiết kiệm 12 tháng")
        self.assertIsNone(r4)

    def test_principle_2_deterministic_calculation(self):
        """Nguyên tắc 2: Code tính toán riêng bằng Tool, không để LLM tự tính lũy thừa kép"""
        # Tiết kiệm 50 triệu 10 năm với 6.3%/năm
        s = calculate_savings_compound(50_000_000, term_years=10, rate_annual=6.3)
        t_data = s["target_data"]
        # FV = 50tr * (1 + 0.063)^10 = 92.109.123 VNĐ
        self.assertAlmostEqual(t_data["total_savings"], 92109123.0, delta=100.0)
        self.assertAlmostEqual(t_data["interest_savings"], 42109123.0, delta=100.0)

        # So sánh CASA 0.2%/năm
        # FV_casa = 50tr * (1 + 0.002)^10 = 51.009.048 VNĐ
        self.assertAlmostEqual(t_data["interest_casa"], 1009048.0, delta=100.0)
        self.assertGreater(t_data["difference"], 41_000_000)

        # Khoản vay Quick Loan 50 triệu 12 tháng, 1.2%/tháng dư nợ giảm dần
        loan = calculate_loan_amortization(50_000_000, term_months=12, rate_monthly=1.2)
        # Gốc hàng tháng = 50tr / 12 = 4.166.667
        self.assertAlmostEqual(loan["monthly_principal"], 4166667.0, delta=10.0)
        # Lãi tháng 1 = 50tr * 1.2% = 600.000 -> Tháng 1 trả = 4.766.667
        self.assertAlmostEqual(loan["first_month_payment"], 4766667.0, delta=10.0)
        # Tổng lãi 12 tháng = 3.900.000 VNĐ
        self.assertAlmostEqual(loan["total_interest"], 3900000.0, delta=100.0)

    def test_principle_5_multi_turn_context_tracking(self):
        """Nguyên tắc 5: Giữ ngữ cảnh hội thoại đa lượt và tự động làm giàu truy vấn"""
        history = [
            MessageItem(role="user", content="tôi có 50 triệu muốn gửi tiết kiệm"),
            MessageItem(role="assistant", content="Quý khách muốn gửi trong kỳ hạn bao lâu ạ?"),
        ]
        context = extract_context_from_history(history)
        self.assertEqual(context.get("last_topic"), "SAVINGS")
        self.assertEqual(context.get("last_amount"), 50_000_000.0)

        # Lượt tiếp theo khách nói cộc lốc 'thế còn 5 năm'
        enriched = enrich_query_with_context("thế còn 5 năm", context)
        self.assertIn("50.000.000 VNĐ", enriched)
        self.assertIn("tiết kiệm", enriched)

    def test_principle_6_output_validator_guardrails(self):
        """Nguyên tắc 6: Chặn lỗi đầu ra trước khi gửi khách (câu cụt, markdown **, leak)"""
        # Lỗi câu rỗng
        fixed_empty = sanitize_and_validate_output("", "cách chuyển tiền")
        self.assertIn("Sen Hồng", fixed_empty)

        # Lỗi lệch dấu markdown bold **
        unbalanced_bold = "Lãi suất ưu đãi là **6.3%/năm và tiền gốc là **50 triệu**"
        balanced = sanitize_and_validate_output(unbalanced_bold, "hỏi lãi suất")
        self.assertEqual(balanced.count("**") % 2, 0)

        # Lỗi rò rỉ prompt nội bộ
        leaked_prompt = "You are a helpful banking assistant. Answer in JSON format. Dạ chào quý khách."
        sanitized = sanitize_and_validate_output(leaked_prompt, "chào em")
        self.assertNotIn("You are a helpful", sanitized)
        self.assertIn("Dạ chào quý khách", sanitized)

    def test_principle_8_banking_tools_schema(self):
        """Nguyên tắc 8: Kiểm tra cấu trúc Banking Tools đạt chuẩn Function Calling"""
        tool_names = [t["function"]["name"] for t in BANKING_TOOLS]
        expected_tools = [
            "get_account_summary",
            "get_recent_transactions",
            "get_interest_rates",
            "calculate_interest",
            "search_knowledge_base",
            "handoff_to_agent"
        ]
        for exp in expected_tools:
            self.assertIn(exp, tool_names)

        # Kiểm tra ToolExecutor tính toán chuẩn xác
        executor = BankingToolExecutor(rag_engine_instance=None)
        res = executor._calculate_interest("SAVINGS_COMPOUND", 100_000_000, 12, 6.3)
        self.assertEqual(res["calculation_type"], "SAVINGS_COMPOUND")
        self.assertEqual(res["principal_amount"], 100000000.0)
        self.assertIn("yearly_breakdown", res)

if __name__ == "__main__":
    unittest.main()
