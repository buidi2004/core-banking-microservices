"""
Test hệ thống gợi ý câu hỏi (Quick Replies) — thuần, không cần DB/LLM:
- Journey stages phủ đủ domain mới (PHI_HAN_MUC / INSURANCE / SME_BUSINESS)
- enrich_smart_quick_replies: không gợi ý lặp câu vừa hỏi, chuẩn hóa viết hoa,
  bổ sung gợi ý chuyên sâu theo domain khi LLM trả thiếu
"""

import sys
import unittest
from pathlib import Path

SERVICE_ROOT = Path(__file__).resolve().parent.parent
if str(SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVICE_ROOT))

from app.vietnamese_nlp import (  # noqa: E402
    CONTEXTUAL_JOURNEY_STAGES,
    CURATED_SUGGESTIONS_BY_TOPIC,
    enrich_smart_quick_replies,
    detect_query_topic,
)


class TestJourneyCoverage(unittest.TestCase):

    def test_journey_covers_new_domains(self):
        for topic in ("PHI_HAN_MUC", "INSURANCE", "SME_BUSINESS"):
            self.assertIn(topic, CONTEXTUAL_JOURNEY_STAGES,
                          f"Domain {topic} thiếu journey stages cho multi-turn suggestions")
            self.assertGreaterEqual(len(CONTEXTUAL_JOURNEY_STAGES[topic]), 2)

    def test_every_topic_has_curated_fallback(self):
        # detect_query_topic trả về topic nào thì curated phải có key đó (tránh rơi về GENERAL)
        detected = {detect_query_topic(q) for q in [
            "lãi suất tiết kiệm", "mở thẻ visa", "phí chuyển tiền napas",
            "bảo hiểm nhân thọ", "chi trả lương doanh nghiệp", "quyết định 2345",
            "tra soát giao dịch", "voucher xinchao50", "kinh tế vĩ mô"
        ]}
        missing = detected - set(CURATED_SUGGESTIONS_BY_TOPIC.keys())
        self.assertFalse(missing, f"Topic {missing} chưa có curated suggestions")


class TestEnrichQuickReplies(unittest.TestCase):

    def test_caps_at_max_items(self):
        out = enrich_smart_quick_replies("lãi suất tiết kiệm", [], max_items=3)
        self.assertEqual(len(out), 3)

    def test_does_not_repeat_the_question(self):
        out = enrich_smart_quick_replies("lãi suất tiết kiệm 12 tháng", [], max_items=3)
        for s in out:
            self.assertNotIn("12 tháng", s.lower(),
                             f"Gợi ý lặp lại chính câu hỏi: {s}")

    def test_dedupes_raw_replies(self):
        out = enrich_smart_quick_replies(
            "mở thẻ visa ảo",
            ["Mở thẻ Visa ảo", "mở thẻ visa ảo ", "Biểu phí thẻ"],
            max_items=3
        )
        lowered = [s.lower() for s in out]
        self.assertEqual(len(lowered), len(set(lowered)), f"Gợi ý bị trùng: {out}")
        self.assertEqual(len(out), 3)

    def test_capitalizes_first_letter(self):
        out = enrich_smart_quick_replies("chuyển tiền napas", ["hạn mức chuyển tiền"], max_items=3)
        self.assertTrue(out[0][0].isupper(), f"Gợi ý không viết hoa đầu câu: {out[0]}")

    def test_multiturn_avoids_covered_stages(self):
        # Lượt trước đã hỏi thủ tục vay → lượt này không gợi ý lại thủ tục
        history = [
            {"role": "user", "content": "điều kiện và thủ tục vay Quick Loan cần gì"},
            {"role": "assistant", "content": "Dạ điều kiện vay là... Quý khách bấm chọn gợi ý bên dưới nhé ạ!"},
        ]
        out = enrich_smart_quick_replies("lãi suất vay bao nhiêu", [], max_items=3, history=history)
        self.assertTrue(out)
        for s in out:
            self.assertNotIn("thủ tục", s.lower())

    def test_no_diacritic_question_still_gets_domain_suggestions(self):
        out = enrich_smart_quick_replies("phi chuyen tien napas", [], max_items=3)
        self.assertEqual(len(out), 3)
        self.assertTrue(any("chuyển" in s.lower() or "napas" in s.lower() for s in out))


if __name__ == "__main__":
    unittest.main(verbosity=2)
