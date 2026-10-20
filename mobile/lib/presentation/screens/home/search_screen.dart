import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  int _selectedFilterIdx = 0; // 0: Tat ca, 1: Dich vu, 2: Thu huong, 3: Huong dan

  @override
  void initState() {
    super.initState();
    // Chờ 480ms cho hiệu ứng chuyển màn hình diễn ra chậm rãi, mượt mà xong hẳn rồi mới mở bàn phím
    // Đảm bảo không xảy ra bất kỳ hiện tượng khựng khung hình nào
    Future.delayed(const Duration(milliseconds: 480), () {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  final List<String> _recentSearches = [
    'Chuyển tiền Napas',
    'Tiền điện EVN',
    'Tiết kiệm Phát Lộc',
    'Mã PIN Smart OTP',
  ];

  final List<String> _trendingKeywords = [
    'Chuyển tiền 24/7',
    'Nạp ĐT 3%',
    'Tiết kiệm 7.4%',
    'EVN Hóa đơn',
    'Vé Vietlott',
    'Face Match 2345',
  ];

  final List<Map<String, dynamic>> _features = const [
    {
      'title': 'Chuyển tiền Napas 24/7',
      'sub': 'Chuyển liên ngân hàng hoặc nội bộ tức thì',
      'category': 'Dịch vụ',
      'keywords': 'chuyen tien napas 247 ibft ngan hang stk',
      'icon': CupertinoIcons.paperplane_fill,
      'route': '/transfer',
    },
    {
      'title': 'Nạp tiền vào tài khoản',
      'sub': 'Nạp từ thẻ ghi nợ ngân hàng liên kết',
      'category': 'Dịch vụ',
      'keywords': 'nap tien nguon tien ngan hang lien ket',
      'icon': CupertinoIcons.arrow_down_circle_fill,
      'route': '/deposit',
    },
    {
      'title': 'Rút tiền về ngân hàng',
      'sub': 'Rút tiền tức thì miễn phí 24/7',
      'category': 'Dịch vụ',
      'keywords': 'rut tien ve tai khoan ngan hang',
      'icon': CupertinoIcons.arrow_up_circle_fill,
      'route': '/withdraw',
    },
    {
      'title': 'Nạp tiền điện thoại (Top-up)',
      'sub': 'Chiết khấu 3% Viettel, Vinaphone, Mobifone',
      'category': 'Dịch vụ',
      'keywords': 'nap dien thoai topup the cao viettel vina mobi',
      'icon': CupertinoIcons.device_phone_portrait,
      'route': '/bills/phone-recharge',
    },
    {
      'title': 'Thanh toán tiền điện EVN',
      'sub': 'Tra cứu và nộp tiền điện toàn quốc',
      'category': 'Dịch vụ',
      'keywords': 'tien dien evn hoa don dien luc',
      'icon': CupertinoIcons.bolt_fill,
      'route': '/bills/input?service=Tiền điện',
    },
    {
      'title': 'Thanh toán tiền nước sinh hoạt',
      'sub': 'Sawaco, Viwaco, Chợ Lớn, Nước ngầm',
      'category': 'Dịch vụ',
      'keywords': 'tien nuoc hoa don sawaco viwaco',
      'icon': CupertinoIcons.drop_fill,
      'route': '/bills/input?service=Tiền nước',
    },
    {
      'title': 'Vé số Vietlott Online',
      'sub': 'Mega 6/45, Power 6/55, Keno trúng thưởng',
      'category': 'Dịch vụ',
      'keywords': 'vietlott keno mega power xo so',
      'icon': CupertinoIcons.ticket_fill,
      'route': '/bills/lottery',
    },
    {
      'title': 'Mở sổ tiết kiệm Sen Lộc Phát',
      'sub': 'Lãi suất dẫn đầu thị trường đến 7.4%/năm',
      'category': 'Dịch vụ',
      'keywords': 'tiet kiem online so tiet kiem lai suat sinh loi',
      'icon': CupertinoIcons.archivebox_fill,
      'route': '/bills/savings',
    },
    {
      'title': 'Vay tiêu dùng siêu tốc',
      'sub': 'Duyệt hạn mức tự động 50 triệu trong 3 phút',
      'category': 'Dịch vụ',
      'keywords': 'vay tin chap tieu dung han muc',
      'icon': CupertinoIcons.bolt_horizontal_circle_fill,
      'route': '/bills/quick-loan',
    },
    {
      'title': 'Quản lý thẻ Sen Hồng (Cards)',
      'sub': 'Khóa/mở thẻ tức thì, cấp lại PIN thẻ, hạn mức',
      'category': 'Dịch vụ',
      'keywords': 'the tin dung the visa napas kho the pin the',
      'icon': CupertinoIcons.creditcard_fill,
      'route': '/cards',
    },
    {
      'title': 'Hồ sơ CCCD & eKYC sinh trắc học',
      'sub': 'Đối soát C06 & chip NFC theo QĐ 2345/QĐ-NHNN',
      'category': 'Hướng dẫn',
      'keywords': 'ekyc cccd can cuoc chip sinh trac hoc 2345',
      'icon': CupertinoIcons.person_crop_circle_badge_checkmark,
      'route': '/profile/identity-document',
    },
    {
      'title': 'Hạn mức giao dịch & KYC Level',
      'sub': 'Xem hạn mức ngày và nâng cấp hạn mức',
      'category': 'Hướng dẫn',
      'keywords': 'han muc kyc level cap do chuyen tien toi da',
      'icon': CupertinoIcons.gauge,
      'route': '/profile/kyc-level',
    },
    {
      'title': 'Danh bạ người thụ hưởng',
      'sub': 'Quản lý tài khoản ngân hàng và ví đã lưu',
      'category': 'Thụ hưởng',
      'keywords': 'danh ba nguoi thu huong tk da luu ban be',
      'icon': CupertinoIcons.person_2_fill,
      'route': '/beneficiaries',
    },
    {
      'title': 'Cài đặt bảo mật & Smart OTP',
      'sub': 'Đổi mã PIN, FaceID, kích hoạt Smart OTP PKI',
      'category': 'Hướng dẫn',
      'keywords': 'bao mat smart otp pin face id mat khau',
      'icon': CupertinoIcons.lock_shield_fill,
      'route': '/settings/security',
    },
    {
      'title': 'Lịch sử giao dịch & Tra soát',
      'sub': 'Xem biên lai chi tiết, tải PDF và tạo tra soát',
      'category': 'Dịch vụ',
      'keywords': 'lich su giao dich bien lai sao ke tra soat',
      'icon': CupertinoIcons.doc_text_search,
      'route': '/history',
    },
  ];

  @override
  void dispose() {
    _focusNode.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> get _results {
    List<Map<String, dynamic>> list = _features;
    if (_selectedFilterIdx == 1) {
      list = list.where((f) => f['category'] == 'Dịch vụ').toList();
    } else if (_selectedFilterIdx == 2) {
      list = list.where((f) => f['category'] == 'Thụ hưởng').toList();
    } else if (_selectedFilterIdx == 3) {
      list = list.where((f) => f['category'] == 'Hướng dẫn').toList();
    }

    if (_query.trim().isEmpty) return list;
    final q = _query.toLowerCase().trim();
    return list.where((f) {
      final t = (f['title'] as String).toLowerCase();
      final s = (f['sub'] as String).toLowerCase();
      final k = (f['keywords'] as String).toLowerCase();
      return t.contains(q) || s.contains(q) || k.contains(q);
    }).toList();
  }

  void _applyKeyword(String kw) {
    HapticFeedback.selectionClick();
    setState(() {
      _query = kw;
      _searchCtrl.text = kw;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: TextField(
          controller: _searchCtrl,
          focusNode: _focusNode,
          autofocus: false,
          onChanged: (val) => setState(() => _query = val),
          style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 16),
          decoration: InputDecoration(
            hintText: 'Tìm chức năng, dịch vụ, hóa đơn, CCCD...',
            hintStyle: const TextStyle(color: AppColors.textMutedLight),
            border: InputBorder.none,
            suffixIcon: _query.isNotEmpty
                ? IconButton(
                    icon: const Icon(CupertinoIcons.xmark_circle_fill, color: AppColors.textMutedLight, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      setState(() => _query = '');
                    },
                  )
                : null,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildFilterChip('Tất cả', 0),
                    _buildFilterChip('Dịch vụ & Tiện ích', 1),
                    _buildFilterChip('Thụ hưởng', 2),
                    _buildFilterChip('Bảo mật & Hướng dẫn', 3),
                  ],
                ),
              ),
            ),
            const Divider(height: 1, color: AppColors.borderLight),

            // Body list
            Expanded(
              child: ListView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 32),
                children: [
                  // Trending and Recent (only if query is empty)
                  if (_query.isEmpty) ...[
                    _buildRecentHistorySection(),
                    const SizedBox(height: 20),
                    _buildTrendingKeywordsSection(),
                    const SizedBox(height: 20),
                  ],

                  // Section Header
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _query.isEmpty ? 'Tất cả chức năng ngân hàng' : 'Kết quả tìm kiếm (${_results.length})',
                            style: AppTypography.titleMedium(color: AppColors.primaryDark),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (_results.isEmpty) ...[
                          const SizedBox(width: 8),
                          const Text('Không có kết quả', style: TextStyle(color: AppColors.textSecondaryLight, fontSize: 12)),
                        ],
                      ],
                    ),
                  ),

                  // Result Cards
                  if (_results.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(32),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          const Icon(CupertinoIcons.search, size: 48, color: AppColors.textMutedLight),
                          const SizedBox(height: 12),
                          Text('Không tìm thấy kết quả cho "$_query"', style: const TextStyle(color: AppColors.textSecondaryLight)),
                          const SizedBox(height: 6),
                          const Text('Thử tìm bằng từ khóa khác như "chuyển tiền", "điện", "tiết kiệm"', style: TextStyle(color: AppColors.textMutedLight, fontSize: 12)),
                        ],
                      ),
                    )
                  else
                    ..._results.map((f) => _buildFeatureItem(f)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIdx == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? Colors.white : AppColors.textPrimaryLight)),
        selected: isSelected,
        selectedColor: AppColors.primary,
        backgroundColor: AppColors.dividerLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderLight)),
        onSelected: (_) {
          HapticFeedback.selectionClick();
          setState(() => _selectedFilterIdx = index);
        },
      ),
    );
  }

  Widget _buildRecentHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Tìm kiếm gần đây', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight)),
            InkWell(
              onTap: () {
                HapticFeedback.mediumImpact();
                setState(() => _recentSearches.clear());
              },
              child: const Text('Xóa lịch sử', style: TextStyle(color: AppColors.bottomBarCyan, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _recentSearches.map((item) {
            return InkWell(
              onTap: () => _applyKeyword(item),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.dividerLight,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.borderLight),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(CupertinoIcons.clock, size: 12, color: AppColors.textSecondaryLight),
                    const SizedBox(width: 6),
                    Text(item, style: const TextStyle(fontSize: 12, color: AppColors.textPrimaryLight)),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTrendingKeywordsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(CupertinoIcons.flame_fill, size: 16, color: AppColors.accentGold),
            SizedBox(width: 6),
            Text('Xu hướng tìm kiếm', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.textPrimaryLight)),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _trendingKeywords.map((kw) {
            return ActionChip(
              label: Text(kw, style: const TextStyle(fontSize: 12, color: AppColors.primaryDark, fontWeight: FontWeight.w500)),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: const BorderSide(color: AppColors.borderSubtle)),
              onPressed: () => _applyKeyword(kw),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildFeatureItem(Map<String, dynamic> f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.88),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Material(
          type: MaterialType.transparency,
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: () {
              HapticFeedback.lightImpact();
              context.push(f['route'] as String);
            },
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(f['icon'] as IconData, color: AppColors.primary, size: 22),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    f['title'] as String,
                    style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontSize: 14),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.dividerLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(f['category'] as String, style: const TextStyle(fontSize: 9.5, color: AppColors.textSecondaryLight)),
                ),
              ],
            ),
            subtitle: Text(f['sub'] as String, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
            trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
          ),
        ),
      ),
    );
  }
}

