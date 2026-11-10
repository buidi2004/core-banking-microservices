import time
import math
import logging
import unicodedata
from enum import Enum
from typing import Dict, Any, List, Optional, Tuple
from pydantic import BaseModel, Field

from app.vietnamese_nlp import normalize_vietnamese_query, strip_vietnamese_accents, detect_query_topic

logger = logging.getLogger("jev_system_one")


def strip_accents(text: str) -> str:
    """Loại bỏ dấu tiếng Việt để so khớp từ khóa không dấu chính xác trên Mobile"""
    if not text:
        return ""
    text = unicodedata.normalize('NFD', text)
    text = ''.join(c for c in text if unicodedata.category(c) != 'Mn')
    return text.replace('đ', 'd').replace('Đ', 'D').lower()


class IntentChoice(str, Enum):
    BALANCE_INQUIRY = "BALANCE_INQUIRY"         # Tra cứu số dư ví / tài khoản cá nhân
    TRANSACTION_HISTORY = "TRANSACTION_HISTORY" # Tra cứu lịch sử giao dịch, biến động số dư, người gửi/nhận
    PROFILE_INQUIRY = "PROFILE_INQUIRY"         # Tra cứu thông tin hồ sơ cá nhân, eKYC, SĐT, Alias
    CARDS_INQUIRY = "CARDS_INQUIRY"             # Tra cứu thẻ Visa, thẻ ngân hàng cá nhân
    SAVINGS_INQUIRY = "SAVINGS_INQUIRY"         # Tra cứu sổ tiết kiệm cá nhân đang gửi
    LOANS_INQUIRY = "LOANS_INQUIRY"             # Tra cứu khoản vay cá nhân và lịch trả nợ
    REMINDERS_INQUIRY = "REMINDERS_INQUIRY"     # Tra cứu lịch tài chính, nhắc nhở định kỳ cá nhân
    FINANCIAL_OVERVIEW = "FINANCIAL_OVERVIEW"   # Tổng quan tài chính 360 độ cá nhân
    POLICY_RAG = "POLICY_RAG"                   # Tra cứu biểu phí, lãi suất, quy định QĐ 2345
    ACTION_NAVIGATION = "ACTION_NAVIGATION"     # Yêu cầu thực hiện hành động (chuyển tiền, mở thẻ, gửi tiết kiệm)
    SECURITY_EMERGENCY = "SECURITY_EMERGENCY"   # Báo mất tiền, nghi lừa đảo, khóa thẻ khẩn cấp
    CREDENTIAL_EXPOSURE = "CREDENTIAL_EXPOSURE" # Nghi vấn lộ hoặc đòi mã OTP, PIN, mật khẩu
    GENERAL_CHITCHAT = "GENERAL_CHITCHAT"       # Chào hỏi, trò chuyện thông thường


class GateAction(str, Enum):
    ALLOW_RAG = "ALLOW_RAG"                             # Cho phép chuyển tiếp sang System Two (LLM Gemini)
    DIVERT_INTERNAL_WALLET = "DIVERT_INTERNAL_WALLET"   # Rẽ nhánh sang microservice nội bộ ví (Zero-LLM leak)
    DIVERT_INTERNAL_TRANSACTIONS = "DIVERT_INTERNAL_TRANSACTIONS" # Rẽ nhánh sang microservice giao dịch & đối tác
    DIVERT_INTERNAL_PROFILE = "DIVERT_INTERNAL_PROFILE" # Rẽ nhánh sang microservice hồ sơ & eKYC cá nhân
    DIVERT_INTERNAL_CARDS = "DIVERT_INTERNAL_CARDS"     # Rẽ nhánh sang microservice thẻ cá nhân
    DIVERT_INTERNAL_SAVINGS = "DIVERT_INTERNAL_SAVINGS" # Rẽ nhánh sang microservice sổ tiết kiệm cá nhân
    DIVERT_INTERNAL_LOANS = "DIVERT_INTERNAL_LOANS"     # Rẽ nhánh sang microservice khoản vay cá nhân
    DIVERT_INTERNAL_REMINDERS = "DIVERT_INTERNAL_REMINDERS" # Rẽ nhánh sang hệ thống nhắc nhở tài chính cá nhân hóa
    DIVERT_INTERNAL_OVERVIEW = "DIVERT_INTERNAL_OVERVIEW" # Rẽ nhánh tổng quan tài chính 360 độ
    INTERCEPT_EMERGENCY = "INTERCEPT_EMERGENCY"         # Kích hoạt quy trình khóa tài khoản khẩn cấp
    BLOCK_CREDENTIAL_THEFT = "BLOCK_CREDENTIAL_THEFT"   # Chặn câu hỏi đòi/cung cấp thông tin nhạy cảm
    FAST_NAVIGATE = "FAST_NAVIGATE"                     # Trả ngay nút điều hướng nhanh không cần qua LLM


class JevDecision(BaseModel):
    """
    Cấu trúc phản hồi chuẩn của Jev (Mô hình System One - TypeSafe AI):
    - Không sinh văn bản tự nhiên (Non-autoregressive).
    - Trả về Choice (Lựa chọn), Score (Xác suất chuẩn hóa) và RiskScore (Mức độ rủi ro).
    - Cung cấp tín hiệu gác cổng (Gatekeeper) điều khiển luồng phần mềm.
    """
    choice: IntentChoice = Field(..., description="Quyết định phân nhánh logic của System One")
    score: float = Field(..., ge=0.0, le=1.0, description="Độ tin cậy của lựa chọn (Calibrated Score)")
    risk_score: float = Field(..., ge=0.0, le=1.0, description="Xác suất rủi ro bảo mật (Risk Assessment)")
    gate_action: GateAction = Field(..., description="Hành động gác cổng phần mềm được kích hoạt")
    domain: Optional[str] = Field(None, description="Chủ đề nghiệp vụ từ detect_query_topic (LOANS, SAVINGS, PHI_HAN_MUC...) để tái sử dụng cho domain filter RAG")
    suggested_route: Optional[str] = Field(None, description="Đường dẫn điều hướng trên App (nếu có)")
    suggested_label: Optional[str] = Field(None, description="Nhãn nút bấm gợi ý")
    execution_time_ms: float = Field(..., description="Thời gian thực thi của System One (< 15ms)")


class JevSystemOneGatekeeper:
    """
    Mô phỏng & Hiện thực hóa Kiến trúc Jev (System One của TypeSafe AI)
    trong Ngân hàng Số Sen Hồng:
    
    1. Tối ưu định tuyến và điều khiển: Trả về Choice, Score, GateAction thay vì sinh văn bản.
    2. Giảm chi phí & độ trễ: Đưa ra quyết định trung gian trong 5-12ms, tiết kiệm 100% token LLM.
    3. Tạo lớp gác cổng an toàn (Safety Gatekeeper): Đánh giá rủi ro trước khi gọi System Two.
    4. Không thay thế code cứng: Chạy song song sau lớp Regex PII & Security Guardrails cốt lõi.
    """
    def __init__(self):
        # Mẫu tham chiếu (Exemplar prototypes) cho từng Intent để tính điểm tương đồng vector
        self.intent_prototypes: Dict[IntentChoice, List[str]] = {
            IntentChoice.BALANCE_INQUIRY: [
                "số dư ví của tôi còn bao nhiêu",
                "tài khoản còn bao nhiêu tiền",
                "kiểm tra số dư tài khoản",
                "xem ví còn tiền không",
                "số dư hiện tại trong ví sen hồng"
            ],
            IntentChoice.TRANSACTION_HISTORY: [
                "lịch sử giao dịch gần đây của tôi",
                "xem các giao dịch vừa thực hiện",
                "tôi vừa chuyển tiền cho ai",
                "ai vừa chuyển tiền cho tôi",
                "biến động số dư tài khoản",
                "giao dịch gần đây nhất",
                "hôm nay tôi đã chi tiêu bao nhiêu tiền",
                "xem sao kê giao dịch gần đây"
            ],
            IntentChoice.POLICY_RAG: [
                "biểu phí chuyển tiền liên ngân hàng",
                "lãi suất tiền gửi tiết kiệm kỳ hạn 12 tháng",
                "quy định quyết định 2345 ngân hàng nhà nước",
                "hướng dẫn phát hành thẻ visa platinum",
                "phí duy trì tài khoản và sms banking",
                "bị nuốt thẻ tại cây atm thì làm thế nào",
                "cách nâng hạn mức giao dịch bằng chữ ký số smart otp",
                "kiến trúc hệ thống microservices và cơ chế saga",
                "điều kiện và thủ tục vay nhanh quick loan",
                "tôi có vay tiền được không",
                "lãi suất và hạn mức gói vay tiêu dùng tín chấp",
                "hướng dẫn nạp tiền điện thoại và mua thẻ cào data 4g",
                "quy định điều khoản bảo mật và chính sách an toàn thông tin",
                "quy trình gửi tiết kiệm online tích lũy",
                "thanh toán hóa đơn điện nước internet"
            ],
            IntentChoice.ACTION_NAVIGATION: [
                "tôi muốn chuyển tiền ngay bây giờ",
                "hướng dẫn tôi mở thẻ visa mới",
                "tôi muốn gửi tiết kiệm online",
                "nạp tiền vào tài khoản ví",
                "tôi muốn đăng ký vay tiền ngay",
                "hướng dẫn tôi vay nhanh quick loan",
                "nạp thẻ điện thoại ngay",
                "thanh toán hóa đơn tiền điện"
            ],
            IntentChoice.SECURITY_EMERGENCY: [
                "tài khoản tôi bị hack mất tiền rồi",
                "tôi nghi ngờ bị lừa đảo chuyển tiền",
                "khóa thẻ khẩn cấp ngay lập tức",
                "kẻ gian đang rút trộm tiền trong tài khoản"
            ],
            IntentChoice.CREDENTIAL_EXPOSURE: [
                "mã otp của tôi gửi về máy",
                "cho xin mã pin giao dịch",
                "mật khẩu đăng nhập tài khoản là gì",
                "mã cvv phía sau thẻ visa"
            ],
            IntentChoice.GENERAL_CHITCHAT: [
                "xin chào em",
                "chào bạn nhé",
                "cảm ơn em nhiều",
                "cảm ơn bạn nhé",
                "tạm biệt em",
                "bạn là ai",
                "bạn tên gì",
                "chúc một ngày tốt lành"
            ],
            IntentChoice.REMINDERS_INQUIRY: [
                "nhắc nhở tài chính của tôi",
                "các lời nhắc thanh toán của tôi",
                "tôi có hóa đơn nào sắp tới không",
                "lịch thanh toán tiền điện nước của tôi",
                "nhắc nhở hạn trả nợ và thẻ của tôi"
            ],
            # Bổ sung prototype cho 5 intent trước đây không có vector mẫu (chỉ dựa heuristic)
            IntentChoice.PROFILE_INQUIRY: [
                "hồ sơ cá nhân của tôi có gì",
                "xem thông tin tài khoản và eKYC của tôi",
                "số điện thoại đăng ký của tôi là gì",
                "trình trạng định danh danh tính của tôi",
                "tôi đã xác thực eKYC chưa",
                "cấp độ tài khoản của tôi là gì"
            ],
            IntentChoice.CARDS_INQUIRY: [
                "danh sách thẻ của tôi có những thẻ nào",
                "thẻ visa của tôi đang hoạt động không",
                "xem các thẻ ngân hàng liên kết của tôi",
                "thẻ ảo của tôi hạn mức bao nhiêu",
                "thẻ của tôi còn hiệu lực đến khi nào"
            ],
            IntentChoice.SAVINGS_INQUIRY: [
                "các sổ tiết kiệm của tôi đang gửi",
                "sổ tiết kiệm của tôi đáo hạn khi nào",
                "tôi đang gửi bao nhiêu sổ tiết kiệm",
                "tiền gửi tiết kiệm của tôi sinh lời bao nhiêu",
                "xem danh mục tiền gửi của tôi"
            ],
            IntentChoice.LOANS_INQUIRY: [
                "khoản vay của tôi còn bao nhiêu",
                "lịch trả nợ khoản vay của tôi",
                "tôi đang vay bao nhiêu tiền",
                "hợp đồng vay của tôi thế nào",
                "kỳ trả góp tiếp theo của tôi là ngày nào"
            ],
            IntentChoice.FINANCIAL_OVERVIEW: [
                "tổng quan tài chính của tôi",
                "tôi có tổng bao nhiêu tài sản ở sen hồng",
                "báo cáo tài chính cá nhân của tôi",
                "toàn bộ ví thẻ tiết kiệm và khoản vay của tôi",
                "tình hình tài chính hiện tại của tôi thế nào"
            ]
        }
        self.prototype_embeddings: Dict[IntentChoice, List[List[float]]] = {}
        self.is_initialized = False

    def initialize_embeddings(self, embed_model):
        """Pre-compute vector prototypes để suy luận cực nhanh (< 10ms) trong bộ nhớ RAM"""
        if self.is_initialized:
            return
        logger.info("Initializing Jev (System One) prototype embeddings...")
        for intent, phrases in self.intent_prototypes.items():
            enriched = [f"query: {p}" for p in phrases]
            vecs = embed_model.encode(enriched, normalize_embeddings=True).tolist()
            self.prototype_embeddings[intent] = vecs
        self.is_initialized = True
        logger.info("Jev (System One) ready with %d intent branches.", len(self.intent_prototypes))

    def evaluate(self, user_question: str, embed_model, user_id: Optional[str] = None) -> JevDecision:
        """
        Thực thi quyết định System One trong một lượt tính toán song song:
        - Phân loại Choice & Score
        - Đánh giá RiskScore
        - Đưa ra GateAction
        """
        start = time.time()
        self.initialize_embeddings(embed_model)

        q_clean = normalize_vietnamese_query(user_question.strip())
        q_lower = q_clean.lower()
        q_no_accent = strip_accents(q_clean)

        # Nhận diện các nghiệp vụ ngân hàng cốt lõi (hỗ trợ cả có dấu và không dấu)
        is_loan_keyword = any(k in q_lower or k in q_no_accent for k in [
            "vay", "quick loan", "vay tien", "vay von", "vay tieu dung", "khoan vay", "vay tra gop", "vay tin chap"
        ])

        is_topup_keyword = any(k in q_lower or k in q_no_accent for k in [
            "nap tien dt", "nap the dt", "nap the dien thoai", "the cao", "data 4g", "nap data", "nap the game", "the game", "nap dien thoai"
        ])

        is_savings_keyword = any(k in q_lower or k in q_no_accent for k in [
            "tiet kiem", "lai suat", "so tiet kiem", "gui tiet kiem", "rut tiet kiem"
        ])

        is_security_policy_keyword = any(k in q_lower or k in q_no_accent for k in [
            "bao mat", "dieu khoan", "phap ly", "qd 2345", "quyet dinh 2345", "pci dss", "chinh sach"
        ]) and not any(w in q_lower for w in ["của tôi là", "của em là", "cho xin", "gửi mã", "xin mã"])

        is_bill_keyword = any(k in q_lower or k in q_no_accent for k in [
            "hoa don", "tien dien", "tien nuoc", "internet", "truyen hinh", "dien nuoc"
        ])

        is_lottery_keyword = any(k in q_lower or k in q_no_accent for k in [
            "ve so", "vietlott", "xo so", "vua xo so"
        ])

        is_referral_keyword = any(k in q_lower or k in q_no_accent for k in [
            "gioi thieu ban be", "giới thiệu bạn bè", "link gioi thieu", "link giới thiệu", "ma gioi thieu", "mã giới thiệu", "nhan 50k", "nhận 50k", "friend50k"
        ])

        is_promotion_keyword = any(k in q_lower or k in q_no_accent for k in [
            "voucher", "khuyen mai", "khuyến mại", "khuyến mãi", "uu dai", "ưu đãi", "giam gia", "giảm giá",
            "ma giam gia", "mã giảm giá", "ma qua tang", "mã quà tặng", "cashback", "hoan tien", "hoàn tiền",
            "senpoint", "sen point", "tich diem", "tích điểm", "doi diem", "đổi điểm", "doi qua", "đổi quà",
            "xinchao50", "freego", "welcome100k", "senbank9", "hlcoffee50", "shopee100", "begrab40",
            "phuclong30", "cgvpopcorn", "pizza35", "vinfast0", "homeloan52", "tech0percent", "senshopee100",
            "vivuhe300", "phuclong25", "evo390k", "goldengate4", "autobill50", "platinum2026", "hotel15", "xangdau5",
            "coffee30", "tra gop 0%", "trả góp 0%", "vay mua xe", "vay mua nha"
        ])

        has_financial_keyword = (
            is_loan_keyword or is_topup_keyword or is_savings_keyword or 
            is_security_policy_keyword or is_bill_keyword or is_lottery_keyword or
            is_referral_keyword or is_promotion_keyword or
            any(k in q_no_accent for k in [
                "chuyen", "rut", "nap", "lai suat", "bieu phi", "han muc",
                "the", "visa", "so du", "giao dich", "sao ke", "otp", "pin"
            ])
        )

        # 1. Đo lường rủi ro (Risk Scoring)
        risk_score = 0.0
        is_device_support = any(w in q_lower or w in q_no_accent for w in [
            "mất điện thoại", "mat dien thoai", "đăng xuất từ xa", "dang xuat tu xa",
            "mất máy", "mat may", "quản lý thiết bị", "quan ly thiet bi"
        ])

        is_pwd_recovery = any(r in q_lower or r in q_no_accent for r in [
            "quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "cài lại", "cai lai",
            "khôi phục", "khoi phuc", "reset"
        ]) and any(p in q_lower or p in q_no_accent for p in ["mật khẩu", "mat khau", "password"])

        # Phân biệt yêu cầu trợ giúp đổi/cài lại PIN hoặc mật khẩu với hành vi đòi/lộ mã nhạy cảm
        is_pin_recovery = (any(r in q_lower or r in q_no_accent for r in [
            "quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "cài lại", "cai lai",
            "khôi phục", "khoi phuc", "reset", "mất mã pin", "mat ma pin", "mất pin", "mat pin",
            "bị khóa", "bi khoa", "mở lại", "mo lai", "mở khóa", "mo khoa", "nhập sai", "nhap sai",
            "sai 3 lần", "sai 5 lần", "sai mã pin", "sai pin", "khóa mã pin", "khoa ma pin", "khóa pin", "khoa pin"
        ]) and any(p in q_lower or p in q_no_accent for p in ["pin", "mã pin", "ma pin"])) or (
            any(r in q_lower or r in q_no_accent for r in [
                "quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "cài lại", "cai lai",
                "khôi phục", "khoi phuc", "reset", "bị khóa", "bi khoa", "mở lại", "mo lai", "mở khóa", "mo khoa"
            ]) and any(p in q_lower or p in q_no_accent for p in ["mật khẩu", "mat khau", "password"])
        )

        is_pin_change = any(c in q_lower or c in q_no_accent for c in [
            "đổi", "doi", "thay đổi", "thay doi", "cách đổi", "huong dan doi", "hướng dẫn đổi"
        ]) and any(p in q_lower or p in q_no_accent for p in ["pin", "mã pin", "ma pin", "mật khẩu", "mat khau", "password"]) and not is_pin_recovery

        is_pin_change_or_reset = is_pin_recovery or is_pin_change or is_pwd_recovery or any(w in q_lower or w in q_no_accent for w in [
            "đổi mã pin", "doi ma pin", "đổi pin", "doi pin", "cách đổi pin", "hướng dẫn đổi pin",
            "quên mã pin", "quen ma pin", "quên pin", "quen pin", "lấy lại pin", "lay lai pin",
            "đổi mật khẩu", "doi mat khau", "quên mật khẩu", "quen mat khau", "cài lại pin", "cai lai pin",
            "mở khóa pin", "mo khoa pin", "mở lại pin", "mo lai pin", "sai mã pin", "sai ma pin"
        ])

        # Nhận diện chào hỏi / cảm ơn / giao tiếp xã giao (chỉ đúng khi KHÔNG chứa từ khóa tài chính)
        chitchat_phrases = [
            "xin chào", "xin chao", "chào em", "chao em", "chào bạn", "chao ban", "hello", "hi em", "chào bot", "chao bot", "hi bot",
            "cảm ơn", "cam on", "cảm ơn em", "cam on em", "cảm ơn bạn", "cam on ban", "thank you", "thanks", "tks",
            "tạm biệt", "tam biet", "bye", "bạn là ai", "ban la ai", "bạn tên gì", "ban ten gi"
        ]
        is_chitchat = (not has_financial_keyword) and any(
            w == q_lower or q_lower.startswith(w + " ") or q_lower.endswith(" " + w) or f" {w} " in f" {q_lower} " or
            w == q_no_accent or q_no_accent.startswith(w + " ") or q_no_accent.endswith(" " + w) or f" {w} " in f" {q_no_accent} "
            for w in chitchat_phrases
        )

        # Phân biệt thắc mắc nghiệp vụ Chữ ký số Smart OTP với hành vi lộ mã OTP bí mật
        is_smart_otp_or_policy = any(w in q_lower or w in q_no_accent for w in [
            "smart otp", "chữ ký số", "chu ky so", "soft otp", "cách đăng ký smart otp", "nâng hạn mức", "nang han muc"
        ]) and not any(w in q_lower for w in ["của tôi là", "của em là", "cho xin", "gửi mã", "xin mã"])

        # Phân biệt câu hỏi về cơ chế kỹ thuật chống mất tiền/Saga hoặc hỏi về mất tiền lãi khi rút trước hạn với sự cố khách hàng bị mất tiền thật
        is_safe_loss_inquiry = any(w in q_lower or w in q_no_accent for w in [
            "tiền lãi", "tien lai", "mất hết tiền lãi", "mat het tien lai", "mất tiền lãi", "mất lãi", "mat lai",
            "có bị mất tiền không", "co bi mat tien khong", "có mất tiền không", "co mat tien khong",
            "tiền có bị mất không", "tien co bi mat khong", "liệu có bị mất tiền", "lieu co bi mat tien"
        ])

        is_anti_loss_or_architecture = any(w in q_lower or w in q_no_accent for w in [
            "chống mất tiền", "chong mat tien", "ngăn mất tiền", "ngan mat tien", "tránh mất tiền", "tranh mat tien",
            "saga", "kiến trúc", "kien truc", "microservice", "outbox", "ledger", "sổ cái kép", "so cai kep"
        ])

        if not is_device_support and not is_pin_change_or_reset and not is_smart_otp_or_policy and not is_anti_loss_or_architecture and not is_safe_loss_inquiry:
            if any(w in q_lower or w in q_no_accent for w in ["otp", "mã pin", "pin", "mật khẩu", "password", "cvv", "cvc"]):
                risk_score += 0.70
            if any(w in q_lower or w in q_no_accent for w in ["lừa đảo", "lua dao", "bị hack", "tôi bị mất tiền", "vừa bị mất tiền", "mất hết tiền", "chiếm quyền"]):
                risk_score += 0.85
            if any(w in q_lower or w in q_no_accent for w in ["hack", "jailbreak", "prompt injection", "ignore previous instructions"]):
                risk_score += 0.95
            risk_score = min(risk_score, 1.0)

        # 2. Tính tương đồng vector với các prototype (Cosine Similarity)
        query_vec = embed_model.encode(f"query: {q_clean}", normalize_embeddings=True).tolist()

        intent_scores: Dict[IntentChoice, float] = {}
        for intent, proto_vecs in self.prototype_embeddings.items():
            max_sim = -1.0
            for pv in proto_vecs:
                # Dot product của normalized vector = Cosine similarity
                sim = sum(a * b for a, b in zip(query_vec, pv))
                if sim > max_sim:
                    max_sim = sim
            intent_scores[intent] = max_sim

        # Softmax với Temperature = 0.15 để tạo xác suất chuẩn hóa (Calibrated Score)
        temp = 0.15
        exp_scores = {k: math.exp(v / temp) for k, v in intent_scores.items()}
        total_exp = sum(exp_scores.values())
        calibrated_probs = {k: v / total_exp for k, v in exp_scores.items()}

        best_choice = max(calibrated_probs, key=calibrated_probs.get)
        confidence = calibrated_probs[best_choice]

        # Heuristic tăng cường: Từ khóa đặc thù ngành ngân hàng
        is_transaction_keyword = any(k in q_lower or k in q_no_accent for k in [
            "lịch sử giao dịch", "lich su giao dich", "lịch sử", "lich su",
            "giao dịch gần", "giao dich gan", "vừa chuyển", "vua chuyen",
            "ai chuyển", "ai chuyen", "biến động số dư", "bien dong so du",
            "sao kê", "sao ke", "chi tiêu hôm nay", "chi tieu", "giao dịch mới nhất"
        ]) and not any(k in q_lower or k in q_no_accent for k in ["hướng dẫn", "cách", "quy định", "hạn mức"])

        is_balance_keyword = any(k in q_lower or k in q_no_accent for k in [
            "số dư", "so du", "còn bao nhiêu tiền", "con bao nhieu tien", 
            "trong ví còn", "kiểm tra số dư", "kiem tra so du"
        ]) and not is_transaction_keyword

        is_atm_or_card_issue = any(k in q_lower or k in q_no_accent for k in [
            "nuốt thẻ", "nuot the", "bị nuốt", "bi nuot", "kẹt thẻ", "ket the"
        ])

        has_self_ref = any(s in q_lower or s in q_no_accent for s in [
            "cua toi", "của tôi", "cua minh", "của mình", "cua em", "của em",
            "toi dang co", "tôi đang có", "toi co", "tôi có", "cho toi xem", "cho tôi xem",
            "xem giup toi", "xem giúp tôi", "kiem tra giup toi", "kiểm tra giúp tôi",
            "toi dang", "tôi đang", "hien tai cua toi", "hiện tại của tôi", "cua ban than", "của bản thân"
        ])

        # Nhận diện thắc mắc về Chuyển tiền hoặc Tra soát treo tiền (để không bị nhầm sang tra cứu thẻ)
        is_transfer_or_dispute_context = any(k in q_lower or k in q_no_accent for k in [
            "chuyển khoản", "chuyen khoan", "chuyển tiền", "chuyen tien",
            "chưa nhận được", "chua nhan duoc", "bị trừ tiền", "bi tru tien",
            "treo tiền", "treo tien", "tiền bị treo", "tra soát", "tra soat",
            "khiếu nại", "khieu nai", "tiền chưa tới", "chuyển nhầm"
        ])

        q_no_spaced = f" {q_no_accent} "
        is_card_word = (
            (any(w in q_lower for w in ["thẻ", "visa", "ecard", "mastercard"]) or
             ("napas" in q_lower and not is_transfer_or_dispute_context)) or
            (any(w in q_no_spaced for w in [" the ", " the-", " visa ", " ecard "]) and not any(e in q_no_accent for e in ["the nao", "co the", "thay the"]))
        )

        is_advisory_or_simulation = any(w in q_lower or w in q_no_accent for w in [
            "neu toi", "nếu tôi", "gia su", "giả sử",
            "nen gui", "nên gửi", "nen vay", "nên vay", "tu van", "tư vấn", "loi khuyen", "lời khuyên", "khuyen toi", "khuyên tôi",
            "hay chia", "chia nho", "chia nhỏ", "chia ra", "linh hoat", "linh hoạt",
            "so sanh", "so sánh", "khac gi", "khác gì", "tot hon", "tốt hơn", "loi hon", "lợi hơn", "hay la", "hay là",
            "thau chi", "thấu chi", "tat toan", "tất toán", "dao han", "đáo hạn", "ket tien", "kẹt tiền",
            "may thang", "mấy tháng", "ky han nao", "kỳ hạn nào", "lai cao nhat", "lãi cao nhất",
            "cach tinh", "cách tính", "tinh lai", "tính lãi", "cong thuc", "công thức",
            "tu no", "tự nó", "tu nso", "10 nam", "10 năm", "vai nam", "vài năm", "lai kep", "lãi kép",
            "lai suat vay", "lãi suất vay", "tien trong tai khoan", "tiền trong tài khoản",
            "muon gui", "muốn gửi", "dinh gui", "định gửi", "du dinh", "dự định",
            "muon vay", "muốn vay", "dinh vay", "định vay", "du dinh vay", "dự định vay",
            "dieu kien", "điều kiện", "thu tuc", "thủ tục", "moi thang tra bao nhieu", "mỗi tháng trả bao nhiêu",
            "du no giam dan", "dư nợ giảm dần", "co dinh", "cố định", "rut tien o atm duoc khong", "rút tiền ở atm",
            "phi bao nhieu", "phí bao nhiêu", "phi doi ngoai te", "phí đổi ngoại tệ"
        ])

        is_personal_profile = any(k in q_lower or k in q_no_accent for k in [
            "thông tin tài khoản", "thong tin tai khoan", "hồ sơ của tôi", "ho so cua toi",
            "thông tin của tôi", "thong tin cua toi", "tôi đã ekyc chưa", "toi da ekyc chua",
            "tình trạng ekyc", "tinh trang ekyc", "cấp độ ekyc", "cap do ekyc", "định danh của tôi",
            "tên tài khoản của tôi", "số điện thoại của tôi", "so dien thoai cua toi", "sđt của tôi", "sdt cua toi",
            "alias của tôi", "biệt danh của tôi", "biet danh cua toi", "hạn mức giao dịch của tôi", "hồ sơ cá nhân", "ho so ca nhan"
        ])

        is_personal_cards = (not is_advisory_or_simulation) and (not is_transfer_or_dispute_context) and ((any(k in q_no_accent for k in [
            "the cua toi", "the cua minh", "the cua em", "the dang dung", "the dang mo", "the dang hoat dong",
            "the lien ket", "ngan hang lien ket", "danh sach the"
        ]) or (has_self_ref and is_card_word and any(k in q_no_accent for k in ["co", "nao", "gi", "xem", "danh sach", "bao nhieu"]))) and not any(k in q_lower for k in ["hướng dẫn mở", "phí phát hành", "cách mở thẻ", "làm thẻ mới", "khóa thẻ"]))

        is_personal_savings = (not is_advisory_or_simulation) and ((any(k in q_no_accent for k in [
            "so tiet kiem cua toi", "tien tiet kiem cua toi", "so tiet kiem dang gui", "tien gui cua toi",
            "so cua toi", "xem so tiet kiem cua toi", "danh sach so tiet kiem", "so tiet kiem hien tai"
        ]) or (has_self_ref and any(k in q_no_accent for k in ["so tiet kiem", "tiet kiem", "tien gui"]) and any(k in q_no_accent for k in ["co", "nao", "gi", "xem", "danh sach", "bao nhieu", "dang gui"]))) and not any(k in q_lower for k in ["lãi suất tiết kiệm", "biểu lãi", "cách mở sổ", "hướng dẫn gửi tiết kiệm"]))

        is_personal_loans = (not is_advisory_or_simulation) and ((any(k in q_no_accent for k in [
            "khoan vay cua toi", "khoan vay hien tai", "du no cua toi", "hop dong vay cua toi",
            "lich tra no cua toi", "no cua toi", "vay cua toi", "tien no cua toi", "tien vay cua toi", "du no hien tai"
        ]) or (has_self_ref and any(k in q_no_accent for k in ["khoan vay", "vay", "du no", "tien no", "hop dong vay", "no"]) and any(k in q_no_accent for k in ["co", "nao", "gi", "xem", "the nao", "bao nhieu", "hien tai"]))) and not any(k in q_lower for k in ["điều kiện vay", "hướng dẫn vay", "lãi suất vay"]))

        is_options_query = any(k in q_lower or k in q_no_accent for k in ["phuong an", "phương án", "giai phap", "giải pháp"])
        is_personal_reminders = (not is_advisory_or_simulation) and (not is_options_query) and (
            any(k in q_lower or k in q_no_accent for k in [
                "nhac nho cua toi", "nhắc nhở của tôi", "loi nhac cua toi", "lời nhắc của tôi",
                "lich tai chinh cua toi", "lịch tài chính của tôi", "lich thanh toan cua toi", "lịch thanh toán của tôi",
                "hoa don cua toi", "hóa đơn của tôi", "cac loi nhac", "các lời nhắc",
                "nhac nho toi", "nhắc nhở tôi", "nhac toi", "nhắc tôi"
            ]) or (
                has_self_ref and any(k in q_lower or k in q_no_accent for k in [
                    "nhac nho", "nhắc nhở", "loi nhac", "lời nhắc", "lich thanh toan", "lịch thanh toán", "hoa don", "hóa đơn"
                ])
            )
        )

        is_personal_overview = any(k in q_lower or k in q_no_accent for k in [
            "tổng quan tài chính", "tong quan tai chinh", "tóm tắt tài khoản", "tom tat tai khoan",
            "tổng tài sản của tôi", "tong tai san cua toi", "tổng tài sản", "tong tai san",
            "tổng quan tài khoản", "tong quan tai khoan", "tài sản của tôi", "tai san cua toi",
            "báo cáo tài chính của tôi", "tất cả dịch vụ tôi đang có", "tôi đang có những gì trên app",
            "tổng thể tài sản", "báo cáo tài sản"
        ])

        if is_chitchat:
            best_choice = IntentChoice.GENERAL_CHITCHAT
            confidence = 0.99
            risk_score = 0.0
        elif is_personal_overview:
            best_choice = IntentChoice.FINANCIAL_OVERVIEW
            confidence = 0.99
            risk_score = 0.0
        elif is_personal_profile:
            best_choice = IntentChoice.PROFILE_INQUIRY
            confidence = 0.99
            risk_score = 0.0
        elif is_personal_cards:
            best_choice = IntentChoice.CARDS_INQUIRY
            confidence = 0.99
            risk_score = 0.0
        elif is_personal_savings:
            best_choice = IntentChoice.SAVINGS_INQUIRY
            confidence = 0.99
            risk_score = 0.0
        elif is_personal_loans:
            best_choice = IntentChoice.LOANS_INQUIRY
            confidence = 0.99
            risk_score = 0.0
        elif is_personal_reminders:
            best_choice = IntentChoice.REMINDERS_INQUIRY
            confidence = 0.99
            risk_score = 0.0
        elif is_loan_keyword:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.98
        elif is_topup_keyword:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.98
        elif is_security_policy_keyword:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.98
        elif is_savings_keyword:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.98
        elif is_bill_keyword:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.98
        elif is_lottery_keyword:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.98
        elif is_referral_keyword:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.98
        elif is_promotion_keyword:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.98
        elif is_device_support:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.95
        elif is_atm_or_card_issue:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.95
        elif is_pwd_recovery:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.99
            risk_score = 0.0
            suggested_route = "/auth/forgot-password"
            suggested_label = "Quên mật khẩu"
        elif is_pin_change_or_reset:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.99
            risk_score = 0.0
        elif is_smart_otp_or_policy:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.96
            suggested_route = "/profile/digital-signature"
            suggested_label = "Chữ ký số Smart OTP"
        elif is_anti_loss_or_architecture:
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.96
        elif is_transaction_keyword:
            best_choice = IntentChoice.TRANSACTION_HISTORY
            confidence = 0.98
        elif is_balance_keyword:
            best_choice = IntentChoice.BALANCE_INQUIRY
            confidence = 0.98
        elif best_choice in [IntentChoice.BALANCE_INQUIRY, IntentChoice.TRANSACTION_HISTORY] and not (is_balance_keyword or is_transaction_keyword):
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.85

        # Chặn false-positive GENERAL_CHITCHAT:
        # Nếu model phỏng đoán GENERAL_CHITCHAT nhưng độ tin cậy < 0.70 hoặc chứa từ khóa tài chính, hạ cấp về POLICY_RAG
        if best_choice == IntentChoice.GENERAL_CHITCHAT:
            if not is_chitchat and (confidence < 0.70 or has_financial_keyword):
                best_choice = IntentChoice.POLICY_RAG
                confidence = 0.85

        if any(k in q_lower or k in q_no_accent for k in ["lừa đảo", "bi lua dao", "bị hack", "khóa khẩn cấp", "khoa khan cap"]) and not is_device_support and not is_pin_change_or_reset and not is_atm_or_card_issue and not is_anti_loss_or_architecture:
            best_choice = IntentChoice.SECURITY_EMERGENCY
            confidence = 0.98

        # Phòng vệ vector path: intent tra cứu dữ liệu cá nhân chỉ được giữ khi câu hỏi
        # thực sự có tín hiệu sở hữu cá nhân (của tôi/xem/danh sách...) HOẶC điểm vector đủ cao.
        # Tránh trường hợp câu hỏi chính sách ("hạn mức rút tiền ATM") bị prototype mới
        # kéo về nhánh tra cứu thẻ với confidence rất thấp (~0.1).
        personal_inquiry_intents = {
            IntentChoice.PROFILE_INQUIRY,
            IntentChoice.CARDS_INQUIRY,
            IntentChoice.SAVINGS_INQUIRY,
            IntentChoice.LOANS_INQUIRY,
            IntentChoice.FINANCIAL_OVERVIEW,
            IntentChoice.REMINDERS_INQUIRY,
        }
        if (
            best_choice in personal_inquiry_intents
            and confidence < 0.35
            and not is_personal_overview
            and not is_personal_profile
            and not is_personal_cards
            and not is_personal_savings
            and not is_personal_loans
            and not is_personal_reminders
            and not has_self_ref
        ):
            best_choice = IntentChoice.POLICY_RAG
            confidence = 0.85

        # 3. Quyết định hành động gác cổng (GateAction)
        gate_action = GateAction.ALLOW_RAG
        suggested_route = None
        suggested_label = None

        if is_chitchat or (best_choice == IntentChoice.GENERAL_CHITCHAT and confidence >= 0.70 and not has_financial_keyword):
            gate_action = GateAction.FAST_NAVIGATE
            suggested_route = None
            suggested_label = None

        elif best_choice == IntentChoice.FINANCIAL_OVERVIEW or is_personal_overview:
            # Gác cổng Zero-PII Leak: Báo cáo tài chính 360 độ từ Microservices nội bộ
            gate_action = GateAction.DIVERT_INTERNAL_OVERVIEW
            suggested_route = "/profile"
            suggested_label = "Tổng quan tài chính"

        elif best_choice == IntentChoice.PROFILE_INQUIRY or is_personal_profile:
            # Gác cổng Zero-PII Leak: Hồ sơ, eKYC, SĐT, Alias từ identity-service & wallet-service
            gate_action = GateAction.DIVERT_INTERNAL_PROFILE
            suggested_route = "/profile"
            suggested_label = "Hồ sơ cá nhân"

        elif best_choice == IntentChoice.CARDS_INQUIRY or is_personal_cards:
            # Gác cổng Zero-PII Leak: Thẻ Visa & Ngân hàng liên kết từ payment-service
            gate_action = GateAction.DIVERT_INTERNAL_CARDS
            suggested_route = "/cards"
            suggested_label = "Quản lý thẻ"

        elif best_choice == IntentChoice.SAVINGS_INQUIRY or is_personal_savings:
            # Gác cổng Zero-PII Leak: Sổ tiết kiệm & lãi suất thực tế từ payment-service
            gate_action = GateAction.DIVERT_INTERNAL_SAVINGS
            suggested_route = "/savings"
            suggested_label = "Sổ tiết kiệm của tôi"

        elif best_choice == IntentChoice.LOANS_INQUIRY or is_personal_loans:
            # Gác cổng Zero-PII Leak: Khoản vay & lịch trả nợ từ payment-service
            gate_action = GateAction.DIVERT_INTERNAL_LOANS
            suggested_route = "/bills/quick-loan"
            suggested_label = "Khoản vay của tôi"

        elif best_choice == IntentChoice.REMINDERS_INQUIRY or is_personal_reminders:
            # Gác cổng Zero-PII Leak: Lời nhắc tài chính cá nhân hóa & lịch chi tiêu sinh hoạt
            gate_action = GateAction.DIVERT_INTERNAL_REMINDERS
            suggested_route = "/profile"
            suggested_label = "Lịch tài chính & Nhắc nhở"

        elif best_choice == IntentChoice.TRANSACTION_HISTORY and is_transaction_keyword:
            # Gác cổng Zero-PII Leak: Lấy trực tiếp từ payment-service & identity-service
            gate_action = GateAction.DIVERT_INTERNAL_TRANSACTIONS
            suggested_route = "/history"
            suggested_label = "Xem tất cả giao dịch"

        elif best_choice == IntentChoice.BALANCE_INQUIRY and is_balance_keyword:
            # Gác cổng Zero-PII Leak: Không bao giờ cho phép gọi System Two LLM
            gate_action = GateAction.DIVERT_INTERNAL_WALLET
            suggested_route = "/profile"
            suggested_label = "Xem chi tiết ví"


        elif is_pwd_recovery:
            gate_action = GateAction.ALLOW_RAG
            suggested_route = "/auth/forgot-password"
            suggested_label = "Quên mật khẩu"

        elif is_loan_keyword:
            gate_action = GateAction.ALLOW_RAG
            suggested_route = "/bills/quick-loan"
            suggested_label = "Vay nhanh Quick Loan"

        elif is_topup_keyword:
            gate_action = GateAction.ALLOW_RAG
            suggested_route = "/bills/phone-recharge"
            suggested_label = "Nạp tiền điện thoại"

        elif is_savings_keyword:
            gate_action = GateAction.ALLOW_RAG
            suggested_route = "/bills/savings"
            suggested_label = "Mở sổ tiết kiệm"

        elif is_security_policy_keyword:
            gate_action = GateAction.ALLOW_RAG
            suggested_route = "/settings/security"
            suggested_label = "Cài đặt bảo mật"

        elif is_lottery_keyword:
            gate_action = GateAction.ALLOW_RAG
            suggested_route = "/bills/lottery"
            suggested_label = "Vé số Vietlott"

        elif is_referral_keyword:
            gate_action = GateAction.ALLOW_RAG
            suggested_route = "/referral"
            suggested_label = "Giới thiệu bạn bè"

        elif is_promotion_keyword:
            gate_action = GateAction.ALLOW_RAG
            suggested_route = "/promotions"
            suggested_label = "Kho Voucher & Ưu đãi"

        elif is_device_support:
            gate_action = GateAction.ALLOW_RAG
            suggested_route = "/settings/devices"
            suggested_label = "Quản lý thiết bị"

        elif is_atm_or_card_issue:
            gate_action = GateAction.ALLOW_RAG
            suggested_route = "/cards"
            suggested_label = "Quản lý thẻ"

        elif is_pin_change_or_reset:
            gate_action = GateAction.ALLOW_RAG
            if is_pin_recovery or any(k in q_lower or k in q_no_accent for k in ["quên", "quen", "lay lai", "lấy lại", "cấp lại", "cap lai", "khôi phục", "khoi phuc", "reset", "mở lại", "mo lai", "mở khóa", "mo khoa", "bị khóa", "bi khoa", "nhập sai", "nhap sai"]):
                suggested_route = "/auth/forgot-pin"
                suggested_label = "Lấy lại mã PIN"
            else:
                suggested_route = "/settings/change-pin"
                suggested_label = "Đổi mã PIN giao dịch"


        elif best_choice == IntentChoice.SECURITY_EMERGENCY and (
            risk_score >= 0.5 or any(k in q_lower or k in q_no_accent for k in ["lừa đảo", "lua dao", "bị hack", "bi hack", "khóa khẩn cấp", "khoa khan cap", "khóa thẻ", "khoa the"])
        ):
            gate_action = GateAction.INTERCEPT_EMERGENCY
            is_card_emergency = any(k in q_lower or k in q_no_accent for k in ["thẻ", "the", "visa", "napas", "atm"])
            suggested_route = "/cards" if is_card_emergency else "/settings/security"
            suggested_label = "Khóa thẻ ngay" if is_card_emergency else "Khóa khẩn cấp"

        elif best_choice == IntentChoice.CREDENTIAL_EXPOSURE and risk_score > 0.5:
            gate_action = GateAction.BLOCK_CREDENTIAL_THEFT
            suggested_route = "/settings/security"
            suggested_label = "Đổi mã PIN & Mật khẩu"

        else:
            # POLICY_RAG hoặc ACTION_NAVIGATION
            gate_action = GateAction.ALLOW_RAG
            if any(k in q_lower or k in q_no_accent for k in ["nạp tiền", "nap tien", "nạp ví", "nap vi", "topup"]):
                suggested_route = "/deposit"
                suggested_label = "Nạp tiền vào ví"
            elif any(k in q_lower or k in q_no_accent for k in ["rút tiền", "rut tien"]):
                if any(k in q_lower or k in q_no_accent for k in ["atm", "không thẻ", "khong the"]):
                    suggested_route = "/atm-withdrawal"
                    suggested_label = "Rút tiền ATM không thẻ"
                else:
                    suggested_route = "/withdraw"
                    suggested_label = "Rút tiền về ngân hàng"
            elif any(k in q_lower or k in q_no_accent for k in ["chuyển tiền", "chuyen tien", "chuyển khoản", "chuyen khoan", "napas"]):
                suggested_route = "/transfer"
                suggested_label = "Chuyển tiền ngay"
            elif any(k in q_lower or k in q_no_accent for k in ["chia tiền", "chia tien", "nhắc nợ", "nhac no", "split bill"]):
                suggested_route = "/transfer/request"
                suggested_label = "Chia tiền / Nhắc nợ"
            elif any(k in q_lower or k in q_no_accent for k in ["liên kết", "lien ket", "ngân hàng liên kết", "ngan hang lien ket", "thẻ liên kết", "the lien ket"]):
                suggested_route = "/bank-cards"
                suggested_label = "Thẻ & Ngân hàng liên kết"
            elif any(k in q_lower or k in q_no_accent for k in ["thẻ", "the", "visa"]):
                suggested_route = "/cards"
                suggested_label = "Quản lý thẻ"
            elif any(k in q_lower or k in q_no_accent for k in ["tiết kiệm", "tiet kiem", "lãi suất", "lai suat"]):
                suggested_route = "/bills/savings"
                suggested_label = "Mở sổ tiết kiệm"
            elif any(k in q_lower or k in q_no_accent for k in ["vay", "quick loan"]):
                suggested_route = "/bills/quick-loan"
                suggested_label = "Vay nhanh Quick Loan"
            elif any(k in q_lower or k in q_no_accent for k in ["hóa đơn", "hoa don", "tiền điện", "tien dien", "tiền nước", "tien nuoc"]):
                suggested_route = "/bills"
                suggested_label = "Thanh toán hóa đơn"
            elif any(k in q_lower or k in q_no_accent for k in ["vé số", "ve so", "vietlott", "xo so"]):
                suggested_route = "/bills/lottery"
                suggested_label = "Vé số Vietlott"
            elif any(k in q_lower or k in q_no_accent for k in ["mã qr", "ma qr", "qr của tôi", "qr cua toi"]):
                suggested_route = "/my-qr"
                suggested_label = "Mã QR của tôi"
            elif any(k in q_lower or k in q_no_accent for k in ["danh bạ", "danh ba", "thụ hưởng", "thu huong"]):
                suggested_route = "/beneficiaries"
                suggested_label = "Danh bạ thụ hưởng"
            elif any(k in q_lower or k in q_no_accent for k in ["số đẹp", "so dep", "tài khoản đẹp", "tai khoan dep"]):
                suggested_route = "/lucky-account"
                suggested_label = "Tài khoản số đẹp"
            elif any(k in q_lower or k in q_no_accent for k in ["quốc tế", "quoc te", "kiều hối", "kieu hoi"]):
                suggested_route = "/international-transfer"
                suggested_label = "Chuyển tiền quốc tế"
            elif any(k in q_lower or k in q_no_accent for k in ["sinh trắc học", "sinh trac hoc", "khuôn mặt", "khuon mat", "cccd", "nfc", "2345"]):
                suggested_route = "/profile/nfc-reader"
                suggested_label = "Đọc chip NFC CCCD"
            elif any(k in q_lower or k in q_no_accent for k in ["voucher", "ưu đãi", "uu dai", "khuyến mại", "khuyen mai"]):
                suggested_route = "/promotions"
                suggested_label = "Kho Voucher & Ưu đãi"
            elif any(k in q_lower or k in q_no_accent for k in ["giới thiệu", "gioi thieu", "referral"]):
                suggested_route = "/referral"
                suggested_label = "Giới thiệu bạn bè"
            else:
                suggested_route = "/more"
                suggested_label = "Xem tất cả tiện ích"

        elapsed_ms = (time.time() - start) * 1000

        # Gắn kèm domain nghiệp vụ (hàm thuần) để dispatcher tái sử dụng cho domain filter RAG
        rag_domain = detect_query_topic(q_clean)

        decision = JevDecision(
            choice=best_choice,
            score=round(confidence, 4),
            risk_score=round(risk_score, 4),
            gate_action=gate_action,
            domain=rag_domain,
            suggested_route=suggested_route,
            suggested_label=suggested_label,
            execution_time_ms=round(elapsed_ms, 2)
        )

        logger.info(
            "[Jev System One] Choice: %s (score: %.2f), Risk: %.2f, Gate: %s in %.2fms",
            decision.choice.value, decision.score, decision.risk_score, decision.gate_action.value, decision.execution_time_ms
        )
        return decision


# Singleton instance của Jev System One Gatekeeper
jev_gatekeeper = JevSystemOneGatekeeper()
