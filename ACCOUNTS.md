# 🏦 DANH SÁCH TÀI KHOẢN HỆ THỐNG CORE BANKING & E-WALLET
*Tài liệu tra cứu tài khoản cán bộ chi nhánh & khách hàng ví điện tử*

---

## 🔑 MẬT KHẨU MẶC ĐỊNH (DEFAULT PASSWORD)
Tất cả các tài khoản Demo và Cán bộ ngân hàng sử dụng mật khẩu chung:
> **`DemoPass#2026!`**  
> *(BCrypt Hash: `$2a$10$Bcg3rjT7oYME6TAZkU8yiuHtvX01FWxsKYWWV/Zl3vuQdHgRxciZy`)*

---

## 👨‍💼 I. TÀI KHOẢN CÁN BỘ NGÂN HÀNG (STAFF ACCOUNTS)

| STT | Họ và Tên | Tên đăng nhập (`username`) | Số điện thoại | Quyền hạn (`Role`) | Chi nhánh (`branch_id`) | Chức năng chính |
|:---:|---|:---:|:---:|:---:|:---:|---|
| **1** | **Nguyễn Văn A** | `teller1` | `0911000001` | **`ROLE_TELLER`** | `BR_Q1` (Quận 1, TP.HCM) | Giao dịch viên quầy: Lập lệnh nạp tiền $\le 50\text{M}$ tự duyệt, $> 50\text{M}$ gửi duyệt |
| **2** | **Trần Thị B** | `teller2` | `0911000002` | **`ROLE_TELLER`** | `BR_HK` (Hoàn Kiếm, HN) | Giao dịch viên quầy Chi nhánh Hà Nội |
| **3** | **Lê Hoàng C** | `manager1` | `0911000003` | **`ROLE_MANAGER`** | `BR_Q1` (Quận 1, TP.HCM) | Kiểm soát viên: Phê duyệt Maker-Checker các lệnh nạp tiền lớn $> 50\text{M}$ hoặc từ chối AML |

---

## 👤 II. TÀI KHOẢN KHÁCH HÀNG VÍ ĐIỆN TỬ (CUSTOMER WALLET ACCOUNTS)

| STT | Tên khách hàng | Tên đăng nhập | Số ĐT ví | Số CCCD (12 số) | Mã tài khoản ví | Số dư khả dụng | Trạng thái ví | KYC Sinh trắc học |
|:---:|---|:---:|:---:|:---:|:---:|:---:|:---:|:---:|
| **1** | **Alice Nguyen** | `alice` | `0901234567` | `079204001234` | `W-ALICE-1001` | **14,500,000 VND** | 🟢 `ACTIVE` | 🛡️ `VERIFIED` (C06 BCA) |
| **2** | **Bob Tran** | `bob` | `0909876543` | `079204005678` | `W-BOB-2002` | **151,500,000 VND** | 🟢 `ACTIVE` | 🛡️ `VERIFIED` (C06 BCA) |
| **3** | **Charlie Le** | `charlie` | `0912345678` | `001091234567` | `W-CHARLIE-3003` | **25,000,000 VND** | 🟢 `ACTIVE` | 🛡️ `VERIFIED` |
| **4** | **David Pham** | `david` | `0933333333` | `079093333333` | `W-DAVID-4004` | **5,000,000 VND** | 🔴 **`BLOCKED`** | ⛔ *Tài khoản bị tạm khóa để kiểm tra xử lý lỗi nghiệp vụ* |
| **5** | **Hoang Mai** | `hoangmai` | `0988889999` | `001098889999` | `W-HOANG-5005` | **80,000,000 VND** | 🟢 `ACTIVE` | 🛡️ `VERIFIED` |

---

## ⚡ III. HƯỚNG DẪN ĐĂNG NHẬP NHANH

### 1. Trên Giao Diện Web React Portal:
Truy cập: [http://localhost:5173](http://localhost:5173)
* Chọn tab **"1-Click Đăng Nhập Cán Bộ"** để vào ngay với vai trò **Teller 1** hoặc **Manager 1**.
* Hoặc nhập trực tiếp `username` và `password`:
  * Tài khoản: `teller1`
  * Mật khẩu: `DemoPass#2026!`

### 2. Gọi API Đăng Nhập Qua cURL (Lấy JWT Token):
```bash
curl -X POST http://localhost:8080/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "teller1",
    "password": "DemoPass#2026!"
  }'
```

### 3. Tự Động Nạp Token Vào Môi Trường:
```bash
# Cấp mới JWT Token cho 3 cán bộ
./run.sh tokens

# Nạp vào shell
source ./scripts/e2e/.staff_tokens.env
echo "Teller Token: $TELLER1_TOKEN"
echo "Manager Token: $MANAGER1_TOKEN"
```
