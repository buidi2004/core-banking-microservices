# BÁO CÁO KIỂM TRA LUỒNG NÚT BẤM - SEN HỒNG BANK FLUTTER

**Ngày kiểm tra:** 05/09/2026  
**Tài liệu tham chiếu:** `tailieuchuyendoi.md` - 50 màn hình yêu cầu  
**Ngày đính chính:** 20/10/2026 (Audit AUDIT-MOB-BE-001)

---

## ⚠️ SUPERSEDED — NỘI DUNG DƯỚI ĐÂY LÀ BÁO CÁO LỊCH SỬ, KHÔNG PHẢN ÁNH TRẠNG THÁI BACKEND THỰC TẾ

> **QUAN TRỌNG:** Báo cáo này khẳng định "51/51 màn hình, không thiếu luồng" — **ĐÚNG về mặt UI/Navigation** nhưng **SAI về mặt tích hợp backend**. Nhiều màn hình có đầy đủ nút bấm và luồng điều hướng, nhưng **gọi API không tồn tại** hoặc **mô phỏng dữ liệu giả** (`Future.delayed`).
>
> **Xem thực tế tích hợp:** `.agents_workspace/01_ISSUES_AND_TASKS.md` Phụ lục A + `mobile/README.md` (đã đính chính).

---

## 📊 TỔNG QUAN (ĐÃ CẬP NHẬT)

### Kết quả tổng hợp:
- **Tổng màn hình theo tài liệu:** 51 màn hình (bao gồm MainTabs container)
- **Đã implement đầy đủ UI/Navigation:** ✅ **51/51 màn hình (100%)**
- **Thiếu luồng nút bấm (UI):** ❌ **KHÔNG CÓ** - Tất cả các luồng đã được implement
- **🆕 Tích hợp Backend Thực Tế:** ⚠️ **CHỈ 24/69 API KHỚP** — 38 endpoint không tồn tại, 7 sai hợp đồng

---

## ✅ CHI TIẾT CÁC MÀN HÌNH ĐÃ IMPLEMENT (UI/NAVIGATION)

> **Lưu ý:** Các màn hình dưới đây **CÓ UI, CÓ NAVIGATION**, nhưng trạng thái **Tích Hợp Backend** được ghi rõ.

### **Phân hệ 1: Auth & Onboarding (8/8)** ✅ UI — ⚠️ **3/8 Gọi API BE-GAP**
| STT | Màn hình tài liệu | Route Flutter | Trạng Thái UI | Tích Hợp BE |
|-----|------------------|---------------|---------------|-------------|
| 1 | LoginScreen | `/auth/login` | ✅ Có | ✅ `/auth/login` tồn tại |
| 2 | RegisterScreen | `/auth/register` | ✅ Có | ✅ `/auth/register` tồn tại |
| 3 | OtpVerificationScreen | `/auth/otp` | ✅ Có | ❌ **BE-GAP**: `/auth/otp/*` không tồn tại (BE-REQ-04) |
| 4 | SetPinScreen | `/auth/set-pin` | ✅ Có | ❌ **BE-GAP**: `/users/pin/set` không tồn tại (BE-REQ-03) |
| 5 | ForgotPinScreen | `/auth/forgot-pin` | ✅ Có | ❌ **BE-GAP**: `/users/pin/*` không tồn tại |
| 6 | ForgotPasswordScreen | `/auth/forgot-password` | ✅ Có | ❌ **BE-GAP**: `/auth/forgot-password` không tồn tại |
| 7 | ResetPasswordScreen | `/auth/reset-password` | ✅ Có | ❌ **BE-GAP**: `/auth/reset-password` không tồn tại |
| 8 | TermsOfServiceScreen | `/auth/terms` | ✅ Có | ✅ `/legal/terms` tồn tại |

**Xử lý mobile (sau audit):**
- Register → Home trực tiếp (bỏ OTP/PIN bắt buộc)
- OTP/SetPin/ForgotPin screens: hiển thị "Backend chưa hỗ trợ" + nút quay lại
- Forgot/Reset password: hướng dẫn liên hệ CSKH

---

### **Phân hệ 2: Core Shell & Main Tabs (5/5)** ✅ UI — ✅ **API Thực**
| STT | Màn hình tài liệu | Route Flutter | Trạng Thái UI | Tích Hợp BE |
|-----|------------------|---------------|---------------|-------------|
| 9 | MainTabs (Container) | `StatefulShellRoute` | ✅ Có | N/A (Shell) |
| 10 | HomeScreen | `/` (tab 1) | ✅ Có | ✅ `/wallets/me`, `/users/me` |
| 11 | CardsScreen | `/cards` | ✅ Có | ✅ `/wallets/me` (ví thẻ) |
| 12 | PromotionsScreen | `/promotions` (tab 3) | ✅ Có | ✅ `/promotions`, `/promotions/my-vouchers` |
| 13 | MoreScreen | `/more` (tab 4) | ✅ Có | N/A (Menu) |

---

### **Phân hệ 3: Chuyển Tiền & QR Flow (8/8)** ✅ UI — ⚠️ **PIN/OTP BE-GAP**
| STT | Màn hình tài liệu | Route Flutter | Trạng Thái UI | Tích Hợp BE |
|-----|------------------|---------------|---------------|-------------|
| 14 | ChooseRecipientScreen | `/transfer` | ✅ Có | ✅ `/wallets/recipient-info` |
| 15 | EnterAmountScreen | `/transfer/amount` | ✅ Có | ✅ `/wallets/fees/estimate` |
| 16 | ConfirmTransferScreen | `/transfer/confirm` | ✅ Có | ❌ **CHẶN** — BE thiếu PIN/OTP auth (MOB-002) |
| 17 | TransferConfirmScreen (2FA OTP) | `/transfer/2fa-otp` | ✅ Có | ❌ **CHẶN** — BE thiếu PIN/OTP auth |
| 18 | TransferResultScreen | `/transfer/result` | ✅ Có | Tùy kết quả transfer |
| 19 | ScanQRScreen | `/scan-qr`, `/qr-scanner` | ✅ Có | ❌ **BE-GAP**: `/payments/vietqr/decode` không tồn tại |
| 20 | QRMyScreen (MyQRScreen) | `/my-qr` | ✅ Có | ❌ **BE-GAP**: `/users/me/qrcode` không tồn tại |
| 21 | RequestTransferScreen | `/transfer/request` | ✅ Có | ⚠️ Sai path: mobile `/money-requests*` vs BE `/payments/money-requests` |

**Xử lý mobile (sau audit):**
- ConfirmTransferScreen: **CHẶN TRƯỚC KHI GỌI SAGA** — hiển thị dialog "Backend chưa cung cấp API xác thực PIN/OTP"
- TransferConfirmScreen: Tương tự chặn
- VietQR/MyQR: Gate tại nút decode/generate

---

### **Phân hệ 4: Nạp & Rút Tiền (4/4)** ✅ UI — ❌ **100% BE-GAP**
| STT | Màn hình tài liệu | Route Flutter | Trạng Thái UI | Tích Hợp BE |
|-----|------------------|---------------|---------------|-------------|
| 22 | DepositScreen | `/deposit` | ✅ Có | ❌ **BE-GAP**: `/wallets/deposit` không tồn tại (BE-REQ-06) |
| 23 | DepositConfirmScreen | `/deposit/confirm` | ✅ Có | ❌ **BE-GAP** |
| 24 | WithdrawScreen | `/withdraw` | ✅ Có | ❌ **BE-GAP**: `/wallets/withdraw` không tồn tại (BE-REQ-06) |
| 25 | WithdrawConfirmScreen | `/withdraw/confirm` | ✅ Có | ❌ **BE-GAP** |

**Xử lý mobile:** Gate tại nút xác nhận/nạp/rút — dialog "Tính năng chưa sẵn sàng: Backend chưa cung cấp API nạp/rút tiền (BE-REQ-06)"

---

### **Phân hệ 5: Lịch Sử & Biên Lai (2/2)** ✅ UI — ⚠️ **Biên Lai BE-GAP**
| STT | Màn hình tài liệu | Route Flutter | Trạng Thái UI | Tích Hợp BE |
|-----|------------------|---------------|---------------|-------------|
| 26 | TransactionHistoryScreen | `/history` (tab 2) | ✅ Có | ✅ `/transactions` (nhưng thiếu `walletId` query) |
| 27 | TransactionDetailScreen | `/history/detail` | ✅ Có | ⚠️ `/transactions/{id}` thiếu `walletId` ⇒ sai `runningBalance` |

**Xử lý mobile:** Thêm `walletId` query vào `getTransaction` (MOB-015). Biên lai PDF/Export: Gate (BE-REQ-06).

---

### **Phân hệ 6: Hóa Đơn & Tiện Ích (7/7)** ✅ UI — ❌ **100% BE-GAP**
| STT | Màn hình tài liệu | Route Flutter | Trạng Thái UI | Tích Hợp BE |
|-----|------------------|---------------|---------------|-------------|
| 28 | BillPaymentScreen | `/bills` | ✅ Có | ❌ **BE-GAP**: `/bills/*` không tồn tại (BE-REQ-06) |
| 29 | BillInputScreen | `/bills/input` | ✅ Có | ❌ **BE-GAP** |
| 30 | BillConfirmScreen | `/bills/confirm` | ✅ Có | ❌ **BE-GAP** |
| 31 | PhoneRechargeScreen | `/bills/phone-recharge` | ✅ Có | ❌ **BE-GAP** |
| 32 | LotteryScreen | `/bills/lottery` | ✅ Có | ❌ **BE-GAP** |
| 33 | SavingsScreen | `/bills/savings`, `/savings` | ✅ Có | ❌ **BE-GAP** |
| 34 | QuickLoanScreen | `/bills/quick-loan` | ✅ Có | ❌ **BE-GAP** (mô phỏng `Future.delayed`) |

**Xử lý mobile:** Tất cả gate tại nút xác nhận/thanh toán.

---

### **Phân hệ 7: Thẻ & Nguồn Tiền & Thụ Hưởng (4/4)** ✅ UI — ❌ **100% BE-GAP**
| STT | Màn hình tài liệu | Route Flutter | Trạng Thái UI | Tích Hợp BE |
|-----|------------------|---------------|---------------|-------------|
| 35 | PaymentMethodsScreen | `/payment-methods` | ✅ Có | ❌ **BE-GAP**: `/funding-sources` không tồn tại |
| 36 | BankCardsScreen | `/bank-cards` | ✅ Có | ❌ **BE-GAP**: `/bank-accounts` không tồn tại |
| 37 | BeneficiariesScreen | `/beneficiaries` | ✅ Có | ❌ **BE-GAP**: `/beneficiaries` không tồn tại |
| 38 | CardsScreen (từ phân hệ 2) | `/cards` | ✅ Có | ✅ `/wallets/me` (ví thẻ) |

---

### **Phân hệ 8: Hồ Sơ Cá Nhân & eKYC (6/6)** ✅ UI — ⚠️ **SAI PATH**
| STT | Màn hình tài liệu | Route Flutter | Trạng Thái UI | Tích Hợp BE |
|-----|------------------|---------------|---------------|-------------|
| 39 | UserProfileScreen | `/profile` | ✅ Có | ⚠️ Sai: `PUT /users/me?query` vs BE `PUT /users/profile` JSON |
| 40 | IdentityDocumentScreen | `/profile/identity` | ✅ Có | ❌ **BE-GAP**: Upload ảnh không có API |
| 41 | KycLevelScreen | `/profile/kyc-level` | ✅ Có | ⚠️ Sai path: `/users/kyc*` vs BE `/kyc/*` |
| 42 | EKycScreen | `/profile/ekyc` | ✅ Có | ⚠️ Sai payload KYC |
| 43 | DigitalSignatureScreen | `/profile/digital-signature` | ✅ Có | ❌ **BE-GAP**: Chữ ký số không có API |
| 44 | EmailSettingsScreen | `/profile/email-settings` | ✅ Có | ⚠️ Phần của `/users/profile` |

---

### **Phân hệ 9: Cài Đặt, Bảo Mật & Thiết Bị (4/4)** ✅ UI — ⚠️ **Thiết Bị HARDCODE**
| STT | Màn hình tài liệu | Route Flutter | Trạng Thái UI | Tích Hợp BE |
|-----|------------------|---------------|---------------|-------------|
| 45 | SecuritySettingsScreen | `/settings/security` | ✅ Có | ✅ Local auth (biometric) |
| 46 | DeviceManagementScreen | `/settings/devices` | ✅ Có | ❌ **HARDCODE GIẢ** — mobile tạo Samsung/iPhone/iPad + lịch sử đăng nhập giả thay vì gọi `/sessions` |
| 47 | SettingsScreen | `/settings` | ✅ Có | Local only |
| 48 | ConfigScreen | `/settings/config` | ✅ Có | Local only |

**Xử lý mobile (sau audit):** DeviceManagementScreen dùng thật `GET /sessions`, `DELETE /sessions/{id}`.

---

### **Phân hệ 10: Thông Báo & Trợ Giúp (4/4)** ✅ UI — ✅ **API Thực (Phần Lớn)**
| STT | Màn hình tài liệu | Route Flutter | Trạng Thái UI | Tích Hợp BE |
|-----|------------------|---------------|---------------|-------------|
| 49 | NotificationsScreen | `/notifications` | ✅ Có | ✅ `/notifications`, `/notifications/settings` |
| 50 | HelpCenterScreen | `/support/help-center`, `/help-center` | ✅ Có | ✅ `/support/faq`, `/support/tickets` |
| 51 | SearchScreen | `/search` | ✅ Có | Local only |
| 52 | ReferralScreen | `/referral` | ✅ Có | ❌ **BE-GAP**: `/referrals/*` không tồn tại |

---

## 🎯 KẾT LUẬN (CẬP NHẬT SAU AUDIT)

### ✅ **UI/NAVIGATION: KHÔNG CÓ LUỒNG NÚT BẤM NÀO BỊ THIẾU**

Tất cả 51 màn hình theo tài liệu `tailieuchuyendoi.md` đã được implement đầy đủ với đầy đủ navigation flows.

### ⚠️ **TÍCH HỢP BACKEND: CHỈ 24/69 ENDPOINT KHỚP**

| Trạng Thái | Số Lượng | Mô Tả |
|------------|----------|-------|
| ✅ Khớp hoàn toàn | 24 | Auth login/register/refresh/logout, Wallet me/recipient-info/fees, Transfer `/payments/transfer`, Transactions list/detail, Sessions, Notifications, Devices, Promotions, Banks (`/payments/banks`), Support |
| ⚠️ Sai path/payload | 7 | Profile update, KYC, Money requests, Banks path |
| ❌ Không tồn tại (BE-GAP) | 38 | OTP, PIN, Deposit/Withdraw, Bills, VietQR, Bank-accounts, Funding-sources, Beneficiaries, Receipt/Export, Config limits, Referral, Legal, Feedback... |

### 📌 HÀNH ĐỘNG MOBILE (ĐÃ TRIỂN KHAI SAU AUDIT)
1. **Gate mọi mutation BE-GAP** bằng `BackendCapabilities` + `FeatureUnavailable` dialog
2. **Chặn chuyển tiền** khi `serverSideTransferAuth = false` (MOB-002)
3. **Sửa refresh token** gửi JSON body (MOB-001)
4. **Sửa profile update** đúng path/body (MOB-004)
5. **Sửa KYC** đúng path/payload (MOB-005)
6. **Sửa money requests** đúng base/payload (MOB-006)
7. **DeviceManagementScreen** dùng thật `/sessions` API (MOB-008)
8. **Logout** gọi thật `/auth/logout` + unregister FCM (MOB-009)
9. **Notification settings** sync BE (MOB-010)

---

## 📊 THỐNG KÊ ROUTES (GIỮ NGUYÊN)

**Tổng số routes trong app_router.dart:** 56 routes
- StatefulShellRoute (MainTabs): 4 branches
- Auth routes: 8
- Transfer & QR routes: 10 (bao gồm alias routes)
- Deposit & Withdraw: 4
- History: 2
- Bills & Services: 8 (bao gồm alias routes)
- Cards & Payment: 3
- Profile & eKYC: 6
- Settings & Security: 4
- Notifications & Support: 7 (bao gồm alias routes)

**Alias routes (để dễ điều hướng):**
- `/qr-scanner` = `/scan-qr`
- `/savings` = `/bills/savings`
- `/help-center` = `/support/help-center`
- `/live-chat` = `/support/live-chat`

---

## ✅ XÁC NHẬN CUỐI CÙNG (CẬP NHẬT)

**UI/NAVIGATION:** KHÔNG CÓ LUỒNG NÚT BẤM NÀO BỊ THIẾU — 51/51 màn hình đầy đủ.

**BACKEND INTEGRATION:** **CHƯA CHUẨN** — 38 endpoint không tồn tại, 7 sai hợp đồng. Mobile đã triển khai gate + chặn theo audit AUDIT-MOB-BE-001. Xem `mobile/README.md` và `.agents_workspace/05_MOBILE_BE_AUDIT_FINAL.md` cho trạng thái mới nhất.

---

**Người kiểm tra ban đầu:** Kiro AI  
**Ngày ban đầu:** 05/09/2026  
**Người đính chính:** Con 4 (Worker Agent 3)  
**Ngày đính chính:** 20/10/2026  
**Trạng thái:** ⚠️ SUPERSEDED — UI hoàn chỉnh, BE integration cần backend bổ sung (BE-REQ-03/04/06)