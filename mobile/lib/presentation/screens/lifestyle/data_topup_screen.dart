import 'package:sen_hong_bank/presentation/widgets/vietnam_destination_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

/// Màn hình Đăng ký Gói Data 4G/5G và Nạp tiền điện thoại trực tiếp chiết khấu cao
class DataTopupScreen extends StatefulWidget {
  const DataTopupScreen({super.key});

  @override
  State<DataTopupScreen> createState() => _DataTopupScreenState();
}

class _DataTopupScreenState extends State<DataTopupScreen> {
  int _tabMode = 0; // 0: Gói cước Data 4G/5G, 1: Nạp tiền điện thoại
  int _selectedTelco = 0; // 0: Viettel, 1: Vinaphone, 2: Mobifone, 3: Wintel
  int _selectedDataPkg = 1;
  int _selectedAmount = 2; // 100,000đ
  final TextEditingController _phoneCtrl =
      TextEditingController(text: '0912345678');

  final List<String> _telcos = ['Viettel', 'Vinaphone', 'Mobifone', 'Wintel'];

  final List<Map<String, dynamic>> _dataPackages = [
    {
      'code': 'ST70K',
      'data': '15 GB',
      'sub': '500 MB / ngày',
      'duration': '30 Ngày',
      'price': 70000,
      'isHot': false,
    },
    {
      'code': 'ST90N',
      'data': '120 GB',
      'sub': '4 GB / ngày tốc độ cao',
      'duration': '30 Ngày',
      'price': 90000,
      'isHot': true,
    },
    {
      'code': 'MXH100',
      'data': '30 GB',
      'sub': 'Free data Youtube, TikTok, FB',
      'duration': '30 Ngày',
      'price': 100000,
      'isHot': true,
    },
    {
      'code': 'ST15K',
      'data': '3 GB',
      'sub': 'Data dùng trong 3 ngày',
      'duration': '3 Ngày',
      'price': 15000,
      'isHot': false,
    },
    {
      'code': '12HD70',
      'data': '60 GB',
      'sub': '5GB/tháng x 12 tháng liên tục',
      'duration': '12 Tháng',
      'price': 500000,
      'isHot': false,
    },
  ];

  final List<int> _topupAmounts = [20000, 50000, 100000, 200000, 500000];

  void _payNow() {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập số điện thoại hợp lệ (10 chữ số)'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final isData = _tabMode == 0;
    final telco = _telcos[_selectedTelco];
    final int amount = isData
        ? (_dataPackages[_selectedDataPkg]['price'] as int)
        : _topupAmounts[_selectedAmount];
    final title = isData
        ? 'Đăng ký gói ${_dataPackages[_selectedDataPkg]['code']} - ${_dataPackages[_selectedDataPkg]['data']}'
        : 'Nạp tiền điện thoại trực tiếp';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              const Icon(CupertinoIcons.antenna_radiowaves_left_right,
                  size: 54, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'XÁC NHẬN GIAO DỊCH',
                style: AppTypography.titleMedium(
                  color: const Color(0xFF1E293B),
                ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.06), width: 0.5),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow('Dịch vụ', title),
                    const Divider(height: 16),
                    _buildSummaryRow('Số thuê bao', phone),
                    const Divider(height: 16),
                    _buildSummaryRow('Nhà mạng', telco),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      'Số tiền thanh toán',
                      '${CurrencyFormatter.format(amount)} đ',
                      isHighlight: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Hủy'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        HapticFeedback.heavyImpact();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isData
                                ? '🎉 Đăng ký gói ${dataPkg['code']} thành công! Dung lượng đã được cộng vào thuê bao $phone.'
                                : '🎉 Nạp tiền điện thoại thành công! Số dư tài khoản đã được nạp $amount đ.'),
                            backgroundColor: const Color(0xFF059669),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Thanh toán ngay',
                          style: TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, dynamic> get dataPkg => _dataPackages[_selectedDataPkg];

  Widget _buildSummaryRow(String title, String val,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: AppTypography.bodySmall(color: const Color(0xFF64748B))),
        Text(
          val,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontFeatures: const [FontFeature.tabularFigures()],
            fontSize: isHighlight ? 15 : 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color: isHighlight ? AppColors.primary : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFDF9),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFFFDF9),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.arrow_left, color: Color(0xFF1E293B)),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.maybePop(context);
          },
        ),
        title: Text(
          'Data 4G / Nạp tiền',
          style: AppTypography.titleMedium(
            color: const Color(0xFF1E293B),
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFF10B981), width: 0.5),
            ),
            child: const Text(
              'Hoàn tiền 3.5%',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF047857)),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: VietnamDestinationCarousel()),
          // Segmented Tab Switcher (Gói cước Data vs Nạp trực tiếp)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _tabMode = 0);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabMode == 0
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _tabMode == 0
                                ? [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2))
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Gói cước Data 4G/5G',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _tabMode == 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _tabMode == 0
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _tabMode = 1);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: _tabMode == 1
                                ? Colors.white
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: _tabMode == 1
                                ? [
                                    BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 4,
                                        offset: const Offset(0, 2))
                                  ]
                                : null,
                          ),
                          child: Text(
                            'Nạp tiền điện thoại',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: _tabMode == 1
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: _tabMode == 1
                                  ? const Color(0xFF1E293B)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Nhập số điện thoại thuê bao
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.06), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Số điện thoại nhận',
                      style: AppTypography.bodySmall(
                              color: const Color(0xFF64748B))
                          .copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        hintText: 'Nhập số điện thoại',
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        prefixIcon: const Icon(CupertinoIcons.phone_fill,
                            color: AppColors.primary, size: 20),
                        suffixIcon: IconButton(
                          icon: const Icon(
                              CupertinoIcons.person_crop_circle_fill_badge_plus,
                              color: AppColors.primary),
                          onPressed: () {
                            HapticFeedback.lightImpact();
                            setState(() => _phoneCtrl.text = '0988776655');
                          },
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.08))),
                        enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(
                                color: Colors.black.withOpacity(0.08))),
                        focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: AppColors.primary, width: 1.2)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Danh sách nhà mạng
                    Row(
                      children: List.generate(_telcos.length, (idx) {
                        final isSel = _selectedTelco == idx;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: idx == 0 ? 0 : 3,
                              right: idx == _telcos.length - 1 ? 0 : 3,
                            ),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _selectedTelco = idx);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 8),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF8FAFC),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isSel
                                        ? AppColors.primary
                                        : Colors.black.withOpacity(0.06),
                                    width: isSel ? 1.2 : 0.5,
                                  ),
                                ),
                                child: Text(
                                  _telcos[idx],
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSel
                                        ? AppColors.primary
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Nội dung theo Tab
          if (_tabMode == 0) ...[
            // Danh sách Gói Data 4G
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  'Chọn gói cước Data 4G tốc độ cao',
                  style:
                      AppTypography.bodyMedium(color: const Color(0xFF1E293B))
                          .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pkg = _dataPackages[index];
                    final isSel = _selectedDataPkg == index;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _selectedDataPkg = index);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : Colors.black.withOpacity(0.06),
                              width: isSel ? 1.5 : 0.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? const Color(0xFFEFF6FF)
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  CupertinoIcons.wifi,
                                  color: isSel
                                      ? AppColors.primary
                                      : const Color(0xFF64748B),
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      spacing: 6,
                                      runSpacing: 4,
                                      children: [
                                        Text(
                                          pkg['code'] as String,
                                          style: AppTypography.titleSmall(
                                                  color:
                                                      const Color(0xFF1E293B))
                                              .copyWith(
                                                  fontWeight: FontWeight.w800),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: const Color(0xFFEFF6FF),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: Text(
                                            pkg['data'] as String,
                                            style: const TextStyle(
                                                fontSize: 10,
                                                fontWeight: FontWeight.w700,
                                                color: AppColors.primary),
                                          ),
                                        ),
                                        if (pkg['isHot'] as bool) ...[
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: const Color(0xFFFEE2E2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: const Text(
                                              'HOT',
                                              style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFFDC2626)),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${pkg['sub']} • Chu kỳ ${pkg['duration']}',
                                      style: AppTypography.bodySmall(
                                          color: const Color(0xFF64748B)),
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${CurrencyFormatter.format(pkg['price'])} đ',
                                style: const TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontFeatures: [FontFeature.tabularFigures()],
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF1E293B),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _dataPackages.length,
                ),
              ),
            ),
          ] else ...[
            // Mệnh giá Nạp tiền điện thoại
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
                child: Text(
                  'Chọn mệnh giá nạp',
                  style:
                      AppTypography.bodyMedium(color: const Color(0xFF1E293B))
                          .copyWith(fontWeight: FontWeight.w700),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.6,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final amount = _topupAmounts[index];
                    final isSel = _selectedAmount == index;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedAmount = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : Colors.black.withOpacity(0.08),
                            width: isSel ? 1.5 : 0.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              '${CurrencyFormatter.format(amount)} đ',
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSel
                                    ? AppColors.primary
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Chiết khấu 3.5%',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isSel
                                    ? AppColors.primary
                                    : const Color(0xFF10B981),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _topupAmounts.length,
                ),
              ),
            ),
          ],

          // Nút thanh toán
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _payNow,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(CupertinoIcons.bolt_fill, size: 18),
                      const SizedBox(width: 8),
                      Flexible(
                          child: Text(
                        _tabMode == 0
                            ? 'Đăng ký ngay — ${CurrencyFormatter.format(dataPkg['price'])} đ'
                            : 'Nạp ngay — ${CurrencyFormatter.format(_topupAmounts[_selectedAmount])} đ',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 15),
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      )),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Đệm 110dp chống cấn Bottom Bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 110),
          ),
        ],
      ),
    );
  }
}
