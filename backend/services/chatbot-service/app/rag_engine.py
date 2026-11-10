import os
import re
import time
import json
import hashlib
import logging
from pathlib import Path
from typing import List, Dict, Any, Tuple, Optional
import requests
import psycopg
from pgvector.psycopg import register_vector
from sentence_transformers import SentenceTransformer
from openai import OpenAI

from app.config import settings
from app import rate_config
from app.guardrails import (
    mask_pii,
    tokenize_pii,
    detokenize_pii,
    check_security_guardrails
)
from app.jev_system_one import (
    jev_gatekeeper, 
    GateAction, 
    IntentChoice, 
    JevDecision
)
from app.schemas import MessageItem, ChatResponse, IngestResponse, ActionItem
from app.vietnamese_nlp import (
    normalize_vietnamese_query,
    enrich_smart_quick_replies,
    strip_vietnamese_accents,
    detect_query_topic
)
from app.financial_calculator import (
    generate_comprehensive_financial_analysis,
    calculate_savings_compound,
    calculate_loan_amortization,
    format_vnd
)
from app.disambiguation_handler import (
    check_ambiguous_query,
    extract_context_from_history,
    enrich_query_with_context
)
from app.output_validator import sanitize_and_validate_output
from app.banking_agent import BankingReActAgent
from app.long_query_handler import handle_comprehensive_long_query
from app.deep_thinking_engine import deep_thinking_engine
from app.app_feature_catalog import (
    check_app_has_feature, 
    find_feature_by_query, 
    APP_FEATURES,
    format_feature_howto_answer
)
from app.guided_flow_handler import (
    classify_question_archetype, 
    GuidedFlowHandler, 
    INTENT_LEAD_ACTION, 
    INTENT_HOW_TO_ACTION,
    INTENT_PERSONAL_DATA,
    INTENT_PRODUCT_INFO
)

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
    "24_kho_voucher_uu_dai_doi_tac_va_chuong_trinh_khuyen_mai.md": "Kho Voucher & Ưu Đãi Đối Tác",
    "25_ty_gia_ngoai_te_va_kieu_hoi_quoc_te.md": "Tỷ giá & Kiều hối quốc tế",
    "26_mang_luoi_chi_nhanh_va_diem_giao_dich.md": "Mạng lưới Chi nhánh & ATM",
    "27_huong_dan_biet_danh_tai_khoan_alias_va_vietqr_pro.md": "Biệt danh Alias & VietQR Pro",
    "28_giai_dap_tinh_huong_nghiep_vu_kho_va_tu_van_chuyen_sau.md": "Tư vấn nghiệp vụ & Tình huống chuyên sâu",
    "29_ngu_canh_kinh_te_tai_chinh_ngan_hang_va_quan_tri_tai_san.md": "Kinh tế vĩ mô & Quản trị tài chính",
    "30_bo_cong_an_de_an_06_vneid_va_xac_thuc_dan_cu.md": "Dữ liệu dân cư C06 & VNeID Bộ Công An",
    "31_dieu_khoan_dich_vu_app_sen_hong_va_chinh_sach_bao_ve_du_lieu.md": "Điều khoản dịch vụ & Bảo vệ dữ liệu NĐ 13",
    "32_cam_nang_giay_to_ho_so_mo_tai_khoan_va_vay_von.md": "Hồ sơ giấy tờ mở tài khoản & vay vốn",
    "33_vay_the_chap_bat_dong_san_o_to_va_tham_dinh_cic.md": "Vay thế chấp BĐS, Ô tô & Thẩm định CIC",
    "34_chung_chi_tien_gui_tiet_kiem_da_dang_va_bao_hiem_tien_gui.md": "Chứng chỉ tiền gửi CD & Bảo hiểm tiền gửi DIV",
    "35_chuyen_tien_quoc_te_swift_kieu_hoi_va_quan_ly_ngoai_hoi.md": "Chuyển tiền quốc tế SWIFT & Kiều hối",
    "36_the_tin_dung_cashback_tra_gop_0_phan_tram_va_xu_ly_su_co_the.md": "Thẻ tín dụng hoàn tiền & Trả góp 0%",
    "37_nop_thue_dien_tu_etax_mobile_dich_vu_cong_va_hoa_don_so.md": "Nộp thuế điện tử eTax Mobile & Dịch vụ công",
    "38_cam_nang_nhan_dien_15_thu_doan_lua_dao_va_xu_ly_khan_cap.md": "Nhận diện 15 thủ đoạn lừa đảo & Xử lý khẩn cấp",
    "39_khach_hang_uu_tien_senhong_priority_va_private_wealth.md": "Khách hàng ưu tiên Sen Hong Priority & Private Banking",
    "40_diem_giao_dich_thong_minh_smart_lounge_va_crm_247.md": "Smart Lounge 24/7 & Cây nạp rút tiền CRM",
    "41_phan_tich_chi_tieu_sinh_hoat_va_quan_ly_tai_chinh_ca_nhan_pfm.md": "Phân tích chi tiêu sinh hoạt & Quản lý tài chính PFM",
    "42_ca_nhan_hoa_tai_chinh_va_he_thong_nhac_nho_thong_minh.md": "Cá nhân hóa chi tiêu & Hệ thống nhắc nhở thông minh",
    "43_cac_phuong_an_tai_chinh_toan_dien_va_ra_quyet_dinh_thong_minh.md": "Các phương án tài chính toàn diện & Ra quyết định",
    "44_bieu_phi_han_muc_the_va_giao_dich_chi_tiet.md": "Biểu phí & Hạn mức chi tiết",
    "45_chuong_trinh_senpoint_doi_diem_hang_thanh_vien.md": "Chương trình SenPoint & Hạng thành viên",
    "46_bao_hiem_nhan_tho_suc_khoe_du_lich_lien_ket.md": "Bảo hiểm nhân thọ, sức khỏe & du lịch",
    "47_ngan_hang_so_doanh_nghiep_sme_payroll_viqr_pro.md": "Ngân hàng số Doanh nghiệp SME",
    "48_dinh_gia_tai_san_the_chap_bat_dong_san_o_to.md": "Định giá tài sản thế chấp",
    "49_vay_ho_kinh_doanh_tieu_thuong_vi_mo.md": "Vay hộ kinh doanh tiểu thương Vimo",
    "50_tai_khoan_nguoi_chua_thanh_nien_tk_phu_thuoc.md": "Tài khoản người chưa thành niên & TK phụ thuộc",
    "51_su_co_app_ky_thuat_khong_phai_tra_soat.md": "Sự cố kỹ thuật ứng dụng",
    "52_chung_chi_quy_mo_fund_mo_dau_tu.md": "Chứng chỉ quỹ & Fund mở đầu tư",
    "53_thue_thu_nhap_ca_nhan_giam_tru_gia_canh.md": "Thuế thu nhập cá nhân & Giảm trừ gia cảnh",
    "54_the_mat_the_hong_dong_bang_phat_hanh_lai.md": "Thẻ mất, thẻ hỏng & phát hành lại",
    "55_quy_dinh_nap_rut_tien_mat_cdm_atm_han_muc.md": "Nạp/rút tiền mặt CDM/ATM & Hạn mức",
    "56_tu_dien_thuat_ngu_ngan_hang_cho_nguoi_moi.md": "Từ điển thuật ngữ ngân hàng",
    "bieu_phi_dich_vu.md": "Biểu phí dịch vụ",
    "huong_dan_the_visa.md": "Hướng dẫn thẻ Visa",
    "lai_suat_tiet_kiem.md": "Biểu lãi suất tiết kiệm",
    "quy_dinh_qd2345.md": "Quy định QĐ 2345",
    "tai_khoan_va_ekyc.md": "Tài khoản & eKYC",
}

# Domain taxonomy dùng đúng bộ enum topic của detect_query_topic() (vietnamese_nlp.py)
# để filter metadata trước khi tìm vector: WHERE domain = <topic> OR domain = 'GENERAL_ACCOUNT'
# (GENERAL_ACCOUNT là domain "bắt ke" chứa tài liệu đa chủ đề — luôn nằm trong kết quả lọc).
FILE_DOMAIN_MAP = {
    "01_huong_dan_chuyen_tien.md": "TRANSFER",
    "02_nap_va_rut_tien.md": "TRANSFER",
    "02a_rut_tien_atm_khong_the.md": "TRANSFER",
    "03_thanh_toan_hoa_don_tien_ich.md": "BILLS_TOPUP",
    "04_vay_tieu_dung_quick_loan.md": "LOANS",
    "04a_vay_tieu_dung_tin_chap_quick_loan.md": "LOANS",
    "05_tiet_kiem_online_core_savings.md": "SAVINGS",
    "06_quan_ly_the_va_tai_khoan.md": "CARDS",
    "07_quy_dinh_sinh_trac_hoc_qd2345.md": "BIOMETRICS",
    "08_tien_ich_xo_so_giai_tri.md": "BILLS_TOPUP",
    "09_bieu_phi_va_han_muc_chi_tiet.md": "PHI_HAN_MUC",
    "10_an_toan_bao_mat_va_canh_bao_lua_dao.md": "SECURITY",
    "11_ho_tro_khieu_nai_va_cskh.md": "DISPUTE",
    "12_tong_hop_cau_hoi_thuong_gap_faq.md": "GENERAL_ACCOUNT",
    "13_ma_vietqr_va_chia_tien_split_bill.md": "TRANSFER",
    "14_dat_lich_chuyen_tien_dinh_ky.md": "TRANSFER",
    "15_danh_ba_thu_huong_va_danh_sach_ngan_hang_napas.md": "TRANSFER",
    "16_tai_khoan_so_dep_va_chuyen_tien_quoc_te.md": "TRANSFER",
    "17_chuong_trinh_gioi_thieu_va_voucher_uu_dai.md": "PROMOTIONS",
    "18_quan_ly_thiet_bi_va_bao_mat_phien.md": "SECURITY",
    "19_dieu_khoan_phap_ly_va_giay_phep_nhnn.md": "TERMS_OF_SERVICE",
    "20_cam_nang_toan_dien_cac_man_hinh_va_tinh_nang_app.md": "GENERAL_ACCOUNT",
    "21_kien_truc_he_thong_microservices_va_backend.md": "GENERAL_ACCOUNT",
    "22_cam_nang_chuyen_sau_tinh_nang_mobile_va_tien_ich_so.md": "GENERAL_ACCOUNT",
    "23_tong_hop_toan_bo_tinh_nang_mobile_va_backend_huong_dan_khach_hang.md": "GENERAL_ACCOUNT",
    "24_kho_voucher_uu_dai_doi_tac_va_chuong_trinh_khuyen_mai.md": "PROMOTIONS",
    "25_ty_gia_ngoai_te_va_kieu_hoi_quoc_te.md": "MACRO_ECONOMICS",
    "26_mang_luoi_chi_nhanh_va_diem_giao_dich.md": "GENERAL_ACCOUNT",
    "27_huong_dan_biet_danh_tai_khoan_alias_va_vietqr_pro.md": "TRANSFER",
    "28_giai_dap_tinh_huong_nghiep_vu_kho_va_tu_van_chuyen_sau.md": "FINANCIAL_ADVISORY",
    "29_ngu_canh_kinh_te_tai_chinh_ngan_hang_va_quan_tri_tai_san.md": "MACRO_ECONOMICS",
    "30_bo_cong_an_de_an_06_vneid_va_xac_thuc_dan_cu.md": "BCA_VNEID_EKYC",
    "31_dieu_khoan_dich_vu_app_sen_hong_va_chinh_sach_bao_ve_du_lieu.md": "TERMS_OF_SERVICE",
    "32_cam_nang_giay_to_ho_so_mo_tai_khoan_va_vay_von.md": "ACCOUNT_OPENING_DOCS",
    "33_vay_the_chap_bat_dong_san_o_to_va_tham_dinh_cic.md": "LOANS",
    "34_chung_chi_tien_gui_tiet_kiem_da_dang_va_bao_hiem_tien_gui.md": "SAVINGS",
    "35_chuyen_tien_quoc_te_swift_kieu_hoi_va_quan_ly_ngoai_hoi.md": "TRANSFER",
    "36_the_tin_dung_cashback_tra_gop_0_phan_tram_va_xu_ly_su_co_the.md": "CARDS",
    "37_nop_thue_dien_tu_etax_mobile_dich_vu_cong_va_hoa_don_so.md": "BILLS_TOPUP",
    "38_cam_nang_nhan_dien_15_thu_doan_lua_dao_va_xu_ly_khan_cap.md": "SECURITY",
    "39_khach_hang_uu_tien_senhong_priority_va_private_wealth.md": "GENERAL_ACCOUNT",
    "40_diem_giao_dich_thong_minh_smart_lounge_va_crm_247.md": "GENERAL_ACCOUNT",
    "41_phan_tich_chi_tieu_sinh_hoat_va_quan_ly_tai_chinh_ca_nhan_pfm.md": "FINANCIAL_ADVISORY",
    "42_ca_nhan_hoa_tai_chinh_va_he_thong_nhac_nho_thong_minh.md": "FINANCIAL_ADVISORY",
    "43_cac_phuong_an_tai_chinh_toan_dien_va_ra_quyet_dinh_thong_minh.md": "FINANCIAL_ADVISORY",
    "44_bieu_phi_han_muc_the_va_giao_dich_chi_tiet.md": "PHI_HAN_MUC",
    "45_chuong_trinh_senpoint_doi_diem_hang_thanh_vien.md": "PROMOTIONS",
    "46_bao_hiem_nhan_tho_suc_khoe_du_lich_lien_ket.md": "INSURANCE",
    "47_ngan_hang_so_doanh_nghiep_sme_payroll_viqr_pro.md": "SME_BUSINESS",
    "48_dinh_gia_tai_san_the_chap_bat_dong_san_o_to.md": "LOANS",
    "49_vay_ho_kinh_doanh_tieu_thuong_vi_mo.md": "LOANS",
    "50_tai_khoan_nguoi_chua_thanh_nien_tk_phu_thuoc.md": "ACCOUNT_OPENING_DOCS",
    "51_su_co_app_ky_thuat_khong_phai_tra_soat.md": "DISPUTE",
    "52_chung_chi_quy_mo_fund_mo_dau_tu.md": "FINANCIAL_ADVISORY",
    "53_thue_thu_nhap_ca_nhan_giam_tru_gia_canh.md": "BILLS_TOPUP",
    "54_the_mat_the_hong_dong_bang_phat_hanh_lai.md": "CARDS",
    "55_quy_dinh_nap_rut_tien_mat_cdm_atm_han_muc.md": "TRANSFER",
    "56_tu_dien_thuat_ngu_ngan_hang_cho_nguoi_moi.md": "GENERAL_ACCOUNT",
    "bieu_phi_dich_vu.md": "PHI_HAN_MUC",
    "huong_dan_the_visa.md": "CARDS",
    "lai_suat_tiet_kiem.md": "SAVINGS",
    "quy_dinh_qd2345.md": "BIOMETRICS",
    "tai_khoan_va_ekyc.md": "ACCOUNT_OPENING_DOCS",
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
        self._reranker = None
        self._last_rag_context = None
        
        self._init_db_schema()
        self._init_llm_clients()
        self.banking_agent = BankingReActAgent(self)
        self.guided_flow = GuidedFlowHandler(self)

    def _get_db_connection(self):
        """Tái sử dụng kết nối autocommit persistent với cơ chế tự phục hồi kết nối (Self-Healing Socket)"""
        need_reconnect = False
        if self._conn is None or self._conn.closed:
            need_reconnect = True
        else:
            try:
                # Kiểm tra socket còn sống không trước khi giao cho transaction mới
                with self._conn.cursor() as cur:
                    cur.execute("SELECT 1;")
            except Exception:
                need_reconnect = True

        if need_reconnect:
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

                # ===== Migration idempotent cho RAG dữ liệu lớn (CREATE TABLE IF NOT EXISTS
                # không nâng cấp được DB cũ, nên dùng ALTER ADD COLUMN IF NOT EXISTS) =====
                cur.execute("""
                    ALTER TABLE parent_documents
                    ADD COLUMN IF NOT EXISTS domain VARCHAR(50),
                    ADD COLUMN IF NOT EXISTS content_hash VARCHAR(64);
                """)
                cur.execute("""
                    ALTER TABLE knowledge_chunks
                    ADD COLUMN IF NOT EXISTS domain VARCHAR(50);
                """)
                cur.execute("""
                    CREATE TABLE IF NOT EXISTS ingest_state (
                        source_file VARCHAR(255) PRIMARY KEY,
                        content_hash VARCHAR(64) NOT NULL,
                        chunk_count INT NOT NULL DEFAULT 0,
                        ingested_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    );
                """)
                cur.execute("""
                    CREATE INDEX IF NOT EXISTS idx_chunks_domain
                    ON knowledge_chunks (domain);
                """)
                cur.execute("""
                    CREATE INDEX IF NOT EXISTS idx_parents_domain
                    ON parent_documents (domain);
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

    def _get_reranker(self):
        """
        Tải lazy CrossEncoder reranker (chỉ khi settings.RERANK_ENABLED=true).
        Lưu ý vận hành: model ~1.1GB fp32 CPU — cần nâng mem_limit chatbot-service lên 2g.
        """
        if not settings.RERANK_ENABLED:
            return None
        if self._reranker is None:
            from sentence_transformers import CrossEncoder
            logger.info("Loading reranker model (%s)...", settings.RERANK_MODEL)
            self._reranker = CrossEncoder(settings.RERANK_MODEL, max_length=512)
            logger.info("Reranker model loaded successfully.")
        return self._reranker

    def _rerank_parent_rows(self, query: str, rows: List[Dict[str, Any]]) -> List[Dict[str, Any]]:
        """
        Rerank cross-encoder trên danh sách parent rows (điểm RRF chỉ là tín hiệu xếp thô).
        - Nếu điểm cao nhất < settings.RERANK_MIN_SCORE → trả danh sách rỗng để pipeline
          trả lời trung thực "chưa có thông tin" thay vì ép LLM suy đoán.
        - Lỗi rerank (model/VRAM) → giữ nguyên thứ hạng RRF, không làm hỏng luồng chính.
        """
        reranker = self._get_reranker()
        if reranker is None or not rows:
            return rows
        try:
            start = time.time()
            pairs = [(query, r["parent_content"]) for r in rows]
            scores = reranker.predict(pairs)
            scored = sorted(
                [(row, float(score)) for row, score in zip(rows, scores)],
                key=lambda t: t[1],
                reverse=True
            )
            best_score = scored[0][1] if scored else float("-inf")
            logger.info(
                "Rerank %d candidates in %.0fms (best=%.3f, threshold=%.3f)",
                len(rows), (time.time() - start) * 1000, best_score, settings.RERANK_MIN_SCORE
            )
            if best_score < settings.RERANK_MIN_SCORE:
                logger.info("Rerank threshold not met -> trả rỗng để từ chối trung thực.")
                return []
            return [dict(row, rerank_score=score) for row, score in scored]
        except Exception as e:
            logger.warning("Rerank failed, giữ nguyên thứ hạng RRF: %s", e)
            return rows

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
        - Gán domain (FILE_DOMAIN_MAP) để lọc metadata trước khi tìm vector
        - Ghi ingest_state (content_hash) cho ingest tăng dần
        """
        model = self._get_embed_model()
        path_obj = Path(file_path)
        content = path_obj.read_text(encoding="utf-8")
        content_hash = hashlib.sha256(content.encode("utf-8")).hexdigest()
        file_domain = FILE_DOMAIN_MAP.get(source_name, "GENERAL_ACCOUNT")

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

                # 1. Lưu Parent Document (kèm domain phục vụ lọc metadata khi tìm kiếm)
                cur.execute(
                    "INSERT INTO parent_documents (source_file, heading, parent_content, domain) VALUES (%s, %s, %s, %s) RETURNING id",
                    (source_name, clean_heading, full_parent_content, file_domain)
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
                        """INSERT INTO knowledge_chunks (parent_id, source_file, chunk_content, embedding, domain)
                           VALUES (%s, %s, %s, %s, %s)""",
                        (parent_id, source_name, chunk, vector, file_domain)
                    )
                    chunks_created += 1

                i += 2

            # Ghi nhận trạng thái nạp (content_hash) để lần ingest sau bỏ qua file không đổi
            cur.execute(
                """INSERT INTO ingest_state (source_file, content_hash, chunk_count, ingested_at)
                   VALUES (%s, %s, %s, CURRENT_TIMESTAMP)
                   ON CONFLICT (source_file) DO UPDATE
                   SET content_hash = EXCLUDED.content_hash,
                       chunk_count = EXCLUDED.chunk_count,
                       ingested_at = CURRENT_TIMESTAMP""",
                (source_name, content_hash, chunks_created)
            )

        logger.info("Ingested '%s' [domain=%s]: %d child chunks.", source_name, file_domain, chunks_created)
        return chunks_created

    def ingest_documents(self, force: bool = False) -> IngestResponse:
        """
        Nạp tài liệu Markdown trong thư mục data/ vào PostgreSQL (tăng dần).
        - Mỗi file băm SHA-256 so với ingest_state: không đổi → bỏ qua (không re-embed)
        - force=True → nạp lại toàn bộ bất kể hash
        - Chỉ làm mới Semantic Cache khi có ít nhất 1 file được nạp lại
        """
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

        # Đọc trạng thái hash đã nạp từ lần trước
        state_hashes: Dict[str, str] = {}
        try:
            conn = self._get_db_connection()
            with conn.cursor() as cur:
                cur.execute("SELECT source_file, content_hash FROM ingest_state")
                state_hashes = {row[0]: row[1] for row in cur.fetchall()}
        except Exception as e:
            logger.warning("Could not read ingest_state, sẽ nạp lại toàn bộ: %s", e)

        # Xác định file cần nạp lại (force=True → tất cả)
        changed_files: List[Path] = []
        skipped_files: List[str] = []
        for f in files:
            try:
                f_hash = hashlib.sha256(f.read_bytes()).hexdigest()
            except Exception as e:
                logger.error("Error hashing %s: %s", f.name, e)
                changed_files.append(f)
                continue
            if not force and state_hashes.get(f.name) == f_hash:
                skipped_files.append(f.name)
            else:
                changed_files.append(f)

        if not changed_files:
            logger.info("Ingest tăng dần: cả %d file không đổi, bỏ qua re-embed.", len(files))
            return IngestResponse(
                status="success",
                documents_indexed=len(files),
                chunks_created=0,
                details=[{"file": name, "skipped": True, "chunks": 0} for name in skipped_files]
            )

        # Làm mới Semantic Cache CHỈ khi có tài liệu thay đổi
        try:
            with self._get_db_connection() as conn:
                with conn.cursor() as cur:
                    cur.execute("TRUNCATE TABLE semantic_cache;")
            logger.info("Semantic cache truncated (%d/%d file changed).", len(changed_files), len(files))
        except Exception as e:
            logger.warning("Could not truncate semantic_cache: %s", e)

        total_chunks = 0
        details = [{"file": name, "skipped": True, "chunks": 0} for name in skipped_files]
        for f in changed_files:
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

        # 7. Tránh nhầm lẫn giữa các mã voucher, khuyến mãi đối tác cụ thể
        voucher_codes = [
            "xinchao50", "freego", "friend50k", "welcome100k", "senbank9", "hlcoffee50",
            "shopee100", "begrab40", "phuclong30", "cgvpopcorn", "pizza35", "vinfast0",
            "homeloan52", "tech0percent", "senshopee100", "vivuhe300", "phuclong25",
            "evo390k", "goldengate4", "autobill50", "platinum2026", "hotel15", "xangdau5"
        ]
        code_1 = next((c for c in voucher_codes if c in l1), None)
        code_2 = next((c for c in voucher_codes if c in l2), None)
        if code_1 and code_2 and code_1 != code_2:
            return False
        if (code_1 is not None) != (code_2 is not None):
            return False

        return True

    def _check_semantic_cache(self, user_question: str, query_vec: List[float], max_distance: float = 0.040) -> Optional[Dict[str, Any]]:
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

    def _search_parent_rows(
        self,
        user_question: str,
        query_vec: List[float],
        candidate_limit: int,
        domain: Optional[str] = None
    ) -> List[Dict[str, Any]]:
        """
        Hybrid Search RRF (Vector + Full-Text) trả về danh sách parent rows có điểm.
        - domain: lọc metadata CHÍNH XÁC TRƯỚC khi tìm (thu hẹp không gian tìm kiếm).
          KHÔNG mồi thêm domain 'GENERAL_ACCOUNT' vào filter: file tổng hợp khổng lồ
          (20/22/23) sẽ áp đảo kết quả trên câu hỏi đàm thoại. File đa chủ đề chỉ được
          tìm khi câu hỏi mơ hồ (không truyền domain) hoặc qua luồng retry không lọc.
        - Tăng hnsw.ef_search để cân bằng recall khi dữ liệu lớn.
        """
        hybrid_query = """
        WITH vector_search AS (
            SELECT id, (embedding <=> %s::vector) AS vec_dist,
                   RANK() OVER (ORDER BY embedding <=> %s::vector) AS vec_rank
            FROM knowledge_chunks
            WHERE (%s::text IS NULL OR domain = %s)
            ORDER BY embedding <=> %s::vector
            LIMIT %s
        ),
        keyword_search AS (
            SELECT id, RANK() OVER (ORDER BY ts_rank_cd(tsv_content, plainto_tsquery('simple', %s)) DESC) AS kw_rank
            FROM knowledge_chunks
            WHERE tsv_content @@ plainto_tsquery('simple', %s)
              AND (%s::text IS NULL OR domain = %s)
            LIMIT %s
        ),
        combined AS (
            SELECT COALESCE(v.id, k.id) AS chunk_id,
                   COALESCE(1.0 / (60 + v.vec_rank), 0.0) + COALESCE(1.0 / (60 + k.kw_rank), 0.0) AS rrf_score
            FROM vector_search v
            FULL OUTER JOIN keyword_search k ON v.id = k.id
        )
        SELECT pd.id AS parent_id, pd.source_file, pd.heading, pd.parent_content,
               MAX(c.rrf_score) AS score, MIN(v.vec_dist) AS best_vec_dist
        FROM combined c
        JOIN knowledge_chunks kc ON kc.id = c.chunk_id
        JOIN parent_documents pd ON pd.id = kc.parent_id
        LEFT JOIN vector_search v ON v.id = c.chunk_id
        GROUP BY pd.id, pd.source_file, pd.heading, pd.parent_content
        ORDER BY score DESC
        LIMIT %s;
        """
        try:
            conn = self._get_db_connection()
            with conn.cursor() as cur:
                cur.execute("SET hnsw.ef_search = 100;")
                cur.execute(
                    hybrid_query,
                    (query_vec, query_vec, domain, domain, query_vec, candidate_limit,
                     user_question, user_question, domain, domain, candidate_limit,
                     candidate_limit)
                )
                rows = cur.fetchall()

            return [
                {
                    "parent_id": row[0],
                    "source_file": row[1],
                    "heading": row[2],
                    "parent_content": row[3],
                    "score": float(row[4]),
                    "best_vec_distance": float(row[5]) if row[5] is not None else None,
                }
                for row in rows
            ]
        except Exception as e:
            logger.error("Error executing Hybrid Search SQL: %s", e)
            return []

    def _compress_parent_content(self, parent_content: str, query: str, max_chars: int = 800) -> str:
        """
        Nén ngữ cảnh extractive: giữ heading + câu/dòng chứa token của câu hỏi,
        giữ nguyên dòng bảng khớp query. Mục tiêu: ít nhiễu cho LLM, rẻ token,
        không mất dòng bảng lãi suất/phí liên quan.
        """
        lines = [ln for ln in parent_content.split("\n") if ln.strip()]
        if sum(len(ln) for ln in lines) <= max_chars:
            return parent_content
        q_tokens = {t for t in strip_vietnamese_accents(query).split() if len(t) >= 3}
        scored = []
        for idx, ln in enumerate(lines):
            ln_tokens = set(strip_vietnamese_accents(ln).split())
            overlap = len(q_tokens & ln_tokens)
            is_heading_or_table = idx == 0 or ln.strip().startswith("|")
            scored.append((overlap + (1 if is_heading_or_table else 0), idx, ln))
        kept = [t for t in scored if t[0] > 0] or scored[:6]
        kept.sort(key=lambda t: t[1])
        out: List[str] = []
        size = 0
        for _, _, ln in kept:
            if size + len(ln) > max_chars and out:
                break
            out.append(ln)
            size += len(ln)
        return "\n".join(out)

    def _hybrid_search_rrf(
        self,
        user_question: str,
        query_vec: List[float],
        top_k: int = 4,
        domain: Optional[str] = None
    ) -> Tuple[str, List[str]]:
        """
        Hybrid Search (Vector + Full-Text RRF) trong 1 câu SQL duy nhất
        - Vector search: Cosine distance lấy top N ứng viên
        - Keyword search: Full-Text Search tsvector @@ plainto_tsquery lấy top N ứng viên
        - RRF Score = 1/(60 + vec_rank) + 1/(60 + kw_rank)
        - Bật rerank cross-encoder khi settings.RERANK_ENABLED (lấy rộng, chấm lại, cắt top_k)
        - GROUP BY parent_documents để lấy toàn bộ bảng biểu và điều kiện gốc
        """
        try:
            candidate_limit = settings.RERANK_CANDIDATES if settings.RERANK_ENABLED else max(top_k * 4, 15)
            rows = self._search_parent_rows(user_question, query_vec, candidate_limit, domain=domain)

            if settings.RERANK_ENABLED and rows:
                rows = self._rerank_parent_rows(user_question, rows)

            if not rows:
                return "Không tìm thấy tài liệu chính thống liên quan.", []

            # Ngưỡng khoảng cách vector (settings.MAX_DISTANCE): nếu ứng viên tốt nhất vẫn
            # quá xa ngữ nghĩa → trả rỗng để LLM từ chối trung thực thay vì bịa (anti-hallucination).
            best_dist = rows[0].get("best_vec_distance")
            if best_dist is not None and settings.MAX_DISTANCE > 0 and best_dist > settings.MAX_DISTANCE:
                logger.info(
                    "Vector distance floor triggered: best=%.3f > MAX_DISTANCE=%.3f -> từ chối trung thực.",
                    best_dist, settings.MAX_DISTANCE
                )
                return "Không tìm thấy tài liệu chính thống liên quan.", []

            rows = rows[:top_k]
            context_texts = []
            sources = []
            for row in rows:
                source_file = row["source_file"]
                if source_file not in sources:
                    sources.append(source_file)
                compressed = self._compress_parent_content(row["parent_content"], user_question)
                context_texts.append(f"--- Tài liệu: {source_file} ({row['heading']}) ---\n{compressed}")

            combined_context = "\n\n".join(context_texts)
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
        def _normalize_dict(d: Dict[str, Any]) -> Dict[str, Any]:
            qr = d.get("quick_replies")
            if qr and isinstance(qr, list):
                clean_qr = []
                for item in qr:
                    if isinstance(item, str) and item.strip():
                        clean_qr.append(item.strip())
                    elif isinstance(item, dict):
                        lbl = item.get("label") or item.get("text") or item.get("title") or ""
                        if lbl:
                            clean_qr.append(str(lbl).strip())
                        if not d.get("suggested_action") and item.get("route"):
                            d["suggested_action"] = {
                                "label": str(lbl or "Xem chi tiết").strip(),
                                "route": item["route"]
                            }
                    elif item is not None:
                        clean_qr.append(str(item).strip())
                d["quick_replies"] = clean_qr[:4]
            elif qr is not None and not isinstance(qr, list):
                d["quick_replies"] = [str(qr).strip()]
            return d

        try:
            parsed = json.loads(text, strict=False)
            if isinstance(parsed, list) and len(parsed) > 0 and isinstance(parsed[0], dict):
                return _normalize_dict(parsed[0])
            elif isinstance(parsed, dict):
                return _normalize_dict(parsed)
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
        cleaned_text = text.strip()
        if cleaned_text.startswith("{") and cleaned_text.endswith("}"):
            cleaned_text = cleaned_text[1:-1].strip()
        if len(cleaned_text) > 20:
            return {
                "answer": cleaned_text,
                "quick_replies": [],
                "suggested_action": None
            }
        return None

    def _build_loan_advisory_answer(self, analysis: Dict[str, Any], user_question: str = "") -> Dict[str, Any]:
        """Tư vấn trực diện, chuẩn xác 100% về Khoản Vay Quick Loan & Dự tính trả góp (Vay ra vay, Lãi vay ra lãi vay)"""
        base_amt = analysis["fmt_base_amount"]
        l_calc = analysis["loan_calc"]

        lines = [
            f"Dạ Sen Hồng xin tư vấn chi tiết về khoản vay tiêu dùng **{base_amt}** (Kỳ hạn 12 tháng) và dự tính trả nợ theo đúng chuẩn **dư nợ giảm dần** để Quý khách chủ động kế hoạch tài chính ạ:\n",
            f"1. 📈 **Lãi suất & Biểu phí khoản vay:**",
            f"- **Lãi suất vay ưu đãi:** Chỉ từ **1.2% - 1.5%/tháng** (tương đương 14.4%/năm) tính trên **dư nợ giảm dần**.",
            f"- **Nguyên tắc dư nợ giảm dần:** Tiền lãi tháng sau luôn thấp hơn tháng trước vì chỉ tính trên số dư nợ gốc thực tế còn nợ sau mỗi kỳ thanh toán.",
            f"- **Phí tất toán trước hạn:** **0 VNĐ (Miễn phí 100%)**, Quý khách có thể thanh toán hết nợ bất kỳ lúc nào mà không bị phạt.",
            f"- **Phí thẩm định & hồ sơ:** **0 VNĐ (Miễn phí 100%)**.\n",
            f"2. 🧮 **Bảng dự tính trả góp chi tiết cho {base_amt} (Kỳ hạn 12 tháng):**",
            f"- **Tiền gốc cố định hàng tháng:** **{l_calc['fmt_monthly_principal']}/tháng**.",
            f"- **Tiền trả tháng đầu tiên (cao nhất):** **{l_calc.get('fmt_first_month_payment', '')}** (gồm tiền gốc + tiền lãi tháng đầu {l_calc.get('fmt_first_month_interest', '360.000đ')}).",
            f"- **Tiền trả tháng cuối cùng (thấp nhất):** **{l_calc.get('fmt_last_month_payment', '')}** (gốc + tiền lãi tháng cuối {l_calc.get('fmt_last_month_interest', '30.000đ')}).",
            f"- **Tổng tiền lãi ước tính cả kỳ 12 tháng:** **{l_calc['fmt_total_interest']}**.\n",
            f"3. ⚡ **Thời gian xét duyệt & Thủ tục giải ngân:**",
            f"- **Thời gian giải ngân:** Tiền vào ví chỉ trong **1 phút** sau khi phê duyệt hợp đồng điện tử bằng Smart OTP.",
            f"- **Hồ sơ yêu cầu:** **DUY NHẤT 01 GIẤY TỜ** là Thẻ Căn cước / CCCD gắn chip chính chủ đã eKYC, **hoàn toàn không cần nộp bảng lương**, không cần sao kê giấy hay thế chấp tài sản.",
            f"- **Độ tuổi:** Công dân Việt Nam từ đủ 18 đến 60 tuổi, không có nợ xấu CIC.\n",
            f"👉 Quý khách có thể bấm nút **[Vay nhanh Quick Loan]** hoặc chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        ]

        return {
            "answer": "\n".join(lines),
            "sources": ["Quy chế vay tiêu dùng tín chấp Quick Loan", "Biểu lãi suất cho vay Sen Hồng Bank"],
            "quick_replies": ["Đăng ký vay ngay", "Bảng lịch trả nợ vay", "Hạn mức vay Quick Loan"],
            "suggested_action": {"label": "Vay nhanh Quick Loan", "route": "/bills/quick-loan"}
        }

    def _build_savings_advisory_answer(self, analysis: Dict[str, Any], user_question: str = "") -> Dict[str, Any]:
        """Tư vấn trực diện, chuẩn xác 100% về Gửi Tiết Kiệm & Lãi suất sinh lời (Tiết kiệm ra tiết kiệm, Lãi tiết kiệm ra lãi tiết kiệm)"""
        base_amt = analysis["fmt_base_amount"]
        src = analysis["amount_source"]
        term_y = analysis["term_years"]
        s_calc = analysis["savings_calc"]

        if src == "WALLET_BALANCE":
            intro = f"Dạ ghi nhận số dư khả dụng hiện tại trong tài khoản của Quý khách là **{base_amt}**."
        else:
            intro = f"Dạ với số tiền vốn **{base_amt}**, em xin gửi Quý khách bản kế hoạch gửi tiết kiệm online sinh lời tối ưu:"

        t_data = s_calc["target_data"]
        y1_data = s_calc["yearly_breakdown"][0]
        goal_calc = analysis.get("goal_calc")
        is_goal = analysis.get("is_goal_intent", False)

        lines = [f"{intro}\n"]

        if is_goal and goal_calc:
            lines.extend([
                f"🎯 **Kế hoạch Tích Lũy Mục Tiêu:**",
                f"Để tích lũy được số tiền mục tiêu **{base_amt}** sau **{term_y} năm** ({goal_calc['term_months']} tháng):",
                f"- Số tiền cần gửi tích lũy đều đặn mỗi tháng: **{goal_calc['fmt_monthly_deposit']}/tháng**.",
                f"- Tổng số tiền gốc Quý khách thực đóng: **{goal_calc['fmt_total_deposit']}**.",
                f"- Tiền lãi ngân hàng hỗ trợ sinh ra: **+{goal_calc['fmt_earned_interest']}** (chiếm ~{round(goal_calc['earned_interest']/goal_calc['target_amount']*100, 1)}% tổng tài sản mục tiêu)!\n"
            ])

        lines.extend([
            f"📈 **1. Lãi suất Tiền gửi Tiết kiệm Online (Lãi kép):**",
            f"- Mức lãi suất áp dụng: **{rate_config.SAVINGS_RATES[12]:.1f}%/năm** (Kỳ hạn 12 tháng) hoặc lên tới **{rate_config.SAVINGS_RATES[24]:.1f}%/năm** (Kỳ hạn 24 - 36 tháng).",
            f"- Hình thức: Tiền gửi online tự động tái tục cả gốc và lãi khi đến hạn (Lãi nhập gốc sinh lời lũy kế).",
            f"- Tiền lãi nhận sau **1 năm đầu**: **{y1_data['fmt_interest_savings']}** (Tổng tài sản: **{y1_data['fmt_total_savings']}**).",
            f"- Tiền lãi nhận sau **{term_y} năm**: **{t_data['fmt_interest_savings']}** (Tổng tài sản tăng trưởng: **{t_data['fmt_total_savings']}**).",
            f"- **So sánh với việc để tiền trong tài khoản thanh toán (0.2%/năm):** Sau {term_y} năm chỉ nhận được **{t_data['fmt_interest_casa']}**. Việc gửi tiết kiệm online giúp Quý khách sinh lời vượt trội hơn **+{t_data['fmt_difference']}**!\n",
            f"📊 **Bảng tăng trưởng tài sản theo thời gian:**\n",
            f"{s_calc['markdown_table']}\n",
            f"💡 **2. Lời khuyên tối ưu lãi suất & Bảo toàn vốn:**",
            f"- **Bảo toàn lãi suất theo Thông tư 04/2022/TT-NHNN:** Khi có việc đột xuất, Quý khách được quyền rút một phần tiền gốc trước hạn. Phần tiền gốc còn lại vẫn được giữ nguyên mức lãi suất có kỳ hạn ban đầu mà không bị mất toàn bộ lãi.",
            f"- **Chiến lược bậc thang:** Quý khách có thể chia số tiền làm 2 sổ (1 sổ 6 tháng lãi suất {rate_config.SAVINGS_RATES[6]:.1f}%/năm để dự phòng chi tiêu và 1 sổ 12-24 tháng lãi suất {rate_config.SAVINGS_RATES[12]:.1f}% - {rate_config.SAVINGS_RATES[24]:.1f}%/năm để tối đa hóa lợi nhuận).",
            f"- Quý khách có thể mở sổ tiết kiệm online 24/7 chỉ từ 1.000.000 VNĐ ngay trên ứng dụng bằng nút bên dưới ạ!\n",
            f"👉 Quý khách có thể bấm nút **[Mở sổ tiết kiệm ngay]** hoặc chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        ])

        return {
            "answer": "\n".join(lines),
            "sources": ["Biểu lãi suất tiết kiệm Sen Hồng", "Thông tư 04/2022/TT-NHNN"],
            "quick_replies": ["Mở sổ tiết kiệm online", "Biểu lãi suất tiết kiệm", "Chiến lược tiết kiệm bậc thang"],
            "suggested_action": {"label": "Mở sổ tiết kiệm ngay", "route": "/bills/savings"}
        }

    def _build_compound_comparison_answer(self, analysis: Dict[str, Any], user_question: str = "") -> Dict[str, Any]:
        """Tư vấn so sánh 2 chiều giữa Gửi Tiết Kiệm và Vay Vốn khi khách hàng chủ động yêu cầu so sánh hoặc lập kế hoạch toàn diện"""
        base_amt = analysis["fmt_base_amount"]
        term_y = analysis["term_years"]
        s_calc = analysis["savings_calc"]
        l_calc = analysis["loan_calc"]
        t_data = s_calc["target_data"]

        lines = [
            f"Dạ Sen Hồng xin gửi Quý khách bảng đối chiếu so sánh 2 chiều giữa Gửi Tiết Kiệm và Vay Vốn cho số tiền **{base_amt}**:\n",
            f"📈 **1. Kế hoạch Gửi Tiết Kiệm Online Lãi Kép ({term_y} năm) (Kỳ hạn 12 tháng - {rate_config.SAVINGS_RATES[12]:.1f}%/năm):**",
            f"- Tiền lãi sinh ra sau 1 năm: **{s_calc['yearly_breakdown'][0]['fmt_interest_savings']}**.",
            f"- Sau {term_y} năm với lãi kép tái tục: Nhận tổng lãi **+{t_data['fmt_interest_savings']}** (Tổng tài sản: **{t_data['fmt_total_savings']}**).",
            f"- Bảo toàn lãi suất khi rút gốc một phần theo Thông tư 04/2022/TT-NHNN.\n",
            f"💼 **2. Đối chiếu Khoản Vay Tiêu Dùng Quick Loan (Kỳ hạn 12 tháng - Dư nợ giảm dần 1.2%/tháng):**",
            f"- Tiền gốc trả cố định: **{l_calc['fmt_monthly_principal']}/tháng**.",
            f"- Tiền trả tháng đầu: **{l_calc['fmt_first_month_payment']}**, tháng cuối: **{l_calc['fmt_last_month_payment']}**.",
            f"- Tổng tiền lãi vay 12 tháng: **{l_calc['fmt_total_interest']}** (0đ phí phạt tất toán trước hạn).\n",
            f"💡 **Lời khuyên tư vấn tài chính thông minh:** Nếu Quý khách cần vốn gấp để giải quyết công việc, gói vay Quick Loan giải ngân trong 1 phút là giải pháp linh hoạt. Nếu có nguồn tiền nhàn rỗi, gửi tiết kiệm online giúp bảo toàn vốn và sinh lời an toàn.\n",
            f"👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết cho từng phương án nhé ạ!"
        ]

        return {
            "answer": "\n".join(lines),
            "sources": ["Biểu lãi suất tiết kiệm Sen Hồng", "Quy định vay tiêu dùng Quick Loan"],
            "quick_replies": ["Mở sổ tiết kiệm online", "Vay nhanh Quick Loan", "Bảng lịch trả nợ vay"],
            "suggested_action": {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}
        }

    def _build_financial_advisory_answer(self, analysis: Dict[str, Any], user_question: str = "") -> Dict[str, Any]:
        """Điều hướng thông minh: Vay ra vay, Lãi ra lãi, Tiết kiệm ra tiết kiệm (Không trả lời lan man)"""
        q = (user_question or analysis.get("user_question") or "").lower()
        is_loan = analysis.get("is_loan_intent") or (
            any(k in q for k in ["vay", "khoan vay", "khoản vay", "quick loan", "trả nợ vay", "tra no vay", "mượn", "dư nợ", "du no"]) and
            not any(k in q for k in ["tiết kiệm", "tiet kiem", "gửi tiền", "gui tien"])
        )
        is_comp = analysis.get("is_comparison_intent") or any(k in q for k in ["so sánh", "so sanh", "hay là", "hay la", "nên vay hay", "nen vay hay", "kế hoạch tài chính toàn diện"])

        if is_comp:
            return self._build_compound_comparison_answer(analysis, user_question)
        elif is_loan:
            return self._build_loan_advisory_answer(analysis, user_question)
        else:
            return self._build_savings_advisory_answer(analysis, user_question)

    def _extractive_fallback_answer(self, context: Optional[str], user_question: str, history: Optional[List[MessageItem]] = None) -> Dict[str, Any]:
        """Tự động trích xuất nội dung từ kho tài liệu chính thống khi LLM gặp sự cố mạng (Anti-Rambling Banking Fallback)"""
        q_lower = user_question.lower()

        # 1. Kiểm tra xem có phải câu hỏi dài / phức tạp đa ý định hoặc chuyên đề kinh tế vĩ mô không (Ưu tiên số 1)
        long_resp = handle_comprehensive_long_query(user_question)
        if long_resp:
            return long_resp

        # 2. Kiểm tra câu hỏi tính toán tài chính / lãi suất / trả góp khoản vay (Vay ra vay, Lãi ra lãi)
        fin_analysis = generate_comprehensive_financial_analysis(user_question, user_wallet=getattr(self, "_current_user_wallet", None))
        if fin_analysis:
            is_explicit_loan = fin_analysis.get("is_loan_intent") or (
                any(k in q_lower for k in ["vay", "khoan vay", "khoản vay", "quick loan", "trả nợ vay", "tra no vay", "mượn", "dư nợ", "du no"]) and
                not any(k in q_lower for k in ["tiết kiệm", "tiet kiem", "gửi tiền", "gui tien"])
            )
            is_explicit_savings = fin_analysis.get("is_savings_intent") or (
                (any(k in q_lower for k in ["tiết kiệm", "tiet kiem", "gửi tiền", "gui tien", "gửi góp", "gui gop", "lãi kép", "lai kep", "tích lũy", "tich luy"]) or
                 bool(re.search(r'\b(?:gửi|gui)\s+\d+', q_lower))) and
                not any(k in q_lower for k in ["vay", "khoan vay", "khoản vay", "quick loan"])
            )
            is_comparison = fin_analysis.get("is_comparison_intent") or any(k in q_lower for k in ["so sánh", "so sanh", "hay là", "hay la", "nên vay hay", "nen vay hay", "kế hoạch tài chính toàn diện"])

            if is_comparison:
                return self._build_compound_comparison_answer(fin_analysis, user_question)
            elif is_explicit_loan:
                return self._build_loan_advisory_answer(fin_analysis, user_question)
            elif is_explicit_savings or fin_analysis["term_years"] >= 2 or any(k in q_lower for k in ["tiền trong tài khoản", "tien trong tai khoan", "tự nó", "tu no", "vài năm", "vai nam", "10 năm", "10 nam", "10 namw"]):
                return self._build_savings_advisory_answer(fin_analysis, user_question)

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

        # Hồ sơ & Giấy tờ Tạo tài khoản / Mở App Sen Hồng
        is_account_opening_docs = (
            any(k in q_lower for k in [
                "tạo tài khoản", "tao tai khoan", "mở tài khoản", "mo tai khoan",
                "tạo app", "tao app", "mở app", "mo app", "đăng ký tài khoản", "dang ky tai khoan", "đăng ký app"
            ]) and any(k in q_lower for k in [
                "giấy tờ", "giay to", "hồ sơ", "ho so", "cần gì", "can gi", "cần những gì", "can nhung gi",
                "thủ tục", "thu tuc", "điều kiện", "dieu kien", "bao nhiêu tuổi", "bao nhieu tuoi",
                "tuổi", "tuoi", "không có nfc", "khong co nfc", "smart lounge", "vneid"
            ])
        ) or any(k in q_lower for k in [
            "giấy tờ mở tài khoản", "giay to mo tai khoan", "giấy tờ tạo app", "giay to tao app",
            "hồ sơ tạo tài khoản", "ho so tao tai khoan", "hồ sơ mở tài khoản", "ho so mo tai khoan",
            "bao nhiêu tuổi được mở tài khoản", "bao nhieu tuoi duoc mo tai khoan", "bao nhiêu tuổi thì mở app được",
            "bao nhiêu tuổi được tạo app", "không có nfc có mở app được không", "khong co nfc co mo app duoc khong"
        ])
        if is_account_opening_docs:
            return {
                "answer": (
                    "Dạ để **Tạo tài khoản / Mở ứng dụng Ngân hàng Số Sen Hồng** trực tuyến 100% qua eKYC, "
                    "Quý khách chỉ cần chuẩn bị danh mục giấy tờ và đáp ứng điều kiện đơn giản như sau ạ:\n\n"
                    "1. 🪪 **Giấy tờ tùy thân bắt buộc (01 loại duy nhất):**\n"
                    "  - **Thẻ Căn cước** (theo Luật Căn cước 2023) hoặc **Thẻ CCCD gắn chip 12 số** còn thời hạn sử dụng do Bộ Công An cấp.\n"
                    "  - *(Lưu ý: CMND 9 số cũ hoặc CCCD mã vạch không có chip đã ngừng hỗ trợ mở tài khoản ngân hàng điện tử theo quy định của NHNN & Bộ Công An).*\n\n"
                    "2. 📱 **Điều kiện Thuê bao & Thiết bị:**\n"
                    "  - **Số điện thoại chính chủ:** Đăng ký trùng khớp thông tin cá nhân trên mạng viễn thông.\n"
                    "  - **Điện thoại thông minh:** Hỗ trợ camera và kết nối **NFC** để quét chip vi mạch CCCD.\n"
                    "  - 👉 **Nếu máy không có NFC:** Quý khách mang CCCD gắn chip đến bất kỳ điểm **Sen Hồng Smart Lounge** trên toàn quốc để giao dịch viên hỗ trợ quét chip 2 phút hoàn toàn miễn phí.\n"
                    "  - 👉 **Đã có VNeID Mức 2:** Quý khách có thể chọn mở tài khoản liên thông qua VNeID chỉ trong 30 giây.\n\n"
                    "3. ⚖️ **Độ tuổi & Người nước ngoài:**\n"
                    "  - Công dân Việt Nam từ **đủ 15 tuổi trở lên** có CCCD gắn chip và đầy đủ năng lực hành vi dân sự.\n"
                    "  - Người nước ngoài: Cần Hộ chiếu (còn hạn từ 6 tháng trở lên) kèm Thị thực/Thẻ tạm trú (còn hạn từ 12 tháng trở lên) mở tại quầy Smart Lounge."
                ),
                "quick_replies": ["Đăng ký tài khoản ngay", "Quét chip NFC CCCD", "Mở tài khoản bằng VNeID"],
                "suggested_action": {"label": "Đăng ký tài khoản ngay", "route": "/auth/register"},
                "sources": ["Cẩm nang Giấy tờ Mở tài khoản Sen Hồng Bank", "Thông tư 17/2024/TT-NHNN"]
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

        # Điều kiện & Thủ tục vay Quick Loan / Giấy tờ vay vốn
        if is_loan_q and any(k in q_lower for k in [
            "điều kiện", "dieu kien", "thủ tục", "thu tuc", "cần giấy tờ gì", "can giay to gi",
            "ai được vay", "ai duoc vay", "hồ sơ vay", "ho so vay", "yêu cầu", "yeu cau",
            "giấy tờ", "giay to", "bảng lương", "bang luong", "sao kê", "sao ke",
            "chứng minh thu nhập", "chung minh thu nhap", "thế chấp", "the chap"
        ]):
            return {
                "answer": (
                    "Dạ, Sen Hồng Bank xin tư vấn chi tiết về **Hồ sơ, Giấy tờ vay vốn** theo từng hạn mức để Quý khách chuẩn bị thuận tiện nhất ạ:\n\n"
                    "1. 🚀 **GÓI VAY NHANH QUICK LOAN (Từ 5 triệu đến 50 triệu VNĐ) - 100% ONLINE:**\n"
                    "  - **Giấy tờ yêu cầu:** **DUY NHẤT 01 GIẤY TỜ** là **Thẻ Căn cước / CCCD gắn chip chính chủ** đã định danh eKYC trên App Sen Hồng.\n"
                    "  - **Có cần bảng lương không?** 👉 **HOÀN TOÀN KHÔNG CẦN BẢNG LƯƠNG**, không cần sao kê giấy, không cần chứng minh thu nhập hay thế chấp tài sản! Hệ thống chấm điểm tự động qua dữ liệu eKYC và CIC.\n"
                    "  - **Điều kiện:** Công dân Việt Nam từ đủ 18 - 60 tuổi, không có nợ xấu CIC.\n"
                    "  - **Thời gian giải ngân:** Duyệt tự động trong 30 giây, giải ngân về ví chỉ trong **1 phút**.\n\n"
                    "2. 🏢 **GÓI VAY TIÊU DÙNG HẠN MỨC CAO (Từ 50 triệu đến 200 triệu VNĐ):**\n"
                    "  - Thẻ Căn cước / CCCD gắn chip chính chủ.\n"
                    "  - **Chứng minh thu nhập (Chuẩn bị 01 trong 3 loại):** Sao kê lương 3-6 tháng gần nhất, hoặc Hợp đồng lao động, hoặc ảnh chụp quá trình đóng BHXH trên ứng dụng **VssID**.\n\n"
                    "3. 🏪 **GÓI VAY HỘ KINH DOANH / TIỂU THƯƠNG (Hạn mức đến 300 triệu VNĐ):**\n"
                    "  - Thẻ Căn cước của chủ hộ kinh doanh + Giấy ĐKKD hoặc hợp đồng thuê sạp/mặt bằng.\n"
                    "  - Biên lai thuế và sao kê giao dịch nhận tiền mã **VietQR Pro Sen Hồng** 3 - 6 tháng."
                ),
                "quick_replies": ["Vay nhanh Quick Loan", "Bảng tính trả nợ chi tiết", "Lãi suất vay Quick Loan"],
                "suggested_action": {"label": "Vay nhanh", "route": "/bills/quick-loan"},
                "sources": ["Cẩm nang Hồ sơ Vay vốn Sen Hồng Bank", "Thông tư 06/2023/TT-NHNN"]
            }

        # Phí tất toán khoản vay trước hạn
        if is_loan_q and any(k in q_lower for k in [
            "tất toán trước hạn", "tat toan truoc han", "trả trước hạn", "tra truoc han",
            "phạt", "phat", "phí tất toán", "phi tat toan"
        ]):
            return {
                "answer": (
                    "Dạ, tại Sen Hồng Bank, gói vay tiêu dùng Quick Loan áp dụng chính sách **KHÔNG PHẠT TẤT TOÁN TRƯỚC HẠN (0 VNĐ)** ạ:\n\n"
                    "- 🆓 **Phí phạt tất toán trước hạn:** **0 VNĐ (Miễn phí 100%)**, Quý khách có thể tất toán trả hết nợ bất kỳ lúc nào mà không bị phạt.\n"
                    "- 📉 **Lợi ích:** Tiền lãi chỉ tính đến đúng ngày Quý khách tất toán thực tế theo dư nợ giảm dần, giúp tiết kiệm tối đa tiền lãi."
                ),
                "quick_replies": ["Lịch trả nợ vay", "Vay nhanh", "Lãi suất vay Quick Loan"],
                "suggested_action": {"label": "Lịch trả nợ vay", "route": "/loan/schedule"}
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

        if any(k in q_lower for k in [
            "nfc", "chip cccd", "cccd", "2345", "khuon mat 3d", "khuôn mặt 3d",
            "sinh trắc học", "sinh trac hoc", "khuôn mặt", "khuon mat", "bắt quét", "bat quet",
            "lỗi quét", "loi quet", "đọc chip", "doc chip", "lỗi sinh trắc học", "loi sinh trac hoc"
        ]):
            return {
                "answer": (
                    "Dạ theo **Quyết định 2345/QĐ-NHNN** của Ngân hàng Nhà nước, hướng dẫn cài đặt và xử lý lỗi Sinh trắc học NFC CCCD như sau ạ:\n\n"
                    "- 🛡️ **Quy định bắt buộc:** Giao dịch chuyển tiền từ **10.000.000 VNĐ/lần** hoặc tổng trên **20.000.000 VNĐ/ngày** bắt buộc phải xác thực khuôn mặt khớp với dữ liệu thẻ CCCD gắn chip của Bộ Công an.\n"
                    "- 📱 **Mẹo quét chip NFC thành công 100% trong 3 giây:**\n"
                    "  + **Tháo ốp lưng:** Tháo ốp lưng dày hoặc ốp có kim loại/nam châm MagSafe trước khi quét.\n"
                    "  + **Vị trí đầu đọc NFC:**\n"
                    "    • iPhone: Nằm ở **mép đỉnh trên cùng** mặt lưng máy (ngang cụm camera).\n"
                    "    • Android (Samsung, Xiaomi...): Nằm ở **chính giữa mặt lưng** máy (vui lòng bật NFC trong phần Cài đặt).\n"
                    "  + **Thao tác:** Áp sát mặt sau thẻ CCCD (phần có vi mạch chip) cố định vào vị trí đọc, giữ yên trong **3 đến 5 giây** cho đến khi app báo thành công.\n"
                    "- 🚀 **Hạn mức sau xác thực:** Nâng hạn mức chuyển tiền lên tới **500.000.000 VNĐ/ngày**.\n\n"
                    "Quý khách bấm nút bên dưới để mở trực tiếp màn hình quét chip CCCD ạ!"
                ),
                "quick_replies": ["Quét chip NFC CCCD", "Hạn mức theo eKYC", "Chữ ký số Smart OTP"],
                "suggested_action": {"label": "Quét chip NFC CCCD", "route": "/profile/nfc-reader"}
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

        # Tra soát giao dịch / Treo tiền chuyển khoản Napas
        is_dispute_q = any(k in q_lower for k in [
            "chưa nhận được", "chua nhan duoc", "trừ tiền rồi mà", "tru tien roi ma",
            "bị trừ tiền nhưng", "bi tru tien nhung", "treo tiền", "treo tien", "tiền bị treo",
            "lỗi chuyển tiền", "loi chuyen tien", "chuyển nhầm", "chuyen nham", "tra soát", "tra soat",
            "khiếu nại", "khieu nai", "tiền chưa tới", "tiền chưa qua"
        ])
        if is_dispute_q:
            return {
                "answer": (
                    "Dạ Sen Hồng xin thông tin đến Quý khách về trường hợp chuyển tiền bị chậm hoặc người nhận chưa thấy tiền ạ:\n\n"
                    "- ⏱️ **Thời gian đối soát liên ngân hàng:** Các giao dịch Napas 24/7 thường thành công trong 1-3 giây. Tuy nhiên vào các khung giờ cao điểm, ngân hàng thụ hưởng có thể mất từ **5 đến 30 phút** để cập nhật số dư vào tài khoản người nhận.\n"
                    "- 🧾 **Biên lai chuyển tiền:** Quý khách vào mục **Lịch sử giao dịch** -> Chọn giao dịch đó -> Bấm **Tải biên lai** (có đầy đủ Mã chuẩn chi Napas Trace No) để gửi người nhận đối soát.\n"
                    "- 🛡️ **Bảo toàn dòng tiền (Saga & Double-Entry Ledger):** Nếu giao dịch gặp sự cố mạng Napas, hệ thống tự động hoàn tiền nguyên vẹn (Reversal) về ví Sen Hồng của Quý khách.\n"
                    "- 📝 **Gửi yêu cầu tra soát trực tuyến:** Nếu sau 30 phút người nhận vẫn chưa thấy tiền, Quý khách bấm nút **[Lịch sử giao dịch & Tra soát]** bên dưới hoặc gọi hotline 24/7 **1900-SENHONG** (1900 736 466) để chuyên viên hỗ trợ tra soát tức thì ạ!"
                ),
                "quick_replies": ["Xem lịch sử giao dịch", "Gửi yêu cầu tra soát", "Hotline 1900-SENHONG"],
                "suggested_action": {"label": "Lịch sử giao dịch & Tra soát", "route": "/history"}
            }

        # Giới thiệu bạn bè nhận thưởng
        if any(k in q_lower for k in ["gioi thieu ban be", "giới thiệu bạn bè", "referral", "ma gioi thieu", "mã giới thiệu", "moi ban", "mời bạn"]):
            return {
                "answer": (
                    "Dạ, chương trình **'Lan Tỏa Sen Hồng - Rinh Thưởng 50.000đ'** áp dụng không giới hạn số lượt:\n\n"
                    "- 🎁 **Người giới thiệu (Quý khách):** Nhận ngay **50.000 VNĐ tiền mặt** vào ví cho mỗi bạn bè đăng ký và eKYC thành công.\n"
                    "- 🎁 **Người được giới thiệu:** Nhận gói Voucher ưu đãi thanh toán hóa đơn & nạp điện thoại trị giá **100.000 VNĐ**.\n"
                    "- 📲 **Cách giới thiệu:** Mở app Sen Hồng -> Chọn **Ưu đãi** -> Nhấn **Giới thiệu bạn bè** -> Sao chép Mã giới thiệu (chính là SĐT của Quý khách) hoặc chia sẻ link tải app trực tiếp qua Zalo/Facebook."
                ),
                "quick_replies": ["Lấy mã giới thiệu", "Kho Voucher của tôi", "Chương trình ưu đãi"],
                "suggested_action": {"label": "Giới thiệu bạn bè", "route": "/referral"}
            }

        # Kho Voucher & Khuyến mãi
        if any(k in q_lower for k in ["voucher", "khuyen mai", "khuyến mãi", "ma giam gia", "mã giảm giá", "uu dai", "ưu đãi"]):
            return {
                "answer": (
                    "Dạ, tại **Kho Voucher & Khuyến Mãi Sen Hồng**, Quý khách có thể thu thập các ưu đãi hấp dẫn:\n\n"
                    "- ⚡ Giảm 20.000đ - 50.000đ cho hóa đơn Điện EVN và Nước sinh hoạt.\n"
                    "- ⚡ Chiết khấu trực tiếp tới 5% khi Nạp tiền điện thoại & Data 4G/5G.\n"
                    "- ⚡ Giảm tới 150.000đ khi Đặt vé máy bay trực tuyến iMedia.\n"
                    "- ⚡ Miễn 100% phí thường niên Thẻ ảo quốc tế Visa Platinum Virtual.\n\n"
                    "Quý khách bấm nút bên dưới để vào Kho Voucher lưu mã và sử dụng ngay ạ!"
                ),
                "quick_replies": ["Kho Voucher & Ưu đãi", "Giới thiệu bạn bè", "Thanh toán hóa đơn"],
                "suggested_action": {"label": "Kho Voucher", "route": "/promotions"}
            }

        # =========================================================================
        # 1.1 HẠN MỨC GIAO DỊCH (TRANSACTION LIMITS - ƯU TIÊN TRƯỚC CÁCH LÀM)
        # =========================================================================
        # Hạn mức chuyển tiền
        is_transfer_limit_q = any(k in q_lower for k in [
            "hạn mức chuyển", "han muc chuyen", "chuyển tối đa", "chuyen toi da",
            "chuyển được bao nhiêu", "chuyen duoc bao nhieu", "hạn mức chuyển tiền", "han muc chuyen tien",
            "chuyển tối đa bao nhiêu", "chuyển 1 lần tối đa", "chuyển 1 ngày tối đa", "hạn mức giao dịch chuyển"
        ]) or (
            any(k in q_lower for k in ["hạn mức", "han muc", "tối đa bao nhiêu", "toi da bao nhieu"]) and 
            any(t in q_lower for t in ["chuyển tiền", "chuyen tien", "chuyển khoản", "chuyen khoan", "napas"])
        )
        if is_transfer_limit_q:
            return {
                "answer": (
                    "Dạ, hạn mức chuyển tiền trực tuyến (Napas 24/7 và Nội bộ) trên Ngân hàng Số Sen Hồng được quy định theo cấp độ định danh eKYC như sau ạ:\n\n"
                    "- 📌 **Tài khoản eKYC Cấp 1 (Định danh chụp ảnh CCCD):**\n"
                    "  + Hạn mức tối đa: **10.000.000 VNĐ/giao dịch**.\n"
                    "  + Hạn mức tối đa: **20.000.000 VNĐ/ngày**.\n\n"
                    "- 🛡️ **Tài khoản eKYC Cấp 2 (Xác thực Sinh trắc học & Đọc chip NFC CCCD theo QĐ 2345/QĐ-NHNN):**\n"
                    "  + Hạn mức tối đa: **100.000.000 VNĐ/giao dịch**.\n"
                    "  + Hạn mức tối đa: **500.000.000 VNĐ/ngày**.\n\n"
                    "- ⚡ **Lưu ý Quyết định 2345:** Giao dịch trên **10.000.000 VNĐ/lần** hoặc tổng giao dịch tích lũy trong ngày vượt quá **20.000.000 VNĐ** bắt buộc phải quét khuôn mặt 3D Face ID khớp với dữ liệu thẻ CCCD gắn chip của Bộ Công an.\n\n"
                    "Quý khách có thể nâng hạn mức lên tới 500 triệu đồng/ngày hoàn toàn miễn phí bằng cách quét chip NFC CCCD bên dưới ạ!"
                ),
                "quick_replies": ["Quét chip NFC CCCD", "Chuyển tiền Napas 24/7", "Biểu phí chuyển tiền"],
                "suggested_action": {"label": "Nâng hạn mức (NFC CCCD)", "route": "/profile/nfc-reader"}
            }

        # Phí chuyển tiền
        is_transfer_fee_q = any(k in q_lower for k in [
            "chuyển tiền có mất phí", "chuyen tien co mat phi", "phí chuyển tiền", "phi chuyen tien",
            "chuyển tiền mất bao nhiêu phí", "chuyển liên ngân hàng có mất phí", "chuyển tiền napas có mất phí",
            "chuyển tiền tốn phí", "chuyển tiền miễn phí", "chuyen tien ton phi", "chuyen tien mien phi",
            "phí chuyển khoản", "phi chuyen khoan", "chuyển khoản có mất phí", "chuyen khoan co mat phi"
        ]) or (
            any(f in q_lower for f in ["phí", "phi", "mất phí", "mat phi", "tốn phí", "ton phi"]) and
            any(t in q_lower for t in ["chuyển tiền", "chuyen tien", "chuyển khoản", "chuyen khoan", "napas"])
        )
        if is_transfer_fee_q:
            return {
                "answer": (
                    "Dạ, tại Ngân hàng Số Sen Hồng, mọi giao dịch chuyển tiền đều **HOÀN TOÀN MIỄN PHÍ 100% TRỌN ĐỜI** ạ:\n\n"
                    "- 🆓 **Chuyển tiền nội bộ Sen Hồng:** Miễn phí 100%, tiền nhận tức thì 24/7 qua SĐT/STK/Biệt danh Alias.\n"
                    "- 🆓 **Chuyển tiền liên ngân hàng Napas 24/7:** Miễn phí 100% tới hơn 40 ngân hàng toàn quốc (Vietcombank, MB, Techcombank, BIDV, Agribank, ACB, VPBank...).\n"
                    "- 🆓 **Chuyển tiền qua mã VietQR:** Miễn phí 100% không giới hạn số lượt.\n"
                    "- 🆓 **Không thu bất kỳ khoản phụ phí nào:** Không phí duy trì tài khoản, không yêu cầu số dư tối thiểu trong ví."
                ),
                "quick_replies": ["Chuyển tiền ngay", "Hạn mức chuyển tiền", "Mã VietQR của tôi"],
                "suggested_action": {"label": "Chuyển tiền ngay", "route": "/transfer"}
            }

        # Hạn mức rút tiền ATM
        is_atm_limit_q = any(k in q_lower for k in [
            "hạn mức rút atm", "han muc rut atm", "rút atm tối đa", "rut atm toi da",
            "hạn mức rút tiền atm", "han muc rut tien atm", "rút tiền atm tối đa bao nhiêu",
            "rút atm được bao nhiêu", "rút tiền atm tối thiểu", "hạn mức rút tiền tại atm",
            "hạn mức rút cây atm", "rút tối đa bao nhiêu ở atm", "rut duoc bao nhieu o atm"
        ]) or (
            any(l in q_lower for l in ["hạn mức", "han muc", "tối đa bao nhiêu", "toi da bao nhieu", "tối thiểu", "toi thieu"]) and
            any(w in q_lower for w in ["rút tiền", "rut tien", "rút atm", "rut atm"]) and
            any(a in q_lower for a in ["atm", "cây atm", "không thẻ", "khong the"])
        )
        if is_atm_limit_q:
            return {
                "answer": (
                    "Dạ, hạn mức rút tiền mặt không cần thẻ tại cây ATM qua Sen Hồng như sau ạ:\n\n"
                    "- 💵 **Số tiền rút tối thiểu:** **50.000 VNĐ/lần**.\n"
                    "- 💵 **Hạn mức rút tối đa mỗi lần:** **5.000.000 VNĐ/lần**.\n"
                    "- 💵 **Hạn mức rút tối đa mỗi ngày:** **20.000.000 VNĐ/ngày**.\n"
                    "- 🏦 **Mạng lưới cây ATM hỗ trợ:** Miễn phí 100% tại hơn 20.000 cây ATM của toàn bộ các ngân hàng thuộc liên minh Napas trên toàn quốc (Vietcombank, BIDV, VietinBank, Agribank, MB, Techcombank, ACB...)."
                ),
                "quick_replies": ["Rút tiền ATM không thẻ", "Biểu phí rút tiền ATM", "Tìm cây ATM gần nhất"],
                "suggested_action": {"label": "Rút tiền ATM không thẻ", "route": "/atm-withdrawal"}
            }

        # Phí rút tiền ATM
        is_atm_fee_q = any(k in q_lower for k in [
            "rút tiền atm có mất phí", "rut tien atm co mat phi", "phí rút tiền atm", "phi rut tien atm",
            "rút atm có tốn phí", "rut atm co ton phi", "rút tiền tại cây atm có mất phí", "phí rút atm", "phi rut atm",
            "rút tiền không thẻ có mất phí", "phí rút tiền không thẻ"
        ]) or (
            any(f in q_lower for f in ["phí", "phi", "mất phí", "mat phi", "tốn phí", "ton phi", "mien phi", "miễn phí"]) and
            any(w in q_lower for w in ["rút tiền", "rut tien", "rút atm", "rut atm"]) and
            any(a in q_lower for a in ["atm", "cây atm", "không thẻ", "khong the"])
        )
        if is_atm_fee_q:
            return {
                "answer": (
                    "Dạ, dịch vụ rút tiền mặt không cần thẻ tại cây ATM qua ứng dụng Sen Hồng là **HOÀN TOÀN MIỄN PHÍ 100%** ạ:\n\n"
                    "- 🆓 **Phí rút tiền mặt tại ATM:** **0 VNĐ (Miễn phí 100%)** tại tất cả cây ATM thuộc liên minh Napas trên cả nước.\n"
                    "- 🆓 **Phí tạo mã rút tiền trên App:** Miễn phí 100%.\n"
                    "- 💵 **Hạn mức áp dụng:** Tối thiểu 50.000đ/lần, tối đa 5.000.000đ/lần và 20.000.000đ/ngày."
                ),
                "quick_replies": ["Rút tiền ATM không thẻ", "Hạn mức rút tiền ATM", "Tìm cây ATM gần nhất"],
                "suggested_action": {"label": "Rút tiền ATM không thẻ", "route": "/atm-withdrawal"}
            }

        # Số tiền gửi tiết kiệm tối thiểu
        is_min_savings_q = any(k in q_lower for k in [
            "tiết kiệm tối thiểu", "tiet kiem toi thieu", "mở sổ tối thiểu", "mo so toi thieu",
            "gửi tiết kiệm từ bao nhiêu", "gui tiet kiem tu bao nhieu", "mở sổ tiết kiệm tối thiểu",
            "mở sổ tiết kiệm online cần bao nhiêu tiền", "số tiền gửi tiết kiệm tối thiểu", "so tien gui tiet kiem toi thieu",
            "gửi tiết kiệm ít nhất bao nhiêu", "mở sổ ít nhất", "gui tiet kiem it nhat bao nhieu"
        ]) or (
            any(k in q_lower for k in ["tiết kiệm", "tiet kiem", "mở sổ", "mo so"]) and
            any(m in q_lower for m in ["tối thiểu", "toi thieu", "ít nhất", "it nhat", "thấp nhất", "thap nhat"])
        )
        if is_min_savings_q:
            return {
                "answer": (
                    "Dạ, số tiền gửi tiết kiệm tối thiểu tại Ngân hàng Số Sen Hồng cực kỳ linh hoạt để khách hàng dễ dàng tích lũy tài chính:\n\n"
                    "- 💎 **Tiết kiệm Online có kỳ hạn (1 - 36 tháng):** Tối thiểu chỉ từ **1.000.000 VNĐ**.\n"
                    "- 💎 **Tiết kiệm Tích lũy Gửi góp (Goal Savings):** Tối thiểu chỉ từ **100.000 VNĐ/lần gửi**.\n"
                    "- 💎 **Hạn mức gửi tối đa:** Không giới hạn số tiền và không giới hạn số lượng sổ tiết kiệm mở cùng lúc.\n"
                    f"- 📈 **Lãi suất ưu đãi:** Lên tới **{rate_config.SAVINGS_RATES[12]:.1f}%/năm** (kỳ hạn 12 tháng) và **{rate_config.SAVINGS_RATES[24]:.1f}%/năm** (kỳ hạn 24 tháng), lãi suất tự động nhập gốc khi tái tục."
                ),
                "quick_replies": ["Mở sổ tiết kiệm ngay", "Biểu lãi suất tiết kiệm", "Tiết kiệm tích lũy mục tiêu"],
                "suggested_action": {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}
            }

        # Điều kiện mở sổ tiết kiệm online
        is_savings_conditions_q = any(k in q_lower for k in ["tiết kiệm", "tiet kiem", "mở sổ", "mo so"]) and any(k in q_lower for k in [
            "điều kiện", "dieu kien", "thủ tục", "thu tuc", "cần gì", "can gi", "giấy tờ", "giay to", "quy định", "quy dinh"
        ]) and not any(k in q_lower for k in ["tối thiểu", "toi thieu", "lãi suất", "lai suat", "tính", "tinh"])
        if is_savings_conditions_q:
            return {
                "answer": (
                    "Dạ, điều kiện để mở sổ tiết kiệm trực tuyến tại Ngân hàng Số Sen Hồng rất thuận tiện:\n\n"
                    "- 📋 **Điều kiện tham gia:**\n"
                    "  + Là công dân Việt Nam có tài khoản ví Sen Hồng đã hoàn tất định danh eKYC.\n"
                    "  + Số dư khả dụng trong ví tối thiểu từ **1.000.000 VNĐ** (đối với tiết kiệm có kỳ hạn) hoặc từ **100.000 VNĐ** (đối với tiết kiệm tích lũy).\n"
                    "- ⚡ **Thủ tục:** Thực hiện 100% online trên ứng dụng trong 30 giây, sổ tiết kiệm điện tử có giá trị pháp lý tương đương sổ giấy mở tại quầy."
                ),
                "quick_replies": ["Mở sổ tiết kiệm ngay", "Biểu lãi suất tiết kiệm", "Tiết kiệm tích lũy"],
                "suggested_action": {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}
            }

        # Hạn mức nạp tiền vào ví
        is_deposit_limit_q = any(k in q_lower for k in [
            "hạn mức nạp tiền", "han muc nap tien", "nạp tối đa", "nap toi da",
            "nạp tối thiểu", "nap toi thieu", "nạp vào ví tối đa bao nhiêu", "hạn mức nạp ví",
            "nạp được bao nhiêu", "nap duoc bao nhieu"
        ]) or (
            any(l in q_lower for l in ["hạn mức", "han muc", "tối đa", "toi da", "tối thiểu", "toi thieu"]) and
            any(d in q_lower for d in ["nạp tiền", "nap tien", "nạp ví", "nap vi"])
        )
        if is_deposit_limit_q:
            return {
                "answer": (
                    "Dạ, hạn mức nạp tiền vào ví Sen Hồng được quy định như sau ạ:\n\n"
                    "- 💰 **Số tiền nạp tối thiểu:** **10.000 VNĐ/giao dịch**.\n"
                    "- 💰 **Hạn mức nạp tối đa:**\n"
                    "  + Tài khoản eKYC Cấp 1: Tối đa **50.000.000 VNĐ/ngày**.\n"
                    "  + Tài khoản eKYC Cấp 2 (Xác thực NFC CCCD): Tối đa **500.000.000 VNĐ/ngày**.\n"
                    "- 🆓 **Biểu phí nạp tiền:** Hoàn toàn **miễn phí 100%** từ mọi ngân hàng liên kết hoặc nạp tiền mặt tại quầy giao dịch."
                ),
                "quick_replies": ["Nạp tiền vào ví ngay", "Liên kết ngân hàng", "Nâng hạn mức eKYC"],
                "suggested_action": {"label": "Nạp tiền vào ví", "route": "/deposit"}
            }

        # Phí nạp tiền vào ví
        is_deposit_fee_q = any(k in q_lower for k in [
            "nạp tiền có mất phí", "nap tien co mat phi", "phí nạp tiền", "phi nap tien",
            "nạp tiền vào ví có tốn phí", "nạp ví mất bao nhiêu", "nap tien ton phi", "nạp tiền tốn phí"
        ]) or (
            any(f in q_lower for f in ["phí", "phi", "mất phí", "mat phi", "tốn phí", "ton phi"]) and
            any(d in q_lower for d in ["nạp tiền", "nap tien", "nạp ví", "nap vi"])
        )
        if is_deposit_fee_q:
            return {
                "answer": (
                    "Dạ, nạp tiền vào ví Sen Hồng là **HOÀN TOÀN MIỄN PHÍ 100%** ạ:\n\n"
                    "- 🆓 **Nạp online từ tài khoản ngân hàng liên kết:** Miễn phí 100%, tiền vào ví ngay trong 1 giây.\n"
                    "- 🆓 **Nạp tiền mặt tại quầy giao dịch Sen Hồng:** Miễn phí 100%.\n"
                    "- 💵 **Số tiền nạp:** Tối thiểu chỉ từ 10.000 VNĐ/giao dịch."
                ),
                "quick_replies": ["Nạp tiền vào ví ngay", "Liên kết ngân hàng", "Kiểm tra số dư ví"],
                "suggested_action": {"label": "Nạp tiền vào ví", "route": "/deposit"}
            }

        # Phí thẻ ảo Visa Platinum Virtual
        is_visa_fee_q = any(k in q_lower for k in [
            "phí thẻ visa", "phi the visa", "thẻ visa có mất phí", "the visa co mat phi",
            "phí thường niên visa", "phi thuong nien visa", "phí phát hành thẻ visa", "phi phat hanh the visa",
            "thẻ ảo có mất phí", "the ao co mat phi", "phí duy trì thẻ visa", "phi duy tri the visa"
        ]) or (
            any(f in q_lower for f in ["phí", "phi", "mất phí", "mat phi", "thường niên", "thuong nien", "phát hành", "phat hanh"]) and
            any(v in q_lower for v in ["visa", "thẻ ảo", "the ao", "platinum"])
        )
        if is_visa_fee_q:
            return {
                "answer": (
                    "Dạ, Thẻ ảo quốc tế **Visa Platinum Virtual** tại Sen Hồng Bank áp dụng chính sách **Miễn phí 100% trọn đời** ạ:\n\n"
                    "- 💳 **Phí phát hành thẻ online:** **0 VNĐ (Miễn phí 100%)**, kích hoạt thẻ dùng ngay trong 30 giây.\n"
                    "- 💳 **Phí thường niên trọn đời:** **0 VNĐ (Miễn phí 100%)**, không điều kiện chi tiêu.\n"
                    "- 💳 **Phí đổi mã CVV bảo mật:** Miễn phí 100%.\n"
                    "- 🌍 **Thanh toán quốc tế:** Miễn phí giao dịch nội địa, phí chuyển đổi ngoại tệ cực ưu đãi chỉ 1.5% khi mua sắm tại các trang web nước ngoài."
                ),
                "quick_replies": ["Mở thẻ Visa Platinum ngay", "Quản lý thẻ", "Biểu phí & Hạn mức"],
                "suggested_action": {"label": "Mở thẻ Visa Platinum", "route": "/cards"}
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

        # Bộ Công An, Đề án 06 & Định danh điện tử VNeID
        if any(k in q_lower for k in ["bộ công an", "bo cong an", "bca", "c06", "đề án 06", "de an 06", "vneid", "dân cư quốc gia", "dan cu quoc gia", "luật căn cước"]):
            return {
                "answer": (
                    "Dạ thực hiện **Đề án 06 của Chính phủ** và chỉ đạo của **Bộ Công An (C06)** phối hợp cùng Ngân hàng Nhà nước:\n\n"
                    "1. 🏛️ **Làm sạch 100% dữ liệu tài khoản:** Toàn bộ tài khoản ngân hàng Sen Hồng được đối soát trực tiếp với **Cơ sở Dữ liệu Quốc gia về Dân cư**, triệt tiêu tài khoản rác và tài khoản mở bằng giấy tờ giả mạo, bảo đảm nguyên tắc **Một danh tính số chính chủ duy nhất**.\n"
                    "2. 🆔 **Tích hợp Định danh VNeID Mức 2:** Khách hàng sở hữu tài khoản VNeID Mức 2 có thể mở tài khoản Sen Hồng online siêu tốc không cần chụp lại giấy tờ và được cấp ngay hạn mức giao dịch lên tới **500.000.000 VNĐ/ngày**.\n"
                    "3. 🪪 **Luật Căn cước số 26/2023/QH15:** Sen Hồng Bank hỗ trợ đầy đủ cả Thẻ CCCD gắn chip (12 số) và **Thẻ Căn cước mẫu mới** (có hiệu lực từ 01/07/2024)."
                ),
                "quick_replies": ["Xác thực CCCD / NFC", "Định danh VNeID", "Hạn mức tài khoản"],
                "suggested_action": {"label": "Xác thực Căn cước / VNeID", "route": "/profile/nfc-reader"}
            }

        # Điều khoản dịch vụ App & Bảo vệ dữ liệu cá nhân Nghị định 13
        if any(k in q_lower for k in ["điều khoản", "dieu khoan", "thỏa thuận", "thoa thuan", "nghị định 13", "nghi dinh 13", "nd 13", "bảo vệ dữ liệu", "bao ve du lieu", "xóa dữ liệu"]):
            return {
                "answer": (
                    "Dạ theo bản **Thỏa thuận Điều khoản & Điều kiện Sử dụng Dịch vụ Ngân hàng Số Sen Hồng** (Phiên bản 2.4) và **Nghị định 13/2023/NĐ-CP**:\n\n"
                    "1. 📋 **Điều kiện Khách hàng:** Cá nhân từ **đủ 15 tuổi trở lên**, có đầy đủ năng lực hành vi dân sự và sở hữu Căn cước/CCCD gắn chip chính chủ.\n"
                    "2. 🛡️ **Bảo vệ Dữ liệu Cá nhân (Nghị định 13):** Dữ liệu eKYC và sinh trắc học chỉ dùng để phục vụ giao dịch và phòng chống gian lận. Sen Hồng Bank **cam kết tuyệt đối không mua bán, không chia sẻ dữ liệu cho bên thứ ba** vì mục đích thương mại.\n"
                    "3. ⚖️ **Quyền của Khách hàng:** Có quyền xem, chỉnh sửa tại mục Hồ sơ cá nhân; hoặc yêu cầu xóa dữ liệu bằng văn bản gửi đến email pháp chế: `legal@senhongbank.vn`."
                ),
                "quick_replies": ["Xem toàn bộ điều khoản", "Bảo vệ dữ liệu NĐ 13", "Cài đặt bảo mật"],
                "suggested_action": {"label": "Xem toàn bộ Điều khoản", "route": "/auth/terms"}
            }

        # Chế tài mua bán tài khoản (Điều 291 BLHS) & Cảnh báo mạo danh Bộ Công An
        if any(k in q_lower for k in ["bán tài khoản", "ban tai khoan", "cho thuê tài khoản", "cho thue tai khoan", "cho mượn tài khoản", "điều 291", "mạo danh công an", "công an gọi điện"]):
            return {
                "answer": (
                    "Dạ Bộ Công An và Ngân hàng Số Sen Hồng đưa ra **Cảnh báo khẩn cấp và Chế tài pháp luật nghiêm khắc**:\n\n"
                    "1. ⚖️ **Chế tài Hình sự (Điều 291 BLHS & Nghị định 88/2019/NĐ-CP):**\n"
                    "  - Phạt tiền từ **40.000.000 VNĐ đến 100.000.000 VNĐ**; phạt tù từ **03 tháng đến 07 năm tù giam** đối với hành vi mua bán, cho thuê, cho mượn tài khoản ngân hàng.\n"
                    "  - Tài khoản vi phạm bị phong tỏa vĩnh viễn và bị đưa vào **Danh sách đen (Blacklist) liên ngân hàng của NHNN và Bộ Công An**.\n\n"
                    "2. 🚨 **Cảnh báo Lừa đảo Mạo danh Công an:**\n"
                    "  - Cơ quan Công an **tuyệt đối không làm việc, không lấy lời khai, không yêu cầu chuyển tiền qua điện thoại hay Zalo/Telegram**.\n"
                    "  - Tuyệt đối không chuyển tiền vào 'tài khoản an toàn' của bất kỳ ai và không cung cấp mã OTP/PIN cho người lạ."
                ),
                "quick_replies": ["Cài đặt bảo mật", "Khóa thẻ khẩn cấp", "Tổng đài 1900-SENHONG"],
                "suggested_action": {"label": "Cài đặt bảo mật", "route": "/settings/security"}
            }

        # Lãi suất ngoại tệ USD / Đô la Mỹ theo quy định của Ngân hàng Nhà nước
        if any(k in q_lower for k in ["usd", "đô la", "do la", "ngoại tệ", "ngoai te"]) and any(k in q_lower for k in ["lãi suất", "lai suat", "0%", "gửi tiết kiệm"]):
            return {
                "answer": (
                    "Dạ theo quy định chính thức của **Ngân hàng Nhà nước Việt Nam (NHNN)** về quản lý ngoại hối và chống đô la hóa nền kinh tế:\n\n"
                    "1. 📌 **Mức lãi suất áp dụng:** Lãi suất tiền gửi tiết kiệm bằng đồng Đô la Mỹ (**USD**) của cá nhân và tổ chức tại các ngân hàng thương mại Việt Nam áp dụng mức **0%/năm** trọn đời.\n\n"
                    "2. 💡 **Mục tiêu điều hành từ Ngân hàng Nhà nước:**\n"
                    "  - Ngăn chặn triệt để tình trạng găm giữ ngoại tệ (đô la hóa), chuyển hóa nguồn vốn ngoại tệ nhàn rỗi sang đồng Việt Nam (VND) để phục vụ sản xuất kinh doanh và phát triển kinh tế.\n"
                    "  - Ổn định tỷ giá hối đoái USD/VND và nâng cao vị thế, giá trị của đồng nội tệ Việt Nam.\n\n"
                    f"3. 🚀 **Giải pháp sinh lời tối ưu:** Thay vì cất giữ USD lãi suất 0%, Quý khách nên chuyển đổi sang **VND gửi Tiết Kiệm Online Sen Hồng** với mức lãi suất hấp dẫn lên tới **{rate_config.SAVINGS_RATES[12]:.1f}%/năm - {rate_config.SAVINGS_RATES[24]:.1f}%/năm**, mang lại lợi nhuận thực dương an toàn và bảo toàn vốn tuyệt đối ạ!"
                ),
                "quick_replies": ["Biểu lãi suất VND", "Bảng tỷ giá USD/VND", "Mở sổ tiết kiệm"],
                "suggested_action": {"label": "Xem tỷ giá ngoại tệ", "route": "/international-transfer"}
            }

        # Quản trị dòng tiền & Quỹ dự phòng khẩn cấp (Emergency Fund)
        if any(k in q_lower for k in ["dòng tiền", "dong tien", "quỹ dự phòng", "quy du phong", "vốn lưu động", "von luu dong"]):
            return {
                "answer": (
                    "Dạ theo chuẩn mực quản trị tài chính ngân hàng, Sen Hồng Bank xin tư vấn nguyên tắc **Quản trị dòng tiền** "
                    "và thiết lập **Quỹ dự phòng khẩn cấp (Emergency Fund)** như sau ạ:\n\n"
                    "1. 🛡️ **Quy mô Quỹ Dự Phòng Khẩn Cấp:**\n"
                    "  - Mỗi cá nhân và hộ kinh doanh cần chuẩn bị một quỹ dự phòng tương đương **3 đến 6 tháng chi tiêu cơ bản** (tiền ăn uống, nhà ở, học phí, chi phí kinh doanh thiết yếu).\n"
                    "  - **Mục đích:** Bảo vệ bạn và gia đình trước các biến cố bất ngờ (mất việc làm, ốm đau, gián đoạn kinh doanh) mà không phải vay mượn lãi cao hay bán tháo tài sản.\n\n"
                    "2. 💰 **Phương Thức Cất Giữ Thông Minh Tại Sen Hồng:**\n"
                    "  - Không nên để toàn bộ ở tiền mặt hoặc tài khoản thanh toán không kỳ hạn (chỉ 0.1% - 0.2%/năm).\n"
                    f"  - Nên chia nhỏ vào các sổ **Tiết kiệm Online kỳ hạn ngắn 1 - 3 tháng** (lãi suất **{rate_config.SAVINGS_RATES[1]:.1f}% - {rate_config.SAVINGS_RATES[3]:.1f}%/năm**).\n"
                    "  - Nhờ tính năng tất toán trực tuyến 24/7 trên App Sen Hồng, Quý khách vừa tối ưu sinh lời cho dòng tiền nhàn rỗi, vừa có thể rút tiền khẩn cấp về ví chỉ trong 3 giây khi có sự cố phát sinh ạ!"
                ),
                "quick_replies": ["Mở sổ tiết kiệm online", "Chiến lược tiết kiệm bậc thang", "Tổng quan tài chính"],
                "suggested_action": {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}
            }

        # Kim tự tháp tài chính & Phân bổ danh mục tài sản
        if any(k in q_lower for k in ["kim tự tháp", "kim tu thap", "phân bổ tài sản", "phan bo tai san", "danh mục đầu tư"]):
            return {
                "answer": (
                    "Dạ theo mô hình **Kim Tự Tháp Tài Chính Cá Nhân**, các chuyên gia tài chính Sen Hồng khuyên Quý khách "
                    "nên phân bổ nguồn vốn theo 3 tầng tài sản vững chắc để phòng ngừa rủi ro chu kỳ kinh tế:\n\n"
                    "1. 🏛️ **Tầng 1 - Nền tảng An toàn & Phòng thủ (Chiếm 50% - 60% tài sản):**\n"
                    "  - Quỹ dự phòng khẩn cấp 3 - 6 tháng chi phí cố định.\n"
                    f"  - Tiền gửi **Tiết kiệm Online Sen Hồng** kỳ hạn 6 - 24 tháng (lãi suất **{rate_config.SAVINGS_RATES[6]:.1f}% - {rate_config.SAVINGS_RATES[24]:.1f}%/năm**), tạo dòng tiền thụ động đều đặn và bảo toàn vốn 100% nhờ bảo hiểm tiền gửi.\n\n"
                    "2. 🎯 **Tầng 2 - Tích lũy Mục tiêu & Phòng hộ Lạm phát (Chiếm 20% - 30% tài sản):**\n"
                    "  - Tiết kiệm gửi góp tích lũy mua nhà, mua xe, học vấn.\n"
                    "  - Vàng nhẫn / Vàng miếng 9999 để phòng ngừa rủi ro địa chính trị và lạm phát toàn cầu.\n\n"
                    "3. 🚀 **Tầng 3 - Tăng trưởng & Cơ hội (Chiếm 10% - 15% tài sản):**\n"
                    "  - Cổ phiếu, quỹ mở, bất động sản đầu tư. Chỉ dùng vốn nhàn rỗi dài hạn từ 3 - 5 năm trở lên, tuyệt đối không dùng tiền vay mượn ngắn hạn.\n\n"
                    "Quý khách có thể bắt đầu xây dựng tầng móng tài chính an toàn ngay hôm nay với các gói tiết kiệm tích lũy tại Sen Hồng ạ!"
                ),
                "quick_replies": ["Mở sổ tiết kiệm ngay", "Kế hoạch tài chính 10 năm", "Biểu lãi suất"],
                "suggested_action": {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}
            }

        if any(k in q_lower for k in ["lai suat", "lãi suất", "lai xuat", "lãi xuất"]):
            is_asking_loan = any(k in q_lower for k in ["vay", "quick loan", "khoản vay", "khoan vay"])
            is_asking_savings = any(k in q_lower for k in ["tiết kiệm", "tiet kiem", "gửi tiền", "gui tien", "sổ", "so", "không kỳ hạn", "khong ky han", "rút trước hạn", "rut truoc han"])

            # 1. Nếu hỏi riêng về LÃI SUẤT VAY (Lãi vay ra lãi vay)
            if is_asking_loan and not is_asking_savings:
                return {
                    "answer": (
                        "Dạ, gói vay tiêu dùng tín chấp Quick Loan tại Sen Hồng áp dụng mức lãi suất cực kỳ ưu đãi:\n\n"
                        "- 📉 **Lãi suất vay:** Chỉ từ **1.2% - 1.5%/tháng** (tương đương 14.4%/năm) tính trên **dư nợ giảm dần**.\n"
                        "- 📉 **Cách tính lãi:** Tiền lãi tháng sau luôn thấp hơn tháng trước do chỉ tính trên số dư nợ gốc thực tế còn lại.\n"
                        "- 🆓 **Phí tất toán trước hạn:** **0 VNĐ (Miễn phí 100%)**, Quý khách có thể trả hết nợ bất kỳ lúc nào mà không bị phạt.\n"
                        "- 🆓 **Phí thẩm định hồ sơ:** **0 VNĐ (Miễn phí 100%)** trực tuyến.\n"
                        "- ⚡ **Hạn mức vay:** Từ 5.000.000 VNĐ đến 50.000.000 VNĐ, kỳ hạn linh hoạt 3 - 24 tháng."
                    ),
                    "quick_replies": ["Bảng lịch trả nợ vay", "Đăng ký vay ngay", "Hạn mức vay Quick Loan"],
                    "suggested_action": {"label": "Vay nhanh", "route": "/bills/quick-loan"},
                    "sources": ["Quy chế vay tiêu dùng tín chấp Quick Loan", "Biểu lãi suất cho vay Sen Hồng Bank"]
                }

            # 2. Nếu hỏi riêng về LÃI SUẤT TIẾT KIỆM (Lãi tiết kiệm ra lãi tiết kiệm) — SSOT rate_config
            term_prefix = ""
            if "1 tháng" in q_lower or "1 thang" in q_lower:
                term_prefix = f"Lãi suất tiền gửi tiết kiệm online kỳ hạn **1 tháng** hiện nay là **{rate_config.SAVINGS_RATES[1]:.1f}%/năm**.\n\n"
            elif "3 tháng" in q_lower or "3 thang" in q_lower:
                term_prefix = f"Lãi suất tiền gửi tiết kiệm online kỳ hạn **3 tháng** hiện nay là **{rate_config.SAVINGS_RATES[3]:.1f}%/năm**.\n\n"
            elif "6 tháng" in q_lower or "6 thang" in q_lower:
                term_prefix = f"Lãi suất tiền gửi tiết kiệm online kỳ hạn **6 tháng** hiện nay là **{rate_config.SAVINGS_RATES[6]:.1f}%/năm**.\n\n"
            elif "12 tháng" in q_lower or "12 thang" in q_lower:
                term_prefix = f"Lãi suất tiền gửi tiết kiệm online kỳ hạn **12 tháng** hiện nay là **{rate_config.SAVINGS_RATES[12]:.1f}%/năm**.\n\n"
            elif "24 tháng" in q_lower or "24 thang" in q_lower or "36 tháng" in q_lower:
                term_prefix = f"Lãi suất tiền gửi tiết kiệm online kỳ hạn **24 - 36 tháng** hiện nay là **{rate_config.SAVINGS_RATES[24]:.1f}%/năm**.\n\n"
            elif any(k in q_lower for k in ["không kỳ hạn", "khong ky han", "rút trước hạn", "rut truoc han"]):
                term_prefix = f"Lãi suất tiền gửi **không kỳ hạn** hoặc rút trước hạn là **{rate_config.CASA_RATE:.1f}%/năm**.\n\n"

            if is_asking_savings or term_prefix or not is_asking_loan:
                return {
                    "answer": (
                        f"Dạ, {term_prefix}"
                        "Biểu lãi suất tiền gửi tiết kiệm online mới nhất tại Ngân hàng Số Sen Hồng như sau ạ:\n\n"
                        f"- 💎 **Kỳ hạn 1 tháng:** **{rate_config.SAVINGS_RATES[1]:.1f}%/năm**\n"
                        f"- 💎 **Kỳ hạn 3 tháng:** **{rate_config.SAVINGS_RATES[3]:.1f}%/năm**\n"
                        f"- 💎 **Kỳ hạn 6 tháng:** **{rate_config.SAVINGS_RATES[6]:.1f}%/năm**\n"
                        f"- 💎 **Kỳ hạn 9 tháng:** **{rate_config.SAVINGS_RATES[9]:.1f}%/năm**\n"
                        f"- 💎 **Kỳ hạn 12 tháng:** **{rate_config.SAVINGS_RATES[12]:.1f}%/năm**\n"
                        f"- 💎 **Kỳ hạn 18 tháng:** **{rate_config.SAVINGS_RATES[18]:.1f}%/năm**\n"
                        f"- 💎 **Kỳ hạn 24 - 36 tháng:** **{rate_config.SAVINGS_RATES[24]:.1f}%/năm** (mức lãi suất cao nhất)\n"
                        f"- 💎 **Tiền gửi không kỳ hạn / rút trước hạn:** **{rate_config.CASA_RATE:.1f}%/năm**.\n\n"
                        "🛡️ **Đặc quyền bảo toàn tiền lãi:** Theo Thông tư 04/2022/TT-NHNN, khi Quý khách rút gốc một phần trước hạn, phần tiền còn lại vẫn được bảo toàn 100% mức lãi suất có kỳ hạn ban đầu!\n\n"
                        "Quý khách có thể mở sổ tiết kiệm online 24/7 chỉ từ **1.000.000 VNĐ** ngay trên App ạ."
                    ),
                    "quick_replies": ["Mở sổ tiết kiệm ngay", "Bảo toàn lãi suất TT 04", "Tiết kiệm tích lũy"],
                    "suggested_action": {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"},
                    "sources": ["Biểu lãi suất tiết kiệm Sen Hồng", "Thông tư 04/2022/TT-NHNN"]
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

        # Thẻ ảo quốc tế Visa Platinum Virtual & Biểu phí thẻ
        if any(k in q_lower for k in ["visa", "the ao", "thẻ ảo", "platinum", "the tin dung", "thẻ tín dụng", "the visa", "thẻ visa"]):
            return {
                "answer": (
                    "Dạ, thông tin về **Thẻ ảo quốc tế Visa Platinum Virtual** tại Sen Hồng Bank:\n\n"
                    "- 💳 **Phí phát hành & Phí thường niên:** **Miễn phí 100% trọn đời**.\n"
                    "- ⏱️ **Thời gian phát hành:** Mở thẻ trực tuyến tức thì trong **30 giây**, sẵn sàng thanh toán ngay.\n"
                    "- 🛡️ **Bảo mật tối tân:** Mã CVV động tự động thay đổi định kỳ, bảo vệ an toàn tuyệt đối khi mua sắm online.\n"
                    "- 🌍 **Phạm vi sử dụng:** Thanh toán toàn cầu tại mọi website, dịch vụ quốc tế (Netflix, Spotify, Apple, Google, Facebook Ads...) và hỗ trợ liên kết Apple Pay / Google Wallet.\n"
                    "- 💰 **Hạn mức thanh toán:** Lên đến **100.000.000 VNĐ/ngày** sau khi định danh eKYC Cấp 2."
                ),
                "quick_replies": ["Mở thẻ Visa ngay", "Quản lý thẻ", "Biểu phí & Hạn mức"],
                "suggested_action": {"label": "Mở thẻ Visa Platinum", "route": "/cards"}
            }

        # Biểu phí chung & Hạn mức chung
        if any(k in q_lower for k in ["biểu phí", "bieu phi", "bảng phí", "bang phi", "phí dịch vụ", "phi dich vu", "mất phí không", "mat phi khong"]):
            return {
                "answer": (
                    "Dạ, Ngân hàng Số Sen Hồng áp dụng chính sách **Miễn phí toàn diện (Zero-Fee Banking)**:\n\n"
                    "- 🆓 **Chuyển tiền Napas 24/7:** Miễn phí 100% trọn đời cho mọi giao dịch.\n"
                    "- 🆓 **Nạp tiền vào ví:** Miễn phí 100% từ tài khoản ngân hàng liên kết.\n"
                    "- 🆓 **Rút tiền về ngân hàng & Rút ATM QR:** Miễn phí 100%.\n"
                    "- 🆓 **Phát hành & Phí thường niên Thẻ ảo Visa Platinum:** Miễn phí 100%.\n"
                    "- 🆓 **Thanh toán hóa đơn điện, nước, nạp điện thoại:** Miễn phí 100%.\n"
                    "- 🆓 **Phí thẩm định & Tất toán khoản vay Quick Loan trước hạn:** Miễn phí 100%."
                ),
                "quick_replies": ["Chuyển tiền nhanh", "Mở thẻ Visa", "Vay Quick Loan"],
                "suggested_action": {"label": "Xem biểu phí chi tiết", "route": "/settings"}
            }

        if not context or "Không tìm thấy" in context:
            return {
                "answer": "Dạ hiện tại hệ thống Trợ lý Tài chính đang đồng bộ dữ liệu. Quý khách vui lòng liên hệ hotline 1900-SENHONG (1900 736 466) để được hỗ trợ chuyên sâu 24/7 ạ.",
                "quick_replies": ["Xem biểu phí dịch vụ", "Lãi suất tiết kiệm", "Chuyển tiền ngay"],
                "suggested_action": None
            }

        # 2. Cơ chế trích xuất thông minh theo khối Heading hoặc cụm Hỏi/Đáp (Bảo tồn toàn vẹn ngữ cảnh)
        raw_lines = [l.strip() for l in context.splitlines() if l.strip()]
        candidate_blocks = []
        curr_block = []

        for line in raw_lines:
            if line.startswith("--- Tài liệu:") or line.startswith("passage:"):
                continue
            is_new_block = (
                line.startswith("## ") or 
                line.startswith("### ") or 
                line.startswith("- **Hỏi:")
            )
            if is_new_block and curr_block:
                candidate_blocks.append("\n".join(curr_block))
                curr_block = [line]
            else:
                curr_block.append(line)
        if curr_block:
            candidate_blocks.append("\n".join(curr_block))

        # Chấm điểm mức độ liên quan của từng khối với câu hỏi
        stop_words = {
            "cho", "tôi", "làm", "sao", "thế", "nào", "như", "được", "không", "ứng", "dụng", 
            "hướng", "dẫn", "cách", "xem", "năm", "thời", "tiết", "ngày", "ở", "có", "bao", 
            "nhiêu", "của", "và", "là", "thì", "mà", "với", "các", "những", "này", "đó", "ạ", "dạ"
        }
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

        # Kiểm tra xem đây có phải lần fallback liên tiếp (Nguyên tắc 7: Fallback thông minh)
        is_consecutive_fallback = False
        if history:
            last_bot_msg = next((h.content.lower() for h in reversed(history) if h.role in ("assistant", "bot")), "")
            fallback_indicators = ["chưa tìm thấy thông tin", "chưa có thông tin", "mô tả chi tiết hơn", "diễn đạt rõ hơn", "tiện ích trên ứng dụng"]
            if any(ind in last_bot_msg for ind in fallback_indicators):
                is_consecutive_fallback = True

        if best_block and best_score >= 2:
            clean_block = re.sub(r'^[#*\-\s]+', '', best_block).strip()
            if len(clean_block) > 1200:
                clean_block = clean_block[:1200].rsplit(' ', 1)[0] + "..."
            answer = (
                f"Dạ, Sen Hồng Bank xin cung cấp thông tin chi tiết về nội dung Quý khách quan tâm như sau ạ:\n\n"
                f"{clean_block}\n\n"
                f"👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
            )
            
            # Gợi ý thông minh và nút hành động theo ngữ cảnh trích xuất
            blk_low = clean_block.lower()
            if any(k in blk_low for k in ["cic", "nhóm nợ", "nợ xấu", "thế chấp"]):
                quick_replies = ["Vay thế chấp BĐS", "Tra cứu CIC cá nhân", "Xóa lịch sử nợ xấu"]
                suggested_action = {"label": "Vay thế chấp", "route": "/bills/quick-loan"}
            elif any(k in blk_low for k in ["chứng chỉ tiền gửi", "bảo hiểm tiền gửi", "div"]):
                quick_replies = ["Chứng chỉ tiền gửi CD", "Bảo hiểm tiền gửi DIV", "Lãi suất tiết kiệm"]
                suggested_action = {"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}
            elif any(k in blk_low for k in ["swift", "ngoại tệ", "du học", "kiều hối"]):
                quick_replies = ["Mã SWIFT SENHVNVX", "Chuyển tiền du học", "Nhận kiều hối 0đ"]
                suggested_action = {"label": "Chuyển tiền quốc tế", "route": "/international-transfer"}
            elif any(k in blk_low for k in ["cashback", "trả góp 0%", "miễn lãi 55"]):
                quick_replies = ["Thẻ hoàn tiền Cashback", "Trả góp 0% lãi suất", "Biểu phí & Hạn mức"]
                suggested_action = {"label": "Quản lý thẻ", "route": "/cards"}
            elif any(k in blk_low for k in ["etax", "thuế", "phạt nguội"]):
                quick_replies = ["Nộp thuế eTax Mobile", "Nộp phạt nguội C08", "Hóa đơn điện nước"]
                suggested_action = {"label": "Nộp thuế & Dịch vụ công", "route": "/bills"}
            elif any(k in blk_low for k in ["crm", "smart lounge", "nạp tiền mặt"]):
                quick_replies = ["Cây nạp tiền CRM 24/7", "Kiosk in thẻ Smart Lounge", "Mạng lưới ATM"]
                suggested_action = {"label": "Điểm giao dịch CRM", "route": "/deposit"}
            elif any(k in blk_low for k in ["priority", "loungekey", "phòng chờ"]):
                quick_replies = ["Hội viên Sen Hong Priority", "Phòng chờ LoungeKey", "Private Banker"]
                suggested_action = {"label": "Khách hàng ưu tiên", "route": "/profile"}
            elif any(k in blk_low for k in ["lừa đảo", "khẩn cấp", "khóa thẻ"]):
                quick_replies = ["Khóa thẻ khẩn cấp", "Quy định QĐ 2345", "Cảnh báo A05"]
                suggested_action = {"label": "Khóa tài khoản khẩn cấp", "route": "/settings/security"}
            else:
                quick_replies = ["Xem biểu phí dịch vụ", "Lãi suất tiết kiệm", "Chuyển tiền ngay"]
                suggested_action = None
        else:
            if is_consecutive_fallback:
                # Lần 2 liên tiếp không giải quyết được -> Đề xuất chuyển sang người thật / hotline
                answer = (
                    "Dạ, em nhận thấy yêu cầu của Quý khách cần được hỗ trợ chuyên sâu hơn từ bộ phận nghiệp vụ. "
                    "Quý khách vui lòng liên hệ tổng đài hỗ trợ 24/7 **1900-SENHONG** (1900 736 466) "
                    "hoặc gửi yêu cầu tra soát trực tiếp để chuyên viên ngân hàng hỗ trợ giải quyết ngay cho Quý khách ạ!"
                )
                quick_replies = ["Gửi yêu cầu tra soát", "Hotline 1900-SENHONG", "Về trang chủ"]
                suggested_action = {"label": "Hỗ trợ tra soát", "route": "/support/help-center"}
            else:
                # Lần 1: Không giục gọi hotline ngay, đưa 2-3 gợi ý gần nhất
                answer = (
                    "Dạ, em chưa tìm thấy thông tin chính xác cho yêu cầu này của Quý khách trong tài liệu hiện tại. "
                    "Quý khách có thể diễn đạt rõ hơn giúp em, hoặc tham khảo nhanh một số dịch vụ phổ biến bên dưới ạ:"
                )
                quick_replies = ["Lãi suất tiết kiệm online", "Vay tiêu dùng Quick Loan", "Biểu phí & Hạn mức", "Quên mã PIN"]
                suggested_action = None

        return {
            "answer": answer,
            "quick_replies": quick_replies,
            "suggested_action": suggested_action
        }

    def _call_llm_with_failover(
        self, 
        messages: List[Dict[str, str]], 
        fallback_context: Optional[str] = None, 
        user_question: str = "",
        history: Optional[List[MessageItem]] = None
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
        return self._extractive_fallback_answer(fallback_context, user_question, history=history), True

    def query(self, user_question: str, history: Optional[List[MessageItem]] = None, user_id: Optional[str] = None) -> Dict[str, Any]:
        """
        Xử lý câu hỏi với Semantic Cache, Hybrid Search RRF và Grounded LLM
        (API chuẩn tương thích hoàn toàn với đoạn code mẫu)
        """
        start_time = time.time()
        model = self._get_embed_model()

        # Nếu là câu hỏi đa lượt có đại từ thay thế ("nó", "thẻ này", "gói này"), bổ sung ngữ cảnh lượt trước
        search_query = user_question
        search_query = normalize_vietnamese_query(user_question)
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

        # 3. Hybrid Search lấy Top Parent Documents
        # Thu hẹp không gian tìm kiếm trước, rồi mới tìm: suy domain từ câu hỏi
        # (hàm thuần detect_query_topic, <1ms) rồi lọc metadata trong SQL.
        # Topic GENERAL_ACCOUNT (câu hỏi mơ hồ/đa chủ đề) → không lọc để tránh mất kết quả.
        rag_domain = detect_query_topic(search_query)
        effective_domain = rag_domain if rag_domain != "GENERAL_ACCOUNT" else None
        combined_context, sources = self._hybrid_search_rrf(
            search_query, query_vec, top_k=settings.TOP_K, domain=effective_domain
        )
        if not sources and effective_domain is not None:
            # Fallback: lọc domain quá chặt với câu hỏi đa chủ đề → thử lại không lọc
            logger.info("Domain filter '%s' returned empty, retrying without filter.", effective_domain)
            combined_context, sources = self._hybrid_search_rrf(
                search_query, query_vec, top_k=settings.TOP_K, domain=None
            )

        # 3b. Tự động tích hợp dữ liệu Live Promotions & Vouchers từ notification-service khi khách hỏi về ưu đãi/mã giảm giá
        q_lower_check = search_query.lower()
        is_promo_query = any(k in q_lower_check for k in [
            "voucher", "khuyen mai", "khuyến mại", "khuyến mãi", "uu dai", "ưu đãi", "giam gia", "giảm giá",
            "ma giam gia", "mã giảm giá", "ma qua tang", "mã quà tặng", "xinchao50", "freego", "friend50k",
            "welcome100k", "senbank9", "senpoint", "sen point", "tich diem", "tích điểm", "hoan tien", "hoàn tiền"
        ])
        if is_promo_query:
            try:
                live_promos = self._fetch_active_promotions()
                if live_promos:
                    promo_lines = ["DANH SÁCH MÃ VOUCHER LIVE ĐANG CÓ HIỆU LỰC TRÊN HỆ THỐNG SEN HỒNG:"]
                    for p in live_promos:
                        c = p.get("code")
                        t = p.get("title")
                        val = p.get("discountValue", 0)
                        min_ord = p.get("minOrderAmount", 0)
                        val_str = f"{val:,.0f}đ".replace(",", ".")
                        min_str = f"{min_ord:,.0f}đ".replace(",", ".") if min_ord else "0đ"
                        promo_lines.append(f"- Mã `{c}`: {t} (Giá trị giảm: {val_str}, Đơn tối thiểu: {min_str}, Trạng thái: Đang hoạt động)")
                    live_promo_block = "\n".join(promo_lines)
                    combined_context = f"{live_promo_block}\n\n{combined_context}"
                    if "Kho Voucher & Ưu Đãi Đối Tác" not in sources:
                        sources.append("Kho Voucher & Ưu Đãi Đối Tác")
            except Exception as e:
                logger.warning("Could not enrich live promotions: %s", e)

        # 3c. Tự động tích hợp Động cơ Tính toán Tài chính Siêu Chuẩn Xác (Robo-Advisor Financial Engine)
        user_wallet = self._fetch_user_wallet_balance(user_id) if user_id else None
        self._current_user_wallet = user_wallet
        financial_analysis = generate_comprehensive_financial_analysis(search_query, user_wallet=user_wallet)
        if financial_analysis:
            base_amt = financial_analysis['fmt_base_amount']
            term_y = financial_analysis['term_years']
            s_calc = financial_analysis['savings_calc']
            l_calc = financial_analysis['loan_calc']
            t_data = s_calc['target_data']
            y1_data = s_calc['yearly_breakdown'][0]

            fin_lines = [
                "=== DỮ LIỆU TÍNH TOÁN TÀI CHÍNH SIÊU CHUẨN XÁC TỪ CORE BANKING (BẮT BUỘC SỬ DỤNG CHÍNH XÁC CÁC SỐ LIỆU NÀY) ===",
                f"- Số tiền vốn/gốc được đưa vào tính toán: {base_amt} (Nguồn: {financial_analysis['amount_source']})",
                f"- Số dư ví khả dụng thực tế của khách hàng: {financial_analysis['fmt_wallet_balance']}",
                f"- Gửi Tiết Kiệm Online Lãi Kép ({term_y} năm, lãi suất {s_calc['rate_annual']:.1f}%/năm tự động tái tục cả gốc và lãi):",
                f"  * Tiền lãi sau 1 năm: {y1_data['fmt_interest_savings']} (Tổng nhận: {y1_data['fmt_total_savings']})",
                f"  * Tiền lãi sau {term_y} năm: {t_data['fmt_interest_savings']} (Tổng nhận: {t_data['fmt_total_savings']})",
                f"  * So sánh với để tiền trong ví không kỳ hạn ({rate_config.CASA_RATE:.1f}%/năm): Sau {term_y} năm chỉ nhận được {t_data['fmt_interest_casa']}. Gửi tiết kiệm lãi kép sinh lời vượt trội hơn: +{t_data['fmt_difference']}!",
                f"  * Bảng tăng trưởng chi tiết theo thời gian:",
                s_calc['markdown_table'],
                f"- Khoản vay tiêu dùng Quick Loan tương ứng ({base_amt}, kỳ hạn 12 tháng, {rate_config.DEFAULT_LOAN_MONTHLY_RATE:.1f}%/tháng dư nợ giảm dần):",
                f"  * Tiền gốc trả hàng tháng: {l_calc['fmt_monthly_principal']}",
                f"  * Tiền trả tháng đầu (tháng cao nhất): {l_calc['fmt_first_month_payment']}",
                f"  * Tiền trả tháng cuối (tháng thấp nhất): {l_calc['fmt_last_month_payment']}",
                f"  * Tổng tiền lãi toàn kỳ 12 tháng: {l_calc['fmt_total_interest']}",
                f"  * Quy định: Giải ngân trong 1 phút về ví, miễn phí phạt trả nợ trước hạn 100%.",
                f"- Lời khuyên tài chính thông minh (Robo-Advisor Insight):",
                f"  * Chiến lược tiết kiệm bậc thang: Chia nhỏ thành các sổ 6 tháng ({rate_config.SAVINGS_RATES[6]:.1f}%/năm) và 12-24 tháng ({rate_config.SAVINGS_RATES[12]:.1f}% - {rate_config.SAVINGS_RATES[24]:.1f}%/năm) để linh hoạt dòng tiền.",
                f"  * Theo Thông tư 04/2022/TT-NHNN: Rút một phần tiền gốc trước hạn vẫn giữ nguyên lãi suất có kỳ hạn cho phần tiền còn lại.",
                f"  * Đối chiếu vay vs tiết kiệm: Khi cần vốn ngắn hạn gấp, có thể vay Quick Loan để không phải phá sổ tiết kiệm dài hạn đang sinh lời cao.",
                "=========================================================================================="
            ]
            fin_block = "\n".join(fin_lines)
            combined_context = f"{fin_block}\n\n{combined_context}"
            if "Động cơ Tính toán Tài chính Sen Hồng" not in sources:
                sources.append("Động cơ Tính toán Tài chính Sen Hồng")

        # Lưu ngữ cảnh cuối cùng phục vụ Grounding Check ở Layer Deep Thinking
        self._last_rag_context = combined_context

        # 4. Prompt hệ thống ngân hàng chuyên nghiệp & bảo mật (Thiết kế chống lan man - Đúng trọng tâm)
        system_prompt = f"""
Bạn là Trợ lý Tài chính AI Thông minh 24/7 của Ngân hàng Số Sen Hồng (Sen Hồng Core Banking).

VAI TRÒ & PHONG CÁCH:
- Xưng hô "em" và gọi khách hàng là "quý khách" lịch sự, chu đáo, chuẩn mực dịch vụ ngân hàng số cao cấp.
- NGUYÊN TẮC: CHUẨN XÁC, NGẮN GỌN, ĐÚNG TRỌNG TÂM, TUYỆT ĐỐI KHÔNG LAN MAN:
  * Vào thẳng trọng tâm câu trả lời trong 1-2 câu đầu tiên, không chào hỏi dài dòng.
  * Trình bày súc tích (khoảng 3-6 gạch đầu dòng ngắn gọn), đi thẳng vào giải pháp hoặc con số cốt lõi mà khách hàng cần.
  * Luôn in đậm các số liệu quan trọng bằng cú pháp markdown `**...**` (ví dụ: `**miễn phí 100%**`, `**5.6%/năm**`, `**50.000đ**`, `**10 triệu đồng**`, `**1.2%/tháng**`, `**1 đến 3 giây**`) để ứng dụng di động tự động làm nổi bật sắc nét cho khách hàng.
  * Khi hướng dẫn thao tác, đánh số các bước mạch lạc: `1. **Bước 1:** ...`, `2. **Bước 2:** ...` để khách hàng dễ làm theo.
- CẦU NỐI DẪN HƯỚNG GỢI Ý (GỢI Ý SANG CÂU TRẢ LỜI TIẾP THEO):
  * Cuối mỗi câu trả lời, luôn có câu dẫn tự nhiên hướng khách hàng bấm chọn các câu hỏi gợi ý bên dưới để xem tiếp câu trả lời chi tiết:
    "👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"

NGHIỆP VỤ & NGUYÊN TẮC BẢO MẬT:
1. QUY TẮC CỐT LÕI VỀ TÍNH CHÍNH XÁC (ANTI-HALLUCINATION):
   - Bạn CHỈ ĐƯỢC PHÉP trả lời dựa trên NGỮ CẢNH TÀI LIỆU CHÍNH THỐNG và DỮ LIỆU TÍNH TOÁN được cung cấp bên dưới.
   - Tuyệt đối KHÔNG tự phỏng đoán, suy diễn hoặc bịa đặt lãi suất, biểu phí, hạn mức, hay quy chế ngân hàng.
   - Bịa đặt lãi suất ngân hàng là vi phạm pháp luật và gây thiệt hại nghiêm trọng. Nếu tài liệu không có thông tin hoặc câu hỏi ngoài phạm vi, hãy thẳng thắn thông báo: "Dạ hiện tại Sen Hồng chưa có thông tin chính thức về [vấn đề] trong hệ sinh thái" và đưa ra các gợi ý dịch vụ tài chính có sẵn.

2. QUY TẮC HỎI LẠI KHI THIẾU DỮ LIỆU (SLOT FILLING):
   - Nếu khách hàng hỏi thiếu thông tin quan trọng (ví dụ: muốn mở sổ tiết kiệm nhưng chưa rõ số tiền hoặc kỳ hạn), hãy lịch sự hỏi lại để khách hàng làm rõ số tiền hoặc kỳ hạn dự kiến, không tự phỏng đoán số tiền hay kỳ hạn của khách.

3. NGUYÊN TẮC CỐT LÕI: ĐÚNG TRỌNG TÂM - VAY RA VAY, LÃI RA LÃI (ANTI-RAMBLING PRINCIPLE):
   - HỎI VAY -> TRẢ LỜI 100% VỀ VAY:
     * Nếu khách hàng hỏi về VAY (Gói vay tiêu dùng Quick Loan, điều kiện vay, thủ tục vay, hạn mức 5 - 50 triệu, giải ngân 1 phút, hồ sơ vay chỉ cần CCCD chip 0đ bảng lương, tính tiền trả góp khoản vay): Tập trung trả lời 100% trực diện về Vay.
     * TUYỆT ĐỐI KHÔNG chèn thông tin gửi tiết kiệm, KHÔNG khuyên mở sổ tiết kiệm, KHÔNG lan man sang dịch vụ khác. Nút hành động BẮT BUỘC là {{"label": "Vay nhanh", "route": "/bills/quick-loan"}} hoặc {{"label": "Lịch trả nợ vay", "route": "/loan/schedule"}}.
   - HỎI TIẾT KIỆM -> TRẢ LỜI 100% VỀ TIẾT KIỆM:
     * Nếu khách hàng hỏi về TIẾT KIỆM (Gửi tiết kiệm online, biểu lãi suất tiết kiệm từ {rate_config.SAVINGS_RATES[1]:.1f}% đến {rate_config.SAVINGS_RATES[24]:.1f}%/năm, tiền lãi gửi tiết kiệm, kỳ hạn 1 - 36 tháng, bảo toàn lãi khi rút một phần theo Thông tư 04/2022/TT-NHNN): Tập trung trả lời 100% trực diện về Tiết kiệm.
     * TUYỆT ĐỐI KHÔNG chèn thông tin vay nợ, KHÔNG đối chiếu khoản vay Quick Loan. Nút hành động BẮT BUỘC là {{"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}}.
   - HỎI LÃI SUẤT VAY -> TRẢ LỜI LÃI SUẤT VAY:
     * Lãi suất vay Quick Loan ưu đãi từ {rate_config.LOAN_RATE_RANGE_TEXT}. 0 VNĐ phí phạt tất toán trước hạn. Giải thích rõ tiền lãi giảm dần theo thời gian. Không nói lan man sang lãi suất tiết kiệm.
   - HỎI LÃI SUẤT TIẾT KIỆM -> TRẢ LỜI LÃI SUẤT TIẾT KIỆM:
     * Biểu lãi suất tiết kiệm có kỳ hạn từ {rate_config.SAVINGS_RATES[1]:.1f}% đến {rate_config.SAVINGS_RATES[24]:.1f}%/năm (12 tháng: {rate_config.SAVINGS_RATES[12]:.1f}%, 24-36 tháng: {rate_config.SAVINGS_RATES[24]:.1f}%). Tiền gửi không kỳ hạn/rút trước hạn: {rate_config.CASA_RATE:.1f}%/năm. Không nói lan man sang lãi suất vay.
   - CHỈ KHI KHÁCH HỎI SO SÁNH (ví dụ: "Nên gửi tiết kiệm hay vay?", "So sánh lãi suất vay và tiết kiệm", hoặc yêu cầu phân bổ danh mục tài chính toàn diện) thì mới trình bày song song cả hai.
   - Khi có DỮ LIỆU TÍNH TOÁN TÀI CHÍNH, BẮT BUỘC sử dụng đúng các con số này, không làm tròn sai lệch.
   - Khi khách gặp sự cố giao dịch (bị trừ tiền nhưng chưa nhận): Luôn trấn an trước tiên: **"Tiền của Quý khách luôn được bảo toàn 100% trong hệ thống sổ cái kép Ledger của ngân hàng và không bao giờ bị thất thoát."**
   - Khi khách bị khóa mã PIN sau 3 lần nhập sai hoặc khóa mật khẩu sau 5 lần: Hướng dẫn tự mở khóa và đặt mã PIN mới ngay trên App bằng eKYC khuôn mặt + OTP mà **KHÔNG CẦN RA QUẦY**, điều hướng tới `/auth/forgot-pin`.
   - Về thẻ ảo Visa Platinum Virtual: Phát hành ngay 30s, miễn phí phát hành và thường niên 100%; bảo mật CVV động; thanh toán online toàn cầu; phí ngoại tệ **1.5%**.

4. TUYỆT ĐỐI BẢO MẬT:
   - Tuyệt đối không bao giờ hỏi hoặc yêu cầu khách cung cấp mã OTP, mật khẩu hay mã PIN.

5. VÍ DỤ MINH HỌA (FEW-SHOT EXAMPLES):
   - Ví dụ 1 (Hỏi lại khi thiếu thông tin):
     Khách: "Tôi muốn mở sổ tiết kiệm"
     Trả lời: "Dạ Sen Hồng rất vui được đồng hành cùng Quý khách! Để em tính toán mức sinh lời tối ưu nhất, Quý khách dự định gửi số tiền bao nhiêu và trong kỳ hạn khoảng bao lâu ạ (ví dụ: 10 triệu, 50 triệu kỳ hạn 6 tháng hay 12 tháng)?"
     Quick Replies: ["Gửi 10 triệu 6 tháng", "Gửi 50 triệu 12 tháng", "Biểu lãi suất tiết kiệm"]
     Action: {{"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}}

   - Ví dụ 2 (Hỏi vay - Trả lời 100% về vay, không nói lan man tiết kiệm):
     Khách: "Tôi muốn vay 30 triệu thì mỗi tháng trả bao nhiêu?"
     Trả lời: "Dạ với khoản vay tiêu dùng **30.000.000 VNĐ** (Kỳ hạn 12 tháng) tại Sen Hồng Bank:\n- **Lãi suất:** Từ **1.2%/tháng** tính trên **dư nợ giảm dần**.\n- **Tiền gốc cố định hàng tháng:** **2.500.000 VNĐ/tháng**.\n- **Tiền trả tháng đầu tiên (cao nhất):** **2.860.000 VNĐ** (gốc 2.500.000đ + lãi 360.000đ).\n- **Tiền trả tháng cuối cùng (thấp nhất):** **2.530.000 VNĐ**.\n- **Tổng tiền lãi cả kỳ 12 tháng:** **2.340.000 VNĐ**.\n- **Phí phạt tất toán trước hạn:** **0 VNĐ (Miễn phí 100%)**.\n- **Thủ tục:** 100% online chỉ cần CCCD gắn chip, **hoàn toàn không cần nộp bảng lương**, giải ngân vào ví sau **1 phút** ạ!"
     Quick Replies: ["Đăng ký vay ngay", "Bảng lịch trả nợ vay", "Hạn mức vay Quick Loan"]
     Action: {{"label": "Vay nhanh", "route": "/bills/quick-loan"}}

   - Ví dụ 3 (Hỏi tiết kiệm - Trả lời 100% về tiết kiệm, không nói lan man vay nợ):
     Khách: "Có 50 triệu gửi 10 năm được bao nhiêu tiền lãi?"
     Trả lời: "Dạ với số tiền **50.000.000 VNĐ**, nếu Quý khách gửi tiết kiệm online kỳ hạn 12 tháng tự động tái tục cả gốc và lãi (**5.6%/năm**), sau **10 năm**:\n- Tiền lãi lũy kế sinh lời: **+36.222.053 VNĐ**.\n- Tổng tài sản Quý khách nhận về: **86.222.053 VNĐ**.\n\nSo với việc để tiền trong tài khoản thanh toán chỉ được **1.009.040 VNĐ** (0.2%/năm), gửi tiết kiệm online giúp Quý khách sinh lời vượt trội hơn **+35.213.013 VNĐ**!\n\nNếu Quý khách cần hỗ trợ thêm thông tin nào, cứ nhắn em nhé ạ!"
     Quick Replies: ["Chiến lược tiết kiệm bậc thang", "Biểu lãi suất tiết kiệm", "Mở sổ tiết kiệm ngay"]
     Action: {{"label": "Mở sổ tiết kiệm ngay", "route": "/bills/savings"}}

6. ĐỊNH HƯỚNG ĐIỀU HƯỚNG THÔNG MINH (suggested_action):
   - Quên mã PIN, lấy lại mã PIN -> {{"label": "Lấy lại mã PIN", "route": "/auth/forgot-pin"}}
   - Quên mật khẩu -> {{"label": "Quên mật khẩu", "route": "/auth/forgot-password"}}
   - Đổi mã PIN -> {{"label": "Đổi mã PIN", "route": "/settings/change-pin"}}
   - Liên kết ngân hàng -> {{"label": "Thẻ & Ngân hàng liên kết", "route": "/bank-cards"}}
   - Chuyển tiền -> {{"label": "Chuyển tiền ngay", "route": "/transfer"}}
   - Nạp tiền -> {{"label": "Nạp tiền vào ví", "route": "/deposit"}}
   - Rút tiền -> {{"label": "Rút tiền về ngân hàng", "route": "/withdraw"}}
   - Vay nhanh -> {{"label": "Vay nhanh", "route": "/bills/quick-loan"}}
   - Lịch trả nợ vay -> {{"label": "Lịch trả nợ vay", "route": "/loan/schedule"}}
   - Tiết kiệm online -> {{"label": "Mở sổ tiết kiệm", "route": "/bills/savings"}}
   - Kho ưu đãi -> {{"label": "Kho Voucher & Ưu đãi", "route": "/promotions"}}
   - Thẻ Visa -> {{"label": "Quản lý thẻ", "route": "/cards"}}
   - Khiếu nại, tra soát -> {{"label": "Hỗ trợ tra soát", "route": "/support/help-center"}}

7. ĐỊNH DẠNG ĐẦU RA: Trả về JSON thuần túy (không bọc mã markdown codeblock) gồm đúng 3 trường:
   - "answer": Nội dung trả lời chi tiết, súc tích, lịch sự bằng tiếng Việt.
   - "quick_replies": Mảng gồm 2-3 câu hỏi gợi ý tự nhiên người dùng rất có thể muốn hỏi tiếp, viết bằng tiếng Việt chuẩn ngữ pháp, có dấu đầy đủ, súc tích (10-45 ký tự), liên quan mật thiết đến nội dung vừa giải đáp (Ví dụ: ["Lãi suất kỳ hạn 12 tháng", "Rút trước hạn có mất lãi không?", "Cách mở sổ online"]). Tuyệt đối không sinh câu hỏi cộc lốc hay lặp lại câu hỏi gốc.
   - "suggested_action": Object điều hướng như mô tả ở trên hoặc null nếu không cần thiết.

NGỮ CẢNH TÀI LIỆU CHÍNH THỐNG:
{combined_context}

{rate_config.rate_table_text()}
"""
        messages = [{"role": "system", "content": system_prompt}]
        if history:
            for item in history[-4:]:
                messages.append({"role": item.role, "content": item.content})
        messages.append({"role": "user", "content": user_question})

        result_json, is_extractive = self._call_llm_with_failover(
            messages, 
            fallback_context=combined_context, 
            user_question=user_question,
            history=history
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
            elif any(k in q_lower for k in ["nap the", "nạp thẻ", "nap the dien thoai", "nạp thẻ điện thoại", "the cao", "thẻ cào", "viettel", "vinaphone", "mobifone"]):
                result_json["suggested_action"] = {"label": "Nạp điện thoại", "route": "/bills/phone-recharge"}
            elif any(k in q_lower for k in ["sinh trac hoc", "sinh trắc học", "ekyc", "dinh danh", "định danh"]):
                result_json["suggested_action"] = {"label": "Xác thực eKYC", "route": "/profile/ekyc"}
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

            if financial_analysis:
                result_json["suggested_action"] = {"label": "Mở sổ tiết kiệm ngay", "route": "/bills/savings"}
            elif is_pin_rec:
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
            elif any(k in q_lower for k in ["gioi thieu ban be", "giới thiệu bạn bè", "link gioi thieu", "link giới thiệu", "ma gioi thieu", "mã giới thiệu", "nhan 50k", "nhận 50k", "friend50k", "referral"]):
                result_json["suggested_action"] = {"label": "Giới thiệu bạn bè", "route": "/referral"}
            elif any(k in q_lower for k in ["voucher", "khuyen mai", "khuyến mại", "khuyến mãi", "uu dai", "ưu đãi", "giam gia", "giảm giá", "senpoint", "sen point", "tich diem", "tích điểm", "doi diem", "đổi điểm", "doi qua", "đổi quà", "xinchao50", "freego", "welcome100k"]):
                result_json["suggested_action"] = {"label": "Kho Voucher & Ưu đãi", "route": "/promotions"}
        # 4b. Kiểm duyệt và bảo vệ đầu ra (Anti-truncated, balanced markdown, leak filtering)
        raw_ans = result_json.get("answer", "")
        result_json["answer"] = sanitize_and_validate_output(raw_ans, user_question)

        latency = (time.time() - start_time) * 1000
        result_json["latency_ms"] = round(latency, 2)

        # 5. Lưu vào Semantic Cache chỉ khi LLM sinh câu trả lời thành công (không lưu extractive fallback hoặc thông báo quá tải)
        if not history and not is_extractive and "quá tải" not in result_json.get("answer", ""):
            self._save_semantic_cache(user_question, query_vec, result_json)

        return result_json

    # ==================== INTEGRATION CHO TOÀN BỘ ECOSYSTEM ====================
    def _internal_headers(self, user_id: Optional[str]) -> Dict[str, str]:
        """
        Header chuẩn cho MỌI call service-to-service nội bộ:
        - X-User-Id: danh tính client do API Gateway verify JWT rồi inject (đã sanitize ở main.py)
        - X-Internal-Key: shared secret v1 — khi wallet/payment/identity bật verification
          theo từng endpoint (pattern tham khảo: identity KycController) thì call từ
          chatbot không bị chặn.
        """
        headers: Dict[str, str] = {"X-Internal-Key": settings.INTERNAL_API_KEY}
        if user_id:
            headers["X-User-Id"] = user_id
        return headers

    def _fetch_active_promotions(self) -> List[Dict[str, Any]]:
        """Lấy danh sách mã voucher khuyến mãi đang có hiệu lực trực tiếp từ notification-service"""
        try:
            url = f"{settings.NOTIFICATION_SERVICE_URL}/api/v1/promotions"
            resp = requests.get(url, headers=self._internal_headers(None), timeout=2.5)
            if resp.status_code == 200:
                body = resp.json()
                return body.get("data", [])
        except Exception as e:
            logger.warning("Error calling notification-service promotions: %s", e)
        return []

    def _fetch_user_vouchers(self, user_id: str) -> List[Dict[str, Any]]:
        """Lấy danh sách voucher cá nhân của người dùng từ notification-service"""
        if not user_id:
            return []
        try:
            url = f"{settings.NOTIFICATION_SERVICE_URL}/api/v1/promotions/my-vouchers"
            resp = requests.get(url, headers=self._internal_headers(user_id), timeout=2.5)
            if resp.status_code == 200:
                body = resp.json()
                return body.get("data", [])
        except Exception as e:
            logger.warning("Error calling notification-service my-vouchers: %s", e)
        return []

    def _fetch_user_wallet_balance(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Gọi nội bộ sang wallet-service để lấy số dư (Zero-LLM leak)"""
        if not user_id:
            return None
        try:
            url = f"{settings.WALLET_SERVICE_URL}/api/v1/wallets/me"
            resp = requests.get(url, headers=self._internal_headers(user_id), timeout=3.0)
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
            resp = requests.get(url, headers=self._internal_headers(user_id), timeout=3.0)
            if resp.status_code == 200:
                body = resp.json()
                return body.get("data", {}).get("content", [])
        except Exception as e:
            logger.warning("Error fetching transactions from payment-service: %s", e)
        return []

    def _fetch_user_profile(self, user_id: str) -> Optional[Dict[str, Any]]:
        """Lấy thông tin hồ sơ và định danh eKYC từ identity-service (Zero-LLM leak)"""
        if not user_id:
            return None
        try:
            url = f"{settings.IDENTITY_SERVICE_URL}/api/v1/users/me"
            resp = requests.get(url, headers=self._internal_headers(user_id), timeout=3.0)
            if resp.status_code == 200:
                return resp.json().get("data")
        except Exception as e:
            logger.warning("Error fetching user profile from identity-service: %s", e)
        return None

    def _fetch_user_cards(self, user_id: str) -> List[Dict[str, Any]]:
        """Lấy danh sách thẻ thanh toán (Visa/E-Card) từ payment-service (Zero-LLM leak)"""
        if not user_id:
            return []
        try:
            url = f"{settings.PAYMENT_SERVICE_URL}/api/v1/cards"
            resp = requests.get(url, headers=self._internal_headers(user_id), timeout=3.0)
            if resp.status_code == 200:
                data = resp.json().get("data")
                return data if isinstance(data, list) else []
        except Exception as e:
            logger.warning("Error fetching cards from payment-service: %s", e)
        return []

    def _fetch_user_bank_accounts(self, user_id: str) -> List[Dict[str, Any]]:
        """Lấy danh sách tài khoản ngân hàng liên kết từ payment-service (Zero-LLM leak)"""
        if not user_id:
            return []
        try:
            url = f"{settings.PAYMENT_SERVICE_URL}/api/v1/bank-accounts"
            resp = requests.get(url, headers=self._internal_headers(user_id), timeout=3.0)
            if resp.status_code == 200:
                data = resp.json().get("data")
                return data if isinstance(data, list) else []
        except Exception as e:
            logger.warning("Error fetching linked bank accounts from payment-service: %s", e)
        return []

    def _fetch_user_savings(self, user_id: str) -> List[Dict[str, Any]]:
        """Lấy danh sách sổ tiết kiệm đang gửi từ payment-service (Zero-LLM leak)"""
        if not user_id:
            return []
        try:
            url = f"{settings.PAYMENT_SERVICE_URL}/api/v1/savings/accounts"
            resp = requests.get(url, headers=self._internal_headers(user_id), timeout=3.0)
            if resp.status_code == 200:
                data = resp.json().get("data")
                return data if isinstance(data, list) else []
        except Exception as e:
            logger.warning("Error fetching savings accounts from payment-service: %s", e)
        return []

    def _fetch_user_loans(self, user_id: str) -> List[Dict[str, Any]]:
        """Lấy danh sách hợp đồng vay tiêu dùng từ payment-service (Zero-LLM leak)"""
        if not user_id:
            return []
        try:
            url = f"{settings.PAYMENT_SERVICE_URL}/api/v1/loans"
            resp = requests.get(url, headers=self._internal_headers(user_id), timeout=3.0)
            if resp.status_code == 200:
                data = resp.json().get("data")
                return data if isinstance(data, list) else []
        except Exception as e:
            logger.warning("Error fetching loans from payment-service: %s", e)
        return []

    def _resolve_counterparty_info(self, wallet_id: Optional[str]) -> Optional[Dict[str, str]]:
        """Tra cứu Tên và SĐT của đối tác qua wallet-service và identity-service nội bộ"""
        if not wallet_id:
            return None
        try:
            # 1. Lấy ownerId từ wallet-service
            w_url = f"{settings.WALLET_SERVICE_URL}/api/v1/wallets/{wallet_id}"
            w_resp = requests.get(w_url, headers=self._internal_headers(None), timeout=2.0)
            if w_resp.status_code != 200:
                return None
            owner_id = w_resp.json().get("data", {}).get("ownerId")
            if not owner_id:
                return None

            # 2. Lấy tên và SĐT từ identity-service
            u_url = f"{settings.IDENTITY_SERVICE_URL}/api/v1/internal/users/{owner_id}"
            u_resp = requests.get(u_url, headers=self._internal_headers(None), timeout=2.0)
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

    def _build_profile_response(self, profile: Dict[str, Any], wallet: Optional[Dict[str, Any]]) -> str:
        """Định dạng phản hồi hồ sơ cá nhân và eKYC chuẩn văn phong ngân hàng bảo mật cao"""
        full_name = profile.get("fullName", "Quý khách")
        phone = profile.get("phoneNumber", "Chưa cập nhật")
        email = profile.get("email", "Chưa liên kết")
        alias = profile.get("accountAlias") or "Chưa tạo (Quý khách có thể tạo Biệt danh chuyển tiền miễn phí)"
        
        kyc_tier = profile.get("kycTier", "TIER_1")
        if kyc_tier in ["VERIFIED", "TIER_2"]:
            kyc_desc = "Đã định danh eKYC Cấp 2 (Xác thực Sinh trắc học & NFC CCCD)"
        elif kyc_tier == "TIER_1":
            kyc_desc = "Đã xác thực Cấp 1 (Chờ bổ sung xác thực khuôn mặt sinh trắc học)"
        else:
            kyc_desc = "Chưa định danh đầy đủ"

        daily_limit = wallet.get("dailyLimit", 50000000) if wallet else 50000000
        formatted_limit = f"{daily_limit:,.0f} VNĐ/ngày".replace(",", ".")
        status_text = "Đang hoạt động bình thường" if profile.get("status") == "ACTIVE" else "Tạm khóa"

        return (
            f"Dạ em xin gửi Quý khách thông tin hồ sơ tài khoản tại **Sen Hồng Bank**:\n\n"
            f"- 👤 **Chủ tài khoản:** **{full_name}**\n"
            f"- 📱 **Số điện thoại:** `{phone}`\n"
            f"- 📧 **Email:** `{email}`\n"
            f"- 🏷️ **Biệt danh tài khoản (Alias):** **{alias}**\n"
            f"- 🛡️ **Cấp độ eKYC:** **{kyc_desc}**\n"
            f"- ⚡ **Hạn mức giao dịch ngày:** **{formatted_limit}**\n"
            f"- 🟢 **Trạng thái tài khoản:** **{status_text}**\n\n"
            f"Quý khách có thể cập nhật thông tin CCCD gắn chip, đổi mã PIN hoặc nâng hạn mức chữ ký số tại mục **Hồ sơ cá nhân** ạ!"
        )

    def _build_cards_response(self, cards: List[Dict[str, Any]], bank_accounts: List[Dict[str, Any]]) -> str:
        """Định dạng phản hồi danh sách thẻ Visa và Ngân hàng liên kết"""
        lines = ["Dạ em xin gửi Quý khách danh sách thẻ thanh toán và ngân hàng liên kết tại **Sen Hồng Bank**:\n"]
        if cards:
            lines.append("💳 **Thẻ thanh toán (Visa / E-Card):**")
            # Hiển thị tối đa 3 thẻ tiêu biểu nếu có nhiều thẻ
            for idx, c in enumerate(cards[:3], 1):
                title = c.get("title", "Thẻ Sen Hồng Visa")
                tier = c.get("tier", "Thẻ thanh toán")
                masked = c.get("maskedNumber", "•••• •••• •••• ••••")
                status = "🟢 Đang hoạt động" if c.get("status") == "ACTIVE" else "🔴 Đang khóa"
                online = "Bật" if c.get("onlinePayment", True) else "Tắt"
                avail = c.get("available", 0)
                formatted_avail = f"{avail:,.0f} VNĐ".replace(",", ".")
                lines.append(f"{idx}. **{title}** (`{masked}`)")
                lines.append(f"   - Phân hạng: *{tier}*")
                lines.append(f"   - Trạng thái: **{status}**")
                lines.append(f"   - Hạn mức khả dụng: **{formatted_avail}**")
                lines.append(f"   - Thanh toán trực tuyến: **{online}**\n")
            if len(cards) > 3:
                lines.append(f"*(Quý khách đang sở hữu tổng cộng **{len(cards)}** thẻ thanh toán)*\n")
        else:
            lines.append("💳 **Thẻ thanh toán:** Quý khách hiện chưa phát hành thẻ Visa. Quý khách có thể mở Thẻ ảo Visa E-Card miễn phí 100% trong 30 giây để mua sắm quốc tế ạ!\n")

        if bank_accounts:
            lines.append("🏦 **Tài khoản ngân hàng liên kết:**")
            for idx, b in enumerate(bank_accounts, 1):
                b_name = b.get("bankName", "Ngân hàng liên kết")
                acc_num = b.get("accountNumber", "••••")
                acc_name = b.get("accountName", "")
                is_def = " (Mặc định)" if b.get("isDefault") else ""
                lines.append(f"- **{b_name}** - Số TK: `{acc_num}` - Chủ TK: **{acc_name}**{is_def}")
            lines.append("")
        else:
            lines.append("🏦 **Tài khoản ngân hàng liên kết:** Quý khách chưa liên kết tài khoản ngân hàng nào. Quý khách có thể liên kết để nạp/rút tiền 24/7 hoàn toàn miễn phí ạ!\n")

        lines.append("Quý khách có thể bấm nút **Quản lý thẻ** bên dưới để kích hoạt, khóa thẻ hoặc đổi mã PIN thẻ tức thì ạ!")
        return "\n".join(lines)

    def _build_savings_response(self, savings: List[Dict[str, Any]]) -> str:
        """Định dạng phản hồi danh sách sổ tiết kiệm đang gửi sinh lời"""
        if not savings:
            return (
                "Dạ Quý khách hiện chưa có sổ tiết kiệm nào đang mở tại Sen Hồng Bank ạ.\n\n"
                f"Hiện ngân hàng đang áp dụng chương trình **Tiết kiệm Phát Lộc Online** với lãi suất hấp dẫn lên đến **{rate_config.SAVINGS_RATES[24]:.1f}%/năm**, "
                "gửi tích lũy linh hoạt từ 1.000.000 VNĐ, kỳ hạn đa dạng từ 1 đến 36 tháng.\n\n"
                "Quý khách có muốn em hỗ trợ mở sổ tiết kiệm online ngay bây giờ không ạ?"
            )

        total_principal = 0.0
        total_expected_interest = 0.0
        lines = ["Dạ em xin gửi Quý khách danh sách các sổ tiết kiệm đang sinh lời tại **Sen Hồng Bank**:\n"]

        for s in savings:
            principal = float(s.get("principal", 0))
            exp_interest = float(s.get("expectedInterest", 0))
            total_principal += principal
            total_expected_interest += exp_interest

        for idx, s in enumerate(savings[:3], 1):
            acc_num = s.get("accountNumber", f"TK-{idx}")
            prod = s.get("productType", "TIET_KIEM_PHAT_LOC")
            prod_name = "Tiết kiệm Phát Lộc" if "PHAT_LOC" in str(prod) else "Tiết kiệm Tích lũy"
            principal = float(s.get("principal", 0))
            rate = float(s.get("interestRate", 0))
            term = s.get("termMonths", 0)
            exp_interest = float(s.get("expectedInterest", 0))
            maturity = s.get("maturityDate", "Đang cập nhật")
            status = "Đang sinh lời" if s.get("status") == "ACTIVE" else s.get("status", "Đang hoạt động")

            fmt_principal = f"{principal:,.0f} VNĐ".replace(",", ".")
            fmt_interest = f"{exp_interest:,.0f} VNĐ".replace(",", ".")

            lines.append(f"**{idx}. Sổ {prod_name}** — Số TK: `{acc_num}`")
            lines.append(f"   - 💰 Tiền gốc gửi: **{fmt_principal}**")
            lines.append(f"   - 📈 Lãi suất: **{rate}%/năm** (Kỳ hạn {term} tháng)")
            lines.append(f"   - 🎁 Tiền lãi dự kiến nhận: **{fmt_interest}**")
            lines.append(f"   - 📅 Ngày đáo hạn: **{maturity}**")
            lines.append(f"   - 🟢 Trạng thái: **{status}**\n")

        if len(savings) > 3:
            lines.append(f"*(Hiển thị 3 sổ tiêu biểu gần nhất trong tổng số **{len(savings)}** sổ tiết kiệm)*\n")

        fmt_total_principal = f"{total_principal:,.0f} VNĐ".replace(",", ".")
        fmt_total_interest = f"{total_expected_interest:,.0f} VNĐ".replace(",", ".")
        lines.append(f"📊 **Tổng kết tài sản tiết kiệm:**")
        lines.append(f"- Tổng số sổ tiết kiệm: **{len(savings)} sổ**")
        lines.append(f"- Tổng tiền gửi gốc: **{fmt_total_principal}**")
        lines.append(f"- Tổng tiền lãi dự kiến: **{fmt_total_interest}**\n")
        lines.append("Quý khách có thể bấm nút **Sổ tiết kiệm** bên dưới để xem chi tiết từng hợp đồng hoặc gửi thêm tiết kiệm ạ!")
        return "\n".join(lines)

    def _build_loans_response(self, loans: List[Dict[str, Any]]) -> str:
        """Định dạng phản hồi hợp đồng vay và dư nợ cá nhân"""
        # Lọc các khoản vay đang có hiệu lực / giải ngân
        active_loans = [l for l in loans if l.get("status") in ["ACTIVE", "DISBURSED"]]
        if not active_loans:
            return (
                "Dạ Quý khách hiện không có dư nợ hoặc khoản vay nào tại Sen Hồng Bank ạ! "
                "Lịch sử tín dụng của Quý khách rất tốt (CIC Chuẩn Nhóm 1 - Nợ đủ tiêu chuẩn).\n\n"
                "Quý khách đang đủ điều kiện được phê duyệt trước gói **Vay nhanh Quick Loan** "
                "với hạn mức lên đến **50.000.000 VNĐ**, lãi suất ưu đãi từ **1.2%/tháng**, "
                "giải ngân tự động về ví chỉ sau 3-5 phút mà không cần thế chấp tài sản.\n\n"
                "Quý khách có muốn tham khảo thông tin hoặc đăng ký vay không ạ?"
            )

        total_debt = sum(float(l.get("remainingPrincipal", l.get("principalAmount", 0))) for l in active_loans)
        lines = ["Dạ em xin gửi Quý khách thông tin hợp đồng vay và lịch trả nợ tại **Sen Hồng Bank**:\n"]
        for idx, l in enumerate(active_loans[:3], 1):
            contract = l.get("contractNumber", f"LN-{idx}")
            prod = l.get("productType", "VAY_TIEU_DUNG_NHANH")
            prod_name = "Vay tiêu dùng Quick Loan" if "NHANH" in str(prod) or "QUICK" in str(prod) else "Khoản vay tín chấp"
            principal = float(l.get("principalAmount", 0))
            remaining = float(l.get("remainingPrincipal", principal))
            monthly = float(l.get("monthlyPayment", 0))
            rate = float(l.get("annualInterestRate", l.get("interestRate", 0)))
            term = l.get("termMonths", 0)
            due_date = l.get("firstDueDate", "Đang cập nhật")
            cic = l.get("cicGroupName", "Nhóm 1 - Nợ đủ tiêu chuẩn")
            status = "Đang giải ngân" if l.get("status") == "DISBURSED" else "Đang hiệu lực"

            fmt_principal = f"{principal:,.0f} VNĐ".replace(",", ".")
            fmt_remaining = f"{remaining:,.0f} VNĐ".replace(",", ".")
            fmt_monthly = f"{monthly:,.0f} VNĐ/tháng".replace(",", ".")

            lines.append(f"**{idx}. Hợp đồng {prod_name}** — Mã HĐ: `{contract}`")
            lines.append(f"   - 💵 Số tiền vay ban đầu: **{fmt_principal}**")
            lines.append(f"   - 📉 Dư nợ gốc: **{fmt_remaining}**")
            lines.append(f"   - 🗓️ Trả góp định kỳ: **{fmt_monthly}**")
            lines.append(f"   - 📈 Lãi suất: **{rate}%/năm** (Kỳ hạn {term} tháng)")
            lines.append(f"   - ⏰ Ngày đến hạn thanh toán: **{due_date}**")
            lines.append(f"   - 🛡️ Xếp hạng tín dụng: **{cic}**")
            lines.append(f"   - 🟢 Trạng thái: **{status}**\n")

        if len(active_loans) > 3:
            lines.append(f"*(Hiển thị 3 hợp đồng tiêu biểu trong tổng số **{len(active_loans)}** khoản vay)*\n")

        fmt_total_debt = f"{total_debt:,.0f} VNĐ".replace(",", ".")
        lines.append(f"📊 **Tổng dư nợ các khoản vay:** **{fmt_total_debt}**\n")
        lines.append("Quý khách lưu ý thanh toán đúng hạn vào ngày đến hạn định kỳ để duy trì điểm tín dụng tốt nhất nhé!")
        return "\n".join(lines)

    def _build_financial_overview_response(
        self,
        profile: Optional[Dict[str, Any]],
        wallet: Optional[Dict[str, Any]],
        cards: List[Dict[str, Any]],
        savings: List[Dict[str, Any]],
        loans: List[Dict[str, Any]]
    ) -> str:
        """Định dạng Báo cáo Tổng quan Tài chính 360 độ cá nhân toàn diện trên ứng dụng Mobile"""
        full_name = profile.get("fullName", "Quý khách") if profile else "Quý khách"
        alias = profile.get("accountAlias") if profile else None
        alias_str = f" (@{alias})" if alias else ""
        
        # 1. Ví thanh toán
        bal = float(wallet.get("balance", 0)) if wallet else 0.0
        fmt_bal = f"{bal:,.0f} VNĐ".replace(",", ".")
        daily_limit = float(wallet.get("dailyLimit", 50000000)) if wallet else 50000000.0
        fmt_limit = f"{daily_limit:,.0f} VNĐ/ngày".replace(",", ".")

        # 2. Tiết kiệm
        total_savings = sum(float(s.get("principal", 0)) for s in savings)
        fmt_savings = f"{total_savings:,.0f} VNĐ".replace(",", ".")

        # 3. Dư nợ vay
        active_loans = [l for l in loans if l.get("status") in ["ACTIVE", "DISBURSED"]]
        total_loans = sum(float(l.get("remainingPrincipal", l.get("principalAmount", 0))) for l in active_loans)
        fmt_loans = f"{total_loans:,.0f} VNĐ".replace(",", ".")

        # 4. Thẻ
        active_cards = [c for c in cards if c.get("status") == "ACTIVE"]
        cards_summary = f"{len(active_cards)}/{len(cards)} thẻ đang hoạt động" if cards else "Chưa phát hành thẻ"

        # 5. Giá trị tài sản ròng ước tính (Net Worth)
        net_worth = (bal + total_savings) - total_loans
        fmt_net_worth = f"{net_worth:,.0f} VNĐ".replace(",", ".")

        lines = [
            f"Dạ em xin gửi Quý khách **{full_name}**{alias_str} **Báo cáo Tổng quan Tài chính 360°** tại Sen Hồng Bank:\n",
            f"🌟 **TỔNG TÀI SẢN TÍCH LŨY RÒNG:** **{fmt_net_worth}**\n",
            f"💳 **1. Tài khoản thanh toán & Ví:**",
            f"- Số dư ví khả dụng: **{fmt_bal}**",
            f"- Hạn mức giao dịch ngày: **{fmt_limit}**\n",
            f"📈 **2. Sổ tiết kiệm sinh lời:**",
            f"- Số lượng sổ đang mở: **{len(savings)} sổ**",
            f"- Tổng tiền gửi gốc: **{fmt_savings}**\n",
            f"💳 **3. Thẻ thanh toán (Visa / E-Card):**",
            f"- Tình trạng: **{cards_summary}**\n",
            f"💼 **4. Dư nợ vay tiêu dùng (Quick Loan):**",
            f"- Tổng dư nợ hiện tại: **{fmt_loans}**\n",
            f"🛡️ **5. An toàn & Bảo mật:**",
            f"- Chuẩn tuân thủ: **Quyết định 2345/QĐ-NHNN & PCI-DSS Quốc tế**",
            f"- Xác thực sinh trắc học: **Sẵn sàng**\n",
            f"Quý khách có thể bấm vào các mục bên dưới để quản lý chi tiết từng dịch vụ tài chính của mình ạ!"
        ]
        return "\n".join(lines)

    def _build_personalized_reminders_response(
        self,
        profile: Optional[Dict[str, Any]],
        wallet: Optional[Dict[str, Any]],
        cards: List[Dict[str, Any]],
        savings: List[Dict[str, Any]],
        loans: List[Dict[str, Any]],
        recent_txs: List[Dict[str, Any]]
    ) -> str:
        """Định dạng Lịch Tài Chính & Hệ Thống Nhắc Nhở Cá Nhân Hóa Toàn Diện cho Khách Hàng"""
        full_name = profile.get("fullName", "Quý khách") if profile else "Quý khách"
        alias = profile.get("accountAlias") if profile else None
        alias_str = f" (@{alias})" if alias else ""

        bal = float(wallet.get("balance", 0)) if wallet else 0.0
        fmt_bal = f"{bal:,.0f} VNĐ".replace(",", ".")

        active_loans = [l for l in loans if l.get("status") in ["ACTIVE", "DISBURSED"]]
        total_loans = sum(float(l.get("remainingPrincipal", l.get("principalAmount", 0))) for l in active_loans)
        fmt_loans = f"{total_loans:,.0f} VNĐ".replace(",", ".")

        total_savings = sum(float(s.get("principal", 0)) for s in savings)
        fmt_savings = f"{total_savings:,.0f} VNĐ".replace(",", ".")

        # Đánh giá số dư phục vụ hóa đơn sinh hoạt
        bill_assessment = (
            f"Số dư khả dụng hiện tại (**{fmt_bal}**) hoàn toàn đủ để thanh toán các hóa đơn sinh hoạt định kỳ. Quý khách có thể bật **Auto-Debit (Trích nợ tự động)** để hệ thống gạch nợ tự động 0đ phí."
            if bal >= 2000000 else
            f"Số dư khả dụng hiện tại (**{fmt_bal}**) cần được nạp thêm để đảm bảo đủ số dư thanh toán các hóa đơn sinh hoạt khi đến kỳ chốt cước."
        )

        # Trạng thái thẻ tín dụng
        card_remind = (
            f"Quý khách đang sở hữu **{len(cards)} thẻ**. Lời nhắc: Vui lòng thanh toán toàn bộ 100% dư nợ sao kê trước ngày **15 hàng tháng** để bảo toàn trọn vẹn đặc quyền **45 - 55 ngày miễn lãi** và tránh phí phạt trễ hạn 4% - 5%."
            if cards else
            "Quý khách chưa kích hoạt thẻ tín dụng Sen Hồng. Gợi ý: Đăng ký Thẻ ảo **Visa Platinum Virtual** tức thì trên app để nhận hạn mức đến **100.000.000 VNĐ** và hoàn tiền mua sắm."
        )

        # Trạng thái khoản vay
        loan_remind = (
            f"Quý khách đang có **{len(active_loans)} khoản vay** (tổng dư nợ: **{fmt_loans}**). Lời nhắc: Duy trì đủ số dư ví trước ngày đến hạn thanh toán định kỳ hàng tháng để tránh phát sinh nợ quá hạn nhảy nhóm CIC."
            if active_loans else
            "Quý khách hiện không có khoản nợ vay nào. Hạn mức vay tiêu dùng **Quick Loan** giải ngân online trong 1 phút sẵn sàng hỗ trợ đến **50.000.000 VNĐ** khi cần."
        )

        # Trạng thái sổ tiết kiệm
        savings_remind = (
            f"Quý khách đang có **{len(savings)} sổ tiết kiệm** (tổng tiền gửi: **{fmt_savings}**). Hệ thống sẽ gửi thông báo trước 2 ngày khi sổ đáo hạn; Quý khách có thể chọn tự động tái tục cả gốc và lãi (lãi suất đến **{rate_config.SAVINGS_RATES[24]:.1f}%/năm**) hoặc rút linh hoạt theo Thông tư 04/2022/TT-NHNN."
            if savings else
            f"Quý khách chưa mở sổ tiết kiệm online. Gợi ý: Gửi tiết kiệm online chỉ từ **1.000.000 VNĐ** với lãi suất hấp dẫn đến **{rate_config.SAVINGS_RATES[24]:.1f}%/năm**."
        )

        lines = [
            f"Dạ Sen Hồng Bank xin gửi Quý khách **{full_name}**{alias_str} **Bản Lời Nhắc Tài Chính & Lịch Sinh Hoạt Cá Nhân Hóa**:\n",
            f"💵 **Số dư ví khả dụng hiện tại:** **{fmt_bal}**\n",
            f"🔔 **1. Nhắc Lịch Thanh Toán Hóa Đơn Sinh Hoạt (Điện, Nước, Internet):**",
            f"- Chu kỳ phát sinh: Từ ngày **10 đến 15 hàng tháng**.",
            f"- Tình trạng: {bill_assessment}\n",
            f"💳 **2. Nhắc Hạn Thanh Toán Thẻ Tín Dụng & Miễn Lãi:**",
            f"- {card_remind}\n",
            f"📑 **3. Nhắc Lịch Trả Nợ Khoản Vay Định Kỳ:**",
            f"- {loan_remind}\n",
            f"📈 **4. Nhắc Ngày Đáo Hạn Sổ Tiết Kiệm (Core Savings):**",
            f"- {savings_remind}\n",
            f"⚠️ **5. Cảnh Báo Ngưỡng Chi Tiêu Sinh Hoạt (Smart PFM):**",
            f"- Hệ thống sẽ tự động phát cảnh báo tức thì khi tổng chi tiêu hoặc một nhóm danh mục chạm mốc **80% hạn mức ngân sách tháng**.\n",
            f"💰 **6. Nhắc Tích Lũy Tự Động Định Kỳ (Auto-Savings):**",
            f"- Khuyến nghị trích tự động **10% - 20%** lương vào ngày nhận lương hàng tháng chuyển thẳng vào sổ tiết kiệm tích lũy.\n",
            f"👉 Quý khách có thể bấm chọn nhanh các gợi ý bên dưới để xem tiếp câu trả lời chi tiết nhé ạ!"
        ]
        return "\n".join(lines)

    def _enrich_with_deep_thinking(
        self,
        resp: ChatResponse,
        question: str,
        start_time: float
    ) -> ChatResponse:
        """
        Bổ sung chuỗi suy luận sâu (Extended Thinking / Chain-of-Thought) 5 bước
        và kiểm chứng toán học độc lập vào ChatResponse.
        """
        if resp.thought_process is None or not resp.reasoning_steps:
            calc_latency = resp.latency_ms if resp.latency_ms is not None else round((time.time() - start_time) * 1000, 2)
            thought_data = deep_thinking_engine.analyze_and_reason(
                query=question,
                answer_text=resp.answer,
                sources=resp.sources,
                base_latency_ms=calc_latency,
                retrieved_context=self._last_rag_context
            )
            resp.thought_process = thought_data.get("thought_process")
            resp.reasoning_steps = thought_data.get("reasoning_steps", [])
            resp.thinking_duration_ms = thought_data.get("thinking_duration_ms")
            resp.confidence_score = thought_data.get("confidence_score", 0.99)
            resp.grounding_warnings = thought_data.get("grounding_warnings", [])
        return resp

    def answer_query(
        self, 
        question: str, 
        history: Optional[List[MessageItem]] = None,
        user_id: Optional[str] = None,
        client_context: Optional[Dict[str, Any]] = None
    ) -> ChatResponse:
        """
        Điểm tiếp nhận câu hỏi tích hợp kiến trúc Multi-Tier:
        - Layer 1: Code cứng (Deterministic Security Guardrails: OTP/PIN/Fraud Regex)
        - Layer 2: Jev (System One của TypeSafe AI) - Định tuyến & Gác cổng an toàn
        - Layer 3: System Two Generative Model (Gemini 3.5 Flash Lite + Hybrid RAG trên Postgres)
        - Layer 4: Deep Thinking & Mathematical Verification Engine (Chuỗi suy luận 5 bước minh bạch)
        """
        start_time = time.time()
        resp = self._dispatch_answer_query(
            question=question,
            history=history,
            user_id=user_id,
            client_context=client_context,
            start_time=start_time
        )
        # Tối ưu hóa gợi ý câu hỏi (Quick Replies) dựa trên câu hỏi hiện tại và ngữ cảnh lịch sử trước đó
        resp.quick_replies = enrich_smart_quick_replies(
            query=question,
            raw_replies=resp.quick_replies,
            max_items=3,
            history=history
        )
        return self._enrich_with_deep_thinking(resp, question, start_time)

    def _dispatch_answer_query(
        self, 
        question: str, 
        history: Optional[List[MessageItem]] = None,
        user_id: Optional[str] = None,
        client_context: Optional[Dict[str, Any]] = None,
        start_time: Optional[float] = None
    ) -> ChatResponse:
        """
        Thực thi pipeline phân luồng và xử lý truy vấn của Chatbot.
        """
        if start_time is None:
            start_time = time.time()
        q_clean = normalize_vietnamese_query(question.strip())
        embed_model = self._get_embed_model()

        # =========================================================================
        # LAYER 1: QUY TẮC BẢO MẬT CỐT LÕI (CODE CỨNG - DETERMINISTIC GUARDRAILS)
        # "Các quy tắc bảo mật cốt lõi và giới hạn quyền vẫn phải được lập trình
        # trực tiếp vào ứng dụng vì Jev chỉ cung cấp tín hiệu xác suất."
        # =========================================================================
        is_triggered, guardrail_msg = check_security_guardrails(q_clean)
        if is_triggered:
            q_lower_check = q_clean.lower()
            is_card_emergency = any(k in q_lower_check for k in ["thẻ", "the", "visa", "napas", "atm"])
            action_route = "/cards" if is_card_emergency else "/settings/security"
            action_label = "Khóa thẻ ngay" if is_card_emergency else "Cài đặt bảo mật"
            return ChatResponse(
                answer=sanitize_and_validate_output(guardrail_msg or "Cảnh báo bảo mật từ Sen Hồng Bank.", q_clean),
                sources=[],
                quick_replies=["Khóa thẻ khẩn cấp" if is_card_emergency else "Hướng dẫn bảo mật", "Liên hệ tổng đài 1900-SENHONG"],
                suggested_action=ActionItem(type="NAVIGATE", label=action_label, route=action_route),
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # =========================================================================
        # LAYER 1.5: THEO DÕI NGỮ CẢNH ĐA LƯỢT & HỎI LẠI KHI MƠ HỒ (DISAMBIGUATION)
        # 1. Trích xuất trạng thái hội thoại trước đó (sản phẩm, số tiền $P, kỳ hạn)
        # 2. Với các câu ngắn như 'tính lãi', 'phí', 'hạn mức': Hỏi lại nhã nhặn,
        #    đưa 2-3 lựa chọn rõ ràng và Quick Replies để khách chọn nhanh trong 1 chạm.
        # =========================================================================
        history_context = extract_context_from_history(history, client_context=client_context)
        self._history_context = history_context
        q_enriched = enrich_query_with_context(q_clean, history_context)
        is_continued = (q_enriched != q_clean)
        if is_continued:
            logger.info("Enriched multi-turn query from '%s' to '%s'", q_clean, q_enriched)
            q_clean = q_enriched

        if not is_continued:
            ambiguous_resp = check_ambiguous_query(q_clean)
            if ambiguous_resp:
                logger.info("Disambiguation triggered for query '%s' -> %s", q_clean, ambiguous_resp.get("disambiguation_type"))
                clean_ans = sanitize_and_validate_output(ambiguous_resp["answer"], q_clean)
                action_item = None
                if ambiguous_resp.get("suggested_action"):
                    action_item = ActionItem(
                        type="NAVIGATE",
                        label=ambiguous_resp["suggested_action"]["label"],
                        route=ambiguous_resp["suggested_action"]["route"]
                    )
                return ChatResponse(
                    answer=clean_ans,
                    sources=[],
                    quick_replies=ambiguous_resp["quick_replies"],
                    suggested_action=action_item,
                    latency_ms=round((time.time() - start_time) * 1000, 2)
                )

        # =========================================================================
        # LAYER 1.6: XỬ LÝ CÂU HỎI DÀI & ĐA Ý ĐỊNH (COMPREHENSIVE LONG QUERY ENGINE)
        # Tự động nhận diện và phản hồi trọn vẹn, có cấu trúc các câu hỏi dài, phức tạp:
        # - Vay Quick Loan (Điều kiện + Thủ tục + Lãi suất + Giải ngân + Dự tính trả góp)
        # - Tiết kiệm (So sánh 12m vs 24m + Rút một phần trước hạn theo TT 04/2022)
        # - Tra soát Napas (Bị trừ tiền nhưng chưa nhận, Bảo toàn dòng tiền Saga Ledger)
        # - Thẻ Visa Platinum Virtual (Phí 0đ + Hạn mức 100tr + Netflix/Spotify/Apple Pay)
        # - Sinh trắc học 2345 (Hạn mức bắt buộc + Vị trí đầu đọc NFC iPhone/Android)
        # =========================================================================
        long_resp = handle_comprehensive_long_query(q_clean)
        if long_resp:
            logger.info("Comprehensive Long Query triggered for query: '%s'", q_clean[:80])
            action_item = None
            if long_resp.get("suggested_action"):
                action_item = ActionItem(
                    type="NAVIGATE",
                    label=long_resp["suggested_action"]["label"],
                    route=long_resp["suggested_action"]["route"]
                )
            clean_ans = sanitize_and_validate_output(long_resp["answer"], q_clean)
            return ChatResponse(
                answer=clean_ans,
                sources=long_resp.get("sources", ["Cẩm nang Ngân Hàng Số Sen Hồng"]),
                quick_replies=long_resp.get("quick_replies", []),
                suggested_action=action_item,
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # =========================================================================
        # LAYER 1.7: DANH BẠ TÍNH NĂNG & LUỒNG DẪN DẮT (APP CATALOG & GUIDED FLOW)
        # 1. Trả lời chính xác 'App có tính năng X không?' (Có trong bảng -> có, không -> nói rõ chưa hỗ trợ)
        # 2. Xử lý nhóm LEAD_ACTION: Dẫn dắt từng bước cho Vay và Tiết Kiệm (kèm Disclaimer)
        # 3. Xử lý nhóm HOW_TO_ACTION: Hướng dẫn thao tác từng bước + Nút mở thẳng màn hình
        # =========================================================================
        # 1.7A: Kiểm tra câu hỏi tra cứu 'App có tính năng X không?'
        has_feat, feat_obj, feat_msg = check_app_has_feature(q_clean)
        if feat_msg:
            action = ActionItem(type="NAVIGATE", label=f"Mở {feat_obj['ten']}", route=feat_obj["route"]) if feat_obj else ActionItem(type="NAVIGATE", label="Xem tất cả tiện ích", route="/more")
            return ChatResponse(
                answer=sanitize_and_validate_output(feat_msg, q_clean),
                sources=["Danh Bạ Tính Năng Sen Hồng Bank"],
                quick_replies=["Xem chi tiết", "Biểu phí & Hạn mức", "Quay lại trang chủ"],
                suggested_action=action,
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # 1.7B: Phân loại 4 nhóm ý định cốt lõi
        archetype = classify_question_archetype(q_clean, history)

        # Xử lý luồng dẫn dắt (LEAD_ACTION)
        if archetype == INTENT_LEAD_ACTION:
            guided_resp = self.guided_flow.handle_lead_action(q_clean, history, user_id)
            if guided_resp:
                return guided_resp

        # Xử lý hướng dẫn thao tác (HOW_TO_ACTION)
        if archetype == INTENT_HOW_TO_ACTION:
            matched_f = find_feature_by_query(q_clean)
            if matched_f:
                howto_text = format_feature_howto_answer(matched_f)
                return ChatResponse(
                    answer=sanitize_and_validate_output(howto_text, q_clean),
                    sources=["Danh Bạ Tính Năng Sen Hồng Bank"],
                    quick_replies=[f"Mở {matched_f['ten']}", "Biểu phí & Hạn mức", "Cẩm nang tiện ích"],
                    suggested_action=ActionItem(type="NAVIGATE", label=matched_f['ten'], route=matched_f['route']),
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

        # Rẽ nhánh 2B-1: Báo cáo Tổng quan Tài chính 360 độ (Zero-PII Leak)
        if jev_decision.gate_action == GateAction.DIVERT_INTERNAL_OVERVIEW:
            if user_id:
                profile = self._fetch_user_profile(user_id)
                wallet = self._fetch_user_wallet_balance(user_id)
                cards = self._fetch_user_cards(user_id)
                savings = self._fetch_user_savings(user_id)
                loans = self._fetch_user_loans(user_id)
                answer_text = self._build_financial_overview_response(profile, wallet, cards, savings, loans)
                return ChatResponse(
                    answer=answer_text,
                    sources=["senhong_core_banking_overview"],
                    quick_replies=["Số dư ví", "Sổ tiết kiệm", "Quản lý thẻ", "Khoản vay"],
                    suggested_action=ActionItem(type="NAVIGATE", label="Tổng quan tài chính", route="/profile"),
                    latency_ms=round((time.time() - start_time) * 1000, 2)
                )
            return ChatResponse(
                answer="Dạ để bảo mật thông tin tài khoản, Quý khách vui lòng đăng nhập vào ứng dụng để xem báo cáo tổng quan tài chính ạ.",
                sources=[],
                quick_replies=["Đăng nhập", "Xem biểu phí"],
                suggested_action=ActionItem(type="NAVIGATE", label="Đăng nhập", route="/auth/login"),
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # Rẽ nhánh 2B-2: Tra cứu Hồ sơ cá nhân, eKYC, Alias (Zero-PII Leak)
        if jev_decision.gate_action == GateAction.DIVERT_INTERNAL_PROFILE:
            if user_id:
                profile = self._fetch_user_profile(user_id)
                wallet = self._fetch_user_wallet_balance(user_id)
                if profile:
                    answer_text = self._build_profile_response(profile, wallet)
                    return ChatResponse(
                        answer=answer_text,
                        sources=["identity_service_internal_api"],
                        quick_replies=["Số dư ví", "Quản lý thẻ", "Sổ tiết kiệm"],
                        suggested_action=ActionItem(type="NAVIGATE", label="Hồ sơ cá nhân", route="/profile"),
                        latency_ms=round((time.time() - start_time) * 1000, 2)
                    )
            return ChatResponse(
                answer="Dạ để bảo mật thông tin tài khoản, Quý khách vui lòng đăng nhập vào ứng dụng để tra cứu hồ sơ cá nhân và eKYC ạ.",
                sources=[],
                quick_replies=["Đăng nhập", "Xem biểu phí"],
                suggested_action=ActionItem(type="NAVIGATE", label="Đăng nhập", route="/auth/login"),
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # Rẽ nhánh 2B-3: Tra cứu Thẻ Visa & Ngân hàng liên kết (Zero-PII Leak)
        if jev_decision.gate_action == GateAction.DIVERT_INTERNAL_CARDS:
            if user_id:
                cards = self._fetch_user_cards(user_id)
                bank_accounts = self._fetch_user_bank_accounts(user_id)
                answer_text = self._build_cards_response(cards, bank_accounts)
                return ChatResponse(
                    answer=answer_text,
                    sources=["payment_service_cards_api"],
                    quick_replies=["Số dư ví", "Mở thẻ Visa ảo", "Lịch sử giao dịch"],
                    suggested_action=ActionItem(type="NAVIGATE", label="Quản lý thẻ", route="/cards"),
                    latency_ms=round((time.time() - start_time) * 1000, 2)
                )
            return ChatResponse(
                answer="Dạ để bảo mật thông tin thẻ, Quý khách vui lòng đăng nhập vào ứng dụng để tra cứu danh sách thẻ ạ.",
                sources=[],
                quick_replies=["Đăng nhập", "Xem biểu phí"],
                suggested_action=ActionItem(type="NAVIGATE", label="Đăng nhập", route="/auth/login"),
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # Rẽ nhánh 2B-4: Tra cứu Sổ tiết kiệm của tôi (Zero-PII Leak)
        if jev_decision.gate_action == GateAction.DIVERT_INTERNAL_SAVINGS:
            if user_id:
                savings = self._fetch_user_savings(user_id)
                answer_text = self._build_savings_response(savings)
                return ChatResponse(
                    answer=answer_text,
                    sources=["payment_service_savings_api"],
                    quick_replies=["Mở sổ tiết kiệm", "Xem lãi suất", "Số dư ví"],
                    suggested_action=ActionItem(type="NAVIGATE", label="Sổ tiết kiệm của tôi", route="/savings"),
                    latency_ms=round((time.time() - start_time) * 1000, 2)
                )
            return ChatResponse(
                answer="Dạ để bảo mật thông tin tiền gửi tiết kiệm, Quý khách vui lòng đăng nhập vào ứng dụng để tra cứu sổ tiết kiệm ạ.",
                sources=[],
                quick_replies=["Đăng nhập", "Xem biểu phí"],
                suggested_action=ActionItem(type="NAVIGATE", label="Đăng nhập", route="/auth/login"),
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # Rẽ nhánh 2B-5: Tra cứu Khoản vay của tôi (Zero-PII Leak)
        if jev_decision.gate_action == GateAction.DIVERT_INTERNAL_LOANS:
            if user_id:
                loans = self._fetch_user_loans(user_id)
                answer_text = self._build_loans_response(loans)
                return ChatResponse(
                    answer=answer_text,
                    sources=["payment_service_loans_api"],
                    quick_replies=["Vay nhanh Quick Loan", "Lãi suất vay", "Lịch sử giao dịch"],
                    suggested_action=ActionItem(type="NAVIGATE", label="Khoản vay của tôi", route="/bills/quick-loan"),
                    latency_ms=round((time.time() - start_time) * 1000, 2)
                )
            return ChatResponse(
                answer="Dạ để bảo mật thông tin tín dụng, Quý khách vui lòng đăng nhập vào ứng dụng để tra cứu hợp đồng vay ạ.",
                sources=[],
                quick_replies=["Đăng nhập", "Xem biểu phí"],
                suggested_action=ActionItem(type="NAVIGATE", label="Đăng nhập", route="/auth/login"),
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # Rẽ nhánh 2B-6: Tra cứu Lời nhắc tài chính & Lịch sinh hoạt cá nhân hóa (Zero-PII Leak)
        if jev_decision.gate_action == GateAction.DIVERT_INTERNAL_REMINDERS:
            if user_id:
                profile = self._fetch_user_profile(user_id)
                wallet = self._fetch_user_wallet_balance(user_id)
                cards = self._fetch_user_cards(user_id)
                savings = self._fetch_user_savings(user_id)
                loans = self._fetch_user_loans(user_id)
                recent_txs = self._fetch_user_recent_transactions(user_id, limit=5)
                answer_text = self._build_personalized_reminders_response(profile, wallet, cards, savings, loans, recent_txs)
                return ChatResponse(
                    answer=answer_text,
                    sources=["senhong_smart_reminders_service"],
                    quick_replies=["Cài đặt Auto-Debit hóa đơn", "Xem lịch trả nợ vay", "Mở sổ tiết kiệm tích lũy"],
                    suggested_action=ActionItem(type="NAVIGATE", label="Lịch tài chính & Nhắc nhở", route="/profile"),
                    latency_ms=round((time.time() - start_time) * 1000, 2)
                )
            return ChatResponse(
                answer=(
                    "Dạ để nhận được **Bản Lời Nhắc Tài Chính & Lịch Sinh Hoạt Cá Nhân Hóa** chính xác theo số dư và danh mục của riêng mình, "
                    "Quý khách vui lòng đăng nhập vào ứng dụng Sen Hồng Bank ạ!\n\n"
                    "👉 Quý khách có thể tìm hiểu thêm về Hệ thống 6 loại Nhắc nhở Thông minh của ngân hàng ở gợi ý bên dưới nhé ạ!"
                ),
                sources=[],
                quick_replies=["Hệ thống nhắc nhở thông minh", "Đăng nhập", "Xem biểu phí"],
                suggested_action=ActionItem(type="NAVIGATE", label="Đăng nhập", route="/auth/login"),
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
                else:
                    return ChatResponse(
                        answer="Dạ tài khoản của Quý khách hiện chưa liên kết hoặc chưa kích hoạt ví điện tử cá nhân. Quý khách vui lòng kiểm tra tại mục Hồ sơ hoặc liên hệ tổng đài 1900-SENHONG để được hỗ trợ kích hoạt ví tức thì ạ!",
                        sources=[],
                        quick_replies=["Thông tin tài khoản", "Xem biểu phí", "Mở thẻ Visa"],
                        suggested_action=ActionItem(type="NAVIGATE", label="Thông tin tài khoản", route="/profile"),
                        latency_ms=round((time.time() - start_time) * 1000, 2)
                    )
            return ChatResponse(
                answer="Dạ để bảo mật thông tin tài khoản, Quý khách vui lòng đăng nhập vào ứng dụng để tra cứu số dư chi tiết ạ.",
                sources=[],
                quick_replies=["Đăng nhập", "Xem biểu phí"],
                suggested_action=ActionItem(type="NAVIGATE", label="Đăng nhập", route="/auth/login"),
                latency_ms=round((time.time() - start_time) * 1000, 2)
            )

        # Rẽ nhánh 2C: Hỏi lịch sử giao dịch & đối tác (Zero-PII Leak)
        if jev_decision.gate_action == GateAction.DIVERT_INTERNAL_TRANSACTIONS:
            if user_id:
                recent_txs = self._fetch_user_recent_transactions(user_id, limit=5)
                if recent_txs:
                    answer_text = self._build_transaction_history_response(recent_txs, user_id)
                else:
                    answer_text = "Dạ tài khoản của Quý khách hiện chưa phát sinh giao dịch nào gần đây ạ. Quý khách có thể thực hiện nạp tiền, chuyển tiền hoặc thanh toán hóa đơn để trải nghiệm dịch vụ của Sen Hồng Bank nhé!"
                return ChatResponse(
                    answer=answer_text,
                    sources=["payment_service_internal_api"] if recent_txs else [],
                    quick_replies=["Kiểm tra số dư ví", "Chuyển tiền ngay", "Biểu phí dịch vụ"],
                    suggested_action=ActionItem(type="NAVIGATE", label="Xem tất cả giao dịch" if recent_txs else "Chuyển tiền ngay", route="/history" if recent_txs else "/transfer"),
                    latency_ms=round((time.time() - start_time) * 1000, 2)
                )
            return ChatResponse(
                answer="Dạ để bảo mật thông tin tài khoản, Quý khách vui lòng đăng nhập vào ứng dụng để tra cứu lịch sử giao dịch chi tiết ạ.",
                sources=[],
                quick_replies=["Đăng nhập", "Xem biểu phí"],
                suggested_action=ActionItem(type="NAVIGATE", label="Đăng nhập", route="/auth/login"),
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
        # LAYER 3: FINANCIAL REACT AGENT WITH TOOLS (AUTONOMOUS FUNCTION CALLING)
        # Agent tự suy nghĩ -> Tự gọi công cụ -> Xem kết quả -> Trả lời chính xác
        # =========================================================================
        try:
            agent_response = self.banking_agent.run_agent_loop(
                user_question=q_clean,
                history=history,
                user_id=user_id
            )
            if agent_response and agent_response.answer and len(agent_response.answer) > 20:
                logger.info("[REACT AGENT COMPLETE] Answer generated via autonomous tool loop in %.2fms", agent_response.latency_ms)
                return agent_response
        except Exception as e:
            logger.warning("ReAct Agent encountered exception: %s. Falling back to single-pass RAG.", e)

        masked_q, token_map = tokenize_pii(q_clean)
        res_dict = self.query(masked_q, history=history, user_id=user_id)

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
        raw_qr = res_dict.get("quick_replies", [])
        quick_replies = []
        if isinstance(raw_qr, list):
            for qr in raw_qr:
                if isinstance(qr, str) and qr.strip():
                    quick_replies.append(qr.strip())
                elif isinstance(qr, dict):
                    lbl = qr.get("label") or qr.get("text") or qr.get("title") or ""
                    if lbl:
                        quick_replies.append(str(lbl).strip())
                elif qr is not None:
                    quick_replies.append(str(qr).strip())
        elif isinstance(raw_qr, str) and raw_qr.strip():
            quick_replies = [raw_qr.strip()]
        # Chỉ cắt 4 items RAW: enrichment (loại trùng lặp, thêm gợi ý chuyên sâu theo domain,
        # chuẩn hóa ngữ pháp) chạy DUY NHẤT ở answer_query() — tránh enrich 2 lần và để
        # semantic cache lưu dữ liệu thô (cache hit vẫn được enrich fresh theo logic mới nhất).

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

            is_alias_reg = any(k in q_lower_clean for k in [
                "alias", "biệt danh", "biet danh", "đặt tên tài khoản", "dat ten tai khoan", "tên tài khoản"
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
            elif is_alias_reg:
                final_route = "/profile"
                action_label = "Cài đặt Biệt danh Alias"
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
            elif any(k in raw_route.lower() for k in ["promo", "voucher", "ưu đãi", "uu_dai", "khuyến mại", "khuyen_mai", "senpoint"]):
                final_route = "/promotions"
                action_label = action_data.get("label", "Kho Voucher & Ưu đãi")
            elif any(k in raw_route.lower() for k in ["referral", "giới thiệu", "gioi_thieu"]):
                final_route = "/referral"
                action_label = action_data.get("label", "Giới thiệu bạn bè")
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
        clean_answer = sanitize_and_validate_output(answer_final, q_clean)

        return ChatResponse(
            answer=clean_answer,
            sources=sources_final,
            quick_replies=quick_replies,
            suggested_action=suggested_action,
            latency_ms=round(latency, 2)
        )


# Singleton Instance phục vụ Microservice
rag_engine = AdvancedRAGEngine()
