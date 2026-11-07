"""Bộ ghi nhận chỉ số vận hành eKYC (Giai đoạn 5 — Giám sát log).

Ring buffer in-memory (mặc định 2000 lần verify gần nhất) phục vụ:
  - Độ trễ xử lý p50/p95 (SLA < 1.5s/request)
  - Histogram quyết định (APPROVED / MANUAL_REVIEW / REJECTED)
  - Điểm Liveness & độ khớp trung bình → tinh chỉnh ngưỡng thực tế
Đơn giản, không phụ thuộc Prometheus — đủ cho dashboard nội bộ tuần 8.
"""
from __future__ import annotations

import threading
import time
from collections import deque
from dataclasses import dataclass, field
from typing import Literal


@dataclass
class VerifyRecord:
    ts: float
    decision: str
    latency_ms: int
    similarity: float | None
    liveness_score: float | None
    error_code: str | None
    auto_approved: bool


@dataclass
class MetricsWindow:
    total: int = 0
    approved: int = 0
    manual_review: int = 0
    rejected: int = 0
    auto_approved: int = 0
    latencies: list[int] = field(default_factory=list)
    similarities: list[float] = field(default_factory=list)
    liveness_scores: list[float] = field(default_factory=list)
    error_codes: dict = field(default_factory=dict)


class EkycMetricsRecorder:
    def __init__(self, window: int = 2000) -> None:
        self._records: deque[VerifyRecord] = deque(maxlen=window)
        self._lock = threading.Lock()
        self._started_at = time.time()

    def record_verify(
        self,
        decision: Literal["APPROVED", "MANUAL_REVIEW", "REJECTED"],
        latency_ms: int,
        similarity: float | None,
        liveness_score: float | None,
        error_code: str | None,
        auto_approved: bool,
    ) -> None:
        rec = VerifyRecord(
            ts=time.time(),
            decision=decision,
            latency_ms=latency_ms,
            similarity=similarity,
            liveness_score=liveness_score,
            error_code=error_code,
            auto_approved=auto_approved,
        )
        with self._lock:
            self._records.append(rec)

    def snapshot(self) -> dict:
        with self._lock:
            records = list(self._records)
        w = MetricsWindow()
        for r in records:
            w.total += 1
            if r.decision == "APPROVED":
                w.approved += 1
            elif r.decision == "MANUAL_REVIEW":
                w.manual_review += 1
            else:
                w.rejected += 1
            if r.auto_approved:
                w.auto_approved += 1
            w.latencies.append(r.latency_ms)
            if r.similarity is not None:
                w.similarities.append(r.similarity)
            if r.liveness_score is not None:
                w.liveness_scores.append(r.liveness_score)
            if r.error_code:
                w.error_codes[r.error_code] = w.error_codes.get(r.error_code, 0) + 1

        def pct(arr: list, p: float):
            if not arr:
                return None
            arr = sorted(arr)
            return round(arr[max(0, int(len(arr) * p) - 1)], 3)

        return {
            "windowSize": len(records),
            "uptimeSeconds": int(time.time() - self._started_at),
            "decisions": {
                "approved": w.approved,
                "manualReview": w.manual_review,
                "rejected": w.rejected,
                "autoApproved": w.auto_approved,
            },
            "latencyMs": {
                "p50": pct(w.latencies, 0.50),
                "p95": pct(w.latencies, 0.95),
                "max": max(w.latencies) if w.latencies else None,
                "slaTargetMs": 1500,
                "slaBreaches": sum(1 for x in w.latencies if x > 1500),
            },
            "biometrics": {
                "avgSimilarity": round(sum(w.similarities) / len(w.similarities), 4) if w.similarities else None,
                "avgLivenessScore": round(sum(w.liveness_scores) / len(w.liveness_scores), 4) if w.liveness_scores else None,
            },
            "errorCodes": w.error_codes,
        }

    def reset(self) -> None:
        with self._lock:
            self._records.clear()
            self._started_at = time.time()
