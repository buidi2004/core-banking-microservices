from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field, field_validator
from app.output_validator import sanitize_and_validate_output

class MessageItem(BaseModel):
    role: str = Field(..., description="'user' hoặc 'assistant'")
    content: str = Field(..., max_length=4000, description="Nội dung tin nhắn")

class ActionItem(BaseModel):
    type: str = Field(default="NAVIGATE", description="'NAVIGATE' hoặc 'DEEP_LINK'")
    label: str = Field(..., description="Nhãn hiển thị trên nút bấm hành động")
    route: str = Field(..., description="Đường dẫn điều hướng màn hình trên Flutter")

class ChatRequest(BaseModel):
    question: str = Field(..., min_length=1, max_length=1000, description="Câu hỏi của khách hàng")
    history: Optional[List[MessageItem]] = Field(default=[], max_length=20, description="Lịch sử hội thoại trước đó (tối đa 20 lượt)")
    user_id: Optional[str] = Field(default=None, max_length=128, description="Mã định danh khách hàng (nếu truyền trong body)")
    client_context: Optional[Dict[str, Any]] = Field(default=None, description="Ngữ cảnh từ Mobile App (screen, kyc, platform...)")

class ChatResponse(BaseModel):
    answer: str = Field(..., description="Câu trả lời từ trợ lý AI")
    sources: List[str] = Field(default=[], description="Danh sách tài liệu trích dẫn nguồn")
    quick_replies: List[str] = Field(default=[], description="Gợi ý câu hỏi tiếp theo")
    suggested_action: Optional[ActionItem] = Field(default=None, description="Hành động điều hướng nhanh trên App")
    latency_ms: float = Field(default=0.0, description="Thời gian xử lý tính bằng mili-giây")
    thought_process: Optional[str] = Field(default=None, description="Chuỗi suy nghĩ lập luận chuyên sâu (Chain-of-Thought / Deep Thinking)")
    reasoning_steps: Optional[List[str]] = Field(default=[], description="Danh sách các bước suy luận và tự kiểm chứng số học của AI")
    thinking_duration_ms: Optional[float] = Field(default=None, description="Thời gian suy nghĩ và đối soát logic (ms)")
    confidence_score: Optional[float] = Field(default=0.99, description="Độ tin cậy sau khi kiểm chứng số học và chính sách")
    grounding_warnings: Optional[List[str]] = Field(default=[], description="Các con số trong câu trả lời không truy vết được trong ngữ cảnh nguồn (mobile hiển thị cảnh báo 'cần kiểm chứng')")

    @field_validator("answer")
    @classmethod
    def clean_and_bridge_answer(cls, v: str) -> str:
        return sanitize_and_validate_output(v)

# Whitelist route điều hướng hợp lệ trên ứng dụng Flutter Sen Hồng (dùng chung bởi
# rag_engine.query() và banking_agent để chặn LLM sinh route không tồn tại).
VALID_APP_ROUTES = frozenset({
    "/transfer", "/transfer/request", "/my-qr", "/scan-qr", "/beneficiaries",
    "/deposit", "/withdraw", "/atm-withdrawal",
    "/bills", "/bills/phone-recharge", "/bills/lottery",
    "/bills/savings", "/savings", "/savings/detail",
    "/bills/quick-loan", "/loan/schedule",
    "/cards", "/payment-methods", "/bank-cards",
    "/lucky-account", "/international-transfer",
    "/flight-booking", "/social-insurance", "/vua-xo-so", "/vietlott",
    "/data-topup", "/game-cards", "/all-services",
    "/history", "/promotions", "/referral", "/profile",
    "/profile/identity", "/profile/kyc-level", "/profile/ekyc",
    "/profile/digital-signature", "/profile/email-settings", "/profile/nfc-reader",
    "/settings", "/settings/security", "/settings/devices", "/settings/change-pin",
    "/notifications", "/notifications/settings",
    "/support/help-center", "/auth/terms", "/more",
    "/auth/forgot-password", "/auth/forgot-pin", "/auth/login", "/auth/register"
})


class IngestResponse(BaseModel):
    status: str
    documents_indexed: int
    chunks_created: int
    details: List[Dict[str, Any]] = []

class HealthResponse(BaseModel):
    status: str
    vector_db_ready: bool
    embedding_model: str
    llm_configured: bool
    total_vectors: int
    configured_keys_count: int = 1
