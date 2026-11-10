# CẨM NANG VAY THẾ CHẤP BẤT ĐỘNG SẢN, VAY MUA Ô TÔ & THẨM ĐỊNH TÍN DỤNG CIC

## 1. Tổng quan các Gói Vay Thế Chấp Tài Sản Đảm Bảo (TSBĐ)
Ngân hàng Số Sen Hồng cung cấp các gói tín dụng có tài sản bảo đảm với hạn mức vượt trội, thời hạn vay dài và lãi suất cạnh tranh nhất thị trường:

### Gói 1: Vay Mua Nhà / Đất / Xây Sửa Nhà Ở
- **Hạn mức tài trợ:** Tối đa lên tới **85% giá trị tài sản bảo đảm** (định giá theo thị trường) hoặc 100% nhu cầu vốn nếu thế chấp thêm bất động sản khác.
- **Thời hạn vay:** Kéo dài lên đến **35 năm (420 tháng)**, giúp giảm thiểu tối đa áp lực trả nợ gốc hàng tháng cho gia đình trẻ.
- **Lãi suất ưu đãi:**
  - Lựa chọn 1: Cố định **5.9%/năm** trong 12 tháng đầu.
  - Lựa chọn 2: Cố định **7.2%/năm** trong 24 tháng đầu.
  - Sau ưu đãi: Lãi suất thả nổi = Lãi suất cơ sở tiền gửi 12 tháng + Biên độ 3.2%/năm.
- **Phương thức trả nợ:** Trả gốc đều hàng tháng hoặc theo bậc thang tăng dần; lãi trả hàng tháng theo dư nợ giảm dần thực tế.

### Gói 2: Vay Mua Ô Tô (Tiêu dùng & Kinh doanh Vận tải)
- **Hạn mức vay:** Lên tới **80% giá trị xe mới** (xuất hóa đơn VAT) hoặc 70% giá trị xe cũ (thời gian xuất xưởng không quá 5 năm).
- **Thời gian vay:** Tối đa **8 năm (96 tháng)** đối với xe mới; tối đa **5 năm** đối với xe đã qua sử dụng.
- **Tài sản thế chấp:** Chính chiếc xe chuẩn bị mua (Ngân hàng giữ Giấy đăng ký xe bản gốc, cấp Giấy đi đường hợp lệ cho khách hàng lưu hành) hoặc bất động sản có sẵn.
- **Tốc độ giải ngân:** Cam kết phê duyệt nguyên tắc trong **4 giờ làm việc**; giải ngân phong tỏa vào tài khoản showroom/đại lý ngay khi có Giấy hẹn lấy Đăng ký xe từ Cơ quan Cảnh sát Giao thông.

---

## 2. Quy Trình Chấm Điểm Tín Dụng & Phân Loại 5 Nhóm Nợ CIC
Hệ thống Sen Hồng kết nối API trực tiếp với **Trung tâm Thông tin Tín dụng Quốc gia Việt Nam (CIC - trực thuộc Ngân hàng Nhà nước)** để tra cứu lịch sử nợ và chấm điểm rủi ro tự động theo **Thông tư 11/2021/TT-NHNN**:

### Bảng Phân Loại 5 Nhóm Nợ Theo Quy Định Của NHNN:
1. **Nhóm 1 - Nợ Đủ Tiêu Chuẩn (Standard):**
   - Khoản nợ trong hạn hoặc quá hạn **dưới 10 ngày**.
   - Được đánh giá có khả năng thu hồi đầy đủ cả gốc và lãi đúng hạn.
   - **Tác động:** Được cấp xét duyệt vay vốn siêu tốc với lãi suất tốt nhất.
2. **Nhóm 2 - Nợ Cần Chú Ý (Special Mention):**
   - Quá hạn từ **10 ngày đến 90 ngày**.
   - **Tác động:** Không thể duyệt tự động qua AI, cần thẩm định hồ sơ giải trình lý do khách quan. Lịch sử nhóm 2 sẽ tự động xóa sạch trên hệ thống CIC sau **12 tháng** kể từ ngày khách hàng thanh toán hết nợ.
3. **Nhóm 3 - Nợ Dưới Tiêu Chuẩn (Sub-standard - Bắt đầu tính là NỢ XẤU):**
   - Quá hạn từ **91 ngày đến 180 ngày**.
   - Bắt đầu trích lập dự phòng rủi ro 20%.
4. **Nhóm 4 - Nợ Nghi Ngờ (Doubtful - NỢ XẤU):**
   - Quá hạn từ **181 ngày đến 360 ngày**.
   - Trích lập dự phòng rủi ro 50%.
5. **Nhóm 5 - Nợ Có Khả Năng Mất Vốn (Loss - NỢ XẤU NẶNG):**
   - Quá hạn **trên 360 ngày**.
   - Trích lập dự phòng cụ thể 100%.

### Quy Định Về Xóa Lịch Sử Nợ Xấu (Nhóm 3, 4, 5) Trên CIC:
- Theo quy định pháp luật của Ngân hàng Nhà nước, sau khi khách hàng **đã thanh toán toàn bộ gốc, lãi và phí phạt**, dữ liệu nợ xấu nhóm 3, 4, 5 sẽ được lưu vết trên hệ thống CIC trong vòng **05 năm (60 tháng)**.
- Sau tròn 5 năm kể từ ngày tất toán sạch nợ, hệ thống CIC sẽ tự động gỡ bỏ hoàn toàn lịch sử nợ xấu, khách hàng được khôi phục quyền tiếp cận tín dụng bình thường.
- **Cảnh báo lừa đảo:** Tuyệt đối không có bất kỳ cá nhân hay dịch vụ nào có thể "xóa nợ xấu CIC" trước thời hạn. Mọi quảng cáo nhận xóa nợ xấu lấy phí đều là **hành vi lừa đảo chiếm đoạt tài sản**.

---

## 3. Hồ Sơ Cần Chuẩn Bị Khi Vay Thế Chấp Tại Sen Hồng Bank
1. **Hồ sơ Pháp lý cá nhân:**
   - Thẻ Căn cước công dân gắn chip / Thẻ Căn cước mới của người vay và vợ/chồng (nếu đã kết hôn).
   - Giấy chứng nhận kết hôn hoặc Giấy xác nhận tình trạng hôn nhân độc thân.
2. **Hồ sơ Tài sản Bảo đảm (TSBĐ):**
   - Giấy chứng nhận quyền sử dụng đất, quyền sở hữu nhà ở (Sổ đỏ / Sổ hồng).
   - Hợp đồng mua bán căn hộ/nhà ở hình thành trong tương lai kèm phiếu thu/hóa đơn tiền cọc.
   - Đối với vay ô tô: Hợp đồng mua bán xe, Phiếu thu tiền đặt cọc và Thông báo giao xe của đại lý chính hãng.
3. **Hồ sơ Chứng minh Nguồn thu nhập trả nợ:**
   - Thu nhập từ lương: Hợp đồng lao động + Sao kê tài khoản ngân hàng nhận lương 6 tháng gần nhất.
   - Thu nhập từ kinh doanh/cho thuê: Giấy chứng nhận ĐKKD, Sổ sách theo dõi doanh thu, Hợp đồng cho thuê nhà/xe kèm chứng từ thanh toán định kỳ.
   - Thu nhập từ cổ tức / đầu tư: Báo cáo tài chính doanh nghiệp, quyết định chia cổ tức.
