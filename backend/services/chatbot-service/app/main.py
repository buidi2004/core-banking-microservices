import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI, Header, HTTPException, Depends, status
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

@app.post("/api/v1/chat", response_model=ChatResponse, tags=["Chat"])
def chat(
    request: ChatRequest,
    x_user_id: str = Header(None, alias="X-User-Id"),
    _auth: bool = Depends(verify_internal_key)
):
    """
    Điểm tiếp nhận câu hỏi của khách hàng:
    - Nhận câu hỏi và lịch sử trò chuyện
    - Lọc PII và kiểm tra Guardrails bảo mật
    - Tìm kiếm Top-K vector tương đồng trong ChromaDB
    - Gọi LLM qua OpenAI SDK và trả về câu trả lời kèm trích dẫn nguồn
    """
    effective_user_id = x_user_id or request.user_id
    logger.info("Received chat query from user %s: '%s'", effective_user_id or "Anonymous", request.question)
    return rag_engine.answer_query(request.question, request.history, user_id=effective_user_id)

@app.post("/admin/ingest", response_model=IngestResponse, tags=["Admin"])
def admin_ingest(_auth: bool = Depends(verify_internal_key)):
    """
    Điểm nạp lại dữ liệu tài liệu ngân hàng từ data/ vào ChromaDB:
    - Bắt buộc header X-Internal-Key
    - Đọc file .md, chunking và sinh embedding mới
    """
    logger.info("Admin triggered manual ingestion...")
    return rag_engine.ingest_documents()

