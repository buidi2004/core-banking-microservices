"""Điểm vào ekyc-ai-service — FastAPI + Uvicorn.

Chạy dev:  .venv/bin/uvicorn app.main:app --port 8900
Docker:    xem Dockerfile (Uvicorn worker, model warm-up lúc start).
"""
from __future__ import annotations

import logging
import time
import sys

from fastapi import FastAPI

from .api.routes import init_state, router
from .config import (
    LOG_LEVEL,
    RSA_PRIVATE_KEY_PATH,
    SERVICE_PORT,
    model_paths,
)
from .core.session_store import SessionStore
from .services.face_pipeline import FacePipeline

logging.basicConfig(
    level=LOG_LEVEL,
    format="%(asctime)s %(levelname)s [%(name)s] %(message)s",
    stream=sys.stdout,
)
logger = logging.getLogger("ekyc.main")

app = FastAPI(
    title="Sen Hồng eKYC AI Service",
    version="0.1.0",
    description="Anti-spoofing & Face Matching microservice — chuẩn ngân hàng, ONNX Runtime GPU (GTX 1650).",
)

pipeline_holder: dict[str, object] = {}


@app.on_event("startup")
def startup() -> None:
    det, rec, liv = model_paths()
    logger.info("Warm-up models: %s | %s | %s", det.name, rec.name, liv.name)
    pipeline = FacePipeline()  # providers từ config (CUDA ưu tiên)
    store = SessionStore()

    # Warm-up CUDA kernels để request đầu tiên không chịu cold-start ~700ms
    import numpy as np

    dummy = np.zeros((640, 640, 3), dtype=np.uint8)
    t0 = time.perf_counter()
    pipeline.analyze(dummy)
    logger.info("Warm-up CUDA hoàn tất trong %.0f ms", (time.perf_counter() - t0) * 1000)

    from .config import ONNX_PROVIDERS

    logger.info("Provider đã nạp: %s | Redis: %s", pipeline.provider_used, store.redis_backed)
    pipeline_holder["pipeline"] = pipeline
    pipeline_holder["store"] = store
    init_state(store, pipeline, RSA_PRIVATE_KEY_PATH)


app.include_router(router)


if __name__ == "__main__":
    import uvicorn

    uvicorn.run(app, host="0.0.0.0", port=SERVICE_PORT)
