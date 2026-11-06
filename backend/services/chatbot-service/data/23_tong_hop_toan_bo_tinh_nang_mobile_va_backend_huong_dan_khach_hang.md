# Cẩm Nang Giới Thiệu Toàn Diện & Hướng Dẫn Sử Dụng Chi Tiết Hệ Sinh Thái Sen Hồng Bank (Mobile App & Backend Microservices)

Tài liệu này cung cấp bảng thống kê đầy đủ, phân loại chi tiết và cẩm nang hướng dẫn từng bước (Step-by-step User Manual) dành cho toàn bộ **73 Tính năng trên Ứng dụng Di động (Mobile App Flutter)** và **162 API / 6 Phân hệ Microservices Cốt lõi (Backend)** của Ngân hàng Số Sen Hồng (Sen Hồng Bank).

---

## PHẦN 1: BẢNG TỔNG KẾT QUY MÔ TÍNH NĂNG TOÀN HỆ THỐNG

| Khối Thành Phần | Số Lượng Phân Hệ | Số Lượng Chi Tiết | Công Nghệ Nền Tảng | Ghi Chú Nghiệp Vụ |
| :--- | :---: | :---: | :--- | :--- |
| **Mobile Banking App** | **16 Phân hệ lớn** | **73 Màn hình (Screens)** | Flutter 3.x, Clean Architecture, Liquid Glass | Đệm đáy 110–120dp, Tabular Figures, Haptic Feedback |
| **Backend Microservices** | **6 Services + 1 AI** | **162 Endpoints REST API** | Java 17, Spring Boot 3.2.5, FastAPI, gRPC | Database-per-service, Double-entry Ledger, Saga |
| **Cơ sở dữ liệu** | **6 Databases** | **5 PostgreSQL + 1 pgvector** | PostgreSQL 16 (Port 5433–5438) | Lưu trữ độc lập, Flyway migrations |
| **Thông điệp & Sự kiện** | **Dual-Broker** | **Kafka KRaft + RabbitMQ** | Kafka :9092, RabbitMQ :5672 | Transactional Outbox Relay 500ms, At-least-once |
| **Cổng vào Gateway** | **1 Điểm duy nhất** | **Spring Cloud Gateway :8080** | Netty, Redis Blacklist, Distributed Rate Limit | JWT Verification, Zero PII Leak |

---

## PHẦN 2: CHI TIẾT 16 PHÂN HỆ VÀ 73 TÍNH NĂNG TRÊN MOBILE APP (KÈM HƯỚNG DẪN KHÁCH HÀNG)

### Phân Hệ 1: Xác Thực Danh Tính & Truy Cập An Toàn (Authentication - 8 Tính Năng)
1. **Khởi động ứng dụng (Splash Screen - `/splash`):**
   - *Giới thiệu:* Hiệu ứng đóa sen nở quang học (Blooming Lotus) tinh tế 500ms, tự động kiểm tra token phiên trong Secure Storage.
2. **Đăng nhập đa phương thức (Login - `/auth/login`):**
   - *Hướng dẫn khách hàng:* Nhập Số điện thoại và Mật khẩu đăng nhập. Hoặc chạm 1 chạm vào biểu tượng Face ID / Vân tay để mở khóa tức thì trong 0.5 giây. Bàn phím số ngẫu nhiên giúp chống nhìn trộm và keylogger.
3. **Đăng ký tài khoản số mới (Register - `/auth/register`):**
   - *Hướng dẫn:* Nhập SĐT chính chủ -> Nhận mã xác thực OTP gửi về máy -> Thiết lập mật khẩu và mã PIN giao dịch để sở hữu ngay tài khoản Sen Hồng miễn phí.
4. **Xác thực OTP thông minh (OTP Verification - `/auth/otp`):**
   - *Hướng dẫn:* Nhập mã số gồm 6 chữ số gửi về điện thoại, đồng hồ đếm ngược 60 giây và hỗ trợ gửi lại mã an toàn.
5. **Cài đặt mã PIN giao dịch (Set PIN - `/auth/set-pin`):**
   - *Hướng dẫn:* Nhập mã PIN gồm 6 số dùng để ký lệnh chuyển tiền và thanh toán hóa đơn. Hệ thống cảnh báo tự động nếu khách hàng đặt các dãy số dễ đoán (123456, 111111, ngày sinh).
6. **Khôi phục mật khẩu khi quên (Forgot Password - `/auth/forgot-password`):**
   - *Hướng dẫn:* Tại màn hình Đăng nhập, bấm "Quên mật khẩu?" -> Nhập SĐT -> Nhập OTP -> Quét khuôn mặt sinh trắc học eKYC để xác thực chính chủ -> Thiết lập mật khẩu mới (tối thiểu 8 ký tự gồm chữ hoa, thường và số).
7. **Đặt lại mật khẩu mới (Reset Password - `/auth/reset-password`):**
   - *Hướng dẫn:* Màn hình nhập và xác nhận mật khẩu mới sau khi đã đối soát sinh trắc học thành công.
8. **Khôi phục mã PIN giao dịch khi quên (Forgot PIN - `/auth/forgot-pin`):**
   - *Hướng dẫn:* Khi quên mã PIN chuyển tiền, bấm "Quên mã PIN?" -> Nhập OTP SMS/Smart OTP -> Quét khuôn mặt eKYC đối soát với CCCD -> Tạo mã PIN 6 số mới và kích hoạt giao dịch lại ngay lập tức.
9. **Điều khoản dịch vụ & Pháp lý (Terms of Service - `/auth/terms`):**
   - *Giới thiệu:* Xem chi tiết các điều khoản bảo mật dữ liệu theo Nghị định 13/2023/NĐ-CP và giấy phép trung gian thanh toán của NHNN.

---

### Phân Hệ 2: Chuyển Tiền & Thanh Toán Napas 24/7 (Money Transfer - 8 Tính Năng)
10. **Chuyển tiền nội bộ Sen Hồng (`/transfer`):**
    - *Hướng dẫn:* Chọn Chuyển tiền -> Chọn tab "Nội bộ" -> Nhập SĐT hoặc STK Sen Hồng -> Nhập số tiền -> Xác nhận mã PIN/Face ID. Tiền đến tài khoản người nhận sau **1 giây**, hoàn toàn **miễn phí 100%**.
11. **Chuyển tiền liên ngân hàng Napas 24/7 (`/transfer`):**
    - *Hướng dẫn:* Chọn tab "Liên ngân hàng" -> Chọn ngân hàng nhận trong danh sách hơn 50 ngân hàng Việt Nam -> Nhập số tài khoản -> Hệ thống tự động truy vấn tên chủ tài khoản thụ hưởng -> Kiểm tra thông tin và xác nhận. Hoạt động 24/7 không kể ngày đêm, thứ 7, chủ nhật hay lễ tết.
12. **Nhập số tiền & Gợi ý hạn mức (`/transfer/amount`):**
    - *Tính năng:* Cung cấp các nút chọn nhanh 100k, 200k, 500k, 1 triệu, 2 triệu, 5 triệu; hiển thị số dư khả dụng thực tế và hạn mức còn lại trong ngày.
13. **Kiểm tra thông tin lệnh chuyển tiền (`/transfer/confirm`):**
    - *Tính năng:* Màn hình đối soát thông tin thụ hưởng, kiểm tra phí dịch vụ (0đ), nguồn trích tiền trước khi ký số.
14. **Xác thực ký lệnh chuyển tiền (`TransferConfirmScreen`):**
    - *Tính năng:* Bàn phím số bảo mật Custom PIN Numpad và xác thực sinh trắc học Face ID chống can thiệp phần cứng.
15. **Biên lai giao dịch điện tử (`/transfer/result`):**
    - *Tính năng:* Biên lai chi tiết có Mã tham chiếu giao dịch FT/TX, nút lưu người nhận vào danh bạ, nút chia sẻ ảnh biên lai hoặc xuất file PDF qua Zalo, Messenger, Email.
16. **Chia tiền nhóm Split Bill (`/transfer/request`):**
    - *Hướng dẫn:* Vào Chuyển tiền -> Chọn tab "Yêu cầu / Chia tiền" -> Nhập tổng hóa đơn ăn uống/du lịch -> Chọn danh sách bạn bè -> Hệ thống tự tính số tiền từng người và gửi link/mã VietQR nhắc nợ văn minh.
17. **Danh bạ thụ hưởng đã lưu (`/beneficiaries`):**
    - *Hướng dẫn:* Quản lý, tìm kiếm nhanh theo tên hoặc STK, chỉnh sửa tên gợi nhớ hoặc xóa các tài khoản ngân hàng thụ hưởng thường xuyên chuyển tiền.
18. **Chuyển tiền quốc tế & Kiều hối SWIFT (`/international-transfer`):**
    - *Hướng dẫn:* Hỗ trợ nhận kiều hối từ nước ngoài và chuyển ngoại tệ an toàn theo quy định NHNN thông qua mạng lưới SWIFT code.

---

### Phân Hệ 3: Thanh Toán QR Code Chuẩn Quốc Gia (QR Code - 2 Tính Năng)
19. **Quét mã VietQR thanh toán (`/scan-qr`):**
    - *Hướng dẫn:* Bấm biểu tượng Quét QR góc trên Trang chủ -> Hướng camera về mã QR của người nhận hoặc bấm biểu tượng "Ảnh" để chọn ảnh mã QR lưu trong máy -> Hệ thống tự điền ngân hàng, STK, số tiền -> Bấm thanh toán.
20. **Mã QR nhận tiền của tôi (`/my-qr`):**
    - *Hướng dẫn:* Bấm "Mã QR của tôi" tại Trang chủ -> Hiển thị mã VietQR tiêu chuẩn quốc gia mang đúng Số tài khoản và Tên chủ tài khoản Sen Hồng. Có thể nhập số tiền cụ thể vào mã QR để người khác quét đúng số tiền cần trả.

---

### Phân Hệ 4: Nạp Tiền & Rút Tiền Đa Kênh (Deposit & Withdraw - 5 Tính Năng)
21. **Nạp tiền vào ví từ ngân hàng liên kết (`/deposit`):**
    - *Hướng dẫn:* Tại Trang chủ bấm "Nạp tiền" -> Chọn mệnh giá hoặc tự nhập số tiền -> Chọn ngân hàng liên kết (Vietcombank, BIDV, Techcombank...) -> Xác nhận mã PIN. Tiền vào số dư ngay lập tức, miễn phí 100%.
22. **Xác nhận nạp tiền (`DepositConfirmScreen`):**
    - *Tính năng:* Kiểm tra nguồn tiền nạp và hạn mức nạp trong ngày.
23. **Rút tiền về tài khoản ngân hàng chính chủ (`/withdraw`):**
    - *Hướng dẫn:* Bấm "Rút tiền" -> Nhập số tiền cần rút -> Chọn tài khoản ngân hàng nhận tiền -> Xác thực Face ID/PIN. Tiền về tài khoản ngân hàng trong vòng 30 giây.
24. **Xác nhận rút tiền (`WithdrawConfirmScreen`):**
    - *Tính năng:* Màn hình đối soát số tiền và tài khoản ngân hàng thụ hưởng trước khi trừ số dư ví.
25. **Rút tiền mặt tại cây ATM không cần thẻ vật lý (`/atm-withdrawal`):**
    - *Hướng dẫn:* Chọn "Rút tiền ATM không thẻ" trên App -> Nhận Mã rút tiền 6 số bí mật (có hiệu lực 15 phút) -> Đến cây ATM Napas/Sen Hồng, chọn "Rút tiền không cần thẻ" -> Nhập mã rút tiền và mã OTP gửi về máy để nhận tiền mặt từ khe máy ATM.

---

### Phân Hệ 5: Thanh Toán Hóa Đơn Đa Tiện Ích (`BillPaymentScreen` - `/bills` - 5 Tính Năng)
26. **Trung tâm Hóa đơn 3 Phân nhóm lớn (`/bills`):**
    - *Nhóm Thiết yếu:* Tiền điện EVN toàn quốc (mã PE...), Tiền nước sinh hoạt (Sawaco, Viwaco...), Cáp quang Internet (FPT, VNPT, Viettel), Truyền hình cáp (K+, FPT Play), Phí quản lý chung cư, Thu phí không dừng ETC (VETC & ePass).
    - *Nhóm Tài chính:* Đóng tiền trả góp vay tiêu dùng (FE Credit, Home Credit, Shinhan...), Dư nợ thẻ tín dụng, Phí bảo hiểm định kỳ (Bảo Việt, Prudential, Manulife...).
    - *Nhóm Dịch vụ công & Y tế - Giáo dục:* Nộp thuế TNCN & Lệ phí trước bạ xe qua Cổng Dịch vụ công Quốc gia, Học phí SSC, Viện phí y tế Bạch Mai / Chợ Rẫy, Vé tàu xe DSVN / Futabus.
27. **Nhập mã khách hàng & Tra cứu nợ cước (`/bills/input`):**
    - *Hướng dẫn:* Chọn dịch vụ -> Nhập Mã khách hàng (ví dụ: mã điện `PE0100088921`) -> Hệ thống tự động kết nối cổng đối tác hiển thị tên chủ hộ, địa chỉ và số tiền cước cần đóng.
28. **Xác nhận hóa đơn thanh toán (`/bills/confirm`):**
    - *Tính năng:* Kiểm tra chi tiết hóa đơn, áp dụng Voucher giảm giá nếu có.
29. **Ký thanh toán hóa đơn (`BillPaymentConfirmScreen`):**
    - *Tính năng:* Xác thực bằng mã PIN hoặc sinh trắc học, cấp biên lai điện tử có mã đối soát của nhà cung cấp.
30. **Tự động trích nợ khi có kỳ cước mới (Auto-Debit):**
    - *Hướng dẫn:* Bật công tắc "Tự động thanh toán hóa đơn này", hàng tháng khi nhà cung cấp phát hành kỳ cước mới, ngân hàng tự động trích nợ số dư ví giúp khách hàng không bao giờ bị cắt điện nước hay trễ hạn.

---

### Phân Hệ 6: Nạp Tiền ĐT & Gói Cước Data 4G/5G (Telecommunications - 3 Tính Năng)
31. **Nạp tiền điện thoại chiết khấu 3-5% (`/bills/phone-recharge`):**
    - *Hướng dẫn:* Chọn "Nạp ĐT" -> Nhập SĐT (hoặc chọn từ danh bạ) -> Chọn mệnh giá từ 10.000đ đến 500.000đ của 5 nhà mạng (Viettel, VinaPhone, MobiFone, Vietnamobile, Wintel) -> Hưởng chiết khấu trực tiếp 3% - 5% trên số tiền thanh toán.
32. **Xác nhận nạp ĐT & Ẩn số riêng tư (`PhoneTopupConfirmScreen`):**
    - *Tính năng:* Công tắc ẩn số điện thoại (hiển thị `091****888`) bảo vệ thông tin riêng tư nơi công cộng.
33. **Mua gói cước Data 3G/4G/5G (`/data-topup`):**
    - *Hướng dẫn:* Chọn gói ngày (1GB - 3GB), gói tuần, gói tháng (30GB - 90GB) -> Bấm đăng ký, dung lượng data được kích hoạt tức thì vào thuê bao di động.

---

### Phân Hệ 7: Tiết Kiệm Online Sinh Lời (Core Savings - 2 Tính Năng)
34. **Mở sổ tiết kiệm trực tuyến (`/bills/savings` hoặc `/savings`):**
    - *Hướng dẫn:* Vào "Tiết kiệm" -> Nhập số tiền gửi (từ 1.000.000đ) -> Chọn kỳ hạn (1 tháng: 3.8%, 3 tháng: 4.2%, 6 tháng: 5.5%, 12 tháng: 6.3%, 24 tháng: 6.8%/năm) -> Chọn phương thức đáo hạn: Tự động tất toán về ví hoặc Quay vòng gốc/lãi -> Xác nhận mở sổ tức thì không cần ra quầy.
35. **Xem chi tiết & Tất toán sổ tiết kiệm (`/savings/detail`):**
    - *Hướng dẫn:* Bấm vào cuốn sổ đang hoạt động -> Xem tiền lãi tạm tính lũy kế theo từng ngày, ngày đáo hạn -> Bấm "Tất toán sổ tiết kiệm" nếu cần rút tiền về số dư ví trước hạn (lãi suất không kỳ hạn 0.2%/năm).

---

### Phân Hệ 8: Vay Tiêu Dùng Tín Chấp Nhanh (Quick Loan - 2 Tính Năng)
36. **Đăng ký vay tiêu dùng Quick Loan (`/bills/quick-loan`):**
    - *Hướng dẫn:* Bấm "Vay nhanh" -> Chọn số tiền muốn vay (từ 5 đến 50 triệu VNĐ) và kỳ hạn trả góp (3 đến 24 tháng) -> Xem trước bảng tiền gốc và lãi (1.2%/tháng tính theo dư nợ giảm dần) -> Đồng ý điều khoản và ký hợp đồng số bằng PIN & OTP -> Tiền giải ngân trực tiếp vào ví sau **1 phút**.
37. **Theo dõi Lịch trả nợ khoản vay (`/loan/schedule`):**
    - *Hướng dẫn:* Vào mục Vay -> Chọn "Lịch trả nợ" -> Xem bảng chi tiết từng kỳ trả nợ (ngày đến hạn, tiền gốc, tiền lãi, dư nợ còn lại, trạng thái `PAID` / `DUE` / `UPCOMING`). Hỗ trợ bật tự động trích nợ trả góp hàng tháng và **Tất toán sớm toàn bộ khoản vay với 0% phí phạt**.

---

### Phân Hệ 9: Quản Lý Thẻ & Tài Khoản Liên Kết (Cards & Linking - 4 Tính Năng)
38. **Quản lý Thẻ Sen Hồng Platinum (`/cards`):**
    - *Hướng dẫn:* Quản lý thẻ Napas và Thẻ ảo Visa Platinum Virtual. Bấm biểu tượng con mắt và xác thực Face ID để xem 16 số thẻ và mã CVV bí mật. Gạt nút **"Khóa thẻ khẩn cấp"** 1 chạm để đóng băng thẻ tức thì khi nghi ngờ rò rỉ thông tin.
39. **Liên kết Thẻ & Tài khoản Ngân hàng Napas (`/bank-cards`):**
    - *Hướng dẫn:* Vào mục "Thẻ & Ngân hàng liên kết" -> Bấm "Thêm liên kết mới (+)" -> Chọn ngân hàng (trong hơn 40 ngân hàng Napas) -> Nhập STK hoặc số thẻ chính chủ -> Nhập OTP xác thực từ ngân hàng để hoàn tất liên kết nạp rút 24/7 miễn phí.
40. **Mở tài khoản Số Đẹp phong thủy (`/lucky-account`):**
    - *Hướng dẫn:* Tìm kiếm và chọn số tài khoản đẹp theo ngày sinh nhật, tứ quý, thần tài, lộc phát và kích hoạt online ngay trên App.
41. **Cài đặt nguồn tiền ưu tiên (`/payment-methods`):**
    - *Tính năng:* Tùy chỉnh thứ tự trích nợ khi thanh toán: Ví chính -> Thẻ liên kết -> Thấu chi lương.

---

### Phân Hệ 10: Lịch Sử Giao Dịch & Sao Kê Điện Tử (History & Statements - 2 Tính Năng)
42. **Tra cứu lịch sử biến động số dư (`/history`):**
    - *Hướng dẫn:* Vào mục Lịch sử -> Xem toàn bộ danh sách giao dịch tiền vào, tiền ra. Sử dụng bộ lọc thông minh theo ngày tháng hoặc tìm kiếm nhanh theo tên người nhận/mã giao dịch.
43. **Chi tiết giao dịch & Xuất biên lai PDF (`/history/detail`):**
    - *Tính năng:* Xem mã giao dịch FT/TX, số dư sau giao dịch, trạng thái đối soát sổ cái, nút tải biên lai PDF có chữ ký số điện tử.

---

### Phân Hệ 11: Định Danh Điện Tử & Bảo Mật eKYC (Profile & Security eKYC - 7 Tính Năng)
44. **Hồ sơ tài khoản cá nhân (`/profile`):**
    - *Tính năng:* Xem thông tin định danh, số điện thoại, cấp độ tài khoản, đổi ảnh đại diện avatar.
45. **Quản lý giấy tờ tùy thân CCCD gắn chip (`/profile/identity`):**
    - *Tính năng:* Kiểm tra số CCCD, ngày cấp, nơi cấp và tình trạng đối soát với cơ sở dữ liệu quốc gia.
46. **Xem Cấp độ Định danh & Quyền lợi (`/profile/kyc-level`):**
    - *Tính năng:* Xem hạn mức giao dịch tương ứng: Cấp 1 (chưa eKYC - 5 triệu/ngày), Cấp 2 (eKYC CCCD - 100 triệu/ngày), Cấp 3 (NFC + Smart OTP - 500 triệu đến 1 tỷ/ngày).
47. **Quy trình định danh eKYC trực tuyến (`/profile/ekyc`):**
    - *Hướng dẫn:* Chụp ảnh mặt trước và mặt sau thẻ CCCD gắn chip -> Quét khuôn mặt 3D theo hướng dẫn (quay trái, quay phải, chớp mắt) để đối soát Liveness Detection chống gian lận.
48. **Đọc chip NFC thẻ CCCD theo Quyết định 2345/QĐ-NHNN (`/profile/nfc-reader`):**
    - *Hướng dẫn:* Bật NFC trên điện thoại -> Áp sát lưng máy vào vị trí chip kim loại của CCCD gắn chip trong 3-5 giây -> Quét khuôn mặt đối chiếu dữ liệu gốc Bộ Công An để mở hạn mức chuyển tiền trên 10 triệu/lần hoặc trên 20 triệu/ngày.
49. **Kích hoạt Chữ ký số Smart OTP (`/profile/digital-signature`):**
    - *Hướng dẫn:* Vào Cài đặt -> Chọn Chữ ký số Smart OTP -> Đăng ký và tạo mã PIN Smart OTP 6 số riêng biệt. Mã tự sinh ngoại tuyến an toàn trên máy mà không cần sóng SMS viễn thông.
50. **Cài đặt Email nhận sao kê tự động (`/profile/email-settings`):**
    - *Hướng dẫn:* Nhập email chính chủ -> Định kỳ ngày mùng 01 hàng tháng ngân hàng tự động gửi file PDF sao kê có chữ ký số điện tử của Tổng giám đốc Sen Hồng Bank.

---

### Phân Hệ 12: Cài Đặt An Toàn & Quản Lý Thiết Bị (Settings & Security - 7 Tính Năng)
51. **Cài đặt chung hệ thống (`/settings`):**
    - *Tính năng:* Tùy chỉnh giao diện Sáng / Tối (Light / Dark mode), chuyển đổi ngôn ngữ Tiếng Việt / English.
52. **Cài đặt bảo mật ứng dụng (`/settings/security`):**
    - *Tính năng:* Bật/tắt đăng nhập sinh trắc học (Face ID / Vân tay), thời gian tự động khóa app khi chạy nền.
53. **Khóa tài khoản khẩn cấp (Emergency Kill-Switch):**
    - *Hướng dẫn:* Khi nghi ngờ bị lừa đảo hoặc mất kiểm soát tài khoản, vào Cài đặt bảo mật và gạt nút "Khóa tài khoản khẩn cấp". Toàn bộ các phiên đăng nhập bị hủy tức thì và mọi giao dịch chuyển/rút tiền bị phong tỏa 100%.
54. **Quản lý thiết bị & Đăng xuất từ xa (`/settings/devices`):**
    - *Hướng dẫn:* Xem danh sách mọi điện thoại/máy tính bảng đang đăng nhập tài khoản. Nếu thấy thiết bị lạ, bấm nút **"Đăng xuất thiết bị này"** để hủy phiên từ xa ngay lập tức.
55. **Đổi mã PIN giao dịch chủ động (`/settings/change-pin`):**
    - *Hướng dẫn:* Nhập mã PIN 6 số hiện tại -> Nhập mã PIN mới 2 lần để đổi mã PIN bảo mật định kỳ.
56. **Cài đặt thông báo đẩy OTT (`/notifications/settings`):**
    - *Tính năng:* Tùy chỉnh nhận thông báo biến động số dư tài khoản, ưu đãi khuyến mại và tin cảnh báo an ninh.
57. **Cấu hình kết nối API (`/settings/config`):**
    - *Tính năng:* Tùy chọn đường dẫn Gateway API (Public Ngrok / Localhost) phục vụ kiểm thử và trải nghiệm.

---

### Phân Hệ 13: Tiện Ích Đời Sống & Giải Trí Số (Lifestyle Services - 10 Tính Năng)
58. **Xem tất cả dịch vụ số (`/all-services`):**
    - *Tính năng:* Bảng danh mục tra cứu toàn diện mọi tiện ích đời sống trên một màn hình duy nhất.
59. **Đặt vé máy bay trực tuyến (`/flight-booking`):**
    - *Hướng dẫn:* Tìm kiếm chuyến bay nội địa và quốc tế (Vietnam Airlines, Vietjet Air, Bamboo Airways) -> Chọn giờ bay, hạng vé -> Thanh toán từ số dư ví Sen Hồng.
60. **Quản lý vé máy bay điện tử (`/digital-flight` & `ImediaFlightScreen`):**
    - *Tính năng:* Lưu trữ thẻ lên tàu bay Boarding Pass điện tử và mã đặt chỗ PNR trên ứng dụng.
61. **Đóng Bảo hiểm xã hội tự nguyện & BHYT (`/social-insurance`):**
    - *Hướng dẫn:* Nhập mã số BHXH/BHYT -> Hệ thống kết nối cổng dữ liệu bảo hiểm quốc gia và hoàn tất đóng phí điện tử tức thì.
62. **Mua vé số điện toán Vietlott (`/bills/lottery`):**
    - *Hướng dẫn:* Chọn loại hình Mega 6/45, Power 6/55 hoặc Keno (quay thưởng 5 phút/lần) -> Chọn số thủ công hoặc bấm "Máy tự chọn" -> Mua vé chính thống qua đối tác cấp phép. Tiền thưởng dưới 10 tỷ VNĐ tự động cộng thẳng vào số dư ví sau giờ quay thưởng.
63. **Tra cứu kết quả Vietlott (`/vietlott`):**
    - *Tính năng:* Xem kết quả các kỳ quay số Vietlott mới nhất và kiểm tra vé trúng thưởng tự động.
64. **Vua Xổ Số kiến thiết 3 miền (`/vua-xo-so`):**
    - *Tính năng:* Xem trực tiếp kết quả xổ số truyền thống miền Bắc, miền Trung, miền Nam hàng ngày.
65. **Mua thẻ nạp Game trực tuyến (`/game-cards`):**
    - *Hướng dẫn:* Chọn loại thẻ (Garena, Zing Xu, VTC Vcoin, Gate) -> Chọn mệnh giá -> Nhận mã thẻ và số serial ngay trên màn hình và qua email.
66. **Tiện ích Vận Số tài lộc (`VanSoScreen`):**
    - *Tính năng:* Tra cứu chiêm tinh tài chính, ngày giờ tốt xuất hành và mở sổ tiết kiệm lấy may.
67. **Tích hợp di chuyển & giao hàng Xanh SM (`GreenSMSettingsScreen`):**
    - *Tính năng:* Liên kết ví Sen Hồng thanh toán tự động các chuyến taxi điện và giao hàng Xanh SM.

---

### Phân Hệ 14: Ưu Đãi Khuyến Mại & Giới Thiệu Bạn Bè (Promotions - 3 Tính Năng)
68. **Kho Voucher & Khuyến mại (`/promotions`):**
    - *Tính năng:* Thu thập mã giảm giá thanh toán hóa đơn EVN, mã hoàn tiền nạp ĐT 50%.
69. **Phân loại danh mục ưu đãi (`PromotionCategoryScreen`):**
    - *Tính năng:* Lọc ưu đãi theo nhóm Mua sắm, Di chuyển Xanh SM, Ẩm thực, Trả góp 0%.
70. **Chương trình Giới thiệu bạn bè nhận thưởng (`/referral`):**
    - *Hướng dẫn:* Lấy mã giới thiệu hoặc link chia sẻ cá nhân gửi cho bạn bè -> Khi bạn bè mở tài khoản và phát sinh giao dịch đầu tiên, cả 2 cùng nhận thưởng tiền mặt vào số dư ví.

---

### Phân Hệ 15: Hỗ Trợ Khách Hàng & Trợ Lý AI 24/7 (Support - 2 Tính Năng)
71. **Trung tâm trợ giúp & Tra soát khiếu nại (`/support/help-center`):**
    - *Hướng dẫn:* Xem các câu hỏi thường gặp FAQ, gửi ticket yêu cầu tra soát khi giao dịch chuyển tiền bị treo hoặc nạp tiền chưa vào tài khoản.
72. **Trò chuyện Trợ lý AI Tài chính Thông minh 24/7 (`/support/live-chat`):**
    - *Hướng dẫn:* Bấm biểu tượng chat ở góc phải Trang chủ hoặc trong mục Trợ giúp -> Đặt câu hỏi bằng tiếng Việt có dấu hoặc không dấu. Trợ lý AI giải đáp biểu phí, lãi suất, tra cứu số dư/sao kê thật (Zero-LLM leak) và cung cấp nút bấm điều hướng 1 chạm đến đúng màn hình cần thực hiện.

---

### Phân Hệ 16: Màn Hình Gốc & Thanh Điều Hướng (Shell & Main Tabs - 3 Tính Năng)
73. **Thanh điều hướng Liquid Glass phong cách Fintech (`MainTabsScreen`):**
    - *Tính năng:* 4 Tab chính với hiệu ứng kính mờ Liquid Glass, chuyển tab mượt mà, lưu giữ trạng thái cuộn của từng màn hình.
74. **Màn hình Trang Chủ (`HomeScreen` - `/`):**
    - *Tính năng:* Trung tâm điều khiển tài chính cá nhân với Thẻ số dư chính, Quick Actions và Carousel Banner ưu đãi.
75. **Hộp thư thông báo OTT biến động số dư (`/notifications`):**
    - *Tính năng:* Lưu trữ toàn bộ tin nhắn OTT biến động số dư, thông báo khuyến mại và cảnh báo đăng nhập.

---

## PHẦN 3: CHI TIẾT 6 MICROSERVICES & 162 ENDPOINTS BACKEND (KÈM CƠ CHẾ BẢO MẬT GIAO DỊCH)

Hệ thống Backend được xây dựng theo kiến trúc Microservices phân tán tiêu chuẩn ngân hàng:

### 1. `api-gateway` (Port 8080 - Spring Cloud Gateway Reactive)
- **Nhiệm vụ:** Điểm đón duy nhất cho toàn bộ Mobile App và Web Portal, đảm bảo không dịch vụ nội bộ nào lộ trực tiếp ra Internet.
- **Tính năng cốt lõi:**
  - `JwtAuthenticationFilter`: Giải mã và xác thực chữ ký số RSA/HMAC của JWT Access Token.
  - `RedisTokenBlacklistFilter`: Đối soát với Redis cache trong 1ms để từ chối các token đã bị thu hồi hoặc phiên đã logout.
  - `DistributedRateLimiting`: Giới hạn tần suất gọi API theo IP và User ID, chống tấn công DDoS.
  - `CircuitBreaker & FallbackController`: Tự động ngắt mạch (Circuit Breaker) và chuyển tiếp về Fallback an toàn khi có microservice phía sau bị quá tải.

### 2. `identity-service` (Port 8081 - Database `ewallet_identity_db`:5433 - 11 Controllers, 38 Endpoints)
- **Nhiệm vụ:** Quản lý toàn bộ vòng đời người dùng, định danh điện tử eKYC, mã hóa mật khẩu và phân quyền bảo mật.
- **Endpoints quan trọng:**
  - `POST /api/v1/auth/login`: Đăng nhập, cấp JWT Access Token và Refresh Token.
  - `POST /api/v1/auth/register`: Đăng ký tài khoản mới bằng số điện thoại.
  - `POST /api/v1/auth/otp/send` & `verify`: Gửi và đối soát mã OTP bảo mật.
  - `POST /api/v1/auth/forgot-password` & `reset-password`: Khôi phục mật khẩu khi quên qua eKYC.
  - `POST /api/v1/users/pin/set` & `verify`: Thiết lập và xác thực mã PIN giao dịch (mã hóa BCrypt strength 12).
  - `POST /api/v1/users/pin/forgot`: Cấp lại mã PIN giao dịch bị quên thông qua xác thực khuôn mặt sinh trắc học.
  - `POST /api/v1/security/emergency-lock`: Kích hoạt Emergency Kill-Switch đóng băng khẩn cấp tài khoản.
  - `POST /api/v1/kyc/submit` & `GET /kyc/status`: Nộp hồ sơ và tra cứu trạng thái eKYC CCCD.
  - `GET /api/v1/sessions` & `DELETE /sessions/{id}`: Quản lý thiết bị đăng nhập và hủy phiên từ xa.
  - `GET /api/v1/users/me` & `PATCH /users/me/alias`: Quản lý hồ sơ cá nhân và số tài khoản đẹp alias.

### 3. `wallet-service` (Port 8082 + gRPC 9090 - Database `ewallet_wallet_db`:5434)
- **Nhiệm vụ:** Quản trị số dư ví, chống gian lận chi tiêu vượt mức (Overdraft) và khóa bản ghi độc quyền.
- **Tính năng cốt lõi:**
  - `Pessimistic Locking (SELECT ... FOR UPDATE)`: Khóa độc quyền bản ghi số dư ở tầng Database, đảm bảo 100 giao dịch đồng thời không bao giờ xảy ra lỗi xung đột Race Condition.
  - `gRPC WalletService (:9090)`: Cung cấp giao thức nhị phân siêu tốc cho Payment Service gọi Debit/Credit số dư nội bộ trong < 5ms.
  - `REST Endpoints`: `GET /api/v1/wallets/me` (tra cứu số dư khả dụng), `GET /api/v1/wallets/{id}`.
  - Phát sự kiện Kafka Topic `banking.wallet.balance-changed.v1` mỗi khi số dư biến động.

### 4. `payment-service` (Port 8083 - Database `ewallet_payment_db`:5435 - 20 Controllers, 82 Endpoints)
- **Nhiệm vụ:** Trái tim xử lý thanh toán, điều phối giao dịch phân tán (Saga Orchestration) và hệ thống tiện ích.
- **Tính năng cốt lõi & Endpoints:**
  - `PaymentSagaOrchestrator`: Điều phối chu trình chuyển tiền 4 bước: `RESERVE` -> `DEBIT` -> `CREDIT` -> `LEDGER`. Tự động kích hoạt bù trừ hoàn tiền (Compensating Action) nếu bước sau gặp sự cố.
  - `POST /api/v1/payments/transfer`: Khởi tạo lệnh chuyển tiền nội bộ hoặc liên ngân hàng Napas 24/7.
  - `POST /api/v1/wallets/deposit` & `POST /withdraw`: Nạp tiền và rút tiền ngân hàng liên kết.
  - `POST /api/v1/teller/cash-deposits`: Quy trình nạp tiền mặt tại quầy 2 cấp duyệt Maker-Checker.
  - `POST /api/v1/payments/vietqr/decode` & `generate`: Xử lý mã VietQR chuẩn quốc gia.
  - `POST /api/v1/payments/money-requests`: Quản lý yêu cầu chia tiền nhóm Split Bill và nhắc nợ.
  - `POST /api/v1/bills/lookup` & `POST /bills/pay`: Tra cứu nợ cước và thanh toán hóa đơn điện EVN, nước, internet, ETC, học phí, viện phí.
  - `POST /api/v1/loans/apply` & `GET /loans/{id}/schedule`: Đăng ký gói vay Quick Loan và theo dõi lịch trả nợ 6 kỳ.
  - `POST /api/v1/savings/accounts` & `POST /savings/accounts/{id}/settle`: Mở và tất toán sổ tiết kiệm online.
  - `POST /api/v1/lottery/buy` & `GET /lottery/results`: Mua vé số Vietlott và trả thưởng tự động.
  - `POST /api/v1/cards/issue` & `PATCH /cards/{id}/status`: Phát hành thẻ ảo Visa Platinum Virtual và khóa thẻ khẩn cấp.
  - `POST /api/v1/bank-accounts/link`: Liên kết tài khoản hơn 40 ngân hàng đối tác Napas.
  - `Transactional Outbox Relay`: Ghi sự kiện vào bảng `outbox_events` cùng transaction DB, đẩy song song Kafka và RabbitMQ đảm bảo tính bền vững At-least-once.

### 5. `ledger-service` (Port 8084 - Database `ewallet_ledger_db`:5436 - 3 Controllers)
- **Nhiệm vụ:** Hệ thống Kế toán Sổ cái Kép (Double-entry Ledger) bảo vệ tính toàn vẹn tài chính theo chuẩn ngân hàng quốc tế.
- **Tính năng cốt lõi:**
  - Mỗi giao dịch bắt buộc tạo 1 `JournalEntry` POSTED và $\ge 2$ bản ghi `LedgerPosting` bất biến.
  - Định luật bảo toàn: $\sum \text{Debit} = \sum \text{Credit}$. Nếu độ lệch $\neq 0$, ném ngoại lệ `LedgerUnbalancedException` và chặn đứng giao dịch.
  - Append-only Audit Log chống sửa đổi dữ liệu quá khứ.
  - Endpoints: `POST /api/v1/ledger/postings`, `GET /api/v1/ledger/accounts/{id}/balance`, `GET /api/v1/audit/logs`.

### 6. `notification-service` (Port 8085 - Database `ewallet_notification_db`:5437 - 4 Controllers)
- **Nhiệm vụ:** Kênh thông tin liên lạc đa phương thức với khách hàng.
- **Tính năng cốt lõi:**
  - `STOMP WebSocket Gateway (/ws-native)`: Đẩy thông báo biến động số dư tức thì lên màn hình điện thoại khách hàng sau 0.1 giây.
  - `FCM Push Notification`: Gửi thông báo đẩy khi ứng dụng chạy nền hoặc đóng hoàn toàn.
  - `SMS Banking Engine`: Gửi tin nhắn mã OTP và biến động số dư viễn thông.
  - Endpoints: `GET /api/v1/notifications`, `PATCH /notifications/{id}/read`, `GET /api/v1/promotions`.

### 7. `chatbot-service` (Port 8000 - Database `ewallet_chatbot_db`:5438 - FastAPI Dual-System)
- **Nhiệm vụ:** Trợ lý Trí tuệ Nhân tạo Tài chính Thông minh 24/7.
- **Tính năng cốt lõi:**
  - `Layer 1 - Deterministic Guardrails`: Chặn lộ mã OTP, PIN, CVV và tấn công Prompt Injection trong 0.04ms.
  - `Layer 2 - Jev System One Router`: Phân loại ý định, rẽ nhánh tra cứu số dư/lịch sử giao dịch trực tiếp từ internal API (Zero-LLM leak tuyệt đối cho dữ liệu tài chính) và phản hồi chào hỏi/xã giao < 20ms không tốn token.
  - `Layer 3 - System Two Generative Model`: Mô hình Gemini kết hợp Hybrid Search RRF trên cơ sở tri thức pgvector gồm 27 tài liệu và 254 chunks.
  - Cung cấp nút bấm Deep-linking 1 chạm dẫn khách hàng đến chính xác màn hình cần thực hiện trên Mobile App Flutter.

---

## PHẦN 4: HƯỚNG DẪN XỬ LÝ SỰ CỐ VÀ TRA SOÁT KHI GẶP LỖI

| Tình Huống Sự Cố | Nguyên Nhân Phổ Biến | Hướng Xử Lý Chuẩn Mực Cho Khách Hàng |
| :--- | :--- | :--- |
| **Quên mật khẩu đăng nhập** | Khách lâu ngày không vào app | Tại màn hình Đăng nhập, bấm **"Quên mật khẩu?"** -> Nhập SĐT -> Nhập OTP -> Xác thực khuôn mặt eKYC -> Tạo mật khẩu mới tức thì (Route: `/auth/forgot-password`). |
| **Quên mã PIN chuyển tiền** | Nhầm lẫn mã PIN ví với PIN ATM | Bấm **"Quên mã PIN?"** tại màn hình nhập PIN -> Xác thực OTP và khuôn mặt eKYC -> Cấp lại mã PIN mới ngay lập tức (Route: `/auth/forgot-pin`). |
| **Giao dịch Napas 24/7 bị treo** | Ngân hàng thụ hưởng bảo trì | Tiền đã trừ ở ví Sen Hồng nhưng ngân hàng đích chưa ghi có -> Khách vào **Cài đặt -> Trung tâm trợ giúp -> Gửi ticket tra soát** kèm mã FT/TX, hệ thống tự động hoàn tiền trong tối đa 24 giờ. |
| **Không đọc được chip NFC CCCD** | Đặt sai vị trí chip hoặc ốp lưng dày | Tháo ốp lưng điện thoại, áp sát thẻ CCCD vào phần trên lưng máy (gần cụm camera đối với iPhone hoặc giữa lưng đối với Samsung), giữ yên 3-5 giây để hoàn tất đọc dữ liệu. |
| **Nghi ngờ tài khoản bị lộ thông tin** | Bị lừa click vào link lạ | Mở mục **Cài đặt bảo mật -> Gạt "Khóa tài khoản khẩn cấp"** để đóng băng tài khoản lập tức, sau đó gọi hotline 24/7 **1900-SENHONG** (1900 736 466) để được hỗ trợ. |

