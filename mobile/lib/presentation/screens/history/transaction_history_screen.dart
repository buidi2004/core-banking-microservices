import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/auth_local_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionHistoryScreen extends StatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  State<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends State<TransactionHistoryScreen> {
  int _selectedFilter = 0; // 0: Tất cả, 1: Chuyển, 2: Nạp/Rút, 3: Hóa đơn

  final List<String> _filters = ['Tất cả', 'Chuyển tiền', 'Nạp / Rút', 'Hóa đơn'];

  final ScrollController _scrollController = ScrollController();
  List<Map<String, dynamic>> _allTransactions = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _isLastPage = false;
  int _currentPage = 0;
  String? _walletId;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadTransactions(refresh: true);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      if (!_isLoadingMore && !_isLastPage && !_isLoading) {
        _loadMoreTransactions();
      }
    }
  }

  String? _getTypeFilter() {
    switch (_selectedFilter) {
      case 1:
        return 'TRANSFER';
      case 2:
        return 'DEPOSIT';
      case 3:
        return 'BILL_PAYMENT';
      default:
        return null;
    }
  }

  String _formatTxDate(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    try {
      final dt = DateTime.tryParse(raw);
      if (dt != null) {
        final local = dt.toLocal();
        return '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')} - ${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}';
      }
    } catch (_) {}
    return raw;
  }

  Future<void> _loadTransactions({bool refresh = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final token = await AuthLocalDataSourceImpl(prefs: prefs).getAccessToken();
    if (token == null || token.isEmpty) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    if (refresh) {
      setState(() {
        _isLoading = true;
        _currentPage = 0;
        _isLastPage = false;
      });
    }

    try {
      if (_walletId == null) {
        final wallet = await WalletRemoteDataSource().getMyWallet();
        _walletId = wallet.walletId;
      }
      final res = await TransactionRemoteDataSource().getTransactionsPage(
        walletId: _walletId!,
        type: _getTypeFilter(),
        page: 0,
        size: 20,
      );
      if (mounted) {
        setState(() {
          _allTransactions = List<Map<String, dynamic>>.from(res['items'] as List);
          _isLastPage = (res['isLast'] ?? false) as bool;
          _currentPage = 0;
          _isLoading = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoading = false);
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Lỗi tải lịch sử',
        );
      }
    }
  }

  Future<void> _loadMoreTransactions() async {
    if (_isLoadingMore || _isLastPage || _walletId == null) return;
    setState(() => _isLoadingMore = true);

    try {
      final nextPage = _currentPage + 1;
      final res = await TransactionRemoteDataSource().getTransactionsPage(
        walletId: _walletId!,
        type: _getTypeFilter(),
        page: nextPage,
        size: 20,
      );
      final newItems = List<Map<String, dynamic>>.from(res['items'] as List);
      if (mounted) {
        setState(() {
          _allTransactions.addAll(newItems);
          _currentPage = nextPage;
          _isLastPage = (res['isLast'] ?? false) as bool || newItems.isEmpty;
          _isLoadingMore = false;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _isLoadingMore = false);
      }
    }
  }

  Future<void> _exportStatement(String format) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = await AuthLocalDataSourceImpl(prefs: prefs).getAccessToken();
      if (token == null || token.isEmpty) throw Exception('Vui lòng đăng nhập để xuất sao kê');
      final wallet = await WalletRemoteDataSource().getMyWallet();
      final bytes = await TransactionRemoteDataSource().exportTransactions(walletId: wallet.walletId, format: format);
      if (mounted) {
        AppAlerts.showSuccess(
          context,
          'Đã xuất thành công sao kê $format (${bytes.length} bytes)',
          title: 'Xuất sao kê',
        );
      }
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Xuất sao kê thất bại',
        );
      }
    }
  }

  IconData _getTransactionIcon(Map<String, dynamic> tx) {
    final title = (tx['title'] as String? ?? '').toLowerCase();
    final type = (tx['type'] as String? ?? '').toLowerCase();

    if (title.contains('điện thoại') || title.contains('viettel') || title.contains('vina') || title.contains('mobi') || type == 'recharge') {
      return CupertinoIcons.device_phone_portrait;
    }
    if (title.contains('evn') || title.contains('tiền điện') || type == 'electricity') {
      return CupertinoIcons.bolt_fill;
    }
    if (title.contains('nước') || type == 'water') {
      return CupertinoIcons.drop_fill;
    }
    if (type == 'deposit' || title.contains('nạp tiền')) {
      return CupertinoIcons.arrow_down_circle_fill;
    }
    if (type == 'withdraw' || title.contains('rút tiền')) {
      return CupertinoIcons.arrow_up_right_circle_fill;
    }
    if (type == 'transfer' || title.contains('chuyển tiền')) {
      return CupertinoIcons.arrow_up_circle_fill;
    }
    if (title.contains('vietlott') || title.contains('vé số')) {
      return CupertinoIcons.ticket_fill;
    }
    final isPositive = ((tx['amount'] as num?)?.toDouble() ?? 0.0) > 0;
    return isPositive ? CupertinoIcons.arrow_down_circle_fill : CupertinoIcons.arrow_up_circle_fill;
  }

  Color _getTransactionColor(Map<String, dynamic> tx) {
    final title = (tx['title'] as String? ?? '').toLowerCase();
    final type = (tx['type'] as String? ?? '').toLowerCase();

    if (title.contains('điện thoại') || title.contains('viettel') || title.contains('vina') || title.contains('mobi') || type == 'recharge') {
      return AppColors.softPurple;
    }
    if (title.contains('evn') || title.contains('tiền điện') || type == 'electricity') {
      return AppColors.warning;
    }
    if (title.contains('nước') || type == 'water') {
      return AppColors.primaryDark;
    }
    if (type == 'deposit' || title.contains('nạp tiền')) {
      return AppColors.emeraldGreen;
    }
    if (type == 'withdraw' || title.contains('rút tiền')) {
      return AppColors.warningText;
    }
    if (type == 'transfer' || title.contains('chuyển tiền')) {
      return AppColors.primary;
    }
    final isPositive = ((tx['amount'] as num?)?.toDouble() ?? 0.0) > 0;
    return isPositive ? AppColors.emeraldGreen : AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Lịch Sử Giao Dịch'),
        actions: [
          IconButton(
            onPressed: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.white,
                useSafeArea: true,
                showDragHandle: true,
                shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
                builder: (ctx) => Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Xuất Sao Kê Giao Dịch',
                              style: AppTypography.titleLarge(color: AppColors.textPrimaryLight),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(CupertinoIcons.xmark, color: AppColors.textPrimaryLight)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('Chọn định dạng báo cáo cần tải về máy:', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                      const SizedBox(height: 16),
                      Material(type: MaterialType.transparency, child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.error.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(CupertinoIcons.doc_fill, color: AppColors.error, size: 22),
                        ),
                        title: const Text('Tải file PDF (Có mộc đỏ điện tử)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                        subtitle: const Text('Phù hợp nộp chứng từ kế toán, xin visa', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _exportStatement('pdf');
                        },
                      )),
                      const Divider(height: 1),
                      Material(type: MaterialType.transparency, child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.emeraldGreen.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(CupertinoIcons.table_fill, color: AppColors.emeraldGreen, size: 22),
                        ),
                        title: const Text('Tải file Excel (.XLSX)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                        subtitle: const Text('Dành cho phân tích thu chi cá nhân', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _exportStatement('excel');
                        },
                      )),
                      const Divider(height: 1),
                      Material(type: MaterialType.transparency, child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
                          child: const Icon(CupertinoIcons.doc_text_fill, color: AppColors.primary, size: 22),
                        ),
                        title: const Text('Tải file CSV (.CSV)', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textPrimaryLight)),
                        subtitle: const Text('Dành cho tích hợp phần mềm tài chính', style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                        onTap: () {
                          Navigator.pop(ctx);
                          _exportStatement('csv');
                        },
                      )),
                    ],
                  ),
                ),
              );
            },
            icon: const Icon(CupertinoIcons.arrow_down_doc_fill, color: AppColors.primary),
            tooltip: 'Xuất sao kê',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter Pills
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                children: List.generate(_filters.length, (idx) {
                  final isSelected = _selectedFilter == idx;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(_filters[idx]),
                      selected: isSelected,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white.withOpacity(0.8),
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppColors.textPrimaryLight,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: isSelected ? AppColors.bottomBarCyan : Colors.white.withOpacity(0.6),
                        width: isSelected ? 1.5 : 1.0,
                      ),
                      shadowColor: AppColors.bottomBarGlow.withOpacity(0.4),
                      elevation: isSelected ? 3 : 0,
                      onSelected: (_) {
                        HapticFeedback.selectionClick();
                        setState(() => _selectedFilter = idx);
                        _loadTransactions(refresh: true);
                      },
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: 8),

            // Transactions List with Pagination & Pull-to-Refresh
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 240),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: child,
                ),
                child: KeyedSubtree(
                  key: ValueKey('filter_${_selectedFilter}_loading_$_isLoading'),
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                      : _allTransactions.isEmpty
                      ? RefreshIndicator(
                          onRefresh: () => _loadTransactions(refresh: true),
                          color: AppColors.primary,
                          child: ListView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                              Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(CupertinoIcons.doc_text_fill, size: 56, color: AppColors.textMutedLight.withOpacity(0.5)),
                                    const SizedBox(height: 14),
                                    Text('Chưa có giao dịch nào', style: AppTypography.titleMedium(color: AppColors.textMutedLight)),
                                    const SizedBox(height: 6),
                                    Text('Kéo xuống để cập nhật biến động số dư', style: AppTypography.bodySmall(color: AppColors.textMutedLight.withOpacity(0.7))),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => _loadTransactions(refresh: true),
                          color: AppColors.primary,
                          child: ListView.builder(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                            itemCount: _allTransactions.length + (_isLoadingMore || _isLastPage ? 1 : 0),
                            itemBuilder: (context, index) {
                              if (index == _allTransactions.length) {
                                if (_isLoadingMore) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                                      ),
                                    ),
                                  );
                                }
                                return Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  child: Center(
                                    child: Text(
                                      'Đã hiển thị tất cả giao dịch',
                                      style: AppTypography.bodySmall(color: AppColors.textMutedLight),
                                    ),
                                  ),
                                );
                              }

                              final tx = _allTransactions[index];
                              final num rawAmount = (tx['amount'] as num?) ?? 0;
                              final double amount = rawAmount.toDouble();
                              final isPositive = amount > 0;
                              final txIcon = _getTransactionIcon(tx);
                              final txColor = _getTransactionColor(tx);
                              final formattedDate = _formatTxDate(tx['date']?.toString());
                              final desc = (tx['desc'] ?? tx['note'] ?? '').toString();
                              final runningBalance = tx['runningBalance'] as num?;
                              final statusStr = (tx['status'] ?? 'SUCCESS').toString();

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: GlassCard(
                                  quality: GlassQuality.minimal, // Minimal: tối ưu 0 chi phí shader khi cuộn mượt mà
                                  child: Material(type: MaterialType.transparency, child: ListTile(
                                    onTap: () {
                                      final uri = Uri(
                                        path: '/history/detail',
                                        queryParameters: {
                                          'id': (tx['id'] ?? '').toString(),
                                          'title': (tx['title'] ?? 'Giao dịch').toString(),
                                          'amount': amount.toString(),
                                          'time': (tx['date'] ?? '').toString(),
                                          'note': (tx['desc'] ?? '').toString(),
                                          'recipient': (tx['counterpartyName'] ?? '').toString(),
                                        },
                                      );
                                      context.push(uri.toString());
                                    },
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    leading: Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: txColor.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: txColor.withOpacity(0.24),
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Icon(
                                        txIcon,
                                        color: txColor,
                                        size: 22,
                                      ),
                                    ),
                                    title: Text(
                                      (tx['title'] ?? 'Giao dịch').toString(),
                                      style: AppTypography.titleMedium(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold, fontSize: 13.5),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    subtitle: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        if (desc.isNotEmpty) ...[
                                          const SizedBox(height: 3),
                                          Text(
                                            desc,
                                            style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(fontSize: 11, color: AppColors.textMutedLight),
                                            ),
                                            if (runningBalance != null)
                                              const SizedBox(width: 8),
                                            if (runningBalance != null)
                                              Flexible(
                                                child: Text(
                                                  'Số dư: ${CurrencyFormatter.formatVND(runningBalance)}',
                                                  style: const TextStyle(fontSize: 11, color: AppColors.primaryDark, fontWeight: FontWeight.w600),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    trailing: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        FittedBox(
                                          fit: BoxFit.scaleDown,
                                          alignment: Alignment.centerRight,
                                          child: Text(
                                            '${isPositive ? '+' : (amount < 0 ? '-' : '')}${CurrencyFormatter.formatVND(amount.abs())}',
                                            style: AppTypography.titleMedium(
                                              color: isPositive ? AppColors.emeraldGreen : AppColors.textPrimaryLight,
                                            ).copyWith(fontWeight: FontWeight.bold, fontSize: 13.5),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: (statusStr == 'SUCCESS' ? AppColors.emeraldGreen : AppColors.primary).withOpacity(0.12),
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: Text(
                                            statusStr == 'SUCCESS' ? 'Thành công' : statusStr,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: statusStr == 'SUCCESS' ? AppColors.emeraldGreen : AppColors.primary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )),
                                ),
                              );
                            },
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
