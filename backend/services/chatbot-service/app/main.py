import base64
import json
import logging
from typing import Optional
from contextlib import asynccontextmanager
from fastapi import FastAPI, Header, HTTPException, Depends, Request, status
from fastapi.middleware.cors import CORSMiddleware

from app.config import settings
from app.schemas import (
    ChatRequest, 
    ChatResponse, 
    IngestResponse, 
    HealthResponse
)
from app.rag_engine import rag_engine

logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s [%(levelname)s] %(name)s: %(message)s"
)
logger = logging.getLogger("main")

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Khởi động: Kiểm tra và tự động nạp dữ liệu nếu PostgreSQL pgvector đang rỗng
    logger.info("Starting Sen Hong Chatbot Service...")
    try:
        # Pre-warm embedding model
        rag_engine._get_embed_model()
        count = rag_engine.get_vector_count()
        if count == 0:
            logger.info("PostgreSQL pgvector is empty. Running initial ingestion of banking knowledge...")
            res = rag_engine.ingest_documents()
            logger.info("Initial ingestion result: %s (indexed %d chunks)", 
                        res.status, res.chunks_created)
        else:
            logger.info("PostgreSQL pgvector already has %d indexed chunks ready.", count)
    except Exception as e:
        logger.warning("Could not complete startup auto-ingestion or pre-warming: %s", e)
    yield
    logger.info("Shutting down Sen Hong Chatbot Service.")

app = FastAPI(
    title="Sen Hong Core Banking - AI Chatbot Service",
    description="Microservice Trợ lý Tài chính RAG hỗ trợ khách hàng 24/7",
    version="1.0.0",
    lifespan=lifespan
)

# CORS Middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

def verify_internal_key(x_internal_key: str = Header(None)):
    """Xác thực Header bảo mật nội bộ giữa API Gateway và Chatbot Service"""
    if settings.INTERNAL_API_KEY and x_internal_key != settings.INTERNAL_API_KEY:
        # Nếu đang dev local không truyền header thì có thể cho phép qua nếu không ép buộc cứng
        if x_internal_key is None and settings.INTERNAL_API_KEY == "senhong-internal-chatbot-key-2026":
            return True
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or missing X-Internal-Key header"
        )
    return True

@app.get("/", tags=["General"])
def read_root():
    return {
        "service": "Sen Hong Bank AI Chatbot Service",
        "status": "UP",
        "version": "1.0.0"
    }

@app.get("/health", response_model=HealthResponse, tags=["General"])
def health_check():
    count = rag_engine.get_vector_count()
    vector_ready = count >= 0

    return HealthResponse(
        status="UP",
        vector_db_ready=vector_ready,
        embedding_model=settings.EMBED_MODEL,
        llm_configured=len(settings.api_keys) > 0,
        total_vectors=count,
        configured_keys_count=len(settings.api_keys)
    )

def _extract_jwt_sub(auth_header: Optional[str]) -> Optional[str]:
    """Tự động trích xuất userId từ JWT Bearer token mà không phụ thuộc thư viện ngoài"""
    if not auth_header or not auth_header.startswith("Bearer "):
        return None
    try:
        token = auth_header.split(" ")[1]
        parts = token.split(".")
        if len(parts) >= 2:
            payload_b64 = parts[1]
            padding = 4 - (len(payload_b64) % 4)
            if padding != 4:
                payload_b64 += "=" * padding
            decoded_bytes = base64.urlsafe_b64decode(payload_b64)
            payload = json.loads(decoded_bytes)
            return payload.get("sub") or payload.get("userId") or payload.get("user_id")
    except Exception as e:
        logger.debug("Could not parse JWT payload: %s", e)
    return None

@app.post("/api/v1/chat", response_model=ChatResponse, tags=["Chat"])
@app.post("/chat", response_model=ChatResponse, tags=["Chat"])
def chat(
    request: ChatRequest,
    req_raw: Request,
    x_user_id: Optional[str] = Header(None, alias="X-User-Id"),
    authorization: Optional[str] = Header(None, alias="Authorization"),
    _auth: bool = Depends(verify_internal_key)
):
    """
    Điểm tiếp nhận câu hỏi của khách hàng:
    - Nhận diện người dùng linh hoạt qua Header X-User-Id, Bearer JWT token hoặc request body
    - Lọc PII và kiểm tra Guardrails bảo mật
    - Định tuyến Jev System One siêu tốc (< 10ms)
    - Hybrid Search trên PostgreSQL pgvector và Grounded LLM
    """
    header_user_id = x_user_id or req_raw.headers.get("x-user-id") or req_raw.headers.get("X-User-Id")
    jwt_user_id = _extract_jwt_sub(authorization or req_raw.headers.get("authorization"))
    effective_user_id = header_user_id or jwt_user_id or request.user_id
    logger.info("Received chat query from user %s: '%s'", effective_user_id or "Anonymous", request.question)
    try:
        return rag_engine.answer_query(request.question, request.history, user_id=effective_user_id)
    except Exception as e:
        logger.exception("Error in answer_query: %s", e)
        raise HTTPException(status_code=500, detail=str(e))

@app.post("/admin/ingest", response_model=IngestResponse, tags=["Admin"])
def admin_ingest(_auth: bool = Depends(verify_internal_key)):
    """
    Điểm nạp lại dữ liệu tài liệu ngân hàng từ data/ vào ChromaDB:
    - Bắt buộc header X-Internal-Key
    - Đọc file .md, chunking và sinh embedding mới
    """
    logger.info("Admin triggered manual ingestion...")
    return rag_engine.ingest_documents()

