# HƯỚNG DẪN BẢO VỆ ĐỒ ÁN VÍ ĐIỆN TỬ (FINTECH E-WALLET SYSTEM)

---

## 1. TỔNG QUAN HỆ THỐNG & ĐIỂM SÁNG NỔI BẬT

Dự án là một hệ thống **Ví điện tử hoàn chỉnh (Full-Stack Fintech Solution)** gồm:
- **Backend Core:** Java 17 + Spring Boot 3 + PostgreSQL + Redis, xây dựng theo chuẩn **Hexagonal Architecture (Ports and Adapters)** kết hợp **Domain-Driven Design (DDD)**.
- **Mobile Client:** React Native (Expo) + TypeScript với **31 màn hình** thiết kế theo chuẩn ngôn ngữ iOS Glassmorphism cao cấp.
- **Độ tin cậy:** 100% kiểm thử tự động (**263/263 Unit & Integration Tests Pass**), bao phủ toàn diện các kịch bản thành công và ngoại lệ tài chính.

---

## 2. 18 BÀI TOÁN KỸ THUẬT FINTECH NÂNG CAO (KEY DEFENSE POINTS)

Khi bảo vệ đồ án, hãy tập trung làm nổi bật **18 kỹ thuật lõi** sau đây trước hội đồng:

### Nhóm 1: Toàn vẹn Tài chính & Chống Race Condition
1. **Idempotency-Key (Task 1):** Header `Idempotency-Key` kết hợp Redis Cache ngăn chặn trùng lặp giao dịch khi mạng chập chờn hoặc người dùng bấm 2 lần.
2. **Khóa số dư cấp hàng (Row-Level Pessimistic Lock & Distributed Lock) (Task 1):** Sử dụng `SELECT ... FOR UPDATE` và Distributed Lock có timeout để ngăn chặn tình trạng rút tiền đồng thời (Double Spending / Race Condition).
3. **Hệ thống Ghi sổ kép (Double-Entry Ledger) (Task 1):** Mọi giao dịch biến động số dư đều sinh ra một bút toán `JournalEntry` gồm tối thiểu 2 dòng `LedgerPosting` (1 Nợ - 1 Có) cân bằng tuyệt đối để phục vụ kiểm toán tài chính.
4. **Bảo toàn dữ liệu & Soft Delete (Task 18):** Tuyệt đối không xóa cứng dữ liệu tài chính (Ledger, Transactions, AuditLog). Mọi sự điều chỉnh đều thông qua giao dịch bù trừ hoặc cập nhật trạng thái `REVERSED`.

### Nhóm 2: Bảo mật & Xác thực Tiêu chuẩn Ngân hàng
5. **Xác thực giao dịch 2 lớp PIN / OTP (Task 2):** Mã hóa PIN bằng BCrypt, tạo và xác thực OTP 6 số ngẫu nhiên qua Redis với cơ chế tự động khóa sau 3 lần nhập sai.
6. **Khóa đăng nhập tạm thời (Task 10):** Chống tấn công Brute-force bằng cách đếm số lần sai mật khẩu trong Redis, tự động khóa tài khoản 30 phút sau 5 lần sai.
7. **Thu hồi Token khi Đăng xuất (Token Blacklisting) (Task 11):** Lưu Access/Refresh Token vào Redis Blacklist khi logout; `JwtAuthenticationFilter` chặn mọi request sử dụng token đã thu hồi.
8. **Rate Limiting (Task 14):** Áp dụng `RedisRateLimiter` trên các endpoint công khai nhạy cảm (Đăng nhập, Đăng ký, Quên mật khẩu, Gửi OTP) để chống Spam và DDoS.
9. **Audit Log tập trung (Task 5):** Ghi nhận vết kiểm toán mọi hành động tài chính, tự động thu thập IP và User-Agent động qua `ClientInfoPort`.

### Nhóm 3: Trải nghiệm & Quy chuẩn Thanh toán Quốc gia
10. **Chuẩn hóa VietQR / EMVCo (Task 3):** Tự sinh và giải mã mã QR thanh toán theo chuẩn EMVCo TLV (Tag-Length-Value) kèm mã kiểm tra lỗi CRC-16.
11. **Xác minh người nhận trước khi chuyển (Task 9):** API `GET /api/v1/wallets/recipient-info` trả về tên người nhận đã che bớt ký tự (`NGUYEN V** AN`) để chống chuyển nhầm tài khoản.
12. **Quản lý hạn mức ngày & tháng (Task 8):** Kiểm tra sớm (Pre-lock Validation) hạn mức ngày (100M/ngày) và tháng (500M/tháng) theo từng cấp độ KYC (Unverified / Verified / Advanced).
13. **Giới hạn số tiền trên từng giao dịch (Task 17):** Ràng buộc số tiền tối thiểu (1,000 VND) và tối đa (50,000,000 VND) trên 1 giao dịch đơn lẻ.

### Nhóm 4: Kiến trúc Vận hành & Hệ thống (DevOps & Reliability)
14. **Máy trạng thái giao dịch & Saga Auto-Reversal (Task 4):** Quản lý trạng thái giao dịch chặt chẽ (`INITIATED` -> `PROCESSING` -> `SUCCESS`/`FAILED`/`REVERSED`) và tự động kích hoạt bù trừ tiền khi kết nối ngân hàng bị Timeout.
15. **Global Exception Handler chuẩn hóa lỗi (Task 12):** Trả về định dạng JSON lỗi thống nhất với các mã `errorCode` tường minh trên toàn bộ API.
16. **Giám sát hệ thống với Actuator (Task 13):** Bật các endpoint `/actuator/health`, `/actuator/info`, `/actuator/metrics` sẵn sàng kết nối Prometheus/Grafana.
17. **Chuẩn hóa lưu trữ thời gian theo UTC (Task 15):** Toàn bộ Entity, Hibernate, và Jackson được cố định theo múi giờ UTC (`Instant`), tránh sai lệch khi triển khai đa vùng miền.
18. **Database Migration & Swagger Documentation (Task 6):** Tự động quản lý schema phiên bản qua Flyway (`V1__init_schema.sql`) và tài liệu tương tác Swagger UI/OpenAPI v3.

---

## 3. CÁC CÂU HỎI HỘI ĐỒNG THƯỜNG HỎI & CÁCH TRẢ LỜI

| Câu hỏi của Hội đồng | Câu trả lời trọng tâm |
| :--- | :--- |
| **Q1: Làm sao hệ thống xử lý khi 2 người cùng chuyển tiền vào 1 ví hoặc 1 người bấm chuyển liên tiếp nhiều lần?** | Dùng **Pessimistic Lock (`SELECT ... FOR UPDATE`)** để tuần tự hóa các giao dịch trên cùng một ví. Kết hợp với **Header `Idempotency-Key`** lưu trong Redis để trả về kết quả đã xử lý nếu request bị lặp lại. |
| **Q2: Nếu ngân hàng thứ ba bị timeout khi rút tiền thì sao?** | Áp dụng cơ chế **Saga Pattern / Auto-Reversal**. Khi gọi Bank Gateway bị timeout, hệ thống sẽ tự động hoàn tiền về ví người dùng và chuyển trạng thái giao dịch sang `REVERSED`, đồng thời ghi một bút toán đảo trong Sổ cái kép. |
| **Q3: Tại sao cần hệ thống Sổ cái kép (Double-Entry Ledger) thay vì chỉ lưu `balance` trong bảng `wallets`?** | `balance` chỉ là trạng thái hiện tại. Sổ cái kép giúp bảo đảm **tính toàn vẹn và bất biến (Immutability)**, cho phép đối soát (Reconciliation) bất cứ lúc nào: Tổng Nợ luôn bằng Tổng Có, giúp phát hiện ngay lập tức nếu dữ liệu bị can thiệp trái phép. |
| **Q4: Cơ chế bảo mật mật khẩu và PIN có gì khác nhau?** | Mật khẩu dùng để xác thực phiên đăng nhập (JWT). Mã PIN (6 số) dùng để xác nhận giao dịch tài chính, được mã hóa BCrypt riêng biệt và yêu cầu OTP phụ trợ nếu giao dịch có giá trị lớn hoặc tài khoản chưa nâng cấp sinh trắc học. |
