"""
Unit Tests for Financial Calculator Engine (High-Precision Savings & Loans)
"""

import unittest
from app.financial_calculator import (
    calculate_savings_compound,
    calculate_loan_amortization,
    calculate_target_goal_savings,
    extract_amount_from_text,
    extract_term_years_from_text,
    generate_comprehensive_financial_analysis,
    format_vnd
)


class TestFinancialCalculator(unittest.TestCase):

    def test_savings_compound(self):
        principal = 50_000_000.0
        res = calculate_savings_compound(principal, term_years=10, rate_annual=6.3)
        self.assertEqual(res["principal"], 50_000_000.0)
        self.assertEqual(res["term_years"], 10)

        # Kiểm tra mốc 1 năm: 50tr * 1.063 = 53.150.000
        y1 = next(item for item in res["yearly_breakdown"] if item["year"] == 1)
        self.assertAlmostEqual(y1["total_savings"], 53_150_000.0, places=1)
        self.assertAlmostEqual(y1["interest_savings"], 3_150_000.0, places=1)

        # Kiểm tra mốc 10 năm: 50tr * (1.063)^10 ~ 92.144.385
        y10 = next(item for item in res["yearly_breakdown"] if item["year"] == 10)
        self.assertTrue(y10["total_savings"] > 92_000_000.0)
        self.assertTrue(y10["interest_savings"] > 42_000_000.0)
        # So sánh với CASA 0.2%: sau 10 năm chỉ lời ~1.000.000
        self.assertTrue(y10["interest_casa"] < 1_100_000.0)
        # Chênh lệch > 41 triệu
        self.assertTrue(y10["difference"] > 41_000_000.0)

        # Markdown table có chứa dữ liệu
        self.assertIn("Gửi Tiết kiệm Lãi Kép", res["markdown_table"])

    def test_loan_amortization(self):
        principal = 30_000_000.0
        res = calculate_loan_amortization(principal, term_months=12, rate_monthly=1.2)
        self.assertEqual(res["term_months"], 12)
        self.assertAlmostEqual(res["monthly_principal"], 2_500_000.0, places=1)

        # Tháng 1: Gốc 2.5tr + Lãi 30tr * 1.2% (360k) = 2.86tr
        self.assertAlmostEqual(res["first_month_payment"], 2_860_000.0, places=1)
        # Tháng 12: Gốc 2.5tr + Lãi 2.5tr * 1.2% (30k) = 2.53tr
        self.assertAlmostEqual(res["last_month_payment"], 2_530_000.0, places=1)
        # Tổng tiền lãi 12 tháng: 30tr * 1.2% * 13 / 2 = 2.340.000
        self.assertAlmostEqual(res["total_interest"], 2_340_000.0, places=1)

    def test_target_goal_savings(self):
        target = 100_000_000.0
        res = calculate_target_goal_savings(target, term_months=36, rate_annual=6.3)
        self.assertEqual(res["target_amount"], 100_000_000.0)
        # Gửi hàng tháng khoảng 2.52 triệu
        self.assertTrue(2_500_000.0 < res["monthly_deposit"] < 2_600_000.0)
        self.assertTrue(res["earned_interest"] > 8_000_000.0)

    def test_extract_amount(self):
        self.assertEqual(extract_amount_from_text("tôi muốn gửi 50tr trong 1 năm"), 50_000_000.0)
        self.assertEqual(extract_amount_from_text("có 100 triệu nên gửi thế nào"), 100_000_000.0)
        self.assertEqual(extract_amount_from_text("vay 30 củ lãi bao nhiêu"), 30_000_000.0)
        self.assertEqual(extract_amount_from_text("tôi có 1.5 tỷ thì sao"), 1_500_000_000.0)
        self.assertEqual(extract_amount_from_text("500k gửi được không"), 500_000.0)
        self.assertIsNone(extract_amount_from_text("lãi suất bao nhiêu vậy"))

    def test_extract_term(self):
        self.assertEqual(extract_term_years_from_text("tiết kiệm 10 năm"), 10)
        self.assertEqual(extract_term_years_from_text("gửi 3 năm được không"), 3)
        self.assertEqual(extract_term_years_from_text("để vài năm thì lời mấy"), 5)

    def test_comprehensive_financial_analysis(self):
        user_wallet = {"balance": 25_000_000.0, "status": "ACTIVE"}
        q = "tôi có tiền trong tài khoản vậy để tiết kiệm 10 năm hay vài năm thì tự nó tính lãi suất và tự nó tính lãi suất vay luôn"
        analysis = generate_comprehensive_financial_analysis(q, user_wallet=user_wallet)
        self.assertIsNotNone(analysis)
        self.assertEqual(analysis["base_amount"], 25_000_000.0)
        self.assertEqual(analysis["amount_source"], "WALLET_BALANCE")
        self.assertEqual(analysis["term_years"], 10)
        self.assertIn("savings_calc", analysis)
        self.assertIn("loan_calc", analysis)


if __name__ == "__main__":
    unittest.main()
