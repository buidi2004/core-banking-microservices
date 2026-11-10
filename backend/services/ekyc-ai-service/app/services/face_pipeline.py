"""Pipeline nhận diện khuôn mặt ONNX chạy trên GTX 1650 (CUDAExecutionProvider).

Thành phần (Giai đoạn 4 roadmap — dựng sẵn từ Giai đoạn 1 để benchmark):
  1. SCRFD-10G  (det_10g.onnx)      — phát hiện khuôn mặt + 5 điểm mốc
  2. ArcFace r50 (w600k_r50.onnx)   — trích xuất vector đặc trưng 512 chiều
  3. Cosine Similarity               — so khớp selfie ↔ ảnh chip NFC

Triển khai decode SCRFD bằng numpy thuần (không cần package insightface —
tránh cython build trên Python mới; đúng logic anchor decode chuẩn InsightFace).
"""
from __future__ import annotations

import logging
import threading
from dataclasses import dataclass

import cv2
import numpy as np
import onnxruntime as ort

from ..config import FACE_MATCH_THRESHOLD, LIVENESS_THRESHOLD, model_paths

logger = logging.getLogger("ekyc.face_pipeline")

# ---------------------------------------------------------------------------
# Kết quả
# ---------------------------------------------------------------------------


@dataclass(frozen=True)
class DetectedFace:
    bbox: tuple[int, int, int, int]  # x1, y1, x2, y2
    score: float
    kps: np.ndarray  # 5 điểm mốc (2 mắt, mũi, 2 khóe miệng)


@dataclass(frozen=True)
class FaceAnalysis:
    face: DetectedFace | None
    embedding: np.ndarray | None  # 512-d đã chuẩn hóa L2
    detect_ms: float
    embed_ms: float


# ---------------------------------------------------------------------------
# Pipeline
# ---------------------------------------------------------------------------


class FacePipeline:
    """Singleton pipeline — model nạp 1 lần lúc start (warm) để không cold-start."""

    ARCFACE_SRC_5P = np.array(
        [
            [38.2946, 51.6963],
            [73.5318, 51.5014],
            [56.0252, 71.7366],
            [41.5493, 92.3655],
            [70.7299, 92.2041],
        ],
        dtype=np.float32,
    )

    def __init__(self, providers: list[str] | None = None) -> None:
        det_path, rec_path, liv_path = model_paths()
        if providers is None:
            from ..config import ONNX_PROVIDERS
            providers = ONNX_PROVIDERS
        self.providers = list(providers)
        self._gpu_lock = threading.Lock()

        sess_opts = ort.SessionOptions()
        sess_opts.graph_optimization_level = ort.GraphOptimizationLevel.ORT_ENABLE_ALL
        # Giới hạn số luồng CPU của ONNX Runtime chống nghẽn 100% CPU hệ thống
        sess_opts.intra_op_num_threads = 2
        sess_opts.inter_op_num_threads = 1
        sess_opts.execution_mode = ort.ExecutionMode.ORT_SEQUENTIAL
        sess_opts.enable_mem_pattern = True
        sess_opts.enable_cpu_mem_arena = True

        # Cấu hình CUDA Provider Options tối ưu cho GTX 1650 (4GB VRAM)
        provider_options = []
        for p in self.providers:
            if p == "CUDAExecutionProvider":
                provider_options.append({
                    "device_id": "0",
                    "arena_extend_strategy": "kSameAsRequested",
                    "gpu_mem_limit": str(2 * 1024 * 1024 * 1024),  # 2GB VRAM cap
                    "cudnn_conv_algo_search": "DEFAULT",
                    "do_copy_in_default_stream": "1",
                })
            else:
                provider_options.append({})

        logger.info("Nạp model: det=%s, rec=%s, liv=%s (providers=%s)", det_path.name, rec_path.name, liv_path.name, self.providers)
        self._det = ort.InferenceSession(str(det_path), sess_opts, providers=self.providers, provider_options=provider_options)
        self._rec = ort.InferenceSession(str(rec_path), sess_opts, providers=self.providers, provider_options=provider_options)
        self._liv = ort.InferenceSession(str(liv_path), sess_opts, providers=self.providers, provider_options=provider_options)

        self._det_in = self._det.get_inputs()[0].name
        self._rec_in = self._rec.get_inputs()[0].name
        self._rec_out = self._rec.get_outputs()[0].name
        self._liv_in = self._liv.get_inputs()[0].name
        self._liv_out = self._liv.get_outputs()[0].name

        # SCRFD-10G: strides 8/16/32
        self._strides = (8, 16, 32)
        self._num_anchors = 2
        self._fmc = len(self._strides)
        self._use_kps = True

        # Pre-compute static anchors cho kích thước chuẩn 640x640 (tiết kiệm CPU mỗi request)
        self._cached_anchors: dict[int, np.ndarray] = {
            stride: self._anchors_for(640 // stride, 640 // stride, stride)
            for stride in self._strides
        }

        self.provider_used = self._det.get_providers()[0]
        logger.info("Provider đang dùng: %s", self.provider_used)

    # ------------------------------------------------------------------
    # Tiền xử lý
    # ------------------------------------------------------------------

    @staticmethod
    def _letterbox(img: np.ndarray, target: int = 640) -> tuple[np.ndarray, float]:
        h, w = img.shape[:2]
        scale = target / max(h, w)
        nh, nw = int(round(h * scale)), int(round(w * scale))
        resized = cv2.resize(img, (nw, nh), interpolation=cv2.INTER_LINEAR)
        canvas = np.zeros((target, target, 3), dtype=np.uint8)
        canvas[:nh, :nw] = resized
        return canvas, scale

    # ------------------------------------------------------------------
    # SCRFD decode
    # ------------------------------------------------------------------

    def detect(self, img_bgr: np.ndarray, score_thresh: float = 0.40) -> list[DetectedFace]:
        faces = self._detect_internal(img_bgr, score_thresh=score_thresh)
        if not faces and score_thresh > 0.25:
            # Fallback ngưỡng thấp 0.25 để nhận diện các ảnh thẻ CCCD in nhỏ hoặc tương phản thấp
            faces = self._detect_internal(img_bgr, score_thresh=0.25)
        return faces

    def _detect_internal(self, img_bgr: np.ndarray, score_thresh: float) -> list[DetectedFace]:
        canvas, scale = self._letterbox(img_bgr)
        blob = cv2.dnn.blobFromImage(canvas, 1.0 / 128.0, (640, 640), (127.5, 127.5, 127.5), swapRB=True)
        with self._gpu_lock:
            outputs = self._det.run(None, {self._det_in: blob})

        # Layout output det_10g (đã probe thực tế, 9 tensor 2-D không batch dim):
        # [s8(N,1), s16(N,1), s32(N,1), b8(N,4), b16(N,4), b32(N,4), k8(N,10), k16, k32]
        fmc = self._fmc
        scores_list = outputs[0:fmc]
        boxes_list = outputs[fmc : 2 * fmc]
        kps_list = outputs[2 * fmc : 3 * fmc] if self._use_kps else [None] * fmc

        all_boxes: list[np.ndarray] = []
        all_scores: list[np.ndarray] = []
        all_kps: list[np.ndarray] = []

        for idx in range(fmc):
            stride = self._strides[idx]
            grid_dim = 640 // stride  # 80 / 40 / 20
            anchors = self._cached_anchors.get(stride) if hasattr(self, "_cached_anchors") and grid_dim == 640 // stride else self._anchors_for(grid_dim, grid_dim, stride)

            s = scores_list[idx].reshape(-1)
            mask = s > score_thresh
            if not mask.any():
                continue
            b = boxes_list[idx].reshape(-1, 4)[mask].astype(np.float32)
            a = anchors[mask]

            # distance2bbox chuẩn InsightFace: khoảng cách nhân stride
            x1 = a[:, 0:1] - b[:, 0:1] * stride
            y1 = a[:, 1:2] - b[:, 1:2] * stride
            x2 = a[:, 0:1] + b[:, 2:3] * stride
            y2 = a[:, 1:2] + b[:, 3:4] * stride
            all_boxes.append(np.concatenate([x1, y1, x2, y2], axis=1))
            all_scores.append(s[mask])

            if kps_list[idx] is not None:
                k = kps_list[idx].reshape(-1, 5, 2)[mask].astype(np.float32)
                a3 = a[:, None, :].astype(np.float32)  # (N,1,2) broadcast theo 5 điểm
                kx = a3[:, :, 0:1] + k[:, :, 0:1] * stride
                ky = a3[:, :, 1:2] + k[:, :, 1:2] * stride
                all_kps.append(np.concatenate([kx, ky], axis=2))  # (N,5,2)

        if not all_boxes:
            return []

        boxes = np.concatenate(all_boxes) / scale
        scores = np.concatenate(all_scores)
        kps_all = np.concatenate(all_kps) / scale if all_kps else None

        keep = self._nms(boxes, scores, iou_thresh=0.4)
        result: list[DetectedFace] = []
        for i in keep:
            x1, y1, x2, y2 = [int(v) for v in boxes[i]]
            kps = kps_all[i].astype(np.float32) if kps_all is not None else np.zeros((5, 2), np.float32)
            result.append(DetectedFace(bbox=(x1, y1, x2, y2), score=float(scores[i]), kps=kps))
        result.sort(key=lambda f: f.score, reverse=True)
        return result

    def _anchors_for(self, w: int, h: int, stride: int) -> np.ndarray:
        """Anchor SCRFD chuẩn InsightFace: mỗi ô lưới 2 anchor TRÙNG tâm
        (không phải lệch nửa stride), thứ tự y-ngoài x-trong."""
        grid = np.stack(np.mgrid[:h, :w][::-1], axis=-1).astype(np.float32)  # (h,w,2)=(x,y)
        centers = (grid * stride).reshape(-1, 2)
        centers = np.stack([centers] * self._num_anchors, axis=1).reshape(-1, 2)  # [c,c,c,c,...]
        return centers

    @staticmethod
    def _nms(boxes: np.ndarray, scores: np.ndarray, iou_thresh: float) -> list[int]:
        x1, y1, x2, y2 = boxes[:, 0], boxes[:, 1], boxes[:, 2], boxes[:, 3]
        areas = (x2 - x1 + 1) * (y2 - y1 + 1)
        order = scores.argsort()[::-1]
        keep: list[int] = []
        while order.size > 0:
            i = order[0]
            keep.append(int(i))
            xx1 = np.maximum(x1[i], x1[order[1:]])
            yy1 = np.maximum(y1[i], y1[order[1:]])
            xx2 = np.minimum(x2[i], x2[order[1:]])
            yy2 = np.minimum(y2[i], y2[order[1:]])
            inter = np.maximum(0.0, xx2 - xx1 + 1) * np.maximum(0.0, yy2 - yy1 + 1)
            iou = inter / (areas[i] + areas[order[1:]] - inter)
            order = order[1:][iou <= iou_thresh]
        return keep

    # ------------------------------------------------------------------
    # ArcFace embedding
    # ------------------------------------------------------------------

    def embed(self, img_bgr: np.ndarray, face: DetectedFace) -> np.ndarray:
        """Căn chỉnh 5 điểm mốc về template ArcFace 112x112 rồi trích vector."""
        aligned = self._align_5p(img_bgr, face.kps)
        blob = cv2.dnn.blobFromImage(aligned, 1.0 / 127.5, (112, 112), (127.5, 127.5, 127.5), swapRB=True)
        with self._gpu_lock:
            emb = self._rec.run([self._rec_out], {self._rec_in: blob})[0].reshape(-1)
        emb = emb.astype(np.float32)
        return emb / max(float(np.linalg.norm(emb)), 1e-9)

    @staticmethod
    def _umeyama(src: np.ndarray, dst: np.ndarray) -> np.ndarray | None:
        """Thuật toán Umeyama tính ma trận tương đồng 2D chuẩn InsightFace từ 5 điểm mốc."""
        num, dim = src.shape
        src_mean = src.mean(axis=0)
        dst_mean = dst.mean(axis=0)
        src_demean = src - src_mean
        dst_demean = dst - dst_mean
        A = np.dot(dst_demean.T, src_demean) / num
        d = np.ones((dim,), dtype=np.double)
        if np.linalg.det(A) < 0:
            d[dim - 1] = -1
        T = np.eye(dim + 1, dtype=np.double)
        U, S, V = np.linalg.svd(A)
        rank = np.linalg.matrix_rank(A)
        if rank == 0:
            return None
        elif rank == dim - 1:
            if np.linalg.det(U) * np.linalg.det(V) > 0:
                T[:dim, :dim] = np.dot(U, V)
            else:
                s = d[dim - 1]
                d[dim - 1] = -1
                T[:dim, :dim] = np.dot(U, np.dot(np.diag(d), V))
                d[dim - 1] = s
        else:
            T[:dim, :dim] = np.dot(U, np.dot(np.diag(d), V))
        scale = 1.0 / (src_demean.var(axis=0).sum() + 1e-9) * np.dot(S, d)
        T[:dim, dim] = dst_mean - scale * np.dot(T[:dim, :dim], src_mean.T)
        T[:dim, :dim] *= scale
        return T[:2, :]

    @staticmethod
    def _align_5p(img: np.ndarray, kps: np.ndarray, size: int = 112) -> np.ndarray:
        """Similarity transform đưa 5 điểm mốc về template chuẩn ArcFace 112x112."""
        src_tmpl = FacePipeline.ARCFACE_SRC_5P
        dst_kps = kps[:, :2].astype(np.float32)
        m = FacePipeline._umeyama(dst_kps, src_tmpl)
        if m is None:
            # Fallback sang LMEDS để không bị RANSAC loại bỏ nhầm inliers
            m, _ = cv2.estimateAffinePartial2D(dst_kps, src_tmpl, method=cv2.LMEDS)
        if m is None:
            # Fallback: crop thường nếu ước lượng ma trận lỗi
            x1, y1 = int(kps[:, 0].min()), int(kps[:, 1].min())
            x2, y2 = int(kps[:, 0].max()), int(kps[:, 1].max())
            pad = max(x2 - x1, y2 - y1) // 2
            crop = img[max(0, y1 - pad): y2 + pad, max(0, x1 - pad): x2 + pad]
            return cv2.resize(crop, (size, size))
        return cv2.warpAffine(img, m, (size, size), borderValue=0)

    # ------------------------------------------------------------------
    # Passive Anti-Spoofing (MiniFASNetV2)
    # ------------------------------------------------------------------

    def detect_liveness(self, img_bgr: np.ndarray, face: DetectedFace) -> dict:
        """Kiểm tra passive anti-spoofing bằng MiniFASNetV2 với tỷ lệ crop 2.7x.
        Phân loại 3 lớp: 0 = print-attack, 1 = live/real, 2 = replay-attack.
        """
        import time
        t0 = time.perf_counter()
        h, w = img_bgr.shape[:2]
        x1, y1, x2, y2 = face.bbox
        bw, bh = x2 - x1, y2 - y1
        cx, cy = x1 + bw / 2.0, y1 + bh / 2.0
        nw, nh = bw * 2.7, bh * 2.7
        nx1 = max(0, int(cx - nw / 2.0))
        ny1 = max(0, int(cy - nh / 2.0))
        nx2 = min(w, int(cx + nw / 2.0))
        ny2 = min(h, int(cy + nh / 2.0))
        crop = img_bgr[ny1:ny2, nx1:nx2]
        if crop.size == 0:
            return {
                "is_live": False,
                "score": 0.0,
                "threshold": LIVENESS_THRESHOLD,
                "reason": "Vùng crop khuôn mặt không hợp lệ",
                "latency_ms": round((time.perf_counter() - t0) * 1000, 2),
            }
        crop_80 = cv2.resize(crop, (80, 80), interpolation=cv2.INTER_LINEAR)
        # MiniFASNetV2 ONNX nhận ma trận điểm ảnh BGR chuẩn miền [0, 255] dạng float32
        # (Không chia cho 255.0 vì model được huấn luyện trên dải 0..255; chia 255 làm ảnh thành
        # gần như toàn màu đen khiến model phân loại nhầm thành replay_attack / màn hình giả mạo).
        blob = crop_80.astype(np.float32).transpose(2, 0, 1)[None, ...]
        with self._gpu_lock:
            outputs = self._liv.run([self._liv_out], {self._liv_in: blob})[0][0]
        exp = np.exp(outputs - np.max(outputs))
        probs = exp / np.sum(exp)
        live_score = float(probs[1])
        pred_label = int(np.argmax(probs))
        is_live = bool(pred_label == 1 and live_score >= LIVENESS_THRESHOLD)
        latency = round((time.perf_counter() - t0) * 1000, 2)
        return {
            "is_live": is_live,
            "score": round(live_score, 4),
            "threshold": LIVENESS_THRESHOLD,
            "predicted_class": pred_label,
            "class_probs": {
                "print_attack": round(float(probs[0]), 4),
                "live": round(float(probs[1]), 4),
                "replay_attack": round(float(probs[2]), 4),
            },
            "latency_ms": latency,
        }

    # ------------------------------------------------------------------
    # API cấp cao
    # ------------------------------------------------------------------

    @staticmethod
    def select_primary_face(faces: list[DetectedFace], img_shape: tuple) -> DetectedFace | None:
        """Chọn khuôn mặt CHÍNH: ưu tiên khung mặt LỚN NHẤT gần tâm ảnh nhất.

        Nếu chỉ có đúng 1 khuôn mặt (như ảnh thẻ CCCD hoặc ảnh selfie thông thường),
        chọn trực tiếp khuôn mặt đó mà không khấu trừ khoảng cách tâm.
        """
        if not faces:
            return None
        if len(faces) == 1:
            return faces[0]

        h, w = img_shape[:2]
        cx, cy = w / 2.0, h * 0.42  # tâm ảnh lệch lên trên (khung chụp eKYC)
        best, best_rank = None, -1.0
        for f in faces:
            x1, y1, x2, y2 = f.bbox
            area = max(1, (x2 - x1) * (y2 - y1))
            fcx, fcy = (x1 + x2) / 2.0, (y1 + y2) / 2.0
            dist = ((fcx - cx) ** 2 + (fcy - cy) ** 2) ** 0.5
            norm_dist = min(dist / (max(w, h) / 2.0), 1.0)
            rank = area * (1.0 - 0.5 * norm_dist)
            if rank > best_rank:
                best, best_rank = f, rank
        return best

    def analyze(self, img_bgr: np.ndarray) -> FaceAnalysis:
        import time

        t0 = time.perf_counter()
        faces = self.detect(img_bgr)
        t1 = time.perf_counter()
        primary = self.select_primary_face(faces, img_bgr.shape)
        if primary is None:
            return FaceAnalysis(face=None, embedding=None, detect_ms=(t1 - t0) * 1000, embed_ms=0.0)
        emb = self.embed(img_bgr, primary)
        t2 = time.perf_counter()
        return FaceAnalysis(
            face=primary, embedding=emb, detect_ms=(t1 - t0) * 1000, embed_ms=(t2 - t1) * 1000
        )

    @staticmethod
    def cosine_similarity(a: np.ndarray, b: np.ndarray) -> float:
        return float(np.clip(np.dot(a, b) / (np.linalg.norm(a) * np.linalg.norm(b) + 1e-9), -1.0, 1.0))

    def match(
        self,
        selfie: np.ndarray,
        reference: np.ndarray,
        selfie_analysis: FaceAnalysis | None = None,
        ref_analysis: FaceAnalysis | None = None,
    ) -> dict:
        """So khớp selfie ↔ ảnh chip NFC (DG2). Tái sử dụng FaceAnalysis nếu đã có."""
        a = selfie_analysis if selfie_analysis is not None else self.analyze(selfie)
        b = ref_analysis if ref_analysis is not None else self.analyze(reference)
        self._last_ref_analysis = b
        if a.embedding is None or b.embedding is None:
            reason = "Không phát hiện khuôn mặt trong ảnh selfie" if a.embedding is None else "Không phát hiện khuôn mặt trên thẻ CCCD hoặc chip NFC"
            return {
                "matched": False,
                "similarity": None,
                "threshold": FACE_MATCH_THRESHOLD,
                "reason": reason,
                "selfie": a.face and {"bbox": a.face.bbox, "score": round(a.face.score, 4)},
                "reference": b.face and {"bbox": b.face.bbox, "score": round(b.face.score, 4)},
                "latency": {"detect_ms": round(a.detect_ms + b.detect_ms, 2), "embed_ms": round(a.embed_ms + b.embed_ms, 2)},
            }
        sim = self.cosine_similarity(a.embedding, b.embedding)
        return {
            "matched": bool(sim >= FACE_MATCH_THRESHOLD),
            "similarity": round(sim, 4),
            "threshold": FACE_MATCH_THRESHOLD,
            "reason": "So khớp thành công" if sim >= FACE_MATCH_THRESHOLD else "Độ khớp dưới ngưỡng",
            "selfie": {"bbox": a.face.bbox, "score": round(a.face.score, 4)},
            "reference": {"bbox": b.face.bbox, "score": round(b.face.score, 4)},
            "latency": {"detect_ms": round(a.detect_ms + b.detect_ms, 2), "embed_ms": round(a.embed_ms + b.embed_ms, 2)},
        }

    def match_multi(
        self,
        selfie: np.ndarray,
        reference: np.ndarray,
        aux_frames: list[np.ndarray] | None = None,
        selfie_analysis: FaceAnalysis | None = None,
        ref_analysis: FaceAnalysis | None = None,
    ) -> dict:
        """So khớp chéo chống ĐÁNH TRÁO NGƯỜI (anti-swap), tái sử dụng analysis."""
        base = self.match(selfie, reference, selfie_analysis=selfie_analysis, ref_analysis=ref_analysis)
        if not base.get("matched") or not aux_frames:
            base["auxFrames"] = []
            return base

        # Tái sử dụng ref_analysis đã phân tích trong self.match (tiết kiệm 1 lần detect + embed)
        effective_ref_analysis = ref_analysis if ref_analysis is not None else getattr(self, "_last_ref_analysis", None)
        if effective_ref_analysis is None or effective_ref_analysis.embedding is None:
            effective_ref_analysis = self.analyze(reference)

        if effective_ref_analysis.embedding is None:
            base["auxFrames"] = []
            return base

        aux_results: list[dict] = []
        all_ok = True
        for i, frame in enumerate(aux_frames):
            a = self.analyze(frame)
            if a.embedding is None:
                aux_results.append({"index": i, "matched": False, "similarity": None,
                                    "reason": "Không thấy khuôn mặt trong khung phụ"})
                all_ok = False
                continue
            sim = self.cosine_similarity(a.embedding, effective_ref_analysis.embedding)
            ok = sim >= FACE_MATCH_THRESHOLD
            aux_results.append({
                "index": i,
                "matched": bool(ok),
                "similarity": round(sim, 4),
                "reason": "Khớp" if ok else "Khung phụ không khớp chủ thể",
            })
            all_ok &= ok

        base["auxFrames"] = aux_results
        if not all_ok:
            base["matched"] = False
            base["reason"] = "Phát hiện khung hình phụ không khớp chủ thể — nghi ngờ đánh tráo người"
        return base
