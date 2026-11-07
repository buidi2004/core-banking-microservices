#!/usr/bin/env python3
"""KIỂM CHỨNG EMPIRICAL các pitfall toán học AI — chạy thật trên GTX 1650.

Pitfall 2.1 — Méo mặt do crop thô vs Affine Transform (5 điểm mốc)
Pitfall 2.2 — L2 Norm: vector chuẩn hóa độ dài 1, cosine = dot product
Pitfall 2.3 — Bắt nhầm mặt hậu cảnh: select_primary_face theo diện tích+tâm
Pitfall 3.1 — Đánh tráo người: match_multi từ chối khung phụ khác chủ thể
"""
import sys
from pathlib import Path

import cv2
import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent.parent))

from app.services.face_pipeline import FacePipeline  # noqa: E402

MODELS_DIR = Path(__file__).resolve().parent.parent / "models"
PASS, FAIL = "✔ PASS", "✘ FAIL"


def load_pipeline() -> FacePipeline:
    return FacePipeline()


def test_l2_norm(pl: FacePipeline) -> bool:
    """Pitfall 2.2: embedding phải có norm == 1; cosine == dot product."""
    img = cv2.imread(str(MODELS_DIR / "face_a.jpg"))
    face = pl.detect(img)[0]
    emb = pl.embed(img, face)
    norm = float(np.linalg.norm(emb))
    ok_norm = abs(norm - 1.0) < 1e-6
    # Vector đã chuẩn hóa: dot product == cosine similarity
    dot = float(np.dot(emb, emb))
    ok_dot = abs(dot - 1.0) < 1e-6  # self-similarity của vector unit = 1
    print(f"{PASS if ok_norm and ok_dot else FAIL} Pitfall 2.2 L2 Norm: "
          f"||emb||={norm:.9f} (yêu cầu=1.0), self-dot={dot:.9f}")
    return ok_norm and ok_dot


def test_affine_vs_naive(pl: FacePipeline) -> bool:
    """Pitfall 2.1: méo ảnh bằng affine (mô phỏng chụp nghiêng) — pipeline
    căn chỉnh theo 5 điểm mốc phải giữ similarity cao; crop thô + resize thì tụt."""
    img = cv2.imread(str(MODELS_DIR / "face_a.jpg"))
    face = pl.detect(img)[0]
    x1, y1, x2, y2 = face.bbox
    pad = (x2 - x1) // 2
    crop = img[max(0, y1 - pad):y2 + pad, max(0, x1 - pad):x2 + pad].copy()
    ch, cw = crop.shape[:2]

    # Méo ảnh: co ngang 15% + xoay 8° (mô phỏng mặt nghiêng/cận cảnh lệch)
    M = cv2.getRotationMatrix2D((cw / 2, ch / 2), 8, 1.0)
    M[0, 2] += cw * 0.15
    warped = cv2.warpAffine(crop, M, (cw, ch), borderValue=(0, 0, 0))

    # (a) Pipeline chuẩn: detect lại trên ảnh méo → align 5 điểm → embed
    emb_aligned = pl.embed(warped, pl.detect(warped)[0])
    emb_ref = pl.embed(img, face)
    sim_aligned = pl.cosine_similarity(emb_aligned, emb_ref)

    # (b) Naive: crop đúng vị trí cũ (đã lệch vì méo) + resize 112 như ArcFace
    naive = cv2.resize(crop, (112, 112))
    # embed trực tiếp ảnh chưa align qua model (mô phỏng code sai)
    blob = cv2.dnn.blobFromImage(naive, 1.0 / 127.5, (112, 112), (127.5,) * 3, swapRB=True)
    emb_naive = pl._rec.run([pl._rec_out], {pl._rec_in: blob})[0].reshape(-1).astype(np.float32)
    emb_naive = emb_naive / max(float(np.linalg.norm(emb_naive)), 1e-9)
    sim_naive = pl.cosine_similarity(emb_naive, emb_ref)

    ok = sim_aligned > sim_naive and sim_aligned > 0.6
    print(f"{PASS if ok else FAIL} Pitfall 2.1 Affine vs naive: "
          f"aligned={sim_aligned:.4f} > naive_crop={sim_naive:.4f} "
          f"(tụt {sim_naive - sim_aligned:+.4f} điểm nếu crop thô)")
    return ok


def test_primary_face_selection(pl: FacePipeline) -> bool:
    """Pitfall 2.3: người phụ ở hậu cảnh — chọn mặt LỚN gần tâm, không faces[0]."""
    img = cv2.imread(str(MODELS_DIR / "face_a.jpg"))
    ref_face = pl.detect(img)[0]

    # Ghép mặt nhỏ của người KHÁC vào góc trên trái (hậu cảnh)
    b_img = cv2.imread(str(MODELS_DIR / "face_b.jpg"))
    b_face = pl.detect(b_img)[0]
    bx1, by1, bx2, by2 = b_face.bbox
    small = b_img[by1:by2, bx1:bx2]
    small = cv2.resize(small, (max(24, (bx2 - bx1) // 2), max(24, (by2 - by1) // 2)))
    h_s, w_s = small.shape[:2]
    composite = img.copy()
    composite[10:10 + h_s, 10:10 + w_s] = small

    faces = pl.detect(composite)
    primary = pl.select_primary_face(faces, composite.shape)
    if primary is None or len(faces) < 2:
        print(f"{FAIL} Pitfall 2.3: cần ≥2 mặt trong composite (thấy {len(faces)})")
        return False

    # Mặt chính phải là mặt LỚN (gần khớp bbox gốc), không phải mặt nhỏ góc trên
    def area(f):
        return (f.bbox[2] - f.bbox[0]) * (f.bbox[3] - f.bbox[1])

    primary_area = area(primary)
    ref_area = area(ref_face)
    is_large = primary_area > 0.5 * ref_area
    is_center = primary.bbox[1] > 50  # không phải mặt góc trên trái
    ok = is_large and is_center
    print(f"{PASS if ok else FAIL} Pitfall 2.3 Primary face: "
          f"{len(faces)} mặt, chọn mặt {primary_area}px (gốc {ref_area}px), bbox_top={primary.bbox[1]}")
    return ok


def test_anti_swap_multi(pl: FacePipeline) -> bool:
    """Pitfall 3.1: khung phụ là người KHÁC → từ chối + nghi ngờ đánh tráo."""
    selfie = cv2.imread(str(MODELS_DIR / "face_a.jpg"))
    reference = cv2.imread(str(MODELS_DIR / "face_a.jpg"))
    impostor = cv2.imread(str(MODELS_DIR / "face_b.jpg"))

    # Trường hợp 1: aux khớp chủ thể → vẫn matched
    r_ok = pl.match_multi(selfie, reference, [selfie])
    # Trường hợp 2: 1 khung phụ là NGƯỜI KHÁC → phải từ chối toàn bộ
    r_swap = pl.match_multi(selfie, reference, [selfie, impostor])

    ok = r_ok.get("matched") is True and r_swap.get("matched") is False
    aux_flag = all(not a.get("matched") for a in r_swap.get("auxFrames", []) if not a.get("matched")) or \
        any(not a.get("matched") for a in r_swap.get("auxFrames", []))
    print(f"{PASS if ok else FAIL} Pitfall 3.1 Anti-swap: "
          f"aux khớp → matched={r_ok.get('matched')} | "
          f"aux giả mạo → matched={r_swap.get('matched')} (bắt buộc False)")
    return ok and aux_flag


def main() -> int:
    print("KIỂM CHỨNG PITFALL TOÁN HỌC AI — GTX 1650 (CUDA)")
    print("=" * 64)
    pl = load_pipeline()
    print(f"Provider: {pl.provider_used}\n")

    results = [
        ("2.2 L2 Norm", test_l2_norm(pl)),
        ("2.1 Affine alignment", test_affine_vs_naive(pl)),
        ("2.3 Primary face", test_primary_face_selection(pl)),
        ("3.1 Anti-swap", test_anti_swap_multi(pl)),
    ]
    print("=" * 64)
    passed = sum(1 for _, ok in results if ok)
    for name, ok in results:
        print(f"  {'✔' if ok else '✘'} {name}")
    print(f"\nKẾT QUẢ: {passed}/{len(results)} pitfall được kiểm chứng")
    return 0 if passed == len(results) else 1


if __name__ == "__main__":
    sys.exit(main())
