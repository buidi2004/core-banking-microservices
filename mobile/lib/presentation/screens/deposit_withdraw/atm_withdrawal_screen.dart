import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/feature_unavailable.dart';

/// Màn hình Rút tiền ATM không cần thẻ qua Mã bí mật & QR Code
class AtmWithdrawalScreen extends StatefulWidget {
  const AtmWithdrawalScreen({super.key});

  @override
  State<AtmWithdrawalScreen> createState() => _AtmWithdrawalScreenState();
}

class _AtmWithdrawalScreenState extends State<AtmWithdrawalScreen> {
  final TextEditingController _amountCtrl = TextEditingController();
  double? _availableBalance;
  bool _isLoading = true;
  String? _balanceError;
  int _selectedPresetIndex = 1;

  final List<int> _presetAmounts = const [
    500000,
    1000000,
    2000000,
    3000000,
    5000000,
  ];

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBalance() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _balanceError = null;
      });
    }
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      if (mounted) {
        setState(() {
          _availableBalance = wallet.availableBalance;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _availableBalance = null;
        _balanceError = 'Không tải được số dư ví. Hãy thử tải lại.';
        _isLoading = false;
      });
    }
  }

  void _onPresetSelected(int index) {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedPresetIndex = index;
      _amountCtrl.text = _presetAmounts[index].toString();
    });
  }

  void _createWithdrawalCode() {
    HapticFeedback.mediumImpact();
    final balance = _availableBalance;
    if (_isLoading || balance == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content:
              Text(_balanceError ?? 'Đang tải số dư ví, vui lòng thử lại.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    final amt =
        double.tryParse(_amountCtrl.text.replaceAll(RegExp(r'[^0-9]'), '')) ??
            0;
    if (amt < 50000) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số tiền rút tối thiểu là 50.000 đ'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (amt > balance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Số dư ví không đủ để thực hiện giao dịch'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    showFeatureUnavailable(
      context,
      feature: 'Rút tiền ATM không cần thẻ',
      reason:
          'Ứng dụng chưa kết nối dịch vụ phát hành mã rút tiền ATM từ ngân hàng. Chưa thể tạo mã hoặc xác nhận giao dịch tại ATM.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Rút tiền ATM không cần thẻ',
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thẻ số dư nguồn tiền
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Nguồn tiền rút',
                        style:
                            TextStyle(color: Color(0xFF94A3B8), fontSize: 13),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF14B885).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'Ví Sen Hồng',
                          style: TextStyle(
                            color: Color(0xFF14B885),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (_isLoading)
                    const Text(
                      'Đang tải số dư…',
                      style: TextStyle(color: Colors.white70, fontSize: 15),
                    )
                  else if (_availableBalance != null)
                    Text(
                      CurrencyFormatter.formatVND(_availableBalance!),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    )
                  else
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _balanceError ?? 'Không tải được số dư ví',
                            style: const TextStyle(
                              color: Color(0xFFFECACA),
                              fontSize: 13,
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: _loadBalance,
                          child: const Text('Thử lại'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(height: 22),

            // Nhập số tiền rút
            const Text(
              'Số tiền cần rút tại cây ATM',
              style: TextStyle(
                color: Color(0xFF1E293B),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountCtrl,
                      keyboardType: TextInputType.number,
                      style: const TextStyle(
                        color: Color(0xFF0F172A),
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: '0',
                      ),
                      onChanged: (val) {
                        setState(() {
                          _selectedPresetIndex = -1;
                        });
                      },
                    ),
                  ),
                  const Text(
                    'VND',
                    style: TextStyle(
                      color: Color(0xFF64748B),
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Các mốc tiền gợi ý
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: List.generate(_presetAmounts.length, (idx) {
                final isSelected = _selectedPresetIndex == idx;
                return ChoiceChip(
                  label: Text(CurrencyFormatter.formatVND(_presetAmounts[idx])),
                  selected: isSelected,
                  onSelected: (_) => _onPresetSelected(idx),
                  selectedColor: const Color(0xFF14B885).withOpacity(0.15),
                  backgroundColor: Colors.white,
                  side: BorderSide(
                    color: isSelected
                        ? const Color(0xFF14B885)
                        : const Color(0xFFE2E8F0),
                    width: isSelected ? 1.5 : 1,
                  ),
                  labelStyle: TextStyle(
                    color: isSelected
                        ? const Color(0xFF0F766E)
                        : const Color(0xFF475569),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                );
              }),
            ),
            const SizedBox(height: 26),

            // Hướng dẫn 3 bước rút tiền tại cây ATM
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFE2E8F0), width: 0.8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(CupertinoIcons.info_circle_fill,
                          color: Color(0xFF2563EB), size: 18),
                      SizedBox(width: 8),
                      Text(
                        'Cách rút tiền tại cây ATM',
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildStepRow(1,
                      'Đến bất kỳ cây ATM nào của Sen Hồng hoặc liên minh Napas.'),
                  const SizedBox(height: 10),
                  _buildStepRow(2,
                      'Bấm phím "Rút tiền không dùng thẻ" hoặc "Rút tiền bằng QR".'),
                  const SizedBox(height: 10),
                  _buildStepRow(3,
                      'Nhập mã giao dịch 6 số hoặc quét mã QR trên màn hình ATM để nhận tiền.'),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Nút Tạo mã rút tiền
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B885),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  elevation: 0,
                ),
                onPressed: _isLoading || _availableBalance == null
                    ? null
                    : _createWithdrawalCode,
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.qrcode, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Kiểm tra hỗ trợ rút tiền ATM',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 120), // Đệm đáy theo chuẩn Taste Skill
          ],
        ),
      ),
    );
  }

  Widget _buildStepRow(int number, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 20,
          height: 20,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: Color(0xFFF1F5F9),
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF475569),
              fontSize: 13,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
