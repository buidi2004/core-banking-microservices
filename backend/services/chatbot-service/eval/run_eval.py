"""
Bộ Đánh Giá RAG Trên Golden Questions (Evaluation Harness — thuần retrieval, KHÔNG gọi LLM)

Đo lường trên eval/golden_questions.json:
- Recall@K   : tỉ lệ câu hỏi có ≥1 file mong đợi xuất hiện trong top-K parent documents
- MRR        : Mean Reciprocal Rank (xếp hạng của file đúng đầu tiên)
- Domain route accuracy: detect_query_topic() đoán đúng domain vàng của câu hỏi
- No-info FP : với câu adversarial (expect_no_info), tỉ lệ mà retrieval vẫn trả kết quả
              (false positive — retrieval không đủ "chắt lọc" để từ chối)

So sánh: domain-filter ON (production) vs OFF (baseline), tùy chọn --domain on|off|both.
Nếu bật RERANK_ENABLED=true, thêm bảng so sánh thứ hạng trước/sau rerank.

Chạy trong container (cần DB + model):
    docker compose exec chatbot-service python eval/run_eval.py
    docker compose exec chatbot-service python eval/run_eval.py --k 4 --domain both --json eval/results.json
"""

import argparse
import json
import statistics
import sys
import time
from pathlib import Path

EVAL_DIR = Path(__file__).resolve().parent
SERVICE_ROOT = EVAL_DIR.parent
if str(SERVICE_ROOT) not in sys.path:
    sys.path.insert(0, str(SERVICE_ROOT))

from app.vietnamese_nlp import detect_query_topic, normalize_vietnamese_query  # noqa: E402
from app.config import settings as rag_engine_settings  # noqa: E402

GENERAL_DOMAIN = "GENERAL_ACCOUNT"


def load_golden(path: Path) -> list:
    with open(path, encoding="utf-8") as f:
        data = json.load(f)
    questions = data.get("questions", [])
    if not questions:
        raise SystemExit(f"Golden set rỗng: {path}")
    return questions


def evaluate_mode(
    rag_engine,
    model,
    golden: list,
    k: int,
    use_domain_filter: bool,
    candidate_limit: int,
    apply_threshold: bool = False,
    apply_rerank: bool = False
) -> dict:
    """Chạy 1 lượt đánh giá với cấu hình domain-filter/ngưỡng/rerank cố định."""
    recall_items = []
    mrr_items = []
    latencies = []
    domain_total = 0
    domain_correct = 0
    noinfo_total = 0
    noinfo_fp = 0
    per_domain = {}
    empty_results = 0
    threshold_rejects = 0

    for item in golden:
        question = normalize_vietnamese_query(item["question"])
        vec = model.encode(f"query: {question}", normalize_embeddings=True).tolist()
        detected = detect_query_topic(question)

        # Production: chỉ lọc khi detect ra domain cụ thể (khác GENERAL_ACCOUNT)
        domain = detected if (use_domain_filter and detected != GENERAL_DOMAIN) else None

        start = time.time()
        rows = rag_engine._search_parent_rows(question, vec, candidate_limit=candidate_limit, domain=domain)

        # Mô phỏng ngưỡng MAX_DISTANCE của production (_hybrid_search_rrf)
        if apply_threshold and rows:
            best_dist = rows[0].get("best_vec_distance")
            if best_dist is not None and best_dist > rag_engine_settings.MAX_DISTANCE:
                rows = []

        # Mô phỏng rerank cross-encoder của production (nếu bật)
        if apply_rerank and rows and getattr(rag_engine_settings, "RERANK_ENABLED", False):
            rows = rag_engine._rerank_parent_rows(question, rows)

        if apply_threshold and not rows and rag_engine._search_parent_rows(
            question, vec, candidate_limit=candidate_limit, domain=domain
        ):
            threshold_rejects += 1
        latencies.append((time.time() - start) * 1000)

        top_files = [r["source_file"] for r in rows[:k]]
        expected = item.get("expected_source_files") or []
        expected_domain = item.get("expected_domain", GENERAL_DOMAIN)

        # Độ chính xác định tuyến domain của detect_query_topic (không phụ thuộc filter)
        domain_total += 1
        if detected == expected_domain:
            domain_correct += 1

        d_stat = per_domain.setdefault(expected_domain, {"n": 0, "hit": 0})
        d_stat["n"] += 1

        if item.get("expect_no_info"):
            noinfo_total += 1
            if top_files:
                noinfo_fp += 1
            continue

        if not top_files:
            empty_results += 1
            recall_items.append(0.0)
            mrr_items.append(0.0)
            continue

        hits = [f for f in top_files if f in expected]
        recall = len(set(hits)) / len(set(expected)) if expected else 0.0
        recall_items.append(recall)

        first_rank = 0
        for rank, fname in enumerate(top_files, start=1):
            if fname in expected:
                first_rank = rank
                break
        mrr_items.append(1.0 / first_rank if first_rank else 0.0)

        if first_rank:
            d_stat["hit"] += 1

    def _mean(values):
        return round(statistics.mean(values), 4) if values else 0.0

    return {
        "mode": "domain_on" if use_domain_filter else "domain_off",
        "k": k,
        "recall_at_k": _mean(recall_items),
        "hit_rate_at_k": _mean([1.0 if r > 0 else 0.0 for r in recall_items]),
        "mrr": _mean(mrr_items),
        "avg_latency_ms": round(statistics.mean(latencies), 1) if latencies else 0.0,
        "p95_latency_ms": round(sorted(latencies)[int(len(latencies) * 0.95) - 1], 1) if len(latencies) >= 20 else 0.0,
        "domain_route_accuracy": round(domain_correct / domain_total, 4) if domain_total else 0.0,
        "no_info_false_positive_rate": round(noinfo_fp / noinfo_total, 4) if noinfo_total else 0.0,
        "empty_results": empty_results,
        "threshold_rejects": threshold_rejects,
        "per_domain_hit_rate": {
            d: {"n": s["n"], "hit_rate": round(s["hit"] / s["n"], 4)}
            for d, s in sorted(per_domain.items())
        },
    }


def main():
    parser = argparse.ArgumentParser(description="Đánh giá RAG trên golden questions (thuần retrieval)")
    parser.add_argument("--k", type=int, default=4, help="K cho Recall@K (mặc định 4 = settings.TOP_K)")
    parser.add_argument("--domain", choices=["on", "off", "both"], default="both",
                        help="So sánh domain filter on/off (mặc định both)")
    parser.add_argument("--candidates", type=int, default=20, help="Số ứng viên parent tối đa cho mỗi câu")
    parser.add_argument("--threshold", choices=["on", "off"], default="on",
                        help="Mô phỏng ngưỡng MAX_DISTANCE của production (mặc định on)")
    parser.add_argument("--rerank", action="store_true",
                        help="Mô phỏng rerank cross-encoder (chỉ chạy khi RERANK_ENABLED=true)")
    parser.add_argument("--limit", type=int, default=0, help="Chạy N câu đầu tiên (0 = toàn bộ, để debug nhanh)")
    parser.add_argument("--json", dest="json_path", default="", help="Ghi kết quả ra file JSON")
    args = parser.parse_args()

    from app.rag_engine import rag_engine  # noqa: E402  (import sau sys.path)

    golden = load_golden(EVAL_DIR / "golden_questions.json")
    if args.limit > 0:
        golden = golden[: args.limit]

    model = rag_engine._get_embed_model()
    print(f"Golden set: {len(golden)} câu | K={args.k} | candidates={args.candidates}")
    print(f"RERANK_ENABLED={getattr(__import__('app.config', fromlist=['settings']).settings, 'RERANK_ENABLED', False)}\n")

    apply_threshold = args.threshold == "on"
    modes = {"on": True, "off": False} if args.domain == "both" else {"on": True} if args.domain == "on" else {"off": False}
    results = []
    for use_filter in modes.values():
        suffix = f" | threshold={'ON' if apply_threshold else 'OFF'} | rerank={'ON' if args.rerank else 'OFF'}"
        print(f"--- Đang chạy mode domain_filter={'ON' if use_filter else 'OFF'}{suffix} ---")
        res = evaluate_mode(
            rag_engine, model, golden, args.k, use_filter, args.candidates,
            apply_threshold=apply_threshold, apply_rerank=args.rerank
        )
        results.append(res)

    for res in results:
        print(f"\n===== KẾT QUẢ [{res['mode']}] =====")
        print(f"Recall@{res['k']}            : {res['recall_at_k']:.2%}")
        print(f"Hit rate@{res['k']}          : {res['hit_rate_at_k']:.2%}")
        print(f"MRR          : {res['mrr']:.4f}")
        print(f"Latency tb/p95: {res['avg_latency_ms']}ms / {res['p95_latency_ms']}ms")
        print(f"Domain route accuracy: {res['domain_route_accuracy']:.2%}")
        print(f"No-info FP rate (càng thấp càng tốt): {res['no_info_false_positive_rate']:.2%}")
        print(f"Số câu trả rỗng (không retrieval): {res['empty_results']} | Bị ngưỡng MAX_DISTANCE chặn: {res['threshold_rejects']}")
        print("Hit rate theo domain:")
        for d, s in res["per_domain_hit_rate"].items():
            print(f"  - {d:22s} {s['hit_rate']:6.2%} ({s['n']} câu)")

    if len(results) == 2:
        delta = results[0]["recall_at_k"] - results[1]["recall_at_k"]
        direction = "TĂNG" if delta > 0 else ("GIẢM" if delta < 0 else "KHÔNG ĐỔI")
        print(f"\n>>> Domain filter làm Recall@{args.k} {direction}: {delta:+.2%}")

    if args.json_path:
        out = Path(args.json_path)
        out.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")
        print(f"\nĐã ghi kết quả: {out}")


if __name__ == "__main__":
    main()
