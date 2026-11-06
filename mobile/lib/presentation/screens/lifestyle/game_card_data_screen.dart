import 'package:sen_hong_bank/presentation/widgets/vietnam_destination_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

/// Màn hình Mua Thẻ Game & Đăng ký Gói Data Game tốc độ cao không giới hạn
class GameCardDataScreen extends StatefulWidget {
  const GameCardDataScreen({super.key});

  @override
  State<GameCardDataScreen> createState() => _GameCardDataScreenState();
}

class _GameCardDataScreenState extends State<GameCardDataScreen> {
  int _activeTab =
      0; // 0: Mua thẻ game, 1: Data 4G chơi game, 2: Kho thẻ đã mua
  int _selectedPublisher = 0; // Garena, Zing, VTC, Gate, Funcard, Steam
  int _selectedAmount = 2; // 100,000đ

  final List<Map<String, dynamic>> _publishers = [
    {'name': 'Garena', 'sub': 'Liên Quân, FC Online', 'discount': 3.5},
    {'name': 'Zing Xu', 'sub': 'VNG games, Kiếm Thế', 'discount': 4.0},
    {'name': 'VTC Vcoin', 'sub': 'Audition, Đột Kích', 'discount': 5.0},
    {'name': 'Gate', 'sub': 'FPT Online', 'discount': 4.5},
    {'name': 'Funcard', 'sub': 'Funtap Games', 'discount': 4.0},
    {'name': 'Steam VN', 'sub': 'Steam Wallet', 'discount': 3.0},
  ];

  final List<int> _amounts = [20000, 50000, 100000, 200000, 500000, 1000000];

  final List<Map<String, dynamic>> _gameDataPacks = [
    {
      'title': 'Gói Liên Quân 4G Max',
      'telco': 'Viettel / Vinaphone',
      'desc': 'Không giới hạn dung lượng chơi Liên Quân Mobile',
      'price': 30000,
      'duration': '30 Ngày',
    },
    {
      'title': 'Gói Free Fire Ultra',
      'telco': 'Tất cả nhà mạng',
      'desc': 'Ping siêu thấp, không lag, tặng 1GB data ngoài/ngày',
      'price': 45000,
      'duration': '30 Ngày',
    },
    {
      'title': 'Gói PUBG Mobile Pro',
      'telco': 'Viettel / Mobifone',
      'desc': 'Băng thông ưu tiên 5G chơi game mượt mà',
      'price': 50000,
      'duration': '30 Ngày',
    },
  ];

  final List<Map<String, dynamic>> _purchasedCards = [
    {
      'pub': 'Garena',
      'amount': 100000,
      'code': 'GRN882910492817',
      'serial': '1000294819284',
      'date': 'Hôm qua - 20:15',
    },
    {
      'pub': 'Zing Xu',
      'amount': 50000,
      'code': 'ZNG771920394810',
      'serial': '1000938472918',
      'date': '01/11/2026',
    },
  ];

  void _buyCard() {
    HapticFeedback.mediumImpact();
    final pub = _publishers[_selectedPublisher];
    final nominal = _amounts[_selectedAmount];
    final discount = (pub['discount'] as double);
    final paid = (nominal * (1 - discount / 100)).round();

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
              const Icon(CupertinoIcons.gamecontroller_fill,
                  size: 54, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'XÁC NHẬN MUA MÃ THẺ GAME',
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
                    _buildSummaryRow('Loại thẻ', pub['name'] as String),
                    const Divider(height: 16),
                    _buildSummaryRow(
                        'Mệnh giá', '${CurrencyFormatter.format(nominal)} đ'),
                    const Divider(height: 16),
                    _buildSummaryRow('Chiết khấu',
                        '-$discount% (${CurrencyFormatter.format(nominal - paid)} đ)'),
                    const Divider(height: 16),
                    _buildSummaryRow(
                      'Thanh toán thực tế',
                      '${CurrencyFormatter.format(paid)} đ',
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
                        setState(() {
                          _purchasedCards.insert(0, {
                            'pub': pub['name'],
                            'amount': nominal,
                            'code':
                                'CODE${DateTime.now().millisecondsSinceEpoch}',
                            'serial':
                                'SERI${DateTime.now().millisecondsSinceEpoch}',
                            'date': 'Vừa xong',
                          });
                          _activeTab = 2;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                '🎉 Mua thẻ thành công! Mã thẻ đã được lưu vào Kho thẻ của bạn.'),
                            backgroundColor: Color(0xFF059669),
                          ),
                        );
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: const Text('Mua ngay',
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
          'Data 4G / Thẻ Game',
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
              'Chiết khấu tới 5%',
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
          // Switcher 3 tab (Mua thẻ, Data Game, Kho thẻ)
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
                    _buildTabItem(0, 'Mua thẻ game'),
                    _buildTabItem(1, 'Data Game'),
                    _buildTabItem(2, 'Kho thẻ (${_purchasedCards.length})'),
                  ],
                ),
              ),
            ),
          ),

          if (_activeTab == 0) ...[
            // Chọn nhà phát hành game
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Chọn nhà phát hành thẻ game',
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
                  childAspectRatio: 1.25,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final pub = _publishers[index];
                    final isSel = _selectedPublisher == index;
                    return GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedPublisher = index);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSel ? const Color(0xFFEFF6FF) : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSel
                                ? AppColors.primary
                                : Colors.black.withOpacity(0.08),
                            width: isSel ? 1.5 : 0.5,
                          ),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              pub['name'] as String,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: isSel
                                    ? AppColors.primary
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '-${pub['discount']}%',
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF059669),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _publishers.length,
                ),
              ),
            ),

            // Mệnh giá thẻ
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  'Chọn mệnh giá',
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
                  childAspectRatio: 1.5,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final amount = _amounts[index];
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
                        child: Text(
                          '${CurrencyFormatter.format(amount)} đ',
                          style: TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontFeatures: const [FontFeature.tabularFigures()],
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: isSel
                                ? AppColors.primary
                                : const Color(0xFF1E293B),
                          ),
                        ),
                      ),
                    );
                  },
                  childCount: _amounts.length,
                ),
              ),
            ),

            // Nút Mua ngay
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _buyCard,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      'Mua ngay thẻ ${_publishers[_selectedPublisher]['name']} — ${CurrencyFormatter.format(_amounts[_selectedAmount])} đ',
                      style: const TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                ),
              ),
            ),
          ] else if (_activeTab == 1) ...[
            // Data Game
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Text(
                  'Các gói cước Data 4G dành riêng cho Game thủ',
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
                    final pack = _gameDataPacks[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                              width: 0.5),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    pack['title'] as String,
                                    style: AppTypography.titleSmall(
                                            color: const Color(0xFF1E293B))
                                        .copyWith(fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${pack['desc']} • ${pack['telco']}',
                                    style: AppTypography.bodySmall(
                                        color: const Color(0xFF64748B)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '${CurrencyFormatter.format(pack['price'])} đ',
                                  style: const TextStyle(
                                    fontFamily: 'BeVietnamPro',
                                    fontFeatures: [
                                      FontFeature.tabularFigures()
                                    ],
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF1E293B),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                FilledButton(
                                  onPressed: () {
                                    HapticFeedback.heavyImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            '🎉 Đăng ký thành công ${pack['title']}!'),
                                        backgroundColor:
                                            const Color(0xFF059669),
                                      ),
                                    );
                                  },
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10)),
                                  ),
                                  child: const Text('Đăng ký',
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _gameDataPacks.length,
                ),
              ),
            ),
          ] else ...[
            // Kho thẻ đã mua
            SliverPadding(
              padding: const EdgeInsets.all(16),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _purchasedCards[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: Colors.black.withOpacity(0.06),
                              width: 0.5),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Thẻ ${item['pub']} • ${CurrencyFormatter.format(item['amount'])} đ',
                                  style: AppTypography.titleSmall(
                                          color: const Color(0xFF1E293B))
                                      .copyWith(fontWeight: FontWeight.w700),
                                ),
                                Text(item['date'] as String,
                                    style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF94A3B8))),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('MÃ THẺ (PIN)',
                                        style: TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF64748B))),
                                    const SizedBox(height: 2),
                                    Text(
                                      item['code'] as String,
                                      style: const TextStyle(
                                          fontFamily: 'BeVietnamPro',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: AppColors.primary,
                                          letterSpacing: 1.2),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(
                                      CupertinoIcons.doc_on_clipboard,
                                      color: AppColors.primary),
                                  onPressed: () {
                                    Clipboard.setData(ClipboardData(
                                        text: item['code'] as String));
                                    HapticFeedback.lightImpact();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              'Đã sao chép mã PIN thẻ game!')),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Số Serial: ${item['serial']}',
                                style: const TextStyle(
                                    fontSize: 12, color: Color(0xFF64748B))),
                          ],
                        ),
                      ),
                    );
                  },
                  childCount: _purchasedCards.length,
                ),
              ),
            ),
          ],

          // Đệm 110dp chống cấn Bottom Bar
          const SliverToBoxAdapter(
            child: SizedBox(height: 110),
          ),
        ],
      ),
    );
  }

  Widget _buildTabItem(int idx, String title) {
    final isSel = _activeTab == idx;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _activeTab = idx);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSel ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSel
                ? [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 4,
                        offset: const Offset(0, 2))
                  ]
                : null,
          ),
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
              color: isSel ? const Color(0xFF1E293B) : const Color(0xFF64748B),
            ),
          ),
        ),
      ),
    );
  }
}
