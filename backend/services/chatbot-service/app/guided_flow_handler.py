"""
Guided Conversational Flow & 4-Archetype Classifier
Phân loại 4 nhóm câu hỏi & Luồng dẫn dắt nghiệp vụ Vay & Tiết Kiệm (Fintech Tier-1):
1. PERSONAL_DATA: Tra cứu dữ liệu cá nhân (Số dư, Lịch sử, eKYC)
2. PRODUCT_INFO: Thông tin sản phẩm, điều kiện, biểu phí, hạn mức
3. HOW_TO_ACTION: Hướng dẫn thao tác theo từng bước đánh số + Nút Deep-link mở màn hình
4. LEAD_ACTION: Luồng dẫn dắt khách hàng (Mục đích -> Số tiền & kỳ hạn -> Tính thử -> Disclaimer -> Đăng ký)
"""

import re
from typing import Dict, Any, List, Optional, Tuple

from app.schemas import MessageItem, ChatResponse, ActionItem
from app import rate_config
from app.financial_calculator import (
    extract_amount_from_text,
    extract_term_years_from_text,
    calculate_loan_amortization,
    calculate_savings_compound,
    format_vnd
)
from app.app_feature_catalog import find_feature_by_query
from app.vietnamese_nlp import normalize_vietnamese_query

# 4 Nhóm Ý Định Cốt Lõi
INTENT_PERSONAL_DATA = "PERSONAL_DATA"
INTENT_PRODUCT_INFO = "PRODUCT_INFO"
INTENT_HOW_TO_ACTION = "HOW_TO_ACTION"
INTENT_LEAD_ACTION = "LEAD_ACTION"


def classify_question_archetype(query: str, history: Optional[List[Any]] = None) -> str:
    """
    Phân loại câu hỏi thành 1 trong 4 nhóm ý định cốt lõi để áp dụng chiến lược xử lý riêng biệt:
    - PERSONAL_DATA: Dữ liệu cá nhân (cần gọi tool/API nội bộ)
    - HOW_TO_ACTION: Hướng dẫn thao tác (cần các bước 1-2-3 và nút bấm mở thẳng)
    - LEAD_ACTION: Ý định vay/tiết kiệm (cần luồng dẫn dắt từng bước, không trả lời cụt)
    - PRODUCT_INFO: Thông tin điều khoản, biểu phí, chính sách (RAG chuẩn)
    """
    q_norm = normalize_vietnamese_query(query.strip()).lower()

    # 1. Kiểm tra nhóm LEAD_ACTION (Khách muốn thực hiện hành động vay hoặc gửi tiết kiệm)
    lead_loan_patterns = [
        r'tôi\s+muốn\s+vay', r'em\s+muốn\s+vay', r'cần\s+vay', r'muốn\s+vay\s+tiền',
        r'đăng\s+ký\s+vay', r'làm\s+hồ\s+sơ\s+vay', r'vay\s+\d+', r'cho\s+tôi\s+vay'
    ]
    lead_savings_patterns = [
        r'tôi\s+muốn\s+gửi\s+tiết\s+kiệm', r'muốn\s+mở\s+sổ\s+tiết\s+kiệm',
        r'muốn\s+gửi\s+tiền', r'tôi\s+có\s+tiền.*gửi\s+tiết\s+kiệm', r'đăng\s+ký\s+gửi\s+tiết\s+kiệm'
    ]
    if any(re.search(p, q_norm) for p in lead_loan_patterns + lead_savings_patterns):
        return INTENT_LEAD_ACTION

    # 2. Kiểm tra nhóm PERSONAL_DATA (Dữ liệu tài khoản của người dùng)
    personal_patterns = [
        r'số\s+dư', r'so\s+du', r'tôi\s+còn\s+bao\s+nhiêu\s+tiền', r'tiền\s+trong\s+ví',
        r'lịch\s+sử\s+giao\s+dịch', r'sao\s+kê', r'giao\s+dịch\s+gần\s+đây',
        r'thông\s+tin\s+tài\s+khoản', r'hồ\s+sơ\s+của\s+tôi'
    ]
    if any(re.search(p, q_norm) for p in personal_patterns):
        return INTENT_PERSONAL_DATA

    # 3. Kiểm tra nhóm HOW_TO_ACTION (Hướng dẫn thao tác từng bước)
    # Loại trừ khi câu hỏi là tìm hiểu về điều kiện, thủ tục, lãi suất, biểu phí, hạn mức, thời gian giải ngân
    # hoặc các câu hỏi phân tích kinh tế vĩ mô, kim tự tháp tài chính, phân bổ tài sản, dòng tiền, lạm phát
    is_policy_or_terms_inquiry = any(k in q_norm for k in [
        "điều kiện", "dieu kien", "thủ tục", "thu tuc", "lãi suất", "lai suat",
        "biểu phí", "bieu phi", "hạn mức", "han muc", "giải ngân", "giai ngan",
        "hồ sơ", "ho so", "bao nhiêu", "bao nhieu", "tối đa", "toi da", "tối thiểu", "toi thieu",
        "lạm phát", "lam phat", "kim tự tháp", "kim tu thap", "phân bổ", "phan bo",
        "vàng", "vang", "chứng khoán", "chung khoan", "bất động sản", "dòng tiền",
        "dti", "quỹ dự phòng", "quy du phong", "usd", "ngoại tệ", "tại sao", "tai sao", "quy định"
    ])

    how_to_patterns = [
        r'cách\s+', r'làm\s+sao', r'thế\s+nào', r'như\s+thế\s+nào', r'hướng\s+dẫn',
        r'các\s+bước', r'thao\s+tác', r'rút\s+tiền\s+atm\s+không', r'đổi\s+mã\s+pin',
        r'lấy\s+lại\s+mã\s+pin', r'liên\s+kết\s+ngân\s+hàng', r'quên\s+mật\s+khẩu'
    ]
    if (not is_policy_or_terms_inquiry) and any(re.search(p, q_norm) for p in how_to_patterns):
        return INTENT_HOW_TO_ACTION

    # 4. Mặc định là nhóm PRODUCT_INFO (Thông tin sản phẩm, điều kiện, lãi suất, quy định)
    return INTENT_PRODUCT_INFO


class GuidedFlowHandler:
    """
    Bộ xử lý luồng dẫn dắt tài chính (Guided Financial Journey):
    - Dẫn dắt từng bước cho Vay tiêu dùng Quick Loan
    - Dẫn dắt kế hoạch gửi tiết kiệm
    - Kèm cảnh báo pháp lý minh bạch: Bot chỉ tính toán thử và tư vấn, việc phê duyệt do hệ thống thẩm định
    """
    def __init__(self, rag_engine_instance):
        self.rag = rag_engine_instance

    def handle_lead_action(
        self, 
        query: str, 
        history: Optional[List[Any]] = None, 
        user_id: Optional[str] = None
    ) -> Optional[ChatResponse]:
        """
        Tiếp nhận câu hỏi dạng LEAD_ACTION và dẫn dắt khách hàng qua từng bước:
        """
        q_norm = normalize_vietnamese_query(query.strip()).lower()

        # Kiểm tra xem đây là luồng VAY hay TIẾT KIỆM
        is_loan_lead = any(k in q_norm for k in ["vay", "quick loan", "vay tiền", "khoản vay"])
        is_savings_lead = any(k in q_norm for k in ["tiết kiệm", "tiet kiem", "sổ tiết kiệm", "gửi tiền"])

        if is_loan_lead:
            return self._handle_guided_loan_flow(query, history, user_id)
        elif is_savings_lead:
            return self._handle_guided_savings_flow(query, history, user_id)

        return None

    def _handle_guided_loan_flow(
        self, 
        query: str, 
        history: Optional[List[Any]], 
        user_id: Optional[str]
    ) -> ChatResponse:
        """
        Luồng dẫn dắt khoản vay tiêu dùng Quick Loan:
        - Bước 1 (Chưa rõ mục đích & số tiền): Hỏi mục đích sử dụng vốn
        - Bước 2 (Đã có số tiền / kỳ hạn): Tính toán trả góp chi tiết + Disclaimer thẩm định + Nút đăng ký
        """
        amt = extract_amount_from_text(query)
        if not amt and history:
            for m in reversed(history):
                content = getattr(m, "content", None) or (m.get("content") if isinstance(m, dict) else "")
                if content:
                    found_amt = extract_amount_from_text(content)
                    if found_amt:
                        amt = found_amt
                        break

        term_y = extract_term_years_from_text(query)
        term_m = 12
        if "6 tháng" in query or "6 thang" in query:
            term_m = 6
        elif "3 tháng" in query or "3 thang" in query:
            term_m = 3
        elif "24 tháng" in query or "2 năm" in query:
            term_m = 24
        elif term_y and term_y != 10:
            term_m = term_y * 12
        elif history:
            # Kiểm tra xem lịch sử có kỳ hạn tháng không
            for m in reversed(history):
                content = getattr(m, "content", None) or (m.get("content") if isinstance(m, dict) else "")
                if content:
                    c_low = content.lower()
                    if "6 tháng" in c_low or "6 thang" in c_low:
                        term_m = 6
                        break
                    elif "3 tháng" in c_low or "3 thang" in c_low:
                        term_m = 3
                        break
                    elif "24 tháng" in c_low or "2 năm" in c_low:
                        term_m = 24
                        break

        # Kiểm tra xem lịch sử trước đó đã có mục đích hoặc số tiền chưa
        purpose_found = None
        for p in ["tiêu dùng", "sinh hoạt", "mua sắm", "công nghệ", "mua xe", "sửa nhà", "kinh doanh"]:
            if p in query.lower():
                purpose_found = p
                break
        if not purpose_found and history:
            for m in reversed(history):
                content = getattr(m, "content", None) or (m.get("content") if isinstance(m, dict) else "")
                if content:
                    for p in ["tiêu dùng", "sinh hoạt", "mua sắm", "công nghệ", "mua xe", "sửa nhà", "kinh doanh"]:
                        if p in content.lower():
                            purpose_found = p
                            break
                    if purpose_found:
                        break

        has_purpose = (purpose_found is not None)

        # Lượt 1: Khách chỉ nói "tôi muốn vay", "cần vay tiền" mà chưa có số tiền cụ thể
        if not amt and not has_purpose:
            return ChatResponse(
                answer=(
                    "Dạ, Ngân hàng Số Sen Hồng rất hân hạnh được đồng hành và hỗ trợ tài chính cùng Quý khách!\n\n"
                    "Hiện tại Sen Hồng đang cung cấp gói **Vay tiêu dùng tín chấp Quick Loan**:\n"
                    "- ⚡ **Hạn mức vay:** Từ **5.000.000 VNĐ** đến **50.000.000 VNĐ**.\n"
                    "- ⏱️ **Giải ngân siêu tốc:** Trong vòng **1 phút** trực tiếp vào ví Sen Hồng sau khi duyệt online.\n"
                    "- 📊 **Lãi suất ưu đãi:** Chỉ từ **1.2%/tháng** tính trên **dư nợ giảm dần**.\n"
                    "- 🆓 **Phí tất toán trước hạn:** **Miễn phí 100%** trọn đời.\n\n"
                    "Dạ để em tư vấn phương án trả nợ tối ưu nhất, Quý khách dự định vay cho **mục đích gì** ạ?"
                ),
                sources=["Quy định vay tiêu dùng Quick Loan", "Biểu phí & Lãi suất Sen Hồng"],
                quick_replies=[
                    "Vay tiêu dùng sinh hoạt",
                    "Vay mua sắm / Đồ công nghệ",
                    "Vay 20 triệu 12 tháng",
                    "Vay 50 triệu 12 tháng"
                ],
                suggested_action=ActionItem(type="NAVIGATE", label="Xem điều kiện vay", route="/bills/quick-loan")
            )

        # Lượt 2: Khách đã nêu mục đích hoặc đã đưa số tiền (ví dụ 50 triệu, 12 tháng)
        loan_amount = amt if amt else 30_000_000.0
        # Giới hạn trần tối đa 50 triệu của gói Quick Loan
        if loan_amount > 50_000_000:
            loan_amount = 50_000_000.0
            note_limit = "*(Lưu ý: Hạn mức vay tiêu dùng tín chấp Quick Loan trực tuyến tối đa là 50.000.000 VNĐ)*\n\n"
        else:
            note_limit = ""

        # Gọi động cơ tính toán số học chuẩn xác (lãi suất đọc từ SSOT rate_config)
        calc = calculate_loan_amortization(loan_amount, term_months=term_m, rate_monthly=rate_config.DEFAULT_LOAN_MONTHLY_RATE)

        return ChatResponse(
            answer=(
                f"Dạ em xin gửi Quý khách bảng tính toán kế hoạch trả nợ ước tính cho gói **Vay tiêu dùng Quick Loan**:\n\n"
                f"{note_limit}"
                f"- 💼 **Số tiền vay:** **{format_vnd(loan_amount)}**\n"
                f"- 📅 **Thời hạn vay:** **{term_m} tháng**\n"
                f"- 📉 **Lãi suất:** **{rate_config.DEFAULT_LOAN_MONTHLY_RATE:.1f}%/tháng** (tương đương **{rate_config.DEFAULT_LOAN_MONTHLY_RATE * 12:.1f}%/năm**) tính trên **dư nợ giảm dần**\n"
                f"- 💵 **Tiền gốc trả cố định hàng tháng:** **{calc['fmt_monthly_principal']}**\n"
                f"- 📈 **Tiền trả tháng đầu tiên (cao nhất):** **{calc['fmt_first_month_payment']}** *(gốc + lãi)*\n"
                f"- 📉 **Tiền trả tháng cuối cùng (thấp nhất):** **{calc['fmt_last_month_payment']}**\n"
                f"- 💰 **Tổng tiền lãi toàn bộ {term_m} tháng:** **{calc['fmt_total_interest']}**\n"
                f"- 🆓 **Phí thẩm định & Tất toán trước hạn:** **Miễn phí 100%**\n\n"
                f"⚠️ **Lưu ý quan trọng từ Sen Hồng Bank:**\n"
                f"- *Bảng tính trên mang tính chất ước tính tham khảo.* Hạn mức phê duyệt và lãi suất chính thức sẽ do hệ thống thẩm định rủi ro tự động quyết định dựa trên hồ sơ eKYC và lịch sử tín dụng của Quý khách.\n"
                f"- Khoản vay giải ngân trực tuyến 100%, không giữ giấy tờ gốc.\n\n"
                f"Quý khách có thể bấm **Đăng ký vay ngay** bên dưới để nộp hồ sơ xét duyệt trong 30 giây ạ!"
            ),
            sources=["Quy định vay tiêu dùng Quick Loan", "Động cơ Tính toán Tài chính Sen Hồng"],
            quick_replies=["Đăng ký vay ngay", "Lịch trả nợ chi tiết", "Điều kiện duyệt khoản vay"],
            suggested_action=ActionItem(type="NAVIGATE", label="Đăng ký vay ngay", route="/bills/quick-loan")
        )

    def _handle_guided_savings_flow(
        self, 
        query: str, 
        history: Optional[List[Any]], 
        user_id: Optional[str]
    ) -> ChatResponse:
        """
        Luồng dẫn dắt gửi tiết kiệm trực tuyến:
        - Nhận biết số dư ví khả dụng của khách hàng
        - Tính toán mức sinh lời tối ưu
        - Điều hướng mở sổ trực tiếp
        """
        amt = extract_amount_from_text(query)
        if not amt and history:
            for m in reversed(history):
                content = getattr(m, "content", None) or (m.get("content") if isinstance(m, dict) else "")
                if content:
                    found_amt = extract_amount_from_text(content)
                    if found_amt:
                        amt = found_amt
                        break

        term_y = extract_term_years_from_text(query)
        if (not term_y or term_y == 10) and history:
            for m in reversed(history):
                content = getattr(m, "content", None) or (m.get("content") if isinstance(m, dict) else "")
                if content:
                    found_y = extract_term_years_from_text(content)
                    if found_y and found_y != 10:
                        term_y = found_y
                        break
        if not term_y:
            term_y = 1

        wallet_info = self.rag._fetch_user_wallet_balance(user_id) if user_id else None
        wallet_balance = float(wallet_info.get("balance", 0.0)) if wallet_info else 0.0

        if not amt:
            if wallet_balance >= 1_000_000:
                amt = wallet_balance
                intro_amt = f"Dạ ghi nhận số dư ví khả dụng hiện tại của Quý khách là **{format_vnd(amt)}**."
            else:
                amt = 50_000_000.0
                intro_amt = "Dạ với số vốn tích lũy ban đầu giả định là **50.000.000 VNĐ**:"
        else:
            intro_amt = f"Dạ với số tiền Quý khách dự định gửi là **{format_vnd(amt)}**:"

        calc = calculate_savings_compound(amt, term_years=term_y, rate_annual=rate_config.SAVINGS_RATES[12])
        t_data = calc["target_data"]

        return ChatResponse(
            answer=(
                f"{intro_amt}\n\n"
                f"Sen Hồng xin gợi ý giải pháp **Gửi Tiết Kiệm Online Lãi Kép ({term_y} năm)**:\n"
                f"- 📈 **Mức lãi suất ưu đãi:** **{rate_config.SAVINGS_RATES[12]:.1f}%/năm** (Kỳ hạn 12 tháng tự động tái tục cả gốc và lãi - Lãi nhập gốc).\n"
                f"- 💰 **Tiền lãi sinh ra sau {term_y} năm:** **{t_data['fmt_interest_savings']}**.\n"
                f"- 💎 **Tổng tài sản Quý khách nhận về:** **{t_data['fmt_total_savings']}**.\n"
                f"- 🛡️ **Bảo toàn lãi suất (TT 04/2022/TT-NHNN):** Khi cần tiền khẩn cấp, Quý khách được rút một phần tiền gốc trước hạn, phần tiền còn lại vẫn giữ nguyên lãi suất {rate_config.SAVINGS_RATES[12]:.1f}%/năm có kỳ hạn ban đầu.\n\n"
                f"⚠️ **Lưu ý:** Số liệu trên là ước tính tham khảo theo biểu lãi suất niêm yết hiện hành; điều kiện và quyết định mở sổ cuối cùng áp dụng theo quy định Sen Hồng Bank tại thời điểm giao dịch.\n\n"
                f"Quý khách có thể bấm **Mở sổ tiết kiệm ngay** bên dưới để kích hoạt sinh lời trong 30 giây ạ!"
            ),
            sources=["Biểu Lãi Suất Tiết Kiệm Sen Hồng", "Động cơ Tính toán Tài chính Sen Hồng"],
            quick_replies=["Mở sổ tiết kiệm ngay", "Chiến lược tiết kiệm bậc thang", "Biểu lãi suất 24 tháng"],
            suggested_action=ActionItem(type="NAVIGATE", label="Mở sổ tiết kiệm ngay", route="/bills/savings")
        )
