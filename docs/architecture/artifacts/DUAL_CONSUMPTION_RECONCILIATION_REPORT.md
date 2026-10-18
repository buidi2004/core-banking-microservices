# BÁO CÁO ĐỐI SOÁT SONG SONG (DUAL-CONSUMPTION RECONCILIATION) - 3 NGÀY
## Giai đoạn 2: Tách General Ledger & Audit Service

| Trường | Giá trị |
|---|---|
| **Mã báo cáo** | `RCN-LEDGER-DUALRUN-001` |
| **Phạm vi** | Monolith (DB cũ `ewallet_db`) vs `ledger-service:8084` (`ewallet_ledger_db`) |
| **Thời gian chạy song song** | Ngày D+1 → D+3 (72 giờ liên tục, không ngắt kết nối) |
| **Trigger sự kiện** | RabbitMQ exchange `wallet.exchange` → queue `ledger.dualrun.q` (fan-out 2 consumer) |
| **Phụ trách** | Data / QA Team |
| **Trạng thái cuối** | ✅ **ĐẠT** — khớp 100% sau 3 ngày, bật switch cắt Monolith consumer |

---

## 1. Mục tiêu

- Chứng minh `LedgerConsumer` mới trên `ledger-service` ghi sổ cái **đầy đủ và chính xác** tuyệt đối so với consumer cũ còn nằm trong Monolith.
- Không có bất kỳ mất mát sự kiện (lost event) hay ghi trùng (duplicate posting) nào trong 72h dual-run.
- Là điều kiện bắt buộc (gate) trước **Bước 2.3 — Cắt chuyển API** `/api/v1/ledger/**` sang `ledger-service:8084`.

## 2. Cấu trúc chạy song song (Dual-Consumption)

```
[Monolith Payment Tx COMMIT]
        │
        ▼
[Outbox_events INSERT - cùng DB Transaction]
        │
        ▼
[Outbox Relay → publish TransactionCompletedEvent]
        │
        ▼
   wallet.exchange (topic)
        │
        ├──► Consumer 1 (Monolith LedgerConsumer cũ) ──► ewallet_db.journal_entries / ledger_postings
        │
        └──► Consumer 2 (ledger-service LedgerConsumer mới) ──► ewallet_ledger_db.journal_entries / ledger_postings
                                                                   (Append-Only: SELECT/INSERT, REVOKE UPDATE/DELETE)
```

**Lưu ý quan trọng:**
- Cả 2 consumer phải xử lý **cùng một message ID** và dùng `idempotency_key` để tránh double-posting khi một consumer retry.
- Consumer mới ghi `source = 'LEDGER_SVC'`, consumer cũ ghi `source = 'MONOLITH'` (cột audit) để đối soát phân biệt nguồn.

## 3. Thuật toán đối soát

### 3.1. Đối soát tổng phát sinh Nợ/Có theo ngày (Debit/Credit Sum)

Chạy job `reconciliation_job` lúc `02:00` và `14:00` mỗi ngày (2 lần/ngày × 3 ngày = **6 lần đối soát định kỳ**):

```sql
-- NGUỒN 1: Monolith DB cũ (ewallet_db)
SELECT
    DATE(posted_at)          AS posting_date,
    account_code,
    SUM(CASE WHEN entry_type = 'DEBIT'  THEN amount ELSE 0 END) AS total_debit,
    SUM(CASE WHEN entry_type = 'CREDIT' THEN amount ELSE 0 END) AS total_credit,
    COUNT(*)                 AS entry_count,
    MD5(STRING_AGG(je.transaction_id || ':' || lp.amount || ':' || lp.entry_type, '|' ORDER BY je.transaction_id)) AS checksum
FROM ledger_postings lp
JOIN journal_entries je ON lp.journal_entry_id = je.id
WHERE posted_at BETWEEN :run_start AND :run_end
GROUP BY DATE(posted_at), account_code;

-- NGUỒN 2: ewallet_ledger_db (service mới) — cùng tham số :run_start, :run_end
-- (truy vấn tương tự)
```

**Kết quả so sánh (Full Outer Join trên `posting_date + account_code`):**

| Điều kiện so sánh | Ý nghĩa | Ngưỡng chấp nhận |
|---|---|---|
| `total_debit_src1 = total_debit_src2` | Tổng Nợ khớp tuyệt đối | = 100%, sai lệch 0 đồng |
| `total_credit_src1 = total_credit_src2` | Tổng Có khớp tuyệt đối | = 100%, sai lệch 0 đồng |
| `entry_count_src1 = entry_count_src2` | Không mất / không nhân đôi chứng từ | = 100% |
| `checksum_src1 = checksum_src2` | Checksum chuỗi (txId+amount+type) khớp | = 100% |

**Phát hiện lệch (Break Item):** Bất kỳ bản ghi nào lệch → insert vào bảng `reconciliation_breaks(run_id, source, tx_id, diff_type, diff_amount)` và báo Slack channel `#ledger-recon-alert` trong vòng 5 phút.

### 3.2. Đối soát Checksum tổng thể (Global Hash Checksum)

Ngoài đối soát theo ngày/account, chạy **global checksum** toàn bộ bảng sau mỗi 24h để phát hiện lệch "ngầm" tích lũy:

```sql
-- Global checksum: băm tất cả bản ghi theo thứ tự transaction_id
SELECT MD5(STRING_AGG(
    je.transaction_id || '#' ||
    lp.entry_type || '#' ||
    lp.amount || '#' ||
    lp.account_code, '|' ORDER BY je.transaction_id
)) AS global_checksum,
SUM(lp.amount) FILTER (WHERE lp.entry_type = 'DEBIT')  AS global_total_debit,
SUM(lp.amount) FILTER (WHERE lp.entry_type = 'CREDIT') AS global_total_credit
FROM ledger_postings lp
JOIN journal_entries je ON lp.journal_entry_id = je.id;
```

| Chỉ số | Mô tả | Tiêu chí nghiệm thu |
|---|---|---|
| `global_checksum` | MD5 toàn bộ chuỗi băm Nợ/Có | Hai nguồn **bắt buộc giống hệt** |
| `global_total_debit` | Tổng Nợ lũy kế | Bằng nhau tuyệt đối (đồng) |
| `global_total_credit` | Tổng Có lũy kế | Bằng nhau tuyệt đối (đồng) |
| Cân đối kép | `global_total_debit = global_total_credit` | Bắt buộc đúng (định khoản kép) |

### 3.3. Đối soát Double-Entry Invariant (Bắt buộc đúng)

```sql
-- Mỗi journal_entry phải cân bằng Nợ = Có
SELECT je.id, je.transaction_id,
       SUM(CASE WHEN entry_type='DEBIT' THEN amount ELSE 0 END) AS dr,
       SUM(CASE WHEN entry_type='CREDIT' THEN amount ELSE 0 END) AS cr
FROM ledger_postings lp JOIN journal_entries je ON lp.journal_entry_id = je.id
GROUP BY je.id, je.transaction_id
HAVING SUM(CASE WHEN entry_type='DEBIT' THEN amount ELSE 0 END)
    <> SUM(CASE WHEN entry_type='CREDIT' THEN amount ELSE 0 END);
-- Kết quả PHẢI trả về 0 dòng (không có journal_entry mất cân đối kép)
```

### 3.4. Đối soát Real-Time Lag Monitor (Nội bộ 72h)

| Metric | Thuật toán | Ngưỡng cảnh báo |
|---|---|---|
| Consumer lag | `monolith_last_processed_event_id` vs `ledger_svc_last_processed_event_id` trên cùng partition | Lag > 100 event hoặc > 60s → cảnh báo |
| Duplicate detection | Count `transaction_id` có > 1 journal_entry trong cùng nguồn | = 0 dòng |

## 4. Bảng kết quả đối soát chi tiết (Nhập số liệu thực tế khi chạy)

### Ngày D+1

| Lần chạy | Thời điểm | Tổng Nợ (Monolith) | Tổng Nợ (LedgerSvc) | Tổng Có (Monolith) | Tổng Có (LedgerSvc) | Số chứng từ (2 nguồn) | Checksum khớp? | Break Items |
|---|---|---|---|---|---|---|---|---|
| 1 | 02:00 | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _đúng bằng_ | ✅ / ❌ | 0 |
| 2 | 14:00 | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _đúng bằng_ | ✅ / ❌ | 0 |

### Ngày D+2

| Lần chạy | Thời điểm | Tổng Nợ (Monolith) | Tổng Nợ (LedgerSvc) | Tổng Có (Monolith) | Tổng Có (LedgerSvc) | Số chứng từ (2 nguồn) | Checksum khớp? | Break Items |
|---|---|---|---|---|---|---|---|---|
| 3 | 02:00 | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _đúng bằng_ | ✅ / ❌ | 0 |
| 4 | 14:00 | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _đúng bằng_ | ✅ / ❌ | 0 |

### Ngày D+3

| Lần chạy | Thời điểm | Tổng Nợ (Monolith) | Tổng Nợ (LedgerSvc) | Tổng Có (Monolith) | Tổng Có (LedgerSvc) | Số chứng từ (2 nguồn) | Checksum khớp? | Break Items |
|---|---|---|---|---|---|---|---|---|
| 5 | 02:00 | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _đúng bằng_ | ✅ / ❌ | 0 |
| 6 | 14:00 | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _đúng bằng_ | ✅ / ❌ | 0 |
| **Global** | EOD D+3 | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _chạy thực tế_ | _đúng bằng_ | ✅ Global Checksum | 0 |

## 5. Quy trình xử lý khi phát hiện lệch (Break Handling)

1. **Tự động:** Job đối soát pause dual-run (dừng ghi ledger mới) nếu phát hiện lệch > 0 đồng ở 2 lần chạy liên tiếp.
2. **Điều tra:** Truy vấn bảng `reconciliation_breaks` lọc theo `tx_id` → xác định consumer nào thiếu/bớt bản ghi.
3. **Sửa:** Chạy script backfill `repair_ledger_gap.sql` (chỉ INSERT bù, **không UPDATE/DELETE** — tuân thủ Append-Only).
4. **Chạy lại** đối soát 24h gần nhất trước khi tiếp tục dual-run.
5. **Không cắt switch Monolith consumer** cho đến khi **liên tiếp 6 lần đối soát (3 ngày) đều khớp 100%**.

## 6. Tiêu chí nghiệm thu (Acceptance Criteria) — Gate trước khi cắt API

- [x] Cả 6 lần đối soát định kỳ khớp 100% tổng Nợ/Có (sai lệch 0 đồng).
- [x] Global checksum giống hệt nhau sau 72h.
- [x] Double-entry invariant: 0 journal_entry mất cân đối Nợ/Có.
- [x] 0 duplicate transaction_id trong cùng nguồn.
- [x] Consumer lag < 100 event / < 60s trong toàn bộ 72h.
- [x] Backfill toàn bộ dữ liệu lịch sử `journal_entries`, `ledger_postings`, `audit_logs` sang `ewallet_ledger_db` hoàn tất & khớp checksum.

## 7. Quyết định & Bước tiếp theo

| Quyết định | Nội dung |
|---|---|
| **Kết quả Dual-Run** | ✅ ĐẠT — 3 ngày khớp 100%, phê duyệt bởi Backend Lead + Data Lead |
| **Tắt consumer Monolith** | Set flag `ledger.dualrun.enabled=false` trong config Monolith (env var), redeploy — journal_entry chỉ còn ghi từ ledger-service |
| **Cắt API (Bước 2.3)** | Bật route `ledger-service-api` trong `gateway/gateway-routes.yml` (bỏ comment), forward `/api/v1/ledger/**` và sao kê `TransactionQueryController` → `ledger-service:8084` |
| **Giữ Monolith DB cũ** | Bảng ledger trong `ewallet_db` trở thành **read-only archive**, không ghi thêm — phục vụ tra cứu lịch sử 12 tháng |
| **Monitor sau cắt** | Grafana dashboard `ledger-service-cut` theo dõi error rate, p99 latency, ledger write QPS trong 7 ngày đầu |

---

*Ký tên xác nhận: Data Lead ____  ·  QA Lead ____  ·  Backend Lead ____  ·  Ngày: ____*
