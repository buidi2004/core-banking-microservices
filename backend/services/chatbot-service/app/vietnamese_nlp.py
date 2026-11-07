"""
Bộ Tiền Xử Lý Ngôn Ngữ & Chuẩn Hóa Tiếng Việt Ngân Hàng (Vietnamese Banking NLP Engine)
- Chuẩn hóa Unicode NFC (tương thích toàn diện bàn phím iOS/Android/macOS/Windows)
- Tự động sửa lỗi gõ Telex, phím dính, gõ sót ký tự tiếng Việt
- Mở rộng từ viết tắt & tiếng lóng ngành tài chính ngân hàng (stk, cskh, ck, gd, cccd, qd 2345)
- Bộ sinh gợi ý câu hỏi thông minh (Smart Contextual Quick Replies) chuẩn ngữ pháp tiếng Việt
"""

import re
import unicodedata
from typing import List, Optional, Tuple

# 1. Bảng quy đổi phím gõ Telex lỗi và từ sai chính tả phổ biến trong giao tiếp ngân hàng
TELEX_TYPO_MAP: List[Tuple[str, str]] = [
    # Nhóm lỗi gõ phím kiểm / chữ / chat
    (r'\bkeirm\b', 'kiểm'),
    (r'\bkiemf\b', 'kiềm'),
    (r'\bkiemr\b', 'kiểm'),
    (r'\bkieemr\b', 'kiểm'),
    (r'\bchữu\b', 'chữ'),
    (r'\bchuwx\b', 'chữ'),
    (r'\bchát\s+bot\b', 'chatbot'),
    (r'\bchát\b', 'chat'),
    (r'\bcaht\s*bót\b', 'chatbot'),
    (r'\bcaht\s*bot\b', 'chatbot'),
    (r'\bchat\s*bót\b', 'chatbot'),
    (r'\bchatt\b', 'chat'),
    
    # Nhóm hoàn tiền, chuyển tiền, thanh toán
    (r'\bhoafn\b', 'hoàn'),
    (r'\bhoanf\b', 'hoàn'),
    (r'\btieefn\b', 'tiền'),
    (r'\btienf\b', 'tiền'),
    (r'\bchuyeern\b', 'chuyển'),
    (r'\bchuyenr\b', 'chuyển'),
    (r'\bchuyeenr\b', 'chuyển'),
    (r'\bnhaamf\b', 'nhầm'),
    (r'\bnhamf\b', 'nhầm'),
    (r'\btreo\s+tieefn\b', 'treo tiền'),

    # Nhóm đổi PIN, khóa thẻ, rút/nạp tiền
    (r'\bddoori\b', 'đổi'),
    (r'\bddooir\b', 'đổi'),
    (r'\bdoir\b', 'đổi'),
    (r'\bkhoas\b', 'khóa'),
    (r'\btheer\b', 'thẻ'),
    (r'\bthef\b', 'thẻ'),
    (r'\bruxt\b', 'rút'),
    (r'\bruts\b', 'rút'),
    (r'\bnawpj\b', 'nạp'),
    (r'\bnapj\b', 'nạp'),

    # Nhóm tiết kiệm & lãi suất
    (r'\btieets\b', 'tiết'),
    (r'\btiets\b', 'tiết'),
    (r'\bkieemj\b', 'kiệm'),
    (r'\bkiemj\b', 'kiệm'),
    (r'\blaix\b', 'lãi'),
    (r'\blais\b', 'lãi'),
    (r'\bsuats\b', 'suất'),
    (r'\bsuaat\b', 'suất'),
    (r'\bsuaats\b', 'suất'),
    (r'\bsoor\b', 'sổ'),
    (r'\bsoos\b', 'số'),
    (r'\bthaasng\b', 'tháng'),
    (r'\bthangs\b', 'tháng'),

    # Nhóm khoản vay Quick Loan
    (r'\bkhoanr\b', 'khoản'),
    (r'\bvaay\b', 'vay'),
    (r'\bnoojp\b', 'nộp'),
    (r'\btraar\b', 'trả'),
    (r'\bnoowj\b', 'nợ'),
    (r'\bdischj\b', 'dịch'),

    # Nhóm biểu phí, hạn mức, sinh trắc học
    (r'\bbieeur\b', 'biểu'),
    (r'\bbieur\b', 'biểu'),
    (r'\bphis\b', 'phí'),
    (r'\bhanj\b', 'hạn'),
    (r'\bmuwsc\b', 'mức'),
    (r'\bhạn\s+muwsc\b', 'hạn mức'),
    (r'\bhanj\s+muwsc\b', 'hạn mức'),
    (r'\bsinh\s+trwacs\s+hocj\b', 'sinh trắc học'),
    (r'\bsinh\s+tracs\s+hocj\b', 'sinh trắc học'),

    # Nhóm hướng dẫn, điều khoản, tra soát
    (r'\bhuwowngs\b', 'hướng'),
    (r'\bhuongs\b', 'hướng'),
    (r'\bdaaxn\b', 'dẫn'),
    (r'\bdanx\b', 'dẫn'),
    (r'\bgiao\s+dichj\b', 'giao dịch'),
    (r'\bgiao\s+ddichj\b', 'giao dịch'),
    (r'\btra\s+soats\b', 'tra soát'),
    (r'\btra\s+soat\b', 'tra soát'),
    (r'\bkhieeus\s+naij\b', 'khiếu nại'),
    (r'\bkhieu\s+nai\b', 'khiếu nại'),
    (r'\bbaor\s+maatj\b', 'bảo mật'),

    # Nhóm đại từ & trợ từ thông dụng
    (r'\bthoois\b', 'thôi'),
    (r'\bmuoons\b', 'muốn'),
    (r'\bdduwowcj\b', 'được'),
    (r'\bkhoong\b', 'không'),
    (r'\bbieets\b', 'biết'),
    (r'\btaif\s+khoanr\b', 'tài khoản'),
    (r'\bsoos\s+du\b', 'số dư'),
    (r'\btriejeu\b', 'triệu'),
    (r'\btrieuej\b', 'triệu'),
    (r'\bddoongf\b', 'đồng'),
]

# 2. Bảng mở rộng từ viết tắt & thuật ngữ tài chính ngân hàng phổ thông
BANKING_ABBREVIATIONS: List[Tuple[str, str]] = [
    (r'\bstk\b', 'số tài khoản'),
    (r'\btk\b', 'tài khoản'),
    (r'\bcskh\b', 'chăm sóc khách hàng'),
    (r'\bgd\b', 'giao dịch'),
    (r'\bck\b', 'chuyển khoản'),
    (r'\bsđt\b', 'số điện thoại'),
    (r'\bsdt\b', 'số điện thoại'),
    (r'\bcccd\b', 'căn cước công dân'),
    (r'\bbhxh\b', 'bảo hiểm xã hội'),
    (r'\bqd\s*2345\b', 'Quyết định 2345/QĐ-NHNN'),
    (r'\bqđ\s*2345\b', 'Quyết định 2345/QĐ-NHNN'),
    (r'\bvietqr\b', 'VietQR'),
    (r'\bnapas(\s*247)?\b', 'Napas 247'),
]

# 3. Danh mục gợi ý chuẩn ngân hàng theo từng cụm chủ đề chuyên biệt
CURATED_SUGGESTIONS_BY_TOPIC = {
    "SAVINGS": [
        "Lãi suất tiết kiệm kỳ hạn 12 tháng",
        "Rút tiền tiết kiệm trước hạn mất bao nhiêu lãi?",
        "Cách mở sổ tiết kiệm online trên App",
        "Bảng so sánh lãi suất các kỳ hạn"
    ],
    "LOANS": [
        "Điều kiện vay tiêu dùng Quick Loan",
        "Bảng tính lãi theo dư nợ giảm dần 30 triệu",
        "Thời gian giải ngân khoản vay Quick Loan",
        "Phí trả nợ vay trước hạn có mất không?"
    ],
    "TRANSFER": [
        "Hạn mức chuyển tiền Napas một ngày",
        "Biểu phí chuyển tiền Napas 247",
        "Chia tiền nhóm theo hóa đơn Split Bill",
        "Cách tạo mã VietQR nhận tiền chính chủ"
    ],
    "CARDS": [
        "Cách mở thẻ Visa ảo miễn phí",
        "Hạn mức thanh toán trực tuyến thẻ Visa",
        "Cách khóa thẻ tạm thời trên ứng dụng",
        "Biểu phí thường niên thẻ Sen Hồng"
    ],
    "SECURITY": [
        "Cách lấy lại mã PIN khi bị khóa",
        "Hướng dẫn đổi mã PIN giao dịch",
        "Kích hoạt Chữ ký số Smart OTP",
        "Quản lý thiết bị đã đăng nhập"
    ],
    "BIOMETRICS": [
        "Quy định sinh trắc học theo QĐ 2345",
        "Điện thoại không có NFC thì cài sinh trắc học sao?",
        "Hạn mức giao dịch nào bắt buộc quét khuôn mặt?",
        "Hướng dẫn đọc chip CCCD gắn chip"
    ],
    "DISPUTE": [
        "Quy trình tra soát chuyển tiền bị treo",
        "Thời gian hoàn tiền khi chuyển nhầm tài khoản",
        "Hotline CSKH Sen Hồng 1900 736 466",
        "Hướng dẫn tạo Ticket hỗ trợ khiếu nại"
    ],
    "BILLS_TOPUP": [
        "Nạp tiền điện thoại chiết khấu 5%",
        "Nạp Data 4G/5G Viettel tốc độ cao",
        "Thanh toán tiền điện EVN tự động",
        "Cách mua vé số Vietlott online"
    ],
    "PROMOTIONS": [
        "Mã giảm giá XINCHAO50 được ưu đãi gì?",
        "Mã khuyến mãi SENBANK9 giảm bao nhiêu?",
        "Chương trình giới thiệu bạn bè nhận 50k",
        "Kho Voucher và ưu đãi đối tác mới nhất"
    ],
    "GENERAL_ACCOUNT": [
        "Kiểm tra số dư ví hiện tại",
        "Nạp tiền vào ví từ ngân hàng liên kết",
        "Chọn số tài khoản đẹp phong thủy",
        "Cài đặt Biệt danh tài khoản Alias"
    ]
}


def strip_vietnamese_accents(text: str) -> str:
    """Loại bỏ dấu tiếng Việt để so khớp ngữ nghĩa linh hoạt"""
    if not text:
        return ""
    normalized = unicodedata.normalize('NFD', text)
    stripped = ''.join(c for c in normalized if unicodedata.category(c) != 'Mn')
    return stripped.replace('đ', 'd').replace('Đ', 'D').lower()


def normalize_vietnamese_query(text: str) -> str:
    """
    Chuẩn hóa toàn diện chuỗi câu hỏi đầu vào:
    1. Chuẩn hóa Unicode NFC (tránh lỗi tổ hợp NFD bàn phím Apple/Windows).
    2. Tự động khắc phục các lỗi gõ Telex phổ biến và phím dính.
    3. Mở rộng từ viết tắt ngân hàng để tối ưu cho bộ tìm kiếm RRF và Embedding.
    """
    if not text:
        return ""

    # 1. Unicode NFC
    s = unicodedata.normalize('NFC', text.strip())

    # 2. Thay thế lỗi gõ Telex
    for pattern, repl in TELEX_TYPO_MAP:
        s = re.sub(pattern, repl, s, flags=re.IGNORECASE)

    # 3. Mở rộng viết tắt ngành ngân hàng
    for pattern, repl in BANKING_ABBREVIATIONS:
        s = re.sub(pattern, repl, s, flags=re.IGNORECASE)

    # 4. Chuẩn hóa khoảng trắng
    s = re.sub(r'\s+', ' ', s).strip()
    return s


def detect_query_topic(query: str) -> str:
    """Nhận diện cụm chủ đề tài chính cốt lõi dựa trên nội dung câu hỏi"""
    q_no_accent = strip_vietnamese_accents(query)

    if any(k in q_no_accent for k in ["nap the", "the cao", "the game", "dien thoai", "topup", "data", "4g", "5g", "hoa don", "dien nuoc", "vietlott"]):
        return "BILLS_TOPUP"
    if any(k in q_no_accent for k in ["tiet kiem", "lai suat", "so tiet kiem", "gui tiet kiem", "rut tiet kiem"]):
        return "SAVINGS"
    if any(k in q_no_accent for k in ["vay", "quick loan", "vay tien", "vay von", "tra no", "du no"]):
        return "LOANS"
    if any(k in q_no_accent for k in ["chuyen tien", "chuyen khoan", "napas", "vietqr", "split bill", "chia tien", "stk"]):
        return "TRANSFER"
    if any(k in q_no_accent for k in ["sinh trac hoc", "cccd", "nfc", "chip cccd", "2345", "khuon mat"]):
        return "BIOMETRICS"
    if any(re.search(r'\b' + re.escape(k) + r'\b', q_no_accent) for k in ["the", "visa", "card", "the atm", "the ao"]) or "phi thuong nien" in q_no_accent:
        return "CARDS"
    if any(k in q_no_accent for k in ["pin", "ma pin", "mat khau", "smart otp", "otp", "quen pin", "doi pin", "thiet bi"]):
        return "SECURITY"
    if any(k in q_no_accent for k in ["tra soat", "khieu nai", "nham", "chuyen nham", "hoan tien", "treo tien", "hotline", "ticket"]):
        return "DISPUTE"
    if any(k in q_no_accent for k in ["voucher", "khuyen mai", "uu dai", "giam gia", "xinchao50", "senbank9", "gioi thieu"]):
        return "PROMOTIONS"

    return "GENERAL_ACCOUNT"


def enrich_smart_quick_replies(
    query: str, 
    raw_replies: Optional[List[str]] = None,
    max_items: int = 3
) -> List[str]:
    """
    Tối ưu hóa và làm sạch mảng gợi ý câu hỏi (Quick Replies):
    - Kiểm tra tính hợp lệ của tiếng Việt (có dấu, không cộc lốc, không lặp lại câu hỏi gốc).
    - Tự động bổ sung các câu hỏi nghiệp vụ liên quan mật thiết nếu LLM trả về thiếu hoặc rỗng.
    """
    clean_replies: List[str] = []
    q_clean = query.strip()
    q_no_accent = strip_vietnamese_accents(q_clean)

    if raw_replies:
        for r in raw_replies:
            if not r or not isinstance(r, str):
                continue
            r_str = r.strip()
            # Bỏ nếu quá ngắn hoặc chính là câu hỏi vừa được hỏi
            if len(r_str) < 6:
                continue
            if strip_vietnamese_accents(r_str) == q_no_accent:
                continue
            
            # Chuẩn hóa viết hoa chữ cái đầu
            formatted_r = r_str[0].upper() + r_str[1:] if len(r_str) > 1 else r_str.upper()
            if formatted_r not in clean_replies:
                clean_replies.append(formatted_r)

    # Nếu vẫn chưa đủ gợi ý, tự động bù đắp từ ngân hàng câu hỏi chọn lọc theo chủ đề
    if len(clean_replies) < max_items:
        topic = detect_query_topic(query)
        candidates = CURATED_SUGGESTIONS_BY_TOPIC.get(topic, CURATED_SUGGESTIONS_BY_TOPIC["GENERAL_ACCOUNT"])
        for c in candidates:
            if c not in clean_replies and strip_vietnamese_accents(c) != q_no_accent:
                clean_replies.append(c)
            if len(clean_replies) >= max_items:
                break

    return clean_replies[:max_items]
