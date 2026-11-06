# Cẩm Nang Tra Cứu Toàn Diện Các Màn Hình và Tính Năng trên Ứng Dụng Sen Hồng

## 1. Cấu trúc 4 Tab chính trên Thanh điều hướng (Bottom Bar)
Thanh điều hướng Liquid Glass phong cách Fintech cao cấp phía dưới màn hình gồm 4 phân hệ chính:
- **Tab 1 - Trang chủ (`/`):**
  - Hiển thị Lời chào cá nhân hóa, Tên chủ tài khoản, Số tài khoản và Số dư khả dụng (kèm nút biểu tượng con mắt để ẩn/hiện số dư bảo mật nơi công cộng).
  - Vùng hành động tài chính nhanh (Quick Actions): Chuyển tiền, Nạp tiền, Rút tiền, Quét QR, Nạp tiền điện thoại, Thanh toán điện nước, Tiết kiệm online, Vay tiêu dùng Quick Loan, Mua vé Vietlott.
  - Vùng Tiện ích sống & Giải trí số (Lifestyle): Vua Xổ Số, Vé số Vietlott, Nạp Data 4G/5G, Đặt vé máy bay trực tuyến (Vietnam Airlines, Vietjet Air, Bamboo), Thẻ nạp game, Vận Số chiêm tinh tài lộc, Xem tất cả dịch vụ.
  - Khung Carousel Banner ưu đãi tự động cuộn hiển thị các chương trình hoàn tiền 50%, voucher giảm giá hóa đơn và đặc quyền thẻ Visa.
- **Tab 2 - Thẻ (`/cards`):**
  - Quản lý thẻ ghi nợ nội địa Napas và Thẻ ảo quốc tế Visa Platinum Virtual.
  - Tính năng: Xem số thẻ 16 số, ngày hết hạn, mã bảo mật CVV (yêu cầu xác thực sinh trắc học/mã PIN để hiển thị).
  - Công tắc Khóa thẻ khẩn cấp (Card Freeze) tức thì 1 chạm khi nghi ngờ mất thẻ hoặc rò rỉ thông tin.
  - Cài đặt hạn mức thanh toán trực tuyến trong nước và quốc tế.
- **Tab 3 - Ưu đãi (`/promotions`):**
  - Kho Voucher giảm giá, mã khuyến mại thanh toán tiền điện EVN, tiền nước Sawaco, nạp data 4G và quà tặng từ các đối tác liên kết (Ẩm thực, Mua sắm, Du lịch, Di chuyển).
  - Phân loại ưu đãi theo danh mục: Mua sắm, Xe cộ, Sự kiện, Trả góp 0% lãi suất.
- **Tab 4 - Xem thêm / Menu Tiện ích tổng hợp (`/more`):**
  - Trung tâm quản lý toàn bộ hệ sinh thái dịch vụ ngân hàng, tài chính cá nhân, quản lý tài khoản, pháp lý, giới thiệu bạn bè và trung tâm hỗ trợ CSKH.

---

## 2. Bảng Hướng dẫn Thao tác và Điều hướng Chi tiết từng Tính năng

### A. Phân hệ Chuyển tiền & Thanh toán QR
- **Chuyển tiền nội bộ Sen Hồng:** Trang chủ -> Nhấn nút "Chuyển tiền" -> Chọn tab "Nội bộ" -> Nhập SĐT hoặc STK người nhận tại Sen Hồng -> Nhập số tiền -> Nhập mã PIN/Face ID (Route: `/transfer`). Hoàn toàn miễn phí 100%, tiền nhận sau 1 giây.
- **Chuyển tiền liên ngân hàng 24/7 (Napas 247):** Trang chủ -> "Chuyển tiền" -> Chọn tab "Liên ngân hàng" -> Chọn Ngân hàng nhận -> Nhập số tài khoản -> Kiểm tra tên người nhận tự động -> Bấm "Tiếp tục" và xác thực PIN/Sinh trắc học (Route: `/transfer`). Miễn phí chuyển khoản 24/7 kể cả ngày nghỉ/lễ tết.
- **Quét mã VietQR chuyển tiền:** Góc trên bên phải Trang chủ -> Bấm biểu tượng "Quét QR" -> Hướng camera về mã QR người nhận hoặc chọn ảnh QR từ thư viện ảnh -> Hệ thống tự điền thông tin và chuyển khoản tức thì (Route: `/scan-qr`).
- **Mã QR của tôi (Nhận tiền nhanh):** Trang chủ -> Bấm biểu tượng "Mã QR của tôi" -> Hiển thị mã VietQR tiêu chuẩn quốc gia có gắn số tài khoản và tên chủ tài khoản Sen Hồng, có thể lưu ảnh QR hoặc chia sẻ qua Zalo/Tin nhắn (Route: `/my-qr`).
- **Chia tiền nhóm / Yêu cầu chuyển tiền (Split Bill):** Chuyển tiền -> Chọn tab "Yêu cầu / Chia tiền" -> Nhập tổng số tiền hóa đơn, chọn danh sách bạn bè cần chia đều hoặc chia theo tỷ lệ -> Hệ thống tự tạo link chia tiền kèm mã VietQR gửi đến bạn bè (Route: `/transfer/request`).
- **Danh bạ thụ hưởng đã lưu:** Chuyển tiền -> Bấm biểu tượng "Danh bạ" góc trên -> Quản lý, tìm kiếm hoặc xóa các tài khoản ngân hàng thụ hưởng thường xuyên giao dịch (Route: `/beneficiaries`).
- **Chuyển tiền quốc tế & Kiều hối:** Menu Xem thêm -> Nhấn "Chuyển tiền quốc tế" -> Hỗ trợ nhận kiều hối qua SWIFT code và chuyển ngoại tệ an toàn theo quy định NHNN (Route: `/international-transfer`).
- **Đặt lịch chuyển tiền định kỳ:** Chuyển tiền -> Bật tùy chọn "Đặt lịch định kỳ" -> Chọn ngày lặp lại hàng tháng (ví dụ ngày 05 hàng tháng trả tiền nhà) -> Hệ thống tự động trích nợ chuyển tiền đúng hạn.

---

### B. Phân hệ Nạp tiền, Rút tiền & Tiền mặt
- **Nạp tiền vào ví từ ngân hàng liên kết:** Trang chủ -> Nhấn nút "Nạp tiền" -> Chọn số tiền muốn nạp (50.000đ, 100.000đ, 500.000đ, 2.000.000đ hoặc tự nhập) -> Chọn nguồn tiền từ ngân hàng liên kết (Vietcombank, BIDV, Techcombank...) -> Xác thực PIN (Route: `/deposit`). Tiền vào số dư ngay lập tức, miễn phí nạp.
- **Rút tiền từ ví về tài khoản ngân hàng:** Trang chủ -> Nhấn nút "Rút tiền" -> Nhập số tiền cần rút -> Chọn tài khoản ngân hàng chính chủ -> Xác thực sinh trắc học/PIN (Route: `/withdraw`). Tiền về tài khoản ngân hàng trong vòng 30 giây.
- **Rút tiền tại ATM không cần thẻ vật lý:** Trang chủ -> Nhấn "Rút tiền ATM" -> Chọn số tiền rút trên ứng dụng -> Ứng dụng cấp Mã rút tiền 6 số bảo mật có hiệu lực trong 15 phút -> Khách hàng đến bất kỳ cây ATM của Sen Hồng hoặc liên minh Napas, chọn "Rút tiền không cần thẻ" -> Nhập mã rút tiền và xác nhận OTP trên điện thoại để nhận tiền mặt (Route: `/atm-withdrawal`).

---

### C. Phân hệ Hóa đơn, Tiện ích & Nạp điện thoại
- **Thanh toán tiền điện EVN:** Trang chủ -> Nhấn "Điện nước" hoặc "Hóa đơn" -> Chọn "Tiền điện" -> Chọn nhà cung cấp (EVN Miền Bắc, EVN Miền Trung, EVN Miền Nam, EVN Hà Nội, EVN TP.HCM) -> Nhập Mã khách hàng (bắt đầu bằng chữ P) -> Kiểm tra số tiền nợ cước -> Bấm thanh toán (Route: `/bills`). Hỗ trợ lưu mã để tự động thông báo khi có hóa đơn mới.
- **Thanh toán tiền nước sinh hoạt:** Trang chủ -> "Hóa đơn" -> Chọn "Tiền nước" -> Chọn công ty cấp nước (Sawaco, Viwaco, Biwase...) -> Nhập Mã danh bạ/Mã khách hàng -> Bấm thanh toán (Route: `/bills`).
- **Nạp tiền điện thoại trả trước (Top-up):** Trang chủ -> Nhấn "Nạp ĐT" -> Nhập số điện thoại cần nạp (hoặc chọn từ danh bạ điện thoại) -> Chọn mệnh giá từ 10.000đ đến 500.000đ (hưởng chiết khấu trực tiếp tới 3-5%) -> Bấm "Nạp ngay" (Route: `/bills/phone-recharge`). Hỗ trợ tất cả nhà mạng Viettel, VinaPhone, MobiFone, Vietnamobile, Wintel.
- **Nạp gói cước Data 3G/4G/5G:** Trang chủ -> Nhấn "Data 4G/5G" -> Chọn gói ngày (1GB/ngày), gói tuần hoặc gói tháng (30GB - 60GB) -> Bấm kích hoạt tức thì (Route: `/data-topup`).
- **Mua thẻ game trực tuyến:** Trang chủ -> Tiện ích -> Chọn "Thẻ Game" -> Chọn loại thẻ Garena, Zing Xu, VTC Vcoin, Gate -> Chọn mệnh giá và nhận mã thẻ + số serial ngay trên màn hình và gửi về email (Route: `/game-cards`).
- **Đóng Bảo hiểm xã hội tự nguyện & BHYT:** Trang chủ -> Tiện ích -> Nhấn "Bảo hiểm xã hội" -> Nhập mã số BHXH/BHYT -> Hệ thống kết nối cổng dữ liệu bảo hiểm quốc gia và hoàn tất đóng phí điện tử (Route: `/social-insurance`).
- **Đặt vé máy bay & Khách sạn số:** Trang chủ -> Tiện ích -> Nhấn "Đặt vé máy bay" -> Tìm kiếm chuyến bay theo ngày bay, điểm đi/đến -> Chọn hãng bay và giờ bay ưng ý -> Thanh toán trực tiếp từ số dư ví Sen Hồng và nhận mã đặt chỗ điện tử (Route: `/flight-booking`, `/digital-flight`).
- **Mua vé số điện toán Vietlott & Vua Xổ Số:** Trang chủ -> Nhấn "Vietlott" hoặc "Vua Xổ Số" -> Chọn loại hình: Power 6/55, Mega 6/45, Max 3D Pro hoặc Keno (quay thưởng 5 phút/lần) -> Chọn số thủ công hoặc bấm "Máy tự chọn" -> Xác nhận mua vé chính thống qua đối tác cấp phép -> Trúng thưởng dưới 10 tỷ VNĐ được trả thưởng trực tiếp vào số dư ví sau giờ quay thưởng (Route: `/bills/lottery`, `/vietlott`, `/vua-xo-so`).

---

### D. Phân hệ Tài chính Sinh lời & Tín dụng
- **Mở sổ tiết kiệm trực tuyến (Core Savings):** Trang chủ -> Nhấn "Tiết kiệm" -> Nhập số tiền gửi (tối thiểu từ 1.000.000đ) -> Chọn kỳ hạn (1 tháng, 3 tháng, 6 tháng: 5.5%/năm, 12 tháng: 6.8%/năm, 24 tháng: 7.2%/năm) -> Chọn phương thức đáo hạn: Tự động tất toán về ví hoặc Quay vòng gốc/lãi -> Xác nhận mở sổ (Route: `/bills/savings`). Sổ tiết kiệm điện tử có giá trị pháp lý tương đương sổ giấy tại quầy.
- **Xem chi tiết & Tất toán sổ tiết kiệm:** Vào mục Tiết kiệm -> Nhấn vào cuốn sổ đang hoạt động -> Xem tiền lãi tạm tính hàng ngày, ngày đáo hạn -> Bấm "Tất toán sổ tiết kiệm" nếu cần rút tiền về số dư ví trước hạn (lãi suất rút trước hạn tính theo lãi không kỳ hạn 0.2%/năm theo Thông tư 04/2022/TT-NHNN) (Route: `/savings/detail`).
- **Vay tiêu dùng tín chấp trực tuyến (Quick Loan):** Trang chủ -> Nhấn "Vay nhanh" -> Đăng ký hạn mức vay từ 10.000.000đ đến 100.000.000đ -> Chọn thời gian trả góp từ 6 đến 36 tháng -> Hệ thống chấm điểm tín dụng tự động qua AI và giải ngân trực tiếp vào tài khoản chỉ sau 15 phút không cần thế chấp tài sản (Route: `/bills/quick-loan`).
- **Xem lịch trả nợ vay (Loan Schedule):** Vào mục Vay nhanh -> Nhấn "Lịch trả nợ" -> Xem bảng chi tiết ngày thanh toán định kỳ hàng tháng, số tiền gốc, tiền lãi và dư nợ giảm dần (Route: `/loan/schedule`).
- **Mở tài khoản Số Đẹp phong thủy:** Menu Xem thêm -> Nhấn "Chọn số tài khoản đẹp" -> Tra cứu theo ngày sinh nhật, tứ quý, thần tài, lộc phát -> Chọn số yêu thích và kích hoạt tức thì (Route: `/lucky-account`).

---

### E. Phân hệ Hồ sơ, eKYC & Bảo mật nâng cao
- **Định danh điện tử eKYC Cấp độ 2:** Hồ sơ cá nhân -> Cấp độ định danh -> Bấm "Định danh ngay" -> Chụp mặt trước và mặt sau CCCD gắn chip -> Quét khuôn mặt 3D Liveness -> Nâng hạn mức giao dịch lên 100.000.000đ/ngày (Route: `/profile/ekyc`, `/profile/kyc-level`).
- **Đọc chip NFC CCCD theo Quyết định 2345/QĐ-NHNN:** Cài đặt -> Nhấn "Sinh trắc học / Đọc NFC" -> Áp mặt sau điện thoại có hỗ trợ NFC vào vị trí chip trên thẻ CCCD để đọc thông tin bảo mật và đối chiếu dữ liệu Bộ Công An -> Kích hoạt hạn mức giao dịch trên 10 triệu đồng/giao dịch hoặc trên 20 triệu đồng/ngày (Route: `/profile/nfc-reader`).
- **Kích hoạt Chữ ký số Smart OTP:** Cài đặt -> Bảo mật -> Chữ ký số Smart OTP -> Đăng ký chữ ký số tích hợp, nâng hạn mức giao dịch lên 500.000.000đ - 1.000.000.000đ/ngày (Route: `/profile/digital-signature`).
- **Đổi mã PIN giao dịch 6 số:** Cài đặt -> Nhấn "Đổi mã PIN" -> Nhập mã PIN hiện tại -> Nhập mã PIN mới 2 lần để xác nhận (Route: `/settings/change-pin`).
- **Quản lý thiết bị đăng nhập & Hủy phiên từ xa:** Cài đặt -> Nhấn "Quản lý thiết bị" -> Xem danh sách điện thoại đang đăng nhập tài khoản (tên dòng máy, hệ điều hành, địa chỉ IP, thời gian hoạt động cuối) -> Bấm nút "Đăng xuất thiết bị này" để ngắt kết nối phiên lạ ngay lập tức (Route: `/settings/devices`).
- **Khóa tài khoản khẩn cấp (Emergency Kill-Switch):** Cài đặt -> Cài đặt bảo mật -> Gạt công tắc "Khóa tài khoản khẩn cấp" -> Hệ thống lập tức vô hiệu hóa mọi phiên đăng nhập, đóng băng mọi giao dịch rút tiền và chuyển tiền để bảo toàn tài sản tuyệt đối.
- **Cài đặt Email nhận sao kê điện tử:** Cài đặt -> Hồ sơ -> Cài đặt Email -> Nhập địa chỉ email chính chủ -> Định kỳ ngày mùng 01 hàng tháng ngân hàng sẽ tự động gửi bản sao kê có chữ ký số điện tử của Tổng giám đốc Sen Hồng Bank (Route: `/profile/email-settings`).
- **Cài đặt thông báo (Notifications):** Cài đặt -> Cài đặt thông báo -> Bật/tắt thông báo OTT biến động số dư, tin khuyến mại ưu đãi, thông báo biến động thị trường (Route: `/notifications/settings`).
- **Trung tâm trợ giúp & Tra soát giao dịch:** Cài đặt -> Trung tâm trợ giúp -> Gửi ticket tra soát khi giao dịch chuyển tiền bị treo hoặc nạp tiền chưa vào tài khoản (Route: `/support/help-center`).
- **Trò chuyện với Trợ lý AI Tài chính Sen Hồng 24/7:** Bấm biểu tượng bóng ma 3D ở góc phải Trang chủ hoặc thanh tìm kiếm, hoặc truy cập CSKH -> Hỗ trợ giải đáp nghiệp vụ, tra cứu số dư và lịch sử giao dịch tự động 24/7 (Route: `/support/live-chat`).
