import time
import math
import logging
import unicodedata
from enum import Enum
from typing import Dict, Any, List, Optional, Tuple
from pydantic import BaseModel, Field

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
    POLICY_RAG = "POLICY_RAG"                   # Tra cứu biểu phí, lãi suất, quy định QĐ 2345
    ACTION_NAVIGATION = "ACTION_NAVIGATION"     # Yêu cầu thực hiện hành động (chuyển tiền, mở thẻ, gửi tiết kiệm)
    SECURITY_EMERGENCY = "SECURITY_EMERGENCY"   # Báo mất tiền, nghi lừa đảo, khóa thẻ khẩn cấp
    CREDENTIAL_EXPOSURE = "CREDENTIAL_EXPOSURE" # Nghi vấn lộ hoặc đòi mã OTP, PIN, mật khẩu
    GENERAL_CHITCHAT = "GENERAL_CHITCHAT"       # Chào hỏi, trò chuyện thông thường


class GateAction(str, Enum):
    ALLOW_RAG = "ALLOW_RAG"                             # Cho phép chuyển tiếp sang System Two (LLM Gemini)
    DIVERT_INTERNAL_WALLET = "DIVERT_INTERNAL_WALLET"   # Rẽ nhánh sang microservice nội bộ ví (Zero-LLM leak)
    DIVERT_INTERNAL_TRANSACTIONS = "DIVERT_INTERNAL_TRANSACTIONS" # Rẽ nhánh sang microservice giao dịch & đối tác
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

        q_clean = user_question.strip()
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

        has_financial_keyword = (
            is_loan_keyword or is_topup_keyword or is_savings_keyword or 
            is_security_policy_keyword or is_bill_keyword or is_lottery_keyword or
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
            "khôi phục", "khoi phuc", "reset", "mất mã pin", "mat ma pin", "mất pin", "mat pin"
        ]) and any(p in q_lower or p in q_no_accent for p in ["pin", "mã pin", "ma pin"])) or (
            any(r in q_lower or r in q_no_accent for r in [
                "quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "cài lại", "cai lai",
                "khôi phục", "khoi phuc", "reset"
            ]) and any(p in q_lower or p in q_no_accent for p in ["mật khẩu", "mat khau", "password"])
        )

        is_pin_change = any(c in q_lower or c in q_no_accent for c in [
            "đổi", "doi", "thay đổi", "thay doi", "cách đổi", "huong dan doi", "hướng dẫn đổi"
        ]) and any(p in q_lower or p in q_no_accent for p in ["pin", "mã pin", "ma pin", "mật khẩu", "mat khau", "password"]) and not is_pin_recovery

        is_pin_change_or_reset = is_pin_recovery or is_pin_change or is_pwd_recovery or any(w in q_lower or w in q_no_accent for w in [
            "đổi mã pin", "doi ma pin", "đổi pin", "doi pin", "cách đổi pin", "hướng dẫn đổi pin",
            "quên mã pin", "quen ma pin", "quên pin", "quen pin", "lấy lại pin", "lay lai pin",
            "đổi mật khẩu", "doi mat khau", "quên mật khẩu", "quen mat khau", "cài lại pin", "cai lai pin"
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

        # Phân biệt câu hỏi về cơ chế kỹ thuật chống mất tiền/Saga với sự cố khách hàng bị mất tiền thật
        is_anti_loss_or_architecture = any(w in q_lower or w in q_no_accent for w in [
            "chống mất tiền", "chong mat tien", "ngăn mất tiền", "ngan mat tien", "tránh mất tiền", "tranh mat tien",
            "saga", "kiến trúc", "kien truc", "microservice", "outbox", "ledger", "sổ cái kép", "so cai kep"
        ])

        if not is_device_support and not is_pin_change_or_reset and not is_smart_otp_or_policy and not is_anti_loss_or_architecture:
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

        if is_chitchat:
            best_choice = IntentChoice.GENERAL_CHITCHAT
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

        # 3. Quyết định hành động gác cổng (GateAction)
        gate_action = GateAction.ALLOW_RAG
        suggested_route = None
        suggested_label = None

        if is_chitchat or (best_choice == IntentChoice.GENERAL_CHITCHAT and confidence >= 0.70 and not has_financial_keyword):
            gate_action = GateAction.FAST_NAVIGATE
            suggested_route = None
            suggested_label = None

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
            if is_pin_recovery or any(k in q_lower or k in q_no_accent for k in ["quên", "quen", "lay lai", "lấy lại", "cấp lại", "cap lai", "khôi phục", "khoi phuc", "reset"]):
                suggested_route = "/auth/forgot-pin"
                suggested_label = "Lấy lại mã PIN"
            else:
                suggested_route = "/settings/change-pin"
                suggested_label = "Đổi mã PIN giao dịch"

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

        elif best_choice == IntentChoice.SECURITY_EMERGENCY and (
            risk_score >= 0.5 or any(k in q_lower or k in q_no_accent for k in ["lừa đảo", "lua dao", "bị hack", "bi hack", "khóa khẩn cấp", "khoa khan cap"])
        ):
            gate_action = GateAction.INTERCEPT_EMERGENCY
            suggested_route = "/settings/security"
            suggested_label = "Khóa khẩn cấp"

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

        decision = JevDecision(
            choice=best_choice,
            score=round(confidence, 4),
            risk_score=round(risk_score, 4),
            gate_action=gate_action,
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
