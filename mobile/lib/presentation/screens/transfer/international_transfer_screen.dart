import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

/// Màn hình Chuyển tiền quốc tế SWIFT đa ngoại tệ (USD, EUR, JPY, KRW, SGD...)
class InternationalTransferScreen extends StatefulWidget {
  const InternationalTransferScreen({super.key});

  @override
  State<InternationalTransferScreen> createState() =>
      _InternationalTransferScreenState();
}

class _InternationalTransferScreenState
    extends State<InternationalTransferScreen> {
  final TextEditingController _amountForeignCtrl =
      TextEditingController(text: '1000');
  final TextEditingController _swiftCtrl =
      TextEditingController(text: 'CHASUS33');
  final TextEditingController _bankNameCtrl =
      TextEditingController(text: 'JPMorgan Chase Bank, N.A.');
  final TextEditingController _accountCtrl =
      TextEditingController(text: 'US98234819230182');
  final TextEditingController _recipientNameCtrl =
      TextEditingController(text: 'JOHNATHAN DOE');

  int _selectedCountryIndex = 0;
  int _selectedPurposeIndex = 0;

  final List<Map<String, dynamic>> _countries = const [
    {
      'country': 'Hoa Kỳ (Mỹ)',
      'currency': 'USD',
      'flag': '🇺🇸',
      'rate': 25450.0,
      'swift': 'CHASUS33',
      'bank': 'JPMorgan Chase Bank, N.A.',
    },
    {
      'country': 'Nhật Bản',
      'currency': 'JPY',
      'flag': '🇯🇵',
      'rate': 165.2,
      'swift': 'BOTKJPJT',
      'bank': 'MUFG Bank, Ltd.',
    },
    {
      'country': 'Hàn Quốc',
      'currency': 'KRW',
      'flag': '🇰🇷',
      'rate': 18.5,
      'swift': 'KOEXKRSE',
      'bank': 'KEB Hana Bank',
    },
    {
      'country': 'Châu Âu (EU)',
      'currency': 'EUR',
      'flag': '🇪🇺',
      'rate': 27200.0,
      'swift': 'BNPAFRPP',
      'bank': 'BNP Paribas',
    },
    {
      'country': 'Vương Quốc Anh',
      'currency': 'GBP',
      'flag': '🇬🇧',
      'rate': 32150.0,
      'swift': 'BARCGB22',
      'bank': 'Barclays Bank PLC',
    },
    {
      'country': 'Singapore',
      'currency': 'SGD',
      'flag': '🇸🇬',
      'rate': 19120.0,
      'swift': 'DBSSSGSG',
      'bank': 'DBS Bank Ltd',
    },
    {
      'country': 'Úc (Australia)',
      'currency': 'AUD',
      'flag': '🇦🇺',
      'rate': 16650.0,
      'swift': 'CTBAAU2S',
      'bank': 'Commonwealth Bank of Australia',
    },
  ];

  final List<String> _purposes = const [
    'Chi phí học tập & du học',
    'Trợ cấp cho thân nhân',
    'Khám chữa bệnh quốc tế',
    'Công tác / Du lịch nước ngoài',
    'Thanh toán chuyển nhượng',
  ];

  @override
  void dispose() {
    _amountForeignCtrl.dispose();
    _swiftCtrl.dispose();
    _bankNameCtrl.dispose();
    _accountCtrl.dispose();
    _recipientNameCtrl.dispose();
    super.dispose();
  }

  void _onCountryChanged(int index) {
    HapticFeedback.selectionClick();
    final c = _countries[index];
    setState(() {
      _selectedCountryIndex = index;
      _swiftCtrl.text = c['swift'] as String;
      _bankNameCtrl.text = c['bank'] as String;
    });
  }

  double get _foreignAmount =>
      double.tryParse(_amountForeignCtrl.text.replaceAll(',', '')) ?? 0;
  double get _rate => _countries[_selectedCountryIndex]['rate'] as double;
  double get _vndTotal => _foreignAmount * _rate;

  void _submitTransfer() {
    HapticFeedback.mediumImpact();
    if (_recipientNameCtrl.text.trim().isEmpty ||
        _accountCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng điền đủ Tên người nhận và Số tài khoản/IBAN'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final curr = _countries[_selectedCountryIndex]['currency'];
    final country = _countries[_selectedCountryIndex]['country'];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
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
              'Xác nhận điện chuyển tiền SWIFT',
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
                  _confirmRow('Quốc gia đến', country),
                  const Divider(height: 16),
                  _confirmRow('Số tiền chuyển', '$_foreignAmount $curr',
                      isBold: true),
                  const Divider(height: 16),
                  _confirmRow('Tỷ giá áp dụng',
                      '1 $curr = ${CurrencyFormatter.formatVND(_rate)}'),
                  const Divider(height: 16),
                  _confirmRow(
                      'Quy đổi VND', CurrencyFormatter.formatVND(_vndTotal),
                      isBold: true, color: const Color(0xFF14B885)),
                  const Divider(height: 16),
                  _confirmRow(
                      'Người nhận', _recipientNameCtrl.text.toUpperCase()),
                  const Divider(height: 16),
                  _confirmRow('Mục đích', _purposes[_selectedPurposeIndex]),
                  const Divider(height: 16),
                  _confirmRow('Phí dịch vụ SWIFT', '120.000 đ'),
                ],
              ),
            ),
            const SizedBox(height: 22),
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
                  Navigator.pop(ctx);
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                          'Lệnh chuyển tiền quốc tế $_foreignAmount $curr đã được gửi thành công!'),
                      backgroundColor: const Color(0xFF14B885),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Xác nhận & Gửi điện',
                    style:
                        TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value,
      {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color ?? const Color(0xFF0F172A),
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final cur = _countries[_selectedCountryIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Chuyển tiền quốc tế',
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
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ chọn Quốc gia đến & Ngoại tệ
            const Text(
              'Chọn quốc gia thụ hưởng',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 72,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _countries.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (ctx, idx) {
                  final c = _countries[idx];
                  final isSelected = _selectedCountryIndex == idx;
                  return InkWell(
                    onTap: () => _onCountryChanged(idx),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      width: 130,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF2B44D6).withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isSelected
                              ? const Color(0xFF2B44D6)
                              : const Color(0xFFE2E8F0),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            children: [
                              Text(c['flag'] as String,
                                  style: const TextStyle(fontSize: 18)),
                              const SizedBox(width: 6),
                              Text(
                                c['currency'] as String,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            c['country'] as String,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                color: Color(0xFF64748B), fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),

            // Nhập số tiền ngoại tệ & tính quy đổi VND
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Số tiền cần chuyển (${cur['currency']})',
                    style:
                        const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _amountForeignCtrl,
                          keyboardType: TextInputType.number,
                          onChanged: (_) => setState(() {}),
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF0F172A),
                          ),
                          decoration: const InputDecoration(
                              border: InputBorder.none, isDense: true),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          cur['currency'] as String,
                          style: const TextStyle(
                              fontWeight: FontWeight.w800, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tổng quy đổi (tỷ giá ước tính):',
                        style:
                            TextStyle(color: Color(0xFF64748B), fontSize: 13),
                      ),
                      Text(
                        CurrencyFormatter.formatVND(_vndTotal),
                        style: const TextStyle(
                          color: Color(0xFF14B885),
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mục đích chuyển tiền
            const Text(
              'Mục đích chuyển tiền',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<int>(
                  value: _selectedPurposeIndex,
                  isExpanded: true,
                  items: List.generate(_purposes.length, (i) {
                    return DropdownMenuItem(
                      value: i,
                      child: Text(_purposes[i],
                          style: const TextStyle(
                              fontSize: 14, color: Color(0xFF0F172A))),
                    );
                  }),
                  onChanged: (val) {
                    if (val != null)
                      setState(() => _selectedPurposeIndex = val);
                  },
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Thông tin ngân hàng & người nhận
            const Text(
              'Thông tin ngân hàng thụ hưởng & người nhận',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 10),
            _inputBox('Mã SWIFT / BIC', _swiftCtrl),
            const SizedBox(height: 10),
            _inputBox('Tên ngân hàng thụ hưởng', _bankNameCtrl),
            const SizedBox(height: 10),
            _inputBox('Số tài khoản / IBAN', _accountCtrl),
            const SizedBox(height: 10),
            _inputBox(
                'Họ tên người nhận (VIẾT HOA KHÔNG DẤU)', _recipientNameCtrl),
            const SizedBox(height: 26),

            // Nút tiếp tục
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2B44D6),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _submitTransfer,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.paperplane_fill, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Tiếp tục chuyển tiền quốc tế',
                      style: TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 120),
          ],
        ),
      ),
    );
  }

  Widget _inputBox(String label, TextEditingController ctrl) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
          border: InputBorder.none,
        ),
        style: const TextStyle(
            color: Color(0xFF0F172A),
            fontSize: 14.5,
            fontWeight: FontWeight.w600),
      ),
    );
  }
}
