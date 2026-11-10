"""
Bộ Xử Lý Hỏi Lại Khi Mơ Hồ & Quản Lý Hội Thoại Đa Lượt (Disambiguation & Clarification Engine)
Ngân Hàng Số Sen Hồng Core Banking:
1. Phát hiện các câu hỏi ngắn, cụt, mơ hồ (underspecified) như: 'tính lãi', 'phí', 'hạn mức', 'vay', 'tiết kiệm'
2. Phản hồi hỏi lại nhã nhặn, đưa ra 2-3 lựa chọn rõ ràng kèm Quick Replies ActionChips
3. Nhận diện ngữ cảnh đa lượt (Multi-turn Context & State Tracking):
   - Kế thừa loại sản phẩm (Tiết kiệm / Vay / Thẻ) từ câu hỏi trước
   - Kế thừa số tiền (50 triệu, 100 triệu) khi khách hỏi tiếp: 'thế còn 5 năm?', 'nếu vay thì sao?'
"""

import re
from typing import Dict, Any, List, Optional, Tuple
from app import rate_config
from app.vietnamese_nlp import normalize_vietnamese_query, strip_vietnamese_accents
from app.financial_calculator import extract_amount_from_text, extract_term_years_from_text, format_vnd


# Danh mục câu hỏi ngắn mơ hồ cần làm rõ trước tiên (Disambiguation Rules)
AMBIGUOUS_PATTERNS = {
    "INTEREST": [
        r'^\s*tính\s+lãi\s*$',
        r'^\s*tinh\s+lai\s*$',
        r'^\s*lãi\s+suất\s*$',
        r'^\s*lai\s+suat\s*$',
        r'^\s*lãi\s*$',
        r'^\s*lai\s*$',
        r'^\s*tính\s+lãi\s+suất\s*$',
        r'^\s*tinh\s+lai\s+suat\s*$',
        r'^\s*cách\s+tính\s+lãi\s*$',
        r'^\s*tính\s+tiền\s+lời\s*$',
        r'^\s*tiền\s+lãi\s*$',
    ],
    "FEES": [
        r'^\s*phí\s*$',
        r'^\s*phi\s*$',
        r'^\s*biểu\s+phí\s*$',
        r'^\s*bieu\s+phi\s*$',
        r'^\s*mất\s+phí\s+không\s*$',
        r'^\s*mat\s+phi\s+khong\s*$',
        r'^\s*có\s+tốn\s+phí\s+không\s*$',
        r'^\s*thu\s+phí\s*$',
        r'^\s*phí\s+dịch\s+vụ\s*$',
        # "phí thường niên thẻ visa platinum" — câu phí kèm sản phẩm: số phí nằm trong
        # tài liệu, không cho LLM tự điền
        r'^\s*phí\s+thường\s+niên.*$',
        r'^\s*phi\s+thuong\s+nien.*$',
    ],
    "LIMITS": [
        r'^\s*hạn\s+mức\s*$',
        r'^\s*han\s+muc\s*$',
        r'^\s*giới\s+hạn\s*$',
        r'^\s*chuyển\s+tối\s+đa\s+bao\s+nhiêu\s*$',
        r'^\s*hạn\s+mức\s+bao\s+nhiêu\s*$',
        r'^\s*hạn\s+mức\s+giao\s+dịch\s*$',
        # Câu dài bắt đầu bằng "hạn mức ..." (hạn mức rút tiền ATM, hạn mức chuyển tiền ngày...)
        r'^\s*hạn\s+mức\s+\S+.*$',
        r'^\s*han\s+muc\s+\S+.*$',
        r'^\s*(rút|rut|chuyển|chuyen|nạp|nap)\b.*\b(hạn\s+mức|han\s+muc)\b.*$',
    ],
    "LOAN": [
        r'^\s*vay\s*$',
        r'^\s*vay\s+tiền\s*$',
        r'^\s*muốn\s+vay\s*$',
        r'^\s*khoản\s+vay\s*$',
        r'^\s*vay\s+vốn\s*$',
        r'^\s*vay\s+tín\s+chấp\s*$',
        r'^\s*quick\s+loan\s*$',
    ],
    "SAVINGS": [
        r'^\s*tiết\s+kiệm\s*$',
        r'^\s*tiet\s+kiem\s*$',
        r'^\s*gửi\s+tiết\s+kiệm\s*$',
        r'^\s*gui\s+tiet\s+kiem\s*$',
        r'^\s*sổ\s+tiết\s+kiệm\s*$',
        r'^\s*gửi\s+tiền\s*$',
        r'^\s*mở\s+sổ\s*$',
        # "mở sổ tiết kiệm tối thiểu bao nhiêu tiền" — số tối thiểu phải lấy từ dữ liệu, không cho LLM bịa
        r'^\s*mở\s+sổ\s+\S+.*$',
        r'^\s*mo\s+so\s+\S+.*$',
        r'^\s*(gửi|gui)\s+(tiết\s+kiệm|tiet\s+kiem)\s+\S+.*$',
    ],
    "CARDS": [
        r'^\s*thẻ\s*$',
        r'^\s*the\s*$',
        r'^\s*thẻ\s+visa\s*$',
        r'^\s*mở\s+thẻ\s*$',
        r'^\s*làm\s+thẻ\s*$',
        r'^\s*thẻ\s+tín\s+dụng\s*$',
    ]
}


def check_ambiguous_query(query: str) -> Optional[Dict[str, Any]]:
    """
    Kiểm tra xem câu hỏi có thuộc nhóm ngắn/cụt/mơ hồ cần hỏi lại không.
    Nếu có, trả về ngay cấu trúc phản hồi định hướng hỏi lại lịch sự.
    """
    if not query:
        return None

    q_norm = normalize_vietnamese_query(query.strip())
    q_no_accent = strip_vietnamese_accents(q_norm).strip()

    # 1. Mơ hồ về Lãi suất / Tính lãi (Interest Disambiguation)
    for pat in AMBIGUOUS_PATTERNS["INTEREST"]:
        if re.search(pat, q_norm, re.IGNORECASE) or re.search(pat, q_no_accent, re.IGNORECASE):
            return {
                "answer": (
                    "Dạ, Quý khách muốn tính lãi cho khoản nào tại **Sen Hồng Bank** ạ?\n\n"
                    f"- 💰 **1. Lãi Tiết Kiệm Online:** Sinh lời vượt trội lên đến **{rate_config.SAVINGS_RATES[24]:.1f}%/năm**, nhận lãi định kỳ hoặc tái tục lãi kép tự động.\n"
                    f"- 💼 **2. Lãi Khoản Vay Tiêu Dùng (Quick Loan):** Lãi suất ưu đãi từ **{rate_config.DEFAULT_LOAN_MONTHLY_RATE:.1f}%/tháng** (**{rate_config.DEFAULT_LOAN_MONTHLY_RATE * 12:.1f}%/năm**) tính trên dư nợ giảm dần.\n"
                    "- 💳 **3. Lãi Thẻ Tín Dụng Visa:** Miễn lãi tối đa lên đến **45 ngày**, không tính lãi nếu thanh toán đúng hạn.\n\n"
                    "Quý khách vui lòng chọn nhanh bên dưới hoặc nhắn số tiền và kỳ hạn để em tính toán chi tiết ngay nhé ạ!"
                ),
                "quick_replies": ["Lãi tiết kiệm online", "Lãi vay Quick Loan", "Lãi thẻ tín dụng Visa"],
                "suggested_action": {"label": "Biểu lãi suất ngân hàng", "route": "/bills/savings"},
                "disambiguation_type": "INTEREST"
            }

    # 2. Mơ hồ về Biểu phí (Fees Disambiguation)
    for pat in AMBIGUOUS_PATTERNS["FEES"]:
        if re.search(pat, q_norm, re.IGNORECASE) or re.search(pat, q_no_accent, re.IGNORECASE):
            return {
                "answer": (
                    "Dạ, Quý khách đang quan tâm đến biểu phí của dịch vụ nào tại **Sen Hồng Bank** ạ?\n\n"
                    "- ⚡ **1. Phí Chuyển Tiền Napas 247:** Miễn phí 100% trọn đời (cả nội bộ và liên ngân hàng).\n"
                    "- 💳 **2. Phí Phát Hành & Thường Niên Thẻ Visa:** Miễn phí phát hành thẻ ảo, miễn phí thường niên năm đầu.\n"
                    "- 🏧 **3. Phí Nạp / Rút Tiền Mặt:** Miễn phí 100% nạp rút từ ngân hàng liên kết và tại cây ATM đối tác Napas.\n"
                    "- 📱 **4. Phí Quản Lý Tài Khoản / Biến Động Số Dư:** Miễn phí hoàn toàn qua thông báo App.\n\n"
                    "Quý khách có thể bấm chọn nhanh dịch vụ bên dưới để xem biểu phí chi tiết ạ!"
                ),
                "quick_replies": ["Phí chuyển tiền Napas 247", "Phí thường niên thẻ Visa", "Phí rút tiền ATM", "Biểu phí tổng hợp"],
                "suggested_action": {"label": "Xem biểu phí chi tiết", "route": "/support/help-center"},
                "disambiguation_type": "FEES"
            }

    # 3. Mơ hồ về Hạn mức (Limits Disambiguation)
    for pat in AMBIGUOUS_PATTERNS["LIMITS"]:
        if re.search(pat, q_norm, re.IGNORECASE) or re.search(pat, q_no_accent, re.IGNORECASE):
            return {
                "answer": (
                    "Dạ, Quý khách muốn kiểm tra hạn mức cho dịch vụ nào tại **Sen Hồng Bank** ạ?\n\n"
                    "- ⚡ **1. Hạn Mức Chuyển Tiền / Giao Dịch Ngày:**\n"
                    "   - *eKYC Cấp 1 (SĐT + OTP):* Tối đa **5.000.000 VNĐ/ngày**.\n"
                    "   - *eKYC Cấp 2 (CCCD gắn chip + Face ID):* Tối đa **50.000.000 VNĐ/ngày** (mở rộng lên **500.000.000 VNĐ/ngày** khi cài Smart OTP).\n"
                    "   - *Quyết định 2345/QĐ-NHNN:* Giao dịch trên **10.000.000 VNĐ/lần** hoặc **20.000.000 VNĐ/ngày** bắt buộc xác thực sinh trắc học khuôn mặt khớp chip CCCD.\n"
                    "- 💼 **2. Hạn Mức Vay Nhanh Quick Loan:** Từ **5.000.000 VNĐ** đến **50.000.000 VNĐ**.\n"
                    "- 💳 **3. Hạn Mức Thanh Toán Thẻ Visa:** Lên đến **100.000.000 VNĐ/giao dịch**.\n\n"
                    "Quý khách có thể chọn nhanh bên dưới để xem quy định hạn mức chi tiết nhé ạ!"
                ),
                "quick_replies": ["Hạn mức chuyển tiền ngày", "Hạn mức vay Quick Loan", "Nâng hạn mức Smart OTP"],
                "suggested_action": {"label": "Cấp độ tài khoản & Hạn mức", "route": "/profile/kyc-level"},
                "disambiguation_type": "LIMITS"
            }

    # 4. Mơ hồ về Vay vốn (Loan Disambiguation)
    for pat in AMBIGUOUS_PATTERNS["LOAN"]:
        if re.search(pat, q_norm, re.IGNORECASE) or re.search(pat, q_no_accent, re.IGNORECASE):
            return {
                "answer": (
                    "Dạ, Quý khách đang có nhu cầu vay vốn tại **Sen Hồng Bank** đúng không ạ?\n\n"
                    "Hiện ngân hàng đang triển khai gói **Vay tiêu dùng Quick Loan** siêu tiện lợi:\n"
                    f"- 💰 **Hạn mức linh hoạt:** Từ **{format_vnd(rate_config.QUICK_LOAN_MIN)}** đến **{format_vnd(rate_config.QUICK_LOAN_MAX)}**.\n"
                    "- 🕒 **Thời hạn vay:** Từ **3 tháng, 6 tháng, 12 tháng đến 24 tháng**.\n"
                    f"- 📉 **Lãi suất ưu đãi:** Chỉ từ **{rate_config.DEFAULT_LOAN_MONTHLY_RATE:.1f}%/tháng** tính trên **dư nợ giảm dần**.\n"
                    "- ⚡ **Giải ngân siêu tốc:** 1 phút về thẳng ví sau khi duyệt hồ sơ online, không thế chấp tài sản.\n\n"
                    "Quý khách dự kiến muốn vay khoảng bao nhiêu tiền và trong mấy tháng để em tính thử lịch trả nợ cho mình nhé ạ!"
                ),
                "quick_replies": ["Vay 10 triệu trong 6 tháng", "Vay 30 triệu trong 12 tháng", "Điều kiện đăng ký vay"],
                "suggested_action": {"label": "Đăng ký Vay nhanh", "route": "/bills/quick-loan"},
                "disambiguation_type": "LOAN"
            }

    # 5. Mơ hồ về Tiết kiệm (Savings Disambiguation)
    for pat in AMBIGUOUS_PATTERNS["SAVINGS"]:
        if re.search(pat, q_norm, re.IGNORECASE) or re.search(pat, q_no_accent, re.IGNORECASE):
            return {
                "answer": (
                    "Dạ, Quý khách đang muốn tìm hiểu về gửi tiết kiệm tại **Sen Hồng Bank** ạ?\n\n"
                    "Ngân hàng hiện có 2 hình thức tiết kiệm online sinh lời hấp dẫn:\n"
                    f"- 📈 **1. Tiết kiệm Có kỳ hạn:** Gửi từ **1.000.000 VNĐ**, kỳ hạn từ 1 đến 36 tháng (lãi suất cao nhất **{rate_config.SAVINGS_RATES[24]:.1f}%/năm**), hỗ trợ tái tục lãi kép tự động.\n"
                    "- 🎯 **2. Tiết kiệm Tích lũy gửi góp:** Cho phép nạp thêm tiền bất cứ lúc nào từ **100.000 VNĐ/lần**, rất phù hợp cho mục tiêu tích lũy đều đặn.\n\n"
                    "Quý khách dự định gửi khoảng bao nhiêu tiền và gửi trong bao lâu để em lập bảng tính tiền lời chi tiết cho mình ạ?"
                ),
                "quick_replies": ["Gửi 50 triệu 12 tháng", "Gửi 100 triệu 5 năm lãi kép", "Mở sổ tiết kiệm online"],
                "suggested_action": {"label": "Mở sổ tiết kiệm ngay", "route": "/bills/savings"},
                "disambiguation_type": "SAVINGS"
            }

    # 6. Mơ hồ về Thẻ (Cards Disambiguation)
    for pat in AMBIGUOUS_PATTERNS["CARDS"]:
        if re.search(pat, q_norm, re.IGNORECASE) or re.search(pat, q_no_accent, re.IGNORECASE):
            return {
                "answer": (
                    "Dạ, Quý khách đang quan tâm đến dòng thẻ nào của **Sen Hồng Bank** ạ?\n\n"
                    "- 💳 **1. Thẻ ảo Visa Platinum Virtual:** Phát hành tức thì trong 30 giây, miễn phí phát hành & thường niên 100%, bảo mật CVV động thanh toán quốc tế.\n"
                    "- 🏦 **2. Thẻ ghi nợ Napas liên kết:** Liên kết tài khoản ngân hàng nội địa để nạp rút tiền 24/7 hoàn toàn miễn phí.\n\n"
                    "Quý khách muốn mở thẻ mới hay quản lý thẻ hiện có ạ?"
                ),
                "quick_replies": ["Mở thẻ Visa ảo 30 giây", "Liên kết ngân hàng Napas", "Quản lý thẻ của tôi"],
                "suggested_action": {"label": "Quản lý thẻ", "route": "/cards"},
                "disambiguation_type": "CARDS"
            }

    return None


def extract_term_months_from_text(text: str) -> Optional[int]:
    """Trích xuất số tháng: 6 tháng, 3 tháng, 12 tháng, 24 tháng..."""
    if not text:
        return None
    t = text.lower()
    m_match = re.search(r'(\d+)\s*(?:tháng|thang|m|months?)\b', t)
    if m_match:
        try:
            return int(m_match.group(1))
        except ValueError:
            pass
    return None


def extract_context_from_history(
    history: Optional[List[Any]],
    client_context: Optional[Dict[str, Any]] = None
) -> Dict[str, Any]:
    """
    Theo dõi và trích xuất ngữ cảnh hội thoại đa lượt chuyên sâu (Multi-turn Context & State Tracking):
    - Đang bàn về sản phẩm gì (SAVINGS, LOANS, CARDS, TRANSFER, WITHDRAW, DEPOSIT, PIN, EKYC, BILLS)?
    - Số tiền đã đề cập trước đó ($P)?
    - Số năm / kỳ hạn đã đề cập trước đó?
    - Câu hỏi dở dang từ bot (pending_clarification): bot vừa hỏi mục đích, kỳ hạn hay số tiền?
    - Ngữ cảnh màn hình đang đứng từ client_context (Flutter Mobile app)
    """
    context: Dict[str, Any] = {
        "last_topic": None,
        "last_amount": None,
        "last_term_years": None,
        "last_term_months": None,
        "last_purpose": None,
        "pending_clarification": None,
        "consecutive_fallbacks": 0,
        "client_screen": None
    }

    # 1. Trích xuất ngữ cảnh từ Client (Mobile App) nếu có
    if client_context and isinstance(client_context, dict):
        cur_screen = client_context.get("current_screen") or ""
        context["client_screen"] = cur_screen
        if cur_screen:
            cs_low = cur_screen.lower()
            if any(k in cs_low for k in ["quick-loan", "loan", "vay"]):
                context["last_topic"] = "LOANS"
            elif any(k in cs_low for k in ["saving", "tiet-kiem", "tiet_kiem"]):
                context["last_topic"] = "SAVINGS"
            elif any(k in cs_low for k in ["card", "the"]):
                context["last_topic"] = "CARDS"
            elif any(k in cs_low for k in ["transfer", "chuyen-tien"]):
                context["last_topic"] = "TRANSFER"
            elif any(k in cs_low for k in ["atm", "withdrawal"]):
                context["last_topic"] = "WITHDRAW"
            elif any(k in cs_low for k in ["deposit", "nap-tien"]):
                context["last_topic"] = "DEPOSIT"
            elif any(k in cs_low for k in ["pin"]):
                context["last_topic"] = "PIN"
            elif any(k in cs_low for k in ["nfc", "ekyc"]):
                context["last_topic"] = "EKYC"
            elif any(k in cs_low for k in ["bill", "hoa-don"]):
                context["last_topic"] = "BILLS"

    if not history:
        return context

    # 2. Xác định câu hỏi dở dang (pending_clarification) từ phản hồi trợ lý AI gần nhất
    last_assistant_msg = ""
    for msg in reversed(history):
        r = getattr(msg, "role", None) or (msg.get("role") if isinstance(msg, dict) else "")
        if r in ("assistant", "bot"):
            last_assistant_msg = getattr(msg, "content", None) or (msg.get("content") if isinstance(msg, dict) else "")
            break

    if last_assistant_msg:
        la_low = last_assistant_msg.lower()
        if "mục đích gì" in la_low or "mục đích sử dụng vốn" in la_low:
            context["pending_clarification"] = "WAITING_FOR_LOAN_PURPOSE"
        elif "bao nhiêu tiền và trong mấy tháng" in la_low or "khoảng bao nhiêu tiền và trong mấy tháng" in la_low:
            context["pending_clarification"] = "WAITING_FOR_LOAN_AMOUNT_TERM"
        elif "bao nhiêu tiền và gửi trong bao lâu" in la_low or "bao nhiêu tiền và trong bao lâu" in la_low:
            context["pending_clarification"] = "WAITING_FOR_SAVINGS_AMOUNT_TERM"
        elif "muốn tính lãi cho khoản nào" in la_low:
            context["pending_clarification"] = "WAITING_FOR_INTEREST_CATEGORY"
        elif "tra cứu biểu phí cho dịch vụ nào" in la_low:
            context["pending_clarification"] = "WAITING_FOR_FEE_CATEGORY"
        elif "kiểm tra hạn mức cho dịch vụ nào" in la_low:
            context["pending_clarification"] = "WAITING_FOR_LIMIT_CATEGORY"
        elif "quan tâm đến dòng thẻ nào" in la_low:
            context["pending_clarification"] = "WAITING_FOR_CARD_TYPE"

    # 3. Duyệt ngược lịch sử hội thoại để trích xuất thực thể
    for msg in reversed(history):
        content = getattr(msg, "content", None) or (msg.get("content") if isinstance(msg, dict) else "")
        role = getattr(msg, "role", None) or (msg.get("role") if isinstance(msg, dict) else "")
        if not content:
            continue

        c_lower = content.lower()

        # Đếm số lần fallback liên tiếp nếu có dấu hiệu bot báo không tìm thấy thông tin
        if role in ("assistant", "bot"):
            if any(k in c_lower for k in ["chưa tìm thấy thông tin", "chưa có thông tin", "không tìm thấy", "liên hệ hotline"]):
                context["consecutive_fallbacks"] += 1
            else:
                context["consecutive_fallbacks"] = 0

        # Trích xuất chủ đề đang thảo luận (ưu tiên tin nhắn gần nhất)
        if not context["last_topic"]:
            if any(k in c_lower for k in ["tiết kiệm", "tiet kiem", "gửi tiền", "sổ tiết kiệm", "lãi kép", "tích lũy"]):
                context["last_topic"] = "SAVINGS"
            elif any(k in c_lower for k in ["vay", "quick loan", "khoản vay", "nợ", "mượn tiền", "trả nợ", "dư nợ"]):
                context["last_topic"] = "LOANS"
            elif any(k in c_lower for k in ["thẻ", "the", "visa", "platinum", "thẻ ảo"]):
                context["last_topic"] = "CARDS"
            elif any(k in c_lower for k in ["chuyển tiền", "chuyen tien", "napas", "bắn tiền"]):
                context["last_topic"] = "TRANSFER"
            elif any(k in c_lower for k in ["rút tiền", "rut tien", "rút atm", "atm"]):
                context["last_topic"] = "WITHDRAW"
            elif any(k in c_lower for k in ["nạp tiền", "nap tien", "nạp ví"]):
                context["last_topic"] = "DEPOSIT"
            elif any(k in c_lower for k in ["mã pin", "đổi pin", "quên pin", "pin"]):
                context["last_topic"] = "PIN"
            elif any(k in c_lower for k in ["nfc", "cccd", "ekyc", "căn cước"]):
                context["last_topic"] = "EKYC"
            elif any(k in c_lower for k in ["hóa đơn", "hoa don", "tiền điện", "tiền nước"]):
                context["last_topic"] = "BILLS"

        # Trích xuất mục đích vay nếu có
        if not context["last_purpose"] and context["last_topic"] == "LOANS":
            for p in ["tiêu dùng", "sinh hoạt", "mua sắm", "công nghệ", "kinh doanh", "mua xe", "sửa nhà", "du lịch"]:
                if p in c_lower:
                    context["last_purpose"] = p
                    break

        # Trích xuất số tiền đã nhắc tới
        if not context["last_amount"]:
            amt = extract_amount_from_text(content)
            if amt and amt > 0:
                context["last_amount"] = amt

        # Trích xuất thời hạn năm
        if not context["last_term_years"]:
            y = extract_term_years_from_text(content)
            if y and y != 10:  # Không lấy giá trị mặc định 10
                context["last_term_years"] = y

        # Trích xuất thời hạn tháng
        if not context["last_term_months"]:
            m = extract_term_months_from_text(content)
            if m:
                context["last_term_months"] = m

    return context


def enrich_query_with_context(
    query: str,
    history_context: Dict[str, Any]
) -> str:
    """
    Kế thừa thông tin từ lượt chat trước để câu sau không bị 'mất trí nhớ':
    1. Tiếp tục luồng dẫn dắt (Pending Clarification Resolution)
    2. Kế thừa thuộc tính (Phí, Hạn mức, Cách làm, Điều kiện...)
    3. Chuyển đổi sản phẩm 2 chiều (Vay <-> Tiết kiệm)
    4. Kế thừa số tiền & kỳ hạn (Continuation Term & Amount)
    """
    q_clean = query.strip()
    q_lower = q_clean.lower()

    last_topic = history_context.get("last_topic")
    last_amount = history_context.get("last_amount")
    pending = history_context.get("pending_clarification")

    # =========================================================================
    # A. PHẢN HỒI THEO CÂU HỎI CHỜ (PENDING CLARIFICATION RESOLUTION)
    # =========================================================================
    if pending == "WAITING_FOR_LOAN_PURPOSE":
        purpose_keywords = [
            "tiêu dùng", "sinh hoạt", "mua sắm", "công nghệ", "kinh doanh",
            "mua xe", "sửa nhà", "du lịch", "đóng học phí", "cá nhân", "chi tiêu"
        ]
        if any(p in q_lower for p in purpose_keywords) or q_lower.startswith("để ") or q_lower.startswith("cho "):
            amt_phrase = f" {last_amount:,.0f} VNĐ".replace(",", ".") if last_amount else ""
            return f"tôi muốn vay tiêu dùng{amt_phrase} Quick Loan cho mục đích {q_clean}"
        amt = extract_amount_from_text(query)
        if amt:
            return f"tôi muốn vay {q_clean} Quick Loan tiêu dùng"

    if pending == "WAITING_FOR_LOAN_AMOUNT_TERM":
        amt = extract_amount_from_text(query)
        if amt:
            return f"tôi muốn vay {q_clean} Quick Loan"

    if pending == "WAITING_FOR_SAVINGS_AMOUNT_TERM":
        amt = extract_amount_from_text(query)
        if amt:
            return f"tôi muốn gửi tiết kiệm {q_clean}"
        if any(t in q_lower for t in ["tháng", "thang", "năm", "nam"]):
            amt_phrase = f" với số tiền {last_amount:,.0f} VNĐ".replace(",", ".") if last_amount else ""
            return f"tính lãi gửi tiết kiệm kỳ hạn {q_clean}{amt_phrase}"

    if pending == "WAITING_FOR_INTEREST_CATEGORY":
        if any(k in q_lower for k in ["tiết kiệm", "tiet kiem", "gửi tiền"]):
            return "tính lãi suất gửi tiết kiệm online"
        if any(k in q_lower for k in ["vay", "quick loan"]):
            return "tính lãi suất khoản vay tiêu dùng Quick Loan"
        if any(k in q_lower for k in ["thẻ", "the", "visa"]):
            return "quy định lãi suất và thời gian miễn lãi thẻ tín dụng Visa"

    if pending == "WAITING_FOR_FEE_CATEGORY":
        if any(k in q_lower for k in ["chuyển tiền", "chuyen tien", "napas"]):
            return "biểu phí chuyển tiền Napas 24/7"
        if any(k in q_lower for k in ["thẻ", "the", "visa"]):
            return "biểu phí phát hành và thường niên thẻ visa platinum"
        if any(k in q_lower for k in ["rút tiền", "rút atm", "atm"]):
            return "biểu phí rút tiền ATM không dùng thẻ"
        if any(k in q_lower for k in ["tiết kiệm", "tiet kiem"]):
            return "phí mở sổ và tất toán tiết kiệm online"
        if any(k in q_lower for k in ["vay", "quick loan"]):
            return "phí thẩm định và tất toán trước hạn khoản vay Quick Loan"

    if pending == "WAITING_FOR_LIMIT_CATEGORY":
        if any(k in q_lower for k in ["chuyển tiền", "chuyen tien", "napas"]):
            return "hạn mức chuyển tiền Napas 24/7 theo từng cấp độ eKYC"
        if any(k in q_lower for k in ["rút tiền", "rút atm", "atm"]):
            return "hạn mức rút tiền ATM bằng mã QR tối đa một ngày"
        if any(k in q_lower for k in ["vay", "quick loan"]):
            return "hạn mức gói vay tiêu dùng Quick Loan tối đa"
        if any(k in q_lower for k in ["thẻ", "the", "visa"]):
            return "hạn mức chi tiêu thanh toán thẻ Visa Platinum"

    if pending == "WAITING_FOR_CARD_TYPE":
        if any(k in q_lower for k in ["visa", "ảo", "platinum", "quốc tế"]):
            return "thẻ ảo quốc tế Visa Platinum Virtual"
        if any(k in q_lower for k in ["napas", "nội địa", "ghi nợ", "liên kết"]):
            return "thẻ và tài khoản ngân hàng liên kết Napas"

    # =========================================================================
    # B. KẾ THỪA THUỘC TÍNH (FEE, LIMIT, HOW-TO, CONDITIONS) TỪ CHỦ ĐỀ TRƯỚC
    # =========================================================================
    # 1. Hỏi về phí (Fee inheritance)
    is_fee_query = any(k in q_lower for k in ["phí", "phi", "mất phí", "tốn phí", "biểu phí", "tính phí"])
    if is_fee_query and len(q_clean.split()) <= 6:
        if last_topic == "CARDS":
            return "biểu phí phát hành và phí thường niên thẻ visa platinum"
        elif last_topic == "TRANSFER":
            return "chuyển tiền Napas 24/7 có mất phí không"
        elif last_topic == "WITHDRAW":
            return "phí rút tiền ATM không dùng thẻ là bao nhiêu"
        elif last_topic == "LOANS":
            return "phí thẩm định và phí tất toán trước hạn khoản vay Quick Loan"
        elif last_topic == "SAVINGS":
            return "phí mở và tất toán sổ tiết kiệm online"

    # 2. Hỏi về hạn mức (Limit inheritance)
    is_limit_query = any(k in q_lower for k in ["hạn mức", "han muc", "tối đa bao nhiêu", "được bao nhiêu", "giới hạn"])
    if is_limit_query and len(q_clean.split()) <= 6:
        if last_topic == "LOANS":
            return "hạn mức vay tiêu dùng Quick Loan tối đa là bao nhiêu"
        elif last_topic == "TRANSFER":
            return "hạn mức chuyển tiền Napas 24/7 một ngày tối đa bao nhiêu"
        elif last_topic == "WITHDRAW":
            return "hạn mức rút tiền ATM tối đa một ngày"
        elif last_topic == "SAVINGS":
            return "hạn mức gửi tiết kiệm online tối thiểu và tối đa"
        elif last_topic == "CARDS":
            return "hạn mức thanh toán thẻ Visa Platinum"

    # 3. Hỏi về điều kiện, thủ tục (Condition / Requirement inheritance)
    is_cond_query = any(k in q_lower for k in ["điều kiện", "dieu kien", "thủ tục", "thu tuc", "cần gì", "hồ sơ"])
    if is_cond_query and len(q_clean.split()) <= 6:
        if last_topic == "LOANS":
            return "điều kiện và hồ sơ đăng ký vay tiêu dùng Quick Loan"
        elif last_topic == "CARDS":
            return "điều kiện mở thẻ Visa Platinum Virtual"
        elif last_topic == "SAVINGS":
            return "điều kiện mở sổ tiết kiệm online"
        elif last_topic == "EKYC":
            return "điều kiện xác thực sinh trắc học NFC CCCD"

    # 4. Hỏi về cách thao tác (How-to inheritance)
    is_howto_query = any(k in q_lower for k in ["cách làm", "làm sao", "làm thế nào", "hướng dẫn", "các bước", "đăng ký thế nào"])
    if is_howto_query and len(q_clean.split()) <= 6:
        if last_topic == "CARDS":
            return "hướng dẫn cách mở thẻ ảo Visa Platinum Virtual"
        elif last_topic == "LOANS":
            return "hướng dẫn các bước đăng ký vay Quick Loan"
        elif last_topic == "SAVINGS":
            return "hướng dẫn các bước mở sổ tiết kiệm online"
        elif last_topic == "WITHDRAW":
            return "hướng dẫn cách rút tiền ATM không cần thẻ"
        elif last_topic == "TRANSFER":
            return "hướng dẫn cách chuyển tiền Napas 24/7"
        elif last_topic == "PIN":
            return "hướng dẫn đổi mã PIN giao dịch"
        elif last_topic == "EKYC":
            return "hướng dẫn đọc chip NFC Căn cước công dân"

    # 5. Chuyển đổi sản phẩm 2 chiều (Cross-product pivot)
    if any(k in q_lower for k in ["thế còn vay", "thế nếu vay", "vậy vay thì sao", "còn vay thì sao"]):
        amt_phrase = f" với số tiền {last_amount:,.0f} VNĐ".replace(",", ".") if last_amount else ""
        return f"tính lãi khoản vay tiêu dùng Quick Loan{amt_phrase}"
    if any(k in q_lower for k in ["thế còn tiết kiệm", "thế nếu gửi tiết kiệm", "vậy tiết kiệm thì sao", "còn gửi tiết kiệm"]):
        amt_phrase = f" với số tiền {last_amount:,.0f} VNĐ".replace(",", ".") if last_amount else ""
        return f"tính lãi gửi tiết kiệm online{amt_phrase}"

    # =========================================================================
    # C. KẾ THỪA THỜI HẠN & SỐ TIỀN (TERM & AMOUNT CONTINUATION)
    # =========================================================================
    has_continuation = any(p in q_lower for p in ["thế còn", "the con", "nếu", "neu", "còn", "con", "thế nếu", "vậy nếu"])
    has_term = any(t in q_lower for t in ["năm", "nam", "tháng", "thang"])

    if (has_continuation or has_term) and last_amount and not extract_amount_from_text(query):
        amt_fmt = f"{last_amount:,.0f} VNĐ".replace(",", ".")
        topic_phrase = "tiết kiệm" if last_topic == "SAVINGS" else ("vay" if last_topic == "LOANS" else "")
        return f"{query} với số tiền {amt_fmt} {topic_phrase}".strip()

    # Nhập gọn số tiền ('50 triệu', '100tr')
    extracted_amt = extract_amount_from_text(query)
    if extracted_amt and len(query.strip().split()) <= 4:
        if last_topic == "SAVINGS":
            return f"tính lãi gửi tiết kiệm {query}"
        elif last_topic == "LOANS":
            return f"tôi muốn vay {query} tiêu dùng Quick Loan"
        elif last_topic == "TRANSFER":
            return f"chuyển tiền {query}"

    return query
