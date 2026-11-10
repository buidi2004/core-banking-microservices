"""
NGUỒN CHÂN LÝ DUY NHẤT VỀ LÃI SUẤT / PHÍ TRONG CODE (Single Source of Truth — SSOT)
Ngân Hàng Số Sen Hồng Core Banking:

Toàn bộ số liệu lãi suất/phí dùng trong code (calculator, prompt LLM, ReAct agent,
deep-thinking, disambiguation, guided-flow) PHẢI đọc từ module này — tuyệt đối không
hardcode số trực tiếp trong logic nghiệp vụ nữa.

Quy tắc đồng bộ:
- Giá trị ở đây PHẢI khớp biểu lãi suất chính thức trong data/lai_suat_tiet_kiem.md
  và data/04_vay_tieu_dung_quick_loan.md (nguồn RAG).
- tests/test_rate_config.py tự động parse file .md và so khớp với bảng dưới —
  nếu file kiến thức đổi mà quên cập nhật đây, test sẽ đỏ ngay.
- Khi ngân hàng điều chỉnh biểu: sửa file .md (cho RAG) + sửa đây (cho code) → re-ingest.
"""

from typing import Dict

# ==================== LÃI SUẤT TIỀN GỬI (%/năm) ====================
CASA_RATE = 0.2  # Không kỳ hạn (ví/tài khoản thanh toán)

SAVINGS_RATES: Dict[int, float] = {
    0: 0.2,   # Không kỳ hạn (CASA)
    1: 3.2,   # 1 tháng
    3: 3.6,   # 3 tháng
    6: 4.8,   # 6 tháng
    9: 5.0,   # 9 tháng
    12: 5.6,  # 12 tháng (Gói ưu đãi tiết kiệm tích lũy tương lai)
    18: 5.8,  # 18 tháng
    24: 6.0,  # 24 tháng
    36: 6.0,  # 36 tháng
}

# Lãi suất quầy niêm yết = online - 0.3%/năm (quy ước file kiến thức: online cộng thêm 0.3)
ONLINE_PREMIUM = 0.3

# ==================== LÃI SUẤT VAY (%/tháng, dư nợ giảm dần) ====================
DEFAULT_LOAN_MONTHLY_RATE = 1.2
LOAN_RATE_MIN_MONTHLY = 1.2
LOAN_RATE_MAX_MONTHLY = 1.5
LOAN_RATE_RANGE_TEXT = "1.2% - 1.5%/tháng (tương đương 14.4% - 18%/năm) tính trên dư nợ giảm dần"

# ==================== Hạn mức tham chiếu (VNĐ) ====================
QUICK_LOAN_MIN = 5_000_000
QUICK_LOAN_MAX = 50_000_000


def get_savings_rate(term_months: int) -> float:
    """Lãi suất online theo kỳ hạn (tháng); kỳ hạn lạ → kỳ hạn gần nhất trong biểu."""
    if term_months in SAVINGS_RATES:
        return SAVINGS_RATES[term_months]
    nearest = min(SAVINGS_RATES, key=lambda k: abs(k - term_months))
    return SAVINGS_RATES[nearest]


def rate_table_text() -> str:
    """Biểu lãi suất dạng chuỗi để nhúng thẳng vào prompt LLM (cùng nguồn với calculator)."""
    lines = ["BIỂU LÃI SUẤT CHUẨN (NGUỒN DUY NHẤT — BẮT BUỘC DÙNG ĐÚNG SỐ NÀY):"]
    lines.append(f"- Tiền gửi không kỳ hạn (CASA): {CASA_RATE}%/năm")
    for term in sorted(k for k in SAVINGS_RATES if k > 0):
        lines.append(f"- Tiết kiệm online kỳ hạn {term} tháng: {SAVINGS_RATES[term]}%/năm")
    lines.append(f"- Vay Quick Loan: {LOAN_RATE_RANGE_TEXT}")
    return "\n".join(lines)
