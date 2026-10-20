import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transaction_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/curved_promo_banner.dart';
import 'package:sen_hong_bank/presentation/widgets/vietnam_hero_header.dart';
import 'package:sen_hong_bank/presentation/widgets/app_morph_icon.dart';
import 'package:flutter/services.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _hideBalance = false;
  double _balance = 0;
  String _displayName = '';
  String _accountNumber = '';
  bool _isLoading = true;
  List<Map<String, dynamic>> _recentTransactions = [];

  final List<Map<String, dynamic>> _quickServices = const [
    {'icon': Icons.send_outlined, 'label': 'Chuyển tiền', 'route': '/transfer'},
    {'icon': Icons.phone_android_outlined, 'label': 'Nạp ĐT', 'route': '/bills/phone-recharge'},
    {'icon': Icons.receipt_long_outlined, 'label': 'Điện nước', 'route': '/bills'},
    {'icon': Icons.account_balance_outlined, 'label': 'Tiết kiệm', 'route': '/bills/savings'},
    {'icon': Icons.trending_up_rounded, 'label': 'Vay nhanh', 'route': '/bills/quick-loan'},
    {'icon': Icons.confirmation_number_outlined, 'label': 'Vietlott', 'route': '/bills/lottery'},
    {'icon': Icons.credit_card_outlined, 'label': 'Quản lý thẻ', 'route': '/cards'},
    {'icon': Icons.grid_view_outlined, 'label': 'Xem thêm', 'route': '/more'},
  ];

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    await Future.wait([
      _loadProfile(),
      _loadWalletAndTransactions(),
    ]);
  }

  Future<void> _loadProfile() async {
    try {
      const storage = FlutterSecureStorage();
      final savedPhone = await storage.read(key: AppConstants.keyPhoneNumber);
      final savedName = await storage.read(key: AppConstants.keyFullName);
      if (mounted && (savedPhone != null || savedName != null)) {
        setState(() {
          if (savedPhone != null && savedPhone.isNotEmpty) _accountNumber = savedPhone;
          if (savedName != null && savedName.isNotEmpty) _displayName = savedName;
        });
      }

      final profile = await ProfileRemoteDataSource().getMe();
      if (!mounted) return;
      setState(() {
        final fullName = profile['fullName'] as String?;
        if (fullName != null && fullName.isNotEmpty) {
          _displayName = fullName;
        }
        final phone = profile['phoneNumber'] as String?;
        if (phone != null && phone.isNotEmpty) {
          _accountNumber = phone;
        }
      });
    } catch (_) {}
  }

  Future<void> _loadWalletAndTransactions() async {
    try {
      final wallet = await WalletRemoteDataSource().getMyWallet();
      if (mounted) {
        setState(() => _balance = wallet.balance);
      }
      final transactions = await TransactionRemoteDataSource().getTransactions(
        walletId: wallet.walletId,
        size: 3,
      );
      if (mounted) {
        setState(() {
          _recentTransactions = transactions.take(3).toList();
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _loadAllData,
        color: AppColors.primary,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(parent: BouncingScrollPhysics()),
          slivers: [
            // 1. Header Lễ Hội SenBank Tích Hợp Toàn Bộ Thông Tin (Lời chào, STK, Số dư)
            SliverToBoxAdapter(
              child: VietnamHeroHeader(
                balance: _balance,
                isHidden: _hideBalance,
                onToggleVisibility: () => setState(() => _hideBalance = !_hideBalance),
                onNotificationTap: () => context.push('/notifications'),
                onSearchTap: () => context.push('/search'),
                onTransfer: () => context.push('/transfer'),
                onDeposit: () => context.push('/deposit'),
                onWithdraw: () => context.push('/withdraw'),
                onQr: () => context.push('/my-qr'),
                onProfileTap: () => context.push('/profile'),
                displayName: _displayName,
                accountNumber: _accountNumber,
              ),
            ),

            // Quick Services Grid
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                child: Text(
                  'Dịch vụ nổi bật',
                  style: AppTypography.titleLarge(color: AppColors.textPrimaryLight),
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.85,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final item = _quickServices[index];
                    return InkWell(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        context.push(item['route'] as String);
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 52,
                            height: 52,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Icon(
                              item['icon'] as IconData,
                              color: AppColors.primary,
                              size: 24,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            item['label'] as String,
                            textAlign: TextAlign.center,
                            style: AppTypography.bodySmall(color: AppColors.textPrimaryLight).copyWith(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    );
                  },
                  childCount: _quickServices.length,
                ),
              ),
            ),

            // Banner Promotion (Curved shape bẻ cong ảnh dưới)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: CurvedPromoBanner(
                  onRegisterTap: () => context.push('/promotions'),
                ),
              ),
            ),

            // Recent Transactions Section Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Giao dịch gần đây',
                          style: AppTypography.titleLarge(color: AppColors.textPrimaryLight),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() => _hideBalance = !_hideBalance);
                          },
                          child: AppMorphIcon(
                            icon: _hideBalance ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 19,
                            color: AppColors.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    TextButton(
                      onPressed: () => context.push('/history'),
                      child: const Text('Xem tất cả', style: TextStyle(color: AppColors.primary)),
                    ),
                  ],
                ),
              ),
            ),

            // Recent Transactions List
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                ),
              )
            else if (_recentTransactions.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.7)),
                    ),
                    child: Column(
                      children: [
                        const Icon(CupertinoIcons.doc_text_search, size: 40, color: AppColors.textMutedLight),
                        const SizedBox(height: 8),
                        Text('Chưa có giao dịch phát sinh', style: AppTypography.titleSmall(color: AppColors.textSecondaryLight)),
                        const SizedBox(height: 4),
                        const Text(
                          'Nạp tiền hoặc chuyển tiền để trải nghiệm dịch vụ ngân hàng SenBank ngay!',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.textMutedLight),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final tx = _recentTransactions[index];
                      final amountNum = (tx['amount'] as num?)?.toDouble() ?? 0.0;
                      final isPositive = amountNum > 0;
                      final title = tx['title'] as String? ?? 'Giao dịch';
                      final desc = tx['desc'] as String? ?? '';
                      final date = tx['date']?.toString() ?? '';

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.white.withOpacity(0.7), width: 1),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Material(
                            type: MaterialType.transparency,
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              leading: CircleAvatar(
                                backgroundColor: isPositive
                                    ? AppColors.emeraldGreen.withOpacity(0.12)
                                    : AppColors.primary.withOpacity(0.12),
                                child: Icon(
                                  isPositive ? CupertinoIcons.arrow_down_left : CupertinoIcons.arrow_up_right,
                                  color: isPositive ? AppColors.emeraldGreen : AppColors.primary,
                                  size: 18,
                                ),
                              ),
                              title: Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.titleMedium(color: AppColors.textPrimaryLight),
                              ),
                              subtitle: Text(
                                desc.isNotEmpty ? '$desc • $date' : date,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                              ),
                              trailing: Text(
                                _hideBalance
                                    ? '••••••••'
                                    : '${isPositive ? '+' : ''}${CurrencyFormatter.formatVND(amountNum)}',
                                style: AppTypography.titleMedium(
                                  color: isPositive ? AppColors.emeraldGreen : AppColors.textPrimaryLight,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    childCount: _recentTransactions.length,
                  ),
                ),
              ),

            // Bottom Curved Promo & Feature Banner ("bẻ cong ảnh dưới" & "ghép ảnh chéo")
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: CurvedPromoBanner(
                  isDiagonalSlanted: true,
                  onRegisterTap: () => context.push('/promotions'),
                ),
              ),
            ),

            // Khoảng trống đệm để cuộn banner lướt qua dưới thanh kính nổi (Glass Refraction)
            const SliverToBoxAdapter(
              child: SizedBox(height: 380),
            ),
          ],
        ),
      ),
    );
  }
}
