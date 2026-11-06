# 🤖 Sen Hong Core Banking - AI Chatbot Microservice (PostgreSQL pgvector RAG)

Microservice Trợ lý Tài chính AI 24/7 của Ngân hàng Số Sen Hồng, xây dựng trên nền tảng **Python FastAPI**, **PostgreSQL (`pgvector` extension)**, **`intfloat/multilingual-e5-small`** và **Gemini 2.5 Flash / Gemini Flash Lite (OpenAI SDK)**.

---

## 🏗️ Kiến Trúc Hệ Thống

```
Mobile App (Flutter) / Web Teller Portal
        │ (Bearer JWT)
        ▼
   API Gateway (:8080)
        │ (X-User-Id, X-Internal-Key)
        ▼
   chatbot-service (:8000)
        ├── 1. Lọc PII & Kiểm tra Guardrails (OTP / PIN / Fraud Refusal)
        ├── 2. Vectorize câu hỏi bằng multilingual-e5-small (384 chiều)
        ├── 3. Tìm kiếm Cosine Distance (<=>) trong PostgreSQL (HNSW index)
        ├── 4. Xây dựng System Prompt với Ngữ cảnh tài liệu chính thống
        └── 5. Gọi LLM với Multi-Key Failover (Primary -> Backup Key) -> Trả lời + Trích dẫn nguồn
```

---

## 🛡️ Ưu Thế Kiến Trúc pgvector
1. **Database-Per-Service chuẩn mực:** Đồng nhất cơ sở dữ liệu về PostgreSQL với container riêng `postgres-chatbot` (`pgvector/pgvector:pg16`), tuân thủ tuyệt đối quy ước kiến trúc microservices.
2. **Nhẹ & Tiết kiệm tài nguyên:** Thay thế ChromaDB bằng extension `pgvector` tích hợp, chỉ tiêu tốn ~25MB RAM trên database và không tạo file SQLite ngầm.
3. **Chỉ mục HNSW:** Tìm kiếm tương đồng Cosine cực nhanh dưới 5ms trên bảng `knowledge_chunks`.
4. **Cơ chế Failover kép:** Tự động đảo sang Key dự phòng khi Key chính chạm ngưỡng giới hạn 15 RPM.

---

## 🔍 Kiểm Tra API & Nạp Dữ Liệu Bằng cURL

### 1. Kiểm tra trạng thái hoạt động:
```bash
curl http://localhost:8000/health
```

### 2. Nạp (Ingest) lại tài liệu kiến thức ngân hàng:
```bash
curl -X POST http://localhost:8000/admin/ingest \
  -H "X-Internal-Key: senhong-internal-chatbot-key-2026"
```

### 3. Hỏi đáp tài chính:
```bash
curl -X POST http://localhost:8000/api/v1/chat \
  -H "Content-Type: application/json" \
  -H "X-Internal-Key: senhong-internal-chatbot-key-2026" \
  -d '{"question": "Phí chuyển tiền liên ngân hàng Napas 247 là bao nhiêu?"}'
```
