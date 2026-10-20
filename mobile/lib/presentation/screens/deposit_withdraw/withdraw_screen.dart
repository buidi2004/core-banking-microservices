import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/bank_account_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';

import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final TextEditingController _amountCtrl = TextEditingController(text: '1000000');
  int _selectedBankIdx = 0;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  List<Map<String, String>> _linkedBanks = [];
  double _availableBalance = 0;
  List<Map<String, dynamic>> _recentWithdrawals = [];
  bool _isLoadingHistory = false;

  @override
  void initState() {
    super.initState();
    _loadBankAccounts();
    _loadBalanceAndHistory();
  }

  Future<void> _loadBalanceAndHistory() async {
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      if (mounted) setState(() => _availableBalance = wallet.balance);
      _loadWithdrawalHistory(wallet.walletId);
    } catch (_) {}
  }

  Future<void> _loadWithdrawalHistory(String walletId) async {
    if (!mounted) return;
    setState(() => _isLoadingHistory = true);
    try {
      final txs = await TransactionRemoteDataSource().getTransactions(
        walletId: walletId,
        type: 'WITHDRAWAL',
        size: 5,
      );
      if (!mounted) return;
      setState(() {
        _recentWithdrawals = txs.map((tx) {
          final amt = (tx['amount'] as num?)?.toDouble() ?? 0.0;
          final timeStr = tx['createdAt'] as String? ?? '';
          final statusStr = tx['status'] == 'SUCCESS' ? 'Rút thành công' : (tx['status'] ?? 'Thành công');
          final desc = tx['description'] as String? ?? 'Rút tiền về tài khoản';
          return {
            'bank': desc,
            'amount': amt,
            'time': timeStr.isNotEmpty && timeStr.length >= 16 ? timeStr.substring(0, 16).replaceAll('T', ' ') : timeStr,
            'status': statusStr,
          };
        }).toList();
        _isLoadingHistory = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoadingHistory = false);
    }
  }

  Future<void> _loadBankAccounts() async {
    try {
      final accounts = await BankAccountRemoteDataSource().getAccounts();
      if (!mounted) return;
      setState(() {
        _linkedBanks = accounts.map((account) => {
          'id': account['id'] as String,
          'bank': account['bankCode'] as String? ?? '',
          'acc': account['accountNumber'] as String? ?? '',
          'name': account['accountHolderName'] as String? ?? '',
          'logo': account['bankCode'] as String? ?? '?',
        }).toList();
        if (_selectedBankIdx >= _linkedBanks.length) _selectedBankIdx = 0;
      });
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Tài khoản ngân hàng',
        );
      }
    }
  }

  final List<double> _quickChips = [200000, 500000, 1000000, 2000000, 5000000];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Rút Tiền Về Ngân Hàng'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Balance Badge
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary, AppColors.bottomBarCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(color: AppColors.bottomBarGlow.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3)),
                  ],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('SỐ DƯ KHẢ DỤNG CỦA VÍ', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              CurrencyFormatter.formatVND(_availableBalance),
                              style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: AppColors.primaryDark,
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        minimumSize: const Size(0, 36),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        HapticFeedback.selectionClick();
                        setState(() => _amountCtrl.text = _availableBalance.toInt().toString());
                      },
                      child: const Text('Rút tất cả', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Withdraw Limit Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.successBorder),
                ),
                child: const Row(
                  children: [
                    Icon(CupertinoIcons.checkmark_shield_fill, color: AppColors.emeraldGreen, size: 28),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('HẠN MỨC RÚT TIỀN: 100.000.000 Đ / NGÀY', style: TextStyle(color: AppColors.successText, fontSize: 11, fontWeight: FontWeight.bold)),
                          SizedBox(height: 2),
                          Text('Miễn phí rút tiền còn lại: 10/10 lượt tháng này', style: TextStyle(color: AppColors.successText, fontSize: 13, fontWeight: FontWeight.bold)),
                          Text('Tiền về tài khoản ngân hàng tức thì trong 30 giây (Napas 24/7)', style: TextStyle(color: AppColors.successText, fontSize: 11)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Amount Input Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Nhập số tiền cần rút', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _amountCtrl,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(color: AppColors.primaryDark, fontSize: 28, fontWeight: FontWeight.w900),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          suffixIcon: _amountCtrl.text.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(CupertinoIcons.clear_circled_solid, color: AppColors.textMutedLight, size: 20),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _amountCtrl.clear());
                                  },
                                )
                              : null,
                          suffixText: 'đ',
                          suffixStyle: const TextStyle(color: AppColors.primaryDark, fontSize: 22, fontWeight: FontWeight.bold),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          'Bằng chữ: ${CurrencyFormatter.toVietnameseWords(double.tryParse(_amountCtrl.text) ?? 0)} đồng',
                          style: AppTypography.bodySmall(color: AppColors.primaryDark).copyWith(
                            fontStyle: FontStyle.italic,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _quickChips.map((amt) {
                          return ActionChip(
                            label: Text(CurrencyFormatter.formatVND(amt)),
                            backgroundColor: AppColors.surfaceLight,
                            labelStyle: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                            side: const BorderSide(color: AppColors.borderLight),
                            onPressed: () {
                              HapticFeedback.selectionClick();
                              setState(() => _amountCtrl.text = amt.toInt().toString());
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Linked Bank Selection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Tài khoản ngân hàng nhận tiền',
                      style: AppTypography.titleLarge(color: AppColors.textPrimaryLight),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      await context.push('/bank-cards');
                      _loadBankAccounts();
                    },
                    icon: const Icon(CupertinoIcons.plus_circle, size: 16),
                    label: const Text('Thêm ngân hàng'),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (_linkedBanks.isEmpty)
                GlassCard(
                  quality: GlassQuality.minimal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      children: [
                        const Icon(CupertinoIcons.creditcard, size: 44, color: AppColors.textMutedLight),
                        const SizedBox(height: 10),
                        Text(
                          'Chưa có tài khoản ngân hàng liên kết',
                          style: AppTypography.titleMedium(color: AppColors.textPrimaryLight),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Vui lòng liên kết tài khoản ngân hàng chính chủ để rút tiền về tức thì 24/7',
                          textAlign: TextAlign.center,
                          style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                        ),
                        const SizedBox(height: 14),
                        ElevatedButton.icon(
                          onPressed: () async {
                            await context.push('/bank-cards');
                            _loadBankAccounts();
                          },
                          icon: const Icon(CupertinoIcons.plus_circle_fill, size: 16),
                          label: const Text('Liên kết ngân hàng ngay'),
                        ),
                      ],
                    ),
                  ),
                )
              else
                ...List.generate(_linkedBanks.length, (idx) {
                  final b = _linkedBanks[idx];
                  final isSelected = _selectedBankIdx == idx;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: isSelected ? Border.all(color: AppColors.primaryDark, width: 1.8) : null,
                      ),
                      child: GlassCard(
                        quality: GlassQuality.minimal,
                        child: Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selectedBankIdx = idx);
                            },
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.12),
                              child: Text(b['logo']!, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 11)),
                            ),
                            title: Text(
                              '${b['bank']} - ${b['acc']}',
                              style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              b['name']!,
                              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: isSelected
                                ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.emeraldGreen)
                                : const Icon(CupertinoIcons.circle, color: AppColors.textMutedLight),
                          ),
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isSubmitting
                      ? null
                      : () async {
                          final amt = double.tryParse(_amountCtrl.text) ?? 0;
                          if (amt < 20000) {
                            AppAlerts.showWarning(context, 'Số tiền rút tối thiểu là 20.000đ', title: 'Hạn mức rút tiền');
                            return;
                          }
                          if (amt > _availableBalance) {
                            AppAlerts.showWarning(
                              context,
                              'Số tiền rút vượt quá số dư khả dụng (${CurrencyFormatter.formatVND(_availableBalance)})',
                              title: 'Số dư không đủ',
                            );
                            return;
                          }
                          if (_linkedBanks.isEmpty) {
                            AppAlerts.showWarning(
                              context,
                              'Chưa có tài khoản ngân hàng liên kết để nhận tiền',
                              title: 'Tài khoản liên kết',
                              actionLabel: 'Thêm mới',
                              onAction: () => context.push('/bank-cards'),
                            );
                            return;
                          }

                          setState(() => _isSubmitting = true);
                          HapticFeedback.mediumImpact();

                          final target = _linkedBanks[_selectedBankIdx];
                          await context.push('/withdraw/confirm?amount=$amt&bank=${target['bank']}&acc=${target['acc']}&bankAccountId=${target['id']}');
                          if (mounted) setState(() => _isSubmitting = false);
                        },
                  child: _isSubmitting
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Tiếp tục xác nhận rút tiền'),
                ),
              ),
              const SizedBox(height: 24),

              // Recent Withdrawals Log
              Text('Giao dịch rút tiền gần đây', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 12),

              if (_isLoadingHistory)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(),
                  ),
                )
              else if (_recentWithdrawals.isEmpty)
                GlassCard(
                  quality: GlassQuality.minimal,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(CupertinoIcons.clock, color: AppColors.textMutedLight, size: 36),
                          const SizedBox(height: 8),
                          Text(
                            'Chưa có giao dịch rút tiền gần đây',
                            style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                ..._recentWithdrawals.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      quality: GlassQuality.minimal,
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(CupertinoIcons.arrow_up_circle_fill, color: AppColors.primaryDark, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['bank'] as String,
                                    style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold, fontSize: 13),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    item['time'] as String,
                                    style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '-${CurrencyFormatter.formatVND(item['amount'] as double)}',
                                  style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                                Text(
                                  item['status'] as String,
                                  style: const TextStyle(color: AppColors.emeraldGreen, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
