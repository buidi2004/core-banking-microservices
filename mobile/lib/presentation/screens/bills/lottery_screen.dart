import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class LotteryScreen extends StatefulWidget {
  const LotteryScreen({super.key});

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends State<LotteryScreen> {
  int _mainTab = 0; // 0: Mua vé mới, 1: Vé của tôi, 2: Kết quả kỳ trước
  int _gameIdx = 0; // 0: Mega 6/45, 1: Power 6/55, 2: Keno
  final List<String> _games = ['Mega 6/45', 'Power 6/55', 'Keno'];
  final List<int> _selectedNumbers = [3, 12, 18, 27, 35, 42];
  int _ticketQuantity = 1;
  bool _autoRecurring = false; // Nuôi số may mắn hàng tuần

  int get _maxNumber => _gameIdx == 0 ? 45 : (_gameIdx == 1 ? 55 : 80);
  int get _requiredCount => 6;
  double get _ticketPrice => 10000;
  double get _totalPrice => _ticketPrice * _ticketQuantity;

  // Vé mẫu đã mua trong tab "Vé của tôi"
  final List<Map<String, dynamic>> _myTickets = [
    {
      'code': 'VTL-8829104',
      'game': 'Power 6/55',
      'drawDate': '18:00 - Hôm nay',
      'drawPeriod': 'Kỳ #01124',
      'numbers': [7, 14, 22, 33, 45, 52],
      'specialNum': 11,
      'amount': 20000.0,
      'quantity': 2,
      'status': 'CHỜ MỞ THƯỞNG',
      'canCheck': true,
    },
    {
      'code': 'VTL-7719203',
      'game': 'Mega 6/45',
      'drawDate': '18:00 - 04/09/2026',
      'drawPeriod': 'Kỳ #01290',
      'numbers': [3, 15, 24, 31, 38, 42],
      'specialNum': null,
      'amount': 10000.0,
      'quantity': 1,
      'status': 'TRÚNG GIẢI BA (30.000đ)',
      'canCheck': false,
    },
  ];

  // Kết quả kỳ quay gần nhất
  final List<Map<String, dynamic>> _recentDrawResults = [
    {
      'game': 'Power 6/55',
      'period': 'Kỳ #01123 • 05/09/2026',
      'jackpot1': '68.500.000.000 đ',
      'jackpot2': '4.250.000.000 đ',
      'numbers': [8, 15, 26, 34, 47, 53],
      'special': 19,
      'winnersJ1': 0,
      'winnersJ2': 1,
    },
    {
      'game': 'Mega 6/45',
      'period': 'Kỳ #01289 • 04/09/2026',
      'jackpot1': '24.180.000.000 đ',
      'jackpot2': null,
      'numbers': [5, 12, 18, 29, 36, 44],
      'special': null,
      'winnersJ1': 0,
      'winnersJ2': 0,
    },
  ];

  void _generateRandomNumbers() {
    HapticFeedback.mediumImpact();
    final rng = Random();
    final set = <int>{};
    while (set.length < _requiredCount) {
      set.add(rng.nextInt(_maxNumber) + 1);
    }
    final sorted = set.toList()..sort();
    setState(() {
      _selectedNumbers
        ..clear()
        ..addAll(sorted);
    });
  }

  void _toggleNumber(int n) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedNumbers.contains(n)) {
        _selectedNumbers.remove(n);
      } else {
        if (_selectedNumbers.length < _requiredCount) {
          _selectedNumbers.add(n);
          _selectedNumbers.sort();
        } else {
          AppAlerts.showWarning(context, 'Chỉ được chọn tối đa $_requiredCount số cho mỗi vé', title: 'Giới hạn số');
        }
      }
    });
  }

  void _handleBuy() {
    if (_selectedNumbers.length < _requiredCount) {
      AppAlerts.showWarning(
        context,
        'Vui lòng chọn đủ $_requiredCount số hoặc bấm nút Chọn ngẫu nhiên',
        title: 'Chưa đủ số',
      );
      return;
    }

    final gameName = _games[_gameIdx];
    final numbersStr = _selectedNumbers.join(', ');
    context.push(
      '/bills/confirm?service=${Uri.encodeComponent('Vietlott $gameName')}&provider=Vietlott&code=${Uri.encodeComponent(numbersStr)}&amount=$_totalPrice',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030B17),
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            left: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bottomBarCyan.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                _buildNavTabs(),
                Expanded(
                  child: _mainTab == 0
                      ? _buildBuyTicketTab()
                      : (_mainTab == 1 ? _buildMyTicketsTab() : _buildDrawResultsTab()),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF030B17).withValues(alpha: 0.75),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                CupertinoIcons.chevron_left,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vé Số Vietlott Online',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
                Text(
                  'Xổ số điện toán • Bộ Tài Chính cấp phép',
                  style: TextStyle(
                    color: AppColors.bottomBarCyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGold.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.accentGold.withValues(alpha: 0.4)),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.shield_lefthalf_fill, color: AppColors.accentGold, size: 14),
                SizedBox(width: 4),
                Text('100% HỢP PHÁP', style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavTabs() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1A2E).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          _buildTabItem(0, 'Đặt Vé Mới', CupertinoIcons.ticket_fill),
          _buildTabItem(1, 'Vé Của Tôi (${_myTickets.length})', CupertinoIcons.square_list_fill),
          _buildTabItem(2, 'Kết Quả', CupertinoIcons.sparkles),
        ],
      ),
    );
  }

  Widget _buildTabItem(int index, String title, IconData icon) {
    final isSelected = _mainTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _mainTab = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.bottomBarCyan : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 15,
                color: isSelected ? AppColors.primaryDark : Colors.white60,
              ),
              const SizedBox(width: 6),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryDark : Colors.white70,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= TAB 0: ĐẶT VÉ MỚI =================
  Widget _buildBuyTicketTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      children: [
        _buildJackpotBanner(),
        const SizedBox(height: 18),
        _buildGameSelector(),
        const SizedBox(height: 18),
        _buildPickedNumbersCard(),
        const SizedBox(height: 22),
        _buildNumberMatrixHeader(),
        const SizedBox(height: 10),
        _buildNumberMatrixGrid(),
        const SizedBox(height: 20),
        _buildAutoRecurringCard(),
        const SizedBox(height: 20),
        _buildPrizeStructureCard(),
        const SizedBox(height: 20),
        _buildLegalPolicyCard(),
        const SizedBox(height: 24),
        _buildCheckoutSection(),
      ],
    );
  }

  Widget _buildJackpotBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102847),
            Color(0xFF0F2B48),
            Color(0xFF071526),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.accentGold.withValues(alpha: 0.4),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.accentGold.withValues(alpha: 0.15),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.accentGold.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(CupertinoIcons.ticket_fill, color: AppColors.accentGold, size: 22),
                  ),
                  const SizedBox(width: 10),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'GIẢI JACKPOT 1 ĐANG TÍCH LŨY',
                        style: TextStyle(
                          color: AppColors.accentGold,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.1,
                        ),
                      ),
                      Text(
                        'Kỳ quay 18:00 Hôm nay • Vietlott',
                        style: TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.redAccent.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.redAccent.withValues(alpha: 0.4)),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.flame_fill, color: Colors.redAccent, size: 12),
                    SizedBox(width: 4),
                    Text('HOT', style: TextStyle(color: Colors.redAccent, fontSize: 10, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _gameIdx == 0 ? '24.180.000.000' : '68.500.000.000',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              const Text(
                'VND',
                style: TextStyle(
                  color: AppColors.accentGold,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '• Vé trúng thưởng được hệ thống tự động trả thẳng vào Ví SenBank sau khi có kết quả chính thức từ Vietlott.',
            style: TextStyle(color: Colors.white60, fontSize: 11.5, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildGameSelector() {
    return Row(
      children: List.generate(_games.length, (idx) {
        final g = _games[idx];
        final isSelected = _gameIdx == idx;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: idx < _games.length - 1 ? 8 : 0),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() {
                  _gameIdx = idx;
                  _generateRandomNumbers();
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary
                      : const Color(0xFF0C1929).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.bottomBarCyan
                        : Colors.white.withValues(alpha: 0.08),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    g,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.white70,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildPickedNumbersCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Bộ số đã chọn (${_selectedNumbers.length}/$_requiredCount)',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
                GestureDetector(
                  onTap: _generateRandomNumbers,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: AppColors.bottomBarCyan.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.3)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.shuffle, color: AppColors.bottomBarCyan, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Chọn ngẫu nhiên',
                          style: TextStyle(color: AppColors.bottomBarCyan, fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_requiredCount, (idx) {
                final sorted = _selectedNumbers.toList()..sort();
                final val = idx < sorted.length ? sorted[idx] : null;
                final hasNum = val != null;
                return Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: hasNum
                        ? const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                        : null,
                    color: hasNum ? null : Colors.white.withValues(alpha: 0.05),
                    border: Border.all(
                      color: hasNum ? AppColors.bottomBarCyan : Colors.white.withValues(alpha: 0.15),
                      width: hasNum ? 1.8 : 1,
                    ),
                    boxShadow: hasNum
                        ? [
                            BoxShadow(
                              color: AppColors.bottomBarCyan.withValues(alpha: 0.25),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      val != null ? (val < 10 ? '0$val' : '$val') : '?',
                      style: TextStyle(
                        color: hasNum ? Colors.white : Colors.white38,
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberMatrixHeader() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Bảng số ma trận (Chạm để chọn / bỏ chọn)',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
        Text(
          'Tối đa 6 số',
          style: TextStyle(color: Colors.white54, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildNumberMatrixGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
      ),
      itemCount: _maxNumber,
      itemBuilder: (context, idx) {
        final numVal = idx + 1;
        final isPicked = _selectedNumbers.contains(numVal);
        return InkWell(
          onTap: () => _toggleNumber(numVal),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              gradient: isPicked
                  ? const LinearGradient(
                      colors: [AppColors.primary, AppColors.bottomBarCyan],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              color: isPicked ? null : Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isPicked ? AppColors.bottomBarCyan : Colors.white.withValues(alpha: 0.1),
                width: isPicked ? 1.5 : 1,
              ),
            ),
            child: Center(
              child: Text(
                numVal < 10 ? '0$numVal' : '$numVal',
                style: TextStyle(
                  color: isPicked ? AppColors.primaryDark : Colors.white,
                  fontWeight: isPicked ? FontWeight.w900 : FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAutoRecurringCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentGold.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(CupertinoIcons.repeat, color: AppColors.accentGold, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Nuôi số may mắn định kỳ (Auto-Buy)',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Tự động mua bộ số này vào 10:00 sáng các ngày mở thưởng trong tuần',
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5, height: 1.25),
                  ),
                ],
              ),
            ),
            CupertinoSwitch(
              value: _autoRecurring,
              activeTrackColor: AppColors.accentGold,
              onChanged: (val) {
                setState(() => _autoRecurring = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeStructureCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(CupertinoIcons.chart_bar_circle_fill, color: AppColors.bottomBarCyan, size: 20),
                SizedBox(width: 8),
                Text(
                  'Cơ cấu giải thưởng Vietlott Power 6/55',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13.5),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildPrizeRow('Jackpot 1 (Trùng 6 số):', 'Tối thiểu 30 Tỷ VNĐ + Tích lũy'),
            _buildPrizeRow('Jackpot 2 (Trùng 5 số + Số đặc biệt):', 'Tối thiểu 3 Tỷ VNĐ + Tích lũy'),
            _buildPrizeRow('Giải Nhất (Trùng 5 số):', '40.000.000 đ / vé'),
            _buildPrizeRow('Giải Nhì (Trùng 4 số):', '500.000 đ / vé'),
            _buildPrizeRow('Giải Ba (Trùng 3 số):', '50.000 đ / vé'),
          ],
        ),
      ),
    );
  }

  Widget _buildPrizeRow(String title, String val) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: const TextStyle(color: Colors.white60, fontSize: 11.5)),
          Text(val, style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildLegalPolicyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.emeraldGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.25)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(CupertinoIcons.info_circle_fill, color: AppColors.emeraldGreen, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Quy định pháp lý: Công dân Việt Nam từ đủ 18 tuổi trở lên. Thuế TNCN 10% áp dụng cho phần giá trị trúng thưởng vượt trên 10.000.000đ theo Thông tư 111/2013/TT-BTC. Tiền thưởng được trả tự động vào Ví SenBank.',
              style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.35),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tổng tiền thanh toán:', style: TextStyle(color: Colors.white60, fontSize: 12)),
                const SizedBox(height: 2),
                Text(
                  CurrencyFormatter.formatVND(_totalPrice),
                  style: const TextStyle(
                    color: AppColors.bottomBarCyan,
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(CupertinoIcons.minus_circle_fill, color: Colors.white54),
                  onPressed: _ticketQuantity > 1
                      ? () {
                          HapticFeedback.selectionClick();
                          setState(() => _ticketQuantity--);
                        }
                      : null,
                ),
                Text('$_ticketQuantity vé', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                IconButton(
                  icon: const Icon(CupertinoIcons.plus_circle_fill, color: AppColors.bottomBarCyan),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    setState(() => _ticketQuantity++);
                  },
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
            onPressed: _handleBuy,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.cart_fill, size: 18),
                SizedBox(width: 8),
                Text('Thanh toán mua vé ngay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= TAB 1: VÉ CỦA TÔI =================
  Widget _buildMyTicketsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      children: [
        const Text(
          'Danh sách vé đã mua & Chờ kết quả',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 4),
        const Text(
          'Hệ thống tự động dò số và thông báo ngay khi có kết quả',
          style: TextStyle(color: Colors.white54, fontSize: 12),
        ),
        const SizedBox(height: 14),
        ..._myTickets.map((t) => _buildMyTicketCard(t)),
      ],
    );
  }

  Widget _buildMyTicketCard(Map<String, dynamic> t) {
    final nums = t['numbers'] as List<int>;
    final isWaiting = t['status'].toString().contains('CHỜ');

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1929).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isWaiting
              ? AppColors.bottomBarCyan.withValues(alpha: 0.35)
              : AppColors.emeraldGreen.withValues(alpha: 0.4),
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(CupertinoIcons.ticket, color: AppColors.accentGold, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    '${t['game']} • ${t['drawPeriod']}',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isWaiting
                      ? AppColors.bottomBarCyan.withValues(alpha: 0.15)
                      : AppColors.emeraldGreen.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  t['status'] as String,
                  style: TextStyle(
                    color: isWaiting ? AppColors.bottomBarCyan : AppColors.emeraldGreen,
                    fontWeight: FontWeight.bold,
                    fontSize: 10.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: nums.map((n) {
              return Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primaryDark.withValues(alpha: 0.8),
                  border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.4)),
                ),
                child: Center(
                  child: Text(
                    n < 10 ? '0$n' : '$n',
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Mã vé: ${t['code']}', style: const TextStyle(color: Colors.white54, fontSize: 11)),
              Text('Kỳ quay: ${t['drawDate']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TAB 2: KẾT QUẢ KỲ TRƯỚC =================
  Widget _buildDrawResultsTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
      children: [
        const Text(
          'Kết quả quay thưởng gần nhất',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
        ),
        const SizedBox(height: 14),
        ..._recentDrawResults.map((r) => _buildResultCard(r)),
      ],
    );
  }

  Widget _buildResultCard(Map<String, dynamic> r) {
    final nums = r['numbers'] as List<int>;
    final special = r['special'] as int?;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0C1929).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                r['game'] as String,
                style: const TextStyle(color: AppColors.accentGold, fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                r['period'] as String,
                style: const TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              ...nums.map((n) {
                return Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      n < 10 ? '0$n' : '$n',
                      style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                );
              }),
              if (special != null) ...[
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Colors.redAccent, Color(0xFFB91C1C)],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      special < 10 ? '0$special' : '$special',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.04),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Giá trị Jackpot: ${r['jackpot1']}', style: const TextStyle(color: Colors.white70, fontSize: 11)),
                Text('Số người trúng: ${r['winnersJ1']}', style: const TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
