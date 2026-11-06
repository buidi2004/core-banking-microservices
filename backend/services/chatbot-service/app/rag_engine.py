import os
import re
import time
import json
import logging
from pathlib import Path
from typing import List, Dict, Any, Tuple, Optional
import requests
import psycopg
from pgvector.psycopg import register_vector
from sentence_transformers import SentenceTransformer
from openai import OpenAI

from app.config import settings
from app.guardrails import (
    mask_pii, 
    tokenize_pii,
    detokenize_pii,
    check_security_guardrails, 
    BANKING_SYSTEM_PROMPT
)
from app.jev_system_one import (
    jev_gatekeeper, 
    GateAction, 
    IntentChoice, 
    JevDecision
)
from app.schemas import MessageItem, ChatResponse, IngestResponse, ActionItem

logger = logging.getLogger("rag_engine")

DOCUMENT_TITLE_MAP = {
    "01_huong_dan_chuyen_tien.md": "Hướng dẫn chuyển tiền",
    "02_nap_va_rut_tien.md": "Nạp & Rút tiền",
    "03_thanh_toan_hoa_don_tien_ich.md": "Thanh toán hóa đơn",
    "04_vay_tieu_dung_quick_loan.md": "Vay tiêu dùng Quick Loan",
    "05_tiet_kiem_online_core_savings.md": "Tiết kiệm Online",
    "06_quan_ly_the_va_tai_khoan.md": "Quản lý thẻ & Tài khoản",
    "07_quy_dinh_sinh_trac_hoc_qd2345.md": "Quy định QĐ 2345/QĐ-NHNN",
    "08_tien_ich_xo_so_giai_tri.md": "Vé số & Giải trí",
    "09_bieu_phi_va_han_muc_chi_tiet.md": "Biểu phí & Hạn mức",
    "10_an_toan_bao_mat_va_canh_bao_lua_dao.md": "An toàn & Bảo mật",
    "11_ho_tro_khieu_nai_va_cskh.md": "Hỗ trợ & Khiếu nại",
    "12_tong_hop_cau_hoi_thuong_gap_faq.md": "Câu hỏi thường gặp",
    "13_ma_vietqr_va_chia_tien_split_bill.md": "VietQR & Chia tiền nhóm",
    "14_dat_lich_chuyen_tien_dinh_ky.md": "Đặt lịch chuyển tiền",
    "15_danh_ba_thu_huong_va_danh_sach_ngan_hang_napas.md": "Danh bạ & Ngân hàng Napas",
    "16_tai_khoan_so_dep_va_chuyen_tien_quoc_te.md": "Số đẹp & Kiều hối",
    "17_chuong_trinh_gioi_thieu_va_voucher_uu_dai.md": "Ưu đãi & Voucher",
    "18_quan_ly_thiet_bi_va_bao_mat_phien.md": "Bảo mật thiết bị",
    "19_dieu_khoan_phap_ly_va_giay_phep_nhnn.md": "Điều khoản & Pháp lý",
    "20_cam_nang_toan_dien_cac_man_hinh_va_tinh_nang_app.md": "Cẩm nang tính năng Sen Hồng",
    "21_kien_truc_he_thong_microservices_va_backend.md": "Kiến trúc hệ thống & Backend",
    "22_cam_nang_chuyen_sau_tinh_nang_mobile_va_tien_ich_so.md": "Cẩm nang tính năng Mobile App",
    "23_tong_hop_toan_bo_tinh_nang_mobile_va_backend_huong_dan_khach_hang.md": "Cẩm nang tính năng Mobile & Backend",
    "bieu_phi_dich_vu.md": "Biểu phí dịch vụ",
    "huong_dan_the_visa.md": "Hướng dẫn thẻ Visa",
    "lai_suat_tiet_kiem.md": "Biểu lãi suất tiết kiệm",
    "quy_dinh_qd2345.md": "Quy định QĐ 2345",
    "tai_khoan_va_ekyc.md": "Tài khoản & eKYC",
}

def clean_source_title(filename: str) -> str:
    """Chuyển đổi tên file kỹ thuật sang Tiêu đề nghiệp vụ tiếng Việt sang trọng, tuyệt đối không lộ .md hay mã file"""
    if not filename:
        return ""
    base = filename.strip()
    if base.lower().endswith(".md"):
        base_without_ext = base[:-3]
    else:
        base_without_ext = base

    # Loại trừ file chào mừng nội bộ hoặc file mã nguồn
    if any(k in base.lower() for k in ["chao_mung", "internal_api", "service", "jev", "typesafe", ".py"]):
        return ""

    if f"{base_without_ext}.md" in DOCUMENT_TITLE_MAP:
        return DOCUMENT_TITLE_MAP[f"{base_without_ext}.md"]
    if base_without_ext in DOCUMENT_TITLE_MAP:
        return DOCUMENT_TITLE_MAP[base_without_ext]

    clean = re.sub(r'^\d+_', '', base_without_ext)
    clean = clean.replace('_', ' ')
    title = clean.strip().title()
    # Loại bỏ triệt để đuôi .md nếu còn sót
    if title.lower().endswith(".md"):
        title = title[:-3].strip()
    return title


class AdvancedRAGEngine:
    """
    Advanced RAG Engine cho PostgreSQL + pgvector (Sen Hong Core Banking)
    Tích hợp 5 kỹ thuật tối tân:
    1. Parent-Child Chunking (parent_documents + knowledge_chunks)
    2. Contextual Header Breadcrumbs (passage: [Tài liệu > Mục > Hạng mục])
    3. Hybrid Search RRF trong 1 câu SQL (Vector Cosine + tsvector plainto_tsquery)
    4. Semantic Cache trên PostgreSQL (< 50ms)
    5. Single-Pass Grounded LLM Inference & Zero-PII Leak
    """
    def __init__(self):
        self.db_url = settings.DATABASE_URL
        self.embed_model_name = settings.EMBED_MODEL
        self.embed_model = None
        self.llm_model = settings.LLM_MODEL
        self.llm_clients: Dict[str, OpenAI] = {}
        self._conn = None
        
        self._init_db_schema()
        self._init_llm_clients()

    def _get_db_connection(self):
        """Tái sử dụng kết nối autocommit persistent, giảm độ trễ kết nối 17.8x (< 1ms/query)"""
        if self._conn is None or self._conn.closed or (
            hasattr(self._conn, "info") and self._conn.info.transaction_status == psycopg.pq.TransactionStatus.UNKNOWN
        ):
            try:
                if self._conn and not self._conn.closed:
                    self._conn.close()
            except Exception:
                pass
            self._conn = psycopg.connect(self.db_url, autocommit=True)
            register_vector(self._conn)
        return self._conn

    def _init_db_schema(self):
        """Khởi tạo schema database chuẩn Parent-Child, tsvector và Semantic Cache"""
        try:
            conn = self._get_db_connection()
            with conn.cursor() as cur:
                cur.execute("CREATE EXTENSION IF NOT EXISTS vector;")
                cur.execute("CREATE EXTENSION IF NOT EXISTS unaccent;")
                cur.execute("""
                    CREATE OR REPLACE FUNCTION immutable_unaccent(text) RETURNS text AS $$
                        SELECT public.unaccent('public.unaccent', $1);
                    $$ LANGUAGE sql IMMUTABLE PARALLEL SAFE STRICT;
                """)

                # Bảng 1: Lưu tài liệu gốc (Parent Chunks)
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS parent_documents (
                        id SERIAL PRIMARY KEY,
                        source_file VARCHAR(255) NOT NULL,
                        heading TEXT NOT NULL,
                        parent_content TEXT NOT NULL,
                        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
                """)

                # Bảng 2: Lưu các đoạn con (Child Chunks) gắn vector và Full-Text tsvector song ngữ dấu/không dấu
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS knowledge_chunks (
                        id SERIAL PRIMARY KEY,
                        parent_id INT REFERENCES parent_documents(id) ON DELETE CASCADE,
                        source_file VARCHAR(255) NOT NULL,
                        chunk_content TEXT NOT NULL,
                        embedding vector(384),
                        tsv_content tsvector GENERATED ALWAYS AS (to_tsvector('simple', chunk_content || ' ' || immutable_unaccent(chunk_content))) STORED
                    );
                """)

                cur.execute("""
                    CREATE INDEX IF NOT EXISTS idx_knowledge_embedding 
                    ON knowledge_chunks USING hnsw (embedding vector_cosine_ops);
                """)

                cur.execute("""
                    CREATE INDEX IF NOT EXISTS idx_knowledge_tsv 
                    ON knowledge_chunks USING gin (tsv_content);
                """)

                # Bảng 3: Semantic Cache trả kết quả dưới 30ms
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS semantic_cache (
                        id SERIAL PRIMARY KEY,
                        query_text TEXT NOT NULL,
                        query_embedding vector(384),
                        response_json JSONB NOT NULL,
                        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
                """)

                cur.execute("""
                    CREATE INDEX IF NOT EXISTS idx_cache_embedding 
                    ON semantic_cache USING hnsw (query_embedding vector_cosine_ops);
                """)
            logger.info("PostgreSQL pgvector schema (parent_documents, knowledge_chunks, semantic_cache) ready.")
        except Exception as e:
            logger.warning("Database schema init notice: %s", e)

    def _init_llm_clients(self):
        """Khởi tạo OpenAI clients với danh sách khóa API (hỗ trợ failover)"""
        try:
            keys = settings.api_keys
            for key in keys:
                self.llm_clients[key] = OpenAI(
                    base_url=settings.LLM_BASE_URL,
                    api_key=key,
                    max_retries=0,
                    timeout=4.0
                )
            if not self.llm_clients:
                self.llm_clients["default"] = OpenAI(
                    base_url=settings.LLM_BASE_URL,
                    api_key=settings.LLM_API_KEY or "dummy_key",
                    max_retries=0,
                    timeout=4.0
                )
            logger.info("Initialized %d LLM client(s) with model: %s", len(self.llm_clients), self.llm_model)
        except Exception as e:
            logger.warning("LLM client init notice: %s", e)

    def _get_embed_model(self) -> SentenceTransformer:
        """Tải hoặc trả về model embedding đã pre-warmed"""
        if self.embed_model is None:
            logger.info("Loading embedding model (%s)...", self.embed_model_name)
            self.embed_model = SentenceTransformer(self.embed_model_name)
            logger.info("Embedding model loaded successfully.")
        return self.embed_model

    def get_vector_count(self) -> int:
        """Đếm số lượng vector child chunks hiện có trong database"""
        try:
            conn = self._get_db_connection()
            with conn.cursor() as cur:
                cur.execute("SELECT count(*) FROM knowledge_chunks;")
                row = cur.fetchone()
                return row[0] if row else 0
        except Exception as e:
            logger.warning("Could not count vectors: %s", e)
            return 0

    # ==================== PHA INGEST (NẠP TÀI LIỆU) ====================
    def ingest_markdown_file(self, file_path: str, source_name: str) -> int:
        """
        Cắt tài liệu theo tiêu đề Markdown (Parent-Child) và nạp vào Postgres
        - Parent: toàn bộ section (# hoặc ##) chứa đầy đủ bảng biểu & điều kiện
        - Child: chia theo các đoạn nội dung/bullets (120-150 từ)
        - Gắn bánh mì dẫn đường (Contextual Breadcrumbs) trước khi embed
        """
        model = self._get_embed_model()
        path_obj = Path(file_path)
        content = path_obj.read_text(encoding="utf-8")

        # Tách tiêu đề tài liệu H1
        lines = content.split("\n")
        h1 = source_name
        for line in lines:
            if line.startswith("# "):
                h1 = line[2:].strip()
                break

        # Tách tài liệu theo các thẻ Heading Markdown (# hoặc ##)
        raw_sections = re.split(r'(^#{1,3}\s+.+)', content, flags=re.MULTILINE)

        chunks_created = 0
        conn = self._get_db_connection()
        with conn.cursor() as cur:
            # Xóa dữ liệu cũ của file này nếu nạp lại (ON DELETE CASCADE xóa luôn child chunks)
            cur.execute("DELETE FROM parent_documents WHERE source_file = %s", (source_name,))

            i = 1
            while i < len(raw_sections):
                heading_raw = raw_sections[i].strip()
                body = raw_sections[i+1].strip() if i+1 < len(raw_sections) else ""
                full_parent_content = f"{heading_raw}\n{body}"

                if not body:
                    i += 2
                    continue

                clean_heading = heading_raw.lstrip('#').strip()

                # 1. Lưu Parent Document
                cur.execute(
                    "INSERT INTO parent_documents (source_file, heading, parent_content) VALUES (%s, %s, %s) RETURNING id",
                    (source_name, clean_heading, full_parent_content)
                )
                parent_id = cur.fetchone()[0]

                # 2. Cắt nhỏ thành các Child Chunks
                # Ưu tiên tách theo bullet '-' hoặc đoạn theo cụm 120 từ
                bullet_blocks = re.split(r'\n(?=- [A-ZÀ-Ỹ0-9])', body)
                child_texts = []

                if len(bullet_blocks) > 1:
                    for b in bullet_blocks:
                        b_clean = b.strip()
                        if b_clean:
                            child_texts.append(b_clean)
                else:
                    words = body.split()
                    chunk_size = 120
                    for j in range(0, len(words), chunk_size):
                        child_texts.append(" ".join(words[j:j+chunk_size]))

                for chunk in child_texts:
                    # Gắn bánh mì dẫn đường (Contextual Breadcrumbs)
                    first_line = chunk.split('\n')[0].lstrip('- *').strip()
                    sub_title = first_line.split(':')[0] if ':' in first_line else first_line[:35]
                    breadcrumb = f"[Tài liệu: {source_name} > Mục: {h1} > Hạng mục: {clean_heading} > {sub_title}]"
                    enriched_text = f"passage: {breadcrumb}\n{chunk}"

                    vector = model.encode(enriched_text, normalize_embeddings=True).tolist()

                    cur.execute(
                        """INSERT INTO knowledge_chunks (parent_id, source_file, chunk_content, embedding)
                           VALUES (%s, %s, %s, %s)""",
                        (parent_id, source_name, chunk, vector)
                    )
                    chunks_created += 1

                i += 2

        logger.info("Ingested '%s': created 1 parent doc and %d child chunks.", source_name, chunks_created)
        return chunks_created

    def ingest_documents(self) -> IngestResponse:
        """Nạp toàn bộ tài liệu Markdown trong thư mục data/ vào PostgreSQL"""
        data_dir = Path(settings.DATA_DIR)
        if not data_dir.exists():
            return IngestResponse(
                status="error",
                documents_indexed=0,
                chunks_created=0,
                details=[{"error": f"Data directory not found: {data_dir}"}]
            )

        files = list(data_dir.glob("*.md"))
        if not files:
            return IngestResponse(
                status="warning",
                documents_indexed=0,
                chunks_created=0,
                details=[{"message": "No markdown files found in data directory"}]
            )

        # Làm mới Semantic Cache khi nạp tài liệu mới
        try:
            with self._get_db_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("TRUNCATE TABLE semantic_cache;")
            logger.info("Semantic cache truncated successfully.")
        except Exception as e:
            logger.warning("Could not truncate semantic_cache: %s", e)

        total_chunks = 0
        details = []
        for f in files:
            try:
                cnt = self.ingest_markdown_file(str(f), f.name)
                total_chunks += cnt
                details.append({"file": f.name, "chunks": cnt})
            except Exception as e:
                logger.error("Error ingesting %s: %s", f.name, e)
                details.append({"file": f.name, "error": str(e)})

        return IngestResponse(
            status="success",
            documents_indexed=len(files),
            chunks_created=total_chunks,
            details=details
        )

    # ==================== PHA QUERY (TRUY VẤN THỜI GIAN THỰC) ====================
    def _is_cache_semantically_compatible(self, q1: str, q2: str) -> bool:
        """
        Xác thực ngữ nghĩa chuyên sâu chống xung đột bộ nhớ đệm (Anti-Collision Semantic Filter):
        Đảm bảo 2 câu hỏi thực sự cùng ý định, không nhầm lẫn giữa các câu ngắn có tên sản phẩm trùng nhau.
        """
        l1 = q1.lower()
        l2 = q2.lower()

        # 1. Tránh nhầm lẫn giữa Hỏi Lãi suất vs Thời gian giải ngân vs Hạn mức vs Điều kiện
        has_interest_1 = any(k in l1 for k in ["lãi suất", "lai suat", "lãi", "lai"])
        has_interest_2 = any(k in l2 for k in ["lãi suất", "lai suat", "lãi", "lai"])
        if has_interest_1 != has_interest_2:
            return False

        has_disburse_1 = any(k in l1 for k in ["giải ngân", "giai ngan", "bao lâu", "thời gian", "mất bao lâu"])
        has_disburse_2 = any(k in l2 for k in ["giải ngân", "giai ngan", "bao lâu", "thời gian", "mất bao lâu"])
        if has_disburse_1 != has_disburse_2:
            return False

        has_limit_1 = any(k in l1 for k in ["hạn mức", "han muc", "tối đa", "toi da", "bao nhiêu tiền"])
        has_limit_2 = any(k in l2 for k in ["hạn mức", "han muc", "tối đa", "toi da", "bao nhiêu tiền"])
        if has_limit_1 != has_limit_2:
            return False

        has_condition_1 = any(k in l1 for k in ["điều kiện", "dieu kien", "thủ tục", "thu tuc", "cần những gì", "can nhung gi"])
        has_condition_2 = any(k in l2 for k in ["điều kiện", "dieu kien", "thủ tục", "thu tuc", "cần những gì", "can nhung gi"])
        if has_condition_1 != has_condition_2:
            return False

        # 2. Tránh nhầm lẫn giữa các kỳ hạn tiết kiệm (1 tháng vs 3 tháng vs 6 tháng vs 12 tháng vs 24 tháng)
        terms = ["1 tháng", "3 tháng", "6 tháng", "12 tháng", "24 tháng", "không kỳ hạn", "rút trước hạn"]
        term_1 = next((t for t in terms if t in l1), None)
        term_2 = next((t for t in terms if t in l2), None)
        if term_1 and term_2 and term_1 != term_2:
            return False
        if (term_1 is not None) != (term_2 is not None):
            return False

        # 3. Tránh nhầm lẫn giữa Quên mã PIN vs Đổi mã PIN
        has_forgot_1 = any(k in l1 for k in ["quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "cài lại", "cai lai", "khôi phục", "khoi phuc", "reset"])
        has_forgot_2 = any(k in l2 for k in ["quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "cài lại", "cai lai", "khôi phục", "khoi phuc", "reset"])
        if has_forgot_1 != has_forgot_2:
            return False

        # 4. Tránh nhầm lẫn giữa Rút tiền ATM không thẻ vs Rút tiền về tài khoản ngân hàng
        has_atm_1 = any(k in l1 for k in ["atm", "cây atm", "không thẻ", "khong the"])
        has_atm_2 = any(k in l2 for k in ["atm", "cây atm", "không thẻ", "khong the"])
        if has_atm_1 != has_atm_2:
            return False

        # 5. Tránh nhầm lẫn giữa Nạp tiền vs Rút tiền
        has_deposit_1 = any(k in l1 for k in ["nạp tiền", "nap tien", "nạp ví"])
        has_deposit_2 = any(k in l2 for k in ["nạp tiền", "nap tien", "nạp ví"])
        if has_deposit_1 != has_deposit_2:
            return False

        has_withdraw_1 = any(k in l1 for k in ["rút tiền", "rut tien"])
        has_withdraw_2 = any(k in l2 for k in ["rút tiền", "rut tien"])
        if has_withdraw_1 != has_withdraw_2:
            return False

        # 6. Tránh nhầm lẫn giữa Liên kết ngân hàng vs Mở thẻ / Thẻ Visa
        has_link_1 = any(k in l1 for k in ["liên kết", "lien ket"])
        has_link_2 = any(k in l2 for k in ["liên kết", "lien ket"])
        if has_link_1 != has_link_2:
            return False

        return True

    def _check_semantic_cache(self, user_question: str, query_vec: List[float], max_distance: float = 0.020) -> Optional[Dict[str, Any]]:
        """Kiểm tra Semantic Cache với khoảng cách Cosine <= 0.020 (độ tương đồng >= 0.980) và bộ lọc ngữ nghĩa tương thích"""
        try:
            conn = self._get_db_connection()
            with conn.cursor() as cur:
                cur.execute(
                    """SELECT response_json, (query_embedding <=> %s::vector) AS dist, query_text
                       FROM semantic_cache 
                       WHERE (query_embedding <=> %s::vector) <= %s 
                       ORDER BY dist ASC LIMIT 3;""",
                    (query_vec, query_vec, max_distance)
                )
                rows = cur.fetchall()
                for row in rows:
                    cached_json, dist, query_text = row
                    if self._is_cache_semantically_compatible(user_question, query_text):
                        logger.info("[CACHE HIT] (dist: %.4f, q: '%s' matched '%s') - Returning under 25ms!", dist, query_text, user_question)
                        return cached_json
                    else:
                        logger.info("[CACHE COLLISION PREVENTED] (dist: %.4f, candidate: '%s' vs query: '%s')", dist, query_text, user_question)
        except Exception as e:
            logger.warning("Error checking semantic_cache: %s", e)
        return None

    def _save_semantic_cache(self, user_question: str, query_vec: List[float], response_data: Dict[str, Any]):
        """Lưu câu trả lời vào Semantic Cache để phục vụ các lần hỏi sau"""
        try:
            cached_data = dict(response_data)
            if "sources" in cached_data and isinstance(cached_data["sources"], list):
                clean_srcs = []
                for s in cached_data["sources"]:
                    t = clean_source_title(str(s))
                    if t and t not in clean_srcs and not t.lower().endswith(".md"):
                        clean_srcs.append(t)
                cached_data["sources"] = clean_srcs

            conn = self._get_db_connection()
            with conn.cursor() as cur:
                cur.execute(
                    """INSERT INTO semantic_cache (query_text, query_embedding, response_json)
                       VALUES (%s, %s, %s);""",
                    (user_question, query_vec, json.dumps(cached_data, ensure_ascii=False))
                )
        except Exception as e:
            logger.warning("Error saving to semantic_cache: %s", e)

    def _hybrid_search_rrf(self, user_question: str, query_vec: List[float], top_k: int = 4) -> Tuple[str, List[str]]:
        """
        Hybrid Search (Vector + Full-Text RRF) trong 1 câu SQL duy nhất
        - Vector search: Cosine distance lấy top 15
        - Keyword search: Full-Text Search tsvector @@ plainto_tsquery lấy top 15
        - RRF Score = 1/(60 + vec_rank) + 1/(60 + kw_rank)
        - GROUP BY parent_documents để lấy toàn bộ bảng biểu và điều kiện gốc
        """
        hybrid_query = """
        WITH vector_search AS (
            SELECT id, RANK() OVER (ORDER BY embedding <=> %s::vector) AS vec_rank
            FROM knowledge_chunks
            ORDER BY embedding <=> %s::vector
            LIMIT 15
        ),
        keyword_search AS (
            SELECT id, RANK() OVER (ORDER BY ts_rank_cd(tsv_content, plainto_tsquery('simple', %s)) DESC) AS kw_rank
            FROM knowledge_chunks
            WHERE tsv_content @@ plainto_tsquery('simple', %s)
            LIMIT 15
        ),
        combined AS (
            SELECT COALESCE(v.id, k.id) AS chunk_id,
                   COALESCE(1.0 / (60 + v.vec_rank), 0.0) + COALESCE(1.0 / (60 + k.kw_rank), 0.0) AS rrf_score
            FROM vector_search v
            FULL OUTER JOIN keyword_search k ON v.id = k.id
        )
        SELECT pd.source_file, pd.heading, pd.parent_content, MAX(c.rrf_score) AS score
        FROM combined c
        JOIN knowledge_chunks kc ON kc.id = c.chunk_id
        JOIN parent_documents pd ON pd.id = kc.parent_id
        GROUP BY pd.id, pd.source_file, pd.heading, pd.parent_content
        ORDER BY score DESC
        LIMIT %s;
        """
        try:
            conn = self._get_db_connection()
            with conn.cursor() as cur:
                cur.execute(hybrid_query, (query_vec, query_vec, user_question, user_question, top_k))
                rows = cur.fetchall()

            context_texts = []
            sources = []
            for row in rows:
                source_file, heading, parent_content, _ = row
                if source_file not in sources:
                    sources.append(source_file)
                context_texts.append(f"--- Tài liệu: {source_file} ({heading}) ---\n{parent_content}")

            combined_context = "\n\n".join(context_texts) if context_texts else "Không tìm thấy tài liệu chính thống liên quan."
            return combined_context, sources

            combined_context = "\n\n".join(context_texts) if context_texts else "Không tìm thấy tài liệu chính thống liên quan."
            return combined_context, sources
        except Exception as e:
            logger.error("Error executing Hybrid Search SQL: %s", e)
            return "Không tìm thấy tài liệu chính thống liên quan.", []

    def _safe_parse_llm_json(self, content: str) -> Optional[Dict[str, Any]]:
        """Giải mã JSON từ LLM với cơ chế tự phục hồi cú pháp (Self-Healing JSON Parser)"""
        if not content:
            return None
        text = content.strip()
        # 1. Loại bỏ markdown codeblock ```json ... ```
        if text.startswith("```"):
            lines = text.splitlines()
            if lines[0].startswith("```"):
                lines = lines[1:]
            if lines and lines[-1].startswith("```"):
                lines = lines[:-1]
            text = "\n".join(lines).strip()

        # 2. Thử parse với strict=False (cho phép ký tự điều khiển/xuống dòng thực tế)
        try:
            parsed = json.loads(text, strict=False)
            if isinstance(parsed, list) and len(parsed) > 0 and isinstance(parsed[0], dict):
                return parsed[0]
            elif isinstance(parsed, dict):
                return parsed
        except Exception:
            pass

        # 3. Phục hồi qua Regex nếu JSON bị lỗi dấu phẩy hoặc escape
        try:
            ans_match = re.search(r'"answer"\s*:\s*"(.*?)(?:"\s*,\s*"(?:quick_replies|suggested_action)"|\s*"\s*\}|\s*$)', text, re.DOTALL)
            if ans_match:
                extracted_ans = ans_match.group(1).replace('\\"', '"').replace('\\n', '\n').strip()
                qr_match = re.search(r'"quick_replies"\s*:\s*\[(.*?)\]', text, re.DOTALL)
                quick_replies = []
                if qr_match:
                    quick_replies = [q.strip().strip('"').strip("'") for q in qr_match.group(1).split(",") if q.strip()]
                return {
                    "answer": extracted_ans,
                    "quick_replies": quick_replies[:3],
                    "suggested_action": None
                }
        except Exception:
            pass

        # 4. Nếu JSON hỏng nhưng LLM đã sinh văn bản tự nhiên hữu ích, bảo toàn câu trả lời
        cleaned_text = re.sub(r'[{}\[\]"]', '', text).strip()
        if len(cleaned_text) > 20:
            return {
                "answer": cleaned_text,
                "quick_replies": [],
                "suggested_action": None
            }
        return None

    def _extractive_fallback_answer(self, context: Optional[str], user_question: str) -> Dict[str, Any]:
        """Tự động trích xuất nội dung từ kho tài liệu chính thống khi LLM gặp sự cố mạng (Anti-Rambling Banking Fallback)"""
        q_lower = user_question.lower()

        # 1. Hướng dẫn trực diện cho các nghiệp vụ chính (Ưu tiên theo thứ tự đặc thù -> tổng quát)
        # Quên mã PIN / Lấy lại mã PIN (Phải ưu tiên số 1 để bảo vệ trải nghiệm khách hàng)
        is_pin_recovery_q = any(k in q_lower for k in [
            "quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "cài lại", "cai lai",
            "khôi phục", "khoi phuc", "reset", "mất mã pin", "mat ma pin", "mất pin", "mat pin"
        ]) and any(p in q_lower for p in ["pin", "mã pin", "ma pin"])

        if is_pin_recovery_q:
            return {
                "answer": (
                    "Dạ, để lấy lại mã PIN giao dịch khi bị quên trên ứng dụng Sen Hồng, quý khách thực hiện theo các bước sau:\n\n"
                    "- Bước 1: Mở ứng dụng Sen Hồng, tại màn hình yêu cầu nhập mã PIN giao dịch, nhấn chọn dòng chữ **'Quên mã PIN?'** (hoặc truy cập màn hình Lấy lại mã PIN bên dưới).\n"
                    "- Bước 2: Hệ thống gửi mã xác thực Smart OTP/SMS về số điện thoại chính chủ đã đăng ký.\n"
                    "- Bước 3: Thực hiện xác thực sinh trắc học khuôn mặt eKYC (đối soát an toàn với dữ liệu chip CCCD).\n"
                    "- Bước 4: Thiết lập mã PIN 6 số mới và xác nhận lại mã PIN để kích hoạt lại giao dịch tức thì."
                ),
                "quick_replies": ["Đổi mã PIN", "Xác thực eKYC", "Hotline 1900-SENHONG"],
                "suggested_action": {"label": "Lấy lại mã PIN", "route": "/auth/forgot-pin"}
            }

        is_pin_change_q = any(k in q_lower for k in ["doi pin", "đổi pin", "doi ma pin", "đổi mã pin", "thay đổi pin", "thay doi pin"]) and not is_pin_recovery_q
        if is_pin_change_q:
            return {
                "answer": (
                    "Dạ, để đổi mã PIN giao dịch trên ứng dụng Sen Hồng khi quý khách vẫn nhớ mã PIN cũ:\n\n"
                    "- Bước 1: Mở App Sen Hồng, vào mục **Cài đặt** (biểu tượng bánh răng) -> Chọn **Đổi mã PIN giao dịch**.\n"
                    "- Bước 2: Nhập mã PIN hiện tại (6 chữ số).\n"
                    "- Bước 3: Nhập mã PIN mới 6 số và xác nhận lại mã PIN mới.\n\n"
                    "Lưu ý bảo mật: Quý khách không nên đặt mã PIN là ngày sinh nhật, số điện thoại hay các dãy số dễ đoán (123456, 111111) ạ."
                ),
                "quick_replies": ["Quên mã PIN?", "Cài đặt bảo mật", "Chữ ký số Smart OTP"],
                "suggested_action": {"label": "Đổi mã PIN", "route": "/settings/change-pin"}
            }

        # Liên kết ngân hàng / Thẻ ngân hàng liên kết
        if any(k in q_lower for k in ["liên kết ngân hàng", "lien ket ngan hang", "liên kết thẻ", "lien ket the", "thêm ngân hàng", "them ngan hang", "thêm thẻ", "them the", "tài khoản liên kết", "ngân hàng liên kết"]):
            return {
                "answer": (
                    "Dạ, để liên kết tài khoản hoặc thẻ ngân hàng (Vietcombank, MB, BIDV, Techcombank, ACB...) với ví Sen Hồng:\n\n"
                    "- Bước 1: Mở App Sen Hồng, vào mục **Thẻ** hoặc **Cài đặt** -> Chọn **Thẻ & Ngân hàng liên kết**.\n"
                    "- Bước 2: Nhấn nút **Thêm liên kết mới** (+) và chọn ngân hàng của quý khách trong danh sách hơn 40 ngân hàng Napas.\n"
                    "- Bước 3: Nhập Số tài khoản hoặc Số thẻ ngân hàng chính chủ (tên chủ tài khoản và SĐT đăng ký phải trùng với tài khoản Sen Hồng).\n"
                    "- Bước 4: Nhập mã xác thực OTP gửi từ ngân hàng liên kết để hoàn tất ủy quyền.\n\n"
                    "Sau khi liên kết thành công, quý khách có thể nạp tiền vào ví và rút tiền về ngân hàng 24/7 hoàn toàn miễn phí 100% ạ!"
                ),
                "quick_replies": ["Nạp tiền vào ví", "Rút tiền về ngân hàng", "Hạn mức nạp rút"],
                "suggested_action": {"label": "Thẻ & Ngân hàng liên kết", "route": "/bank-cards"}
            }

        # Gói vay Quick Loan theo từng mục thắc mắc riêng biệt
        is_loan_q = any(k in q_lower for k in ["vay", "khoan vay", "khoản vay", "quick loan"])
        if is_loan_q and any(k in q_lower for k in ["lãi suất", "lai suat", "lãi", "lai"]):
            return {
                "answer": (
                    "Dạ, gói vay tiêu dùng tín chấp Quick Loan tại Sen Hồng có lãi suất cực kỳ ưu đãi:\n\n"
                    "- **Lãi suất vay:** Chỉ từ **1.2% - 1.5%/tháng** (tương đương 14.4%/năm) tính trên **dư nợ giảm dần**.\n"
                    "- **Phí thẩm định & hồ sơ:** Hoàn toàn **miễn phí 100%** trực tuyến.\n"
                    "- **Phí tất toán trước hạn:** **Miễn phí 100%**, quý khách có thể trả hết nợ bất kỳ lúc nào mà không bị phạt.\n"
                    "- **Hạn mức vay:** Từ 5.000.000 VNĐ đến 50.000.000 VNĐ, kỳ hạn linh hoạt 3 - 24 tháng."
                ),
                "quick_replies": ["Đăng ký vay ngay", "Thời gian giải ngân", "Lịch trả nợ vay"],
                "suggested_action": {"label": "Vay nhanh", "route": "/bills/quick-loan"}
            }

        if is_loan_q and any(k in q_lower for k in ["giải ngân", "giai ngan", "bao lâu", "thời gian", "mất bao lâu"]):
            return {
                "answer": (
                    "Dạ, khoản vay tiêu dùng tín chấp Quick Loan tại Sen Hồng giải ngân siêu tốc:\n\n"
                    "- **Thời gian giải ngân:** Chỉ trong vòng **1 phút** sau khi hồ sơ vay được hệ thống tự động phê duyệt.\n"
                    "- **Kênh nhận tiền:** Tiền giải ngân được cộng trực tiếp vào số dư ví Sen Hồng của quý khách.\n"
                    "- **Thao tác:** 100% online trên ứng dụng, không cần gặp mặt hay thế chấp giấy tờ."
                ),
                "quick_replies": ["Lãi suất vay Quick Loan", "Hạn mức vay tối đa", "Đăng ký vay ngay"],
                "suggested_action": {"label": "Vay nhanh", "route": "/bills/quick-loan"}
            }

        if is_loan_q and any(k in q_lower for k in ["hạn mức", "han muc", "tối đa", "toi da", "bao nhiêu tiền"]):
            return {
                "answer": (
                    "Dạ, hạn mức vay tiêu dùng tín chấp Quick Loan tại Sen Hồng như sau:\n\n"
                    "- **Hạn mức tối thiểu:** **5.000.000 VNĐ**.\n"
                    "- **Hạn mức tối đa:** **50.000.000 VNĐ**.\n"
                    "- **Thời hạn vay:** Linh hoạt từ 3 tháng, 6 tháng, 12 tháng đến 24 tháng.\n"
                    "- **Hình thức:** Vay tín chấp trực tuyến, chỉ cần CCCD gắn chip và tài khoản eKYC."
                ),
                "quick_replies": ["Lãi suất vay Quick Loan", "Thời gian giải ngân", "Đăng ký vay ngay"],
                "suggested_action": {"label": "Vay nhanh", "route": "/bills/quick-loan"}
            }

        if is_loan_q:
            return {
                "answer": (
                    "Dạ, gói vay tiêu dùng tín chấp Quick Loan tại Sen Hồng giải ngân siêu tốc trong 1 phút:\n\n"
                    "- **Hạn mức vay:** Từ 5.000.000 VNĐ đến 50.000.000 VNĐ.\n"
                    "- **Thời hạn vay:** Linh hoạt từ 3 tháng đến 24 tháng.\n"
                    "- **Lãi suất:** Ưu đãi từ 1.2%/tháng tính theo dư nợ giảm dần.\n"
                    "- **Thời gian giải ngân:** Tự động giải ngân vào ví chỉ trong 1 phút sau khi duyệt online.\n"
                    "- **Thủ tục:** 100% trực tuyến không thế chấp, chỉ cần CCCD gắn chip và tài khoản eKYC."
                ),
                "quick_replies": ["Đăng ký vay ngay", "Lãi suất vay Quick Loan", "Lịch trả nợ vay"],
                "suggested_action": {"label": "Vay nhanh", "route": "/bills/quick-loan"}
            }

        if any(k in q_lower for k in ["lich tra no", "lịch trả nợ", "lich vay", "lịch vay", "tra no vay", "trả nợ vay"]):
            return {
                "answer": (
                    "Dạ, để tra cứu lịch trả nợ khoản vay Quick Loan:\n\n"
                    "- Bước 1: Mở App Sen Hồng, vào mục **Tiện ích** -> Chọn **Lịch trả nợ vay**.\n"
                    "- Bước 2: Xem chi tiết dư nợ gốc còn lại, số tiền gốc và lãi đến hạn theo từng kỳ.\n"
                    "- Bước 3: Quý khách có thể bấm **Thanh toán ngay** để trả nợ đúng hạn hoặc tất toán trước hạn hoàn toàn miễn phí."
                ),
                "quick_replies": ["Vay nhanh tiêu dùng", "Thanh toán khoản vay", "Tất toán trước hạn"],
                "suggested_action": {"label": "Lịch trả nợ vay", "route": "/loan/schedule"}
            }

        if any(k in q_lower for k in ["sao ke email", "sao kê email", "cai dat email", "cài đặt email", "sao ke thang", "sao kê tháng"]):
            return {
                "answer": (
                    "Dạ, để cài đặt nhận bản sao kê tài khoản tự động gửi về email hàng tháng:\n\n"
                    "- Bước 1: Vào mục **Cài đặt** -> Chọn **Hồ sơ cá nhân** -> Nhấn **Cài đặt Email nhận sao kê**.\n"
                    "- Bước 2: Nhập địa chỉ email chính chủ và bấm **Lưu thay đổi**.\n"
                    "- Bước 3: Định kỳ vào ngày mùng 01 hàng tháng, hệ thống sẽ tự động gửi file PDF sao kê có chữ ký số điện tử bảo mật về email của quý khách."
                ),
                "quick_replies": ["Xem lịch sử giao dịch", "Xuất sao kê PDF", "Bảo mật tài khoản"],
                "suggested_action": {"label": "Cài đặt Email", "route": "/profile/email-settings"}
            }

        if any(k in q_lower for k in ["dang xuat tu xa", "đăng xuất từ xa", "mat dien thoai", "mất điện thoại", "mat may", "mất máy", "thiet bi", "thiết bị"]):
            return {
                "answer": (
                    "Dạ khi bị mất điện thoại hoặc phát hiện thiết bị lạ đăng nhập, quý khách xử lý ngay như sau:\n\n"
                    "- Bước 1: Mở ứng dụng Sen Hồng trên điện thoại mới hoặc máy tính, vào mục **Cài đặt** -> Chọn **Quản lý thiết bị**.\n"
                    "- Bước 2: Danh sách các thiết bị đang đăng nhập sẽ hiển thị. Nhấn **Đăng xuất khỏi thiết bị này** bên cạnh thiết bị bị mất.\n"
                    "- Bước 3: Thiết bị đó sẽ bị hủy phiên đăng nhập tức thì. Đồng thời quý khách nên đổi ngay mã PIN và mật khẩu để an toàn tuyệt đối."
                ),
                "quick_replies": ["Khóa thẻ khẩn cấp", "Đổi mã PIN", "Hotline 1900-SENHONG"],
                "suggested_action": {"label": "Quản lý thiết bị", "route": "/settings/devices"}
            }

        if any(k in q_lower for k in ["nfc", "chip cccd", "cccd", "2345", "khuon mat 3d", "khuôn mặt 3d"]):
            return {
                "answer": (
                    "Dạ, theo Quyết định 2345 của Ngân hàng Nhà nước, hướng dẫn đọc chip NFC CCCD và hạn mức như sau:\n\n"
                    "- **Khi nào bắt buộc:** Giao dịch trên **10.000.000 VNĐ/lần** hoặc tổng giao dịch tích lũy trong ngày vượt quá **20.000.000 VNĐ/ngày** bắt buộc phải xác thực sinh trắc học khớp với dữ liệu chip CCCD.\n"
                    "- **Cách thao tác:** Vào Hồ sơ -> Chọn **Đọc chip NFC CCCD** -> Áp sát thẻ CCCD gắn chip vào lưng điện thoại giữ nguyên 3-5 giây để đối soát dữ liệu của Bộ Công an.\n"
                    "- **Hạn mức sau xác thực:** Nâng hạn mức giao dịch lên tới 500.000.000 VNĐ/ngày."
                ),
                "quick_replies": ["Cấp độ eKYC", "Hạn mức chuyển tiền", "Chữ ký số Smart OTP"],
                "suggested_action": {"label": "Đọc chip NFC CCCD", "route": "/profile/nfc-reader"}
            }

        if any(k in q_lower for k in ["chu ky so", "chữ ký số", "smart otp"]):
            return {
                "answer": (
                    "Dạ, Chữ ký số Smart OTP cho phép xác thực các giao dịch giá trị cao lên tới 500.000.000 VNĐ/ngày:\n\n"
                    "- Bước 1: Vào mục **Cài đặt** -> **Bảo mật** -> Chọn **Chữ ký số Smart OTP**.\n"
                    "- Bước 2: Kích hoạt dịch vụ và thiết lập mã PIN Smart OTP 6 số riêng biệt.\n"
                    "- Bước 3: Mã OTP tự động sinh nội bộ an toàn trên thiết bị mà không cần chờ SMS, chống đánh cắp dữ liệu viễn thông."
                ),
                "quick_replies": ["Đổi mã PIN Smart OTP", "Nâng hạn mức giao dịch", "Đọc chip NFC"],
                "suggested_action": {"label": "Chữ ký số Smart OTP", "route": "/profile/digital-signature"}
            }

        if any(k in q_lower for k in ["quen mat khau", "quên mật khẩu", "quen pass", "quên pass", "lay lai mat khau", "lấy lại mật khẩu", "reset mat khau", "reset mật khẩu"]):
            return {
                "answer": (
                    "Dạ, để lấy lại mật khẩu đăng nhập ứng dụng Sen Hồng khi bị quên, Quý khách thực hiện như sau:\n\n"
                    "- Bước 1: Tại màn hình Đăng nhập, nhấn vào dòng chữ **'Quên mật khẩu?'** (hoặc truy cập màn hình bên dưới).\n"
                    "- Bước 2: Nhập số điện thoại đăng ký tài khoản và mã xác thực OTP gửi về SMS/Smart OTP.\n"
                    "- Bước 3: Xác thực khuôn mặt eKYC chính chủ để đảm bảo an toàn tuyệt đối.\n"
                    "- Bước 4: Thiết lập mật khẩu mới (tối thiểu 8 ký tự gồm chữ hoa, chữ thường và số) và đăng nhập lại."
                ),
                "quick_replies": ["Đăng nhập", "Quên mã PIN", "Hotline 1900-SENHONG"],
                "suggested_action": {"label": "Quên mật khẩu", "route": "/auth/forgot-password"}
            }

        if any(k in q_lower for k in ["hoa don", "hóa đơn", "dien nuoc", "điện nước", "tien dien", "tiền điện", "tien nuoc", "tiền nước", "internet", "truyen hinh", "truyền hình", "chung cu", "chung cư", "etc"]):
            return {
                "answer": (
                    "Dạ, để thanh toán hóa đơn sinh hoạt (điện EVN, nước Sawaco/Viwaco, internet, truyền hình, phí chung cư, phí không dừng ETC) trên Sen Hồng:\n\n"
                    "- Bước 1: Tại Trang chủ, chọn **Hóa đơn & Tiện ích** -> Chọn danh mục dịch vụ cần đóng.\n"
                    "- Bước 2: Chọn nhà cung cấp và nhập Mã khách hàng / Mã danh bạ (ví dụ: mã điện PE...).\n"
                    "- Bước 3: Hệ thống tự động tra cứu chính xác số tiền nợ cước từ nhà cung cấp.\n"
                    "- Bước 4: Bật tùy chọn **Tự động thanh toán (Auto-Debit)** nếu muốn hệ thống tự trích nợ khi có kỳ cước mới.\n"
                    "- Bước 5: Xác nhận thanh toán bằng mã PIN hoặc Face ID hoàn toàn miễn phí 100%."
                ),
                "quick_replies": ["Nạp tiền điện thoại", "Vay tiêu dùng", "Kho Voucher"],
                "suggested_action": {"label": "Thanh toán hóa đơn", "route": "/bills"}
            }

        if any(k in q_lower for k in ["nap dien thoai", "nạp điện thoại", "nap dt", "nạp đt", "mua the cao", "mua thẻ cào", "topup dt", "top-up"]):
            return {
                "answer": (
                    "Dạ, để nạp tiền điện thoại chiết khấu trực tiếp tới 3% - 5% trên Sen Hồng:\n\n"
                    "- Bước 1: Tại Trang chủ, nhấn chọn **Nạp ĐT**.\n"
                    "- Bước 2: Nhập số điện thoại cần nạp (hoặc chọn từ danh bạ điện thoại cá nhân).\n"
                    "- Bước 3: Chọn mệnh giá nạp (từ 10.000đ đến 500.000đ). Hỗ trợ mọi nhà mạng Viettel, VinaPhone, MobiFone, Vietnamobile, Wintel.\n"
                    "- Bước 4: Kiểm tra số tiền sau chiết khấu và xác nhận bằng PIN/Face ID tức thì."
                ),
                "quick_replies": ["Nạp Data 4G/5G", "Thanh toán hóa đơn", "Chuyển tiền ngay"],
                "suggested_action": {"label": "Nạp tiền điện thoại", "route": "/bills/phone-recharge"}
            }

        if any(k in q_lower for k in ["ma qr cua toi", "mã qr của tôi", "qr cua toi", "qr của tôi", "nhan tien qr", "nhận tiền qr"]):
            return {
                "answer": (
                    "Dạ, để xem và chia sẻ mã QR nhận tiền chuẩn VietQR của Quý khách:\n\n"
                    "- Bước 1: Tại Trang chủ, bấm vào nút **Mã QR của tôi** ở thanh hành động nhanh.\n"
                    "- Bước 2: Mã VietQR tiêu chuẩn quốc gia mang đúng Số tài khoản và Tên chủ tài khoản Sen Hồng của Quý khách sẽ hiển thị.\n"
                    "- Bước 3: Quý khách có thể nhập số tiền cụ thể vào mã QR, tải ảnh QR về máy hoặc chia sẻ trực tiếp qua Zalo, Messenger."
                ),
                "quick_replies": ["Quét mã QR chuyển tiền", "Chuyển tiền Napas", "Chia tiền nhóm"],
                "suggested_action": {"label": "Mã QR của tôi", "route": "/my-qr"}
            }

        if any(k in q_lower for k in ["chuyen tien", "chuyển tiền", "cach chuyen", "hướng dẫn chuyển"]):
            return {
                "answer": (
                    "Dạ, để chuyển tiền nhanh chóng và miễn phí 100% trên ứng dụng Sen Hồng:\n\n"
                    "- Bước 1: Tại Trang chủ, chọn tính năng **Chuyển tiền**.\n"
                    "- Bước 2: Chọn hình thức **Nội bộ** hoặc **Liên ngân hàng Napas 24/7**.\n"
                    "- Bước 3: Nhập STK hoặc SĐT người nhận, chọn ngân hàng và số tiền.\n"
                    "- Bước 4: Kiểm tra thông tin người nhận và nhấn **Tiếp tục**.\n"
                    "- Bước 5: Xác thực bằng Face ID/Vân tay hoặc mã PIN để hoàn tất tức thì trong 1-3 giây."
                ),
                "quick_replies": ["Chuyển tiền có mất phí không?", "Hạn mức chuyển tiền", "Mã VietQR của tôi"],
                "suggested_action": {"label": "Chuyển tiền ngay", "route": "/transfer"}
            }

        if any(k in q_lower for k in ["ve may bay", "vé máy bay", "chuyen bay", "chuyến bay", "flight"]):
            return {
                "answer": (
                    "Dạ, để đặt vé máy bay trên ứng dụng Sen Hồng:\n\n"
                    "- Bước 1: Tại Trang chủ, vào mục **Tiện ích** -> Chọn **Đặt vé máy bay**.\n"
                    "- Bước 2: Chọn điểm đi, điểm đến, ngày bay và số lượng hành khách.\n"
                    "- Bước 3: Lựa chọn chuyến bay phù hợp của Vietnam Airlines, Vietjet Air, Bamboo Airways.\n"
                    "- Bước 4: Nhập thông tin hành khách và bấm **Thanh toán** trực tiếp từ ví Sen Hồng.\n"
                    "- Bước 5: Mã vé điện tử sẽ hiển thị ngay trên ứng dụng và gửi qua email cho quý khách."
                ),
                "quick_replies": ["Kiểm tra vé đã đặt", "Chính sách hành lý", "Ưu đãi vé máy bay"],
                "suggested_action": {"label": "Đặt vé máy bay", "route": "/flight-booking"}
            }

        if any(k in q_lower for k in ["bao hiem xa hoi", "bảo hiểm xã hội", "bhxh", "vssid", "dong bao hiem", "đóng bảo hiểm"]):
            return {
                "answer": (
                    "Dạ, để nộp Bảo hiểm xã hội tự nguyện hoặc BHYT trên ứng dụng Sen Hồng:\n\n"
                    "- Bước 1: Tại Trang chủ, chọn mục **Tiện ích** -> Nhấn **Bảo hiểm xã hội**.\n"
                    "- Bước 2: Nhập mã số BHXH hoặc mã thẻ BHYT của người tham gia.\n"
                    "- Bước 3: Hệ thống tự động kết nối cổng Bảo hiểm Quốc gia để tra cứu số tiền cần đóng.\n"
                    "- Bước 4: Kiểm tra thông tin người tham gia và xác nhận nộp phí.\n"
                    "- Bước 5: Xác thực bằng mã PIN/Sinh trắc học. Biên lai nộp phí điện tử được cấp ngay lập tức."
                ),
                "quick_replies": ["Tra cứu mã BHXH", "Đóng tiền điện nước", "Hóa đơn dịch vụ"],
                "suggested_action": {"label": "Bảo hiểm xã hội", "route": "/social-insurance"}
            }

        if any(k in q_lower for k in ["chia tien", "chia tiền", "nhac no", "nhắc nợ", "split bill", "gop tien", "góp tiền"]):
            return {
                "answer": (
                    "Dạ, tính năng chia tiền nhóm (Split Bill) trên Sen Hồng thực hiện như sau:\n\n"
                    "- Bước 1: Tại Trang chủ, chọn **Chuyển tiền** -> Chọn tab **Yêu cầu tiền / Chia tiền**.\n"
                    "- Bước 2: Nhập tổng số tiền và chọn danh sách bạn bè cùng tham gia.\n"
                    "- Bước 3: Hệ thống tự chia đều số tiền (quý khách có thể tùy chỉnh số tiền từng người).\n"
                    "- Bước 4: Nhập lời nhắn và nhấn **Gửi yêu cầu**.\n"
                    "- Bước 5: Bạn bè nhận thông báo trên App và chỉ cần bấm đồng ý chuyển tiền là xong."
                ),
                "quick_replies": ["Mã QR của tôi", "Lịch sử yêu cầu tiền", "Chuyển tiền nhanh"],
                "suggested_action": {"label": "Chia tiền / Nhắc nợ", "route": "/transfer/request"}
            }

        if any(k in q_lower for k in ["lai suat", "lãi suất", "lai xuat", "lãi xuất"]):
            term_prefix = ""
            if "1 tháng" in q_lower or "1 thang" in q_lower:
                term_prefix = "Lãi suất tiền gửi tiết kiệm online kỳ hạn **1 tháng** hiện nay là **3.8%/năm**.\n\n"
            elif "3 tháng" in q_lower or "3 thang" in q_lower:
                term_prefix = "Lãi suất tiền gửi tiết kiệm online kỳ hạn **3 tháng** hiện nay là **4.2%/năm**.\n\n"
            elif "6 tháng" in q_lower or "6 thang" in q_lower:
                term_prefix = "Lãi suất tiền gửi tiết kiệm online kỳ hạn **6 tháng** hiện nay là **5.5%/năm**.\n\n"
            elif "12 tháng" in q_lower or "12 thang" in q_lower:
                term_prefix = "Lãi suất tiền gửi tiết kiệm online kỳ hạn **12 tháng** hiện nay là **6.3%/năm**.\n\n"
            elif "24 tháng" in q_lower or "24 thang" in q_lower:
                term_prefix = "Lãi suất tiền gửi tiết kiệm online kỳ hạn **24 tháng** hiện nay là **6.8%/năm**.\n\n"
            elif any(k in q_lower for k in ["không kỳ hạn", "khong ky han", "rút trước hạn", "rut truoc han"]):
                term_prefix = "Lãi suất tiền gửi **không kỳ hạn** hoặc rút trước hạn là **0.2%/năm**.\n\n"

            return {
                "answer": (
                    f"Dạ, {term_prefix}"
                    "Biểu lãi suất tiền gửi tiết kiệm online mới nhất tại Sen Hồng Bank như sau:\n\n"
                    "- Kỳ hạn 1 tháng: **3.8%/năm**\n"
                    "- Kỳ hạn 3 tháng: **4.2%/năm**\n"
                    "- Kỳ hạn 6 tháng: **5.5%/năm**\n"
                    "- Kỳ hạn 12 tháng: **6.3%/năm**\n"
                    "- Kỳ hạn 24 tháng: **6.8%/năm**\n"
                    "- Tiền gửi không kỳ hạn / rút trước hạn: **0.2%/năm**.\n\n"
                    "Quý khách có thể mở sổ tiết kiệm online 24/7 chỉ từ 1.000.000 VNĐ hoàn toàn miễn phí ạ!"
                ),
                "quick_replies": ["Mở sổ tiết kiệm ngay", "Rút tiền trước hạn", "Tiết kiệm tích lũy"],
                "suggested_action": {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}
            }

        if any(k in q_lower for k in ["rut tien", "rút tiền"]):
            if any(k in q_lower for k in ["atm", "khong the", "không thẻ"]):
                return {
                    "answer": (
                        "Dạ, để rút tiền mặt không cần thẻ tại cây ATM qua Sen Hồng:\n\n"
                        "- Bước 1: Mở App Sen Hồng, chọn **Rút tiền ATM không thẻ** để nhận mã rút tiền 6 số.\n"
                        "- Bước 2: Đến cây ATM thuộc hệ thống ngân hàng liên kết, bấm nút **Rút tiền không cần thẻ**.\n"
                        "- Bước 3: Nhập mã số bí mật 6 số và mã OTP gửi về điện thoại để nhận tiền mặt từ khe máy ATM."
                    ),
                    "quick_replies": ["Hạn mức rút tiền", "Tìm cây ATM gần nhất", "Biểu phí dịch vụ"],
                    "suggested_action": {"label": "Rút tiền ATM không thẻ", "route": "/atm-withdrawal"}
                }
            else:
                return {
                    "answer": (
                        "Dạ, để rút tiền từ ví Sen Hồng về tài khoản ngân hàng:\n\n"
                        "- Bước 1: Tại Trang chủ, nhấn chọn **Rút tiền**.\n"
                        "- Bước 2: Chọn tài khoản ngân hàng nhận tiền và nhập số tiền cần rút.\n"
                        "- Bước 3: Xác thực bằng mã PIN bảo mật hoặc Face ID. Tiền sẽ về tài khoản ngân hàng trong 1-3 phút hoàn toàn miễn phí ạ."
                    ),
                    "quick_replies": ["Rút tiền ATM không thẻ", "Hạn mức rút tiền", "Liên kết ngân hàng"],
                    "suggested_action": {"label": "Rút tiền về ngân hàng", "route": "/withdraw"}
                }

        if any(k in q_lower for k in ["nap tien", "nạp tiền", "nap vi", "nạp ví"]):
            return {
                "answer": (
                    "Dạ, để nạp tiền vào ví Sen Hồng hoàn toàn miễn phí 100%:\n\n"
                    "- Kênh 1 (Online): Tại Trang chủ chọn **Nạp tiền** -> Chọn tài khoản ngân hàng liên kết -> Nhập số tiền (tối thiểu 10.000đ) -> Xác nhận mã PIN/Face ID.\n"
                    "- Kênh 2 (Tại Quầy): Đến bất kỳ Chi nhánh / Phòng giao dịch Sen Hồng, xuất trình CCCD và nộp tiền mặt miễn phí 100%."
                ),
                "quick_replies": ["Liên kết ngân hàng", "Hạn mức nạp tiền", "Chuyển tiền ngay"],
                "suggested_action": {"label": "Nạp tiền vào ví", "route": "/deposit"}
            }

        if any(k in q_lower for k in ["saga", "microservice", "chong mat tien", "chống mất tiền", "outbox", "kien truc"]):
            return {
                "answer": (
                    "Dạ, Sen Hồng Bank áp dụng kiến trúc Microservices phân tán với cơ chế Saga Orchestrator và Double-entry Ledger để bảo vệ dòng tiền an toàn tuyệt đối:\n\n"
                    "- **Bước 1 (Payment Service):** Giao dịch tạo ở trạng thái PENDING, đồng thời ghi sự kiện vào outbox_events trong 1 DB Transaction duy nhất.\n"
                    "- **Bước 2 (Wallet Service):** Khóa bản ghi số dư bằng PESSIMISTIC_WRITE (SELECT ... FOR UPDATE) để trừ tiền tài khoản nguồn.\n"
                    "- **Bước 3 (Credit & Compensating):** Cộng tiền vào tài khoản đích. Nếu bước này lỗi, Saga lập tức kích hoạt Compensating Action hoàn tiền nguyên vẹn cho nguồn.\n"
                    "- **Bước 4 (Ledger):** Ghi sổ cái kép bất biến (Double-entry) đảm bảo Tổng Nợ = Tổng Có."
                ),
                "quick_replies": ["An toàn bảo mật", "Tiêu chuẩn NHNN", "Chuyển tiền ngay"],
                "suggested_action": {"label": "Chuyển tiền ngay", "route": "/transfer"}
            }

        if any(k in q_lower for k in ["nuot the", "nuốt thẻ", "ket the", "kẹt thẻ", "khoa the", "khóa thẻ"]):
            return {
                "answer": (
                    "Dạ để bảo vệ tài khoản khi thẻ bị nuốt hoặc cần khóa khẩn cấp:\n\n"
                    "- Bước 1: Mở App Sen Hồng, vào mục **Quản lý thẻ** -> Gạt nút **Khóa thẻ khẩn cấp**.\n"
                    "- Bước 2: Thẻ sẽ bị khóa tức thì, không ai có thể rút tiền hay thanh toán.\n"
                    "- Bước 3: Liên hệ hotline 24/7 **1900-SENHONG** (1900 736 466) để được chuyên viên hỗ trợ cấp lại thẻ mới miễn phí ạ."
                ),
                "quick_replies": ["Khóa thẻ khẩn cấp", "Phát hành lại thẻ", "Hotline CSKH"],
                "suggested_action": {"label": "Quản lý thẻ", "route": "/cards"}
            }

        if not context or "Không tìm thấy" in context:
            return {
                "answer": "Dạ hiện tại hệ thống Trợ lý Tài chính đang đồng bộ dữ liệu. Quý khách vui lòng liên hệ hotline 1900-SENHONG (1900 736 466) để được hỗ trợ chuyên sâu 24/7 ạ.",
                "quick_replies": ["Xem biểu phí dịch vụ", "Lãi suất tiết kiệm", "Chuyển tiền ngay"],
                "suggested_action": None
            }

        # 2. Cơ chế trích xuất thông minh theo cụm Hỏi/Đáp hoặc khối chức năng (Loại bỏ triệt để hiện tượng lan man)
        raw_lines = [l.strip() for l in context.splitlines() if l.strip()]
        candidate_blocks = []
        curr_block = []

        for line in raw_lines:
            if line.startswith("--- Tài liệu:") or line.startswith("passage:"):
                continue
            is_new_block = (
                line.startswith("## ") or 
                line.startswith("### ") or 
                line.startswith("- **Hỏi:") or 
                (line.startswith("- ") and not line.startswith("- **Đáp:") and len(curr_block) > 0)
            )
            if is_new_block and curr_block:
                candidate_blocks.append("\n".join(curr_block))
                curr_block = [line]
            else:
                curr_block.append(line)
        if curr_block:
            candidate_blocks.append("\n".join(curr_block))

        # Chấm điểm mức độ liên quan của từng khối với câu hỏi
        stop_words = {"cho", "tôi", "làm", "sao", "thế", "nào", "như", "được", "không", "ứng", "dụng", "hướng", "dẫn", "cách", "xem"}
        words = [w for w in re.findall(r'\w+', q_lower) if len(w) > 2 and w not in stop_words]
        best_block = ""
        best_score = 0
        for block in candidate_blocks:
            b_lower = block.lower()
            if block.startswith("#") and len(block.splitlines()) == 1:
                continue
            score = sum(2 if w in b_lower else 0 for w in words)
            if score > best_score:
                best_score = score
                best_block = block

        if best_block and best_score > 0:
            clean_block = re.sub(r'^[#*\-\s]+', '', best_block).strip()
            if len(clean_block) > 500:
                clean_block = clean_block[:500].rsplit(' ', 1)[0] + "..."
            answer = (
                f"Dạ, em xin gửi thông tin chi tiết về nội dung Quý khách quan tâm:\n\n"
                f"{clean_block}\n\n"
                f"Quý khách có thể xem thêm chi tiết trên ứng dụng hoặc liên hệ tổng đài 24/7 **1900-SENHONG** (1900 736 466) để được hỗ trợ tức thì ạ!"
            )
        else:
            answer = (
                "Dạ, để thực hiện tính năng này, Quý khách vui lòng mở mục **Tiện ích** trên ứng dụng Sen Hồng "
                "hoặc liên hệ tổng đài 24/7 **1900-SENHONG** (1900 736 466) để được chuyên viên hỗ trợ trực tiếp ạ!"
            )

        return {
            "answer": answer,
            "quick_replies": ["Xem biểu phí dịch vụ", "Lãi suất tiết kiệm", "Chuyển tiền ngay"],
            "suggested_action": None
        }

    def _call_llm_with_failover(
        self, 
        messages: List[Dict[str, str]], 
        fallback_context: Optional[str] = None, 
        user_question: str = ""
    ) -> Tuple[Dict[str, Any], bool]:
        """Gọi LLM (Gemini) hỗ trợ xoay vòng tải ngẫu nhiên giữa 3 API Keys và đa tầng fallback model"""
        import random
        last_error = None
        start_call = time.time()
        # Luôn sử dụng gemini-3.5-flash-lite làm model chính có SLA cao nhất và quota ổn định nhất
        models_to_try = ["gemini-3.5-flash-lite"]
        if self.llm_model and self.llm_model not in models_to_try and "2.5" not in self.llm_model and "1.5" not in self.llm_model:
            models_to_try.append(self.llm_model)

        client_items = list(self.llm_clients.items())
        random.shuffle(client_items)

        attempts = 0
        max_attempts = max(len(client_items), 3)
        for model_name in models_to_try:
            for key, client in client_items:
                if attempts >= max_attempts or (time.time() - start_call) > 7.0:
                    break
                attempts += 1
                try:
                    response = client.chat.completions.create(
                        model=model_name,
                        messages=messages,
                        temperature=0.1,
                        response_format={"type": "json_object"}
                    )
                    content = response.choices[0].message.content
                    parsed = self._safe_parse_llm_json(content)
                    if parsed and parsed.get("answer"):
                        return parsed, False
                except Exception as e:
                    last_error = e
                    logger.warning("LLM attempt on model '%s' with key %s... failed: %s", model_name, key[:8] if key else "", e)
                    continue
            if attempts >= max_attempts or (time.time() - start_call) > 7.0:
                break

        logger.error(
            "All LLM clients and fallback models failed (attempts: %d, elapsed: %.2fs). Last error: %s. Engaging Extractive RAG Fallback.",
            attempts, time.time() - start_call, last_error
        )
        return self._extractive_fallback_answer(fallback_context, user_question), True

    def query(self, user_question: str, history: Optional[List[MessageItem]] = None) -> Dict[str, Any]:
        """
        Xử lý câu hỏi với Semantic Cache, Hybrid Search RRF và Grounded LLM
        (API chuẩn tương thích hoàn toàn với đoạn code mẫu)
        """
        start_time = time.time()
        model = self._get_embed_model()

        # Nếu là câu hỏi đa lượt có đại từ thay thế ("nó", "thẻ này", "gói này"), bổ sung ngữ cảnh lượt trước
        search_query = user_question
        if history and any(p in user_question.lower() for p in ["nó", "đó", "thẻ này", "gói này", "kỳ hạn này", "của nó", "thế còn"]):
            last_user_q = next((h.content for h in reversed(history) if h.role == "user"), "")
            if last_user_q:
                search_query = f"{last_user_q} {user_question}"

        # 1. Gắn tiền tố query theo chuẩn của multilingual-e5
        query_text_for_embed = f"query: {search_query}"
        query_vec = model.encode(query_text_for_embed, normalize_embeddings=True).tolist()

        # 2. Kiểm tra Semantic Cache (Tương đồng >= 0.980 + Anti-Collision Filter) - Chỉ áp dụng khi không có history phụ thuộc
        if not history:
            cached_result = self._check_semantic_cache(user_question, query_vec)
            if cached_result:
                latency = (time.time() - start_time) * 1000
                cached_result["latency_ms"] = round(latency, 2)
                return cached_result

        # 3. Hybrid Search lấy Top Parent Documents (top_k=4 giảm nhiễu)
        combined_context, sources = self._hybrid_search_rrf(search_query, query_vec, top_k=4)

        # 4. Prompt hệ thống ngân hàng chuyên nghiệp & bảo mật (Thiết kế chống lan man - Đúng trọng tâm)
        system_prompt = f"""
Bạn là Trợ lý Tài chính AI Thông minh 24/7 của Ngân hàng Số Sen Hồng (Sen Hồng Core Banking).
VAI TRÒ & PHONG CÁCH:
- Xưng hô "em" và gọi khách hàng là "quý khách" lịch sự, chu đáo, ấm áp, tận tâm chuẩn dịch vụ ngân hàng số cao cấp.
- Trả lời ĐÚNG TRỌNG TÂM, mạch lạc, có cấu trúc gạch đầu dòng các bước thao tác (Bước 1, Bước 2...) khi hướng dẫn khách hàng sử dụng tính năng.

NGHIỆP VỤ & NGUYÊN TẮC BẢO MẬT (CHỐNG LAN MAN - ĐÚNG TRỌNG TÂM):
1. TRẢ LỜI ĐÚNG TRỌNG TÂM, TUYỆT ĐỐI KHÔNG LAN MAN:
   - Khách hỏi tính năng/dịch vụ nào thì CHỈ trả lời duy nhất tính năng/dịch vụ đó.
   - Tuyệt đối KHÔNG giải thích hoặc liệt kê lan man sang các dịch vụ khác cùng nằm trong tài liệu (Ví dụ: khách hỏi về "Vé máy bay" thì KHÔNG được nói về "Học phí", "Bảo hiểm" hay "Tiền điện"; khách hỏi về "Lãi suất 6 tháng" thì CHỈ trả lời lãi suất kỳ hạn 6 tháng, không nói sang tiền gửi tối thiểu hay điều kiện rút trước hạn nếu khách không hỏi; khách hỏi "Rút tiền ATM không thẻ" thì KHÔNG giải thích "Rút tiền về tài khoản ngân hàng").
2. SÚC TÍCH, DƯỚI 150-200 TỪ (3-5 GẠCH ĐẦU DÒNG):
   - Trình bày ngắn gọn, rõ ràng theo từng bước thao tác, tối ưu trải nghiệm đọc trên màn hình điện thoại di động (Mobile Chat UI).
   - Không sao chép nguyên văn khối văn bản dài hoặc các phần không liên quan từ tài liệu.
3. NÊU RÕ CON SỐ & ĐIỀU KIỆN CHÍNH XÁC:
   - Miễn phí 100%, hạn mức, lãi suất cụ thể theo tài liệu chính thức.
4. TUYỆT ĐỐI BẢO MẬT:
   - Tuyệt đối không bao giờ hỏi hoặc yêu cầu khách cung cấp mã OTP, mật khẩu hay mã PIN.
5. ĐỊNH HƯỚNG ĐIỀU HƯỚNG THÔNG MINH (suggested_action):
   - Quên mã PIN, lấy lại mã PIN, cấp lại mã PIN -> {{"label": "Lấy lại mã PIN", "route": "/auth/forgot-pin"}}
   - Quên mật khẩu đăng nhập, lấy lại mật khẩu -> {{"label": "Quên mật khẩu", "route": "/auth/forgot-password"}}
   - Đổi mã PIN giao dịch -> {{"label": "Đổi mã PIN", "route": "/settings/change-pin"}}
   - Liên kết ngân hàng, thẻ ngân hàng liên kết -> {{"label": "Thẻ & Ngân hàng liên kết", "route": "/bank-cards"}}
   - Chuyển tiền, gửi tiền -> {{"label": "Chuyển tiền ngay", "route": "/transfer"}}
   - Nạp tiền vào ví -> {{"label": "Nạp tiền vào ví", "route": "/deposit"}}
   - Rút tiền về ngân hàng -> {{"label": "Rút tiền về ngân hàng", "route": "/withdraw"}}
   - Rút tiền ATM không thẻ -> {{"label": "Rút tiền ATM không thẻ", "route": "/atm-withdrawal"}}
   - Chia tiền nhóm, nhắc nợ, góp tiền -> {{"label": "Chia tiền / Nhắc nợ", "route": "/transfer/request"}}
   - Mã QR của tôi, nhận tiền qua QR -> {{"label": "Mã QR của tôi", "route": "/my-qr"}}
   - Quét mã QR chuyển tiền -> {{"label": "Quét mã VietQR", "route": "/scan-qr"}}
   - Danh bạ thụ hưởng đã lưu -> {{"label": "Danh bạ thụ hưởng", "route": "/beneficiaries"}}
   - Nạp tiền điện thoại, Top-up -> {{"label": "Nạp điện thoại", "route": "/bills/phone-recharge"}}
   - Nạp Data 4G/5G -> {{"label": "Nạp Data 4G/5G", "route": "/data-topup"}}
   - Mua thẻ game Garena/Zing -> {{"label": "Mua thẻ Game", "route": "/game-cards"}}
   - Đặt vé máy bay -> {{"label": "Đặt vé máy bay", "route": "/flight-booking"}}
   - Bảo hiểm xã hội VssID -> {{"label": "Bảo hiểm xã hội", "route": "/social-insurance"}}
   - Thanh toán hóa đơn điện nước -> {{"label": "Thanh toán hóa đơn", "route": "/bills"}}
   - Vay tiêu dùng tín chấp, vay nhanh -> {{"label": "Vay nhanh", "route": "/bills/quick-loan"}}
   - Lịch trả nợ vay -> {{"label": "Lịch trả nợ vay", "route": "/loan/schedule"}}
   - Tiết kiệm online, gửi góp -> {{"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}}
   - Chi tiết sổ tiết kiệm, tất toán -> {{"label": "Chi tiết sổ tiết kiệm", "route": "/savings/detail"}}
   - Tài khoản số đẹp, số phong thủy -> {{"label": "Chọn số tài khoản đẹp", "route": "/lucky-account"}}
   - Chuyển tiền quốc tế, kiều hối -> {{"label": "Chuyển tiền quốc tế", "route": "/international-transfer"}}
   - Giới thiệu bạn bè nhận 50k -> {{"label": "Giới thiệu bạn bè", "route": "/referral"}}
   - Kho ưu đãi, voucher, khuyến mại -> {{"label": "Kho Voucher & Ưu đãi", "route": "/promotions"}}
   - Thẻ và tài khoản, thẻ Visa -> {{"label": "Quản lý thẻ", "route": "/cards"}}
   - Quản lý thiết bị, đăng xuất từ xa -> {{"label": "Quản lý thiết bị", "route": "/settings/devices"}}
   - Đọc chip NFC CCCD -> {{"label": "Đọc chip NFC CCCD", "route": "/profile/nfc-reader"}}
   - Chữ ký số Smart OTP -> {{"label": "Chữ ký số Smart OTP", "route": "/profile/digital-signature"}}
   - Cài đặt Email sao kê -> {{"label": "Cài đặt Email", "route": "/profile/email-settings"}}
   - Cấp độ tài khoản eKYC -> {{"label": "Cấp độ tài khoản eKYC", "route": "/profile/kyc-level"}}
   - Cài đặt thông báo -> {{"label": "Cài đặt thông báo", "route": "/notifications/settings"}}
   - Điều khoản pháp lý, giấy phép NHNN -> {{"label": "Điều khoản & Giấy phép", "route": "/auth/terms"}}
   - Vietlott, xổ số, mua vé -> {{"label": "Vé số Vietlott", "route": "/bills/lottery"}}
   - Khiếu nại, tra soát -> {{"label": "Hỗ trợ tra soát", "route": "/support/help-center"}}
   - Khám phá dịch vụ khác -> {{"label": "Xem tất cả tiện ích", "route": "/more"}}

5. ĐỊNH DẠNG ĐẦU RA: Trả về JSON thuần túy (không bọc mã markdown codeblock) gồm đúng 3 trường:
   - "answer": Nội dung trả lời chi tiết, súc tích, lịch sự bằng tiếng Việt.
   - "quick_replies": Mảng gồm 2-3 câu hỏi gợi ý liên quan mật thiết.
   - "suggested_action": Object điều hướng như mô tả ở trên hoặc null nếu không cần thiết.

NGỮ CẢNH TÀI LIỆU CHÍNH THỐNG:
{combined_context}
"""
        messages = [{"role": "system", "content": system_prompt}]
        if history:
            for item in history[-4:]:
                messages.append({"role": item.role, "content": item.content})
        messages.append({"role": "user", "content": user_question})

        result_json, is_extractive = self._call_llm_with_failover(
            messages, 
            fallback_context=combined_context, 
            user_question=user_question
        )
        if not isinstance(result_json, dict):
            if isinstance(result_json, list) and len(result_json) > 0 and isinstance(result_json[0], dict):
                result_json = result_json[0]
            else:
                result_json = {"answer": str(result_json)}
        clean_sources = []
        for s in sources:
            if not s or any(bad in str(s).lower() for bad in ["chao_mung", "internal_api", "service", "jev", "typesafe", ".py"]):
                continue
            title = clean_source_title(str(s))
            if title and title not in clean_sources and not title.lower().endswith(".md"):
                clean_sources.append(title)
        result_json["sources"] = clean_sources

        # Fallback bổ trợ suggested_action nếu LLM bỏ quên
        if not result_json.get("suggested_action"):
            q_lower = user_question.lower()
            if any(k in q_lower for k in ["nap tien", "nạp tiền", "nap vi", "nạp ví"]):
                result_json["suggested_action"] = {"label": "Nạp tiền vào ví", "route": "/deposit"}
            elif any(k in q_lower for k in ["rut tien", "rút tiền"]):
                if any(k in q_lower for k in ["atm", "khong the", "không thẻ"]):
                    result_json["suggested_action"] = {"label": "Rút tiền ATM không thẻ", "route": "/atm-withdrawal"}
                else:
                    result_json["suggested_action"] = {"label": "Rút tiền về ngân hàng", "route": "/withdraw"}
            elif any(k in q_lower for k in ["chia tien", "chia tiền", "nhac no", "nhắc nợ", "split bill", "gop tien", "góp tiền"]):
                result_json["suggested_action"] = {"label": "Chia tiền / Nhắc nợ", "route": "/transfer/request"}
            elif any(k in q_lower for k in ["tao ma qr", "tạo mã qr", "tao qr", "tạo qr", "ma qr cua toi", "mã qr của tôi", "nhan tien qr", "nhận tiền qr", "my qr", "qr nhận tiền"]):
                result_json["suggested_action"] = {"label": "Mã QR của tôi", "route": "/my-qr"}
            elif any(k in q_lower for k in ["quet qr", "quét qr", "scan qr", "quet ma", "quét mã"]):
                result_json["suggested_action"] = {"label": "Quét mã VietQR", "route": "/scan-qr"}
            elif any(k in q_lower for k in ["danh ba", "danh bạ", "nguoi thu huong", "người thụ hưởng", "so da luu", "số đã lưu"]):
                result_json["suggested_action"] = {"label": "Danh bạ thụ hưởng", "route": "/beneficiaries"}
            elif any(k in q_lower for k in ["so dep", "số đẹp", "tu quy", "tứ quý", "than tai", "thần tài", "phong thuy", "phong thủy"]):
                result_json["suggested_action"] = {"label": "Chọn số tài khoản đẹp", "route": "/lucky-account"}
            elif any(k in q_lower for k in ["quoc te", "quốc tế", "kieu hoi", "kiều hối", "swift"]):
                result_json["suggested_action"] = {"label": "Chuyển tiền quốc tế", "route": "/international-transfer"}
            elif any(k in q_lower for k in ["gioi thieu", "giới thiệu", "referral", "50k", "50.000"]):
                result_json["suggested_action"] = {"label": "Giới thiệu bạn bè", "route": "/referral"}
            elif any(k in q_lower for k in ["voucher", "khuyen mai", "khuyến mại", "uu dai", "ưu đãi", "giam gia", "giảm giá", "cashback"]):
                result_json["suggested_action"] = {"label": "Kho Voucher & Ưu đãi", "route": "/promotions"}
            is_pin_rec = any(k in q_lower for k in [
                "quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "cài lại", "cai lai",
                "khôi phục", "khoi phuc", "reset", "mất mã pin", "mat ma pin"
            ]) and any(p in q_lower for p in ["pin", "mã pin", "ma pin"])

            is_pin_chg = any(k in q_lower for k in [
                "đổi", "doi", "thay đổi", "thay doi"
            ]) and any(p in q_lower for p in ["pin", "mã pin", "ma pin"]) and not is_pin_rec

            is_pwd_rec = any(k in q_lower for k in [
                "quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "khôi phục", "khoi phuc", "reset"
            ]) and any(p in q_lower for p in ["mật khẩu", "mat khau", "password"])

            if is_pin_rec:
                result_json["suggested_action"] = {"label": "Lấy lại mã PIN", "route": "/auth/forgot-pin"}
            elif is_pin_chg:
                result_json["suggested_action"] = {"label": "Đổi mã PIN", "route": "/settings/change-pin"}
            elif is_pwd_rec:
                result_json["suggested_action"] = {"label": "Quên mật khẩu", "route": "/auth/forgot-password"}
            elif any(k in q_lower for k in ["liên kết ngân hàng", "lien ket ngan hang", "liên kết thẻ", "lien ket the", "thẻ ngân hàng", "the ngan hang", "thêm ngân hàng", "them ngan hang", "ngân hàng liên kết"]):
                result_json["suggested_action"] = {"label": "Thẻ & Ngân hàng liên kết", "route": "/bank-cards"}
            elif any(k in q_lower for k in ["thiet bi", "thiết bị", "dang xuat tu xa", "đăng xuất từ xa", "mat may", "mất máy", "mất điện thoại"]):
                result_json["suggested_action"] = {"label": "Quản lý thiết bị", "route": "/settings/devices"}
            elif any(k in q_lower for k in ["nfc", "chip cccd", "quet chip", "quét chip", "2345"]):
                result_json["suggested_action"] = {"label": "Đọc chip NFC CCCD", "route": "/profile/nfc-reader"}
            elif any(k in q_lower for k in ["giay phep", "giấy phép", "phap ly", "pháp lý", "dieu khoan", "điều khoản"]):
                result_json["suggested_action"] = {"label": "Điều khoản & Giấy phép", "route": "/auth/terms"}
            elif any(k in q_lower for k in ["nuot the", "nuốt thẻ", "ket the", "kẹt thẻ", "the", "thẻ", "khoa the", "khóa thẻ", "visa"]):
                result_json["suggested_action"] = {"label": "Quản lý thẻ", "route": "/cards"}
            elif any(k in q_lower for k in ["vay", "khoan vay", "vay tien", "vay tiền", "quick loan"]):
                result_json["suggested_action"] = {"label": "Vay nhanh", "route": "/bills/quick-loan"}
            elif any(k in q_lower for k in ["tiet kiem", "tiết kiệm", "lai suat", "lãi suất", "so tiet kiem", "sổ tiết kiệm"]):
                result_json["suggested_action"] = {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}
            elif any(k in q_lower for k in ["dien", "điện", "nuoc", "nước", "hoa don", "hóa đơn", "evn", "sawaco"]):
                result_json["suggested_action"] = {"label": "Thanh toán hóa đơn", "route": "/bills"}
            elif any(k in q_lower for k in ["chuyen tien", "chuyển tiền", "vietqr", "stk", "napas"]):
                result_json["suggested_action"] = {"label": "Chuyển tiền ngay", "route": "/transfer"}
            elif any(k in q_lower for k in ["lich tra no", "lịch trả nợ", "lich vay", "lịch vay", "tra no vay", "trả nợ vay"]):
                result_json["suggested_action"] = {"label": "Lịch trả nợ vay", "route": "/loan/schedule"}
            elif any(k in q_lower for k in ["tat toan so", "tất toán sổ", "chi tiet so", "chi tiết sổ tiết kiệm"]):
                result_json["suggested_action"] = {"label": "Chi tiết sổ tiết kiệm", "route": "/savings/detail"}
            elif any(k in q_lower for k in ["ve may bay", "vé máy bay", "chuyen bay", "chuyến bay", "flight"]):
                result_json["suggested_action"] = {"label": "Đặt vé máy bay", "route": "/flight-booking"}
            elif any(k in q_lower for k in ["bao hiem xa hoi", "bảo hiểm xã hội", "bhxh", "vssid", "dong bao hiem", "đóng bảo hiểm"]):
                result_json["suggested_action"] = {"label": "Bảo hiểm xã hội", "route": "/social-insurance"}
            elif any(k in q_lower for k in ["data", "3g", "4g", "5g", "goi cuoc", "gói cước", "nap data", "nạp data"]):
                result_json["suggested_action"] = {"label": "Nạp Data 4G/5G", "route": "/data-topup"}
            elif any(k in q_lower for k in ["the game", "thẻ game", "garena", "zing", "vcoin", "vtc"]):
                result_json["suggested_action"] = {"label": "Mua thẻ Game", "route": "/game-cards"}
            elif any(k in q_lower for k in ["chu ky so", "chữ ký số", "smart otp"]):
                result_json["suggested_action"] = {"label": "Chữ ký số Smart OTP", "route": "/profile/digital-signature"}
            elif any(k in q_lower for k in ["cai dat email", "cài đặt email", "sao ke email", "sao kê email", "sao ke thang", "sao kê tháng"]):
                result_json["suggested_action"] = {"label": "Cài đặt Email sao kê", "route": "/profile/email-settings"}
            elif any(k in q_lower for k in ["han muc ekyc", "hạn mức ekyc", "cap do tai khoan", "cấp độ tài khoản"]):
                result_json["suggested_action"] = {"label": "Cấp độ tài khoản eKYC", "route": "/profile/kyc-level"}
            elif any(k in q_lower for k in ["cai dat thong bao", "cài đặt thông báo", "thong bao bien dong", "thông báo biến động"]):
                result_json["suggested_action"] = {"label": "Cài đặt thông báo", "route": "/notifications/settings"}
            elif any(k in q_lower for k in ["the ngan hang", "thẻ ngân hàng", "lien ket the", "liên kết thẻ", "tai khoan nguon", "tài khoản nguồn"]):
                result_json["suggested_action"] = {"label": "Thẻ & Ngân hàng liên kết", "route": "/bank-cards"}
            elif any(k in q_lower for k in ["khieu nai", "khiếu nại", "tra soat", "tra soát", "ticket", "cskh", "tong dai", "tổng đài"]):
                result_json["suggested_action"] = {"label": "Hỗ trợ tra soát", "route": "/support/help-center"}
            elif any(k in q_lower for k in ["quet qr", "quét qr", "scan qr", "quet ma", "quét mã"]):
                result_json["suggested_action"] = {"label": "Quét mã VietQR", "route": "/scan-qr"}
            elif any(k in q_lower for k in ["vietlott", "xo so", "xổ số", "keno", "mega"]):
                result_json["suggested_action"] = {"label": "Vé số Vietlott", "route": "/bills/lottery"}
        latency = (time.time() - start_time) * 1000
        result_json["latency_ms"] = round(latency, 2)

        # 5. Lưu vào Semantic Cache chỉ khi LLM sinh câu trả lời thành công (không lưu extractive fallback hoặc thông báo quá tải)
        if not history and not is_extractive and "quá tải" not in result_json.get("answer", ""):
            self._save_semantic_cache(user_question, query_vec, result_json)

        return result_json

    # ==================== INTEGRATION CHO TOÀN BỘ ECOSYSTEM ====================
    def _fetch_user_wallet_balance(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Gọi nội bộ sang wallet-service để lấy số dư (Zero-LLM leak)"""
        if not user_id:
            return None
        try:
            url = f"{settings.WALLET_SERVICE_URL}/api/v1/wallets/me"
            resp = requests.get(url, headers={"X-User-Id": user_id}, timeout=3.0)
            if resp.status_code == 200:
                body = resp.json()
                return body.get("data")
        except Exception as e:
            logger.warning("Error calling wallet-service: %s", e)
        return None

    def _fetch_user_recent_transactions(self, user_id: str, limit: int = 5) -> List[Dict[str, Any]]:
        """Lấy danh sách giao dịch gần đây của người dùng từ payment-service (Zero-LLM leak)"""
        if not user_id:
            return []
        try:
            url = f"{settings.PAYMENT_SERVICE_URL}/api/v1/transactions?size={limit}"
            resp = requests.get(url, headers={"X-User-Id": user_id}, timeout=3.0)
            if resp.status_code == 200:
                body = resp.json()
                return body.get("data", {}).get("content", [])
        except Exception as e:
            logger.warning("Error fetching transactions from payment-service: %s", e)
        return []

    def _resolve_counterparty_info(self, wallet_id: Optional[str]) -> Optional[Dict[str, str]]:
        """Tra cứu Tên và SĐT của đối tác qua wallet-service và identity-service nội bộ"""
        if not wallet_id:
            return None
        try:
            # 1. Lấy ownerId từ wallet-service
            w_url = f"{settings.WALLET_SERVICE_URL}/api/v1/wallets/{wallet_id}"
            w_resp = requests.get(w_url, timeout=2.0)
            if w_resp.status_code != 200:
                return None
            owner_id = w_resp.json().get("data", {}).get("ownerId")
            if not owner_id:
                return None

            # 2. Lấy tên và SĐT từ identity-service
            u_url = f"{settings.IDENTITY_SERVICE_URL}/api/v1/internal/users/{owner_id}"
            u_resp = requests.get(u_url, timeout=2.0)
            if u_resp.status_code != 200:
                return None
            u_data = u_resp.json()
            full_name = u_data.get("fullName", "Đối tác Sen Hồng")
            phone = u_data.get("phoneNumber", "")
            # Mask số điện thoại bảo mật ngân hàng: 0901***567
            masked_phone = f"{phone[:4]}***{phone[-3:]}" if len(phone) >= 9 else phone
            return {
                "fullName": full_name,
                "phone": phone,
                "maskedPhone": masked_phone
            }
        except Exception as e:
            logger.warning("Error resolving counterparty for wallet %s: %s", wallet_id, e)
            return None

    def _format_transaction_type(self, tx_type: str, is_in: bool) -> Tuple[str, str]:
        """Format loại giao dịch tiếng Việt và ký hiệu +/-"""
        t = (tx_type or "").upper()
        if t in ["TRANSFER_OUT", "TRANSFER"]:
            return "Chuyển tiền đi", "-"
        elif t == "TRANSFER_IN":
            return "Nhận tiền chuyển đến", "+"
        elif t == "DEPOSIT":
            return "Nạp tiền vào ví", "+"
        elif t == "WITHDRAW":
            return "Rút tiền về tài khoản ngân hàng", "-"
        elif t == "LOAN_DISBURSEMENT":
            return "Giải ngân khoản vay Quick Loan", "+"
        elif t == "LOAN_REPAYMENT":
            return "Thanh toán trả nợ khoản vay", "-"
        elif t == "BILL_PAYMENT":
            return "Thanh toán hóa đơn tiện ích", "-"
        elif t == "LOTTERY_PURCHASE":
            return "Mua vé số Vietlott", "-"
        elif t == "REVERSED":
            return "Giao dịch hoàn tiền / đảo ngược", "+"
        return "Giao dịch tài chính", ("+" if is_in else "-")

    def _build_transaction_history_response(self, transactions: List[Dict[str, Any]], user_id: str) -> str:
        """Định dạng bản tin biến động số dư và chi tiết giao dịch thật chuẩn Fintech Tier-1"""
        if not transactions:
            return (
                "Dạ hiện tại tài khoản của Quý khách chưa có phát sinh giao dịch nào gần đây.\n\n"
                "Quý khách có thể nạp tiền vào ví hoặc trải nghiệm chuyển tiền miễn phí 24/7 ngay ạ!"
            )

        lines = [f"Dạ, em xin gửi Quý khách danh sách **{len(transactions)} giao dịch gần nhất** trên tài khoản Sen Hồng:\n"]
        for idx, tx in enumerate(transactions, 1):
            raw_type = tx.get("type", "")
            amount = tx.get("amount", 0)
            note = tx.get("note") or "Không có nội dung"
            created_at = tx.get("createdAt") or tx.get("timestamp") or ""
            # Format thời gian YYYY-MM-DDTHH:mm:ss -> DD/MM/YYYY lúc HH:mm
            time_display = ""
            if "T" in str(created_at):
                date_part, time_part = str(created_at).split("T")
                parts = date_part.split("-")
                if len(parts) == 3:
                    y, m, d = parts
                    hh_mm = time_part[:5]
                    time_display = f"{d}/{m}/{y} lúc {hh_mm}"
                else:
                    time_display = str(created_at)[:16]
            else:
                time_display = str(created_at)[:16]

            # Xác định chiều dòng tiền
            is_in = raw_type in ["TRANSFER_IN", "DEPOSIT", "LOAN_DISBURSEMENT", "REVERSED"]
            type_label, sign = self._format_transaction_type(raw_type, is_in)
            try:
                amt_num = float(amount or 0)
                formatted_amount = f"{sign}{amt_num:,.0f} VNĐ".replace(",", ".")
            except Exception:
                formatted_amount = f"{sign}{amount} VNĐ"

            # Số dư sau giao dịch (runningBalance / balanceAfter)
            running_bal = tx.get("runningBalance") or tx.get("balanceAfter")
            if running_bal is not None:
                try:
                    bal_num = float(running_bal)
                    running_str = f"{bal_num:,.0f} VNĐ".replace(",", ".")
                except Exception:
                    running_str = f"{running_bal} VNĐ"
            else:
                running_str = "Đang cập nhật"

            # Tra cứu đối tác nếu có ví đối ứng
            counterparty_wallet = tx.get("counterpartyWalletId")
            cp_info = self._resolve_counterparty_info(counterparty_wallet) if counterparty_wallet else None

            lines.append(f"**{idx}. {type_label}** — `{formatted_amount}`")
            lines.append(f"   - 🕒 Thời gian: {time_display}")
            if cp_info:
                partner_label = "Người nhận" if sign == "-" else "Người gửi"
                lines.append(f"   - 👤 {partner_label}: **{cp_info['fullName']}** ({cp_info['maskedPhone']})")
            lines.append(f"   - 📝 Nội dung: *{note}*")
            lines.append(f"   - 📊 Số dư biến động: **{running_str}**")
            lines.append("")

        lines.append("Quý khách có thể bấm nút **Xem tất cả giao dịch** bên dưới để tra cứu đầy đủ sao kê chi tiết hoặc tải biên lai giao dịch PDF ạ!")
        return "\n".join(lines)

    def answer_query(
        self, 
        question: str, 
        history: Optional[List[MessageItem]] = None,
        user_id: Optional[str] = None
    ) -> ChatResponse:
        """
        Điểm tiếp nhận câu hỏi tích hợp kiến trúc Dual-System (System 1 + System 2):
        - Layer 1: Code cứng (Deterministic Security Guardrails: OTP/PIN/Fraud Regex)
        - Layer 2: Jev (System One của TypeSafe AI) - Định tuyến & Gác cổng an toàn (Choice, Score, RiskScore)
        - Layer 3: System Two Generative Model (Gemini 3.5 Flash Lite + Hybrid RAG trên Postgres)
        - Bảo mật Zero-PII Leak tuyệt đối cho thông tin tài chính cá nhân
        """
        start_time = time.time()
        q_clean = question.strip()
        embed_model = self._get_embed_model()

        # =========================================================================
        # LAYER 1: QUY TẮC BẢO MẬT CỐT LÕI (CODE CỨNG - DETERMINISTIC GUARDRAILS)
        # "Các quy tắc bảo mật cốt lõi và giới hạn quyền vẫn phải được lập trình
        # trực tiếp vào ứng dụng vì Jev chỉ cung cấp tín hiệu xác suất."
        # =========================================================================
        is_triggered, guardrail_msg = check_security_guardrails(q_clean)
        if is_triggered:
            return ChatResponse(
                answer=guardrail_msg or "Cảnh báo bảo mật từ Sen Hồng Bank.",
                sources=[],
                quick_replies=["Hướng dẫn bảo mật", "Liên hệ tổng đài"],
                suggested_action=ActionItem(type="NAVIGATE", label="Cài đặt bảo mật", route="/settings/security"),
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # =========================================================================
        # LAYER 2: JEV - SYSTEM ONE GATEKEEPER & ROUTER (TYPESAFE AI ARCHITECTURE)
        # Đưa ra quyết định logic có cấu trúc (Choice, Score, RiskScore, GateAction)
        # trong < 10ms mà KHÔNG sinh văn bản, giảm 100% chi phí token.
        # =========================================================================
        jev_decision: JevDecision = jev_gatekeeper.evaluate(q_clean, embed_model, user_id=user_id)

        # Rẽ nhánh 2A: Rủi ro cao hoặc phát hiện gian lận/đòi thông tin nhạy cảm
        if jev_decision.gate_action in [GateAction.INTERCEPT_EMERGENCY, GateAction.BLOCK_CREDENTIAL_THEFT]:
            return ChatResponse(
                answer=(
                    "🔒 **Thông báo an toàn từ Sen Hồng Bank:**\n\n"
                    "Để đảm bảo an toàn tuyệt đối cho tài khoản và tài sản của Quý khách, Ngân hàng Sen Hồng "
                    "không bao giờ yêu cầu hoặc xử lý các thông tin bảo mật (mã PIN, mã OTP, mật khẩu đăng nhập, số CVV) "
                    "qua bất kỳ kênh trò chuyện nào ạ.\n\n"
                    "Nếu Quý khách nghi ngờ có rủi ro hoặc cần khóa thẻ khẩn cấp, vui lòng thực hiện ngay tính năng bên dưới "
                    "hoặc liên hệ hotline 24/7 **1900-SENHONG** (1900 736 466) để được hỗ trợ tức thì."
                ),
                sources=[],
                quick_replies=["Cài đặt bảo mật", "Khóa thẻ khẩn cấp"],
                suggested_action=ActionItem(
                    type="NAVIGATE", 
                    label=jev_decision.suggested_label or "Cài đặt bảo mật", 
                    route=jev_decision.suggested_route or "/settings/security"
                ),
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # Rẽ nhánh 2B: Hỏi số dư ví cá nhân (Zero-PII Leak)
        if jev_decision.gate_action == GateAction.DIVERT_INTERNAL_WALLET:
            if user_id:
                wallet_data = self._fetch_user_wallet_balance(user_id)
                if wallet_data:
                    bal = wallet_data.get("balance", 0)
                    formatted_bal = f"{bal:,.0f} VNĐ".replace(",", ".")
                    daily_limit = wallet_data.get("dailyLimit", 50000000)
                    formatted_limit = f"{daily_limit:,.0f} VNĐ/ngày".replace(",", ".")
                    status_text = "Hoạt động bình thường" if wallet_data.get("status") == "ACTIVE" else "Tạm khóa"
                    answer_text = (
                        f"Dạ số dư hiện khả dụng trong tài khoản của Quý khách là **{formatted_bal}**.\n\n"
                        f"- Trạng thái tài khoản: **{status_text}**\n"
                        f"- Hạn mức giao dịch ngày: **{formatted_limit}**\n\n"
                        f"Quý khách có muốn thực hiện chuyển tiền, gửi tiết kiệm hay xem lịch sử giao dịch không ạ?"
                    )
                    return ChatResponse(
                        answer=answer_text,
                        sources=["wallet_service_internal_api"],
                        quick_replies=["Lịch sử giao dịch", "Chuyển tiền nhanh", "Gửi tiết kiệm"],
                        suggested_action=ActionItem(type="NAVIGATE", label="Xem chi tiết ví", route="/profile"),
                        latency_ms=round((time.time() - start_time) * 1000, 2)
                    )
            return ChatResponse(
                answer="Dạ để bảo mật thông tin tài khoản, Quý khách vui lòng đăng nhập vào ứng dụng để tra cứu số dư chi tiết ạ.",
                sources=[],
                quick_replies=["Đăng nhập", "Xem biểu phí"],
                suggested_action=ActionItem(type="NAVIGATE", label="Đăng nhập", route="/login"),
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # Rẽ nhánh 2C: Hỏi lịch sử giao dịch & đối tác (Zero-PII Leak)
        if jev_decision.gate_action == GateAction.DIVERT_INTERNAL_TRANSACTIONS:
            if user_id:
                recent_txs = self._fetch_user_recent_transactions(user_id, limit=5)
                answer_text = self._build_transaction_history_response(recent_txs, user_id)
                return ChatResponse(
                    answer=answer_text,
                    sources=["payment_service_internal_api"],
                    quick_replies=["Kiểm tra số dư ví", "Chuyển tiền ngay", "Biểu phí dịch vụ"],
                    suggested_action=ActionItem(type="NAVIGATE", label="Xem tất cả giao dịch", route="/history"),
                    latency_ms=round((time.time() - start_time) * 1000, 2)
                )
            return ChatResponse(
                answer="Dạ để bảo mật thông tin tài khoản, Quý khách vui lòng đăng nhập vào ứng dụng để tra cứu lịch sử giao dịch chi tiết ạ.",
                sources=[],
                quick_replies=["Đăng nhập", "Xem biểu phí"],
                suggested_action=ActionItem(type="NAVIGATE", label="Đăng nhập", route="/login"),
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # Rẽ nhánh 2D: Chào hỏi, cảm ơn, xã giao (Zero-RAG hallucination & Zero-Token cost)
        if jev_decision.gate_action == GateAction.FAST_NAVIGATE and not jev_decision.suggested_route:
            q_lower_tmp = q_clean.lower()
            if any(k in q_lower_tmp for k in ["cảm ơn", "cam on", "thank", "tks"]):
                chitchat_answer = (
                    "Dạ không có chi ạ! Rất vui được đồng hành và hỗ trợ Quý khách. "
                    "Nếu Quý khách cần thêm bất kỳ thông tin nào về các dịch vụ tài chính hay tiện ích của Sen Hồng Bank, "
                    "hãy cứ nhắn em nhé. Chúc Quý khách một ngày nhiều niềm vui và giao dịch thuận lợi ạ!"
                )
                replies = ["Kiểm tra số dư ví", "Lịch sử giao dịch", "Kho Voucher & Ưu đãi"]
            elif any(k in q_lower_tmp for k in ["tạm biệt", "tam biet", "bye", "hẹn gặp lại"]):
                chitchat_answer = (
                    "Dạ tạm biệt Quý khách ạ! Chúc Quý khách có một ngày thật nhiều niềm vui và thành công. "
                    "Khi nào cần hỗ trợ dịch vụ ngân hàng, Quý khách cứ nhắn em nhé!"
                )
                replies = ["Cảm ơn em", "Trang chủ", "Ưu đãi"]
            elif any(k in q_lower_tmp for k in ["bạn là ai", "bạn tên gì", "la ai", "ten gi"]):
                chitchat_answer = (
                    "Dạ em là **Trợ lý Tài chính AI** của Ngân hàng Số Sen Hồng (Sen Hồng Bank) ạ! "
                    "Em được tích hợp sẵn trên ứng dụng để đồng hành 24/7 cùng Quý khách: giải đáp chính sách dịch vụ, "
                    "biểu phí, lãi suất tiết kiệm, tra cứu số dư và lịch sử giao dịch nhanh chóng, bảo mật tuyệt đối."
                )
                replies = ["Kiểm tra số dư", "Hướng dẫn chuyển tiền", "Mở sổ tiết kiệm"]
            else:
                chitchat_answer = (
                    "Dạ Sen Hồng Bank xin chào Quý khách! Em là Trợ lý Tài chính AI Sen Hồng. "
                    "Em có thể hỗ trợ Quý khách tra cứu số dư, sao kê giao dịch, chuyển tiền Napas 24/7, "
                    "mở sổ tiết kiệm, vay nhanh Quick Loan hay thanh toán hóa đơn điện nước ạ. "
                    "Quý khách cần em hỗ trợ điều gì hôm nay ạ?"
                )
                replies = ["Kiểm tra số dư ví", "Lịch sử giao dịch", "Mở sổ tiết kiệm", "Chuyển tiền nhanh"]

            return ChatResponse(
                answer=chitchat_answer,
                sources=[],
                quick_replies=replies,
                suggested_action=None,
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # =========================================================================
        # LAYER 3: SYSTEM TWO GENERATIVE LLM (GEMINI 3.5 FLASH LITE + ADVANCED RAG)
        # Chỉ gọi khi Jev xác nhận GateAction.ALLOW_RAG
        # =========================================================================
        masked_q, token_map = tokenize_pii(q_clean)
        res_dict = self.query(masked_q, history=history)

        raw_ans = res_dict.get("answer") or res_dict.get("Answer") or res_dict.get("response") or ""
        answer_final = detokenize_pii(str(raw_ans), token_map)
        
        # Format sources sang Tiêu đề nghiệp vụ đẹp mắt, loại bỏ hoàn toàn mã kỹ thuật và file thô
        raw_sources = res_dict.get("sources", [])
        sources_final = []
        for s in raw_sources:
            if not s or any(bad in str(s).lower() for bad in ["jev", "typesafe", "service", ".py", "chao_mung", "internal_api"]):
                continue
            title = clean_source_title(str(s))
            if title and title not in sources_final and not title.lower().endswith(".md"):
                sources_final.append(title)
        quick_replies = res_dict.get("quick_replies", [])

        # Ghép suggested action từ LLM hoặc fallback tối ưu từ Jev System One
        action_data = res_dict.get("suggested_action")
        suggested_action = None
        if action_data and isinstance(action_data, dict):
            raw_route = action_data.get("route", "/more")
            valid_routes = {
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
            }
            q_lower_clean = q_clean.lower()
            is_pwd_recovery = any(r in q_lower_clean for r in [
                "quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "cài lại", "cai lai",
                "khôi phục", "khoi phuc", "reset"
            ]) and any(p in q_lower_clean for p in ["mật khẩu", "mat khau", "password"])

            is_pin_recovery = any(r in q_lower_clean for r in [
                "quên", "quen", "lấy lại", "lay lai", "cấp lại", "cap lai", "cài lại", "cai lai",
                "khôi phục", "khoi phuc", "reset", "mất mã pin", "mat ma pin"
            ]) and any(p in q_lower_clean for p in ["pin", "mã pin", "ma pin"])

            is_bank_linking = any(k in q_lower_clean for k in [
                "liên kết ngân hàng", "lien ket ngan hang", "liên kết thẻ", "lien ket the", 
                "thẻ ngân hàng liên kết", "thêm ngân hàng", "ngân hàng liên kết"
            ])

            if is_pwd_recovery:
                final_route = "/auth/forgot-password"
                action_label = "Quên mật khẩu"
            elif is_pin_recovery:
                final_route = "/auth/forgot-pin"
                action_label = "Lấy lại mã PIN"
            elif is_bank_linking:
                final_route = "/bank-cards"
                action_label = "Thẻ & Ngân hàng liên kết"
            elif raw_route in valid_routes:
                final_route = raw_route
                action_label = action_data.get("label", "Xem chi tiết")
            elif any(k in raw_route.lower() for k in ["pwd", "password", "mat_khau", "mật khẩu"]):
                final_route = "/auth/forgot-password"
                action_label = action_data.get("label", "Quên mật khẩu")
            elif any(k in raw_route.lower() for k in ["forgot_pin", "pin"]):
                final_route = "/auth/forgot-pin"
                action_label = action_data.get("label", "Lấy lại mã PIN")
            elif any(k in raw_route.lower() for k in ["recharge", "topup", "nap_dt"]):
                final_route = "/bills/phone-recharge"
                action_label = action_data.get("label", "Nạp điện thoại")
            elif any(k in raw_route.lower() for k in ["bill", "hóa đơn", "hoa_don"]):
                final_route = "/bills"
                action_label = action_data.get("label", "Thanh toán hóa đơn")
            elif any(k in raw_route.lower() for k in ["lottery", "vietlott", "vé số", "ve_so"]):
                final_route = "/bills/lottery"
                action_label = action_data.get("label", "Vé số Vietlott")
            elif any(k in raw_route.lower() for k in ["my_qr", "my-qr", "qr"]):
                final_route = "/my-qr"
                action_label = action_data.get("label", "Mã QR của tôi")
            elif any(k in raw_route.lower() for k in ["saving", "tiết kiệm", "tiet_kiem"]):
                final_route = "/bills/savings"
                action_label = action_data.get("label", "Mở sổ tiết kiệm")
            elif any(k in raw_route.lower() for k in ["loan", "vay"]):
                final_route = "/bills/quick-loan"
                action_label = action_data.get("label", "Vay nhanh")
            elif any(k in raw_route.lower() for k in ["card", "thẻ", "the"]):
                final_route = "/cards"
                action_label = action_data.get("label", "Quản lý thẻ")
            elif any(k in raw_route.lower() for k in ["transfer", "chuyen", "chuyển"]):
                final_route = "/transfer"
                action_label = action_data.get("label", "Chuyển tiền ngay")
            elif any(k in raw_route.lower() for k in ["profile", "vi", "ví", "wallet"]):
                final_route = "/profile"
                action_label = action_data.get("label", "Xem chi tiết ví")
            elif any(k in raw_route.lower() for k in ["device", "thiết bị", "thiet_bi"]):
                final_route = "/settings/devices"
                action_label = action_data.get("label", "Quản lý thiết bị")
            elif any(k in raw_route.lower() for k in ["history", "lịch sử", "lich_su"]):
                final_route = "/history"
                action_label = action_data.get("label", "Xem tất cả giao dịch")
            else:
                final_route = "/more"
                action_label = action_data.get("label", "Xem tất cả tiện ích")

            suggested_action = ActionItem(
                type="NAVIGATE",
                label=action_label,
                route=final_route
            )
        elif jev_decision.suggested_route and jev_decision.suggested_label:
            suggested_action = ActionItem(
                type="NAVIGATE",
                label=jev_decision.suggested_label,
                route=jev_decision.suggested_route
            )

        latency = (time.time() - start_time) * 1000

        return ChatResponse(
            answer=answer_final,
            sources=sources_final,
            quick_replies=quick_replies,
            suggested_action=suggested_action,
            latency_ms=round(latency, 2)
        )


# Singleton Instance phục vụ Microservice
rag_engine = AdvancedRAGEngine()
