import base64
import json
import logging
from typing import Optional
from contextlib import asynccontextmanager
from fastapi import FastAPI, Header, HTTPException, Depends, Request, status
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse

from app.config import settings
from app.rate_limiter import SlidingWindowRateLimiter, sanitize_user_id
from app.schemas import (
    ChatRequest,
    ChatResponse,
    IngestResponse,
    HealthResponse
)
from app.rag_engine import rag_engine

"""
MÔ HÌNH TIN CẬY (TRUST MODEL) — Production Hardening:
1. Client (mobile) -> API Gateway :8080: gateway verify JWT người dùng, sau đó
   inject header X-User-Id + X-Internal-Key khi forward về chatbot-service.
2. Chatbot yêu cầu X-Internal-Key BẮT BUỘC trên mọi endpoint (trừ /health, /).
   Port host chỉ bind 127.0.0.1 — truy cập ngoài phải qua gateway.
3. X-User-Id được chấp nhận CHỈ khi đúng định dạng UUID/slug (sanitize_user_id);
   giá trị lạ bị bỏ -> xử lý như khách vãng lai, không dội lỗi về client.
4. Rate limit sliding-window theo user/IP trên endpoint chat.
5. Lưu ý vận hành: X-Internal-Key là shared secret tĩnh — cần xoay định kỳ qua env
   INTERNAL_API_KEY ở gateway VÀ service cùng lúc.
"""

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
    version="1.1.0",
    lifespan=lifespan
)

# Rate limit sliding-window (in-memory, 1 worker) cho endpoint chat theo user/IP
rate_limiter = SlidingWindowRateLimiter(settings.RATE_LIMIT_PER_MINUTE)
RATE_LIMITED_PATHS = {"/api/v1/chat", "/chat"}


@app.middleware("http")
async def rate_limit_middleware(request: Request, call_next):
    if request.url.path in RATE_LIMITED_PATHS:
        client_ip = request.client.host if request.client else "unknown"
        identity = sanitize_user_id(request.headers.get("x-user-id")) or client_ip
        if not rate_limiter.allow(identity):
            retry_after = rate_limiter.retry_after_seconds(identity)
            logger.warning("Rate limit exceeded for %s (retry after %ss)", identity, retry_after)
            return JSONResponse(
                status_code=status.HTTP_429_TOO_MANY_REQUESTS,
                headers={"Retry-After": str(retry_after)},
                content={"detail": "Quý khách gửi yêu cầu quá nhanh. Vui lòng chờ ít giây rồi thử lại ạ."},
            )
    return await call_next(request)

# CORS Middleware (service nằm sau API Gateway; browser client không gọi thẳng)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=False,
    allow_methods=["GET", "POST"],
    allow_headers=["*"],
)

def verify_internal_key(x_internal_key: str = Header(None)):
    """Xác thực Header bảo mật nội bộ giữa API Gateway và Chatbot Service (bắt buộc)."""
    if settings.INTERNAL_API_KEY and x_internal_key != settings.INTERNAL_API_KEY:
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
    vector_ready = count > 0

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
    effective_user_id = sanitize_user_id(header_user_id) or sanitize_user_id(jwt_user_id) or sanitize_user_id(request.user_id)
    if header_user_id and not effective_user_id:
        logger.warning("Rejected malformed X-User-Id header (treated as anonymous).")
    logger.info("Received chat query from user %s: '%s'", effective_user_id or "Anonymous", request.question)
    try:
        return rag_engine.answer_query(
            request.question,
            request.history,
            user_id=effective_user_id,
            client_context=request.client_context
        )
    except Exception as e:
        logger.exception("Error in answer_query: %s", e)
        # Không lộ chi tiết exception nội bộ (DB URL, stack) cho client
        raise HTTPException(status_code=500, detail="Hệ thống tạm thời gặp sự cố. Quý khách vui lòng thử lại sau ạ.")

@app.post("/admin/ingest", response_model=IngestResponse, tags=["Admin"])
def admin_ingest(force: bool = False, _auth: bool = Depends(verify_internal_key)):
    """
    Điểm nạp lại dữ liệu tài liệu ngân hàng từ data/ vào PostgreSQL pgvector:
    - Bắt buộc header X-Internal-Key
    - Mặc định ingest tăng dần: file chưa đổi (content_hash trùng ingest_state) sẽ được bỏ qua
    - force=true → nạp lại toàn bộ bất kể hash
    """
    logger.info("Admin triggered %s ingestion...", "full (force)" if force else "incremental")
    return rag_engine.ingest_documents(force=force)

