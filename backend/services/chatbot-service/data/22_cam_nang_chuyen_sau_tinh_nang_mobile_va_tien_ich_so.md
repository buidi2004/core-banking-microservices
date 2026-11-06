# Cẩm Nang Chuyên Sâu Tính Năng Ứng Dụng Di Động Sen Hồng (Mobile Banking Guide)

Tài liệu này cung cấp toàn bộ hướng dẫn nghiệp vụ, kiến trúc màn hình, luồng thao tác và giải đáp thắc mắc chi tiết về ứng dụng di động **Sen Hồng Bank (Mobile App Flutter)** dành cho Trợ lý Trí tuệ Nhân tạo AI và đội ngũ Chăm sóc khách hàng.

---

## 1. Cấu Trúc Tổng Thể Ứng Dụng & Thiết Kế Giao Diện Liquid Glass

### A. 4 Phân Hệ Tab Chính Trên Thanh Điều Hướng (Bottom Navigation Bar)
Ứng dụng Sen Hồng được xây dựng theo phong cách thiết kế **Fintech Tier-1 Liquid Glass (Kính lỏng quang học)** với 4 Tab chính tại thanh Bottom Bar:
1. **Tab 1 - Trang Chủ (`/`):**
   - **Thẻ Tài Khoản Chính (Master Balance Card):** Hiển thị Số dư khả dụng, Số tài khoản, Trạng thái tài khoản (Đã eKYC / Đọc chip NFC QĐ 2345).
   - **Nút Bảo Mật Ẩn/Hiện Số Dư (Biểu tượng Con Mắt):** Khách hàng nhấn vào biểu tượng con mắt để ẩn số tiền khả dụng (hiển thị `****** VNĐ`) khi sử dụng ứng dụng nơi đông người hoặc chốn công cộng.
   - **Thanh Tác Vụ Nhanh (Quick Actions):** Chuyển tiền (`/transfer`), Nạp tiền (`/deposit`), Rút tiền (`/withdraw`), Quét QR (`/scan-qr`), Nạp ĐT (`/bills/phone-recharge`), Hóa đơn điện nước (`/bills`), Tiết kiệm (`/bills/savings`), Vay nhanh Quick Loan (`/bills/quick-loan`), Vé số Vietlott (`/bills/lottery`).
   - **Tiện Ích Đời Sống Số (Lifestyle Services):** Đặt vé máy bay (`/flight-booking`), Bảo hiểm xã hội (`/social-insurance`), Vua Xổ Số (`/vua-xo-so`), Nạp Data 4G/5G (`/data-topup`), Mua thẻ Game (`/game-cards`), Vận Số tài lộc, Xem tất cả dịch vụ (`/all-services`).
   - **Carousel Banner Ưu Đãi Tự Động:** Giới thiệu các gói hoàn tiền 50%, voucher thanh toán hóa đơn EVN, chương trình đối tác liên kết.
2. **Tab 2 - Quản Lý Thẻ (`/cards`):**
   - Quản trị toàn diện Thẻ ghi nợ nội địa Napas và Thẻ ảo quốc tế Visa Platinum Virtual.
   - Xem thông tin số thẻ 16 số, ngày hết hạn và mã bí mật CVV (yêu cầu xác thực bảo mật Face ID hoặc mã PIN để mở khóa hiển thị).
   - Công tắc **Khóa thẻ khẩn cấp (Card Freeze)** tức thì: Chỉ với 1 chạm, thẻ bị đóng băng ngay lập tức, vô hiệu hóa mọi thanh toán trực tuyến và tại quầy để phòng chống gian lận.
   - Cài đặt hạn mức chi tiêu thẻ ngày/giao dịch và bật/tắt thanh toán trực tuyến (E-commerce).
3. **Tab 3 - Kho Ưu Đãi & Voucher (`/promotions`):**
   - Phân loại khuyến mại theo danh mục: Mua sắm, Di chuyển (liên kết Xanh SM), Ẩm thực, Thanh toán hóa đơn sinh hoạt.
   - Lưu trữ và áp dụng voucher giảm giá tức thì khi thanh toán điện, nước, nạp tiền điện thoại.
4. **Tab 4 - Menu Tiện Ích Mở Rộng (`/more`):**
   - Trung tâm quản lý dịch vụ khách hàng, hồ sơ cá nhân, cài đặt bảo mật, danh bạ thụ hưởng, chuyển tiền quốc tế, chương trình giới thiệu bạn bè nhận thưởng và trung tâm trợ giúp khiếu nại.

### B. Chuẩn Mực Trải Nghiệm Người Dùng (Mobile UX/UI Standards)
- **Khoảng đệm an toàn đáy màn hình (Bottom Inset):** Toàn bộ danh sách cuộn (`ListView`, `CustomScrollView`) duy trì đệm đáy 110–120dp (`SizedBox(height: 110)`) đảm bảo thanh Liquid Glass Tab Bar không bao giờ che khuất nội dung hoặc nút bấm thao tác.
- **Typography Tài Chính Chuẩn Mực:** Kích hoạt tính năng số học căn gióng `FontFeature.tabularFigures()` trên tất cả trường số dư, số tiền và biến động giao dịch giúp các chữ số không bị giật dòng hay nhảy layout khi cập nhật thời gian thực.
- **Rung Phản Hồi Xúc Giác (Haptic Feedback):** Mỗi cú chạm nút chức năng, nhập phím số Custom PIN Numpad hay xác thực thành công đều kèm rung nhẹ tinh tế (`HapticFeedback.selectionClick()` / `HapticFeedback.lightImpact()`).

---

## 2. Phân Hệ Hóa Đơn & Tiện Ích Đa Dịch Vụ (`BillPaymentScreen` - Route: `/bills`)

Màn hình Thanh toán Hóa đơn (`/bills`) tích hợp hàng chục nhà cung cấp dịch vụ tiện ích trên cả nước, phân loại thành 3 nhóm lớn:

### A. Nhóm Dịch Vụ Thiết Yếu Hàng Ngày
1. **Tiền điện EVN toàn quốc:**
   - **Nhà cung cấp hỗ trợ:** EVN Hà Nội, EVN TP.HCM, EVN Miền Bắc, EVN Miền Trung, EVN Miền Nam.
   - **Cách thực hiện:** Vào mục `Hóa đơn` -> Chọn `Tiền điện` -> Chọn khu vực EVN -> Nhập **Mã khách hàng** (bắt đầu bằng chữ `PE`, ví dụ: `PE0100088921`) -> Hệ thống tự động truy vấn cổng EVN, hiển thị tên chủ hộ, địa chỉ và số tiền nợ cước -> Bấm `Thanh toán` bằng PIN/Face ID.
   - **Tự động trích nợ (Auto-Debit):** Bật công tắc "Tự động thanh toán khi có kỳ cước mới", hệ thống sẽ tự trích số dư ví đóng tiền đúng hạn mỗi tháng mà khách hàng không lo bị chậm nộp hay cắt điện.
2. **Tiền nước sinh hoạt:**
   - **Nhà cung cấp:** Cấp nước Sawaco TP.HCM, Viwaco Hà Nội, Nước sạch Huế, Biwase Bình Dương, Cấp nước Đà Nẵng, Hải Phòng...
   - **Cách thực hiện:** Chọn `Tiền nước` -> Chọn đơn vị cấp nước -> Nhập **Mã danh bạ** hoặc **Mã khách hàng** -> Kiểm tra thông tin hóa đơn và thanh toán.
3. **Internet cáp quang & Viễn thông cố định:**
   - Hỗ trợ toàn bộ các nhà mạng: **VNPT Telecom, FPT Telecom, Viettel Telecom**.
   - Nhập Mã hợp đồng internet (ví dụ: `HNI002941` của FPT hoặc mã thuê bao VNPT) -> Hiển thị cước tháng và đóng tiền tức thì.
4. **Truyền hình cáp & Kỹ thuật số:**
   - Hỗ trợ: **K+ (VSTV), VTVCab, FPT Play, ClipTV, Truyền hình Viettel**.
   - Thanh toán cước gia hạn hàng tháng hoặc mua các gói gói xem thể thao Ngoại hạng Anh đỉnh cao.
5. **Phí dịch vụ quản lý chung cư:**
   - Hỗ trợ cư dân thanh toán phí gửi xe, phí dịch vụ tòa nhà, phí duy tu chung cư kết nối trực tiếp với Ban quản trị/Ban quản lý các khu đô thị (Vinhomes, Masterise, Novaland, Đất Xanh, Ecopark...).

### B. Nhóm Dịch Vụ Tài Chính, Tín Dụng & Giao Thông
1. **Thanh toán khoản vay tiêu dùng:**
   - Hỗ trợ đối soát và đóng tiền trả góp hàng tháng cho các công ty tài chính tiêu dùng hàng đầu: **FE Credit, Home Credit, Shinhan Finance, Mirae Asset, MCredit, HD Saison**.
   - Khách hàng nhập Số hợp đồng vay hoặc CCCD -> Hệ thống tra cứu kỳ thanh toán hiện tại, dư nợ cần đóng và xác nhận thanh toán bảo mật.
2. **Dư nợ thẻ tín dụng:**
   - Thanh toán dư nợ sao kê hàng tháng cho thẻ tín dụng Visa/Mastercard của mọi ngân hàng nội địa Napas.
3. **Phí bảo hiểm:**
   - Đóng phí định kỳ bảo hiểm nhân thọ và phi nhân thọ cho **Bảo Việt, Prudential, Manulife, Dai-ichi Life, AIA, FWD, MB Ageas Life**.
4. **Thu phí giao thông không dừng ETC (VETC & ePass):**
   - Nạp tiền trực tiếp vào tài khoản giao thông VETC (Công ty VETC) hoặc ePass (Công ty VDTC - Viettel) bằng biển số xe hoặc mã tài khoản giao thông để lưu thông thông suốt qua các trạm BOT trên toàn quốc.

### C. Nhóm Dịch Vụ Công & Giáo Dục - Y Tế
1. **Nộp Thuế & Lệ phí trực tuyến:**
   - Nộp Thuế thu nhập cá nhân (TNCN), Thuế trước bạ xe ô tô/xe máy, Tiền phạt vi phạm giao thông kết nối trực tiếp qua Cổng Dịch vụ công Quốc gia (DVCQG) và Tổng cục Thuế.
   - Nhập Mã số thuế hoặc Mã hồ sơ kê khai -> Hoàn tất nộp ngân sách nhà nước, biên lai điện tử có giá trị pháp lý đầy đủ.
2. **Học phí SSC & Trường học:**
   - Thanh toán học phí các trường mầm non, tiểu học, THCS, THPT và các trường đại học thông qua mã học sinh/sinh viên trên hệ thống SSC (School Smart Card).
3. **Viện phí không dùng tiền mặt:**
   - Thanh toán tạm ứng viện phí, tiền khám chữa bệnh nội/ngoại trú tại các bệnh viện lớn (Bệnh viện Bạch Mai, Bệnh viện Chợ Rẫy, Đại học Y Dược, Bệnh viện K...) bằng mã bệnh nhân hoặc số hồ sơ bệnh án.
4. **Vé tàu hỏa & Xe khách liên tỉnh:**
   - Mua và thanh toán vé tàu Đường sắt Việt Nam (DSVN), vé xe khách Phương Trang (Futabus), Vexere nhận vé điện tử trực tiếp trên ứng dụng.

---

## 3. Phân Hệ Vay Tiêu Dùng Quick Loan & Lịch Trả Nợ (`QuickLoanScreen` & `LoanScheduleScreen`)

### A. Đăng Ký Vay Tiêu Dùng Quick Loan (`/bills/quick-loan`)
- **Đặc điểm nổi bật:** Vay tín chấp trực tuyến 100%, không cần tài sản thế chấp, không chứng minh thu nhập rườm rà. Hệ thống thẩm định và chấm điểm tín dụng tự động bằng AI siêu tốc trong vòng **1 phút**.
- **Hạn mức vay:** Linh hoạt từ **5.000.000 VNĐ** đến **50.000.000 VNĐ** (đối với khách hàng VIP hoặc thấu chi lương lên tới **100.000.000 VNĐ**).
- **Kỳ hạn vay trả góp:** Từ **3 tháng, 6 tháng, 12 tháng** đến **24 tháng**.
- **Lãi suất minh bạch:** Chỉ từ **1.2%/tháng** (tương đương 14.4%/năm) tính trên **Dư nợ giảm dần** (tiền lãi giảm dần theo từng kỳ sau khi đã trừ tiền gốc đã trả).
- **Công thức tính trả góp hàng tháng:**
  - Tiền gốc hàng tháng = Tổng số tiền vay / Số tháng vay.
  - Tiền lãi tháng đầu = Tổng số tiền vay × Lãi suất tháng (1.2%).
  - Tiền lãi các tháng tiếp theo = Dư nợ gốc còn lại × 1.2%.
  - Tổng số tiền phải nộp hàng tháng = Tiền gốc + Tiền lãi kỳ tương ứng.
- **Quy trình ký hợp đồng tín dụng số (Digital Loan Signing):**
  - Bước 1: Khách hàng kéo thanh trượt chọn Số tiền vay và Kỳ hạn vay mong muốn.
  - Bước 2: Xem trước bảng tính tiền gốc và lãi tạm tính.
  - Bước 3: Tích chọn "Đồng ý với điều khoản hợp đồng tín dụng Sen Hồng".
  - Bước 4: Nhấn `Tiếp tục` -> Mở Modal Ký hợp đồng số.
  - Bước 5: Nhập mã PIN giao dịch 6 số và mã xác thực Smart OTP/SMS để hoàn tất ký số.
  - Bước 6: Khoản vay được hệ thống tự động giải ngân và cộng trực tiếp vào số dư ví Sen Hồng sau 1 phút.

### B. Theo Dõi & Quản Lý Lịch Trả Nợ Khoản Vay (`/loan/schedule`)
- **Truy cập:** Mở App -> Vào mục `Vay nhanh` -> Bấm nút **Lịch trả nợ** (Route: `/loan/schedule`).
- **Thông tin hợp đồng:** Hiển thị Mã hợp đồng tín dụng (ví dụ: `HDTD-2026-88391`), Ngày giải ngân, Tổng số tiền vay, Số kỳ vay.
- **Bảng chi tiết các kỳ:** Danh sách từng kỳ (Kỳ 1 đến Kỳ N) bao gồm:
  - Ngày đến hạn nộp tiền (DueDate).
  - Số tiền gốc phải nộp.
  - Số tiền lãi phải nộp.
  - Tổng số tiền cần nộp kỳ đó.
  - Dư nợ gốc còn lại sau khi nộp.
  - Trạng thái kỳ thanh toán: `PAID` (Đã thanh toán thành công kèm ngày giờ), `DUE` (Đến hạn cần nộp ngay), `UPCOMING` (Kỳ sắp tới).
- **Tùy chọn Trả nợ tự động (Auto-Debit):** Cho phép bật tính năng tự động trích nợ từ số dư ví vào ngày đến hạn hàng tháng để khách hàng không bao giờ bị phát sinh nợ quá hạn hay ảnh hưởng điểm tín dụng CIC.
- **Tất toán khoản vay trước hạn (Early Settlement):**
  - Khách hàng có thể bấm nút **Tất toán toàn bộ khoản vay** bất kỳ lúc nào.
  - **Chính sách ưu đãi:** Sen Hồng Bank **miễn phí 100% phí phạt trả nợ trước hạn**, khách hàng chỉ cần thanh toán số dư gốc còn lại và tiền lãi tính đến ngày tất toán thực tế.

---

## 4. Phân Hệ Nạp ĐT & Gói Cước Data 4G (`PhoneRechargeScreen` & `PhoneTopupConfirmScreen` - Route: `/bills/phone-recharge`)

### A. Nạp Tiền Điện Thoại (Top-up Viễn Thông)
- **Kênh áp dụng:** Hỗ trợ mọi thuê bao di động trả trước và trả sau của cả 5 nhà mạng Việt Nam: **Viettel, VinaPhone, MobiFone, Vietnamobile, Wintel**.
- **Mệnh giá đa dạng:** 10.000đ, 20.000đ, 30.000đ, 50.000đ, 100.000đ, 200.000đ, 300.000đ, 500.000đ.
- **Đặc quyền chiết khấu trực tiếp:** Khách hàng được hưởng chiết khấu trực tiếp từ **3% đến 5%** ngay khi thanh toán (ví dụ: Nạp gói 100.000đ chỉ cần thanh toán 97.000đ từ ví).
- **Tính năng chọn từ Danh bạ điện thoại:** Nhấn biểu tượng danh bạ bên cạnh ô nhập SĐT để chọn người thân/bạn bè nhanh chóng, không lo gõ nhầm số.
- **Bảo mật thông tin thuê bao:** Trên màn hình xác nhận thanh toán (`PhoneTopupConfirmScreen`), hệ thống cung cấp công tắc **Ẩn số điện thoại** (hiển thị dạng `091****888`) để bảo mật thông tin cá nhân.
- **Xác thực bảo mật:** Sử dụng sinh trắc học Face ID/Vân tay hoặc mã PIN giao dịch để thanh toán, tiền vào tài khoản viễn thông chỉ sau 1–3 giây.

### B. Mua Gói Cước Data Di Động 4G/5G (`/data-topup`)
- **Gói ngày:** Phù hợp cho khách hàng đi du lịch, công tác ngắn hạn: 1GB/ngày (5.000đ), 2GB/ngày (10.000đ).
- **Gói tuần:** 7GB/7 ngày, 14GB/7 ngày tốc độ cao.
- **Gói tháng siêu ưu đãi:** 30GB/tháng (1GB/ngày), 60GB/tháng (2GB/ngày kèm miễn phí cước gọi nội mạng), 90GB/tháng.
- **Kích hoạt tự động:** Gói cước data được nhà mạng kích hoạt tức thì ngay sau khi trừ tiền ví thành công.

---

## 5. Phân Hệ Quản Lý Thẻ & Tài Khoản Ngân Hàng Liên Kết (`/cards`, `/bank-cards`, `/lucky-account`)

### A. Quản Lý Thẻ Sen Hồng Platinum (`/cards`)
- **Thẻ ghi nợ Napas & Thẻ ảo Visa Platinum Virtual:** Tích hợp trực tiếp trên ứng dụng, sẵn sàng thanh toán online không biên giới tại các trang thương mại điện tử (Shopee, Lazada, Tiki, Amazon, Netflix, Spotify...).
- **Bảo mật thông tin thẻ:** Để phòng ngừa quay lén hoặc chụp trộm màn hình, các thông tin nhạy cảm (16 số thẻ, Ngày hết hạn MM/YY, 3 số bảo mật CVV) đều được mã hóa bằng dấu hoa thị `••••`. Khách hàng phải bấm vào biểu tượng con mắt và xác thực Face ID/PIN mới có thể xem các chữ số thực.
- **Công tắc Khóa thẻ 1 chạm (Card Freeze):** Khi nghi ngờ thẻ bị lộ hoặc rơi mất, khách hàng mở mục Thẻ và gạt nút "Khóa thẻ khẩn cấp". Thẻ sẽ bị vô hiệu hóa tức thì trên toàn bộ hệ thống Visa/Mastercard/Napas trong vòng chưa đầy 1 giây. Khi tìm lại được thẻ, khách hàng có thể mở khóa lại ngay trên app mà không cần ra quầy ngân hàng.

### B. Liên Kết Thẻ & Tài Khoản Ngân Hàng Napas (`/bank-cards`)
- **Hơn 40 ngân hàng đối tác:** Vietcombank, VietinBank, BIDV, Agribank, Techcombank, MB Bank, ACB, VPBank, TPBank, Sacombank, VIB, HDBank, OCB, MSB, SeABank, Shinhan Bank...
- **Quy trình liên kết tài khoản:**
  - Bước 1: Mở mục `Thẻ & Ngân hàng liên kết` (Route: `/bank-cards`).
  - Bước 2: Nhấn nút `Thêm liên kết mới (+)` và chọn ngân hàng phát hành.
  - Bước 3: Nhập Số tài khoản hoặc Số thẻ ngân hàng chính chủ.
  - Bước 4: Nhập mã xác thực OTP gửi từ ngân hàng để hoàn tất liên kết.
- **Lợi ích:** Nạp tiền vào ví và rút tiền về ngân hàng 24/7 hoàn toàn miễn phí, xử lý giao dịch tức thì trong vòng 30 giây.

### C. Mở Tài Khoản Số Đẹp Phong Thủy (`/lucky-account`)
- Khách hàng có thể tự do tìm kiếm và mở tài khoản số đẹp theo sở thích:
  - Số ngày tháng năm sinh nhật (ví dụ: `ddmmyyyy`).
  - Số phong thủy tài lộc: Tứ quý (`6666`, `8888`, `9999`), Thần tài (`3979`), Lộc phát (`6886`), Tam hoa, Sảnh tiến (`123456`).
- Kích hoạt tài khoản số đẹp online ngay trên ứng dụng, dùng để nhận chuyển tiền liên ngân hàng 24/7.

---

## 6. Phân Hệ Chuyển Tiền, Quét VietQR & Chia Tiền Nhóm

### A. Chuyển Tiền Miễn Phí 24/7 (`/transfer`)
- **Chuyển tiền nội bộ Sen Hồng:** Chuyển tiền qua Số điện thoại hoặc Số tài khoản Sen Hồng. Thời gian nhận tiền sau **1 giây**, hoàn toàn miễn phí 100%.
- **Chuyển tiền liên ngân hàng Napas 247:** Chuyển tiền đến hơn 50 ngân hàng tại Việt Nam. Hệ thống tự động truy vấn tên người nhận theo thời gian thực để đối soát trước khi chuyển. Miễn phí 100% mọi giao dịch, hoạt động 24/7 kể cả ban đêm và dịp lễ tết.
- **Đặt lịch chuyển tiền định kỳ:** Cho phép đặt lệnh chuyển tiền lặp lại hàng tuần hoặc hàng tháng (ví dụ: trả tiền thuê nhà vào ngày mùng 05 hàng tháng). Đến ngày hẹn, hệ thống tự động trích nợ chuyển tiền đúng hạn.

### B. Thanh Toán & Nhận Tiền Bằng Chuẩn VietQR (`/scan-qr` & `/my-qr`)
- **Quét mã QR (`/scan-qr`):** Quét mã QR thanh toán tại các cửa hàng tiện lợi, siêu thị, nhà hàng hoặc mã chuyển khoản cá nhân. Hỗ trợ chọn ảnh mã QR từ thư viện ảnh điện thoại.
- **Mã QR của tôi (`/my-qr`):** Hiển thị mã VietQR tiêu chuẩn quốc gia có gắn sẵn Số tài khoản và Tên chủ tài khoản Sen Hồng. Có thể nhập số tiền cụ thể vào mã QR, tải ảnh mã QR lưu vào máy hoặc chia sẻ qua Zalo, Messenger.

### C. Chia Tiền Nhóm Văn Minh (Split Bill - `/transfer/request`)
- Sau bữa ăn hoặc chuyến du lịch cùng bạn bè, khách hàng chỉ cần mở tính năng Chia tiền, nhập tổng số tiền hóa đơn và chọn danh sách bạn bè cùng tham gia.
- Hệ thống tự động tính số tiền chia đều cho mỗi người (hoặc tùy chỉnh số tiền theo ý muốn), sau đó tạo link yêu cầu chuyển tiền kèm mã VietQR gửi đến bạn bè. Bạn bè chỉ cần 1 chạm trên ứng dụng Sen Hồng để thanh toán phần tiền của mình.

### D. Chuyển Tiền Quốc Tế & Kiều Hối (`/international-transfer`)
- Hỗ trợ nhận kiều hối từ nước ngoài chuyển về Việt Nam và chuyển tiền ngoại tệ ra nước ngoài (du học, trợ cấp thân nhân, chữa bệnh) theo đúng quy định quản lý ngoại hối của Ngân hàng Nhà nước thông qua mạng lưới viễn thông tài chính quốc tế SWIFT Code.

---

## 7. Phân Hệ Xác Thực, eKYC & An Ninh Tài Khoản Nâng Cao

### A. Quy Trình Khôi Phục Mật Khẩu Đăng Nhập (`/auth/forgot-password`)
- **Khi nào áp dụng:** Khách hàng không nhớ mật khẩu đăng nhập tài khoản ứng dụng.
- **Các bước thao tác:**
  - Bước 1: Tại màn hình Đăng nhập, bấm vào dòng chữ **"Quên mật khẩu?"** (hoặc truy cập `/auth/forgot-password`).
  - Bước 2: Nhập Số điện thoại đã đăng ký tài khoản Sen Hồng.
  - Bước 3: Nhập mã xác thực OTP gửi về số điện thoại qua tin nhắn SMS hoặc Smart OTP.
  - Bước 4: Thực hiện xác thực khuôn mặt sinh trắc học eKYC (đối chiếu dữ liệu sống Liveness Detection với CCCD gắn chip).
  - Bước 5: Thiết lập Mật khẩu mới (tối thiểu 8 ký tự, bao gồm chữ in hoa, chữ thường và chữ số). Sau khi đổi thành công, tài khoản sẵn sàng đăng nhập lại tức thì.

### B. Quy Trình Khôi Phục Mã PIN Giao Dịch (`/auth/forgot-pin`)
- **Khi nào áp dụng:** Khách hàng quên mã PIN 6 số dùng để xác nhận chuyển tiền/thanh toán hóa đơn.
- **Các bước thao tác:**
  - Bước 1: Tại màn hình yêu cầu nhập mã PIN giao dịch, bấm vào dòng chữ **"Quên mã PIN?"** (hoặc mở `/auth/forgot-pin`).
  - Bước 2: Nhập mã xác thực OTP gửi về điện thoại chính chủ.
  - Bước 3: Xác thực sinh trắc học khuôn mặt để chứng minh chính chủ tài khoản.
  - Bước 4: Thiết lập Mã PIN 6 số mới và nhập lại lần 2 để xác nhận. Mã PIN mới có hiệu lực ngay lập tức.

### C. Đổi Mã PIN Giao Dịch Chủ Động (`/settings/change-pin`)
- **Khi nào áp dụng:** Khách hàng vẫn nhớ mã PIN cũ nhưng muốn đổi định kỳ để tăng cường bảo mật.
- **Thao tác:** Vào `Cài đặt` -> Chọn `Đổi mã PIN` -> Nhập mã PIN hiện tại (6 số) -> Nhập mã PIN mới 2 lần để hoàn tất.

### D. Quản Lý Thiết Bị Đăng Nhập & Đăng Xuất Từ Xa (`/settings/devices`)
- **Tính năng an ninh:** Hiển thị danh sách toàn bộ các dòng máy điện thoại hoặc máy tính bảng đang đăng nhập tài khoản (kèm Tên dòng máy iPhone/Samsung, Phiên bản hệ điều hành iOS/Android, Địa chỉ IP đăng nhập và Thời gian hoạt động gần nhất).
- **Hủy phiên từ xa (Remote Session Logout):** Khi bị thất lạc điện thoại hoặc nghi ngờ có thiết bị lạ đăng nhập, khách hàng chỉ cần bấm nút **"Đăng xuất khỏi thiết bị này"**. Thiết bị đó sẽ bị hủy phiên (Revoke Token) tức khắc, bị văng ra màn hình đăng nhập và không thể thực hiện bất kỳ giao dịch nào.

### E. Đọc Chip NFC Thẻ CCCD Theo Quyết Định 2345/QĐ-NHNN (`/profile/nfc-reader`)
- **Quy định pháp lý NHNN:** Bắt buộc áp dụng đối với mọi giao dịch chuyển tiền trên **10.000.000 VNĐ/giao dịch** hoặc tổng số tiền giao dịch tích lũy trong ngày vượt quá **20.000.000 VNĐ/ngày**.
- **Cách thực hiện trên ứng dụng:**
  - Bước 1: Mở mục `Cài đặt` -> Chọn `Sinh trắc học / Đọc NFC CCCD` (Route: `/profile/nfc-reader`).
  - Bước 2: Áp sát mặt sau điện thoại (vùng ăng-ten NFC) vào vị trí chip kim loại trên thẻ CCCD. Giữ cố định điện thoại trong 3 đến 5 giây để máy đọc dữ liệu mã hóa ICAO trên chip.
  - Bước 3: Quét nhận diện khuôn mặt 3D để đối chiếu dữ liệu với ảnh gốc lưu trên chip CCCD do Bộ Công An cấp.
  - Bước 4: Sau khi xác thực thành công, hạn mức chuyển tiền trực tuyến được nâng lên tới **500.000.000 VNĐ/ngày**.

### F. Chữ Ký Số Smart OTP Tích Hợp (`/profile/digital-signature`)
- **Phương thức bảo mật đỉnh cao:** Thay thế hoàn toàn mã xác thực SMS OTP truyền thống dễ bị tấn công qua SIM rác hoặc phần mềm gián điệp viễn thông.
- Mã Smart OTP tự sinh trực tiếp trên ứng dụng theo thuật toán mã hóa bất đối xứng mà không cần kết nối mạng viễn thông hay sóng di động, hoạt động trơn tru ngay cả khi khách hàng đang ở nước ngoài.
- Nâng hạn mức chuyển tiền và giao dịch doanh nghiệp lên tới **1.000.000.000 VNĐ/ngày**.

### G. Khóa Tài Khoản Khẩn Cấp (Emergency Kill-Switch)
- Nằm trong mục `Cài đặt bảo mật` (`/settings/security`). Khi khách hàng phát hiện dấu hiệu bị lừa đảo chiếm đoạt tài sản hoặc bị đe dọa, gạt nút **"Khóa tài khoản khẩn cấp"** sẽ lập tức kích hoạt cơ chế bảo vệ tối cao:
  - Khóa toàn bộ các phiên đăng nhập trên mọi thiết bị.
  - Đóng băng toàn bộ số dư và tạm ngưng mọi giao dịch chuyển tiền/rút tiền đi.
  - Muốn mở khóa lại, khách hàng bắt buộc phải xác thực sinh trắc học eKYC hoặc ra phòng giao dịch ngân hàng để đối soát trực tiếp.

---

## 8. Bảng Tra Cứu Nhanh Đường Dẫn (Route Mapping) Dành Cho Mobile Flutter

| Tên Tính Năng Trên Ứng Dụng | Đường Dẫn Điều Hướng (Route) | Tên Màn Hình Flutter | Mục Đích Sử Dụng |
| :--- | :--- | :--- | :--- |
| **Trang chủ ngân hàng** | `/` | `HomeScreen` | Xem số dư, danh sách tiện ích, carousel banner ưu đãi |
| **Lấy lại mật khẩu đăng nhập** | `/auth/forgot-password` | `ForgotPasswordScreen` | Khôi phục mật khẩu khi quên bằng OTP + eKYC |
| **Lấy lại mã PIN giao dịch** | `/auth/forgot-pin` | `ForgotPinScreen` | Cấp lại mã PIN 6 số bị quên |
| **Đổi mã PIN giao dịch** | `/settings/change-pin` | `ChangePinScreen` | Thay đổi mã PIN định kỳ bảo mật |
| **Thanh toán hóa đơn** | `/bills` | `BillPaymentScreen` | Đóng tiền điện EVN, nước, internet, chung cư, ETC |
| **Nạp tiền điện thoại** | `/bills/phone-recharge` | `PhoneRechargeScreen` | Nạp tiền ĐT chiết khấu 3-5%, mua mã thẻ |
| **Xác nhận nạp điện thoại** | `/bills/phone-recharge/confirm` | `PhoneTopupConfirmScreen` | Xem chiết khấu, ẩn SĐT và xác thực PIN |
| **Vay nhanh Quick Loan** | `/bills/quick-loan` | `QuickLoanScreen` | Đăng ký vay tín chấp từ 5-50 triệu trong 1 phút |
| **Lịch trả nợ khoản vay** | `/loan/schedule` | `LoanScheduleScreen` | Bảng kê gốc, lãi, dư nợ giảm dần từng kỳ |
| **Mở sổ tiết kiệm online** | `/bills/savings` | `SavingsScreen` | Gửi tiết kiệm kỳ hạn 1-24 tháng (lãi tới 6.8%/năm) |
| **Chi tiết & Tất toán sổ tiết kiệm** | `/savings/detail` | `SavingsDetailScreen` | Xem lãi tạm tính, tất toán trước hạn về ví |
| **Quản lý thẻ Sen Hồng** | `/cards` | `CardsScreen` | Xem 16 số thẻ, mã CVV, công tắc Khóa thẻ khẩn cấp |
| **Thẻ & Ngân hàng liên kết** | `/bank-cards` | `BankCardsScreen` | Liên kết tài khoản Napas 40+ ngân hàng nạp rút 24/7 |
| **Tài khoản số đẹp** | `/lucky-account` | `LuckyAccountScreen` | Mở tài khoản ngày sinh, tứ quý, thần tài |
| **Chuyển tiền nhanh 24/7** | `/transfer` | `ChooseRecipientScreen` | Chuyển nội bộ 1s và Napas 24/7 miễn phí |
| **Quét mã QR chuyển tiền** | `/scan-qr` | `ScanQrScreen` | Quét mã VietQR camera hoặc từ thư viện ảnh |
| **Mã QR của tôi** | `/my-qr` | `MyQrScreen` | Hiển thị mã VietQR nhận tiền chính chủ |
| **Chia tiền nhóm Split Bill** | `/transfer/request` | `RequestTransferScreen` | Chia tiền ăn uống, du lịch gửi link mã QR |
| **Danh bạ thụ hưởng** | `/beneficiaries` | `BeneficiariesScreen` | Quản lý tài khoản ngân hàng thường xuyên gửi |
| **Chuyển tiền quốc tế SWIFT** | `/international-transfer` | `InternationalTransferScreen`| Nhận kiều hối và chuyển tiền du học, trợ cấp |
| **Mua vé số Vietlott** | `/bills/lottery` | `LotteryScreen` | Mua vé Mega, Power, Keno; trúng thưởng tự vào ví |
| **Đặt vé máy bay** | `/flight-booking` | `FlightBookingScreen` | Đặt vé Vietnam Airlines, Vietjet, Bamboo |
| **Nộp Bảo hiểm xã hội** | `/social-insurance` | `SocialInsuranceScreen` | Nộp BHXH tự nguyện và BHYT cổng quốc gia |
| **Nạp Data 4G/5G** | `/data-topup` | `DataTopupScreen` | Mua dung lượng data ngày, tuần, tháng |
| **Quản lý thiết bị đăng nhập** | `/settings/devices` | `DeviceManagementScreen` | Xem dòng máy đăng nhập và hủy phiên từ xa |
| **Đọc chip NFC CCCD (QĐ 2345)**| `/profile/nfc-reader` | `NfcReaderScreen` | Áp thẻ CCCD đọc chip nâng hạn mức chuyển tiền |
| **Chữ ký số Smart OTP** | `/profile/digital-signature` | `DigitalSignatureScreen` | Đăng ký Soft OTP nâng hạn mức lên 1 tỷ/ngày |
| **Cài đặt Email nhận sao kê** | `/profile/email-settings` | `EmailSettingsScreen` | Nhận file PDF sao kê có chữ ký số ngày 01 hàng tháng |
| **Cài đặt thông báo OTT** | `/notifications/settings` | `NotificationSettingsScreen`| Tùy chỉnh nhận thông báo biến động số dư tức thì |
| **Trung tâm trợ giúp CSKH** | `/support/help-center` | `HelpCenterScreen` | Gửi yêu cầu tra soát giao dịch, khiếu nại |
| **Trò chuyện Trợ lý AI 24/7** | `/support/live-chat` | `LiveChatScreen` | Chat trực tiếp với AI thông minh giải đáp mọi nghiệp vụ |

