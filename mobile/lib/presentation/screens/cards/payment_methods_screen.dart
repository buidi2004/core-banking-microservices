import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/bank_account_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';

class PaymentMethodsScreen extends StatefulWidget {
  const PaymentMethodsScreen({super.key});

  @override
  State<PaymentMethodsScreen> createState() => _PaymentMethodsScreenState();
}

class _PaymentMethodsScreenState extends State<PaymentMethodsScreen> {
  int _selectedSegment = 0; // 0: Thẻ Sen Hồng, 1: Ngân hàng liên kết
  bool _loading = true;
  double _walletBalance = 12580000.0;
  List<Map<String, dynamic>> _bankAccounts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      _walletBalance = wallet.balance;
    } catch (_) {}

    try {
      final rawAccounts = await BankAccountRemoteDataSource().getAccounts();
      _bankAccounts = rawAccounts.map((account) {
        final bankCode = account['bankCode'] as String? ?? 'BANK';
        final accNum = account['accountNumber'] as String? ?? '';
        final isDef = account['isDefault'] as bool? ?? false;
        return {
          'id': account['id']?.toString() ?? '',
          'bankCode': bankCode,
          'accountNumber': accNum,
          'isDefault': isDef,
        };
      }).toList();
    } catch (_) {}

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Nguồn Tiền & Phương Thức'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primary,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
            children: [
              // Apple Cupertino Segmented Control
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: CupertinoSlidingSegmentedControl<int>(
                  groupValue: _selectedSegment,
                  backgroundColor: Colors.transparent,
                  thumbColor: Colors.white,
                  children: const {
                    0: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.creditcard_fill, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('Thẻ Sen Hồng', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                    1: Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.building_2_fill, size: 16, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('Ngân Hàng Liên Kết', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        ],
                      ),
                    ),
                  },
                  onValueChanged: (val) {
                    if (val != null) {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSegment = val);
                    }
                  },
                ),
              ),
              const SizedBox(height: 18),

              // Segment 0: Thẻ Sen Hồng
              if (_selectedSegment == 0) ...[
                _buildCardsSegment(context),
              ] else ...[
                _buildBanksSegment(context),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardsSegment(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'THẺ THANH TOÁN QUỐC TẾ & GHI NỢ',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondaryLight,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/cards');
              },
              icon: const Icon(CupertinoIcons.arrow_up_right_square, size: 14, color: AppColors.primary),
              label: const Text('Xem tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 6),

        // Featured Card 1: Visa Signature
        _buildCreditCardTile(
          title: 'Sen Hồng Visa Signature',
          subtitle: '•••• •••• •••• 6688 • Hạn mức: 150.000.000 đ',
          typeBadge: 'CREDIT',
          badgeColor: const Color(0xFFD97706),
          isDefault: true,
          onTap: () => context.push('/cards'),
        ),
        const SizedBox(height: 12),

        // Featured Card 2: Napas Debit
        _buildCreditCardTile(
          title: 'Sen Hồng Napas Debit',
          subtitle: '•••• •••• •••• 9921 • Khả dụng: ${_formatCurrency(_walletBalance)} đ',
          typeBadge: 'DEBIT',
          badgeColor: AppColors.emeraldGreen,
          isDefault: false,
          onTap: () => context.push('/cards'),
        ),
        const SizedBox(height: 20),

        // Action Hub for Cards
        GlassCard(
          quality: GlassQuality.minimal,
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFE0F7FA), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(CupertinoIcons.creditcard, color: Color(0xFF0077B6), size: 18),
                ),
                title: const Text('Quản lý chi tiết & Khóa/mở thẻ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.textPrimaryLight)),
                subtitle: const Text('Tùy chỉnh hạn mức, mã PIN và thanh toán online', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.textMutedLight),
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/cards');
                },
              ),
              const Divider(height: 1, indent: 60, color: AppColors.dividerLight),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFFEF3C7), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(CupertinoIcons.plus_circle, color: Color(0xFFD97706), size: 18),
                ),
                title: const Text('Mở thêm thẻ ảo phi vật lý mới', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.textPrimaryLight)),
                subtitle: const Text('Phát hành tức thì 0đ phí thường niên', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.textMutedLight),
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/cards');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBanksSegment(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'TÀI KHOẢN NGÂN HÀNG LIÊN KẾT',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
                color: AppColors.textSecondaryLight,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                HapticFeedback.selectionClick();
                context.push('/bank-cards');
              },
              icon: const Icon(CupertinoIcons.plus_circle_fill, size: 14, color: AppColors.primary),
              label: const Text('Liên kết mới', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ),
          ],
        ),
        const SizedBox(height: 6),

        if (_loading) ...[
          const Center(child: Padding(padding: EdgeInsets.all(24), child: CircularProgressIndicator(color: AppColors.primary))),
        ] else if (_bankAccounts.isEmpty) ...[
          // Mock display bank cards if none returned
          _buildBankTile(
            bankCode: 'VCB',
            bankName: 'Vietcombank (Ngoại Thương Việt Nam)',
            accountNumber: '•••• 8829',
            isDefault: true,
            onTap: () => context.push('/bank-cards'),
          ),
          const SizedBox(height: 12),
          _buildBankTile(
            bankCode: 'TCB',
            bankName: 'Techcombank (Kỹ Thương Việt Nam)',
            accountNumber: '•••• 1902',
            isDefault: false,
            onTap: () => context.push('/bank-cards'),
          ),
        ] else ...[
          ..._bankAccounts.map((b) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _buildBankTile(
              bankCode: b['bankCode'] as String,
              bankName: 'Ngân hàng liên kết ${b['bankCode']}',
              accountNumber: b['accountNumber'] as String,
              isDefault: b['isDefault'] as bool,
              onTap: () => context.push('/bank-cards'),
            ),
          )),
        ],
        const SizedBox(height: 20),

        // Quick Movement Actions
        GlassCard(
          quality: GlassQuality.minimal,
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFD1FAE5), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(CupertinoIcons.arrow_down_circle_fill, color: Color(0xFF059669), size: 18),
                ),
                title: const Text('Nạp tiền vào ví từ ngân hàng liên kết', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.textPrimaryLight)),
                subtitle: const Text('Miễn phí giao dịch 24/7, có tiền ngay', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.textMutedLight),
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/deposit');
                },
              ),
              const Divider(height: 1, indent: 60, color: AppColors.dividerLight),
              ListTile(
                leading: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(10)),
                  child: const Icon(CupertinoIcons.arrow_up_circle_fill, color: Color(0xFF4F46E5), size: 18),
                ),
                title: const Text('Rút tiền về tài khoản ngân hàng chính chủ', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.textPrimaryLight)),
                subtitle: const Text('Tất toán an toàn về tài khoản đã đối soát', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
                trailing: const Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.textMutedLight),
                onTap: () {
                  HapticFeedback.selectionClick();
                  context.push('/withdraw');
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreditCardTile({
    required String title,
    required String subtitle,
    required String typeBadge,
    required Color badgeColor,
    required bool isDefault,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: badgeColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(CupertinoIcons.creditcard_fill, color: badgeColor, size: 22),
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
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(4)),
                            child: Text(typeBadge, style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: badgeColor)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(subtitle, style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                if (isDefault)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Mặc định', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen)),
                  ),
                const Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.textMutedLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBankTile({
    required String bankCode,
    required String bankName,
    required String accountNumber,
    required bool isDefault,
    required VoidCallback onTap,
  }) {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            onTap();
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE0E7FF),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(CupertinoIcons.building_2_fill, color: Color(0xFF4F46E5), size: 22),
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
                              bankName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.bodyMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                            decoration: BoxDecoration(color: const Color(0xFFE0E7FF), borderRadius: BorderRadius.circular(4)),
                            child: Text(bankCode, style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Color(0xFF4F46E5))),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('STK: $accountNumber', style: const TextStyle(fontSize: 11.5, color: AppColors.textSecondaryLight)),
                    ],
                  ),
                ),
                if (isDefault)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreen.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Mặc định', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen)),
                  ),
                const Icon(CupertinoIcons.chevron_forward, size: 16, color: AppColors.textMutedLight),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatCurrency(double val) {
    final parts = val.toStringAsFixed(0).split('');
    final buffer = StringBuffer();
    for (int i = 0; i < parts.length; i++) {
      if (i > 0 && (parts.length - i) % 3 == 0) {
        buffer.write('.');
      }
      buffer.write(parts[i]);
    }
    return buffer.toString();
  }
}
