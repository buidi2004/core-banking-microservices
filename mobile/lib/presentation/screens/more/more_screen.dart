import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/data/datasources/auth_local_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/auth_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/core/storage/app_session.dart';
import '../../widgets/user_avatar_widget.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _displayName = 'KHÁCH HÀNG SENBANK';
  String _accountNumber = '';
  String _kycStatus = 'Hội Viên Sen V-Gold • eKYC Cấp 2';
  String _searchQuery = '';
  int _easterEggTapCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      const storage = FlutterSecureStorage();
      final savedPhone = await storage.read(key: AppConstants.keyPhoneNumber);
      final savedName = await storage.read(key: AppConstants.keyFullName);
      if (mounted && (savedPhone != null || savedName != null)) {
        setState(() {
          if (savedPhone != null && savedPhone.isNotEmpty) _accountNumber = savedPhone;
          if (savedName != null && savedName.isNotEmpty) _displayName = savedName.toUpperCase();
        });
      }

      final profile = await ProfileRemoteDataSource().getMe();
      if (!mounted) return;
      setState(() {
        final fullName = profile['fullName'] as String?;
        if (fullName != null && fullName.isNotEmpty) {
          _displayName = fullName.toUpperCase();
        }
        final phone = profile['phoneNumber'] as String?;
        if (phone != null && phone.isNotEmpty) {
          _accountNumber = phone;
        }
      });

      final kyc = await ProfileRemoteDataSource().getKycStatus();
      if (kyc != null && mounted) {
        final status = kyc['status'] as String? ?? 'VERIFIED';
        final level = kyc['level'] ?? 2;
        setState(() {
          _kycStatus = 'Hội Viên Sen V-Gold • eKYC Cấp $level ($status)';
        });
      }
    } catch (_) {}
  }

  List<Map<String, dynamic>> _getAllCatalogItems(BuildContext context) {
    const Color defaultIconBg = Color(0x1400A896); // AppColors.primary with 8% tint
    const Color defaultIconColor = AppColors.primaryDark;

    return [
      // 1. Quản lý thẻ
      {
        'id': 'cards',
        'title': 'Quản lý thẻ Sen Hồng (Visa / Napas)',
        'sub': 'Khóa/mở thẻ, hạn mức thanh toán, đổi PIN thẻ',
        'icon': LucideIcons.creditCard,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Tài chính & Nguồn tiền',
        'keywords': ['the', 'thẻ', 'visa', 'napas', 'khoa the', 'pin the', 'the tin dung', 'the ghi no'],
        'onTap': () => context.push('/cards'),
      },
      // 2. Tiết kiệm
      {
        'id': 'savings',
        'title': 'Tiết kiệm Sen Lộc Phát Online',
        'sub': 'Lãi suất dẫn đầu tới 7.4%/năm, tất toán 24/7',
        'icon': LucideIcons.landmark,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Tài chính & Nguồn tiền',
        'keywords': ['tiet kiem', 'tiết kiệm', 'lai suat', 'lãi suất', 'sen loc phat', 'gui tien', 'so tiet kiem'],
        'onTap': () => context.push('/bills/savings'),
      },
      // 3. Hạn mức & KYC
      {
        'id': 'kyc-level',
        'title': 'Hạn mức giao dịch & Cấp độ eKYC',
        'sub': '100 triệu/ngày • Nâng cấp Cấp 3 không giới hạn',
        'icon': LucideIcons.barChart2,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Tài chính & Nguồn tiền',
        'keywords': ['han muc', 'hạn mức', 'kyc', 'cap do', 'nang cap', 'dinh danh', 'level'],
        'onTap': () => context.push('/profile/kyc-level'),
      },
      // 4. Hồ sơ CCCD
      {
        'id': 'identity',
        'title': 'Hồ sơ CCCD & Sinh trắc học',
        'sub': 'Đối soát chip C06 Quyết định 2345/QĐ-NHNN',
        'icon': LucideIcons.fileText,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Tài chính & Nguồn tiền',
        'keywords': ['cccd', 'can cuoc', 'sinh trac hoc', 'c06', 'qd 2345', 'khuon mat', 'khuôn mặt'],
        'onTap': () => context.push('/profile/identity-document'),
      },
      // 5. Vay tiêu dùng
      {
        'id': 'quick-loan',
        'title': 'Vay tiêu dùng siêu tốc',
        'sub': 'Hạn mức duyệt sẵn đến 50 triệu giải ngân 5 phút',
        'icon': LucideIcons.zap,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Tài chính & Nguồn tiền',
        'keywords': ['vay', 'vay tieu dung', 'tin chap', 'tin chấp', 'lai suat', 'muon tien', 'loan'],
        'onTap': () => context.push('/bills/quick-loan'),
      },
      // 6. Ngân hàng liên kết
      {
        'id': 'bank-cards',
        'title': 'Tài khoản ngân hàng liên kết',
        'sub': 'Nạp rút tiền nhanh 24/7 qua Napas & VietQR',
        'icon': LucideIcons.building2,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Tài chính & Nguồn tiền',
        'keywords': ['ngan hang', 'ngân hàng', 'lien ket', 'nap', 'rut', 'tai khoan', 'napas', 'vietqr'],
        'onTap': () => context.push('/bank-cards'),
      },
      // 7. Danh bạ thụ hưởng
      {
        'id': 'beneficiaries',
        'title': 'Danh bạ người thụ hưởng',
        'sub': 'Quản lý tài khoản chuyển tiền đã lưu',
        'icon': LucideIcons.users,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Tài chính & Nguồn tiền',
        'keywords': ['danh ba', 'danh bạ', 'thu huong', 'thụ hưởng', 'nguoi quen', 'so tai khoan'],
        'onTap': () => context.push('/beneficiaries'),
      },
      // 8. Vé số Vietlott
      {
        'id': 'lottery',
        'title': 'Vé số Vietlott Online',
        'sub': 'Mega 6/45, Power 6/55, Keno trúng thưởng tự động',
        'icon': LucideIcons.ticket,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Dịch vụ & Tiện ích đời sống',
        'keywords': ['ve so', 'vé số', 'vietlott', 'mega', 'power', 'keno', 'so so', 'xổ số'],
        'onTap': () => context.push('/bills/lottery'),
      },
      // 9. Nạp tiền điện thoại
      {
        'id': 'phone-recharge',
        'title': 'Nạp tiền điện thoại (Top-up)',
        'sub': 'Chiết khấu tới 3% cho Viettel, VinaPhone, MobiFone',
        'icon': LucideIcons.smartphone,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Dịch vụ & Tiện ích đời sống',
        'keywords': ['nap tien dien thoai', 'nạp tiền', 'the cao', 'topup', 'viettel', 'vinaphone', 'mobifone', 'data 4g'],
        'onTap': () => context.push('/bills/phone-recharge'),
      },
      // 10. Thanh toán hóa đơn
      {
        'id': 'bills',
        'title': 'Thanh toán hóa đơn thiết yếu',
        'sub': 'Điện EVN, Nước sinh hoạt, Internet, Truyền hình cáp',
        'icon': LucideIcons.receipt,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Dịch vụ & Tiện ích đời sống',
        'keywords': ['hoa don', 'hóa đơn', 'dien', 'điện', 'nuoc', 'nước', 'internet', 'evn', 'truyen hinh'],
        'onTap': () => context.push('/bills'),
      },
      // 11. Giới thiệu bạn bè
      {
        'id': 'referral',
        'title': 'Giới thiệu bạn bè nhận thưởng',
        'sub': 'Nhận 50.000đ khi mời bạn mới đăng ký thành công',
        'icon': LucideIcons.gift,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Dịch vụ & Tiện ích đời sống',
        'keywords': ['gioi thieu', 'giới thiệu', 'ban be', 'hoa hong', 'thuong', 'qua tang', 'referral'],
        'onTap': () => context.push('/referral'),
      },
      // 12. Cài đặt bảo mật & Smart OTP
      {
        'id': 'security',
        'title': 'Cài đặt bảo mật & Smart OTP',
        'sub': 'Xác thực sinh trắc học FaceID, PIN 6 số, PKI',
        'icon': LucideIcons.shieldCheck,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Bảo mật & Cấu hình ứng dụng',
        'keywords': ['bao mat', 'bảo mật', 'smart otp', 'faceid', 'biometric', 'pki', 'chu ky so'],
        'onTap': () => context.push('/settings/security'),
      },
      // 13. Đổi mã PIN giao dịch
      {
        'id': 'change-pin',
        'title': 'Đổi mã PIN giao dịch bảo mật',
        'sub': 'Cập nhật mã PIN 6 số với bàn phím số xáo trộn',
        'icon': LucideIcons.keyRound,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Bảo mật & Cấu hình ứng dụng',
        'keywords': ['doi pin', 'đổi pin', 'ma pin', 'mat khau', 'giao dich', 'passcode'],
        'onTap': () => context.push('/settings/change-pin'),
      },
      // 14. Xác thực Chip CCCD qua NFC
      {
        'id': 'nfc',
        'title': 'Xác thực Chip CCCD (NFC)',
        'sub': 'Quét chip đối soát căn cước chuẩn QĐ 2345/QĐ-NHNN',
        'icon': LucideIcons.nfc,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Bảo mật & Cấu hình ứng dụng',
        'keywords': ['nfc', 'quet chip', 'cccd gắn chip', 'xac thuc chip', 'c06'],
        'onTap': () => context.push('/profile/nfc-reader'),
      },
      // 15. Cài đặt thông báo
      {
        'id': 'notifications-settings',
        'title': 'Cài đặt thông báo & Chuông Ting Ting',
        'sub': 'Quản lý thông báo OTT, SMS biến động số dư',
        'icon': LucideIcons.bell,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Bảo mật & Cấu hình ứng dụng',
        'keywords': ['thong bao', 'thông báo', 'ting ting', 'sms', 'ott', 'bien dong so du'],
        'onTap': () => context.push('/notifications/settings'),
      },
      // 16. Quản lý thiết bị đăng nhập
      {
        'id': 'devices',
        'title': 'Quản lý phiên & Thiết bị đăng nhập',
        'sub': 'Kiểm soát các điện thoại đăng nhập, đăng xuất từ xa',
        'icon': LucideIcons.smartphone,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Bảo mật & Cấu hình ứng dụng',
        'keywords': ['thiet bi', 'thiết bị', 'dang nhap', 'dang xuat tu xa', 'phien', 'device'],
        'onTap': () => context.push('/settings/devices'),
      },
      // 17. Tùy biến giao diện Liquid Glass
      {
        'id': 'theme',
        'title': 'Giao diện Liquid Glass & Hiệu ứng',
        'sub': 'Tùy biến bảng màu đại dương và độ mờ kính thủy tinh',
        'icon': LucideIcons.palette,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Bảo mật & Cấu hình ứng dụng',
        'keywords': ['giao dien', 'giao diện', 'hinh nen', 'liquid glass', 'dark mode', 'theme', 'mau sac'],
        'onTap': () => context.push('/settings'),
      },
      // 18. Hotline & Help Center
      {
        'id': 'help-center',
        'title': 'Trung tâm trợ giúp & Hotline 24/7',
        'sub': 'Tổng đài 1900 6688 • Khóa thẻ và tài khoản khẩn cấp',
        'icon': LucideIcons.phoneCall,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Trợ giúp & Pháp lý ngân hàng',
        'keywords': ['tro giup', 'trợ giúp', 'hotline', 'tong dai', 'khoa the', 'khẩn cấp', 'support', 'cskh'],
        'onTap': () => context.push('/support/help-center'),
      },
      // 19. Live Chat
      {
        'id': 'live-chat',
        'title': 'Live Chat với chuyên viên hỗ trợ',
        'sub': 'Tư vấn trực tuyến phản hồi ngay trong 30 giây',
        'icon': LucideIcons.messageSquare,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Trợ giúp & Pháp lý ngân hàng',
        'keywords': ['live chat', 'chat', 'tu van', 'chuyen vien', 'ho tro', 'tin nhan'],
        'onTap': () => context.push('/support/live-chat'),
      },
      // 20. Điều khoản dịch vụ
      {
        'id': 'terms',
        'title': 'Điều khoản dịch vụ & Giấy phép NHNN',
        'sub': 'Quy chế sử dụng dịch vụ ngân hàng số và quyền riêng tư',
        'icon': LucideIcons.fileText,
        'iconBg': defaultIconBg,
        'iconColor': defaultIconColor,
        'category': 'Trợ giúp & Pháp lý ngân hàng',
        'keywords': ['dieu khoan', 'điều khoản', 'phap ly', 'giay phep', 'nhnn', 'chinh sach', 'nghi dinh 13'],
        'onTap': () => context.push('/auth/terms'),
      },
    ];
  }

  void _showDeveloperDiagnosticsModal() {
    showCupertinoModalPopup<void>(
      context: context,
      builder: (BuildContext ctx) => CupertinoActionSheet(
        title: const Text('Công Cụ Phát Triển & Chẩn Đoán Hệ Thống', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        message: const Text('Các tùy chọn dành cho kiểm thử viên và kỹ sư hệ thống Sen Hồng'),
        actions: <CupertinoActionSheetAction>[
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/splash');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.sparkles, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Trải nghiệm màn mở đầu Hoa Sen Nở (/splash)'),
              ],
            ),
          ),
          CupertinoActionSheetAction(
            onPressed: () {
              Navigator.pop(ctx);
              context.push('/settings/config');
            },
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(CupertinoIcons.antenna_radiowaves_left_right, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text('Cấu hình Gateway & Server Backend (/settings/config)'),
              ],
            ),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Đóng', style: TextStyle(color: AppColors.textPrimaryLight, fontWeight: FontWeight.bold)),
        ),
      ),
    );
  }

  void _handleLogout() {
    HapticFeedback.mediumImpact();
    showCupertinoModalPopup<void>(
      context: context,
      builder: (ctx) => CupertinoActionSheet(
        title: const Text(
          'Đăng Xuất Tài Khoản?',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight),
        ),
        message: const Text(
          'Bạn có chắc chắn muốn đăng xuất khỏi tài khoản Sen Hồng Bank trên thiết bị này?',
          style: TextStyle(fontSize: 13, color: AppColors.textSecondaryLight),
        ),
        actions: [
          CupertinoActionSheetAction(
            isDestructiveAction: true,
            onPressed: () async {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              try {
                final prefs = await SharedPreferences.getInstance();
                final localAuth = AuthLocalDataSourceImpl(prefs: prefs);
                final authRemote = AuthRemoteDataSource(local: localAuth);
                await authRemote.logout();
              } catch (e) {
                debugPrint('[MoreScreen] Logout error: $e');
              } finally {
                AppSession.unlocked = false;
                if (mounted) {
                  context.go('/auth/login');
                }
              }
            },
            child: const Text('Đăng Xuất', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
        cancelButton: CupertinoActionSheetAction(
          isDefaultAction: true,
          onPressed: () => Navigator.pop(ctx),
          child: const Text('Hủy', style: TextStyle(color: AppColors.primary)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catalog = _getAllCatalogItems(context);
    final filtered = _searchQuery.isEmpty
        ? <Map<String, dynamic>>[]
        : catalog.where((item) {
            final title = (item['title'] as String).toLowerCase();
            final sub = (item['sub'] as String).toLowerCase();
            final keywords = (item['keywords'] as List<String>);
            if (title.contains(_searchQuery) || sub.contains(_searchQuery)) return true;
            return keywords.any((k) => k.contains(_searchQuery));
          }).toList();

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Tiện Ích & Dịch Vụ'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            icon: const Icon(LucideIcons.bell, color: AppColors.textPrimaryLight, size: 20),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/notifications');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfile,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Cupertino-style Search Bar
                _buildSearchBar(),

                // Search Results Mode
                if (_searchQuery.isNotEmpty) ...[
                  _buildSearchResults(filtered),
                ] else ...[
                  // User Profile Card (Apple ID Style)
                  _buildUserCard(context),
                  const SizedBox(height: 14),

                  // Loyalty Points Card
                  _buildLoyaltyBanner(context),
                  const SizedBox(height: 18),

                  // Quick Actions Grid (8 Apple Squircles)
                  _buildQuickActionsGrid(context),
                  const SizedBox(height: 20),

                  // Group 1: Tài chính, Thẻ & Tiết kiệm
                  _buildGroupedSection(
                    sectionTitle: 'TÀI CHÍNH & NGUỒN TIỀN',
                    items: catalog.where((i) => i['category'] == 'Tài chính & Nguồn tiền').toList(),
                  ),
                  const SizedBox(height: 16),

                  // Group 2: Dịch vụ & Đời sống
                  _buildGroupedSection(
                    sectionTitle: 'TIỆN ÍCH ĐỜI SỐNG',
                    items: catalog.where((i) => i['category'] == 'Dịch vụ & Tiện ích đời sống').toList(),
                  ),
                  const SizedBox(height: 16),

                  // Group 3: Bảo mật & Cài đặt
                  _buildGroupedSection(
                    sectionTitle: 'BẢO MẬT & HỆ THỐNG',
                    items: catalog.where((i) => i['category'] == 'Bảo mật & Cấu hình ứng dụng').toList(),
                  ),
                  const SizedBox(height: 16),

                  // Group 4: Chăm sóc khách hàng & Pháp lý
                  _buildGroupedSection(
                    sectionTitle: 'HỖ TRỢ & PHÁP LÝ',
                    items: catalog.where((i) => i['category'] == 'Trợ giúp & Pháp lý ngân hàng').toList(),
                  ),
                  const SizedBox(height: 24),

                  // Logout Button
                  _buildLogoutButton(),
                  const SizedBox(height: 24),

                  // Footer with version & 5-tap developer modal
                  _buildBankingFooter(),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.85),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: CupertinoSearchTextField(
        controller: _searchCtrl,
        placeholder: 'Tìm kiếm tiện ích, dịch vụ, hóa đơn, bảo mật...',
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimaryLight),
        placeholderStyle: const TextStyle(fontSize: 13, color: AppColors.textMutedLight),
        backgroundColor: Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        onChanged: (val) {
          setState(() {
            _searchQuery = val.trim().toLowerCase();
          });
        },
        onSuffixTap: () {
          HapticFeedback.lightImpact();
          _searchCtrl.clear();
          setState(() {
            _searchQuery = '';
          });
        },
      ),
    );
  }

  Widget _buildSearchResults(List<Map<String, dynamic>> filtered) {
    if (filtered.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
        alignment: Alignment.center,
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.search, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: 14),
            Text(
              'Không tìm thấy tiện ích',
              style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Không có dịch vụ nào khớp với từ khóa "$_searchQuery". Hãy thử tìm: thẻ, tiết kiệm, vay, hóa đơn, pin...',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight, height: 1.4),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8, top: 4),
          child: Text(
            'KẾT QUẢ TÌM KIẾM (${filtered.length})',
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        GlassCard(
          quality: GlassQuality.minimal,
          child: Column(
            children: filtered.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isLast = idx == filtered.length - 1;
              return Column(
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        (item['onTap'] as VoidCallback)();
                      },
                      leading: Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: item['iconBg'] as Color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x1F00A896)),
                        ),
                        child: Icon(item['icon'] as IconData, color: item['iconColor'] as Color, size: 19),
                      ),
                      title: Text(
                        item['title'] as String,
                        style: AppTypography.bodyMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      subtitle: Text(
                        item['sub'] as String,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                      ),
                      trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textMutedLight, size: 16),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 64, color: AppColors.dividerLight),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context) {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          context.push('/profile');
        },
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              UserAvatarWidget(
                radius: 28,
                borderColor: AppColors.bottomBarCyan,
                onTap: () => context.push('/profile'),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            _displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 6),
                        const Icon(LucideIcons.badgeCheck, color: AppColors.emeraldGreen, size: 16),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Text(
                          'STK: ${_accountNumber.isNotEmpty ? _accountNumber : "Chưa liên kết"}',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            Clipboard.setData(ClipboardData(text: _accountNumber));
                            HapticFeedback.lightImpact();
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                backgroundColor: AppColors.emeraldGreen,
                                content: Text('Đã sao chép STK: $_accountNumber'),
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: const Icon(LucideIcons.copy, size: 13, color: AppColors.primary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _kycStatus,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(LucideIcons.chevronRight, color: AppColors.textMutedLight, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoyaltyBanner(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          colors: [AppColors.cardDark, AppColors.textPrimaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: AppColors.bottomBarCyan.withOpacity(0.18),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.sparkles, color: AppColors.bottomBarCyan, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '12.450 SenPoints',
                  style: TextStyle(color: AppColors.bottomBarCyan, fontSize: 15, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 2),
                Text(
                  'Đổi voucher Grab, Shopee, Highlands',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.bottomBarCyan),
              foregroundColor: AppColors.bottomBarCyan,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(60, 32),
            ),
            onPressed: () {
              HapticFeedback.selectionClick();
              context.push('/promotions');
            },
            child: const Text('Đổi quà', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsGrid(BuildContext context) {
    const Color defaultBg = Color(0x1000A896); // primary 6% subtle system tint
    const Color defaultBorder = Color(0x1F00A896); // primary 12% subtle border
    const Color defaultIconColor = AppColors.primaryDark;

    final quickActions = [
      {
        'label': 'Thẻ Sen Hồng',
        'icon': LucideIcons.creditCard,
        'onTap': () => context.push('/cards'),
      },
      {
        'label': 'Tiết Kiệm',
        'icon': LucideIcons.landmark,
        'onTap': () => context.push('/bills/savings'),
      },
      {
        'label': 'Vay Siêu Tốc',
        'icon': LucideIcons.zap,
        'onTap': () => context.push('/bills/quick-loan'),
      },
      {
        'label': 'Hóa Đơn',
        'icon': LucideIcons.receipt,
        'onTap': () => context.push('/bills'),
      },
      {
        'label': 'Nạp ĐT (Top-up)',
        'icon': LucideIcons.smartphone,
        'onTap': () => context.push('/bills/phone-recharge'),
      },
      {
        'label': 'Vé Vietlott',
        'icon': LucideIcons.ticket,
        'onTap': () => context.push('/bills/lottery'),
      },
      {
        'label': 'Liên Kết NH',
        'icon': LucideIcons.building2,
        'onTap': () => context.push('/bank-cards'),
      },
      {
        'label': 'Danh Bạ',
        'icon': LucideIcons.users,
        'onTap': () => context.push('/beneficiaries'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'TIỆN ÍCH TRỌNG TÂM',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        GlassCard(
          quality: GlassQuality.minimal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: quickActions.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (ctx, index) {
                final item = quickActions[index];
                return InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    (item['onTap'] as VoidCallback)();
                  },
                  borderRadius: BorderRadius.circular(14),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: defaultBg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: defaultBorder),
                        ),
                        child: Icon(item['icon'] as IconData, color: defaultIconColor, size: 22),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item['label'] as String,
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGroupedSection({required String sectionTitle, required List<Map<String, dynamic>> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            sectionTitle,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
        GlassCard(
          quality: GlassQuality.minimal,
          child: Column(
            children: items.asMap().entries.map((entry) {
              final idx = entry.key;
              final item = entry.value;
              final isLast = idx == items.length - 1;
              return Column(
                children: [
                  Material(
                    type: MaterialType.transparency,
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                      onTap: () {
                        HapticFeedback.selectionClick();
                        (item['onTap'] as VoidCallback)();
                      },
                      leading: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: item['iconBg'] as Color,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0x1F00A896)),
                        ),
                        child: Icon(item['icon'] as IconData, color: item['iconColor'] as Color, size: 18),
                      ),
                      title: Text(
                        item['title'] as String,
                        style: AppTypography.bodyMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.w600, fontSize: 13.5),
                      ),
                      subtitle: item['sub'] != null
                          ? Text(
                              item['sub'] as String,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
                            )
                          : null,
                      trailing: const Icon(LucideIcons.chevronRight, color: AppColors.textMutedLight, size: 16),
                    ),
                  ),
                  if (!isLast) const Divider(height: 1, indent: 62, color: AppColors.dividerLight),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton() {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: OutlinedButton.icon(
        onPressed: _handleLogout,
        icon: const Icon(LucideIcons.logOut, color: AppColors.error, size: 18),
        label: Text(
          'Đăng xuất tài khoản',
          style: AppTypography.titleSmall(color: AppColors.error).copyWith(fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.white.withOpacity(0.85),
          side: BorderSide(color: AppColors.error.withOpacity(0.35)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _buildBankingFooter() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(CupertinoIcons.suit_diamond_fill, size: 13, color: AppColors.primary),
            SizedBox(width: 6),
            Text(
              'SEN HỒNG DIGITAL BANK',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: AppColors.textPrimaryLight, letterSpacing: 0.8),
            ),
          ],
        ),
        const SizedBox(height: 4),
        const Text(
          'Giấy phép hoạt động số 88/GP-NHNN do Ngân hàng Nhà nước cấp\n'
          'Bảo hiểm tiền gửi Việt Nam (DIV) bảo trợ theo Luật các TCTD\n'
          'Hotline 24/7: 1900 6688 • contact@senbank.vn',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight, height: 1.4),
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () {
            _easterEggTapCount++;
            if (_easterEggTapCount >= 5) {
              _easterEggTapCount = 0;
              HapticFeedback.heavyImpact();
              _showDeveloperDiagnosticsModal();
            } else if (_easterEggTapCount >= 2) {
              HapticFeedback.selectionClick();
            }
          },
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.55),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white.withOpacity(0.4)),
            ),
            child: const Text(
              'Phiên bản 2.4.0 (Build 2026.10.21)',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.textMutedLight),
            ),
          ),
        ),
      ],
    );
  }
}
