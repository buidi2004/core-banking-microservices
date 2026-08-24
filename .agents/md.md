# Phân tích còn thiếu — E-Wallet Backend (đã chốt phạm vi đồ án)

> Bản cập nhật, loại bỏ các mục ngoài phạm vi (eKYC, AML/PEP đầy đủ...) vì bạn đã xác nhận: **đăng ký/đăng nhập xong, không làm định danh (eKYC)**. Giữ lại và đào sâu các luồng bạn đang làm: **chuyển/nhận tiền, thông báo, quét mã QR ngân hàng người nhận, chuyển tiền qua ngân hàng & qua QR (quét + tạo mã), số dư & lịch sử giao dịch đầy đủ**.

---

## Phần 1 — Nghiệp vụ còn thiếu (trong phạm vi bạn đang làm)

### 1.1. Xác thực giao dịch — mảng dễ bị bỏ quên nhất

Đăng nhập bằng JWT chỉ xác thực **danh tính**, không xác thực **hành động**. Ngân hàng/ví thật luôn tách hai lớp này:

| Thiếu | Vì sao cần | Gợi ý làm |
|---|---|---|
| PIN giao dịch (6 số) hoặc OTP | Chuyển tiền không thể chỉ cần JWT hợp lệ — nếu điện thoại bị chiếm phiên, kẻ gian chuyển sạch tiền | Thêm field `transaction_pin_hash` cho user, endpoint `POST /transactions/{id}/confirm` yêu cầu PIN/OTP trước khi ví thực sự trừ tiền |
| OTP giả lập | Không cần SMS gateway thật cho đồ án | Sinh OTP 6 số, lưu Redis TTL 5 phút, log ra console/email thay vì gửi SMS thật — vẫn thể hiện đúng luồng |
| Khóa tạm sau N lần nhập sai PIN/OTP | Chống brute-force | Đếm số lần sai trong Redis, khóa giao dịch 15–30 phút |

### 1.2. Idempotency & xử lý đồng thời số dư — **quan trọng nhất về mặt kỹ thuật**

Đây là phần hay bị hỏi nhất khi bảo vệ đồ án ngân hàng, vì nó chứng minh bạn hiểu bài toán tài chính thực sự khác app CRUD thông thường:

- **Idempotency-Key ở tầng Controller/Interceptor**: người dùng bấm "Chuyển tiền" 2 lần do mạng chậm → nếu không chặn, tiền bị trừ 2 lần. Cần chặn ngay ở filter/interceptor bằng key duy nhất (client tự sinh UUID) trước khi vào use case.
- **Khóa số dư (row-level lock)**: khi 2 giao dịch cùng đọc/ghi số dư 1 ví cùng lúc (race condition) → dùng `SELECT ... FOR UPDATE` (pessimistic lock) hoặc version column (optimistic lock) trên bảng `wallet_balances`.
- **Nguyên tắc double-entry (ghi sổ kép)**: mỗi giao dịch chuyển tiền phải ghi 2 bút toán (nợ ví A, có ví B) trong cùng 1 transaction DB — không chỉ update trực tiếp field `balance`. Đây là cách ngân hàng thật đảm bảo có thể đối soát và không bao giờ "mất tiền không rõ lý do".

### 1.3. Máy trạng thái giao dịch (Transaction State Machine)

Hiện tại nếu chỉ có `SUCCESS`/`FAILED` là chưa đủ mô phỏng thực tế. Cần tối thiểu:

```
INITIATED → PENDING_CONFIRMATION (chờ OTP/PIN) → PROCESSING → SUCCESS
                                                             → FAILED
                                                             → PENDING_REVERSAL → REVERSED
```

`PENDING_REVERSAL` xử lý case: gọi sang "ngân hàng đối tác" (mock) bị timeout giữa chừng — không được để giao dịch treo vô thời hạn hoặc trừ tiền mà không rõ trạng thái.

### 1.4. Hạn mức giao dịch (dù không có eKYC)

Không cần gắn theo hạng định danh, nhưng **vẫn nên có** một mức mặc định đơn giản (vd 10–20 triệu/ngày), vì:
- Đây là quy định bắt buộc thực tế (Nghị định 52/2024/NĐ-CP) — nêu ra trong báo cáo cho thấy bạn hiểu ngành dù không code full eKYC.
- Về kỹ thuật, đây cũng là một business rule dễ demo (`TransactionLimitPolicy` check trước khi trừ tiền).

### 1.5. Chuẩn QR chuyển tiền (VietQR/Napas 247) — bạn nhấn mạnh phần này

Đây là phần "ăn điểm" nhất nếu làm đúng chuẩn thay vì tự bịa format QR:

- **Chuẩn EMVCo QR Code for Payment Systems** là nền tảng VietQR đang dùng tại Việt Nam — chuỗi QR là một dãy TLV (Tag-Length-Value), không phải JSON tuỳ ý.
- Nội dung tối thiểu cần mã hoá: mã ngân hàng thụ hưởng (BIN — do NAPAS cấp cho từng ngân hàng), số tài khoản/số ví người nhận, số tiền (có thể để trống nếu là QR tĩnh), nội dung chuyển khoản, và **mã CRC-16 checksum** ở cuối chuỗi để chống sai lệch dữ liệu khi quét.
- **QR tĩnh vs QR động**: QR tĩnh (không có số tiền, dùng nhiều lần) khác QR động (có số tiền cụ thể, thường có hạn dùng ngắn — nên set TTL ví dụ 10–15 phút để tránh bị quét lại/replay).
- Luồng đề xuất:
  1. `POST /qr/generate` — sinh chuỗi QR chuẩn + trả về ảnh QR (base64, dùng thư viện tạo QR ở tầng backend hoặc để mobile tự vẽ từ chuỗi trả về).
  2. `POST /qr/parse` — nhận chuỗi QR quét được từ app, decode ngược lại thành object (ngân hàng, số tài khoản, số tiền, nội dung), validate checksum.
  3. `POST /transfer/qr` — dùng object đã parse để thực hiện chuyển tiền, đi qua đúng luồng idempotency + xác thực PIN/OTP như chuyển khoản thường.
- Nếu chỉ có 1 app (chuyển nội bộ ví với ví), bạn vẫn nên tự tuân theo chuẩn EMVCo cho phần "quét mã ngân hàng người nhận" — vì đây chính là điểm khác biệt giữa "làm cho chạy" và "làm đúng chuẩn ngành", rất dễ được đánh giá cao khi hỏi vấn đáp.

### 1.6. Chuyển tiền liên ngân hàng (qua `MockBankGatewayAdapter`)

- Cần rõ ràng: khi gọi sang "ngân hàng khác" (mock), giao dịch phải ở trạng thái `PROCESSING` cho đến khi có phản hồi — không trừ tiền ví nguồn ngay lập tức mà chưa chắc bên nhận đã nhận được.
- **Cơ chế retry có giới hạn + timeout → reversal tự động**: nếu gọi 3 lần vẫn lỗi/timeout, tự động hoàn tiền về ví nguồn và cập nhật trạng thái `REVERSED`, đồng thời gửi thông báo cho người dùng biết lý do.

### 1.7. Thông báo (Notification) — làm cho "chắc", không chỉ "có"

- **Hàng đợi retry khi push FCM thất bại**: nếu không có, thông báo "đã nhận tiền" có thể biến mất vĩnh viễn khi mạng chập chờn.
- **Notification center trong app**: lưu lịch sử thông báo (không chỉ push tức thời) để người dùng xem lại — vì thực tế, nhiều thông báo quan trọng (nhận tiền, giao dịch bị từ chối) người dùng cần tra cứu lại sau.
- Gợi ý sự kiện tối thiểu cần bắn thông báo: nhận tiền thành công, chuyển tiền thành công/thất bại, giao dịch bị hoàn (reversed), đăng nhập từ thiết bị mới.

### 1.8. Audit log cơ bản

Dù không làm AML/sàng lọc danh sách đen, vẫn nên log tối thiểu: ai thực hiện hành động gì, lúc nào, từ thiết bị/IP nào — đặc biệt cho các hành động nhạy cảm (đổi PIN, chuyển tiền, đăng nhập thiết bị lạ). Đây là bằng chứng cho thấy bạn hiểu "traceability" là yêu cầu bắt buộc của hệ thống tài chính, kể cả đồ án.

### 1.9. Lịch sử giao dịch & số dư — hoàn thiện phần bạn đã có

Bạn nói đã có "đầy đủ thông tin số dư và thông tin", nhưng để "đầy đủ" đúng nghĩa nên kiểm tra có các phần sau chưa:
- Phân trang (pagination) + lọc theo khoảng thời gian, loại giao dịch (chuyển đi/nhận vào), trạng thái.
- Chi tiết 1 giao dịch: mã giao dịch, số dư trước/sau (không chỉ số tiền giao dịch), thời gian, nội dung, trạng thái, người thực hiện.
- Số dư "khả dụng" (available balance) tách với số dư "thực" (actual balance) nếu có giao dịch đang `PROCESSING`/`PENDING` — tránh trường hợp double-spend khi có giao dịch chưa hoàn tất.

### 1.10. Quản lý phiên & thiết bị

- Đăng xuất từ xa / đăng xuất tất cả thiết bị (khi nghi ngờ mất máy).
- Cảnh báo khi đăng nhập từ thiết bị mới (kết hợp mục 1.8 — bắn audit log + notification).
- Refresh token rotation — nếu access token JWT đã có nhưng chưa thấy cơ chế thu hồi (revoke) khi cần.

---

## Phần 2 — Công nghệ còn thiếu (mức tối thiểu để luồng trên chạy đúng, không cần Kafka/K8s)

| Thiếu | Dùng cho việc gì |
|---|---|
| Thư viện sinh QR (vd ZXing) | Sinh ảnh QR từ chuỗi chuẩn VietQR |
| Redis lock hoặc DB row-lock (`SELECT FOR UPDATE`) | Chống race condition khi cập nhật số dư đồng thời |
| Optimistic locking (version column) | Phương án nhẹ hơn Redis lock nếu ít giao dịch đồng thời |
| Flyway/Liquibase | Quản lý version schema DB — dễ làm, tăng độ chuyên nghiệp khi demo |
| Swagger/OpenAPI | Tài liệu hoá toàn bộ API `/api/v1/...` — giám khảo test API dễ hơn nhiều |
| Unit + integration test cho luồng transfer | Đây là luồng lõi nhất của đồ án, thiếu test sẽ bị hỏi ngay |
| Correlation ID / request tracing đơn giản | Log 1 giao dịch xuyên suốt Controller → Use Case → Adapter → Bank Gateway để dễ debug khi demo |
| Rate limiting cơ bản (Resilience4j đã có sẵn, tận dụng thêm cho endpoint OTP/transfer) | Chống spam OTP, chống lặp request chuyển tiền |

---

## Phần 3 — Gợi ý ưu tiên (làm gì trước, khả thi trong thời gian đồ án)

1. **Idempotency-Key + khóa số dư (lock) khi chuyển tiền** — giải quyết trực tiếp rủi ro lớn nhất về kỹ thuật, dễ bị hỏi nhất khi bảo vệ.
2. **PIN/OTP xác thực giao dịch** (giả lập, không cần SMS thật) — tăng độ "thật" rất nhiều, công sức thấp.
3. **Chuẩn hoá QR theo VietQR/EMVCo** (sinh + parse + checksum) thay vì tự bịa JSON — đây là điểm khác biệt lớn nhất giữa đồ án "cho chạy được" và đồ án "hiểu đúng ngành".
4. **Transaction state machine + reversal khi timeout** cho luồng chuyển liên ngân hàng mock.
5. **Audit log cơ bản** cho các hành động nhạy cảm.
6. **Swagger + Flyway** — chi phí thấp, tăng điểm trình bày.
7. **Unit test cho luồng transfer** — vì đây là phần lõi, nên có test dù chỉ vài case chính (thành công, hết hạn mức, sai OTP, lỗi mạng giữa chừng).
8. Hạn mức giao dịch đơn giản (mục 1.4) — nêu rõ trong báo cáo là đơn giản hoá do không làm eKYC, không cần chia nhiều hạng.

Phần còn lại (Kafka, distributed tracing, Vault, K8s, WAF, HSM...) nên đưa vào mục **"Hướng phát triển"** của báo cáo — nêu ra để chứng tỏ bạn hiểu chuẩn thật của một hệ thống production, không nhất thiết phải code trong đồ án.

---

## Nguồn tham khảo

- Nghị định 52/2024/NĐ-CP về thanh toán không dùng tiền mặt (hạn mức ví điện tử)
- Chuẩn EMVCo QR Code for Payment Systems và đặc tả VietQR do NAPAS công bố
- Thông lệ chung của các ví điện tử/ngân hàng số tại Việt Nam (MoMo, ZaloPay, VNPay, Timo) về xác thực giao dịch và quản lý phiên

*Lưu ý: các quy định pháp luật có thể thay đổi theo thời gian — nên kiểm tra văn bản mới nhất trước khi nộp báo cáo đồ án.*