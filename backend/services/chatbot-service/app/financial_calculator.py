"""
Động Cơ Tính Toán Tài Chính Siêu Chuẩn Xác (High-Precision Financial Calculator Engine)
Cung cấp các phép tính tài chính chính xác 100% đến từng đồng VNĐ cho Trợ lý AI Sen Hồng:
1. Tính lãi suất tiết kiệm ngắn & dài hạn (1 tháng đến 10 năm) với cơ chế Lãi Kép (Compound Interest)
2. So sánh hiệu quả sinh lời giữa Gửi Tiết Kiệm vs Để tiền trong ví không kỳ hạn (CASA 0.2%/năm)
3. Tính toán lịch trả nợ vay tiêu dùng Quick Loan theo Dư Nợ Giảm Dần (1.2%/tháng)
4. Lập kế hoạch tích lũy mục tiêu (Goal-based Savings)
"""

import math
import re
from typing import Dict, Any, List, Optional, Tuple

from app import rate_config

# Biểu lãi suất chuẩn — SSOT nằm ở app/rate_config.py (khớp data/lai_suat_tiet_kiem.md).
# Alias giữ tương thích với mọi call-site nội bộ của module này.
SAVINGS_RATES = rate_config.SAVINGS_RATES
DEFAULT_LOAN_MONTHLY_RATE = rate_config.DEFAULT_LOAN_MONTHLY_RATE


def format_vnd(amount: float) -> str:
    """Định dạng tiền tệ VNĐ chuẩn ngân hàng Việt Nam: 50.000.000 VNĐ"""
    rounded = round(amount)
    return f"{rounded:,.0f} VNĐ".replace(",", ".")


def calculate_savings_compound(
    principal: float,
    term_years: int = 10,
    rate_annual: Optional[float] = None
) -> Dict[str, Any]:
    """
    Tính toán tăng trưởng tài sản gửi tiết kiệm có kỳ hạn dài hạn (1 đến 10 năm):
    - Cơ chế Tự động tái tục cả gốc và lãi (Lãi kép - Compound Interest hàng năm)
    - So sánh với phương án để tiền trong tài khoản không kỳ hạn (0.2%/năm)
    """
    if principal <= 0:
        principal = 50_000_000.0  # Mốc mặc định nếu không truyền hoặc số dư = 0

    if rate_annual is None:
        rate_annual = SAVINGS_RATES[12]  # Lãi suất online 12 tháng chuẩn theo biểu SSOT

    rate_decimal = rate_annual / 100.0
    casa_rate_decimal = SAVINGS_RATES[0] / 100.0  # 0.002

    yearly_breakdown: List[Dict[str, Any]] = []
    
    # Tính toán từng mốc năm: 1, 2, 3, 5, 10 năm hoặc theo term_years
    milestones = sorted(list(set([1, 2, 3, 5, 10, term_years])))
    milestones = [m for m in milestones if 1 <= m <= max(10, term_years)]

    for y in milestones:
        # Tiết kiệm online tái tục cả gốc và lãi: A = P * (1 + r)^y
        total_savings = principal * math.pow(1.0 + rate_decimal, y)
        interest_savings = total_savings - principal

        # Để trong ví/tài khoản thanh toán không kỳ hạn (0.2%/năm):
        total_casa = principal * math.pow(1.0 + casa_rate_decimal, y)
        interest_casa = total_casa - principal

        difference = interest_savings - interest_casa

        yearly_breakdown.append({
            "year": y,
            "total_savings": total_savings,
            "interest_savings": interest_savings,
            "total_casa": total_casa,
            "interest_casa": interest_casa,
            "difference": difference,
            "fmt_total_savings": format_vnd(total_savings),
            "fmt_interest_savings": format_vnd(interest_savings),
            "fmt_total_casa": format_vnd(total_casa),
            "fmt_interest_casa": format_vnd(interest_casa),
            "fmt_difference": format_vnd(difference),
        })

    # Tìm mốc năm khách hàng hỏi hoặc mốc 10 năm
    target_data = next((item for item in yearly_breakdown if item["year"] == term_years), yearly_breakdown[-1])

    # Tạo bảng biểu so sánh Markdown sắc nét
    table_lines = [
        f"| Thời gian | Để tiền trong ví ({rate_config.CASA_RATE:.1f}%/năm) | Gửi Tiết kiệm Lãi Kép ({rate_annual:.1f}%/năm) | Tiền lãi chênh lệch vượt trội |",
        "| :--- | :--- | :--- | :--- |"
    ]
    for b in yearly_breakdown:
        table_lines.append(
            f"| **Sau {b['year']} năm** | {b['fmt_total_casa']} *(lãi {b['fmt_interest_casa']})* | "
            f"**{b['fmt_total_savings']}** *(lãi **{b['fmt_interest_savings']}**)* | "
            f"**+{b['fmt_difference']}** |"
        )
    markdown_table = "\n".join(table_lines)

    return {
        "principal": principal,
        "fmt_principal": format_vnd(principal),
        "rate_annual": rate_annual,
        "term_years": term_years,
        "target_data": target_data,
        "yearly_breakdown": yearly_breakdown,
        "markdown_table": markdown_table,
    }


def calculate_loan_amortization(
    principal: float,
    term_months: int = 12,
    rate_monthly: float = DEFAULT_LOAN_MONTHLY_RATE
) -> Dict[str, Any]:
    """
    Tính lịch trả nợ vay tiêu dùng Quick Loan theo DƯ NỢ GIẢM DẦN (Chuẩn ngân hàng Sen Hồng):
    - Tiền gốc hàng tháng = P / N
    - Tiền lãi tháng k = Dư nợ còn lại * rate_monthly
    - Tiền trả tháng k = Gốc + Lãi tháng k
    """
    if principal <= 0:
        principal = 30_000_000.0
    if term_months <= 0:
        term_months = 12

    monthly_principal = principal / term_months
    remaining_balance = principal
    total_interest = 0.0

    schedule: List[Dict[str, Any]] = []

    for month in range(1, term_months + 1):
        monthly_interest = remaining_balance * (rate_monthly / 100.0)
        monthly_payment = monthly_principal + monthly_interest
        total_interest += monthly_interest
        remaining_balance -= monthly_principal

        schedule.append({
            "month": month,
            "monthly_payment": monthly_payment,
            "monthly_principal": monthly_principal,
            "monthly_interest": monthly_interest,
            "remaining_balance": max(0.0, remaining_balance),
            "fmt_payment": format_vnd(monthly_payment),
            "fmt_principal": format_vnd(monthly_principal),
            "fmt_interest": format_vnd(monthly_interest),
            "fmt_remaining": format_vnd(max(0.0, remaining_balance)),
        })

    first_month = schedule[0]
    last_month = schedule[-1]
    total_payment = principal + total_interest

    return {
        "principal": principal,
        "fmt_principal": format_vnd(principal),
        "term_months": term_months,
        "rate_monthly": rate_monthly,
        "rate_annual": round(rate_monthly * 12, 2),
        "total_interest": total_interest,
        "fmt_total_interest": format_vnd(total_interest),
        "total_payment": total_payment,
        "fmt_total_payment": format_vnd(total_payment),
        "monthly_principal": monthly_principal,
        "fmt_monthly_principal": format_vnd(monthly_principal),
        "first_month_payment": first_month["monthly_payment"],
        "fmt_first_month_payment": first_month["fmt_payment"],
        "first_month_interest": first_month["monthly_interest"],
        "fmt_first_month_interest": first_month["fmt_interest"],
        "last_month_payment": last_month["monthly_payment"],
        "fmt_last_month_payment": last_month["fmt_payment"],
        "last_month_interest": last_month["monthly_interest"],
        "fmt_last_month_interest": last_month["fmt_interest"],
        "schedule": schedule,
    }


def calculate_target_goal_savings(
    target_amount: float,
    term_months: int = 36,
    rate_annual: float = rate_config.SAVINGS_RATES[36]
) -> Dict[str, Any]:
    """
    Tính số tiền cần tích lũy gửi góp hàng tháng để đạt được mục tiêu tài chính:
    PMT = FV * i / ((1 + i)^n - 1)
    """
    if target_amount <= 0:
        target_amount = 100_000_000.0
    if term_months <= 0:
        term_months = 36

    monthly_rate = (rate_annual / 100.0) / 12.0
    factor = math.pow(1.0 + monthly_rate, term_months) - 1.0
    if factor <= 0:
        monthly_deposit = target_amount / term_months
    else:
        monthly_deposit = target_amount * monthly_rate / factor

    total_deposit = monthly_deposit * term_months
    earned_interest = target_amount - total_deposit

    return {
        "target_amount": target_amount,
        "fmt_target_amount": format_vnd(target_amount),
        "term_months": term_months,
        "monthly_deposit": monthly_deposit,
        "fmt_monthly_deposit": format_vnd(monthly_deposit),
        "total_deposit": total_deposit,
        "fmt_total_deposit": format_vnd(total_deposit),
        "earned_interest": earned_interest,
        "fmt_earned_interest": format_vnd(earned_interest),
    }


def extract_amount_from_text(text: str) -> Optional[float]:
    """
    Trích xuất số tiền linh hoạt từ câu hỏi tiếng Việt:
    - 50tr, 50 triệu, 50.000.000, 1 tỷ, 500k, 20 củ...
    """
    if not text:
        return None
    t = text.lower().replace(",", ".")

    # Pattern: 1.5 tỷ, 2 tỷ
    ty_match = re.search(r'(\d+(?:\.\d+)?)\s*(?:tỷ|ty)\b', t)
    if ty_match:
        try:
            return float(ty_match.group(1)) * 1_000_000_000.0
        except ValueError:
            pass

    # Pattern: 50 triệu, 50tr, 50 trieu, 50 củ
    tr_match = re.search(r'(\d+(?:\.\d+)?)\s*(?:triệu|trieu|tr|củ|cu)\b', t)
    if tr_match:
        try:
            return float(tr_match.group(1)) * 1_000_000.0
        except ValueError:
            pass

    # Pattern: 500k, 500 nghìn, 500 ngàn
    k_match = re.search(r'(\d+(?:\.\d+)?)\s*(?:k|nghìn|nghin|ngàn|ngan)\b', t)
    if k_match:
        try:
            return float(k_match.group(1)) * 1_000.0
        except ValueError:
            pass

    # Pattern số đầy đủ: 50.000.000 hoặc 50000000
    num_match = re.search(r'\b(\d{1,3}(?:\.\d{3}){1,3}|\d{6,11})\b', t)
    if num_match:
        raw_num = num_match.group(1).replace(".", "")
        try:
            val = float(raw_num)
            if val >= 100_000:
                return val
        except ValueError:
            pass

    return None


def extract_term_months_from_text(text: str) -> Optional[int]:
    """Trích xuất số tháng: 12 tháng, 6 tháng, 1 tháng..."""
    if not text:
        return None
    t = text.lower()
    m_match = re.search(r'(\d+)\s*(?:tháng|thang|months?)\b', t)
    if m_match:
        try:
            return int(m_match.group(1))
        except ValueError:
            pass
    return None


def extract_term_years_from_text(text: str, default: Optional[int] = None) -> Optional[int]:
    """Trích xuất số năm tiết kiệm: 10 năm, 5 năm, vài năm..."""
    if not text:
        return default
    t = text.lower()
    
    # 10 năm, 5 năm, 3 năm...
    y_match = re.search(r'(\d+)\s*(?:năm|nam|yr|years?)\b', t)
    if y_match:
        try:
            y = int(y_match.group(1))
            return min(max(y, 1), 30)
        except ValueError:
            pass

    # Quy đổi nếu có số tháng >= 12 (ví dụ 12 tháng -> 1 năm, 24 tháng -> 2 năm)
    m_match = re.search(r'(\d+)\s*(?:tháng|thang|months?)\b', t)
    if m_match:
        try:
            m = int(m_match.group(1))
            if m >= 12:
                return min(max(round(m / 12), 1), 30)
        except ValueError:
            pass

    if any(k in t for k in ["vài năm", "vai nam", "mấy năm", "may nam", "lau dai", "lâu dài"]):
        return 5

    return default


def generate_comprehensive_financial_analysis(
    user_question: str,
    user_wallet: Optional[Dict[str, Any]] = None
) -> Optional[Dict[str, Any]]:
    """
    Tự động phân tích câu hỏi người dùng và sinh báo cáo tài chính tích hợp chuyên sâu:
    - Nhận biết số dư ví hiện tại nếu user nói "tiền trong tài khoản"
    - Tự tính toán tiền lãi tiết kiệm dài hạn (1 năm, 3 năm, 5 năm, 10 năm) với Lãi kép
    - Tự tính toán lãi suất vay Quick Loan tương ứng theo Dư nợ giảm dần để so sánh 2 chiều
    """
    q_lower = user_question.lower()

    # Kiểm tra xem có chứa ý định tính lãi suất tiết kiệm hoặc vay không
    is_savings_intent = any(k in q_lower for k in [
        "tiết kiệm", "tiet kiem", "gửi tiền", "gui tien", "gửi tiết kiệm", "sinh lời", "sinh loi", "để dành",
        "tích lũy", "tich luy", "tích góp", "tich gop", "gửi góp", "gui gop", "mục tiêu", "muc tieu", "mua nhà", "mua xe"
    ]) or bool(re.search(r'\b(?:gửi|gui)\s+\d+', q_lower))
    is_loan_intent = any(k in q_lower for k in [
        "vay", "khoản vay", "khoan vay", "quick loan", "mượn", "trả nợ", "tra no"
    ])
    is_rate_or_calc = any(k in q_lower for k in [
        "lãi", "lai", "lãi suất", "lai suat", "tính", "tinh", "bao nhiêu", "bao nhieu", "được mấy", "lời",
        "mỗi tháng", "moi thang", "cần gửi", "can gui", "phải gửi", "phai gui"
    ])
    has_account_ref = any(k in q_lower for k in [
        "tiền trong tài khoản", "tien trong tai khoan", "trong ví", "trong vi", "số dư", "so du", "tài khoản của tôi"
    ])

    if not (is_savings_intent or is_loan_intent or (has_account_ref and is_rate_or_calc)):
        return None

    # Bộ lọc loại trừ chuyên sâu: Nếu câu hỏi hỏi về tối thiểu/tối đa, hạn mức, biểu phí, điều kiện, thủ tục, cách làm...
    # mà KHÔNG có yêu cầu tính toán số liệu lãi/tiền lời cụ thể thì nhường quyền cho RAG / Rule Handler
    is_inquiry_only = any(k in q_lower for k in [
        "tối thiểu", "toi thieu", "ít nhất", "it nhat", "thấp nhất", "thap nhat",
        "tối đa", "toi da", "nhiều nhất", "nhieu nhat", "cao nhất", "cao nhat",
        "hạn mức", "han muc", "hạn mức ngày", "hạn mức lần",
        "phí", "phi", "mất phí", "mat phi", "biểu phí", "tốn phí", "mien phi", "miễn phí",
        "điều kiện", "dieu kien", "thủ tục", "thu tuc", "hồ sơ", "ho so", "giấy tờ", "giay to",
        "cần gì", "can gi", "quy định", "quy dinh",
        "cách", "cach", "làm sao", "lam sao", "hướng dẫn", "huong dan", "các bước", "cac buoc", "thao tác",
        "biểu lãi suất", "bieu lai suat", "bảng lãi suất", "bang lai suat"
    ])

    has_explicit_calculation_request = any(k in q_lower for k in [
        "tính lãi", "tinh lai", "tính tiền", "tinh tien", "tự nó tính", "tu no tinh", "tu nso tinh",
        "lãi kép", "lai kep", "tiền lời", "tien loi", "bảng tính", "bang tinh",
        "dư nợ giảm dần", "du no giam dan", "gửi góp", "gui gop",
        "được bao nhiêu tiền lãi", "duoc bao nhieu tien lai", "sinh lời bao nhiêu", "sinh loi bao nhieu",
        "sau 1 năm", "sau 2 năm", "sau 3 năm", "sau 5 năm", "sau 10 năm", "vài năm", "vai nam",
        "mỗi tháng trả bao nhiêu", "moi thang tra bao nhieu"
    ])

    if is_inquiry_only and not has_explicit_calculation_request:
        return None

    # Xác định số tiền gốc:
    # 1. Từ số tiền cụ thể trong text
    extracted_amount = extract_amount_from_text(user_question)
    wallet_balance = float(user_wallet.get("balance", 0)) if user_wallet else 0.0

    # Nếu không có số tiền cụ thể và cũng không có yêu cầu tính toán con số thì nhường quyền cho bảng biểu RAG
    if not extracted_amount and not has_explicit_calculation_request and not has_account_ref:
        return None

    if extracted_amount and extracted_amount > 0:
        base_amount = extracted_amount
        amount_source = "USER_SPECIFIED"
    elif has_account_ref and wallet_balance > 0:
        base_amount = wallet_balance
        amount_source = "WALLET_BALANCE"
    elif wallet_balance > 0:
        base_amount = wallet_balance
        amount_source = "WALLET_BALANCE"
    else:
        base_amount = 50_000_000.0  # Mốc tiêu chuẩn 50 triệu VNĐ
        amount_source = "DEFAULT_BENCHMARK"

    term_years = extract_term_years_from_text(user_question, default=10) or 10

    # 1. Tính toán Tiết kiệm Lãi Kép
    savings_calc = calculate_savings_compound(base_amount, term_years=term_years)

    # 2. Tính toán Khoản vay tiêu dùng Quick Loan tương ứng (kỳ hạn 12 tháng)
    loan_calc = calculate_loan_amortization(base_amount, term_months=12)

    # 3. Tính toán Tích lũy mục tiêu (Goal-based Savings)
    goal_calc = calculate_target_goal_savings(base_amount, term_months=term_years * 12)

    is_goal_intent = any(k in q_lower for k in [
        "tích lũy", "tich luy", "mục tiêu", "muc tieu", "mua nhà", "mua nha", "mua xe", "để dành được", "de danh duoc"
    ])

    # Phân loại rạch ròi: Vay ra vay, Lãi ra lãi, Tiết kiệm ra tiết kiệm
    explicit_loan = is_loan_intent and not is_savings_intent
    explicit_savings = is_savings_intent and not is_loan_intent
    explicit_comparison = is_savings_intent and is_loan_intent

    return {
        "base_amount": base_amount,
        "fmt_base_amount": format_vnd(base_amount),
        "amount_source": amount_source,
        "wallet_balance": wallet_balance,
        "fmt_wallet_balance": format_vnd(wallet_balance),
        "term_years": term_years,
        "is_goal_intent": is_goal_intent,
        "is_loan_intent": explicit_loan,
        "is_savings_intent": explicit_savings,
        "is_comparison_intent": explicit_comparison,
        "savings_calc": savings_calc,
        "loan_calc": loan_calc,
        "goal_calc": goal_calc,
        "user_question": user_question,
    }


def calculate_expense_budget_allocation(
    income: float,
    rule: str = "50_30_20"
) -> Dict[str, Any]:
    """
    Phân tích ngân sách chi tiêu sinh hoạt và lập kế hoạch tài chính cá nhân PFM:
    - Quy tắc 50/30/20: 50% Nhu cầu thiết yếu, 30% Mong muốn sở thích, 20% Tiết kiệm tích lũy
    - Mô hình 6 Chiếc lọ (Jars System của T. Harv Eker): 55% NEC, 10% LTSS, 10% FFA, 10% EDU, 10% PLAY, 5% GIVE
    """
    if income <= 0:
        income = 15_000_000.0  # Mức thu nhập chuẩn trung bình khá 15 triệu VNĐ

    needs_pct = 50
    wants_pct = 30
    savings_pct = 20

    needs_amount = income * (needs_pct / 100.0)
    wants_amount = income * (wants_pct / 100.0)
    savings_amount = income * (savings_pct / 100.0)

    # Chi tiết bóc tách trong nhóm thiết yếu (Needs 50%)
    rent_home = needs_amount * 0.45      # Tiền nhà / tiền thuê trọ
    food_grocery = needs_amount * 0.35   # Tiền ăn uống nấu nướng tại nhà
    bills_utility = needs_amount * 0.12  # Hóa đơn điện nước internet
    transport = needs_amount * 0.08      # Xăng xe đi lại

    # Chi tiết bóc tách trong nhóm mong muốn (Wants 30%)
    dining_social = wants_amount * 0.40  # Cà phê, ăn ngoài với bạn bè
    shopping_cloth = wants_amount * 0.35 # Mua sắm quần áo thời trang
    entertainment = wants_amount * 0.25  # Xem phim, giải trí, du lịch

    # Mô hình 6 chiếc lọ (Jars System)
    jars = {
        "NEC": {"label": "Chi tiêu thiết yếu (NEC - 55%)", "amount": income * 0.55, "fmt": format_vnd(income * 0.55)},
        "LTSS": {"label": "Tiết kiệm dài hạn (LTSS - 10%)", "amount": income * 0.10, "fmt": format_vnd(income * 0.10)},
        "FFA": {"label": "Tự do tài chính (FFA - 10%)", "amount": income * 0.10, "fmt": format_vnd(income * 0.10)},
        "EDU": {"label": "Phát triển bản thân (EDU - 10%)", "amount": income * 0.10, "fmt": format_vnd(income * 0.10)},
        "PLAY": {"label": "Hưởng thụ giải trí (PLAY - 10%)", "amount": income * 0.10, "fmt": format_vnd(income * 0.10)},
        "GIVE": {"label": "Cho đi & Thiện nguyện (GIVE - 5%)", "amount": income * 0.05, "fmt": format_vnd(income * 0.05)},
    }

    markdown_table = (
        f"| Hạng Mục Ngân Sách | Tỷ Trọng | Số Tiền Phân Bổ | Nội Dung Chi Tiêu Cụ Thể |\n"
        f"| :--- | :---: | :---: | :--- |\n"
        f"| 🏠 **Nhu cầu thiết yếu** | **50%** | **{format_vnd(needs_amount)}** | Tiền nhà ({format_vnd(rent_home)}), Ăn uống ({format_vnd(food_grocery)}), Điện nước ({format_vnd(bills_utility)}) |\n"
        f"| ☕ **Mong muốn & Sở thích** | **30%** | **{format_vnd(wants_amount)}** | Cà phê giao lưu ({format_vnd(dining_social)}), Mua sắm ({format_vnd(shopping_cloth)}), Giải trí ({format_vnd(entertainment)}) |\n"
        f"| 💰 **Tiết kiệm & Tích lũy** | **20%** | **{format_vnd(savings_amount)}** | Gửi tiết kiệm Sen Hồng (lãi suất đến {max(rate_config.SAVINGS_RATES.values()):.1f}%/năm), Quỹ dự phòng khẩn cấp |\n"
        f"| 💵 **TỔNG THU NHẬP** | **100%** | **{format_vnd(income)}** | Ngân sách cân đối toàn diện hàng tháng |"
    )

    return {
        "income": income,
        "fmt_income": format_vnd(income),
        "needs_amount": needs_amount,
        "fmt_needs_amount": format_vnd(needs_amount),
        "wants_amount": wants_amount,
        "fmt_wants_amount": format_vnd(wants_amount),
        "savings_amount": savings_amount,
        "fmt_savings_amount": format_vnd(savings_amount),
        "jars": jars,
        "markdown_table": markdown_table,
    }
