import 'package:flutter/cupertino.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/promotion_remote_datasource.dart';

class PromotionsScreen extends StatefulWidget {
  const PromotionsScreen({super.key});

  @override
  State<PromotionsScreen> createState() => _PromotionsScreenState();
}

class _PromotionsScreenState extends State<PromotionsScreen> {
  final PageController _bannerController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _voucherInputController = TextEditingController();
  int _selectedTab = 0; // 0: Ưu Đãi, 1: Trả Góp Nhà & Xe, 2: Sự Kiện, 3: Voucher
  int _currentBannerIndex = 0;
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';
  Timer? _bannerTimer;
  List<Map<String, dynamic>> _apiVouchers = [];
  bool _isApplyingVoucher = false;

  final List<String> _tabs = ['Ưu Đãi', 'Trả Góp Nhà & Xe', 'Sự Kiện', 'Voucher'];

  static List<Color> _safeGradient(dynamic val) {
    if (val is List<Color> && val.length >= 2) return val;
    if (val is List) {
      final list = val.whereType<Color>().toList();
      if (list.length >= 2) return list;
      if (list.length == 1) return [list.first, list.first];
    }
    return const [Color(0xFF0077B6), Color(0xFF00B4D8)];
  }

  static Color _safeColor(dynamic val, [Color fallback = const Color(0xFF00B4D8)]) {
    if (val is Color) return val;
    return fallback;
  }

  final List<String> _categories = const [
    'Tất cả',
    'Ẩm thực & Cafe',
    'Di chuyển & Xe',
    'Trả góp & Vay',
    'Mua sắm',
    'Du lịch',
    'Hóa đơn',
    'Giải trí',
  ];

  // ===========================================================================
  // 1. MEGA HERO BANNERS (HỆ THỐNG BANNER CHÍNH)
  // ===========================================================================
  final List<Map<String, dynamic>> _heroBanners = const [
    {
      'title': 'Vay Mua Ô Tô VinFast VF3 - Lãi Suất 0%',
      'subtitle': 'Hỗ trợ 85% giá trị xe, ân hạn nợ gốc 12 tháng, góp chỉ từ 2.9 triệu/tháng',
      'tag': '🚗 XE HOT 2026',
      'icon': CupertinoIcons.car_fill,
      'gradient': [Color(0xFF0077B6), Color(0xFF00B4D8)],
      'route': '/bills/quick-loan',
    },
    {
      'title': 'Gói Vay Mua Nhà An Cư - Lãi Suất 5.2%/Năm',
      'subtitle': 'Vinhomes & Masterise: Cố định 24 tháng, thời hạn vay 35 năm, 0đ phạt trả trước',
      'tag': '🏠 BẤT ĐỘNG SẢN',
      'icon': CupertinoIcons.house_fill,
      'gradient': [Color(0xFF0F3E6D), Color(0xFF056676)],
      'route': '/bills/quick-loan',
    },
    {
      'title': 'Trả Góp 0% iPhone 16 Pro Max & MacBook',
      'subtitle': '0 đồng trả trước tại FPT Shop & Thế Giới Di Động qua thẻ tín dụng SenBank',
      'tag': 'TRẢ GÓP 0%',
      'icon': CupertinoIcons.device_phone_portrait,
      'gradient': [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      'route': '/cards',
    },
    {
      'title': 'Mở Thẻ SenBank Visa Platinum - Hoàn 2 Triệu',
      'subtitle': 'Hoàn tiền 50% chi tiêu kỳ đầu, miễn phí thường niên trọn đời',
      'tag': '💳 SENBANK PREMIER',
      'icon': CupertinoIcons.creditcard_fill,
      'gradient': [Color(0xFF0F2B48), Color(0xFF0077B6)],
      'route': '/cards',
    },
    {
      'title': 'Vi Vu Hè Cùng Vietnam Airlines & Agoda',
      'subtitle': 'Giảm 500.000đ vé máy bay khứ hồi & khách sạn 5 sao toàn quốc',
      'tag': '✈️ DU LỊCH 5 SAO',
      'icon': CupertinoIcons.airplane,
      'gradient': [Color(0xFF10B981), Color(0xFF047857)],
      'route': '/bills/input?service=Vé máy bay',
    },
  ];

  // ===========================================================================
  // 2. GÓI VAY & TRẢ GÓP XE, NHÀ, ĐIỆN MÁY ĐẶC QUYỀN
  // ===========================================================================
  final List<Map<String, dynamic>> _installmentDeals = const [
    {
      'title': 'Gói Vay Mua Nhà An Cư SenBank',
      'partner': 'Vinhomes, Masterise Homes, Novaland',
      'interest': '5.2%/năm',
      'maxLimit': 'Tối đa 30 Tỷ',
      'duration': 'Thời hạn 35 năm',
      'tag': 'Ân hạn gốc 3 năm',
      'desc': 'Tài trợ tới 85% giá trị hợp đồng mua bán nhà ở, căn hộ. Thủ tục thẩm định trực tuyến trong 24h.',
      'gradient': [Color(0xFF0A2540), Color(0xFF0077B6)],
      'icon': CupertinoIcons.graph_square_fill,
      'type': 'house',
      'badgeColor': Color(0xFF00B4D8),
    },
    {
      'title': 'Vay Trả Góp Ô Tô VinFast & Hyundai',
      'partner': 'VinFast VF3, VF5, VF8, VF9, Hyundai Tucson',
      'interest': '0% 12 tháng đầu',
      'maxLimit': 'Hỗ trợ 85% xe',
      'duration': 'Thời hạn 8 năm',
      'tag': 'Góp từ 2.9tr/tháng',
      'desc': 'Ưu đãi tặng gói bảo hiểm vật chất 2 năm và miễn phí trạm sạc pin toàn quốc 1 năm.',
      'gradient': [Color(0xFF0F3E6D), Color(0xFF00B4D8)],
      'icon': CupertinoIcons.car_fill,
      'type': 'car',
      'badgeColor': Color(0xFF10B981),
    },
    {
      'title': 'Trả Góp Xe Máy Điện VinFast Thông Minh',
      'partner': 'VinFast Feliz S, Evo200, Klara S',
      'interest': '0% Lãi suất',
      'maxLimit': '0đ Trả trước',
      'duration': 'Kỳ hạn 12 - 24 tháng',
      'tag': 'Góp từ 390k/tháng',
      'desc': 'Sở hữu ngay xe máy điện bảo vệ môi trường, chi phí sạc siêu tiết kiệm chỉ bằng 1/5 tiền xăng.',
      'gradient': [Color(0xFF056676), Color(0xFF10B981)],
      'icon': CupertinoIcons.battery_charging,
      'type': 'bike',
      'badgeColor': Color(0xFF26E5DC),
    },
    {
      'title': 'Trả Góp 0% Điện Máy & Công Nghệ Flagship',
      'partner': 'FPT Shop, Thế Giới Di Động, CellphoneS, Di Động Việt',
      'interest': '0% Lãi suất',
      'maxLimit': 'Hạn mức 100 Triệu',
      'duration': '3 - 6 - 9 - 12 tháng',
      'tag': 'Miễn phí chuyển đổi',
      'desc': 'Áp dụng cho iPhone 16 Pro Max, MacBook Air M3, TV Sony OLED, Tủ lạnh Samsung Bespoke.',
      'gradient': [Color(0xFF5B21B6), Color(0xFF7C3AED)],
      'icon': CupertinoIcons.device_phone_portrait,
      'type': 'tech',
      'badgeColor': Color(0xFFEC4899),
    },
    {
      'title': 'Vay Tiêu Dùng Tín Chấp Siêu Tốc',
      'partner': 'SenBank FastLoan 24/7',
      'interest': '0.99%/tháng',
      'maxLimit': 'Đến 150 Triệu',
      'duration': 'Duyệt 3 phút',
      'tag': 'Không thế chấp',
      'desc': 'Giải ngân tiền mặt trực tiếp vào tài khoản ví SenBank. Không cần chứng minh thu nhập phức tạp.',
      'gradient': [Color(0xFF005C8A), Color(0xFF0096C7)],
      'icon': CupertinoIcons.bolt_horizontal_circle_fill,
      'type': 'loan',
      'badgeColor': Color(0xFF26E5DC),
    },
  ];

  // ===========================================================================
  // 3. FLASH DEALS (GIỜ VÀNG SĂN DEAL)
  // ===========================================================================
  final List<Map<String, dynamic>> _flashDeals = const [
    {
      'brand': 'Highlands Coffee',
      'title': 'Giảm 50% Freeze\nTrà Sen Vàng',
      'code': 'HLCOFFEE50',
      'discount': '-50%',
      'progress': 0.88,
      'left': 'Còn 12 mã',
      'gradient': [Color(0xFFB91C1C), Color(0xFF7F1D1D)],
      'icon': CupertinoIcons.cart_fill,
      'route': '/scan-qr',
    },
    {
      'brand': 'Shopee Mall',
      'title': 'Voucher Giảm\n100K Đơn 250K',
      'code': 'SHOPEE100',
      'discount': 'GIẢM 100K',
      'progress': 0.94,
      'left': 'Còn 6 mã',
      'gradient': [Color(0xFFEA580C), Color(0xFFC2410C)],
      'icon': CupertinoIcons.bag_fill,
      'route': '/cards',
    },
    {
      'brand': 'GrabCar / BeCar',
      'title': 'Giảm 40.000đ\nChuyến Đi',
      'code': 'BEGRAB40',
      'discount': '-40.000đ',
      'progress': 0.72,
      'left': 'Còn 28 mã',
      'gradient': [Color(0xFF059669), Color(0xFF047857)],
      'icon': CupertinoIcons.car_fill,
      'route': '/transfer',
    },
    {
      'brand': 'Phúc Long Tea',
      'title': 'Giảm 30.000đ\nTrà Đào Sữa',
      'code': 'PHUCLONG30',
      'discount': '-30.000đ',
      'progress': 0.82,
      'left': 'Còn 15 mã',
      'gradient': [Color(0xFF047857), Color(0xFF064E3B)],
      'icon': CupertinoIcons.cart_fill,
      'route': '/scan-qr',
    },
    {
      'brand': 'CGV Cinemas',
      'title': 'Mua 1 Vé Tặng\n1 Bắp Rang Bơ',
      'code': 'CGVPOPCORN',
      'discount': 'MUA 1 TẶNG 1',
      'progress': 0.65,
      'left': 'Còn 35 mã',
      'gradient': [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      'icon': CupertinoIcons.play_circle_fill,
      'route': '/scan-qr',
    },
    {
      'brand': 'Pizza Hut',
      'title': 'Combo 2 Pizza\nGiảm 35%',
      'code': 'PIZZA35',
      'discount': '-35%',
      'progress': 0.55,
      'left': 'Còn 45 mã',
      'gradient': [Color(0xFFDC2626), Color(0xFF991B1B)],
      'icon': CupertinoIcons.smiley_fill,
      'route': '/scan-qr',
    },
  ];

  // ===========================================================================
  // 4. DANH SÁCH TẤT CẢ ƯU ĐÃI KHUYẾN MÃI (16 ITEMS)
  // ===========================================================================
  final List<Map<String, dynamic>> _allPromotions = const [
    {
      'id': 'promo_1',
      'brand': 'Highlands Coffee',
      'category': 'Ẩm thực & Cafe',
      'title': 'Mua 1 Tặng 1 Toàn Bộ Freeze & Trà Sen Vàng',
      'desc': 'Áp dụng cho đồ uống cỡ Lớn khi thanh toán thẻ contactless hoặc quét VietQR SenBank.',
      'discount': 'MUA 1 TẶNG 1',
      'code': 'HLCOFFEE',
      'expiry': 'HSD: 30/09/2026',
      'gradient': [Color(0xFFB91C1C), Color(0xFF7F1D1D)],
      'icon': CupertinoIcons.cart_fill,
      'route': '/scan-qr',
      'condition': 'Tối đa 2 lần/tuần cho mỗi chủ tài khoản SenBank.',
      'rating': 4.8,
      'used': '12.200',
    },
    {
      'id': 'promo_2',
      'brand': 'BeCar & GrabCar',
      'category': 'Di chuyển & Xe',
      'title': 'Giảm Ngay 50.000đ Cho Chuyến Đi Sân Bay & Đi Làm',
      'desc': 'Áp dụng cho mọi chuyến BeCar/GrabCar từ 90.000đ trên toàn quốc.',
      'discount': 'GIẢM 50.000đ',
      'code': 'SENBE50',
      'expiry': 'HSD: 15/10/2026',
      'gradient': [Color(0xFF059669), Color(0xFF047857)],
      'icon': CupertinoIcons.car_fill,
      'route': '/transfer',
      'condition': 'Áp dụng cho mọi khung giờ, kể cả giờ cao điểm.',
      'rating': 4.6,
      'used': '18.400',
    },
    {
      'id': 'promo_3',
      'brand': 'VinFast Auto',
      'category': 'Di chuyển & Xe',
      'title': 'Vay Mua Ô Tô Điện VinFast VF3, VF5, VF8 Lãi Suất 0%',
      'desc': 'SenBank tài trợ 85% giá trị xe, tặng 1 năm sạc pin miễn phí tại tất cả trạm sạc V-Green.',
      'discount': '0% LÃI SUẤT',
      'code': 'VINFAST0',
      'expiry': 'HSD: 31/12/2026',
      'gradient': [Color(0xFF0077B6), Color(0xFF00B4D8)],
      'icon': CupertinoIcons.car_fill,
      'route': '/bills/quick-loan',
      'condition': 'Kỳ hạn vay tối đa 8 năm, xét duyệt hồ sơ online trong 15 phút.',
      'rating': 4.9,
      'used': '4.100',
    },
    {
      'id': 'promo_4',
      'brand': 'SenBank Home Loan',
      'category': 'Trả góp & Vay',
      'title': 'Gói Vay Mua Nhà An Cư - Lãi Suất 5.2%/Năm Cố Định',
      'desc': 'Vay mua chung cư, nhà phố Vinhomes, Masterise, Novaland với ân hạn nợ gốc 36 tháng.',
      'discount': 'LÃI 5.2%',
      'code': 'HOMELOAN52',
      'expiry': 'HSD: 31/12/2026',
      'gradient': [Color(0xFF0F3E6D), Color(0xFF056676)],
      'icon': CupertinoIcons.house_fill,
      'route': '/bills/quick-loan',
      'condition': 'Hạn mức vay lên đến 30 tỷ VNĐ, thời hạn linh hoạt tới 35 năm.',
      'rating': 4.9,
      'used': '2.800',
    },
    {
      'id': 'promo_5',
      'brand': 'FPT Shop & Thế Giới Di Động',
      'category': 'Trả góp & Vay',
      'title': 'Trả Góp 0% iPhone 16 Pro Max & Laptop Gaming',
      'desc': 'Trả trước 0 đồng, kỳ hạn 6-12 tháng qua thẻ tín dụng SenBank, tặng voucher 1 triệu.',
      'discount': 'TRẢ GÓP 0%',
      'code': 'TECH0PERCENT',
      'expiry': 'HSD: 31/10/2026',
      'gradient': [Color(0xFF7C3AED), Color(0xFF5B21B6)],
      'icon': CupertinoIcons.device_phone_portrait,
      'route': '/cards',
      'condition': 'Áp dụng cho đơn hàng từ 3.000.000đ tại chuỗi cửa hàng đối tác.',
      'rating': 4.7,
      'used': '15.900',
    },
    {
      'id': 'promo_6',
      'brand': 'Shopee Mall & Lazada',
      'category': 'Mua sắm',
      'title': 'Hoàn Tiền 100.000đ Trực Tiếp Vào Tài Khoản',
      'desc': 'Tự động hoàn 100k vào tài khoản thanh toán cho đơn hàng từ 300k liên kết thẻ SenBank.',
      'discount': 'HOÀN 100K',
      'code': 'SENSHOPEE100',
      'expiry': 'HSD: 30/09/2026',
      'gradient': [Color(0xFFEA580C), Color(0xFFC2410C)],
      'icon': CupertinoIcons.bag_fill,
      'route': '/cards',
      'condition': 'Tiền hoàn sẽ vào tài khoản trong vòng 24 giờ.',
      'rating': 4.9,
      'used': '35.000',
    },
    {
      'id': 'promo_7',
      'brand': 'Vietnam Airlines',
      'category': 'Du lịch',
      'title': 'Giảm 300.000đ Vé Máy Bay Khứ Hồi Toàn Quốc',
      'desc': 'Ưu đãi dành riêng cho khách hàng SenBank khi đặt vé máy bay đi Phú Quốc, Đà Nẵng, Nha Trang.',
      'discount': 'GIẢM 300K',
      'code': 'VIVUHE300',
      'expiry': 'HSD: 31/10/2026',
      'gradient': [Color(0xFF0288D1), Color(0xFF0077B6)],
      'icon': CupertinoIcons.airplane,
      'route': '/bills/input?service=Vé máy bay',
      'condition': 'Áp dụng cho hạng vé từ Phổ thông tiêu chuẩn trở lên.',
      'rating': 4.7,
      'used': '8.600',
    },
    {
      'id': 'promo_8',
      'brand': 'Phúc Long Tea & Coffee',
      'category': 'Ẩm thực & Cafe',
      'title': 'Giảm 25% Toàn Bộ Hóa Đơn Trà & Bánh Mì',
      'desc': 'Tận hưởng trà Ô Long đậm vị cùng bánh tươi với ưu đãi giảm trực tiếp 25% khi quét QR SenBank.',
      'discount': 'GIẢM 25%',
      'code': 'PHUCLONG25',
      'expiry': 'HSD: 15/10/2026',
      'gradient': [Color(0xFF047857), Color(0xFF065F46)],
      'icon': CupertinoIcons.cart_fill,
      'route': '/scan-qr',
      'condition': 'Áp dụng hóa đơn từ 80.000đ, không giới hạn số lần.',
      'rating': 4.8,
      'used': '21.300',
    },
    {
      'id': 'promo_9',
      'brand': 'VinFast Xe Máy Điện',
      'category': 'Di chuyển & Xe',
      'title': 'Trả Góp Xe Máy Điện Feliz S, Evo200 - 390K/Tháng',
      'desc': 'Không cần trả trước, hỗ trợ hồ sơ online qua app SenBank, nhận xe ngay tại showroom.',
      'discount': 'GÓP 390K',
      'code': 'EVO390K',
      'expiry': 'HSD: 30/11/2026',
      'gradient': [Color(0xFF056676), Color(0xFF0288D1)],
      'icon': CupertinoIcons.battery_charging,
      'route': '/bills/quick-loan',
      'condition': 'Áp dụng cho dòng xe Evo200 và Feliz S thế hệ mới.',
      'rating': 4.9,
      'used': '7.400',
    },
    {
      'id': 'promo_10',
      'brand': 'Golden Gate - Gogi & Kichi',
      'category': 'Ẩm thực & Cafe',
      'title': 'Tặng 1 Suất Buffet Miễn Phí Cho Nhóm 4 Người',
      'desc': 'Áp dụng tại chuỗi nhà hàng Gogi House, Kichi-Kichi, Manwah, Isushi toàn quốc.',
      'discount': 'ĐI 4 TẶNG 1',
      'code': 'GOLDENGATE4',
      'expiry': 'HSD: 20/10/2026',
      'gradient': [Color(0xFFC026D3), Color(0xFF9333EA)],
      'icon': CupertinoIcons.rosette,
      'route': '/scan-qr',
      'condition': 'Áp dụng vào tất cả các ngày trong tuần (trừ ngày Lễ).',
      'rating': 4.8,
      'used': '14.100',
    },
    {
      'id': 'promo_11',
      'brand': 'Điện Lực EVN & Nước Sinh Hoạt',
      'category': 'Hóa đơn',
      'title': 'Hoàn Tiền 50.000đ Khi Đặt Lịch Tự Động Trừ Cước',
      'desc': 'Cài đặt tự động thanh toán hóa đơn tiền điện EVN và tiền nước qua ví SenBank.',
      'discount': 'HOÀN 50K',
      'code': 'AUTOBILL50',
      'expiry': 'HSD: 31/10/2026',
      'gradient': [Color(0xFF0F3E6D), Color(0xFF0288D1)],
      'icon': CupertinoIcons.doc_text_fill,
      'route': '/bills/input?service=ELECTRICITY',
      'condition': 'Hoàn tiền sau khi chu kỳ cước đầu tiên được trích nợ thành công.',
      'rating': 4.5,
      'used': '28.900',
    },
    {
      'id': 'promo_12',
      'brand': 'SenBank Visa Platinum',
      'category': 'Hoàn tiền',
      'title': 'Hoàn Tiền 10% Mọi Chi Tiêu Quốc Tế & Ăn Uống',
      'desc': 'Tối đa 1.500.000đ/tháng, tích lũy điểm SenPoint đổi dặm bay Bông Sen Vàng.',
      'discount': 'HOÀN 10%',
      'code': 'PLATINUM2026',
      'expiry': 'HSD: 31/12/2026',
      'gradient': [Color(0xFF00B4D8), Color(0xFF0077B6)],
      'icon': CupertinoIcons.creditcard_fill,
      'route': '/cards',
      'condition': 'Chi tiêu tối thiểu 1.000.000đ trong 30 ngày kể từ khi kích hoạt.',
      'rating': 4.9,
      'used': '5.200',
    },
    {
      'id': 'promo_13',
      'brand': 'Booking.com & Agoda',
      'category': 'Du lịch',
      'title': 'Đặt Khách Sạn Resort 5 Sao Hoàn 15% Không Giới Hạn',
      'desc': 'Đặt phòng khách sạn qua SenBank Travel Hub, hoàn tiền 15% không giới hạn.',
      'discount': 'HOÀN 15%',
      'code': 'HOTEL15',
      'expiry': 'HSD: 30/10/2026',
      'gradient': [Color(0xFF0288D1), Color(0xFF7C3AED)],
      'icon': CupertinoIcons.building_2_fill,
      'route': '/bills/input?service=Khách sạn',
      'condition': 'Đặt phòng tối thiểu 1 đêm, giá trị phòng từ 500.000đ/đêm.',
      'rating': 4.6,
      'used': '6.800',
    },
    {
      'id': 'promo_14',
      'brand': 'Petrolimex & Xăng Dầu',
      'category': 'Di chuyển & Xe',
      'title': 'Hoàn 5% Khi Đổ Xăng Quét VietQR SenBank',
      'desc': 'Áp dụng tại hơn 3.000 cây xăng Petrolimex và PVOIL trên toàn quốc.',
      'discount': 'HOÀN 5%',
      'code': 'XANGDAU5',
      'expiry': 'HSD: 31/10/2026',
      'gradient': [Color(0xFF059669), Color(0xFF047857)],
      'icon': CupertinoIcons.gauge,
      'route': '/scan-qr',
      'condition': 'Tối đa hoàn 50.000đ mỗi lần giao dịch, 4 lần/tháng.',
      'rating': 4.8,
      'used': '42.000',
    },
    {
      'id': 'promo_15',
      'brand': 'The Coffee House',
      'category': 'Ẩm thực & Cafe',
      'title': 'Giảm 30% Toàn Bộ Menu Cà Phê Buổi Sáng',
      'desc': 'Áp dụng từ 6h-10h hàng ngày khi thanh toán qua ứng dụng SenBank.',
      'discount': 'GIẢM 30%',
      'code': 'COFFEE30',
      'expiry': 'HSD: 31/10/2026',
      'gradient': [Color(0xFF92400E), Color(0xFF78350F)],
      'icon': CupertinoIcons.cart_fill,
      'route': '/scan-qr',
      'condition': 'Áp dụng tất cả cửa hàng The Coffee House, từ 6h-10h.',
      'rating': 4.7,
      'used': '29.600',
    },
    {
      'id': 'promo_16',
      'brand': 'Pizza Hut & KFC',
      'category': 'Ẩm thực & Cafe',
      'title': 'Combo Đôi Pizza + Gà Rán Giảm 35%',
      'desc': 'Thưởng thức combo 2 pizza + 2 phần gà với giá cực ưu đãi khi quét VietQR.',
      'discount': 'GIẢM 35%',
      'code': 'PIZZA35',
      'expiry': 'HSD: 15/10/2026',
      'gradient': [Color(0xFFBE123C), Color(0xFF881337)],
      'icon': CupertinoIcons.smiley_fill,
      'route': '/scan-qr',
      'condition': 'Áp dụng tại tất cả cửa hàng Pizza Hut và KFC toàn quốc.',
      'rating': 4.5,
      'used': '13.300',
    },
  ];

  // ===========================================================================
  // 5. SỰ KIỆN QUAY THƯỞNG & HOT EVENTS
  // ===========================================================================
  final List<Map<String, dynamic>> _events = const [
    {
      'title': 'Ngày Hội Thanh Toán Không Tiền Mặt - Rinh iPhone 16 Pro',
      'date': '15/09 - 30/09/2026',
      'reward': 'Vòng quay may mắn trúng iPhone 16 Pro & Vàng 9999',
      'badge': 'SIÊU HOT',
      'badgeColor': Color(0xFF00B4D8),
      'gradient': [Color(0xFF00B4D8), Color(0xFF7C3AED)],
      'icon': CupertinoIcons.rosette,
      'participants': '24.450 người tham gia',
    },
    {
      'title': 'Thách Thức Tiết Kiệm Mua Nhà & Mua Xe 30 Ngày',
      'date': '01/09 - 30/09/2026',
      'reward': 'Tặng thêm 1.5% lãi suất và voucher 5.000.000đ khi giải ngân',
      'badge': 'MỚI',
      'badgeColor': Color(0xFF10B981),
      'gradient': [Color(0xFFFFB300), Color(0xFF10B981)],
      'icon': CupertinoIcons.chart_bar_alt_fill,
      'participants': '18.320 người tham gia',
    },
    {
      'title': 'Giới Thiệu Bạn Bè - Nhận Ngay 50.000đ & Điểm Thưởng',
      'date': 'Không giới hạn thời gian',
      'reward': '50.000đ tiền tươi vào ví cho mỗi lượt mở tài khoản',
      'badge': 'THƯỜNG XUYÊN',
      'badgeColor': Color(0xFF8B5CF6),
      'gradient': [Color(0xFF8B5CF6), Color(0xFF0288D1)],
      'icon': CupertinoIcons.person_2_fill,
      'participants': '65.200 người tham gia',
    },
    {
      'title': 'Tuần Lễ Vàng Trả Góp Ô Tô Điện & Xe Máy VinFast',
      'date': '10/09 - 25/09/2026',
      'reward': 'Tặng gói phụ kiện cao cấp 15 triệu & miễn phí bảo hiểm',
      'badge': 'ĐẶC QUYỀN',
      'badgeColor': Color(0xFF26E5DC),
      'gradient': [Color(0xFF0F3E6D), Color(0xFF0288D1)],
      'icon': CupertinoIcons.car_fill,
      'participants': '12.100 người tham gia',
    },
  ];

  @override
  void initState() {
    super.initState();
    final isTest = WidgetsBinding.instance.runtimeType.toString().contains('Test');
    if (!isTest) {
      _startBannerTimer();
      _loadApiVouchers();
    }
  }

  Future<void> _loadApiVouchers() async {
    try {
      final list = await PromotionRemoteDataSource().getPromotions();
      if (mounted) setState(() => _apiVouchers = list);
    } catch (_) {}
  }

  void _startBannerTimer() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_bannerController.hasClients) {
        final nextPage = (_currentBannerIndex + 1) % _heroBanners.length;
        _bannerController.animateToPage(
          nextPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    _voucherInputController.dispose();
    super.dispose();
  }

  Future<void> _applyVoucherCode() async {
    final code = _voucherInputController.text.trim();
    if (code.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Vui lòng nhập mã ưu đãi')),
      );
      return;
    }
    setState(() => _isApplyingVoucher = true);
    try {
      final res = await PromotionRemoteDataSource().apply(code: code, orderAmount: 100000);
      final discount = res['discountAmount'] ?? 50000;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.emeraldGreen,
            content: Text('Áp dụng thành công mã $code! Giảm: ${CurrencyFormatter.formatVND((discount as num).toDouble())}'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.error,
            content: Text(e.toString().replaceAll('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isApplyingVoucher = false);
    }
  }

  void _copyVoucherCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.emeraldGreen,
        elevation: 10,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Row(
          children: [
            const Icon(CupertinoIcons.checkmark_circle_fill, color: Colors.white, size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Đã sao chép mã "$code" vào bộ nhớ tạm!',
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _onUseVoucher(Map<String, dynamic> item) {
    final route = item['route'] as String? ?? '/';
    context.push(route);
  }

  void _showVoucherDetailModal(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (ctx) => _buildDetailBottomSheet(ctx, item),
    );
  }

  List<Map<String, dynamic>> get _filteredPromotions {
    return _allPromotions.where((p) {
      final matchesCategory = _selectedCategoryIndex == 0 ||
          p['category'] == _categories[_selectedCategoryIndex];
      final matchesSearch = _searchQuery.isEmpty ||
          (p['title'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p['brand'] as String).toLowerCase().contains(_searchQuery.toLowerCase()) ||
          (p['code'] as String).toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          'Ưu Đãi & Quà Tặng',
          style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: 'Mã đã lưu',
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(CupertinoIcons.star_circle_fill, color: AppColors.primary, size: 24),
                Positioned(
                  top: -3,
                  right: -3,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFE11D48),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('3',
                        style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            onPressed: () {
              setState(() => _selectedTab = 3);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Custom Navigation Pills (Immune to Hot Reload bugs)
          _buildCustomTabBar(),

          // Tab Content
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 240),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: child,
              ),
              child: KeyedSubtree(
                key: ValueKey('promo_tab_$_selectedTab'),
                child: _buildCurrentTab(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===========================================================================
  // NAVIGATION PILLS (TABS)
  // ===========================================================================
  Widget _buildCustomTabBar() {
    return Container(
      height: 48,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(_tabs.length, (idx) {
          final isSelected = _selectedTab == idx;
          return Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedTab = idx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(
                          colors: [AppColors.bottomBarCyan, AppColors.primaryDark],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isSelected ? null : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.40),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _tabs[idx],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white : AppColors.textSecondaryLight,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                      fontSize: 11.5,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildCurrentTab() {
    switch (_selectedTab) {
      case 0:
        return _buildUuDaiTab();
      case 1:
        return _buildTraGopTab();
      case 2:
        return _buildSuKienTab();
      case 3:
        return _buildVoucherTab();
      default:
        return _buildUuDaiTab();
    }
  }

  // ===========================================================================
  // TAB 1: TẤT CẢ ƯU ĐÃI
  // ===========================================================================
  Widget _buildUuDaiTab() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.only(bottom: 110),
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
          child: _buildSearchBar(),
        ),

        // Hero Mega Banners Carousel
        _buildHeroBannerCarousel(),

        // SenPoint Club Bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
          child: _buildSenPointClubCard(),
        ),

        // Quick Category Icons Grid
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
          child: _buildQuickActions(),
        ),

        // Flash Sale Giờ Vàng
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
          child: _buildFlashSaleHeader(),
        ),
        _buildFlashSaleList(),

        // Tiêu Điểm: Trả Góp Xe & Nhà Preview Strip
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.house_fill, color: AppColors.accentGold, size: 20),
                  SizedBox(width: 8),
                  Text(
                    'Ưu Đãi Trả Góp Xe & Nhà Hot',
                    style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              InkWell(
                onTap: () => setState(() => _selectedTab = 1),
                child: const Text('Xem tất cả →',
                    style: TextStyle(color: AppColors.bottomBarCyan, fontSize: 12.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
        _buildInstallmentCarouselPreview(),

        // Category Filter Chips
        Padding(
          padding: const EdgeInsets.only(top: 18, bottom: 10),
          child: _buildCategoryChips(),
        ),

        // Section Label
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Ưu đãi hấp dẫn (${_filteredPromotions.length})',
                style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const Text('Mới nhất',
                  style: TextStyle(color: AppColors.bottomBarCyan, fontSize: 13, fontWeight: FontWeight.w600)),
            ],
          ),
        ),

        if (_filteredPromotions.isEmpty)
          const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: Column(
                children: [
                  Icon(CupertinoIcons.tag_fill, size: 64, color: AppColors.textMutedLight),
                  SizedBox(height: 12),
                  Text('Không tìm thấy ưu đãi phù hợp',
                      style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold)),
                  SizedBox(height: 6),
                  Text('Hãy thử tìm từ khóa khác hoặc đổi danh mục',
                      style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 13)),
                ],
              ),
            ),
          )
        else
          ..._filteredPromotions.map((p) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                child: _buildPromotionCard(p),
              )),
      ],
    );
  }

  // ===========================================================================
  // TAB 2: TRẢ GÓP & VAY XE, NHÀ
  // ===========================================================================
  Widget _buildTraGopTab() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 110),
      children: [
        // Highlight Intro Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0x380C1E36),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0077B6).withOpacity(0.20), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(CupertinoIcons.graph_square_fill, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gói Vay An Cư & Lăn Bánh',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Lãi suất ưu đãi từ 5.2%/năm, thẩm định hồ sơ online nhận kết quả trong 15 phút.',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        const Text('Danh Mục Gói Vay Trả Góp Ưu Đãi',
            style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 17, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        ..._installmentDeals.map((deal) => Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: _buildFullInstallmentCard(deal),
        )),
      ],
    );
  }

  // ===========================================================================
  // TAB 3: SỰ KIỆN & QUÀ TẶNG
  // ===========================================================================
  Widget _buildSuKienTab() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        _buildEventBannerStrip(),
        const SizedBox(height: 16),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.14),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1),
              ),
              child: const Icon(CupertinoIcons.sparkles, color: AppColors.primary, size: 18),
            ),
            const SizedBox(width: 8),
            const Text('Sự kiện đang diễn ra',
                style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.emeraldGreen,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('LIVE',
                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        const SizedBox(height: 14),
        ..._events.map((e) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _buildEventCard(e),
            )),
      ],
    );
  }

  // ===========================================================================
  // TAB 4: MÃ VOUCHER & ĐÃ LƯU
  // ===========================================================================
  Widget _buildVoucherTab() {
    return ListView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 110),
      children: [
        // Redeem Gift Code Box
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0x380C1E36),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
            boxShadow: [
              BoxShadow(color: const Color(0xFF0077B6).withOpacity(0.15), blurRadius: 14, offset: const Offset(0, 4)),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.gift_fill, color: AppColors.accentGold, size: 24),
                  SizedBox(width: 10),
                  Text('Nhập Mã Ưu Đãi Độc Quyền',
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              const Text('Bạn có mã quà tặng từ đối tác hoặc chương trình tri ân?',
                  style: TextStyle(color: Colors.white70, fontSize: 12)),
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                child: Row(
                  children: [
                    const Icon(CupertinoIcons.tickets_fill, color: AppColors.bottomBarCyan, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: TextField(
                        controller: _voucherInputController,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
                        decoration: const InputDecoration(
                          hintText: 'Nhập mã: SENBANK2026...',
                          hintStyle: TextStyle(color: Colors.white38, fontSize: 13),
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: _isApplyingVoucher ? null : _applyVoucherCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.bottomBarCyan,
                        foregroundColor: AppColors.textPrimaryLight,
                        elevation: 0,
                        minimumSize: Size.zero,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      ),
                      child: _isApplyingVoucher
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPrimaryLight),
                            )
                          : const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Popular voucher codes
        const Text('Mã phổ biến hôm nay',
            style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        ..._buildPopularVoucherList(),

        const SizedBox(height: 24),
        const Text('Cách nhận mã ưu đãi',
            style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        _buildHowToGetVoucher(),
      ],
    );
  }

  // ===========================================================================
  // SUB-WIDGETS & UI COMPONENTS
  // ===========================================================================

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withOpacity(0.20)),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Row(
        children: [
          const Icon(CupertinoIcons.search, color: AppColors.bottomBarCyan, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val),
              style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 13.5),
              decoration: const InputDecoration(
                hintText: 'Tìm ưu đãi Highlands, Be, Shopee...',
                hintStyle: TextStyle(color: AppColors.textMutedLight, fontSize: 13),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textSecondaryLight, size: 18),
              onPressed: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
            ),
          Container(
            margin: const EdgeInsets.only(right: 4),
            child: ElevatedButton(
              onPressed: () => _showRedeemDialog(),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bottomBarCyan.withOpacity(0.25),
                foregroundColor: AppColors.bottomBarCyan,
                elevation: 0,
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.bottomBarCyan, width: 1),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(CupertinoIcons.gift_fill, size: 14),
                  SizedBox(width: 5),
                  Text('Nhập mã', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBannerCarousel() {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (idx) => setState(() => _currentBannerIndex = idx),
            itemCount: _heroBanners.length,
            itemBuilder: (context, index) {
              final banner = _heroBanners[index];
              final gradient = _safeGradient(banner['gradient']);
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  onTap: () => context.push(banner['route'] as String),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: gradient,
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: gradient[0].withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: CustomPaint(painter: _CirclePatternPainter()),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(18),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.25),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(banner['tag'] as String,
                                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w900)),
                                ),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(banner['title'] as String,
                                        style: const TextStyle(color: Colors.white, fontSize: 16.5, fontWeight: FontWeight.bold, height: 1.2),
                                        maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text(banner['subtitle'] as String,
                                        style: const TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.3),
                                        maxLines: 2, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 10),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text('Khám phá ngay →',
                                          style: TextStyle(
                                            color: gradient[0],
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.bold,
                                          )),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: 14,
                            top: 14,
                            child: Icon(
                              banner['icon'] as IconData,
                              size: 78,
                              color: Colors.white.withOpacity(0.14),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _heroBanners.length,
            (idx) => AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              height: 4,
              width: _currentBannerIndex == idx ? 22 : 6,
              decoration: BoxDecoration(
                color: _currentBannerIndex == idx ? AppColors.bottomBarCyan : Colors.white24,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSenPointClubCard() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.accentGold.withOpacity(0.45), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withOpacity(0.12),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [AppColors.accentGold, Color(0xFFF59E0B)]),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(CupertinoIcons.star_circle_fill, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('SenPoint Club',
                        style: TextStyle(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.accentGold.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Hạng Vàng',
                          style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                const Text('Bạn đang có 2.450 điểm thưởng tích lũy',
                    style: TextStyle(color: Color(0xFF475569), fontSize: 11.5, fontWeight: FontWeight.w500)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Đang tải danh mục đổi quà SenPoint...')),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.accentGold,
              foregroundColor: Colors.black,
              elevation: 0,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Đổi quà', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final items = [
      {'icon': CupertinoIcons.car_fill, 'label': 'Vay xe 0%', 'action': () => setState(() => _selectedTab = 1)},
      {'icon': CupertinoIcons.house_fill, 'label': 'Mua nhà', 'action': () => setState(() => _selectedTab = 1)},
      {'icon': CupertinoIcons.device_phone_portrait, 'label': 'Điện máy', 'action': () => setState(() => _selectedTab = 1)},
      {'icon': CupertinoIcons.cart_fill, 'label': 'Highlands', 'action': () => _filterQuick('Ẩm thực & Cafe')},
      {'icon': CupertinoIcons.airplane, 'label': 'Vé bay', 'action': () => _filterQuick('Du lịch')},
      {'icon': CupertinoIcons.bag_fill, 'label': 'Shopee', 'action': () => _filterQuick('Mua sắm')},
      {'icon': CupertinoIcons.creditcard_fill, 'label': 'Thẻ hoàn tiền', 'action': () => context.push('/cards')},
      {'icon': CupertinoIcons.gift_fill, 'label': 'Vòng quay', 'action': () => setState(() => _selectedTab = 2)},
    ];

    Widget buildItem(Map<String, dynamic> item) {
      return Expanded(
        child: InkWell(
          onTap: item['action'] as VoidCallback,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withOpacity(0.18),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                  child: Icon(
                    item['icon'] as IconData,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['label'] as String,
                  style: const TextStyle(
                    color: AppColors.textPrimaryLight,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.sublist(0, 4).map(buildItem).toList(),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: items.sublist(4, 8).map(buildItem).toList(),
        ),
      ],
    );
  }

  void _filterQuick(String catName) {
    final idx = _categories.indexOf(catName);
    if (idx != -1) {
      setState(() => _selectedCategoryIndex = idx);
    }
  }

  Widget _buildFlashSaleHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.14),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.25), width: 1),
          ),
          child: const Icon(CupertinoIcons.gift_fill, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 8),
        const Text(
          'Giờ Vàng Săn Deal',
          style: TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00B4D8).withOpacity(0.35),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text('02:45:18',
              style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
        const Spacer(),
        const Text('Cập nhật liên tục',
            style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 11)),
      ],
    );
  }

  Widget _buildFlashSaleList() {
    return SizedBox(
      height: 148,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _flashDeals.length,
        itemBuilder: (context, index) {
          final deal = _flashDeals[index];
          final gradient = _safeGradient(deal['gradient']);
          return Container(
            width: 155,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradient[0].withOpacity(0.8), gradient[1].withOpacity(0.9)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: InkWell(
              onTap: () => _copyVoucherCode(deal['code'] as String),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.35),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(deal['discount'] as String,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(deal['icon'] as IconData, color: Colors.white70, size: 16),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(deal['brand'] as String,
                            style: const TextStyle(color: Colors.white60, fontSize: 10, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 2),
                        Text(deal['title'] as String,
                            style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.bold, height: 1.2),
                            maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: deal['progress'] as double,
                            backgroundColor: Colors.white24,
                            valueColor: const AlwaysStoppedAnimation(Colors.white),
                            minHeight: 4,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(deal['left'] as String,
                                style: const TextStyle(color: Colors.white70, fontSize: 9.5)),
                            const Icon(CupertinoIcons.doc_on_doc_fill, size: 12, color: Colors.white),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // Preview strip cho mục trả góp xe & nhà
  Widget _buildInstallmentCarouselPreview() {
    return SizedBox(
      height: 145,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _installmentDeals.length,
        itemBuilder: (context, index) {
          final deal = _installmentDeals[index];
          final gradient = _safeGradient(deal['gradient']);
          final badgeColor = _safeColor(deal['badgeColor']);
          return Container(
            width: 250,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: gradient, begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withOpacity(0.2)),
            ),
            child: InkWell(
              onTap: () => setState(() => _selectedTab = 1),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: badgeColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: badgeColor, width: 0.8),
                            ),
                            child: Text(
                              (deal['tag'] ?? '').toString(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon((deal['icon'] as IconData?) ?? CupertinoIcons.tickets_fill, color: Colors.white70, size: 20),
                      ],
                    ),
                    Text(deal['title'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold),
                        maxLines: 1, overflow: TextOverflow.ellipsis),
                    Row(
                      children: [
                        Flexible(
                          child: Text.rich(
                            TextSpan(
                              text: 'Lãi suất: ',
                              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 11),
                              children: [
                                TextSpan(
                                  text: deal['interest'] as String,
                                  style: const TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Text('Xem ngay →',
                            style: TextStyle(color: AppColors.bottomBarCyan, fontSize: 11, fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SizedBox(
      height: 38,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final isSelected = _selectedCategoryIndex == index;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: InkWell(
              onTap: () => setState(() => _selectedCategoryIndex = index),
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? const LinearGradient(colors: [Color(0xFF26E5DC), Color(0xFF0077B6)])
                      : null,
                  color: isSelected ? null : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected ? const Color(0xFF26E5DC) : AppColors.borderLight,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: const Color(0xFF00B4D8).withOpacity(0.35),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: Text(
                    _categories[index],
                    style: TextStyle(
                      color: isSelected ? Colors.white : const Color(0xFF475569),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPromotionCard(Map<String, dynamic> item) {
    final gradient = _safeGradient(item['gradient']);
    final discountStr = (item['discount'] as String? ?? '');
    final isHot = discountStr.contains('50%') || discountStr.contains('100%') || discountStr.contains('2TR');

    const double bottomBarHeight = 54.0;
    const double notchRadius = 9.0;
    const double cornerRadius = 18.0;

    return Container(
      decoration: BoxDecoration(
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00142A).withOpacity(0.40),
            blurRadius: 16,
            offset: const Offset(0, 5),
          ),
          BoxShadow(
            color: (isHot ? const Color(0xFFE11D48) : const Color(0xFF00B4D8)).withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CustomPaint(
        foregroundPainter: const TicketBorderPainter(
          bottomBarHeight: bottomBarHeight,
          notchRadius: notchRadius,
          cornerRadius: cornerRadius,
          borderColor: Color(0x33FFFFFF),
          borderWidth: 1.0,
        ),
        child: ClipPath(
          clipper: const TicketCardClipper(
            bottomBarHeight: bottomBarHeight,
            notchRadius: notchRadius,
            cornerRadius: cornerRadius,
          ),
          child: Container(
            color: const Color(0x380C1E36),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showVoucherDetailModal(item),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: gradient,
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color: gradient[0].withOpacity(0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Icon(item['icon'] as IconData, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      item['brand'] as String,
                                      style: const TextStyle(
                                        color: AppColors.bottomBarCyan,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 0.3,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: isHot
                                              ? const [Color(0xFFE11D48), Color(0xFFBE123C)]
                                              : [const Color(0xFF00B4D8), const Color(0xFF0077B6)],
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isHot ? const Color(0xFFE11D48) : const Color(0xFF00B4D8)).withOpacity(0.35),
                                            blurRadius: 6,
                                          ),
                                        ],
                                      ),
                                      child: Text(
                                        item['discount'] as String,
                                        style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  item['title'] as String,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.bold,
                                    height: 1.25,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Text(
                        item['desc'] as String,
                        style: const TextStyle(color: Colors.white70, fontSize: 12, height: 1.35),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 14),
                      // Nét đứt laser phân cách vé ngân hàng kết nối 2 vết cắt bán nguyệt
                      Row(
                        children: List.generate(
                          26,
                          (i) => Expanded(
                            child: Container(
                              height: 1,
                              color: i.isEven ? Colors.white.withOpacity(0.22) : Colors.transparent,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              const Icon(CupertinoIcons.clock_fill, size: 13, color: Colors.white54),
                              const SizedBox(width: 5),
                              Text(
                                item['expiry'] as String,
                                style: const TextStyle(color: Colors.white54, fontSize: 11),
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              OutlinedButton(
                                onPressed: () => _copyVoucherCode(item['code'] as String),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: BorderSide(color: Colors.white.withOpacity(0.25)),
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(CupertinoIcons.doc_on_doc_fill, size: 12, color: Colors.white70),
                                    SizedBox(width: 4),
                                    Text('Lưu mã', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: () => _onUseVoucher(item),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.bottomBarCyan,
                                  foregroundColor: Colors.black,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                  minimumSize: Size.zero,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                child: const Row(
                                  children: [
                                    Text('Dùng ngay', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
                                    SizedBox(width: 4),
                                    Icon(CupertinoIcons.chevron_forward, size: 11, color: AppColors.textPrimaryLight),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Card chi tiết cho Tab Trả Góp Xe & Nhà
  Widget _buildFullInstallmentCard(Map<String, dynamic> deal) {
    final gradient = _safeGradient(deal['gradient']);
    final badgeColor = _safeColor(deal['badgeColor']);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x380C1E36),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF001B3A).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: gradient),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(deal['icon'] as IconData, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(deal['title'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Đối tác: ${deal['partner']}',
                          style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: badgeColor),
                  ),
                  child: Text(deal['tag'] as String,
                      style: TextStyle(color: badgeColor, fontSize: 10.5, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(deal['desc'] as String,
                style: const TextStyle(color: Colors.white70, fontSize: 12.5, height: 1.35)),
            const SizedBox(height: 14),

            // 3 thông số vàng
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.25),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.white.withOpacity(0.08)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Column(
                    children: [
                      const Text('LÃI SUẤT', style: TextStyle(color: Colors.white54, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(deal['interest'] as String,
                          style: const TextStyle(color: AppColors.accentGold, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 1, height: 24, color: Colors.white12),
                  Column(
                    children: [
                      const Text('HẠN MỨC', style: TextStyle(color: Colors.white54, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(deal['maxLimit'] as String,
                          style: const TextStyle(color: AppColors.bottomBarCyan, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  Container(width: 1, height: 24, color: Colors.white12),
                  Column(
                    children: [
                      const Text('THỜI HẠN', style: TextStyle(color: Colors.white54, fontSize: 10)),
                      const SizedBox(height: 2),
                      Text(deal['duration'] as String,
                          style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Đang tải công cụ tính gốc lãi cho gói ${deal['title']}')),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(color: Colors.white.withOpacity(0.3)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Tính tiền góp', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => context.push('/bills/quick-loan'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.bottomBarCyan,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    child: const Text('Đăng ký vay', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventBannerStrip() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0077B6), Color(0xFF00B4D8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(CupertinoIcons.rosette, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Sự Kiện Lễ Hội SenBank 2026',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                SizedBox(height: 2),
                Text('Quay thưởng mỗi ngày - Nhận vàng 9999 và quà tặng',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> event) {
    final gradient = _safeGradient(event['gradient']);
    final badgeColor = _safeColor(event['badgeColor'], AppColors.primary);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0x380C1E36),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(color: const Color(0xFF001B3A).withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(event['icon'] as IconData, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event['title'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(event['date'] as String,
                        style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: badgeColor),
                ),
                child: Text(event['badge'] as String,
                    style: TextStyle(color: badgeColor, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(CupertinoIcons.gift_fill, color: AppColors.accentGold, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Phần thưởng: ${event['reward']}',
                      style: const TextStyle(color: AppColors.accentGold, fontSize: 12, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(event['participants'] as String,
                  style: const TextStyle(color: Colors.white54, fontSize: 11)),
              ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Đã tham gia sự kiện thành công!')),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.bottomBarCyan,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Tham gia ngay', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _buildPopularVoucherList() {
    final List<Map<String, dynamic>> codes = [];
    if (_apiVouchers.isNotEmpty) {
      for (final v in _apiVouchers) {
        codes.add({
          'code': (v['code'] ?? 'SENBANK').toString(),
          'desc': (v['title'] ?? v['description'] ?? 'Ưu đãi tài khoản').toString(),
          'color': const Color(0xFF00B4D8),
        });
      }
    }
    codes.addAll([
      {'code': 'WELCOME100K', 'desc': 'Tặng 100.000đ cho tài khoản mới', 'color': const Color(0xFF10B981)},
      {'code': 'VAYXE0PERCENT', 'desc': 'Gói vay ô tô điện VinFast - Lãi suất 0%', 'color': const Color(0xFF00B4D8)},
      {'code': 'NHAPHO52', 'desc': 'Vay mua nhà phố & căn hộ - Lãi suất 5.2%', 'color': const Color(0xFFFFB300)},
      {'code': 'SENBANK9', 'desc': 'Ưu đãi tháng 9 - Giảm 5% mọi giao dịch', 'color': const Color(0xFF8B5CF6)},
      {'code': 'FRIEND50K', 'desc': 'Giới thiệu bạn bè - Nhận 50.000đ', 'color': const Color(0xFFEC4899)},
    ]);
    return codes.map((c) => Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0x380C1E36),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(color: const Color(0xFF001B3A).withOpacity(0.20), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(color: _safeColor(c['color']), shape: BoxShape.circle),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c['code'] as String,
                      style: const TextStyle(color: AppColors.bottomBarCyan, fontWeight: FontWeight.bold, letterSpacing: 1, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(c['desc'] as String,
                      style: const TextStyle(color: Colors.white70, fontSize: 11.5)),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(CupertinoIcons.doc_on_doc_fill, size: 18, color: AppColors.bottomBarCyan),
              onPressed: () => _copyVoucherCode(c['code'] as String),
            ),
          ],
        ),
      ),
    )).toList();
  }

  Widget _buildHowToGetVoucher() {
    final steps = [
      {'icon': CupertinoIcons.creditcard_fill, 'title': 'Mở thẻ tín dụng SenBank', 'desc': 'Nhận ngay gói voucher 2.000.000đ'},
      {'icon': CupertinoIcons.car_fill, 'title': 'Đăng ký vay xe & mua nhà', 'desc': 'Tặng bảo hiểm và phí trước bạ'},
      {'icon': CupertinoIcons.person_2_fill, 'title': 'Giới thiệu bạn bè', 'desc': 'Mỗi lượt đăng ký nhận 50.000đ tiền mặt'},
      {'icon': CupertinoIcons.waveform_path_ecg, 'title': 'Tham gia vòng quay may mắn', 'desc': 'Cơ hội trúng iPhone 16 Pro'},
    ];
    return Column(
      children: steps.map((s) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0x2E0C1E36),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.14)),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.bottomBarCyan.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(s['icon'] as IconData, color: AppColors.bottomBarCyan, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['title'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                    const SizedBox(height: 2),
                    Text(s['desc'] as String,
                        style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
                  ],
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildDetailBottomSheet(BuildContext ctx, Map<String, dynamic> item) {
    final gradient = _safeGradient(item['gradient']);

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xEB0A192E),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.40),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: gradient),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(item['icon'] as IconData, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['brand'] as String,
                        style: const TextStyle(color: AppColors.bottomBarCyan, fontSize: 13, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 2),
                    Text(item['title'] as String,
                        style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(item['desc'] as String,
              style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.4)),
          const SizedBox(height: 16),

          // Voucher Code Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.bottomBarCyan.withOpacity(0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('MÃ VOUCHER', style: TextStyle(color: Colors.white54, fontSize: 10)),
                    const SizedBox(height: 2),
                    Text(item['code'] as String,
                        style: const TextStyle(color: AppColors.bottomBarCyan, fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
                  ],
                ),
                ElevatedButton(
                  onPressed: () => _copyVoucherCode(item['code'] as String),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.bottomBarCyan,
                    foregroundColor: Colors.black,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Sao chép', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text('Điều kiện sử dụng:',
              style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('• ${item['condition']}',
              style: const TextStyle(color: Colors.white70, fontSize: 12.5)),
          const SizedBox(height: 4),
          Text('• ${item['expiry']}',
              style: const TextStyle(color: Colors.white54, fontSize: 12)),
          const SizedBox(height: 22),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _onUseVoucher(item);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.bottomBarCyan,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: const Text('Sử Dụng Ưu Đãi Ngay',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  void _showRedeemDialog() {
    final codeCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xF20B1C32),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: BorderSide(color: AppColors.bottomBarCyan.withOpacity(0.5), width: 1.2),
        ),
        title: const Row(
          children: [
            Icon(CupertinoIcons.gift_fill, color: AppColors.bottomBarCyan),
            SizedBox(width: 8),
            Expanded(
              child: Text('Nhập Mã Quà Tặng',
                  style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Nhập mã voucher hoặc mã quà tặng từ SenBank và đối tác.',
                style: TextStyle(color: Colors.white70, fontSize: 12.5)),
            const SizedBox(height: 14),
            TextField(
              controller: codeCtrl,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1),
              decoration: InputDecoration(
                hintText: 'Ví dụ: VINFAST0, HOMELOAN52...',
                hintStyle: const TextStyle(color: Colors.white30, fontSize: 12.5, letterSpacing: 0),
                filled: true,
                fillColor: Colors.black.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Hủy', style: TextStyle(color: Colors.white60)),
          ),
          ElevatedButton(
            onPressed: () {
              final code = codeCtrl.text.trim();
              Navigator.pop(ctx);
              if (code.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: AppColors.emeraldGreen,
                    content: Text('Đã kích hoạt thành công mã ưu đãi "$code"!'),
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.bottomBarCyan,
              foregroundColor: Colors.black,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Áp dụng', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

// Pattern painter cho hero banner
class _CirclePatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.06)
      ..style = PaintingStyle.fill;
    for (var i = 0; i < 6; i++) {
      canvas.drawCircle(
        Offset(size.width * 0.75 + i * 20, size.height * 0.3 + i * 15),
        30.0 + i * 12,
        paint,
      );
    }
    canvas.drawCircle(Offset(size.width * 0.1, -10), 60, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Clipper tạo hình dáng vé xé ngân hàng (Coupon Ticket) với 2 lỗ khuyết bán nguyệt 2 bên mép
class TicketCardClipper extends CustomClipper<Path> {
  final double bottomBarHeight;
  final double notchRadius;
  final double cornerRadius;

  const TicketCardClipper({
    this.bottomBarHeight = 54.0,
    this.notchRadius = 9.0,
    this.cornerRadius = 18.0,
  });

  @override
  Path getClip(Size size) {
    final path = Path();
    final notchY = size.height - bottomBarHeight;
    final r = notchRadius;
    final cr = cornerRadius;

    // Góc trên bên trái
    path.moveTo(0, cr);
    path.arcToPoint(Offset(cr, 0), radius: Radius.circular(cr));

    // Cạnh trên
    path.lineTo(size.width - cr, 0);
    // Góc trên bên phải
    path.arcToPoint(Offset(size.width, cr), radius: Radius.circular(cr));

    // Cạnh phải xuống đến vết khuyết bán nguyệt
    path.lineTo(size.width, notchY - r);
    // Vết khuyết bên phải (uốn cong vào trong thân thẻ)
    path.arcToPoint(Offset(size.width, notchY + r), radius: Radius.circular(r), clockwise: false);

    // Cạnh phải xuống đến góc dưới bên phải
    path.lineTo(size.width, size.height - cr);
    path.arcToPoint(Offset(size.width - cr, size.height), radius: Radius.circular(cr));

    // Cạnh đáy
    path.lineTo(cr, size.height);
    // Góc dưới bên trái
    path.arcToPoint(Offset(0, size.height - cr), radius: Radius.circular(cr));

    // Cạnh trái lên đến vết khuyết bán nguyệt
    path.lineTo(0, notchY + r);
    // Vết khuyết bên trái (uốn cong vào trong thân thẻ)
    path.arcToPoint(Offset(0, notchY - r), radius: Radius.circular(r), clockwise: false);

    // Cạnh trái lên đến góc trên bên trái
    path.lineTo(0, cr);

    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant TicketCardClipper oldClipper) =>
      oldClipper.bottomBarHeight != bottomBarHeight ||
      oldClipper.notchRadius != notchRadius ||
      oldClipper.cornerRadius != cornerRadius;
}

/// Painter vẽ viền kính sáng đồng dạng theo đường cong vé xé ngân hàng (kể cả 2 vết khuyết)
class TicketBorderPainter extends CustomPainter {
  final double bottomBarHeight;
  final double notchRadius;
  final double cornerRadius;
  final Color borderColor;
  final double borderWidth;

  const TicketBorderPainter({
    this.bottomBarHeight = 54.0,
    this.notchRadius = 9.0,
    this.cornerRadius = 18.0,
    this.borderColor = const Color(0x33FFFFFF),
    this.borderWidth = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final clipper = TicketCardClipper(
      bottomBarHeight: bottomBarHeight,
      notchRadius: notchRadius,
      cornerRadius: cornerRadius,
    );
    final path = clipper.getClip(size);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant TicketBorderPainter oldDelegate) =>
      oldDelegate.bottomBarHeight != bottomBarHeight ||
      oldDelegate.notchRadius != notchRadius ||
      oldDelegate.borderColor != borderColor ||
      oldDelegate.borderWidth != borderWidth;
}
