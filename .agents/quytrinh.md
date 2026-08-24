0. NGUYÊN TẮC BẮT BUỘC — KHÔNG THƯƠNG LƯỢNG
Không được báo "xong" nếu chưa chạy lệnh thật và thấy output thật. Không suy đoán, không giả định kết quả build/test sẽ pass — phải thực thi và dán nguyên output.
Sau MỌI thay đổi code, bắt buộc chạy lại toàn bộ build + toàn bộ test suite (không chỉ test của module vừa sửa). Nếu có test cũ bị fail do thay đổi mới → phải sửa cho pass lại, không được xoá/skip/comment test để né lỗi.
Cấm tuyệt đối các hành vi "làm giả cho qua": hard-code giá trị để test pass, sửa assertion trong test cho khớp với output sai, đánh dấu @Disabled/@Ignore để bỏ qua test fail, catch exception rồi nuốt lỗi im lặng.
Làm từng nhiệm vụ một, tuần tự theo đúng thứ tự ở Phần 2. Không được nhảy sang nhiệm vụ tiếp theo khi nhiệm vụ hiện tại chưa xanh (build pass + test pass 100%).
Mỗi nhiệm vụ phải có test mới tương ứng (unit test và/hoặc integration test) — không chỉ sửa code rồi tự nhận là "đã test bằng tay".
Không tự ý đổi kiến trúc Hexagonal + DDD hiện có (domain/application/adapter layers). Nếu thấy cần đổi, phải dừng lại và giải thích rõ lý do trước khi làm, không tự quyết.
Sau mỗi nhiệm vụ, báo cáo đúng theo mẫu ở Phần 4 — không được tóm tắt qua loa kiểu "đã hoàn thành, mọi thứ hoạt động tốt" mà không có bằng chứng (lệnh đã chạy + output).
Nếu build hoặc test fail và không tự sửa được sau khi đã thử hợp lý → dừng lại, báo cáo chính xác lỗi gì, không được tự ý bỏ qua để tiếp tục.
1. Bối cảnh kỹ thuật hiện có (không được phá vỡ)
Java Spring Boot 3.2.5, kiến trúc Hexagonal + DDD (domain / application / adapter tách biệt).
PostgreSQL (dữ liệu chính), Redis (cache/session/OTP), JWT (xác thực đăng nhập), Resilience4j (circuit breaker/retry sẵn có).
Các luồng đã có: đăng ký, đăng nhập, chuyển/nhận tiền cơ bản, thông báo, quét QR ngân hàng người nhận, số dư & lịch sử giao dịch.
Không làm eKYC/định danh, không làm AML/PEP đầy đủ — nằm ngoài phạm vi, không được tự thêm.
2. Danh sách nhiệm vụ — LÀM ĐÚNG THỨ TỰ
Task 1 — Idempotency-Key + khóa số dư khi chuyển tiền

Mục tiêu: chống trừ tiền 2 lần khi client gửi trùng request, chống race condition khi 2 giao dịch cùng sửa số dư 1 ví.

Yêu cầu:

Thêm interceptor/filter kiểm tra header Idempotency-Key (UUID do client sinh) trước khi vào use case; nếu key đã xử lý trước đó → trả lại kết quả cũ, không xử lý lại.
Dùng SELECT ... FOR UPDATE (pessimistic lock) hoặc version column (optimistic lock) trên bảng số dư ví khi thực hiện trừ/cộng tiền trong 1 transaction DB.
Ghi sổ kép: mỗi giao dịch chuyển tiền tạo 2 bút toán (nợ ví nguồn, có ví đích) trong cùng 1 DB transaction, không update trực tiếp field balance bằng phép cộng/trừ đơn thuần.

Test bắt buộc:

Test gửi 2 request chuyển tiền giống hệt nhau (cùng Idempotency-Key) → chỉ trừ tiền 1 lần.
Test giả lập 2 giao dịch đồng thời cùng trừ 1 ví (concurrent test, ví dụ dùng CompletableFuture/ExecutorService) → số dư cuối cùng đúng, không âm sai, không mất tiền.
Toàn bộ test cũ liên quan wallet/transaction vẫn pass.
Task 2 — PIN/OTP xác thực giao dịch

Mục tiêu: tách xác thực đăng nhập (JWT) khỏi xác thực hành động chuyển tiền.

Yêu cầu:

Thêm field lưu PIN đã hash cho user; endpoint đổi/đặt PIN.
Sinh OTP giả lập (6 số, lưu Redis TTL 5 phút) khi user khởi tạo giao dịch chuyển tiền; endpoint confirm yêu cầu đúng PIN hoặc OTP mới cho trừ tiền thật sự.
Đếm số lần sai trong Redis, khóa xác nhận giao dịch 15–30 phút nếu sai quá N lần.

Test bắt buộc:

Test chuyển tiền thiếu bước confirm PIN/OTP → phải bị từ chối, không trừ tiền.
Test nhập sai PIN quá số lần cho phép → bị khóa đúng thời gian quy định.
Test luồng đúng (đủ PIN/OTP hợp lệ) → chuyển tiền thành công.
Task 3 — Chuẩn hoá QR theo VietQR/EMVCo

Mục tiêu: sinh và đọc mã QR đúng chuẩn TLV (EMVCo) thay vì tự định dạng JSON tuỳ ý.

Yêu cầu:

POST /qr/generate: sinh chuỗi QR chuẩn (chứa BIN ngân hàng, số tài khoản/ví, số tiền nếu là QR động, nội dung, CRC-16 checksum) + trả ảnh QR (base64).
POST /qr/parse: decode chuỗi QR quét được thành object, validate checksum trước khi cho phép dùng để chuyển tiền.
QR động phải có TTL (ví dụ 10–15 phút), hết hạn thì /qr/parse phải từ chối.
POST /transfer/qr: dùng object đã parse, đi qua đúng luồng Task 1 (idempotency + lock) và Task 2 (PIN/OTP), không được tạo luồng chuyển tiền riêng bỏ qua các bước đó.

Test bắt buộc:

Test sinh QR rồi parse lại → ra đúng dữ liệu gốc.
Test làm sai 1 ký tự trong chuỗi QR (giả lập lỗi quét) → checksum phải phát hiện và từ chối.
Test QR động hết hạn → bị từ chối khi parse/transfer.
Test /transfer/qr vẫn phải đi qua PIN/OTP và idempotency như chuyển khoản thường (không có đường tắt).
Task 4 — Máy trạng thái giao dịch + reversal khi timeout

Mục tiêu: giao dịch không bao giờ "treo" hoặc mất trạng thái khi gọi sang MockBankGatewayAdapter lỗi/timeout.

Yêu cầu:

Áp dụng trạng thái: INITIATED → PENDING_CONFIRMATION → PROCESSING → SUCCESS | FAILED | PENDING_REVERSAL → REVERSED.
Retry có giới hạn (ví dụ tối đa 3 lần) khi gọi bank gateway; hết số lần retry hoặc timeout → tự động chuyển PENDING_REVERSAL, hoàn tiền về ví nguồn, cập nhật REVERSED, bắn thông báo lý do cho người dùng.
Không được trừ tiền ví nguồn trước khi có xác nhận thành công từ gateway.

Test bắt buộc:

Test giả lập bank gateway timeout → giao dịch tự chuyển PENDING_REVERSAL rồi REVERSED, tiền được hoàn đúng số, không mất/không nhân đôi.
Test giả lập bank gateway lỗi 3 lần liên tiếp → dừng retry đúng như cấu hình, không lặp vô hạn.
Test luồng thành công bình thường vẫn đúng trạng thái SUCCESS.
Task 5 — Audit log cơ bản

Mục tiêu: mọi hành động nhạy cảm có thể truy vết.

Yêu cầu:

Log tối thiểu cho: đổi PIN, chuyển tiền, xác nhận OTP sai, đăng nhập từ thiết bị mới — ghi ai, hành động gì, lúc nào, IP/thiết bị nào.
Audit log không được chặn luồng chính (ghi log lỗi không được làm rollback giao dịch tiền).

Test bắt buộc:

Test thực hiện 1 hành động nhạy cảm → có đúng 1 bản ghi audit log tương ứng với đủ thông tin.
Test audit log ghi lỗi (ví dụ giả lập DB log down) → giao dịch chính vẫn không bị ảnh hưởng.
Task 6 — Swagger/OpenAPI + Flyway

Mục tiêu: tài liệu hoá API và quản lý version schema DB.

Yêu cầu:

Toàn bộ endpoint /api/v1/... (bao gồm các endpoint mới từ Task 1–5) phải xuất hiện đầy đủ, đúng trong Swagger UI.
Chuyển toàn bộ thay đổi schema DB (bảng mới, cột mới từ các task trên) thành migration script Flyway, không sửa DB thủ công ngoài migration.

Test bắt buộc:

Chạy ứng dụng từ DB rỗng, để Flyway tự chạy hết migration → ứng dụng khởi động thành công, không lỗi schema.
Gọi thử ít nhất 1 endpoint mới qua Swagger UI → nhận response đúng.
Task 7 — Unit + integration test cho toàn bộ luồng transfer

Mục tiêu: đảm bảo luồng lõi nhất của hệ thống có test bao phủ đầy đủ, không chỉ test rời rạc theo từng task ở trên.

Yêu cầu:

Viết integration test end-to-end cho luồng chuyển tiền hoàn chỉnh: khởi tạo → xác nhận OTP/PIN → xử lý → thành công, và các nhánh lỗi chính (sai OTP, vượt hạn mức, gateway timeout, QR hết hạn/sai checksum).
Test phải chạy được độc lập (không phụ thuộc thứ tự chạy, tự dọn dữ liệu test).

Test bắt buộc: chính task này là viết test — tiêu chí hoàn thành là toàn bộ test suite (cũ + mới) chạy xanh khi build từ đầu (clean install/clean test).

Task 8 — Hạn mức giao dịch đơn giản

Mục tiêu: áp dụng hạn mức chuyển tiền theo ngày/tháng ở mức mặc định đơn giản (không chia theo hạng eKYC).

Yêu cầu:

Kiểm tra tổng giao dịch trong ngày/tháng trước khi cho phép chuyển tiền tiếp; vượt hạn mức → từ chối rõ ràng, không để giao dịch treo.
Đây là bước cuối cùng, phải tích hợp đúng vào luồng đã có ở Task 1–4 (kiểm tra hạn mức trước bước lock số dư).

Test bắt buộc:

Test chuyển tiền trong hạn mức → thành công.
Test chuyển tiền vượt hạn mức → bị từ chối, không trừ tiền, có thông báo lý do rõ ràng.
3. Vòng lặp bắt buộc cho MỖI task
1. Đọc code hiện tại liên quan (không sửa mù)
2. Implement thay đổi
3. Chạy build đầy đủ (ví dụ: mvn clean install) → dán output thật
4. Chạy toàn bộ test suite (ví dụ: mvn test) → dán output thật
5. Nếu có test fail (cũ hoặc mới) → sửa, quay lại bước 3–4, KHÔNG bỏ qua
6. Viết/thêm test cho phần vừa làm nếu chưa có
7. Chỉ khi build xanh + 100% test pass → báo cáo theo mẫu Phần 4
8. Chỉ sau khi được xác nhận task hiện tại đạt → chuyển sang task tiếp theo
4. Mẫu báo cáo bắt buộc sau mỗi task
### Task [số] — [tên task]
- File đã sửa/thêm: [danh sách]
- Lệnh build đã chạy: [lệnh]
- Kết quả build: [PASS/FAIL] — [dán output thật, không tóm tắt]
- Lệnh test đã chạy: [lệnh]
- Kết quả test: [số test pass/tổng số] — [dán output thật]
- Test mới đã thêm: [liệt kê tên test + mục đích]
- Rủi ro/giới hạn còn lại (nếu có): [ghi rõ, không giấu]
5. Các hành vi bị cấm tuyệt đối
Báo "đã xong"/"hoạt động tốt" mà không có output lệnh thật kèm theo.
Xoá, comment, hoặc @Disabled test đang fail để né lỗi.
Sửa assertion của test để khớp với kết quả sai thay vì sửa code.
Bỏ qua test suite cũ, chỉ chạy test mới rồi báo "pass".
Tự ý mở rộng phạm vi sang eKYC/AML/PEP hoặc đổi kiến trúc Hexagonal mà không hỏi trước.
Nhảy cóc sang task sau khi task trước chưa xanh hoàn toàn.
6. Khi gặp lỗi không tự sửa được

Dừng lại ngay, không tiếp tục sang phần khác. Báo cáo:

Lỗi chính xác là gì (copy nguyên error/stacktrace).
Đã thử những cách sửa nào, vì sao chưa được.
Đề xuất hướng xử lý tiếp theo để người dùng quyết định.