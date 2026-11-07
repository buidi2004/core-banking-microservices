#!/usr/bin/env python3
"""Sinh cặp khóa RSA-OAEP cho môi trường dev (chạy 1 lần).

  python scripts/gen_keys.py
→ certs/ekyc_private.pem (server giữ, gitignore) + certs/ekyc_public.pem (đóng gói vào SDK).
"""
import sys
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))
from app.core.crypto import generate_key_pair  # noqa: E402
from app.config import RSA_PRIVATE_KEY_PATH, RSA_PUBLIC_KEY_PATH  # noqa: E402

if __name__ == "__main__":
    RSA_PRIVATE_KEY_PATH.parent.mkdir(parents=True, exist_ok=True)
    generate_key_pair(RSA_PRIVATE_KEY_PATH, RSA_PUBLIC_KEY_PATH)
    print(f"Đã sinh: {RSA_PRIVATE_KEY_PATH} + {RSA_PUBLIC_KEY_PATH}")
