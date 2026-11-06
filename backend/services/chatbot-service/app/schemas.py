from typing import List, Optional, Dict, Any
from pydantic import BaseModel, Field

class MessageItem(BaseModel):
    role: str = Field(..., description="'user' hoặc 'assistant'")
    content: str = Field(..., description="Nội dung tin nhắn")

class ActionItem(BaseModel):
    type: str = Field(default="NAVIGATE", description="'NAVIGATE' hoặc 'DEEP_LINK'")
    label: str = Field(..., description="Nhãn hiển thị trên nút bấm hành động")
    route: str = Field(..., description="Đường dẫn điều hướng màn hình trên Flutter")

class ChatRequest(BaseModel):
    question: str = Field(..., min_length=1, description="Câu hỏi của khách hàng")
    history: Optional[List[MessageItem]] = Field(default=[], description="Lịch sử hội thoại trước đó")
    user_id: Optional[str] = Field(default=None, description="Mã định danh khách hàng (nếu truyền trong body)")

class ChatResponse(BaseModel):
    answer: str = Field(..., description="Câu trả lời từ trợ lý AI")
    sources: List[str] = Field(default=[], description="Danh sách tài liệu trích dẫn nguồn")
    quick_replies: List[str] = Field(default=[], description="Gợi ý câu hỏi tiếp theo")
    suggested_action: Optional[ActionItem] = Field(default=None, description="Hành động điều hướng nhanh trên App")
    latency_ms: float = Field(default=0.0, description="Thời gian xử lý tính bằng mili-giây")

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
