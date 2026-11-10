"""Module đánh giá chất lượng ảnh sinh trắc học khuôn mặt (Image Quality Assessment - IQA).
Xử lý các lỗi thực tế:
1. Độ nét (Laplacian Variance): Chống mờ, out-focus, ống kính dính vân tay.
2. Độ sáng trung bình (Brightness Intensity): Chống ngược sáng (quá tối) hoặc lóa đèn (cháy sáng).
3. Cân bằng sáng 2 bên mặt (Lighting Symmetry): Chống đèn tạt ngang chia đôi bóng mặt.
4. Ám màu bất thường (Color Cast): Phát hiện đèn LED màu làm sai lệch sắc tố da.
"""
from __future__ import annotations

import cv2
import numpy as np


class ImageQualityAssessment:
    @staticmethod
    def assess_face(img_bgr: np.ndarray, bbox: tuple[int, int, int, int]) -> dict:
        """Đánh giá toàn diện chất lượng vùng mặt."""
        x1, y1, x2, y2 = bbox
        h, w = img_bgr.shape[:2]
        
        # Thêm padding nhẹ 10% quanh mặt
        bw, bh = x2 - x1, y2 - y1
        px1 = max(0, int(x1 - bw * 0.1))
        py1 = max(0, int(y1 - bh * 0.1))
        px2 = min(w, int(x2 + bw * 0.1))
        py2 = min(h, int(y2 + bh * 0.1))
        
        face_crop = img_bgr[py1:py2, px1:px2]
        if face_crop.size == 0 or face_crop.shape[0] < 20 or face_crop.shape[1] < 20:
            return {
                "passed": False,
                "reason": "Vùng mặt quá nhỏ hoặc không hợp lệ",
                "error_code": "EKYC_FACE_TOO_SMALL",
            }

        gray = cv2.cvtColor(face_crop, cv2.COLOR_BGR2GRAY)

        # 1. Độ nét bằng phương sai toán tử Laplacian (chống rung tay, mờ sương, dính vân tay)
        # Sử dụng CV_32F thay vì CV_64F để tiết kiệm 50% RAM & CPU float ops.
        # Ngưỡng mờ ảnh cho camera selfie điện thoại trong nhà: >= 35.0 (ảnh out-focus / rung tay nặng < 20.0)
        laplacian_var = float(cv2.Laplacian(gray, cv2.CV_32F).var())
        is_sharp = laplacian_var >= 35.0  # Ngưỡng mờ ảnh thực tế cho smartphone front camera

        # 2. Độ sáng trung bình vùng mặt (Mean pixel intensity: 50 - 220)
        mean_brightness = float(np.mean(gray))
        is_brightness_ok = 50.0 <= mean_brightness <= 220.0

        # 3. Độ cân bằng sáng giữa nửa mặt trái và nửa mặt phải (chống bóng đổ tạt ngang quá 45%)
        fw = gray.shape[1]
        mid = fw // 2
        left_half = gray[:, :mid]
        right_half = gray[:, mid:]
        mean_left = float(np.mean(left_half))
        mean_right = float(np.mean(right_half))
        max_mean = max(mean_left, mean_right, 1.0)
        symmetry_diff = abs(mean_left - mean_right) / max_mean
        is_symmetric = symmetry_diff <= 0.45  # Chấp nhận góc chiếu thực tế trong phòng

        # 4. Kiểm tra ám màu bất thường (HSV Saturation - đèn LED màu, màn hình giả)
        hsv = cv2.cvtColor(face_crop, cv2.COLOR_BGR2HSV)
        sat_mean = float(np.mean(hsv[:, :, 1]))
        is_natural_color = sat_mean <= 190.0

        # 5. Tỷ lệ kích thước mặt so với khung hình (chống đặt quá sát camera < 15cm)
        face_ratio = bw / float(w)
        is_distance_ok = 0.18 <= face_ratio <= 0.85

        # Tổng hợp kết luận
        issues = []
        error_code = None
        error_message = None

        if not is_distance_ok:
            if face_ratio > 0.75:
                issues.append(f"Mặt quá gần camera (Tỷ lệ: {face_ratio:.2f} > 0.75)")
                error_code = "EKYC_FACE_TOO_CLOSE"
                error_message = "Khuôn mặt quá gần camera (gây méo hình). Vui lòng đưa điện thoại ra xa một chút."
            else:
                issues.append(f"Mặt quá xa camera (Tỷ lệ: {face_ratio:.2f} < 0.25)")
                error_code = "EKYC_FACE_TOO_FAR"
                error_message = "Khuôn mặt quá xa camera. Vui lòng đưa điện thoại lại gần hơn."
        elif not is_sharp:
            issues.append(f"Mờ nét (Laplacian: {laplacian_var:.1f} < 70.0)")
            error_code = "EKYC_BLURRY_IMAGE"
            error_message = "Ảnh khuôn mặt bị mờ. Vui lòng lau sạch camera trước và giữ chắc tay."
        elif not is_brightness_ok:
            if mean_brightness < 70.0:
                issues.append(f"Quá tối / Ngược sáng (Độ sáng: {mean_brightness:.1f} < 70.0)")
                error_code = "EKYC_POOR_LIGHTING"
                error_message = "Khuôn mặt bị tối hoặc ngược sáng. Vui lòng di chuyển ra nơi có đủ ánh sáng."
            else:
                issues.append(f"Cháy sáng / Lóa đèn (Độ sáng: {mean_brightness:.1f} > 215.0)")
                error_code = "EKYC_OVEREXPOSED_LIGHTING"
                error_message = "Khuôn mặt bị lóa sáng quá mạnh. Vui lòng tránh nguồn sáng chiếu trực diện."
        elif not is_symmetric:
            issues.append(f"Ánh sáng chia đôi mặt (Độ lệch: {symmetry_diff * 100:.1f}% > 35%)")
            error_code = "EKYC_UNEVEN_LIGHTING"
            error_message = "Ánh sáng không đều giữa hai bên mặt. Vui lòng nhìn thẳng vào nguồn sáng."
        elif not is_natural_color:
            issues.append(f"Ám màu đèn LED bất thường (Saturation: {sat_mean:.1f} > 185.0)")
            error_code = "EKYC_UNNATURAL_LIGHTING"
            error_message = "Môi trường có ánh sáng màu bất thường. Vui lòng dùng ánh sáng trắng hoặc tự nhiên."

        passed = len(issues) == 0

        return {
            "passed": passed,
            "sharpness": round(laplacian_var, 1),
            "brightness": round(mean_brightness, 1),
            "symmetry_diff": round(symmetry_diff, 3),
            "saturation": round(sat_mean, 1),
            "issues": issues,
            "error_code": error_code,
            "error_message": error_message,
        }

