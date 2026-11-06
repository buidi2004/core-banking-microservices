# Flutter Mobile: Anti-Slop Design & Engineering Guide

Tài liệu hướng dẫn chuẩn hóa giao diện Mobile Flutter theo triết lý **Taste Skill v2** — loại bỏ hoàn toàn các dấu hiệu "AI-generated slop", template rẻ tiền, và nâng tầm trải nghiệm đạt chuẩn thẩm mỹ cao cấp (Apple HIG & Fintech Tier-1).

---

## 0. Quy tắc bất biến: Bảo toàn Bottom Navigation Bar

> [!CAUTION]
> **QUY TẮC VÀNG TUYỆT ĐỐI KHÔNG ĐƯỢC VI PHẠM:**
> - Tuyệt đối **KHÔNG ĐƯỢC** thay đổi, phá vỡ, làm sai lệch hoặc thu nhỏ thanh điều hướng đáy (`IOSLiquidGlassTabBar`, `CupertinoTabBar`, hoặc `BottomNavigationBar`).
> - Khi Scaffold dùng `extendBody: true`, nội dung cuộn bên dưới màn hình sẽ tràn xuống tận đáy màn hình (phía sau thanh glass bottom bar). Mọi màn hình cuộn (`CustomScrollView`, `ListView`, `SingleChildScrollView`) **BẮT BUỘC** phải có khoảng đệm đáy an toàn:
>   ```dart
>   // Cuối CustomScrollView:
>   const SliverToBoxAdapter(child: SizedBox(height: 110)),
>   
>   // Hoặc trong ListView / SingleChildScrollView:
>   padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
>   ```
> - Khoảng đệm 110–120dp này đảm bảo mọi card, nút bấm, và banner cuối cùng có thể cuộn nổi lên hoàn toàn phía trên thanh Bottom Bar, không bị che khuất hoặc chạm đè.

---

## 1. Dấu hiệu "Slop" trong Flutter và cách khắc phục

| Dấu hiệu "AI Slop" thường gặp | Chuẩn Taste Skill Flutter |
| :--- | :--- |
| Đổ bóng đục ngầu (`BoxShadow(blurRadius: 15, color: Colors.black26)`) | Bề mặt phẳng, viền chỉ siêu mỏng 0.5dp (`Border.all(color: Colors.black.withOpacity(0.06), width: 0.5)`) hoặc đổ bóng mờ tinh tế (`blurRadius: 8, color: Colors.black.withOpacity(0.04)`) |
| Icon nằm trong các hình tròn 7 màu ngẫu nhiên (cầu vồng đồ chơi) | Container icon đồng nhất, màu nền trắng/kính mờ trung tính, màu biểu tượng mang sắc độ thương hiệu hoặc trung tính |
| Số tiền và biến động số dư nhảy cỡ chữ, giật khung khi cập nhật | Dùng Tabular Figures (`fontFeatures: [FontFeature.tabularFigures()]`) cho mọi con số tài chính |
| Nút bấm và vùng chạm nhỏ hơn 40dp, không có phản hồi rung | Target tối thiểu 44×44dp, tích hợp rung nhẹ `HapticFeedback.selectionClick()` |
| Chữ tiếng Việt bị cắt dấu mũ, dấu thanh do ép `height: 1.0` | Line height chuẩn 1.3–1.4, chọn font hỗ trợ đầy đủ Unicode tiếng Việt (Inter, SF Pro, Be Vietnam Pro) |

---

## 2. Hệ màu & Quy luật 5% (Color on Data, Not Chrome)

- **Nguyên tắc:** Tối đa 3–5% diện tích pixel trên màn hình được mang màu bão hòa cao.
- **Chrome trung tính:** Nền thanh điều hướng, thẻ, viền, thanh tìm kiếm sử dụng các sắc độ kính mờ (Liquid Glass) hoặc trắng/xám trung tính.
- **Màu dành cho Dữ liệu:**
  - Tiền vào (+): Xanh ngọc lục bảo (`AppColors.emeraldGreen`).
  - Tiền ra / Phí (-): Đỏ hồng thương hiệu hoặc xám đậm trung tính.
  - Trạng thái chờ/xử lý: Vàng hổ phách dịu.
  - Không tô màu rực rỡ lên nền của các thẻ tính năng chỉ để "cho vui mắt".

---

## 3. Bề mặt & Kính lỏng (Liquid Glassmorphism)

Tạo cảm giác chân thực, hữu cơ như mặt kính thấu kính iOS:

```dart
ClipRRect(
  borderRadius: BorderRadius.circular(20),
  child: BackdropFilter(
    filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
    child: Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.65),
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    ),
  ),
)
```

---

## 4. Typography & Con số tài chính (Fintech Figures)

```dart
TextStyle get financialFiguresStyle => const TextStyle(
  fontFamily: 'Inter',
  fontSize: 28,
  fontWeight: FontWeight.w700,
  letterSpacing: -0.5,
  fontFeatures: [
    FontFeature.tabularFigures(), // Số có chiều rộng bằng nhau, không bị giật dòng
  ],
);
```

---

## 5. Danh sách kiểm tra chất lượng trước khi bàn giao

1. [ ] **Bottom Bar:** Thanh điều hướng đáy nguyên vẹn 100%, không bị co kéo, che lấp.
2. [ ] **Cuộn chạm:** Toàn bộ nội dung phía dưới cùng cuộn nổi cao hơn Bottom Bar ít nhất 16dp khi kéo hết cỡ.
3. [ ] **Vật lý cuộn:** Sử dụng `BouncingScrollPhysics` mang lại cảm giác mượt mà của hệ điều hành iOS.
4. [ ] **Cảm ứng rung:** Các thao tác chạm vào phím tắt, icon dịch vụ, toggle ẩn/hiện số dư đều kích hoạt `HapticFeedback.selectionClick()`.
5. [ ] **Tương phản:** Chữ trên nền kính có độ tương phản đạt tối thiểu 4.5:1 (WCAG AA).

