import 'dart:math';
import 'package:sen_hong_bank/presentation/widgets/vietnam_destination_carousel.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

/// Màn hình Mua vé số điện toán Vietlott chính hãng qua tài khoản Sen Hồng Bank
class VietlottScreen extends StatefulWidget {
  const VietlottScreen({super.key});

  @override
  State<VietlottScreen> createState() => _VietlottScreenState();
}

class _VietlottScreenState extends State<VietlottScreen> {
  int _selectedGame = 0; // 0: Power 6/55, 1: Mega 6/45, 2: Keno, 3: Max 3D
  final Set<int> _selectedNumbers = {8, 15, 24, 32, 45, 52};
  int _consecutiveDraws = 1;

  final List<Map<String, dynamic>> _gameTypes = [
    {
      'name': 'Power 6/55',
      'jackpot1': '168.200.000.000 đ',
      'jackpot2': '4.850.000.000 đ',
      'maxBall': 55,
      'pickCount': 6,
      'color': const Color(0xFFDC2626),
      'drawTime': '18:00 Thứ 3, 5, 7',
    },
    {
      'name': 'Mega 6/45',
      'jackpot1': '19.450.000.000 đ',
      'jackpot2': null,
      'maxBall': 45,
      'pickCount': 6,
      'color': const Color(0xFFEA580C),
      'drawTime': '18:00 Thứ 4, 6, CN',
    },
    {
      'name': 'Keno',
      'jackpot1': 'Trúng tới 10 Tỷ',
      'jackpot2': null,
      'maxBall': 80,
      'pickCount': 10,
      'color': const Color(0xFF0284C7),
      'drawTime': '10 phút / kỳ quay',
    },
  ];

  int get _maxBall => _gameTypes[_selectedGame]['maxBall'] as int;
  int get _pickCount => _gameTypes[_selectedGame]['pickCount'] as int;

  void _onGameChanged(int idx) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedGame = idx;
      _selectedNumbers.clear();
      _quickPick();
    });
  }

  void _toggleNumber(int num) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedNumbers.contains(num)) {
        _selectedNumbers.remove(num);
      } else {
        if (_selectedNumbers.length < _pickCount) {
          _selectedNumbers.add(num);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Đã chọn tối đa $_pickCount số cho ${_gameTypes[_selectedGame]['name']}'),
              duration: const Duration(seconds: 1),
            ),
          );
        }
      }
    });
  }

  void _quickPick() {
    HapticFeedback.lightImpact();
    final random = Random();
    final set = <int>{};
    while (set.length < _pickCount) {
      set.add(random.nextInt(_maxBall) + 1);
    }
    setState(() {
      _selectedNumbers.clear();
      _selectedNumbers.addAll(set);
    });
  }

  void _clearAll() {
    HapticFeedback.lightImpact();
    setState(() => _selectedNumbers.clear());
  }

  void _confirmPurchase() {
    if (_selectedNumbers.length < _pickCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Vui lòng chọn đủ $_pickCount số trước khi mua vé'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();
    final game = _gameTypes[_selectedGame];
    final total = 10000 * _consecutiveDraws;

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
              const Icon(CupertinoIcons.checkmark_seal_fill,
                  size: 54, color: AppColors.primary),
              const SizedBox(height: 12),
              Text(
                'XÁC NHẬN MUA VÉ VIETLOTT',
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
                    _buildConfirmRow('Sản phẩm', game['name'] as String),
                    const Divider(height: 16),
                    _buildConfirmRow(
                      'Bộ số đã chọn',
                      (_selectedNumbers.toList()..sort())
                          .map((e) => e.toString().padLeft(2, '0'))
                          .join(' - '),
                    ),
                    const Divider(height: 16),
                    _buildConfirmRow(
                        'Số kỳ mở thưởng', '$_consecutiveDraws kỳ liên tiếp'),
                    const Divider(height: 16),
                    _buildConfirmRow(
                      'Tổng thanh toán',
                      '${CurrencyFormatter.format(total)} đ',
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
                          const SnackBar(
                            content: Text(
                                '🎉 Đặt vé Vietlott thành công! Mã vé điện tử đã gửi tới SMS và email của bạn.'),
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

  Widget _buildConfirmRow(String title, String value,
      {bool isHighlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: AppTypography.bodySmall(color: const Color(0xFF64748B))),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontFeatures: const [FontFeature.tabularFigures()],
            fontSize: isHighlight ? 15 : 13,
            fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
            color:
                isHighlight ? const Color(0xFFDC2626) : const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentGame = _gameTypes[_selectedGame];
    final sortedNumbers = _selectedNumbers.toList()..sort();

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
          'Vé Số Vietlott',
          style: AppTypography.titleMedium(
            color: const Color(0xFF1E293B),
          ).copyWith(fontWeight: FontWeight.w700, fontSize: 17),
        ),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.black.withOpacity(0.06), width: 0.5),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(CupertinoIcons.checkmark_shield_fill,
                    size: 14, color: AppColors.primary),
                SizedBox(width: 4),
                Text(
                  'Vietlott SMS',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF334155)),
                ),
              ],
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          const SliverToBoxAdapter(child: VietnamDestinationCarousel()),
          // Bộ chọn loại hình Vietlott
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: List.generate(_gameTypes.length, (idx) {
                    final isSel = _selectedGame == idx;
                    final g = _gameTypes[idx];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => _onGameChanged(idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isSel ? AppColors.primary : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isSel
                                  ? AppColors.primary
                                  : Colors.black.withOpacity(0.08),
                              width: 0.5,
                            ),
                            boxShadow: isSel
                                ? [
                                    BoxShadow(
                                      color: AppColors.primary.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : null,
                          ),
                          child: Text(
                            g['name'] as String,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: isSel
                                  ? Colors.white
                                  : const Color(0xFF334155),
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),

          // Card thông tin Jackpot ước tính
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.06), width: 0.5),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.02),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      runSpacing: 4,
                      children: [
                        SizedBox(
                            width: 155,
                            child: Text(
                              'JACKPOT TÍCH LŨY',
                              style: AppTypography.bodySmall(
                                color: const Color(0xFF64748B),
                              ).copyWith(
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.8),
                              overflow: TextOverflow.ellipsis,
                            )),
                        SizedBox(
                            width: 155,
                            child: Text(
                              currentGame['drawTime'] as String,
                              style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF94A3B8)),
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                            )),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      currentGame['jackpot1'] as String,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontFeatures: [FontFeature.tabularFigures()],
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                    if (currentGame['jackpot2'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Jackpot 2: ${currentGame['jackpot2']}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFEA580C),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),

          // Dải hiển thị bóng số đã chọn
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                      color: Colors.black.withOpacity(0.06), width: 0.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Bộ số của bạn (${_selectedNumbers.length}/$_pickCount)',
                          style: AppTypography.bodyMedium(
                            color: const Color(0xFF1E293B),
                          ).copyWith(fontWeight: FontWeight.w700),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            TextButton.icon(
                              onPressed: _quickPick,
                              icon:
                                  const Icon(CupertinoIcons.sparkles, size: 14),
                              label: const Text('Tự chọn',
                                  style: TextStyle(fontSize: 12)),
                            ),
                            TextButton(
                              onPressed: _clearAll,
                              child: const Text('Xóa',
                                  style: TextStyle(
                                      fontSize: 12, color: Color(0xFFDC2626))),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: List.generate(_pickCount, (i) {
                        final hasVal = i < sortedNumbers.length;
                        final val = hasVal ? sortedNumbers[i] : null;
                        return Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color:
                                hasVal ? const Color(0xFFDC2626) : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: hasVal
                                  ? const Color(0xFFDC2626)
                                  : Colors.black.withOpacity(0.12),
                              width: 1,
                            ),
                            boxShadow: hasVal
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFFDC2626)
                                          .withOpacity(0.25),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    ),
                                  ]
                                : null,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            hasVal ? val.toString().padLeft(2, '0') : '?',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontFeatures: const [
                                FontFeature.tabularFigures()
                              ],
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: hasVal
                                  ? Colors.white
                                  : const Color(0xFF94A3B8),
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

          // Bàn phím ma trận bóng số
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Text(
                'Chạm để chọn các số từ 01 đến $_maxBall',
                style: AppTypography.bodySmall(
                  color: const Color(0xFF64748B),
                ).copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 8,
                crossAxisSpacing: 8,
                childAspectRatio: 1.0,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final ballNum = index + 1;
                  final isSelected = _selectedNumbers.contains(ballNum);
                  return GestureDetector(
                    onTap: () => _toggleNumber(ballNum),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      decoration: BoxDecoration(
                        color:
                            isSelected ? const Color(0xFFDC2626) : Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFFDC2626)
                              : Colors.black.withOpacity(0.1),
                          width: 0.8,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        ballNum.toString().padLeft(2, '0'),
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontFeatures: const [FontFeature.tabularFigures()],
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF1E293B),
                        ),
                      ),
                    ),
                  );
                },
                childCount: _maxBall,
              ),
            ),
          ),

          // Thanh chọn số kỳ quay & Nút Mua vé
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
              child: Column(
                children: [
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    runSpacing: 8,
                    children: [
                      Text(
                        'Số kỳ mua',
                        style: AppTypography.bodySmall(
                          color: const Color(0xFF1E293B),
                        ).copyWith(fontWeight: FontWeight.w700),
                      ),
                      Row(
                        children: [1, 2, 3, 5].map((draw) {
                          final isSel = _consecutiveDraws == draw;
                          return Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: GestureDetector(
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _consecutiveDraws = draw);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: isSel
                                      ? AppColors.primary
                                      : const Color(0xFFF1F5F9),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$draw kỳ',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: isSel
                                        ? Colors.white
                                        : const Color(0xFF475569),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _confirmPurchase,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(CupertinoIcons.cart_fill, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            'Đặt mua vé — ${CurrencyFormatter.format(10000 * _consecutiveDraws)} đ',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 15),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
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
