"""
Test bảo vệ SSOT lãi suất (Single Source of Truth):
- Parse biểu lãi suất từ data/lai_suat_tiet_kiem.md (nguồn RAG) và assert khớp app/rate_config.py
  → nếu file kiến thức đổi mà quên cập nhật rate_config, test sẽ đỏ ngay (và ngược lại).
- Kiểm tra helper get_savings_rate() và rate_table_text().

Chạy: python -m unittest tests.test_rate_config -v  (thuần, không cần DB)
"""

import re
import sys
import unittest
from pathlib import Path

SERVICE_ROOT = Path(__file__).resolve().parent.parent
if str(SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVICE_ROOT))

from app import rate_config  # noqa: E402

DATA_DIR = SERVICE_ROOT / "data"
SAVINGS_FILE = DATA_DIR / "lai_suat_tiet_kiem.md"
LOAN_FILE = DATA_DIR / "04_vay_tieu_dung_quick_loan.md"


class TestRateConfigSSOT(unittest.TestCase):
    """rate_config.py PHẢI khớp với biểu lãi suất trong file kiến thức RAG."""

    @unittest.skipUnless(SAVINGS_FILE.exists(), "Thiếu data/lai_suat_tiet_kiem.md")
    def test_savings_rates_match_knowledge_file(self):
        content = SAVINGS_FILE.read_text(encoding="utf-8")
        # Dạng 1: "- Kỳ hạn 12 tháng: 5.6%/năm."
        single = re.findall(r"Kỳ hạn\s+(\d+)\s+tháng:\s*([\d.]+)\s*%/năm", content)
        # Dạng 2: "- Kỳ hạn 24 tháng và 36 tháng: 6.0%/năm."
        combined = re.findall(
            r"Kỳ hạn\s+(\d+)\s+tháng\s+và\s+(\d+)\s+tháng:\s*([\d.]+)\s*%/năm", content
        )
        parsed: dict = {}
        for term, rate in single:
            parsed[int(term)] = float(rate)
        for t1, t2, rate in combined:
            parsed[int(t1)] = float(rate)
            parsed[int(t2)] = float(rate)

        self.assertGreaterEqual(len(parsed), 6, f"Parse được ít kỳ hạn: {parsed}")
        for term, rate in parsed.items():
            self.assertIn(term, rate_config.SAVINGS_RATES,
                          f"Kỳ hạn {term} tháng có trong file kiến thức nhưng thiếu trong rate_config.SAVINGS_RATES")
            self.assertEqual(
                rate_config.SAVINGS_RATES[term], rate,
                f"LỆCH SSOT: kỳ hạn {term} tháng — file kiến thức {rate}%/năm vs rate_config "
                f"{rate_config.SAVINGS_RATES[term]}%/năm. Hãy cập nhật app/rate_config.py hoặc file .md."
            )

    @unittest.skipUnless(SAVINGS_FILE.exists(), "Thiếu data/lai_suat_tiet_kiem.md")
    def test_casa_rate_matches_knowledge_file(self):
        content = SAVINGS_FILE.read_text(encoding="utf-8")
        m = re.search(r"không kỳ hạn là\s*([\d.]+)\s*%/năm", content)
        self.assertIsNotNone(m, "Không tìm thấy dòng lãi suất CASA trong file kiến thức")
        self.assertEqual(rate_config.CASA_RATE, float(m.group(1)))

    @unittest.skipUnless(LOAN_FILE.exists(), "Thiếu data/04_vay_tieu_dung_quick_loan.md")
    def test_loan_rate_matches_knowledge_file(self):
        content = LOAN_FILE.read_text(encoding="utf-8")
        m = re.search(r"([\d.]+)\s*%\s*-\s*([\d.]+)\s*%/tháng", content)
        self.assertIsNotNone(m, "Không tìm thấy khoảng lãi suất vay trong file kiến thức")
        self.assertEqual(rate_config.LOAN_RATE_MIN_MONTHLY, float(m.group(1)))
        self.assertEqual(rate_config.LOAN_RATE_MAX_MONTHLY, float(m.group(2)))
        self.assertEqual(rate_config.DEFAULT_LOAN_MONTHLY_RATE, rate_config.LOAN_RATE_MIN_MONTHLY)


class TestRateConfigHelpers(unittest.TestCase):
    def test_get_savings_rate_exact_and_nearest(self):
        self.assertEqual(rate_config.get_savings_rate(12), 5.6)
        self.assertEqual(rate_config.get_savings_rate(24), 6.0)
        # Kỳ hạn lạ → trả kỳ hạn gần nhất trong biểu
        self.assertEqual(rate_config.get_savings_rate(15), rate_config.SAVINGS_RATES[12])

    def test_rate_table_text_contains_all_terms(self):
        table = rate_config.rate_table_text()
        for term in (1, 3, 6, 12, 24):
            self.assertIn(f"kỳ hạn {term} tháng", table)
        self.assertIn(
            f"{rate_config.LOAN_RATE_MIN_MONTHLY:g}% - {rate_config.LOAN_RATE_MAX_MONTHLY:g}%/tháng", table
        )
        self.assertIn(str(rate_config.SAVINGS_RATES[12]), table)

    def test_rates_are_monotonic_non_decreasing_with_term(self):
        terms = sorted(k for k in rate_config.SAVINGS_RATES if k > 0)
        for a, b in zip(terms, terms[1:]):
            self.assertLessEqual(rate_config.SAVINGS_RATES[a], rate_config.SAVINGS_RATES[b],
                                 f"Biểu lãi suất giảm tại kỳ hạn {b} tháng — kiểm tra lại rate_config")


if __name__ == "__main__":
    unittest.main(verbosity=2)
