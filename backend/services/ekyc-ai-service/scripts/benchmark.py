#!/usr/bin/env python3
"""Benchmark ONNX Runtime trên GTX 1650 — khử rủi ro GPU ngay Giai đoạn 1.

Đo:
  - Latency SCRFD detect + ArcFace embed (CUDA vs CPU), p50/p95 trên N vòng
  - VRAM tiêu thụ (nvidia-smi) và provider thực tế
Chạy:  .venv/bin/python scripts/benchmark.py [--rounds 30] [--cpu]
"""
from __future__ import annotations

import argparse
import statistics
import subprocess
import sys
import time
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

import cv2
import numpy as np

from app.config import model_paths
from app.services.face_pipeline import FacePipeline


def gpu_memory_mib() -> float:
    try:
        out = subprocess.run(
            ["nvidia-smi", "--query-gpu=memory.used", "--format=csv,noheader,nounits"],
            capture_output=True, text=True, timeout=5,
        )
        return float(out.stdout.strip().splitlines()[0])
    except Exception:
        return -1.0


def make_test_image(seed: int = 7) -> np.ndarray:
    """Ảnh test 1080p — nội dung không quan trọng cho benchmark tốc độ
    (SCRFD chạy full graph bất kể có mặt hay không)."""
    rng = np.random.default_rng(seed)
    img = rng.integers(0, 255, (1080, 1920, 3), dtype=np.uint8)
    # Vẽ 1 "khuôn mặt" hình học để pipeline chạy trọn đường có detect
    cv2.ellipse(img, (960, 540), (160, 220), 0, 0, 360, (220, 200, 180), -1)
    for dx in (-60, 60):
        cv2.circle(img, (960 + dx, 480), 18, (40, 40, 40), -1)
    return img


def bench(pipeline: FacePipeline, img: np.ndarray, rounds: int) -> dict:
    det_ms, emb_ms, liv_ms = [], [], []
    faces = pipeline.detect(img)
    face = faces[0] if faces else None
    for _ in range(rounds):
        t0 = time.perf_counter()
        pipeline.detect(img)
        det_ms.append((time.perf_counter() - t0) * 1000)
        if face is not None:
            t1 = time.perf_counter()
            pipeline.embed(img, face)
            emb_ms.append((time.perf_counter() - t1) * 1000)
            t2 = time.perf_counter()
            pipeline.detect_liveness(img, face)
            liv_ms.append((time.perf_counter() - t2) * 1000)

    def stats(arr):
        if not arr:
            return {"p50": 0, "p95": 0, "mean": 0}
        arr.sort()
        return {
            "p50": round(statistics.median(arr), 2),
            "p95": round(arr[max(0, int(len(arr) * 0.95) - 1)], 2),
            "mean": round(statistics.mean(arr), 2),
        }

    total_times = []
    if emb_ms and liv_ms:
        total_times = [d + e + l for d, e, l in zip(det_ms, emb_ms, liv_ms)]
    elif emb_ms:
        total_times = [d + e for d, e in zip(det_ms, emb_ms)]
    else:
        total_times = det_ms

    return {
        "detect": stats(det_ms),
        "embed": stats(emb_ms),
        "liveness": stats(liv_ms),
        "faces_detected": len(faces),
        "total_pipeline": stats(total_times),
    }


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--rounds", type=int, default=30)
    args = parser.parse_args()

    det, rec, liv = model_paths()
    print(f"Models: {det.name} ({det.stat().st_size // 1024 // 1024}MB) + {rec.name} ({rec.stat().st_size // 1024 // 1024}MB) + {liv.name} ({liv.stat().st_size // 1024 // 1024}MB)")
    img = make_test_image()

    for label, providers in [
        ("CUDA (GTX 1650)", ["CUDAExecutionProvider", "CPUExecutionProvider"]),
        ("CPU", ["CPUExecutionProvider"]),
    ]:
        print(f"\n=== {label} ===")
        try:
            pipeline = FacePipeline(providers=providers)
        except Exception as exc:  # noqa: BLE001
            print(f"  Không nạp được: {exc}")
            continue
        print(f"  Provider thực tế : {pipeline.provider_used}")
        print(f"  VRAM trước       : {gpu_memory_mib():.0f} MiB")
        r = bench(pipeline, img, args.rounds)
        print(f"  Detect   (640px) : {r['detect']}")
        print(f"  Embed    (112px) : {r['embed']}")
        print(f"  Liveness (80px)  : {r['liveness']}")
        print(f"  Pipeline tổng    : {r['total_pipeline']}")
        print(f"  VRAM sau         : {gpu_memory_mib():.0f} MiB")
        if label.startswith("CUDA") and "CUDA" not in pipeline.provider_used:
            print("  ⚠️  CUDA ExecutionProvider KHÔNG hoạt động — đã rơi về CPU, kiểm tra driver/CUDA!")


if __name__ == "__main__":
    main()
