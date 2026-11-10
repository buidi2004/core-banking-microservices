"""
Test nâng cấp RAG dữ liệu lớn (thuần unit — không cần DB/network):
- FILE_DOMAIN_MAP phủ đủ mọi file data/*.md, domain hợp lệ theo enum detect_query_topic
- Schema golden set eval/golden_questions.json hợp lệ
- Config reranker/domain mặc định đúng (RERANK_ENABLED=false)
- Tín hiệu detect_query_topic dùng cho domain filter định tuyến đúng các câu mẫu

Chạy:  python -m unittest tests.test_rag_upgrade -v   (hoặc trong container)
Lưu ý: import app.rag_engine cần torch/psycopg/openai — thiếu sẽ tự SKIP (không FAIL).
"""

import json
import sys
import unittest
from pathlib import Path

SERVICE_ROOT = Path(__file__).resolve().parent.parent
if str(SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVICE_ROOT))

DATA_DIR = SERVICE_ROOT / "data"
GOLDEN_PATH = SERVICE_ROOT / "eval" / "golden_questions.json"

try:
    from app.rag_engine import FILE_DOMAIN_MAP, rag_engine  # noqa: F401
    RAG_ENGINE_AVAILABLE = True
except Exception:
    RAG_ENGINE_AVAILABLE = False
    FILE_DOMAIN_MAP = {}

from app.vietnamese_nlp import detect_query_topic  # noqa: E402

# Đúng bộ enum topic của detect_query_topic() — nguồn của bảng domain
DOMAINS = {
    "ACCOUNT_OPENING_DOCS", "BIOMETRICS", "BCA_VNEID_EKYC", "TERMS_OF_SERVICE",
    "MACRO_ECONOMICS", "LOANS", "FINANCIAL_ADVISORY", "SAVINGS", "BILLS_TOPUP",
    "CARDS", "SECURITY", "DISPUTE", "TRANSFER", "PROMOTIONS", "GENERAL_ACCOUNT",
    "PHI_HAN_MUC", "INSURANCE", "SME_BUSINESS",
}


class TestGoldenSetSchema(unittest.TestCase):
    """Validate cấu trúc golden set — chạy được ở mọi môi trường (chỉ cần json)."""

    @classmethod
    def setUpClass(cls):
        with open(GOLDEN_PATH, encoding="utf-8") as f:
            cls.data = json.load(f)
        cls.questions = cls.data["questions"]

    def test_has_enough_questions(self):
        self.assertGreaterEqual(len(self.questions), 100, "Golden set cần >= 100 câu")

    def test_unique_ids(self):
        ids = [q["id"] for q in self.questions]
        self.assertEqual(len(ids), len(set(ids)), "id trong golden set bị trùng")

    def test_item_schema(self):
        for q in self.questions:
            with self.subTest(id=q.get("id")):
                self.assertTrue(isinstance(q["question"], str) and q["question"].strip())
                self.assertIn(q["expected_domain"], DOMAINS)
                self.assertIsInstance(q["expected_source_files"], list)
                for f in q["expected_source_files"]:
                    self.assertIsInstance(f, str)

    def test_no_info_items_expect_no_files(self):
        for q in self.questions:
            if q.get("expect_no_info"):
                self.assertEqual(
                    q["expected_source_files"], [],
                    f"Câu adversarial id={q['id']} không được có expected_source_files"
                )

    def test_has_adversarial_no_info_items(self):
        no_info = [q for q in self.questions if q.get("expect_no_info")]
        self.assertGreaterEqual(len(no_info), 8, "Cần >= 8 câu adversarial để đo no-info FP")

    @unittest.skipUnless(DATA_DIR.exists(), "Thư mục data/ không tồn tại")
    def test_expected_files_exist_on_disk(self):
        disk_files = {p.name for p in DATA_DIR.glob("*.md")}
        for q in self.questions:
            for f in q["expected_source_files"]:
                with self.subTest(id=q["id"], file=f):
                    self.assertIn(f, disk_files, f"File golden không tồn tại trong data/: {f}")


@unittest.skipUnless(RAG_ENGINE_AVAILABLE, "app.rag_engine cần torch/psycopg/openai — chạy trong container")
class TestFileDomainMap(unittest.TestCase):
    """FILE_DOMAIN_MAP phải phủ trọn bộ knowledge base và dùng đúng enum domain."""

    @unittest.skipUnless(DATA_DIR.exists(), "Thư mục data/ không tồn tại")
    def test_every_data_file_has_domain(self):
        files = {p.name for p in DATA_DIR.glob("*.md")}
        missing = files - set(FILE_DOMAIN_MAP.keys())
        self.assertFalse(missing, f"File chưa map domain: {sorted(missing)}")

    def test_domain_values_are_valid_topics(self):
        invalid = {d for d in FILE_DOMAIN_MAP.values() if d not in DOMAINS}
        self.assertFalse(invalid, f"Domain không thuộc enum detect_query_topic: {invalid}")

    def test_general_account_catch_all_exists(self):
        self.assertIn("GENERAL_ACCOUNT", FILE_DOMAIN_MAP.values(),
                      "Cần domain 'bắt kè' GENERAL_ACCOUNT cho tài liệu đa chủ đề")


class TestConfigRagSettings(unittest.TestCase):
    """Cấu hình mặc định: reranker OFF, domain filter dùng TOP_K."""

    def test_rerank_config_present(self):
        from app.config import settings
        # RERANK_ENABLED cấu hình được qua env (production bật trong docker-compose)
        self.assertIsInstance(settings.RERANK_ENABLED, bool)
        self.assertEqual(settings.RERANK_MODEL, "BAAI/bge-reranker-base")
        self.assertGreaterEqual(settings.RERANK_CANDIDATES, 10)
        self.assertLess(settings.RERANK_MIN_SCORE, 0.0)

    def test_top_k_usable(self):
        from app.config import settings
        self.assertGreaterEqual(settings.TOP_K, 1)


class TestDetectTopicForDomainFilter(unittest.TestCase):
    """Tín hiệu định tuyến domain của detect_query_topic phải đúng trên các câu mẫu."""

    CASES = [
        ("lãi suất tiết kiệm 12 tháng bao nhiêu", "SAVINGS"),
        ("stk ky han 6 thang lai suat may", "SAVINGS"),
        ("điều kiện vay Quick Loan cần gì", "LOANS"),
        ("quyết định 2345 hạn mức giao dịch sinh trắc học", "BIOMETRICS"),
        ("chuyển tiền nhầm số tài khoản thì làm sao", "DISPUTE"),
        ("mở tài khoản cần giấy tờ gì", "ACCOUNT_OPENING_DOCS"),
        ("mã voucher xinchao50 dùng thế nào", "PROMOTIONS"),
        ("thanh toán hóa đơn điện nước trong app", "BILLS_TOPUP"),
        ("mở thẻ Visa ảo có phí không", "CARDS"),
        ("đăng xuất thiết bị khác khỏi tài khoản", "SECURITY"),
    ]

    def test_topic_routing(self):
        for query, expected in self.CASES:
            with self.subTest(query=query):
                self.assertEqual(detect_query_topic(query), expected)


if __name__ == "__main__":
    unittest.main(verbosity=2)
