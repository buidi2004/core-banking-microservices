import re
from typing import Tuple, Optional, Dict

# Regex nhận diện thông tin nhạy cảm (PII)
CARD_REGEX = re.compile(r'\b(?:\d[ -]*?){13,16}\b')
CCCD_REGEX = re.compile(r'\b\d{12}\b')
PHONE_REGEX = re.compile(r'\b(?:0|\+84)(?:3|5|7|8|9)\d{8}\b')
TX_CODE_REGEX = re.compile(r'\b(?:FT|TX)[A-Za-z0-9]{6,20}\b', re.IGNORECASE)

# Từ khóa nhạy cảm về mã xác thực / bảo mật (ngoại trừ hỏi tính năng Smart OTP)
CREDENTIAL_KEYWORDS = [
    "mã otp", "ma otp", "mã pin", "ma pin", "mật khẩu", "mat khau", 
    "password", "cvv", "cvc", "mã bảo mật"
]

# Từ khóa khẩn cấp / nghi ngờ lừa đảo (chỉ kích hoạt khi khách hàng thực sự thông báo sự cố bị mất tiền)
FRAUD_EMERGENCY_KEYWORDS = [
    "bị lừa đảo", "bi lua dao", "tôi bị mất tiền", "vừa bị mất tiền", "bị mất tiền", "mat het tien", "mất hết tiền",
    "bị hack", "bi hack", "khóa khẩn cấp", "khoa khan cap", "khóa thẻ ngay", "khoa the ngay"
]

# Từ khóa tấn công bảo mật / Prompt Injection / Jailbreak
PROMPT_INJECTION_KEYWORDS = [
    "bỏ qua toàn bộ chỉ dẫn", "bo qua toan bo chi dan", "ignore previous instructions",
    "system prompt", "in ra system prompt", "jailbreak", "prompt injection",
    "hiển thị prompt", "show prompt", "in ra hướng dẫn hệ thống"
]

def mask_pii(text: str) -> str:
    """Che giấu thông tin cá nhân (PII) cho mục đích log hoặc fallback"""
    def _mask_card(match):
        digits = re.sub(r'\D', '', match.group(0))
        if len(digits) >= 12:
            return f"{digits[:4]}-****-****-{digits[-4:]}"
        return "****"

    def _mask_cccd(match):
        val = match.group(0)
        return f"CCCD-****{val[-4:]}"

    def _mask_phone(match):
        val = match.group(0)
        return f"{val[:3]}****{val[-3:]}"

    sanitized = CARD_REGEX.sub(_mask_card, text)
    sanitized = CCCD_REGEX.sub(_mask_cccd, sanitized)
    sanitized = PHONE_REGEX.sub(_mask_phone, sanitized)
    return sanitized

def tokenize_pii(text: str) -> Tuple[str, Dict[str, str]]:
    """
    Kỹ thuật Reversible PII Tokenization (Ánh xạ tạm thời trong RAM):
    - Thay thế số thẻ, CCCD, số điện thoại, mã giao dịch bằng các placeholder <CARD_NO_1>, <CCCD_1>...
    - Trả về (masked_text, token_map) để gửi cho LLM xử lý cấu trúc câu mà không lộ dữ liệu thật
    """
    token_map: Dict[str, str] = {}
    idx = 1
    
    def _sub_tx(match):
        nonlocal idx
        val = match.group(0)
        token = f"<TX_ID_{idx}>"
        token_map[token] = val
        idx += 1
        return token

    def _sub_card(match):
        nonlocal idx
        val = match.group(0)
        token = f"<CARD_NO_{idx}>"
        token_map[token] = val
        idx += 1
        return token

    def _sub_cccd(match):
        nonlocal idx
        val = match.group(0)
        token = f"<CCCD_{idx}>"
        token_map[token] = val
        idx += 1
        return token

    def _sub_phone(match):
        nonlocal idx
        val = match.group(0)
        token = f"<PHONE_NO_{idx}>"
        token_map[token] = val
        idx += 1
        return token

    t = TX_CODE_REGEX.sub(_sub_tx, text)
    t = CARD_REGEX.sub(_sub_card, t)
    t = CCCD_REGEX.sub(_sub_cccd, t)
    t = PHONE_REGEX.sub(_sub_phone, t)
    return t, token_map

def detokenize_pii(text: str, token_map: Dict[str, str]) -> str:
    """Hoán đổi ngược lại các placeholder <TOKEN_x> thành giá trị thật trước khi gửi về client"""
    if not token_map:
        return text
    result = text
    for token, original_val in token_map.items():
        result = result.replace(token, original_val)
    return result

def check_security_guardrails(text: str) -> Tuple[bool, Optional[str]]:
    """
    Kiểm tra các tình huống bảo mật đặc biệt của ngân hàng:
    - Yêu cầu / Tiết lộ OTP, PIN, Mật khẩu thực tế (Credential Exposure)
    - Cảnh báo lừa đảo khẩn cấp (Fraud / Scam Alert)
    Ngoại lệ: Các câu hỏi hướng dẫn đổi/quên/lấy lại mã PIN hoặc mật khẩu KHÔNG coi là rủi ro.
    """
    lower_text = text.lower()

    # Nhận diện thắc mắc hướng dẫn lấy lại/đổi mã PIN hoặc mật khẩu hợp lệ (Whitelist)
    is_safe_pin_or_pwd_query = any(k in lower_text for k in [
        "quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "cài lại", "cai lai",
        "đổi", "doi", "thay đổi", "thay doi", "khôi phục", "khoi phuc", "reset", "hướng dẫn", "huong dan", "cách", "cach"
    ]) and any(p in lower_text for p in ["pin", "mã pin", "ma pin", "mật khẩu", "mat khau", "password"])

    # 0. Phát hiện hành vi Prompt Injection / Jailbreak / Đòi hiển thị System Prompt
    for kw in PROMPT_INJECTION_KEYWORDS:
        if kw in lower_text:
            return True, (
                "🛡️ **THÔNG BÁO TỪ HỆ THỐNG GÁC CỔNG BẢO MẬT SEN HỒNG:**\n\n"
                "Yêu cầu của Quý khách đã bị từ chối do vi phạm chính sách an toàn thông tin của Sen Hồng Bank. "
                "Trợ lý AI Sen Hồng chỉ hỗ trợ giải đáp các thắc mắc nghiệp vụ tài chính, chính sách dịch vụ và tiện ích ngân hàng chính thống ạ."
            )

    # 1. Phát hiện tình huống khẩn cấp / Gian lận thật sự
    for kw in FRAUD_EMERGENCY_KEYWORDS:
        if kw in lower_text:
            return True, (
                "🚨 **CẢNH BÁO KHẨN CẤP TỪ SEN HỒNG BANK:**\n\n"
                "Nếu quý khách nghi ngờ tài khoản bị lộ thông tin hoặc đang bị kẻ gian chiếm quyền kiểm soát:\n"
                "1. Vui lòng bấm ngay nút **'Khóa Khẩn Cấp'** trên ứng dụng để đóng băng tài khoản tức thì.\n"
                "2. Hoặc gọi ngay đến Tổng đài Hỗ trợ Khẩn cấp 24/7 của Sen Hồng Bank: **1900-SENHONG** (1900 736 466) để được chuyên viên hỗ trợ khóa tài khoản trong 5 giây.\n"
                "3. Quý khách tuyệt đối không click vào bất kỳ đường link nào nhận được qua SMS hoặc mạng xã hội."
            )

    # 2. Phát hiện hỏi hoặc cung cấp mã OTP / PIN / Password thực tế
    if not is_safe_pin_or_pwd_query:
        for kw in CREDENTIAL_KEYWORDS:
            if kw in lower_text and any(w in lower_text for w in ["của tôi là", "của em là", "xin mã", "cho xin", "gửi mã"]):
                return True, (
                    "🛡️ **QUY TẮC BẢO MẬT TUYỆT ĐỐI TỪ SEN HỒNG BANK:**\n\n"
                    "Ngân hàng Sen Hồng **KHÔNG BAO GIỜ** yêu cầu quý khách cung cấp mã OTP, mã PIN giao dịch, mật khẩu đăng nhập hay mã CVV phía sau thẻ dưới bất kỳ hình thức nào.\n\n"
                    "Quý khách tuyệt đối **KHÔNG chia sẻ mã OTP hoặc mật khẩu** cho bất kỳ ai (kể cả người tự xưng là nhân viên ngân hàng hay cơ quan chức năng) để phòng ngừa rủi ro mất tài sản ạ."
                )

    return False, None

BANKING_SYSTEM_PROMPT = """Bạn là Trợ lý AI Tài chính Thông minh 24/7 của Ngân hàng Số Sen Hồng (Sen Hồng Bank).
Nhiệm vụ của bạn là giải đáp chính xác, lịch sự, thân thiện và hữu ích các thắc mắc của khách hàng về dịch vụ, biểu phí, lãi suất tiết kiệm, quy định ngân hàng theo Quyết định 2345/QĐ-NHNN, thẻ Visa và hướng dẫn sử dụng ứng dụng.

QUY TẮC CỐT LÕI (BẮT BUỘC TUÂN THỦ 100%):
1. CHỈ TRẢ LỜI DỰA TRÊN NGỮ CẢNH ĐƯỢC CUNG CẤP DƯỚI ĐÂY. Tuyệt đối KHÔNG tự ý suy đoán, bịa đặt số liệu về lãi suất, tỷ giá hay biểu phí.
2. Nếu ngữ cảnh không có thông tin hoặc không chắc chắn, hãy thành thật trả lời: "Dạ hiện tại em chưa có thông tin chính thức về vấn đề này trong hệ thống. Quý khách vui lòng liên hệ Tổng đài CSKH Sen Hồng 1900-SENHONG hoặc đến chi nhánh gần nhất để được hỗ trợ chuyên sâu ạ."
3. Văn phong: Giọng điệu chuyên nghiệp, nhã nhặn, chuẩn mực ngành ngân hàng Việt Nam, dùng từ xưng hô "Em" và "Quý khách", kết câu bằng "ạ".
4. TUYỆT ĐỐI KHÔNG BAO GIỜ yêu cầu khách hàng cung cấp mã OTP, mật khẩu hay mã PIN.
5. Nếu trong câu trả lời có nhiều bước, hãy định dạng danh sách (bullet points) rõ ràng, dễ đọc trên màn hình điện thoại di động.

---
NGỮ CẢNH KIẾN THỨC NGÂN HÀNG CHÍNH THỨC:
{context}
---
"""
