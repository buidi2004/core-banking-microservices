# Quy Chuẩn Xác Thực Dữ Liệu Dân Cư Bộ Công An (C06), Định Danh VNeID và Đề Án 06

Tài liệu cung cấp cơ sở tri thức chính thức cho Trợ lý AI Tài chính Sen Hồng Bank về việc kết nối Cơ sở Dữ liệu Quốc gia về Dân cư do Bộ Công An (BCA) quản lý, ứng dụng định danh điện tử VNeID, Luật Căn cước và quy định phòng chống tội phạm công nghệ cao.

---

## 1. Kết Nối Cơ Sở Dữ Liệu Quốc Gia Về Dân Cư (C06 - Bộ Công An) & Đề Án 06

### A. Vai trò của Đề án 06/CP đối với Ngành Ngân Hàng
- **Đề án 06 của Chính phủ** ("Phát triển ứng dụng dữ liệu về dân cư, định danh và xác thực điện tử phục vụ chuyển đổi số quốc gia"):
  - Sen Hồng Bank là một trong những ngân hàng số tiên phong tích hợp trực tiếp với **Trung tâm Dữ liệu Quốc gia về Dân cư (Cục Cảnh sát Quản lý hành chính về trật tự xã hội - C06, Bộ Công An)**.
  - **Mục tiêu cốt lõi:**
    1. Làm sạch 100% dữ liệu tài khoản ngân hàng, xóa bỏ triệt để tài khoản "rác", tài khoản "ma" hoặc mở bằng giấy tờ giả mạo.
    2. Đảm bảo nguyên tắc: **Một cá nhân - Một danh tính số chính chủ duy nhất**.
    3. Ngăn chặn tội phạm sử dụng tài khoản ngân hàng để rửa tiền, đánh bạc online, lừa đảo chiếm đoạt tài sản qua mạng viễn thông.

### B. Quy Trình Xác Thực Thẻ Căn Cước Gắn Chip Trực Tiếp Với Dữ Liệu C06
1. **Chuẩn mã hóa thẻ:** Thẻ Căn cước / CCCD gắn chip của công dân Việt Nam tuân theo chuẩn quốc tế **ICAO Doc 9303**.
2. **Cơ chế xác thực:**
   - Ứng dụng Sen Hồng sử dụng đầu đọc NFC của điện thoại để đọc chip vi mạch bảo mật trên thẻ CCCD.
   - Dữ liệu trích xuất bao gồm: Số định danh cá nhân (12 chữ số), Họ và tên, Ngày tháng năm sinh, Giới tính, Quê quán, Nơi thường trú, Đặc điểm nhận dạng, Ảnh chân dung số và Khóa chứng thư số công khai (Public Key PKI) do Bộ Công An ký số.
   - Hệ thống Sen Hồng đối soát chữ ký số (Passive Authentication) và xác thực động (Active Authentication) trực tiếp với nguồn dữ liệu gốc của C06 Bộ Công An để đảm bảo thẻ thật 100%, không bị làm giả hay can thiệp chip vi mạch.

---

## 2. Ứng Dụng Định Danh Điện Tử VNeID & Luật Căn Cước 2023

### A. Tích Hợp Định Danh Điện Tử VNeID
- **VNeID** là ứng dụng do Trung tâm Dữ liệu Quốc gia về Dân cư - Bộ Công An xây dựng và quản lý theo Nghị định số 69/2024/NĐ-CP.
- **Các cấp độ định danh:**
  - **Tài khoản VNeID Mức 1:** Định danh dựa trên số định danh cá nhân và ảnh chân dung (tự đăng ký trực tuyến).
  - **Tài khoản VNeID Mức 2:** Định danh toàn diện có thu nhận vân tay, mống mắt và đối soát trực tiếp tại cơ quan Công an phường/xã.
- **Ứng dụng trên Sen Hồng Bank:**
  - Khách hàng đã có tài khoản **VNeID Mức 2** có thể sử dụng VNeID để xác thực mở tài khoản Sen Hồng trực tuyến siêu tốc mà không cần chụp lại giấy tờ tùy thân.
  - Thông tin định danh được đồng bộ bảo mật, phục vụ cấp hạn mức giao dịch trực tuyến cao nhất (lên tới **500.000.000 VNĐ/ngày**).

### B. Tuân Thủ Luật Căn Cước Số 26/2023/QH15
- Luật Căn cước số 26/2023/QH15 (chính thức có hiệu lực từ ngày 01/07/2024):
  - Đổi tên từ "Thẻ Căn cước công dân" thành **"Thẻ Căn cước"**.
  - Tích hợp thêm dữ liệu sinh trắc học mống mắt (Iris Recognition) và thông tin ADN/giọng nói tự nguyện vào cơ sở dữ liệu.
  - Các thẻ CCCD gắn chip đã cấp trước ngày 01/07/2024 vẫn có giá trị sử dụng nguyên vẹn đến hết thời hạn ghi trên thẻ; khách hàng không bắt buộc phải đổi sang Thẻ Căn cước mới nếu thẻ cũ còn hạn.
  - Sen Hồng Bank hỗ trợ đầy đủ cả Thẻ CCCD gắn chip (12 số) và Thẻ Căn cước mẫu mới.

---

## 3. Chế Tài Pháp Luật & Cảnh Báo An Ninh Bộ Công An

### A. Tội Mua Bán, Cho Thuê, Cho Mượn Tài Khoản Ngân Hàng (Điều 291 Bộ Luật Hình Sự)
- **Quy định pháp luật:**
  - Khoản 5 Điều 26 Nghị định 88/2019/NĐ-CP (sửa đổi bởi NĐ 143/2021/NĐ-CP): Phạt tiền từ **40.000.000 VNĐ đến 100.000.000 VNĐ** đối với hành vi thuê, cho thuê, mượn, cho mượn, mua bán tài khoản thanh toán hoặc thông tin thẻ.
  - **Xử lý hình sự (Điều 291 BLHS 2015 sửa đổi 2017):** Hành vi thu thập, tàng trữ, trao đổi, mua bán tài khoản ngân hàng từ 10 tài khoản trở lên hoặc thu lợi bất chính từ 20 triệu đồng trở lên có thể bị phạt tù từ **03 tháng đến 07 năm tù giam**.
- **Cảnh báo của Sen Hồng Bank:**
  - Tuyệt đối KHÔNG mở tài khoản hộ, không cho mượn, không bán tài khoản ngân hàng hay mã OTP cho bất kỳ ai dưới mọi hình thức (kể cả người quen hoặc các lời mời tuyển dụng làm việc online lương cao).
  - Các tài khoản tiếp tay cho tội phạm lừa đảo sẽ bị phong tỏa vĩnh viễn và bị đưa vào **Danh sách đen (Blacklist) liên ngân hàng của Ngân hàng Nhà nước và Bộ Công An**, không thể mở tài khoản tại bất kỳ ngân hàng nào trong tương lai.

### B. Cảnh Báo Thủ Đoạn Mạo Danh Cán Bộ Công An Lừa Đảo
- Bộ Công An và Sen Hồng Bank khuyến cáo khẩn cấp:
  1. **Không làm việc qua điện thoại:** Cơ quan Công an (C06, A05, Công an các tỉnh/thành phố), Viện Kiểm sát, Tòa án **tuyệt đối không bao giờ làm việc, lấy lời khai hoặc yêu cầu chuyển tiền qua điện thoại, mạng xã hội (Zalo, Telegram, Facebook)**.
  2. **Không có "Tài khoản an toàn của cơ quan điều tra":** Mọi yêu cầu chuyển tiền vào "tài khoản tạm giữ của cơ quan công an để phục vụ thanh tra/chứng minh trong sạch" đều là **100% lừa đảo**.
  3. **Không yêu cầu mã OTP/PIN:** Cán bộ công an và nhân viên ngân hàng không bao giờ yêu cầu công dân đọc mã OTP, mật khẩu, hay cài app lạ bên ngoài chợ ứng dụng (link lạ `.apk`).
  4. **Kênh xử lý:** Khi có cuộc gọi nghi vấn đe dọa lệnh bắt, giữ tài sản, người dân cần cúp máy ngay lập tức và liên hệ đường dây nóng của Công an địa phương hoặc hotline CSKH Sen Hồng 24/7 **1900-SENHONG**.
