# Design Skill — Giao diện E-Wallet Mobile (React Native, phong cách iOS kính mờ)

> Dán file này cho AI coding agent trước khi bắt đầu dựng UI. Mọi màn hình phải dùng chung 1 bộ token (màu, bo góc, blur) định nghĩa ở Phần 1–5 — **không hard-code màu/số bo góc rời rạc trong từng màn hình**, phải import từ 1 file theme trung tâm (xem Phần 9).

---

## 0. Định hướng chung

App ví điện tử, cảm giác: **nhẹ nhàng, đáng tin, hiện đại kiểu iOS** — nền xanh dương nhạt gần trắng, các khối nổi (card, sheet, nút) dùng kính mờ (glass) để tạo chiều sâu thay vì đổ bóng thô. **Yếu tố nhận diện riêng (signature element)**: "Balance Glass Card" — thẻ số dư có nền gradient xanh dương dịu phủ lớp kính mờ, số tiền hiển thị bằng số rộng, bo tròn, đậm — xuất hiện nhất quán ở Dashboard và Chi tiết ví, là thứ người dùng nhớ nhất về app.

---

## 1. Bảng màu (color tokens)

| Token | Hex | Dùng cho |
|---|---|---|
| `--bg-base` | `#F3F8FF` | Nền toàn app (xanh dương nhạt gần trắng) |
| `--surface` | `#FFFFFF` | Card, sheet, input (nền đặc, không phải glass) |
| `--primary` | `#2F6FE0` | Nút chính, icon active, link |
| `--primary-soft` | `#DCEBFF` | Nền chip/badge nhạt, nền icon tròn |
| `--primary-deep` | `#123B7A` | Text nhấn mạnh trên nền sáng, gradient tối cho hero card |
| `--text-primary` | `#0B2545` | Text chính (navy đậm, không dùng đen thuần) |
| `--text-secondary` | `#5C7A9C` | Text phụ, placeholder, caption |
| `--success` | `#34C759` | Trạng thái thành công / nhận tiền |
| `--danger` | `#FF3B30` | Trạng thái thất bại / lỗi |
| `--warning` | `#FF9F0A` | Trạng thái đang xử lý / chờ xác nhận |
| `--glass-tint` | `rgba(255,255,255,0.55)` | Overlay kính mờ trên nền sáng |
| `--glass-border` | `rgba(255,255,255,0.65)` | Viền 1px cho khối kính mờ |
| `--shadow-color` | `#3A8DFF` (opacity 0.15–0.22) | Đổ bóng mềm màu xanh, không dùng đen thuần |

Gradient hero: `linear-gradient(135deg, #2F6FE0 0%, #5FA8FF 55%, #EAF4FF 100%)`.

---

## 2. Typography

- **Display/số liệu** (số dư, số tiền giao dịch): font bo tròn — iOS dùng `SF Pro Rounded`, Android fallback `Inter` weight 700–800, dùng tabular numbers (số đều nhau) để số dư không "nhảy" khi đổi.
- **Heading/tiêu đề màn hình**: `SF Pro Display` (iOS) / `Inter` weight 600–700.
- **Body**: `SF Pro Text` (iOS) / `Inter` weight 400–500, cỡ 15–16px.
- **Caption/label phụ**: cùng họ body, weight 500, cỡ 12–13px, màu `--text-secondary`.

Quy tắc: chỉ số tiền và tên app dùng font bo tròn đậm — phần còn lại dùng font thường, tránh lạm dụng làm rối mắt.

---

## 3. Hệ thống bo góc — quy tắc "chỗ nào tròn, chỗ nào vuông"

**Nguyên tắc cốt lõi**: khối càng *nổi* và *có thể chạm/kéo* → càng bo tròn nhiều. Khối càng *neo vào cạnh màn hình* hoặc *mang tính cấu trúc/phân chia* → càng vuông.

| Token | Giá trị | Áp dụng |
|---|---|---|
| `--radius-none` | 0px | Header full-bleed sát mép trên, hairline divider, cạnh ngoài của list gộp (grouped list) khi không nổi trên nền |
| `--radius-xs` | 6px | Tag nhỏ trong dòng text, ô input con (mã OTP từng ô) |
| `--radius-sm` | 12px | Hàng trong danh sách gộp (transaction row **giữa** danh sách — 2 hàng liền kề dùng góc vuông ở cạnh chung, chỉ hàng đầu/cuối của nhóm mới bo) |
| `--radius-md` | 20px | Card độc lập (không nằm trong list gộp), nút chính dạng khối, input field, ảnh QR container |
| `--radius-lg` | 28px | Bottom sheet (chỉ 2 góc trên), modal, Balance Hero Card |
| `--radius-pill` | 999px | Nút chính dạng viên thuốc, chip trạng thái, tab bar nổi, nút QR tròn giữa tab bar, avatar |

Ví dụ cụ thể để agent áp đúng:
- Danh sách lịch sử giao dịch: cả khối bo `--radius-md` ở ngoài, nhưng **từng hàng bên trong vuông góc**, chỉ có hairline `1px` màu `--primary-soft` phân cách — đúng kiểu iOS "inset grouped list".
- Balance Hero Card: bo `--radius-lg` toàn bộ 4 góc, nổi hẳn trên nền.
- Bottom sheet (xác nhận giao dịch, chi tiết QR): **chỉ bo 2 góc trên** `--radius-lg`, 2 góc dưới vuông vì dính đáy màn hình.
- Header/Nav bar: nền vuông `--radius-none`, nhưng nút back/icon bên trong là hình tròn `--radius-pill`.
- Nút "Chuyển tiền" chính: `--radius-pill`. Nút phụ "Huỷ": `--radius-md` (không phải pill — tạo phân cấp thị giác rõ giữa hành động chính/phụ).

---

## 4. Hiệu ứng kính mờ (glassmorphism kiểu iOS)

**Thư viện**: dùng Expo → `expo-blur` (`<BlurView intensity={...} tint="light">`), nếu không dùng Expo thì `@react-native-community/blur`.

**Nơi dùng blur** (đúng chỗ, không lạm dụng):
1. **Top nav bar** — dính trên, blur `intensity={70}` `tint="light"`, hiện rõ khi list cuộn qua bên dưới.
2. **Bottom tab bar** — dạng viên nổi cách đáy 12px, `--radius-pill`, blur `intensity={80}`, đổ bóng mềm `--shadow-color`.
3. **Bottom sheet backdrop** — lớp phủ sau sheet dùng blur `intensity={40}` + dim đen nhẹ `rgba(11,37,69,0.25)` phía sau blur.
4. **Balance Hero Card** — lớp kính mờ mỏng phủ lên gradient (không phủ lên nội dung số tiền, chỉ ở phần nền hoạ tiết phía sau) để tạo chiều sâu.
5. **Modal nhập PIN/OTP** — nền phía sau modal blur toàn màn hình.

**Nơi KHÔNG dùng blur** (giữ rõ ràng, dễ đọc):
- Vùng nội dung chính (danh sách giao dịch, form input, text body) — nền đặc `--surface`, không blur.
- Không xếp chồng quá **2 lớp blur cùng lúc** trên 1 màn hình (vừa nặng máy vừa rối mắt) — ví dụ nếu bottom sheet đang mở (có backdrop blur) thì tab bar phía sau tạm ẩn, không blur chồng blur.

---

## 5. Bóng đổ

Không dùng bóng đen thuần. Toàn bộ `shadowColor`/`elevation` dùng tông xanh dịu:
```
shadowColor: '#3A8DFF'
shadowOpacity: 0.15–0.22
shadowRadius: 16–24
shadowOffset: { width: 0, height: 8 }
```
Card càng "nổi cao" (Balance Hero Card, nút QR tròn giữa tab bar) thì `shadowOpacity`/`shadowRadius` càng lớn.

---

## 6. Component chuẩn dùng lại

| Component | Mô tả |
|---|---|
| `PrimaryButton` | Pill (`--radius-pill`), nền gradient `--primary` → `#5FA8FF`, text trắng đậm, shadow xanh |
| `SecondaryButton` | Nền trắng/glass, viền 1px `--primary`, `--radius-md`, text `--primary` |
| `GlassCard` | `BlurView` + viền `--glass-border` 1px, `--radius-lg`, dùng cho hero/sheet |
| `SolidCard` | Nền `--surface` đặc, `--radius-md`, dùng cho card thường (không cần chiều sâu) |
| `StatusChip` | Pill nhỏ, nền `--*-soft` tương ứng trạng thái (PROCESSING/SUCCESS/FAILED), text màu đậm cùng tông |
| `GroupedListRow` | Hàng trong danh sách gộp, góc vuông giữa các hàng, chỉ hàng đầu/cuối nhóm bo `--radius-sm` |
| `PinDot` / `OtpBox` | Ô nhập PIN/OTP dạng ô vuông bo `--radius-xs`, hoặc chấm tròn nếu ẩn số |
| `FloatingQRButton` | Nút tròn nổi giữa tab bar, `--radius-pill`, icon QR, gradient + shadow đậm nhất app |

---

## 7. Lưới khoảng cách (spacing scale)

`4 / 8 / 12 / 16 / 20 / 24 / 32 / 40` (px). Padding ngang mặc định toàn màn hình: `20px`. Khoảng cách giữa các card trong 1 nhóm: `12px`. Giữa các nhóm section: `24–32px`.

---

## 8. Ánh xạ thiết kế cho 21 màn hình

**Nhóm A — Xác thực (5 màn)**: nền `--bg-base` trơn, không blur (form cần rõ ràng). Input `--radius-md`. Nút chính pill. Màn Thiết lập PIN dùng `PinDot` 6 ô tròn.

**Nhóm B — Dashboard (1 màn)**: `Balance Hero Card` (glass + gradient, `--radius-lg`) chiếm phần trên; bên dưới là dãy `SolidCard` icon tròn (Chuyển tiền/Quét QR/QR của tôi) dạng `--radius-pill` cho icon, `--radius-sm` cho nhãn text. Danh sách giao dịch gần nhất dùng `GroupedListRow`.

**Nhóm C — Chuyển tiền (4 màn)**: màn nhập/chọn người nhận và preview dùng `SolidCard`. Màn "Nhập PIN/OTP xác nhận" hiện dạng **modal full-screen với backdrop blur**, `OtpBox`/`PinDot` giữa màn hình. Màn kết quả: `StatusChip` lớn ở giữa (thành công = xanh `--success`, thất bại = đỏ `--danger`, đang xử lý = cam `--warning` kèm hiệu ứng pulse nhẹ).

**Nhóm D — QR (3 màn)**: màn Quét QR — camera full-screen, khung quét bo `--radius-md`, overlay 4 góc sáng. Màn "QR của tôi" — mã QR đặt trong `GlassCard` `--radius-lg` nổi giữa nền gradient nhạt, toggle QR tĩnh/động dạng pill switch, đếm ngược hết hạn hiển thị `StatusChip` màu `--warning`.

**Nhóm E — Số dư & Lịch sử (3 màn)**: Chi tiết ví tái dùng `Balance Hero Card` nhưng thêm dòng phụ "khả dụng / thực" ngay dưới số chính. Lịch sử giao dịch = `GroupedListRow` list, filter dạng chip pill nằm ngang cuộn được. Chi tiết giao dịch = `SolidCard` bố cục 2 cột nhãn–giá trị, `StatusChip` ở đầu.

**Nhóm F — Thông báo (1 màn)**: `GroupedListRow`, mỗi hàng có icon tròn `--primary-soft` nền, hàng chưa đọc có chấm nhỏ màu `--primary` góc trái.

**Nhóm G — Hồ sơ & Bảo mật (4 màn)**: nền trơn, list cài đặt dùng `GroupedListRow` chuẩn iOS Settings (icon vuông bo `--radius-xs` bên trái mỗi mục). Màn quản lý thiết bị: mỗi thiết bị là 1 `SolidCard`, thiết bị hiện tại có `StatusChip` "Đang dùng" màu `--success`.

**Điều hướng chính**: Bottom tab bar dạng viên nổi (glass), 5 mục: Trang chủ — Lịch sử — **QR (nút tròn nổi giữa, lớn hơn, gradient đậm)** — Thông báo — Hồ sơ.

---

## 9. Nguyên tắc thực thi cho AI agent

1. Dùng **React Native + Expo** (để dùng `expo-blur`, `expo-linear-gradient` sẵn có, không cần link native thủ công).
2. Tạo **1 file theme trung tâm** (`theme.ts`) chứa toàn bộ token Phần 1–5 (màu, radius, spacing, shadow) — **mọi màn hình import từ đây**, không viết số/mã màu trực tiếp trong từng component.
3. Build các component dùng lại ở Phần 6 **trước**, dựng thư viện component riêng, sau đó mới ráp vào từng màn hình — tránh lặp code và đảm bảo đồng nhất.
4. Sau khi dựng xong mỗi nhóm màn hình (A → G), **chạy app thật trên simulator/Expo Go**, xác nhận không có lỗi console/redbox trước khi sang nhóm tiếp theo.
5. Không lạm dụng blur quá 2 lớp hiển thị cùng lúc trên 1 màn hình (theo Phần 4).
6. Nếu 1 phần của brief này mâu thuẫn với dữ liệu/luồng thực tế từ backend (ví dụ tên trường, trạng thái giao dịch), **ưu tiên đúng theo hợp đồng API backend**, chỉ áp style theo file này — không tự đổi cấu trúc dữ liệu.
# Design Skill — Giao diện E-Wallet Mobile (React Native, phong cách iOS kính mờ)

> Dán file này cho AI coding agent trước khi bắt đầu dựng UI. Mọi màn hình phải dùng chung 1 bộ token (màu, bo góc, blur) định nghĩa ở Phần 1–5 — **không hard-code màu/số bo góc rời rạc trong từng màn hình**, phải import từ 1 file theme trung tâm (xem Phần 9).

---

## 0. Định hướng chung

App ví điện tử, cảm giác: **nhẹ nhàng, đáng tin, hiện đại kiểu iOS** — nền xanh dương nhạt gần trắng, các khối nổi (card, sheet, nút) dùng kính mờ (glass) để tạo chiều sâu thay vì đổ bóng thô. **Yếu tố nhận diện riêng (signature element)**: "Balance Glass Card" — thẻ số dư có nền gradient xanh dương dịu phủ lớp kính mờ, số tiền hiển thị bằng số rộng, bo tròn, đậm — xuất hiện nhất quán ở Dashboard và Chi tiết ví, là thứ người dùng nhớ nhất về app.

---

## 1. Bảng màu (color tokens)

| Token | Hex | Dùng cho |
|---|---|---|
| `--bg-base` | `#F3F8FF` | Nền toàn app (xanh dương nhạt gần trắng) |
| `--surface` | `#FFFFFF` | Card, sheet, input (nền đặc, không phải glass) |
| `--primary` | `#2F6FE0` | Nút chính, icon active, link |
| `--primary-soft` | `#DCEBFF` | Nền chip/badge nhạt, nền icon tròn |
| `--primary-deep` | `#123B7A` | Text nhấn mạnh trên nền sáng, gradient tối cho hero card |
| `--text-primary` | `#0B2545` | Text chính (navy đậm, không dùng đen thuần) |
| `--text-secondary` | `#5C7A9C` | Text phụ, placeholder, caption |
| `--success` | `#34C759` | Trạng thái thành công / nhận tiền |
| `--danger` | `#FF3B30` | Trạng thái thất bại / lỗi |
| `--warning` | `#FF9F0A` | Trạng thái đang xử lý / chờ xác nhận |
| `--glass-tint` | `rgba(255,255,255,0.55)` | Overlay kính mờ trên nền sáng |
| `--glass-border` | `rgba(255,255,255,0.65)` | Viền 1px cho khối kính mờ |
| `--shadow-color` | `#3A8DFF` (opacity 0.15–0.22) | Đổ bóng mềm màu xanh, không dùng đen thuần |

Gradient hero: `linear-gradient(135deg, #2F6FE0 0%, #5FA8FF 55%, #EAF4FF 100%)`.

---

## 2. Typography

- **Display/số liệu** (số dư, số tiền giao dịch): font bo tròn — iOS dùng `SF Pro Rounded`, Android fallback `Inter` weight 700–800, dùng tabular numbers (số đều nhau) để số dư không "nhảy" khi đổi.
- **Heading/tiêu đề màn hình**: `SF Pro Display` (iOS) / `Inter` weight 600–700.
- **Body**: `SF Pro Text` (iOS) / `Inter` weight 400–500, cỡ 15–16px.
- **Caption/label phụ**: cùng họ body, weight 500, cỡ 12–13px, màu `--text-secondary`.

Quy tắc: chỉ số tiền và tên app dùng font bo tròn đậm — phần còn lại dùng font thường, tránh lạm dụng làm rối mắt.

---

## 3. Hệ thống bo góc — quy tắc "chỗ nào tròn, chỗ nào vuông"

**Nguyên tắc cốt lõi**: khối càng *nổi* và *có thể chạm/kéo* → càng bo tròn nhiều. Khối càng *neo vào cạnh màn hình* hoặc *mang tính cấu trúc/phân chia* → càng vuông.

| Token | Giá trị | Áp dụng |
|---|---|---|
| `--radius-none` | 0px | Header full-bleed sát mép trên, hairline divider, cạnh ngoài của list gộp (grouped list) khi không nổi trên nền |
| `--radius-xs` | 6px | Tag nhỏ trong dòng text, ô input con (mã OTP từng ô) |
| `--radius-sm` | 12px | Hàng trong danh sách gộp (transaction row **giữa** danh sách — 2 hàng liền kề dùng góc vuông ở cạnh chung, chỉ hàng đầu/cuối của nhóm mới bo) |
| `--radius-md` | 20px | Card độc lập (không nằm trong list gộp), nút chính dạng khối, input field, ảnh QR container |
| `--radius-lg` | 28px | Bottom sheet (chỉ 2 góc trên), modal, Balance Hero Card |
| `--radius-pill` | 999px | Nút chính dạng viên thuốc, chip trạng thái, tab bar nổi, nút QR tròn giữa tab bar, avatar |

Ví dụ cụ thể để agent áp đúng:
- Danh sách lịch sử giao dịch: cả khối bo `--radius-md` ở ngoài, nhưng **từng hàng bên trong vuông góc**, chỉ có hairline `1px` màu `--primary-soft` phân cách — đúng kiểu iOS "inset grouped list".
- Balance Hero Card: bo `--radius-lg` toàn bộ 4 góc, nổi hẳn trên nền.
- Bottom sheet (xác nhận giao dịch, chi tiết QR): **chỉ bo 2 góc trên** `--radius-lg`, 2 góc dưới vuông vì dính đáy màn hình.
- Header/Nav bar: nền vuông `--radius-none`, nhưng nút back/icon bên trong là hình tròn `--radius-pill`.
- Nút "Chuyển tiền" chính: `--radius-pill`. Nút phụ "Huỷ": `--radius-md` (không phải pill — tạo phân cấp thị giác rõ giữa hành động chính/phụ).

---

## 4. Hiệu ứng kính mờ (glassmorphism kiểu iOS)

**Thư viện**: dùng Expo → `expo-blur` (`<BlurView intensity={...} tint="light">`), nếu không dùng Expo thì `@react-native-community/blur`.

**Nơi dùng blur** (đúng chỗ, không lạm dụng):
1. **Top nav bar** — dính trên, blur `intensity={70}` `tint="light"`, hiện rõ khi list cuộn qua bên dưới.
2. **Bottom tab bar** — dạng viên nổi cách đáy 12px, `--radius-pill`, blur `intensity={80}`, đổ bóng mềm `--shadow-color`.
3. **Bottom sheet backdrop** — lớp phủ sau sheet dùng blur `intensity={40}` + dim đen nhẹ `rgba(11,37,69,0.25)` phía sau blur.
4. **Balance Hero Card** — lớp kính mờ mỏng phủ lên gradient (không phủ lên nội dung số tiền, chỉ ở phần nền hoạ tiết phía sau) để tạo chiều sâu.
5. **Modal nhập PIN/OTP** — nền phía sau modal blur toàn màn hình.

**Nơi KHÔNG dùng blur** (giữ rõ ràng, dễ đọc):
- Vùng nội dung chính (danh sách giao dịch, form input, text body) — nền đặc `--surface`, không blur.
- Không xếp chồng quá **2 lớp blur cùng lúc** trên 1 màn hình (vừa nặng máy vừa rối mắt) — ví dụ nếu bottom sheet đang mở (có backdrop blur) thì tab bar phía sau tạm ẩn, không blur chồng blur.

---

## 5. Bóng đổ

Không dùng bóng đen thuần. Toàn bộ `shadowColor`/`elevation` dùng tông xanh dịu:
```
shadowColor: '#3A8DFF'
shadowOpacity: 0.15–0.22
shadowRadius: 16–24
shadowOffset: { width: 0, height: 8 }
```
Card càng "nổi cao" (Balance Hero Card, nút QR tròn giữa tab bar) thì `shadowOpacity`/`shadowRadius` càng lớn.

---

## 6. Component chuẩn dùng lại

| Component | Mô tả |
|---|---|
| `PrimaryButton` | Pill (`--radius-pill`), nền gradient `--primary` → `#5FA8FF`, text trắng đậm, shadow xanh |
| `SecondaryButton` | Nền trắng/glass, viền 1px `--primary`, `--radius-md`, text `--primary` |
| `GlassCard` | `BlurView` + viền `--glass-border` 1px, `--radius-lg`, dùng cho hero/sheet |
| `SolidCard` | Nền `--surface` đặc, `--radius-md`, dùng cho card thường (không cần chiều sâu) |
| `StatusChip` | Pill nhỏ, nền `--*-soft` tương ứng trạng thái (PROCESSING/SUCCESS/FAILED), text màu đậm cùng tông |
| `GroupedListRow` | Hàng trong danh sách gộp, góc vuông giữa các hàng, chỉ hàng đầu/cuối nhóm bo `--radius-sm` |
| `PinDot` / `OtpBox` | Ô nhập PIN/OTP dạng ô vuông bo `--radius-xs`, hoặc chấm tròn nếu ẩn số |
| `FloatingQRButton` | Nút tròn nổi giữa tab bar, `--radius-pill`, icon QR, gradient + shadow đậm nhất app |

---

## 7. Lưới khoảng cách (spacing scale)

`4 / 8 / 12 / 16 / 20 / 24 / 32 / 40` (px). Padding ngang mặc định toàn màn hình: `20px`. Khoảng cách giữa các card trong 1 nhóm: `12px`. Giữa các nhóm section: `24–32px`.

---

## 8. Ánh xạ thiết kế cho 21 màn hình

**Nhóm A — Xác thực (5 màn)**: nền `--bg-base` trơn, không blur (form cần rõ ràng). Input `--radius-md`. Nút chính pill. Màn Thiết lập PIN dùng `PinDot` 6 ô tròn.

**Nhóm B — Dashboard (1 màn)**: `Balance Hero Card` (glass + gradient, `--radius-lg`) chiếm phần trên; bên dưới là dãy `SolidCard` icon tròn (Chuyển tiền/Quét QR/QR của tôi) dạng `--radius-pill` cho icon, `--radius-sm` cho nhãn text. Danh sách giao dịch gần nhất dùng `GroupedListRow`.

**Nhóm C — Chuyển tiền (4 màn)**: màn nhập/chọn người nhận và preview dùng `SolidCard`. Màn "Nhập PIN/OTP xác nhận" hiện dạng **modal full-screen với backdrop blur**, `OtpBox`/`PinDot` giữa màn hình. Màn kết quả: `StatusChip` lớn ở giữa (thành công = xanh `--success`, thất bại = đỏ `--danger`, đang xử lý = cam `--warning` kèm hiệu ứng pulse nhẹ).

**Nhóm D — QR (3 màn)**: màn Quét QR — camera full-screen, khung quét bo `--radius-md`, overlay 4 góc sáng. Màn "QR của tôi" — mã QR đặt trong `GlassCard` `--radius-lg` nổi giữa nền gradient nhạt, toggle QR tĩnh/động dạng pill switch, đếm ngược hết hạn hiển thị `StatusChip` màu `--warning`.

**Nhóm E — Số dư & Lịch sử (3 màn)**: Chi tiết ví tái dùng `Balance Hero Card` nhưng thêm dòng phụ "khả dụng / thực" ngay dưới số chính. Lịch sử giao dịch = `GroupedListRow` list, filter dạng chip pill nằm ngang cuộn được. Chi tiết giao dịch = `SolidCard` bố cục 2 cột nhãn–giá trị, `StatusChip` ở đầu.

**Nhóm F — Thông báo (1 màn)**: `GroupedListRow`, mỗi hàng có icon tròn `--primary-soft` nền, hàng chưa đọc có chấm nhỏ màu `--primary` góc trái.

**Nhóm G — Hồ sơ & Bảo mật (4 màn)**: nền trơn, list cài đặt dùng `GroupedListRow` chuẩn iOS Settings (icon vuông bo `--radius-xs` bên trái mỗi mục). Màn quản lý thiết bị: mỗi thiết bị là 1 `SolidCard`, thiết bị hiện tại có `StatusChip` "Đang dùng" màu `--success`.

**Điều hướng chính**: Bottom tab bar dạng viên nổi (glass), 5 mục: Trang chủ — Lịch sử — **QR (nút tròn nổi giữa, lớn hơn, gradient đậm)** — Thông báo — Hồ sơ.

---

## 9. Nguyên tắc thực thi cho AI agent

1. Dùng **React Native + Expo** (để dùng `expo-blur`, `expo-linear-gradient` sẵn có, không cần link native thủ công).
2. Tạo **1 file theme trung tâm** (`theme.ts`) chứa toàn bộ token Phần 1–5 (màu, radius, spacing, shadow) — **mọi màn hình import từ đây**, không viết số/mã màu trực tiếp trong từng component.
3. Build các component dùng lại ở Phần 6 **trước**, dựng thư viện component riêng, sau đó mới ráp vào từng màn hình — tránh lặp code và đảm bảo đồng nhất.
4. Sau khi dựng xong mỗi nhóm màn hình (A → G), **chạy app thật trên simulator/Expo Go**, xác nhận không có lỗi console/redbox trước khi sang nhóm tiếp theo.
5. Không lạm dụng blur quá 2 lớp hiển thị cùng lúc trên 1 màn hình (theo Phần 4).
6. Nếu 1 phần của brief này mâu thuẫn với dữ liệu/luồng thực tế từ backend (ví dụ tên trường, trạng thái giao dịch), **ưu tiên đúng theo hợp đồng API backend**, chỉ áp style theo file này — không tự đổi cấu trúc dữ liệu.

---

## 10. Bổ sung — Cấu trúc bố cục chi tiết theo từng màn (áp dụng pattern UX ngân hàng số phổ biến, giữ bộ nhận diện riêng của app — không dùng logo/tên/linh vật của bất kỳ ngân hàng cụ thể nào)

> Phần này mô tả **thứ tự & cách sắp xếp thành phần** (layout structure), không phải màu sắc/thương hiệu cụ thể — mọi màu/bo góc vẫn lấy từ token Phần 1–5.

### Màn 6 — Dashboard
Thứ tự từ trên xuống:
1. Header: logo app (trái) — cụm icon bên phải: tìm kiếm, chuông thông báo, menu (dạng 3 gạch hoặc icon tròn).
2. `Balance Hero Card` (glass, `--radius-lg`) nằm ngay dưới header, đè lên nền gradient của header: dòng nhãn nhỏ "Tổng số dư" + icon con mắt ẩn/hiện số dư ở cuối dòng, số tiền lớn font bo tròn đậm bên dưới, 1 dòng link phụ dạng CTA nhỏ (vd "Xem chi tiết") có mũi tên `>`.
3. Ngay dưới hero card: 1 khối trắng bo góc trên `--radius-lg` đè lên phần nền gradient phía trên (tạo hiệu ứng "sheet nổi lên"), chứa lưới 4 quick-action (icon tròn nền `--primary-soft` + nhãn dưới): Chuyển tiền, Quét QR, Lịch sử, Thông báo — có thể thêm nút mũi tên nhỏ dạng chevron để "xem thêm" nếu quá 4 mục.
4. Banner khuyến mãi/carousel cuộn ngang (không bắt buộc với đồ án, có thể bỏ nếu không cần).
5. Danh sách giao dịch gần nhất dạng `GroupedListRow`.

### Màn 17 — Trung tâm thông báo
- Header: nút back trái, tiêu đề giữa/trái, icon cài đặt bên phải (dạng icon viền lục giác/tròn nhỏ, không nền).
- Ngay dưới header: thanh tab ngang 2–3 mục (vd "Của tôi" / "Biến động số dư"), có gạch chân dưới tab đang active, nền tab nhạt hơn nền chính.
- **Trạng thái rỗng** (chưa có thông báo): minh hoạ 3D/illustration mềm mại căn giữa (hộp mở + bong bóng chấm than) + dòng caption xám nhạt bên dưới, phần còn lại của màn hình để trống trên nền gradient nhạt dần xuống dưới — dùng đúng pattern này cho mọi empty-state khác trong app (lịch sử giao dịch trống, danh sách thiết bị trống...).

### Màn 7 — Chuyển tiền (chọn người nhận)
- Header: back — chuông — home.
- Tiêu đề lớn đậm ngay dưới header (vd "Chuyển tiền").
- Hàng icon tròn cuộn ngang cho các phương thức nhập nhanh (Số tài khoản / Số điện thoại / Quét QR / Mẫu chuyển...), mỗi icon tròn nền trắng + nhãn 1-2 dòng bên dưới.
- Card nhập liệu chính: viền màu nhấn `--primary` dày 1.5px, placeholder mờ bên trong, icon quét QR/scan ở góc phải; bên dưới card là hàng 2–3 hành động phụ (chụp ảnh / tải ảnh / dán) ngăn cách bằng dấu `|` mảnh.
- 2 card nhỏ song song bên dưới: "Gần đây" và "Đối tác liên kết" — mỗi card hiện vài icon nhỏ + badge "+N" nếu còn nhiều hơn.
- Danh sách người nhận đã lưu (nếu có) dạng row có avatar tròn + tên + số/loại tài khoản; nếu rỗng → dùng lại pattern empty-state ở Màn 17.

### Màn 11 — Quét mã QR
- Nền camera full-screen (đen khi chưa có ánh sáng).
- Header trong suốt trên nền camera: back — tiêu đề trắng — icon đèn flash (nút tròn trắng, icon đen) góc phải.
- Khung quét: hình vuông bo `--radius-md`, viền màu nhấn sáng (dùng `--primary` thay vì đỏ), dòng hướng dẫn text trắng căn giữa phía trên khung.
- Dưới khung quét: dòng nhãn nhỏ + hàng icon loại mã QR được chấp nhận (nếu cần minh hoạ).
- Cuối màn: 3 nút icon tròn nền trắng + nhãn dưới (QR của tôi / Chuyển tiền bằng ảnh / Tải ảnh lên).

### Màn 19 — Cài đặt chung / Màn 8 — Đổi hạn mức (áp cho Task 8 backend)
- 1 card trắng bo `--radius-md` duy nhất chứa toàn bộ danh sách cài đặt.
- Mỗi dòng bên trong: icon outline bên trái + label + chevron `>` bên phải (hoặc toggle switch nếu là on/off) — các dòng ngăn cách bằng hairline mảnh, **không bo góc riêng từng dòng** (đúng nguyên tắc Phần 3: khối ngoài bo, dòng trong vuông).
- Dòng "Đổi hạn mức chuyển tiền" trong nhóm này chính là nơi hiển thị hạn mức đã cấu hình ở Task 8 (backend).

### Màn 18 — Hồ sơ cá nhân (dạng menu trượt từ phải, tuỳ chọn)
- Nếu làm dạng overlay trượt từ phải: nền phía sau dim + blur (đúng token Phần 4), panel trắng chiếm ~80% chiều rộng.
- Đầu panel: avatar tròn + tên + link phụ "Xem hồ sơ" + nút đóng (X) góc phải.
- Bên dưới: các dòng cài đặt dạng `GroupedListRow` (không viền card, cách đều bằng hairline).
- Cuối panel: dòng ngôn ngữ (label + giá trị hiện tại), dòng đăng xuất (icon + label màu `--danger` hoặc `--primary` tuỳ mức nhấn mạnh), và version app nhỏ ở đáy.

### Lệnh bổ sung cho AI agent
1. Dựng đúng **thứ tự và cách nhóm thành phần** mô tả ở trên cho từng màn tương ứng — đây là phần "layout/structure", còn màu sắc, bo góc, hiệu ứng kính mờ **luôn lấy từ token Phần 1–5**, không dùng màu/logo/linh vật của bất kỳ thương hiệu ngân hàng có thật nào.
2. Pattern "empty state" (Màn 17) phải được tái sử dụng làm component chung (`EmptyState`) cho mọi nơi có danh sách rỗng trong app, không viết riêng từng màn.
3. Sau khi dựng xong mỗi màn theo cấu trúc mới, so sánh lại với Phần 8 (ánh xạ 21 màn) để đảm bảo không lệch component/token đã chuẩn hoá.
# Bổ sung Design Skill — 10 màn hình mới cho E-Wallet App

> File này **nối tiếp** file gốc "Design Skill — Giao diện E-Wallet Mobile". Dán cả 2 file cho AI coding agent trước khi bắt đầu dựng nhóm màn hình mới. Toàn bộ màu/bo góc/blur/spacing vẫn lấy từ token Phần 1–5 của file gốc — **không định nghĩa token mới**, phần này chỉ bổ sung component và layout.
>
> Số thứ tự màn hình dưới đây là **Màn 22–31**, tiếp nối giả định file gốc đang đánh số đến Màn 21. Nếu bộ tài liệu backend/task của bạn đánh số khác, chỉ cần đổi số, không đổi nội dung.

---

## 1. Vì sao cần thêm các màn hình này

21 màn hình gốc phủ tốt: xác thực, dashboard, chuyển tiền, QR, số dư/lịch sử, thông báo, hồ sơ/bảo mật. Nhưng còn thiếu các luồng lõi mà một ví điện tử thực tế bắt buộc phải có:

- **Tiền vào ví**: nạp tiền, rút tiền, liên kết ngân hàng/thẻ — chưa có màn nào trong 21 màn gốc xử lý việc này.
- **Use-case lớn nhất của ví ở VN**: thanh toán hoá đơn (điện/nước/internet/di động...).
- **Tính năng chuẩn của mọi ví**: yêu cầu nhận tiền, ưu đãi/khuyến mãi.
- **Bắt buộc về compliance & UX**: trung tâm hỗ trợ, quên mã PIN (hiện chỉ có thiết lập PIN lúc onboarding, chưa có đường khôi phục).
- **Điều hướng**: tìm kiếm toàn app (đã có icon search ở header Dashboard nhưng chưa có màn đích).

---

## 2. Component mới — bổ sung vào bảng Phần 6 (file gốc)

| Component | Mô tả |
|---|---|
| `AmountEntryPad` | Bàn phím số tuỳ chỉnh cho nhập số tiền (nạp/rút/thanh toán hoá đơn). Nút số `--radius-sm`, nền `--surface`, nút xoá dạng icon. |
| `QuickAmountChip` | Chip số tiền gợi ý nhanh (50k/100k/200k...), `--radius-pill`, nền `--primary-soft`, text `--primary-deep`. |
| `BankCardRow` | Hàng hiển thị ngân hàng/thẻ liên kết: logo trái, số tài khoản/thẻ che bớt, badge "Mặc định" nếu có, chevron phải. |
| `ProviderIconGrid` | Lưới icon danh mục/nhà cung cấp dịch vụ (điện, nước, di động...), icon tròn nền `--primary-soft`, nhãn dưới. |
| `SearchBar` | Thanh tìm kiếm dạng pill, nền `--surface`, icon kính lúp trái, nút "Huỷ" text xuất hiện tuỳ ngữ cảnh. |
| `FAQAccordionItem` | Mục hỏi–đáp dạng accordion, nằm trong khối `GroupedListRow`, mở rộng tại chỗ không điều hướng màn khác. |

Tất cả component trên **tái sử dụng token màu/bo góc/shadow hiện có**, không cần thêm token riêng.

---

## 3. Nhóm màn hình mới — bổ sung vào bảng Phần 8 (file gốc)

**Nhóm H — Nạp/Rút tiền (2 màn)**: nền `--bg-base` trơn, **không blur** (giữ đúng nguyên tắc Phần 4: vùng nhập liệu cần rõ ràng). Nút hành động chính dạng pill, dính đáy màn hình.

**Nhóm I — Liên kết & quản lý ngân hàng/thẻ (1 màn)**: danh sách dạng `GroupedListRow` chứa `BankCardRow`, rỗng thì dùng lại `EmptyState`.

**Nhóm J — Thanh toán hoá đơn (2 màn)**: `ProviderIconGrid` cho bước chọn nhà cung cấp; card nhập liệu viền `--primary` 1.5px cho bước nhập mã (tái dùng style Card nhập ở Màn 7 file gốc); luồng xác nhận PIN/OTP + `StatusChip` kết quả tái dùng nguyên Nhóm C.

**Nhóm K — Yêu cầu chuyển tiền (1 màn)**: tái dùng pattern chọn liên hệ của Màn 7; mã QR yêu cầu hiển thị trong `GlassCard` (nhất quán với "QR của tôi" ở Nhóm D) thay vì `SolidCard` thường, vì đây cũng là một QR mang tính "hiển thị nổi bật".

**Nhóm L — Ưu đãi & Khuyến mãi (1 màn)**: lưới 2 cột `SolidCard` nhỏ, `EmptyState` khi rỗng.

**Nhóm M — Hỗ trợ (1 màn)**: `FAQAccordionItem` trong `GroupedListRow`, `SearchBar` phía trên.

**Nhóm N — Tìm kiếm & Khôi phục bảo mật (2 màn)**: `SearchBar` full-width cho tìm kiếm; `OtpBox`/`PinDot` tái dùng nguyên từ Nhóm A cho luồng quên PIN, **không dùng blur** trong toàn bộ luồng này (giữ nguyên tắc bảo mật/rõ ràng của Nhóm A).

Tổng số màn hình sau khi bổ sung: **21 + 10 = 31 màn**.

---

## 4. Chi tiết layout từng màn (nối tiếp Phần 10 file gốc)

### Màn 22 — Nạp tiền vào ví
1. Header: back trái — tiêu đề giữa "Nạp tiền" — không icon phải.
2. Card nguồn tiền (`SolidCard`): hiển thị nguồn nạp đã chọn dạng `BankCardRow` + chevron `>` để đổi nguồn. Nếu chưa liên kết → CTA "Liên kết ngân hàng" dẫn sang Màn 24.
3. Khối nhập số tiền: số lớn font bo tròn đậm căn giữa màn hình, con trỏ nhấp nháy sau số — nền `--surface` trơn (đây là ô input, không dùng glass).
4. Hàng `QuickAmountChip`: 50.000 / 100.000 / 200.000 / 500.000 / 1.000.000.
5. `AmountEntryPad` ở dưới cùng; nút "Tiếp tục" pill full-width dính đáy, xám/disable khi chưa nhập số hợp lệ.
6. Bấm Tiếp tục → mở modal xác nhận PIN/OTP (tái dùng pattern Nhóm C).

### Màn 23 — Rút tiền về ngân hàng
1. Bố cục gương với Màn 22: header "Rút tiền", card ở bước 2 là **ngân hàng nhận** (không phải nguồn nạp).
2. Khối nhập số tiền + `QuickAmountChip` + `AmountEntryPad` giống hệt Màn 22.
3. Dòng phụ nhỏ màu `--text-secondary` dưới khối nhập số: "Số dư khả dụng: [số]".
4. Nếu số tiền nhập vượt hạn mức/số dư → `StatusChip` nhỏ màu `--warning` hiện ngay dưới ô nhập, nút "Tiếp tục" chuyển disable.
5. Luồng xác nhận PIN/OTP tái dùng nguyên Nhóm C.

### Màn 24 — Ngân hàng & thẻ liên kết
1. Header: back — tiêu đề "Ngân hàng & thẻ liên kết" — không icon phải.
2. Danh sách nguồn đã liên kết: mỗi nguồn là `BankCardRow` trong khối `GroupedListRow` (khối ngoài bo `--radius-md`, từng hàng vuông góc, hairline phân cách — đúng Phần 3).
3. Nguồn mặc định có badge nhỏ "Mặc định" dạng `StatusChip` màu `--primary`.
4. Rỗng → `EmptyState` (tái dùng pattern Màn 17 file gốc).
5. Nút "Liên kết ngân hàng/thẻ mới" — `SecondaryButton` (viền `--primary`, `--radius-md`) full-width dưới danh sách.
6. Bấm vào → màn loading rồi kết quả dùng `StatusChip` (thành công/thất bại), giống style kết quả Nhóm C. Luồng liên kết thực tế (redirect ngân hàng/đối tác) không cần thiết kế chi tiết riêng.

### Màn 25 — Thanh toán hoá đơn: chọn danh mục/nhà cung cấp
1. Header: back — tiêu đề "Thanh toán hoá đơn" — icon lịch sử thanh toán hoá đơn góc phải.
2. `SearchBar` tìm nhà cung cấp ngay dưới header.
3. `ProviderIconGrid` 4 cột: Điện, Nước, Internet, Di động trả sau, Truyền hình, Học phí...
4. Khối "Hoá đơn đã lưu" dưới lưới danh mục — `GroupedListRow`, bấm vào đi thẳng tới Màn 26 với thông tin điền sẵn.
5. Rỗng phần "đã lưu" → `EmptyState` rút gọn (chỉ caption, không cần illustration lớn vì không phải trạng thái chính của màn).

### Màn 26 — Thanh toán hoá đơn: nhập mã khách hàng & xác nhận
1. Header: back — tên nhà cung cấp đã chọn ở giữa, kèm logo nhỏ.
2. Card nhập liệu chính: viền `--primary` 1.5px (giống Card nhập ở Màn 7 file gốc), label "Mã khách hàng / Số hợp đồng", icon quét mã vạch góc phải nếu nhà cung cấp hỗ trợ.
3. Sau khi nhập mã hợp lệ → tự động hiện `SolidCard` preview: tên khách hàng, kỳ thanh toán, số tiền phải trả — bố cục 2 cột nhãn–giá trị (giống Chi tiết giao dịch, Nhóm E).
4. Nút "Thanh toán • [số tiền]" pill dính đáy.
5. Luồng xác nhận và kết quả tái dùng nguyên Nhóm C (modal PIN/OTP + `StatusChip` kết quả).

### Màn 27 — Tạo yêu cầu nhận tiền
1. Header: back — tiêu đề "Yêu cầu chuyển tiền".
2. Chọn người gửi: tái dùng khối chọn liên hệ giống Màn 7 (icon phương thức nhập nhanh + danh sách liên hệ gần đây).
3. Khối nhập số tiền + ô lời nhắn không bắt buộc (input đa dòng, `--radius-md`, viền mảnh `--primary-soft`).
4. Nút "Tạo yêu cầu" pill — sau khi tạo, hiện kết quả gồm mã QR yêu cầu trong `GlassCard` (`--radius-lg`, nhất quán với "QR của tôi") + nút "Chia sẻ" (share sheet hệ thống) + nút "Sao chép liên kết".
5. Danh sách "Yêu cầu đã gửi/đang chờ" phía dưới dùng `GroupedListRow`, mỗi hàng có `StatusChip` (Chờ thanh toán/Đã nhận/Hết hạn).

### Màn 28 — Trung tâm ưu đãi
1. Header: back — tiêu đề "Ưu đãi" — icon tìm kiếm ưu đãi góc phải.
2. Banner carousel cuộn ngang trên cùng (ưu đãi nổi bật), bo `--radius-md`.
3. Tab ngang lọc theo danh mục (Tất cả/Chuyển tiền/Thanh toán hoá đơn/Nạp tiền...) — style tab giống Màn 17 file gốc.
4. Lưới 2 cột `SolidCard` nhỏ: ảnh minh hoạ trên, tiêu đề + hạn dùng dưới; `StatusChip` nhỏ "Mới" màu `--primary` góc trên ảnh nếu ưu đãi mới.
5. Rỗng → `EmptyState`.

### Màn 29 — Trung tâm hỗ trợ
1. Header: back — tiêu đề "Trợ giúp".
2. `SearchBar` tìm câu hỏi ngay dưới header.
3. Lưới chủ đề nhanh (Chuyển tiền/Nạp-rút/Bảo mật/Tài khoản...) — tái dùng `ProviderIconGrid` với icon khác.
4. Danh sách câu hỏi thường gặp: `FAQAccordionItem` trong khối `GroupedListRow`, bấm mở rộng câu trả lời tại chỗ, không điều hướng màn khác.
5. Cuối màn: `SolidCard` nổi bật CTA "Chat với hỗ trợ viên" (icon chat + mũi tên).

### Màn 30 — Tìm kiếm toàn app
1. Không có header thường — thay bằng `SearchBar` full-width, tự động focus khi mở màn (từ icon search ở header Dashboard); nút "Huỷ" text bên phải thanh tìm kiếm.
2. Khi chưa nhập: "Tìm kiếm gần đây" dạng chip pill nằm ngang (xoá được từng chip) + "Liên hệ gợi ý" dạng avatar tròn cuộn ngang.
3. Khi có kết quả: chia theo section (Liên hệ / Giao dịch / Tính năng), mỗi section có tiêu đề nhỏ `--text-secondary`, kết quả bên dưới dùng `GroupedListRow`.
4. Không có kết quả → `EmptyState` rút gọn, caption "Không tìm thấy kết quả cho '...'".

### Màn 31 — Quên/Đặt lại mã PIN
1. Nền `--bg-base` trơn, **không blur** trong toàn bộ luồng (đúng nguyên tắc Nhóm A).
2. Bước 1 — Xác thực danh tính: OTP gửi về SĐT/email đã đăng ký, dùng `OtpBox` (tái dùng nguyên từ Nhóm A).
3. Bước 2 — Đặt mã PIN mới: `PinDot` 6 ô tròn (giống màn Thiết lập PIN gốc), yêu cầu nhập lại lần 2 để xác nhận.
4. Nếu 2 lần nhập không khớp → cảnh báo inline nhỏ màu `--danger`, không cần modal riêng.

---

## 5. Lệnh bổ sung cho AI agent

1. Đọc file gốc **và** file này trước khi code — không tự suy diễn token/component, mọi màu/bo góc/blur lấy đúng theo Phần 1–5 file gốc.
2. Build 6 component mới ở Phần 2 (file này) theo cùng cách đã build Phần 6 file gốc — dùng lại, không viết trùng logic với component cũ có sẵn (`GroupedListRow`, `StatusChip`, `EmptyState`, `GlassCard`, `SolidCard`...).
3. Dựng theo thứ tự nhóm H → N, mỗi nhóm xong chạy thử trên simulator/Expo Go trước khi sang nhóm tiếp theo (giữ nguyên quy tắc Phần 9 file gốc).
4. Nếu cấu trúc dữ liệu backend (mã hoá đơn, trạng thái yêu cầu chuyển tiền, danh sách ưu đãi...) khác với mô tả ở đây — ưu tiên đúng hợp đồng API backend, chỉ áp style theo file này.