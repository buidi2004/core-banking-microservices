import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

/// Màn hình Đóng Bảo hiểm Xã hội (BHXH tự nguyện) & Gia hạn BHYT hộ gia đình
class SocialInsuranceScreen extends StatefulWidget {
  const SocialInsuranceScreen({super.key});

  @override
  State<SocialInsuranceScreen> createState() => _SocialInsuranceScreenState();
}

class _SocialInsuranceScreenState extends State<SocialInsuranceScreen> {
  final TextEditingController _bhxhCodeCtrl = TextEditingController(text: '7912345678');
  final TextEditingController _fullNameCtrl = TextEditingController(text: 'NGUYỄN VĂN AN');
  final TextEditingController _cccdCtrl = TextEditingController(text: '079201008899');

  int _serviceType = 0; // 0: BHXH tự nguyện, 1: BHYT hộ gia đình
  int _durationMonths = 3; // 1, 3, 6, 12 tháng
  int _monthlyIncome = 2500000; // Mức thu nhập lựa chọn đóng BHXH
  int _subsidyRate = 10; // 10% đối tượng khác, 25% cận nghèo, 30% hộ nghèo
  String _selectedProvince = 'TP. Hồ Chí Minh';

  final List<String> _provinces = const [
    'TP. Hồ Chí Minh',
    'Hà Nội',
    'Đà Nẵng',
    'Cần Thơ',
    'Hải Phòng',
    'Đồng Tháp',
    'Bình Dương',
    'Đồng Nai',
  ];

  @override
  void dispose() {
    _bhxhCodeCtrl.dispose();
    _fullNameCtrl.dispose();
    _cccdCtrl.dispose();
    super.dispose();
  }

  // Tiền BHXH = 22% mức thu nhập x số tháng - Trợ cấp nhà nước (22% của 1.500.000đ chuẩn nghèo nông thôn x subsidyRate%)
  double get _totalAmount {
    if (_serviceType == 1) {
      // BHYT hộ gia đình: 4.5% mức lương cơ sở (1.800.000) ~ 81.000/tháng
      return 81000.0 * _durationMonths;
    }
    final gross = (_monthlyIncome * 0.22) * _durationMonths;
    final subsidy = (1500000 * 0.22 * (_subsidyRate / 100)) * _durationMonths;
    return gross - subsidy;
  }

  void _confirmPayment() {
    HapticFeedback.mediumImpact();
    if (_bhxhCodeCtrl.text.trim().isEmpty || _fullNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vui lòng nhập Mã số BHXH và Họ tên'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final title = _serviceType == 0 ? 'BHXH tự nguyện' : 'BHYT hộ gia đình';

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
            Row(
              children: [
                const Icon(CupertinoIcons.shield_fill, color: Color(0xFF14B885), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Xác nhận nộp phí $title',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
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
                  _confirmRow('Người tham gia', _fullNameCtrl.text.toUpperCase(), isBold: true),
                  const Divider(height: 16),
                  _confirmRow('Mã số BHXH', _bhxhCodeCtrl.text),
                  const Divider(height: 16),
                  _confirmRow('Cơ quan thu BHXH', 'BHXH $_selectedProvince'),
                  const Divider(height: 16),
                  _confirmRow('Thời hạn đóng', '$_durationMonths tháng'),
                  const Divider(height: 16),
                  _confirmRow(
                    'Số tiền thực đóng',
                    CurrencyFormatter.formatVND(_totalAmount),
                    isBold: true,
                    color: const Color(0xFF14B885),
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
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Thanh toán thành công phí $title cho mã ${_bhxhCodeCtrl.text}! Biên lai đã được lưu trữ.'),
                      backgroundColor: const Color(0xFF14B885),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Thanh toán ngay qua Ví Sen Hồng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Bảo hiểm xã hội Việt Nam',
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
          icon: const Icon(CupertinoIcons.chevron_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Chọn loại hình dịch vụ BHXH
            Row(
              children: [
                Expanded(
                  child: _buildServiceTab(0, 'BHXH tự nguyện'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _buildServiceTab(1, 'Gia hạn BHYT'),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Thông tin định danh người tham gia
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
                  const Text(
                    'Thông tin người tham gia',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _inputField('Mã số BHXH (10 số)', _bhxhCodeCtrl, isNumber: true),
                  const SizedBox(height: 10),
                  _inputField('Họ và tên người tham gia', _fullNameCtrl),
                  const SizedBox(height: 10),
                  _inputField('Số CCCD / Định danh cá nhân', _cccdCtrl, isNumber: true),
                  const SizedBox(height: 12),
                  const Text('Cơ quan BHXH tỉnh/thành phố', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _selectedProvince,
                        isExpanded: true,
                        items: _provinces.map((p) => DropdownMenuItem(value: p, child: Text(p, style: const TextStyle(fontSize: 13.5)))).toList(),
                        onChanged: (v) {
                          if (v != null) setState(() => _selectedProvince = v);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Lựa chọn phương thức đóng & thời hạn
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
                  const Text(
                    'Thời hạn đóng bảo hiểm',
                    style: TextStyle(
                      color: Color(0xFF0F172A),
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildMonthChip(1, '1 Tháng'),
                      const SizedBox(width: 8),
                      _buildMonthChip(3, '3 Tháng'),
                      const SizedBox(width: 8),
                      _buildMonthChip(6, '6 Tháng'),
                      const SizedBox(width: 8),
                      _buildMonthChip(12, '12 Tháng'),
                    ],
                  ),
                  if (_serviceType == 0) ...[
                    const Divider(height: 24),
                    const Text(
                      'Mức thu nhập chọn đóng BHXH hàng tháng',
                      style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          CurrencyFormatter.formatVND(_monthlyIncome),
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('22% tỷ lệ đóng', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF475569))),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Tóm tắt số tiền thực đóng
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFF14B885).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Tổng tiền thanh toán:',
                    style: TextStyle(color: Color(0xFF0F766E), fontSize: 14.5, fontWeight: FontWeight.w600),
                  ),
                  Text(
                    CurrencyFormatter.formatVND(_totalAmount),
                    style: const TextStyle(
                      color: Color(0xFF0F766E),
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Nút thanh toán
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B885),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _confirmPayment,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.creditcard, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'Nộp tiền Bảo hiểm Xã hội',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
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

  Widget _buildServiceTab(int type, String label) {
    final isSelected = _serviceType == type;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _serviceType = type);
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF14B885) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isSelected ? const Color(0xFF14B885) : const Color(0xFFE2E8F0)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : const Color(0xFF475569),
            fontWeight: FontWeight.w700,
            fontSize: 13.5,
          ),
        ),
      ),
    );
  }

  Widget _buildMonthChip(int months, String label) {
    final isSelected = _durationMonths == months;
    return Expanded(
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) {
          HapticFeedback.selectionClick();
          setState(() => _durationMonths = months);
        },
        selectedColor: const Color(0xFF14B885).withOpacity(0.18),
        backgroundColor: Colors.white,
        side: BorderSide(
          color: isSelected ? const Color(0xFF14B885) : const Color(0xFFE2E8F0),
        ),
        labelStyle: TextStyle(
          color: isSelected ? const Color(0xFF0F766E) : const Color(0xFF475569),
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontSize: 11.5,
        ),
      ),
    );
  }

  Widget _inputField(String label, TextEditingController ctrl, {bool isNumber = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNumber ? TextInputType.number : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Color(0xFF64748B), fontSize: 12.5),
          border: InputBorder.none,
          isDense: true,
        ),
        style: const TextStyle(color: Color(0xFF0F172A), fontSize: 14, fontWeight: FontWeight.w600),
      ),
    );
  }
}
