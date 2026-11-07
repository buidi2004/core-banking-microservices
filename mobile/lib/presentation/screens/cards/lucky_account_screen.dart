import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

/// Màn hình Mở tài khoản số đẹp VIP (Tứ quý, Lộc phát, Thần tài, Phong thủy)
class LuckyAccountScreen extends StatefulWidget {
  const LuckyAccountScreen({super.key});

  @override
  State<LuckyAccountScreen> createState() => _LuckyAccountScreenState();
}

class _LuckyAccountScreenState extends State<LuckyAccountScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  int _selectedCategoryIndex = 0;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  final List<String> _categories = const [
    'Tất cả',
    'Lộc Phát (68-86)',
    'Thần Tài (79-39)',
    'Tứ Quý',
    'Số Tiến (6789)',
    'Miễn phí 0đ',
  ];

  final List<Map<String, dynamic>> _allAccounts = const [
    {
      'account': '8888 6868 99',
      'category': 'Lộc Phát (68-86)',
      'tag': 'LỘC PHÁT VÀNG',
      'price': 1000000,
      'meaning': 'Đại phát trường tồn, kinh doanh hanh thông',
    },
    {
      'account': '6868 6868 68',
      'category': 'Lộc Phát (68-86)',
      'tag': 'SIÊU PHẨM VIP',
      'price': 5000000,
      'meaning': 'Lộc phát liên hoàn, phú quý vô tận',
    },
    {
      'account': '7979 7979 79',
      'category': 'Thần Tài (79-39)',
      'tag': 'ĐẠI THẦN TÀI',
      'price': 5000000,
      'meaning': 'Thần tài gõ cửa, tài vận thăng hoa',
    },
    {
      'account': '3939 7979 88',
      'category': 'Thần Tài (79-39)',
      'tag': 'THẦN TÀI NHỎ LỚN',
      'price': 500000,
      'meaning': 'May mắn kép, tiền tài gõ cửa',
    },
    {
      'account': '9999 9999 88',
      'category': 'Tứ Quý',
      'tag': 'BÁT QUÝ 9',
      'price': 10000000,
      'meaning': 'Cửu đỉnh vương quyền, trường thọ bất diệt',
    },
    {
      'account': '8888 8888 16',
      'category': 'Tứ Quý',
      'tag': 'TỨ QUÝ 8',
      'price': 3000000,
      'meaning': 'Toàn phát vinh hiển, tài lộc dồi dào',
    },
    {
      'account': '1234 5678 99',
      'category': 'Số Tiến (6789)',
      'tag': 'SẢNH TIẾN RỒNG',
      'price': 2000000,
      'meaning': 'Công danh thăng tiến không ngừng',
    },
    {
      'account': '0388 6868 00',
      'category': 'Miễn phí 0đ',
      'tag': 'ƯU ĐÃI SEN HỒNG',
      'price': 0,
      'meaning': 'Số đẹp tài lộc tặng riêng hội viên',
    },
    {
      'account': '0966 7979 01',
      'category': 'Miễn phí 0đ',
      'tag': 'ƯU ĐÃI SEN HỒNG',
      'price': 0,
      'meaning': 'Thần tài song hành phí 0 đồng',
    },
  ];

  List<Map<String, dynamic>> get _filteredAccounts {
    final cat = _categories[_selectedCategoryIndex];
    return _allAccounts.where((item) {
      final matchesCat = _selectedCategoryIndex == 0 ||
          (cat == 'Miễn phí 0đ'
              ? (item['price'] == 0)
              : item['category'] == cat);

      final cleanAcc = (item['account'] as String).replaceAll(' ', '');
      final matchesQuery = _searchQuery.isEmpty ||
          cleanAcc.contains(_searchQuery) ||
          (item['tag'] as String)
              .toLowerCase()
              .contains(_searchQuery.toLowerCase());

      return matchesCat && matchesQuery;
    }).toList();
  }

  void _onRegisterAccount(Map<String, dynamic> item) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _ConfirmRegisterSheet(item: item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final list = _filteredAccounts;

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Mở tài khoản số đẹp',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 17.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon:
              const Icon(CupertinoIcons.chevron_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Banner giới thiệu
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF2B44D6), Color(0xFF14B885)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(CupertinoIcons.sparkles,
                        color: Colors.amberAccent, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Tài khoản phong thủy & VIP',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 6),
                Text(
                  'Miễn phí mở tài khoản theo ngày sinh & bộ số Lộc Phát. Kích hoạt tức thì.',
                  style: TextStyle(
                      color: Colors.white70, fontSize: 13, height: 1.3),
                ),
              ],
            ),
          ),

          // Ô tìm kiếm đuôi số mong muốn
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              keyboardType: TextInputType.number,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Nhập dãy số mong muốn (vd: 888, 6868)...',
                hintStyle:
                    const TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                prefixIcon: const Icon(CupertinoIcons.search,
                    color: Color(0xFF64748B), size: 20),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(CupertinoIcons.xmark_circle_fill,
                            size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      const BorderSide(color: Color(0xFF2B44D6), width: 1.5),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Bộ lọc danh mục ngang
          SizedBox(
            height: 38,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (ctx, idx) {
                final isSelected = _selectedCategoryIndex == idx;
                return ChoiceChip(
                  label: Text(_categories[idx]),
                  selected: isSelected,
                  onSelected: (_) {
                    HapticFeedback.selectionClick();
                    setState(() => _selectedCategoryIndex = idx);
                  },
                  selectedColor: const Color(0xFF2B44D6),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF2B44D6)
                        : const Color(0xFFE2E8F0),
                  ),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF475569),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 12.5,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),

          // Danh sách các số tài khoản khả dụng
          Expanded(
            child: list.isEmpty
                ? const Center(
                    child: Text(
                      'Không tìm thấy số phù hợp.\nVui lòng thử cụm số khác.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.only(left: 16, right: 16, bottom: 120),
                    physics: const BouncingScrollPhysics(),
                    itemCount: list.length,
                    itemBuilder: (ctx, idx) {
                      final item = list[idx];
                      final price = item['price'] as int;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                              color: const Color(0xFFE2E8F0), width: 0.8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.02),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 6,
                                          vertical: 3,
                                        ),
                                        decoration: BoxDecoration(
                                          color: price == 0
                                              ? const Color(0xFF14B885)
                                                  .withOpacity(0.12)
                                              : const Color(0xFF2B44D6)
                                                  .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          item['tag'] as String,
                                          style: TextStyle(
                                            color: price == 0
                                                ? const Color(0xFF0F766E)
                                                : const Color(0xFF1E3A8A),
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    item['account'] as String,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 1.2,
                                      fontFeatures: [
                                        FontFeature.tabularFigures()
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['meaning'] as String,
                                    style: const TextStyle(
                                        color: Color(0xFF64748B), fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  price == 0
                                      ? 'MIỄN PHÍ'
                                      : CurrencyFormatter.formatVND(price),
                                  style: TextStyle(
                                    color: price == 0
                                        ? const Color(0xFF14B885)
                                        : const Color(0xFFE11D48),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    fontFeatures: const [
                                      FontFeature.tabularFigures()
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF0F172A),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    elevation: 0,
                                  ),
                                  onPressed: () => _onRegisterAccount(item),
                                  child: const Text(
                                    'Chọn số',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w700),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ConfirmRegisterSheet extends StatelessWidget {
  final Map<String, dynamic> item;

  const _ConfirmRegisterSheet({required this.item});

  @override
  Widget build(BuildContext context) {
    final price = item['price'] as int;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 38,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFCBD5E1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Xác nhận mở tài khoản số đẹp',
            style: TextStyle(
              color: Color(0xFF0F172A),
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                _row('Số tài khoản', item['account'] as String, isBold: true),
                const Divider(height: 18),
                _row('Loại số', item['tag'] as String),
                const Divider(height: 18),
                _row(
                  'Phí mở tài khoản',
                  price == 0
                      ? 'Miễn phí (0 đ)'
                      : CurrencyFormatter.formatVND(price),
                  color: price == 0
                      ? const Color(0xFF14B885)
                      : const Color(0xFF0F172A),
                  isBold: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B885),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                        'Chúc mừng! Đã mở thành công tài khoản ${item['account']}'),
                    backgroundColor: const Color(0xFF14B885),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Xác nhận đăng ký ngay',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _row(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13.5)),
        Text(
          value,
          style: TextStyle(
            color: color ?? const Color(0xFF0F172A),
            fontSize: 14,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
