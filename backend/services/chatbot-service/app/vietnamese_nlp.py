"""
Bộ Tiền Xử Lý Ngôn Ngữ & Chuẩn Hóa Tiếng Việt Ngân Hàng (Vietnamese Banking NLP Engine)
- Chuẩn hóa Unicode NFC (tương thích toàn diện bàn phím iOS/Android/macOS/Windows)
- Tự động sửa lỗi gõ Telex, phím dính, gõ sót ký tự tiếng Việt
- Mở rộng từ viết tắt & tiếng lóng ngành tài chính ngân hàng (stk, cskh, ck, gd, cccd, qd 2345)
- Bộ sinh gợi ý câu hỏi thông minh (Smart Contextual Quick Replies) chuẩn ngữ pháp tiếng Việt
"""

import re
import unicodedata
from typing import List, Optional, Tuple, Dict, Any, Set

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
    (r'\btiet\s+kiem\b', 'tiết kiệm'),
    (r'\btiêt\s+kiệm\b', 'tiết kiệm'),
    (r'\btiet\s+kiêm\b', 'tiết kiệm'),
    (r'\btiêt\s+kiem\b', 'tiết kiệm'),
    (r'\btieets\b', 'tiết'),
    (r'\btiets\b', 'tiết'),
    (r'\btiêt\b', 'tiết'),
    (r'\bkieemj\b', 'kiệm'),
    (r'\bkiemj\b', 'kiệm'),
    (r'\btu\s+nso\b', 'tự nó'),
    (r'\btự\s+nso\b', 'tự nó'),
    (r'\btuwj\s+nso\b', 'tự nó'),
    (r'\blaix\b', 'lãi'),
    (r'\blais\b', 'lãi'),
    (r'\bsuats\b', 'suất'),
    (r'\bsuaat\b', 'suất'),
    (r'\bsuaats\b', 'suất'),
    (r'\blãi\s+xuấy\b', 'lãi suất'),
    (r'\blai\s+xuay\b', 'lãi suất'),
    (r'\blãi\s+xuất\b', 'lãi suất'),
    (r'\blai\s+xuat\b', 'lãi suất'),
    (r'\blãi\s+xuât\b', 'lãi suất'),
    (r'\bsoor\b', 'sổ'),
    (r'\bsoos\b', 'số'),
    (r'\bthaasng\b', 'tháng'),
    (r'\bthangs\b', 'tháng'),
    (r'\bvài\s+nawkm\b', 'vài năm'),
    (r'\bnawkm\b', 'năm'),
    (r'\bnamw\b', 'năm'),
    (r'\bnaem\b', 'năm'),

    # Nhóm tài khoản, thông minh, tiền tệ
    (r'\btìa\s+kharon\b', 'tài khoản'),
    (r'\btia\s+kharon\b', 'tài khoản'),
    (r'\btìa\s+khoản\b', 'tài khoản'),
    (r'\btài\s+kharon\b', 'tài khoản'),
    (r'\btài\s+khon\b', 'tài khoản'),
    (r'\bthoogn\s+minh\b', 'thông minh'),
    (r'\bthoong\s+minh\b', 'thông minh'),
    (r'\btự\s+nso\b', 'tự nó'),
    (r'\btuwj\s+nso\b', 'tự nó'),
    (r'\bnso\b', 'nó'),
    (r'\blun\b', 'luôn'),
    (r'\btui\b', 'tôi'),
    (r'\bvvvv\b', 'vân vân'),

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
    (r'\bcic\b', 'Trung tâm Tín dụng CIC'),
    (r'\bswift(\s*code)?\b', 'SWIFT Code SENHVNVX'),
    (r'\betax(\s*mobile)?\b', 'Thuế điện tử eTax Mobile'),
    (r'\bcrm\b', 'Cây nạp tiền CRM 24/7'),
    (r'\bdiv\b', 'Bảo hiểm Tiền gửi DIV'),
]

# 3. Danh mục gợi ý chuẩn ngân hàng theo từng cụm chủ đề chuyên biệt
CURATED_SUGGESTIONS_BY_TOPIC = {
    "FINANCIAL_ADVISORY": [
        "Tính lãi gửi tiết kiệm 50 triệu trong 5 năm",
        "Lịch trả nợ vay 30 triệu theo dư nợ giảm dần",
        "So sánh gửi tiết kiệm lãi kép vs để tiền trong ví",
        "Kế hoạch tích lũy 100 triệu sau 3 năm"
    ],
    "SAVINGS": [
        "Lãi suất tiết kiệm kỳ hạn 12 tháng",
        "Gửi tiết kiệm 10 năm lãi kép được bao nhiêu?",
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
    "ACCOUNT_OPENING_DOCS": [
        "Điện thoại không có NFC có mở app được không?",
        "Bao nhiêu tuổi được mở tài khoản App Sen Hồng?",
        "Mở tài khoản định danh qua VNeID",
        "Đăng ký tài khoản ngay"
    ],
    "BCA_VNEID_EKYC": [
        "Xác thực danh tính qua VNeID mức 2",
        "Cảnh báo mua bán tài khoản theo Điều 291",
        "Quy định mở tài khoản theo Luật Căn cước",
        "Hướng dẫn quét chip CCCD"
    ],
    "TERMS_OF_SERVICE": [
        "Quy định bảo vệ dữ liệu cá nhân Nghị định 13",
        "Quyền rút lại sự đồng ý dữ liệu cá nhân",
        "Quy trình xóa hoặc đóng tài khoản",
        "Giải quyết tranh chấp tại Trọng tài VIAC"
    ],
    "MACRO_ECONOMICS": [
        "Chiến lược bảo toàn vốn trước lạm phát",
        "Kim tự tháp tài chính và Quỹ khẩn cấp",
        "Tỷ lệ trả nợ DTI an toàn là bao nhiêu?",
        "So sánh gửi tiết kiệm vs vàng vs chứng khoán"
    ],
    "GENERAL_ACCOUNT": [
        "Kiểm tra số dư ví hiện tại",
        "Nạp tiền vào ví từ ngân hàng liên kết",
        "Chọn số tài khoản đẹp phong thủy",
        "Cài đặt Biệt danh tài khoản Alias"
    ],
    "PHI_HAN_MUC": [
        "Hạn mức chuyển tiền theo cấp độ eKYC 1 và 2",
        "Cách nâng hạn mức bằng Smart OTP",
        "Biểu phí thẻ Visa và phí ngoại tệ",
        "Giao dịch nào bắt buộc quét khuôn mặt QĐ 2345?"
    ],
    "INSURANCE": [
        "Quyền lợi bảo hiểm nhân thọ An Tâm",
        "Bảo hiểm sức khỏe chi trả viện phí thế nào?",
        "Bảo hiểm du lịch quốc tế giá bao nhiêu?",
        "Quy trình bồi thường online mất mấy ngày?"
    ],
    "SME_BUSINESS": [
        "Cách chi trả lương tự động cho nhân viên",
        "Đăng ký VietQR Pro và đối soát đơn hàng",
        "Vay vốn lưu động cho hộ kinh doanh",
        "Phân quyền kế toán và duyệt lệnh 2 cấp"
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

    # 1. Hồ sơ giấy tờ Mở tài khoản App Sen Hồng (eKYC / Mở tài khoản trực tuyến / Độ tuổi / NFC mở app)
    has_account_creation = any(k in q_no_accent for k in [
        "tao app", "mo app", "tao tai khoan", "mo tai khoan", "dang ky tai khoan", "dang ky app", "mo vi", "tao vi"
    ])
    has_doc_inquiry = any(k in q_no_accent for k in [
        "giay to", "ho so", "can gi", "can nhung gi", "thu tuc", "dieu kien", "bao nhieu tuoi",
        "duoi 18 tuoi", "15 tuoi", "tuoi", "khong co nfc", "chua co nfc", "cccd", "can cuoc"
    ]) or any(k in q_no_accent for k in [
        "bao nhieu tuoi duoc mo tai khoan", "bao nhieu tuoi duoc tao app", "khong co nfc co mo app duoc khong"
    ])
    if has_account_creation and has_doc_inquiry:
        return "ACCOUNT_OPENING_DOCS"

    # 2. Sinh trắc học & QĐ 2345 (Ưu tiên cao nhất vì tính chất tuân thủ đặc thù)
    if any(k in q_no_accent for k in ["sinh trac hoc", "cccd", "nfc", "chip cccd", "2345", "khuon mat"]):
        return "BIOMETRICS"

    # 3. Bộ Công An, Đề án 06, Định danh VNeID & Phòng chống tội phạm công nghệ cao
    if any(k in q_no_accent for k in [
        "cong an", "bo cong an", "bca", "c06", "a05", "de an 06", "vneid", "dan cu quoc gia",
        "luat can cuoc", "the can cuoc", "can cuoc", "ban tai khoan", "cho thue tai khoan",
        "cho muon tai khoan", "dieu 291", "tai khoan an toan", "lenh bat"
    ]):
        return "BCA_VNEID_EKYC"

    # 4. Điều khoản dịch vụ App & Bảo vệ dữ liệu cá nhân Nghị định 13
    if any(k in q_no_accent for k in [
        "dieu khoan", "thoa thuan", "nghi dinh 13", "nd 13", "pdpa", "bao ve du lieu",
        "hop dong dien tu", "mien tru trach nhiem", "xoa tai khoan", "dong tai khoan",
        "rut lai su dong y", "phong toa tai khoan", "tam khoa tai khoan", "viac", "trong tai"
    ]):
        return "TERMS_OF_SERVICE"

    # 4. Ngữ cảnh Kinh tế Vĩ mô, Lạm phát, Phân bổ tài sản & Quản trị dòng tiền
    if any(k in q_no_accent for k in [
        "lam phat", "cpi", "mat gia", "kinh te", "vi mo", "suy thoai", "chu ky kinh te",
        "vang", "mua vang", "gia vang", "bat dong san", "bds", "chung khoan", "co phieu",
        "lai suat thuc", "lai suat dieu hanh", "dti", "ty le tra no", "vo no",
        "quan tri dong tien", "dong tien luu dong", "von luu dong", "quy khan cap",
        "phan bo tai san", "kim tu thap tai chinh", "ty gia", "ngoai te"
    ]):
        return "MACRO_ECONOMICS"

    # 5. Vay vốn & Tín chấp tiêu dùng Quick Loan (Ưu tiên hơn tiết kiệm khi có hỏi lãi suất vay)
    if any(k in q_no_accent for k in ["vay", "quick loan", "vay tien", "vay von", "tra no", "du no"]):
        return "LOANS"

    # 3. Tư vấn tài chính chuyên sâu (kết hợp cả tiết kiệm & vay hoặc kế hoạch tích lũy dài hạn)
    has_savings_term = any(k in q_no_accent for k in ["tiet kiem", "gui tien", "so tiet kiem"])
    has_long_term = any(k in q_no_accent for k in ["10 nam", "5 nam", "vai nam", "may nam", "lau dai", "lai kep"])
    if (has_savings_term and has_long_term) or "ke hoach tai chinh" in q_no_accent:
        return "FINANCIAL_ADVISORY"

    # 4. Tiết kiệm Online & Lãi suất huy động vốn
    if any(k in q_no_accent for k in [
        "tiet kiem", "lai suat", "so tiet kiem", "gui tiet kiem", "rut tiet kiem",
        "tinh lai", "tien lai", "lai bao nhieu", "ky han"
    ]):
        return "SAVINGS"

    # 5. Hóa đơn, Nạp thẻ & Vé số (Ưu tiên nhận diện trước thẻ ngân hàng để tránh nhầm thẻ cào với thẻ ATM)
    if any(k in q_no_accent for k in ["nap the", "the cao", "the game", "dien thoai", "topup", "data", "4g", "5g", "hoa don", "dien nuoc", "vietlott"]):
        return "BILLS_TOPUP"

    # 5b. Khiếu nại, tra soát & bảo vệ giao dịch (KIỂM TRA TRƯỚC NHÁNH "the" —
    # câu dạng "thẻ bị treo tiền tra soát thế nào" không bị nuốt vào CARDS)
    if any(k in q_no_accent for k in ["tra soat", "khieu nai", "chuyen nham", "nham", "hoan tien", "treo tien", "hotline", "ticket", "khiếu nại", "tra soát", "hoàn tiền"]):
        return "DISPUTE"

    # 5c. Phí & Hạn mức (domain mới) — chỉ nhận câu thuần phí/hạn mức; câu kèm từ sản phẩm
    # mạnh (thẻ/vay/tiết kiệm/napas...) giữ về domain sản phẩm để domain filter không
    # đánh rơi file kiến thức của chính sản phẩm đó (thông tin phí nằm sẵn trong file sản phẩm).
    has_product_keyword = re.search(
        r'\b(the|visa|card|atm|vay|tiet kiem|so tiet kiem|gui tiet kiem|napas|vietqr|hoa don|tien dien|the cao|data)\b',
        q_no_accent
    )
    if not has_product_keyword and (
        any(k in q_no_accent for k in [
            "bieu phi", "mien phi", "phi thuong nien", "han muc", "le phi",
            "phi chuyen", "phi rut", "phi nap", "phi giao dich", "phi duy tri",
            "phi bao tri", "phi dung", "phi thue", "phi qua dem", "phi doi no",
            "phí", "miễn phí", "hạn mức", "lệ phí"
        ]) or re.search(r'\bphi\b', q_no_accent)
    ):
        return "PHI_HAN_MUC"

    # 5f. Nạp/rút tiền mặt và nạp ví (KIỂM TRA TRƯỚC NHÁNH "the" — "rút tiền ATM không thẻ"
    # không bị nuốt vào CARDS; nhánh BILLS bên trên đã giữ riêng "nạp thẻ điện thoại")
    if any(k in q_no_accent for k in [
        "nap tien", "nap vi", "nap tien mat", "nap tien atm", "nap tien qua cay",
        "rut tien", "rut tien mat", "rut tien atm", "rut tien khong the",
        "rut tien ve ngan hang", "rut tien o cay", "nap rut tien", "rút tiền", "nạp tiền"
    ]):
        return "TRANSFER"

    # 5d. Doanh nghiệp SME, hộ kinh doanh, payroll & VietQR Pro
    if any(k in q_no_accent for k in [
        "doanh nghiep", "cong ty", "ho kinh doanh", "payroll", "tieu thuong",
        "chi tra luong", "vietqr pro"
    ]):
        return "SME_BUSINESS"

    # 5e. Bảo hiểm liên kết bancassurance (không gộp "bảo hiểm tiền gửi DIV" — thuộc SAVINGS/GENERAL)
    if any(k in q_no_accent for k in [
        "bao hiem nhan tho", "nhan tho", "bao hiem suc khoe", "bao hiem du lich",
        "bao hiem lien ket", "mua bao hiem", "phi bao hiem", "boi thuong bao hiem", "goi bao hiem"
    ]):
        return "INSURANCE"

    # 6. Thẻ ghi nợ / Tín dụng quốc tế Visa & Thẻ ảo
    # Lưu ý: "thẻ" và "thế" không dấu đều thành "the" — loại trừ cụm nghi vấn "thế nào/thế gì"
    # để câu hỏi "...thế nào?" không bị định tuyến nhầm sang CARDS (ảnh hưởng domain filter RAG).
    if any(re.search(r'\b' + re.escape(k) + r'\b', q_no_accent) for k in ["visa", "card", "the atm", "the ao"]) \
            or "phi thuong nien" in q_no_accent \
            or re.search(r'\bthe\b(?! (nao|gi))', q_no_accent):
        return "CARDS"

    # 7. Bảo mật & Xác thực giao dịch
    if any(k in q_no_accent for k in [
        "pin", "ma pin", "mat khau", "quen mat khau", "smart otp", "otp", "quen pin", "doi pin",
        "thiet bi", "bi khoa", "khoa tai khoan", "tam khoa",
        "khong nhan duoc otp", "khong nhan otp", "khong dang nhap duoc", "dang nhap khong duoc",
        "lua dao", "thu doan", "gia nhan vien", "gian lan"
    ]):
        return "SECURITY"

    # 8. Chuyển tiền Napas 24/7 & VietQR
    if any(k in q_no_accent for k in ["chuyen tien", "chuyen khoan", "napas", "vietqr", "split bill", "chia tien", "stk"]):
        return "TRANSFER"

    # 10. Ưu đãi & Điểm thưởng
    if any(k in q_no_accent for k in ["voucher", "khuyen mai", "uu dai", "giam gia", "xinchao50", "senbank9", "gioi thieu"]):
        return "PROMOTIONS"

    return "GENERAL_ACCOUNT"


# ==============================================================================
# 4. MA TRẬN ĐIỀU HƯỚNG GỢI Ý ĐA LƯỢT THEO HÀNH TRÌNH KHÁCH HÀNG (MULTI-TURN JOURNEY)
# ==============================================================================

def extract_user_queries_from_history(history: Optional[List[Any]]) -> List[str]:
    """Trích xuất toàn bộ câu hỏi trước đó của người dùng từ lịch sử hội thoại"""
    queries: List[str] = []
    if not history:
        return queries
    for msg in history:
        role = getattr(msg, "role", None) or (msg.get("role") if isinstance(msg, dict) else "")
        if role in ("user", "customer"):
            content = getattr(msg, "content", None) or (msg.get("content") if isinstance(msg, dict) else "")
            if content and isinstance(content, str) and content.strip():
                queries.append(content.strip())
    return queries


# Ma trận các giai đoạn trong từng hành trình nghiệp vụ (Journey Stages & Next Steps)
CONTEXTUAL_JOURNEY_STAGES: Dict[str, List[Dict[str, Any]]] = {
    "LOANS": [
        {
            "stage_id": "LOAN_DOCS",
            "keywords": ["giay to", "ho so", "can gi", "can nhung gi", "thu tuc", "dieu kien", "chung minh thu nhap", "bang luong"],
            "next_steps": [
                "Lãi suất vay Quick Loan bao nhiêu?",
                "Bảng tính trả nợ theo dư nợ giảm dần 30 triệu",
                "Thời gian giải ngân khoản vay Quick Loan",
                "Đăng ký vay ngay"
            ]
        },
        {
            "stage_id": "LOAN_INTEREST",
            "keywords": ["lai suat", "lai bao nhieu", "bao nhieu phan tram", "lai suat vay", "lai nam", "1.2%"],
            "next_steps": [
                "Bảng tính trả nợ theo dư nợ giảm dần 30 triệu",
                "Thời gian giải ngân khoản vay Quick Loan",
                "Phí trả nợ vay trước hạn có mất không?",
                "Đăng ký vay ngay"
            ]
        },
        {
            "stage_id": "LOAN_AMORTIZATION",
            "keywords": ["bang tinh", "lich tra no", "du no giam dan", "moi thang", "hang thang", "tra gop", "30 trieu", "50 trieu", "10 trieu"],
            "next_steps": [
                "Thời gian giải ngân khoản vay Quick Loan",
                "Phí trả nợ vay trước hạn có mất không?",
                "Đăng ký vay ngay",
                "Hạn mức vay Quick Loan tối đa"
            ]
        },
        {
            "stage_id": "LOAN_DISBURSEMENT",
            "keywords": ["giai ngan", "bao lau nhan", "khi nao nhan", "nhan tien", "nhan tien o dau"],
            "next_steps": [
                "Phí trả nợ vay trước hạn có mất không?",
                "Bảng tính trả nợ theo dư nợ giảm dần 30 triệu",
                "Đăng ký vay ngay",
                "Điều kiện vay tiêu dùng Quick Loan"
            ]
        },
        {
            "stage_id": "LOAN_PREPAYMENT",
            "keywords": ["truoc han", "tat toan", "phi phat", "phi tra no"],
            "next_steps": [
                "Bảng tính trả nợ theo dư nợ giảm dần 30 triệu",
                "Thời gian giải ngân khoản vay Quick Loan",
                "Đăng ký vay ngay",
                "Hạn mức vay Quick Loan tối đa"
            ]
        }
    ],
    "SAVINGS": [
        {
            "stage_id": "SAVINGS_RATES",
            "keywords": ["bieu lai suat", "lai suat tiet kiem", "12 thang", "6 thang", "24 thang", "bang lai suat", "lai suat cac ky han"],
            "next_steps": [
                "Tính lãi gửi tiết kiệm 50 triệu trong 5 năm",
                "Rút tiền tiết kiệm trước hạn mất bao nhiêu lãi?",
                "Chiến lược gửi tiết kiệm bậc thang",
                "Cách mở sổ tiết kiệm online trên App"
            ]
        },
        {
            "stage_id": "SAVINGS_CALC",
            "keywords": ["tinh lai", "50 trieu", "100 trieu", "lai kep", "vai nam", "5 nam", "10 nam", "duoc bao nhieu"],
            "next_steps": [
                "Rút tiền tiết kiệm trước hạn theo TT 04 có mất lãi không?",
                "Chiến lược gửi tiết kiệm bậc thang",
                "Cách mở sổ tiết kiệm online trên App",
                "So sánh kỳ hạn 12 vs 24 tháng"
            ]
        },
        {
            "stage_id": "SAVINGS_PREMATURE",
            "keywords": ["rut truoc han", "rut mot phan", "thong tu 04", "tt 04", "mat het lai", "mat bao nhieu lai"],
            "next_steps": [
                "Cách rút một phần trên app không tất toán cả sổ",
                "Chiến lược gửi tiết kiệm bậc thang",
                "Cách mở sổ tiết kiệm online trên App",
                "Lãi suất không kỳ hạn khi rút trước hạn"
            ]
        },
        {
            "stage_id": "SAVINGS_OPEN",
            "keywords": ["cach mo so", "mo so online", "mo so tiet kiem", "gui tiet kiem nhu the nao"],
            "next_steps": [
                "Lãi suất tiết kiệm kỳ hạn 12 tháng",
                "Rút tiền tiết kiệm trước hạn theo TT 04 có mất lãi không?",
                "Chiến lược gửi tiết kiệm bậc thang"
            ]
        }
    ],
    "ACCOUNT_OPENING_DOCS": [
        {
            "stage_id": "DOCS_AGE",
            "keywords": ["giay to", "ho so", "can gi", "thu tuc", "bao nhieu tuoi", "duoi 18 tuoi", "15 tuoi", "can nhung gi", "dieu kien mo"],
            "next_steps": [
                "Điện thoại không có NFC có mở app được không?",
                "Mở tài khoản định danh qua VNeID",
                "Bao nhiêu tuổi được mở tài khoản App Sen Hồng?",
                "Đăng ký tài khoản ngay"
            ]
        },
        {
            "stage_id": "NO_NFC_WORKAROUND",
            "keywords": ["khong co nfc", "chua co nfc", "khong quet duoc", "may khong co nfc", "loi nfc"],
            "next_steps": [
                "Điểm Smart Lounge gần nhất để hỗ trợ",
                "Mở tài khoản định danh qua VNeID",
                "Hạn mức giao dịch dưới 10 triệu khi chưa có NFC",
                "Đăng ký tài khoản ngay"
            ]
        },
        {
            "stage_id": "VNEID_INTEGRATION",
            "keywords": ["vneid", "dinh danh", "de an 06", "xac thuc vneid"],
            "next_steps": [
                "Điểm Smart Lounge gần nhất để hỗ trợ",
                "Đăng ký tài khoản ngay",
                "Hạn mức giao dịch sau khi mở tài khoản"
            ]
        }
    ],
    "BIOMETRICS": [
        {
            "stage_id": "QD2345_GENERAL",
            "keywords": ["2345", "sinh trac hoc", "khuon mat", "chip cccd", "quet chip"],
            "next_steps": [
                "Hạn mức giao dịch nào bắt buộc quét khuôn mặt?",
                "Điện thoại không có NFC thì cài sinh trắc học sao?",
                "Hướng dẫn đọc chip CCCD gắn chip",
                "Cài đặt sinh trắc học ngay"
            ]
        },
        {
            "stage_id": "NO_NFC_BIOMETRICS",
            "keywords": ["khong co nfc", "chua co nfc", "khong quet duoc"],
            "next_steps": [
                "Điểm Smart Lounge gần nhất để hỗ trợ",
                "Hạn mức chuyển tiền dưới 10 triệu không cần sinh trắc học",
                "Cài đặt sinh trắc học ngay"
            ]
        }
    ],
    "SECURITY": [
        {
            "stage_id": "FORGOT_PIN",
            "keywords": ["quen pin", "khoa pin", "mat pin", "lay lai pin", "cap lai pin"],
            "next_steps": [
                "Hướng dẫn đổi mã PIN giao dịch",
                "Kích hoạt Chữ ký số Smart OTP",
                "Quản lý thiết bị đã đăng nhập",
                "Cài đặt bảo mật ngay"
            ]
        },
        {
            "stage_id": "CHANGE_PIN",
            "keywords": ["doi pin", "doi ma pin", "thay doi pin"],
            "next_steps": [
                "Kích hoạt Chữ ký số Smart OTP",
                "Quản lý thiết bị đã đăng nhập",
                "Cách lấy lại mã PIN khi bị khóa",
                "Cài đặt bảo mật ngay"
            ]
        },
        {
            "stage_id": "SMART_OTP",
            "keywords": ["smart otp", "otp", "chu ky so", "thiet bi", "doi dien thoai"],
            "next_steps": [
                "Quản lý thiết bị đã đăng nhập",
                "Hướng dẫn đổi mã PIN giao dịch",
                "Hạn mức giao dịch Smart OTP"
            ]
        }
    ],
    "CARDS": [
        {
            "stage_id": "OPEN_CARD",
            "keywords": ["mo the", "the visa ao", "the ao", "tao the", "dang ky the"],
            "next_steps": [
                "Hạn mức thanh toán trực tuyến thẻ Visa",
                "Biểu phí thường niên thẻ Sen Hồng",
                "Cách khóa thẻ tạm thời trên ứng dụng",
                "Mở thẻ Visa ảo miễn phí"
            ]
        },
        {
            "stage_id": "CARD_FEES_LIMITS",
            "keywords": ["phi thuong nien", "han muc the", "phi ngoai te", "bieu phi the"],
            "next_steps": [
                "Cách khóa thẻ tạm thời trên ứng dụng",
                "Cách mở thẻ Visa ảo miễn phí",
                "Kích hoạt thanh toán quốc tế Netflix Spotify"
            ]
        },
        {
            "stage_id": "LOCK_CARD",
            "keywords": ["khoa the", "mat the", "mo khoa the", "tam khoa the"],
            "next_steps": [
                "Cách mở lại thẻ đã khóa",
                "Hotline CSKH Sen Hồng 1900 736 466",
                "Cách mở thẻ Visa ảo miễn phí"
            ]
        }
    ],
    "DISPUTE": [
        {
            "stage_id": "DISPUTE_ISSUE",
            "keywords": ["tra soat", "chuyen nham", "treo tien", "chua nhan duoc", "hoan tien", "khieu nai"],
            "next_steps": [
                "Thời gian hoàn tiền khi chuyển nhầm tài khoản",
                "Hotline CSKH Sen Hồng 1900 736 466",
                "Hướng dẫn tạo Ticket hỗ trợ khiếu nại",
                "Quy trình tra soát chuyển tiền bị treo"
            ]
        }
    ],
    "PHI_HAN_MUC": [
        {
            "stage_id": "FEES_GENERAL",
            "keywords": ["bieu phi", "phi giao dich", "phi chuyen tien", "le phi", "mien phi", "phí", "miễn phí"],
            "next_steps": [
                "Hạn mức chuyển tiền theo cấp độ eKYC 1 và 2",
                "Biểu phí thẻ Visa và phí ngoại tệ",
                "Phí nạp rút tiền mặt tại CRM",
                "Cách nâng hạn mức bằng Smart OTP"
            ]
        },
        {
            "stage_id": "LIMITS_TIER",
            "keywords": ["han muc", "ekyc", "cap 1", "cap 2", "nang han muc", "smart otp", "hạn mức"],
            "next_steps": [
                "Quy định sinh trắc học theo QĐ 2345",
                "Hạn mức thanh toán thẻ Visa",
                "Cách nâng hạn mức bằng Smart OTP",
                "Hạn mức vay Quick Loan tối đa"
            ]
        }
    ],
    "INSURANCE": [
        {
            "stage_id": "INSURANCE_PRODUCTS",
            "keywords": ["bao hiem nhan tho", "bao hiem suc khoe", "bao hiem du lich", "an tam", "cham soc plus", "bao hiểm"],
            "next_steps": [
                "Quy trình bồi thường online mất mấy ngày?",
                "Phí bảo hiểm nhân thọ một năm bao nhiêu?",
                "Hủy hợp đồng miễn phí 21 ngày thế nào?",
                "Mua bảo hiểm ngay trên app"
            ]
        },
        {
            "stage_id": "INSURANCE_CLAIM",
            "keywords": ["boi thuong", "vien phi", "hoi benh", "quyen loi", "bồi thường", "quyền lợi"],
            "next_steps": [
                "Bảo lãnh thanh toán trực tiếp bệnh viện",
                "Quyền lợi bảo hiểm nhân thọ An Tâm",
                "Mua bảo hiểm ngay trên app"
            ]
        }
    ],
    "SME_BUSINESS": [
        {
            "stage_id": "SME_ONBOARD",
            "keywords": ["mo tai khoan doanh nghiep", "dang ky doanh nghiep", "ho kinh doanh", "cong ty", "doanh nghiệp"],
            "next_steps": [
                "Cách chi trả lương tự động cho nhân viên",
                "Đăng ký VietQR Pro và đối soát đơn hàng",
                "Vay vốn lưu động cho doanh nghiệp",
                "Mở tài khoản doanh nghiệp online"
            ]
        },
        {
            "stage_id": "SME_OPERATIONS",
            "keywords": ["payroll", "chi tra luong", "vietqr pro", "doi soat", "phan quyen", "tiểu thương"],
            "next_steps": [
                "Vay vốn lưu động cho hộ kinh doanh",
                "Phân quyền kế toán và duyệt lệnh 2 cấp",
                "Đăng ký VietQR Pro và đối soát đơn hàng",
                "Báo cáo doanh thu cuối ngày"
            ]
        }
    ]
}


def is_suggestion_redundant(
    cand: str, 
    query: str, 
    user_history_queries: List[str],
    covered_stage_ids: Optional[Set[str]] = None,
    current_topic: Optional[str] = None
) -> bool:
    """
    Kiểm tra xem câu gợi ý có bị thừa thãi hoặc lặp lại những gì người dùng đã hỏi không:
    1. Trùng khớp với câu hỏi hiện tại.
    2. Trùng khớp với bất kỳ câu hỏi nào trong lịch sử hội thoại trước đó.
    3. Đã thuộc một giai đoạn (stage) mà người dùng đã hoàn thành trong lượt trước.
    """
    if not cand or not isinstance(cand, str):
        return True
    
    cand_str = cand.strip()
    if len(cand_str) < 6:
        return True

    cand_norm = strip_vietnamese_accents(cand_str)
    q_norm = strip_vietnamese_accents(query.strip())

    # 1. Trùng trực tiếp với câu hỏi hiện tại
    if cand_norm == q_norm:
        return True
    if len(cand_norm) >= 12 and len(q_norm) >= 12:
        if cand_norm in q_norm or q_norm in cand_norm:
            return True

    # 2. Trùng với các câu hỏi người dùng đã từng hỏi trong các lượt trước
    for past_q in user_history_queries:
        past_norm = strip_vietnamese_accents(past_q.strip())
        if cand_norm == past_norm:
            return True
        if len(cand_norm) >= 12 and len(past_norm) >= 12:
            if cand_norm in past_norm or past_norm in cand_norm:
                return True
        # Độ tương đồng token (Jaccard similarity)
        cand_tokens = set(cand_norm.split())
        past_tokens = set(past_norm.split())
        if len(cand_tokens) >= 3 and len(past_tokens) >= 3:
            overlap = len(cand_tokens & past_tokens)
            if overlap / len(cand_tokens) >= 0.70:
                return True

    # 3. Trùng với giai đoạn của chính câu hỏi hiện tại hoặc giai đoạn đã hỏi trong quá khứ
    stages_to_avoid = set()
    if covered_stage_ids:
        stages_to_avoid.update(covered_stage_ids)

    if stages_to_avoid and current_topic and current_topic in CONTEXTUAL_JOURNEY_STAGES:
        for stage in CONTEXTUAL_JOURNEY_STAGES[current_topic]:
            if stage["stage_id"] in stages_to_avoid:
                # Nếu câu gợi ý này là đặc trưng của giai đoạn cần tránh, loại bỏ
                if any(kw in cand_norm for kw in stage["keywords"]):
                    return True

    return False


def enrich_smart_quick_replies(
    query: str, 
    raw_replies: Optional[List[str]] = None,
    max_items: int = 3,
    history: Optional[List[Any]] = None
) -> List[str]:
    """
    Tối ưu hóa và sinh gợi ý câu hỏi (Quick Replies) dựa trên ngữ cảnh câu hỏi trước đó:
    1. Trích xuất lịch sử các câu hỏi trước của người dùng (`history`).
    2. Loại bỏ tuyệt đối các gợi ý trùng lặp ngữ nghĩa hoặc đã được hỏi ở các lượt trước.
    3. Thích ứng động theo luồng nghiệp vụ (Multi-turn Contextual Next Steps): tự động
       dự đoán bước logic tiếp theo trong hành trình của khách hàng (Vay vốn, Tiết kiệm,
       Mở app, Bảo mật, Tra soát).
    4. Chuẩn hóa viết hoa chữ cái đầu và đảm bảo độ dài ngữ pháp tiếng Việt.
    """
    clean_replies: List[str] = []
    q_clean = query.strip()
    user_queries = extract_user_queries_from_history(history)

    current_topic = detect_query_topic(q_clean)
    if current_topic == "GENERAL_ACCOUNT" and user_queries:
        for prev_q in reversed(user_queries):
            prev_topic = detect_query_topic(prev_q)
            if prev_topic != "GENERAL_ACCOUNT":
                current_topic = prev_topic
                break

    # 1. Nhận diện các giai đoạn trong lịch sử hội thoại trước đó (past_covered_stages)
    past_covered_stage_ids: Set[str] = set()
    current_stage_id: Optional[str] = None
    current_stage_obj: Optional[Dict[str, Any]] = None

    if current_topic in CONTEXTUAL_JOURNEY_STAGES:
        for stage in CONTEXTUAL_JOURNEY_STAGES[current_topic]:
            s_id = stage["stage_id"]
            # Check past queries
            for past_q in user_queries:
                u_norm = strip_vietnamese_accents(past_q)
                if any(kw in u_norm for kw in stage["keywords"]):
                    past_covered_stage_ids.add(s_id)
                    break

        # Check current query
        q_norm = strip_vietnamese_accents(q_clean)
        for stage in CONTEXTUAL_JOURNEY_STAGES[current_topic]:
            if any(kw in q_norm for kw in stage["keywords"]):
                current_stage_id = stage["stage_id"]
                current_stage_obj = stage
                break

    # Giai đoạn cần tránh gợi ý: các giai đoạn đã hỏi trong quá khứ + giai đoạn của câu hỏi hiện tại
    stages_to_avoid: Set[str] = set(past_covered_stage_ids)
    if current_stage_id:
        stages_to_avoid.add(current_stage_id)

    # 2. Làm sạch và chắt lọc các gợi ý từ phản hồi thô (raw_replies)
    #    - Gợi ý CÙNG chủ đề với câu hỏi → dùng trước (nguyên tắc đúng trọng tâm).
    #    - Gợi ý LỆCH chủ đề (LLM đôi khi sinh "Quét chip NFC" cho câu hỏi phí)
    #      chỉ được dùng nếu còn trống slot sau khi journey/curated đã lấp.
    matched_raw: List[str] = []
    unmatched_raw: List[str] = []
    if raw_replies:
        for r in raw_replies:
            if not r or not isinstance(r, str):
                continue
            r_str = r.strip()
            if not r_str:
                continue
            r_topic = detect_query_topic(r_str)
            if current_topic == "GENERAL_ACCOUNT" or r_topic in (current_topic, "GENERAL_ACCOUNT"):
                matched_raw.append(r_str)
            else:
                unmatched_raw.append(r_str)

    for r_str in matched_raw:
        if is_suggestion_redundant(
            r_str,
            q_clean,
            user_queries,
            covered_stage_ids=stages_to_avoid,
            current_topic=current_topic
        ):
            continue
        formatted_r = r_str[0].upper() + r_str[1:] if len(r_str) > 1 else r_str.upper()
        if formatted_r not in clean_replies:
            clean_replies.append(formatted_r)

    # 3. Bổ sung từ ma trận bước tiếp theo trong hành trình (Contextual Journey Next Steps)
    if len(clean_replies) < max_items and current_topic in CONTEXTUAL_JOURNEY_STAGES:
        # 3a. Ưu tiên các bước kế tiếp trực tiếp từ giai đoạn hiện tại
        if current_stage_obj:
            for step in current_stage_obj.get("next_steps", []):
                if not is_suggestion_redundant(
                    step, 
                    q_clean, 
                    user_queries, 
                    covered_stage_ids=stages_to_avoid,
                    current_topic=current_topic
                ):
                    formatted_step = step[0].upper() + step[1:] if len(step) > 1 else step.upper()
                    if formatted_step not in clean_replies:
                        clean_replies.append(formatted_step)
                if len(clean_replies) >= max_items:
                    break

        # 3b. Nếu vẫn chưa đủ, bổ sung từ các giai đoạn kế tiếp chưa từng được hỏi
        if len(clean_replies) < max_items:
            for stage in CONTEXTUAL_JOURNEY_STAGES[current_topic]:
                if stage["stage_id"] not in stages_to_avoid:
                    for step in stage.get("next_steps", []):
                        if not is_suggestion_redundant(
                            step, 
                            q_clean, 
                            user_queries, 
                            covered_stage_ids=stages_to_avoid,
                            current_topic=current_topic
                        ):
                            formatted_step = step[0].upper() + step[1:] if len(step) > 1 else step.upper()
                            if formatted_step not in clean_replies:
                                clean_replies.append(formatted_step)
                        if len(clean_replies) >= max_items:
                            break
                if len(clean_replies) >= max_items:
                    break

    # 3c. Gợi ý LỆCH chủ đề từ LLM: chỉ dùng nếu journey/curated chưa lấp đủ slot
    if len(clean_replies) < max_items:
        for r_str in unmatched_raw:
            if is_suggestion_redundant(
                r_str,
                q_clean,
                user_queries,
                covered_stage_ids=stages_to_avoid,
                current_topic=current_topic
            ):
                continue
            formatted_r = r_str[0].upper() + r_str[1:] if len(r_str) > 1 else r_str.upper()
            if formatted_r not in clean_replies:
                clean_replies.append(formatted_r)
            if len(clean_replies) >= max_items:
                break

    # 4. Nếu vẫn chưa đủ, bổ sung từ danh mục gợi ý chuẩn theo chủ đề (Curated Topic Suggestions)
    if len(clean_replies) < max_items:
        candidates = CURATED_SUGGESTIONS_BY_TOPIC.get(
            current_topic, 
            CURATED_SUGGESTIONS_BY_TOPIC["GENERAL_ACCOUNT"]
        )
        for c in candidates:
            if not is_suggestion_redundant(
                c, 
                q_clean, 
                user_queries, 
                covered_stage_ids=stages_to_avoid,
                current_topic=current_topic
            ):
                formatted_c = c[0].upper() + c[1:] if len(c) > 1 else c.upper()
                if formatted_c not in clean_replies:
                    clean_replies.append(formatted_c)
            if len(clean_replies) >= max_items:
                break

    # 5. Nếu vẫn chưa đủ (ví dụ toàn bộ câu chủ đề đã hỏi hết), dùng ngân hàng gợi ý dự phòng
    if len(clean_replies) < max_items:
        general_candidates = [
            "Kiểm tra số dư ví hiện tại",
            "Cài đặt bảo mật tài khoản",
            "Mở thẻ Visa ảo miễn phí",
            "Hotline CSKH Sen Hồng 1900 736 466"
        ]
        for gc in general_candidates:
            if not is_suggestion_redundant(gc, q_clean, user_queries):
                if gc not in clean_replies:
                    clean_replies.append(gc)
            if len(clean_replies) >= max_items:
                break

    return clean_replies[:max_items]
