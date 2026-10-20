import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/referral_remote_datasource.dart';

class ReferralScreen extends StatefulWidget {
  const ReferralScreen({super.key});

  @override
  State<ReferralScreen> createState() => _ReferralScreenState();
}

class _ReferralScreenState extends State<ReferralScreen> {
  final ReferralRemoteDataSource _dataSource = ReferralRemoteDataSource();

  String _myRefCode = 'SENHONG';
  bool _isLoading = true;
  List<Map<String, dynamic>> _invitedFriends = [];
  double _totalReward = 0;

  final List<Map<String, dynamic>> _tiers = const [
    {'name': 'Hạng Đồng', 'count': '1 - 3 bạn', 'bonus': '50.000 đ / lượt', 'min': 1},
    {'name': 'Hạng Bạc', 'count': '4 - 9 bạn', 'bonus': 'Thưởng thêm 200.000 đ', 'min': 4},
    {'name': 'Hạng Vàng', 'count': '10 - 19 bạn', 'bonus': 'Thưởng thêm 500.000 đ + Voucher', 'min': 10},
    {'name': 'Hạng Kim Cương', 'count': '20+ bạn', 'bonus': 'Thưởng 1.000.000 đ + Thẻ Platinum', 'min': 20},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final codeRes = await _dataSource.getReferralCode().catchError((_) => <String, dynamic>{});
      final historyRes = await _dataSource.getReferralHistory().catchError((_) => <Map<String, dynamic>>[]);

      if (!mounted) return;

      final code = codeRes['referralCode'] as String? ?? codeRes['code'] as String? ?? 'SENHONG8866';

      double total = 0;
      final friends = historyRes.map((item) {
        final reward = (item['rewardAmount'] as num?)?.toDouble() ?? 50000.0;
        final status = item['status'] as String? ?? 'Đã nhận thưởng';
        if (status.contains('thành công') || status.contains('nhận') || status == 'COMPLETED' || status == 'SUCCESS') {
          total += reward;
        }
        return {
          'name': item['friendName'] as String? ?? item['name'] as String? ?? 'Bạn bè Sen Hồng',
          'phone': item['phone'] as String? ?? '09******',
          'date': item['createdAt'] as String? ?? 'Gần đây',
          'reward': reward,
          'status': status,
        };
      }).toList();

      setState(() {
        _myRefCode = code;
        _invitedFriends = friends;
        _totalReward = total;
        _isLoading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showQrModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    'Mã QR Giới Thiệu Của Bạn',
                    style: AppTypography.titleLarge(color: AppColors.textPrimaryLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(CupertinoIcons.xmark)),
              ],
            ),
            const SizedBox(height: 16),
            QrImageView(
              data: 'https://senhongbank.vn/ref/$_myRefCode',
              size: 200,
              version: QrVersions.auto,
            ),
            const SizedBox(height: 16),
            Text(
              'Mã: $_myRefCode',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.primaryDark, letterSpacing: 2),
            ),
            const SizedBox(height: 6),
            Text(
              'Bạn bè quét mã để cài app và nhận ngay 50.000đ',
              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final friendsCount = _invitedFriends.length;

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Giới Thiệu Bạn Bè'),
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Promo Banner
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryDark, AppColors.primary, AppColors.bottomBarCyan],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.bottomBarGlow.withOpacity(0.25),
                              blurRadius: 14,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: const Icon(CupertinoIcons.gift_fill, color: Colors.white, size: 20),
                                ),
                                const SizedBox(width: 10),
                                const Expanded(
                                  child: Text(
                                    'LAN TỎA NIỀM VUI - NHẬN QUÀ KHỦNG',
                                    style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            const Text(
                              'Nhận ngay 50.000đ khi mời bạn bè mở tài khoản',
                              style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold, height: 1.3),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Bạn bè nhận gói voucher 500.000đ thanh toán hóa đơn và nạp thẻ sau khi kích hoạt thành công.',
                              style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12, height: 1.4),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Referral Code Box
                      GlassCard(
                        quality: GlassQuality.standard,
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            children: [
                              Text('Mã giới thiệu độc quyền của bạn', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                                decoration: BoxDecoration(
                                  color: AppColors.dividerLight,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(color: AppColors.primaryDark.withOpacity(0.3), width: 1.5),
                                ),
                                child: Text(
                                  _myRefCode,
                                  style: const TextStyle(
                                    color: AppColors.primaryDark,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 4,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 14),
                              Row(
                                children: [
                                  Expanded(
                                    child: ElevatedButton.icon(
                                      onPressed: () {
                                        HapticFeedback.selectionClick();
                                        Clipboard.setData(ClipboardData(text: 'https://senhongbank.vn/ref/$_myRefCode'));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppColors.emeraldGreen,
                                            content: Text('Đã sao chép link giới thiệu: https://senhongbank.vn/ref/$_myRefCode'),
                                          ),
                                        );
                                      },
                                      icon: const Icon(CupertinoIcons.doc_on_clipboard_fill, size: 16),
                                      label: const Text('Sao chép mã'),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      side: const BorderSide(color: AppColors.borderSubtle),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                    ),
                                    onPressed: () => _showQrModal(context),
                                    icon: const Icon(CupertinoIcons.qrcode, color: AppColors.primaryDark, size: 18),
                                    label: const Text('Mã QR', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Stats Row
                      Row(
                        children: [
                          Expanded(
                            child: GlassCard(
                              quality: GlassQuality.minimal,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Đã giới thiệu', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      alignment: Alignment.centerLeft,
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        '$friendsCount Bạn bè',
                                        style: AppTypography.titleLarge(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GlassCard(
                              quality: GlassQuality.minimal,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Tiền thưởng nhận', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                                    const SizedBox(height: 4),
                                    FittedBox(
                                      alignment: Alignment.centerLeft,
                                      fit: BoxFit.scaleDown,
                                      child: Text(
                                        CurrencyFormatter.formatVND(_totalReward),
                                        style: AppTypography.titleLarge(color: AppColors.emeraldGreen).copyWith(fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // 3 Steps Guide
                      Text('Cách thức nhận thưởng 3 bước', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 12),

                      GlassCard(
                        quality: GlassQuality.minimal,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: [
                              _buildStepItem('1', 'Chia sẻ link hoặc mã', 'Gửi mã $_myRefCode cho bạn bè, người thân qua Zalo, Messenger, SMS.'),
                              const Divider(height: 16, color: AppColors.cardBorderLight),
                              _buildStepItem('2', 'Bạn mở tài khoản & eKYC', 'Bạn bè tải app, nhập mã giới thiệu và chụp CCCD định danh eKYC.'),
                              const Divider(height: 16, color: AppColors.cardBorderLight),
                              _buildStepItem('3', 'Cả 2 cùng nhận thưởng', 'Ngay khi bạn bè có giao dịch đầu tiên từ 20.000đ, cả 2 nhận ngay 50.000đ vào ví.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Reward Tiers Progression
                      Text('Cấp bậc Thợ Săn Thưởng', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 12),

                      GlassCard(
                        quality: GlassQuality.minimal,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            children: _tiers.map((tier) {
                              final isReached = friendsCount >= (tier['min'] as int);
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Row(
                                  children: [
                                    Icon(
                                      isReached ? CupertinoIcons.checkmark_seal_fill : CupertinoIcons.circle,
                                      color: isReached ? AppColors.emeraldGreen : AppColors.textMutedLight,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tier['name'] as String,
                                            style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          Text(
                                            tier['count'] as String,
                                            style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        tier['bonus'] as String,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: isReached ? AppColors.emeraldGreen : AppColors.textSecondaryLight,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Invited Friends History
                      Text('Lịch sử bạn bè tham gia', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 12),

                      if (_invitedFriends.isEmpty)
                        GlassCard(
                          quality: GlassQuality.minimal,
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Center(
                              child: Column(
                                children: [
                                  const Icon(CupertinoIcons.person_2, size: 48, color: AppColors.textMutedLight),
                                  const SizedBox(height: 10),
                                  Text(
                                    'Chưa có bạn bè nào tham gia',
                                    style: AppTypography.titleMedium(color: AppColors.textPrimaryLight),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Chia sẻ mã giới thiệu $_myRefCode ngay để cùng nhận thưởng 50.000đ/bạn',
                                    textAlign: TextAlign.center,
                                    style: AppTypography.bodySmall(color: AppColors.textSecondaryLight),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )
                      else
                        ..._invitedFriends.map((f) {
                          final reward = (f['reward'] as num?)?.toDouble() ?? 0.0;
                          final isDone = reward > 0;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: GlassCard(
                              quality: GlassQuality.minimal,
                              child: Padding(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 18,
                                      backgroundColor: AppColors.primary.withOpacity(0.15),
                                      child: const Icon(CupertinoIcons.person_fill, color: AppColors.primaryDark, size: 16),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            f['name'] as String,
                                            style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${f['phone']} • ${f['date']}',
                                            style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        if (isDone)
                                          Text(
                                            '+${CurrencyFormatter.formatVND(reward)}',
                                            style: const TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 13),
                                          )
                                        else
                                          const Text(
                                            'Chờ nạp đầu',
                                            style: TextStyle(color: AppColors.warningText, fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        Text(
                                          f['status'] as String,
                                          style: const TextStyle(color: AppColors.textMutedLight, fontSize: 10),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),

                      const SizedBox(height: 24),

                      // Terms & Conditions
                      Text('Thể lệ chương trình', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 10),

                      GlassCard(
                        quality: GlassQuality.minimal,
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildRuleBullet('Chương trình áp dụng cho tất cả khách hàng cá nhân có tài khoản Sen Hồng Bank đã eKYC.'),
                              const SizedBox(height: 6),
                              _buildRuleBullet('Tiền thưởng được cộng trực tiếp vào số dư ví thanh toán trong vòng 24 giờ sau khi bạn bè hoàn thành điều kiện.'),
                              const SizedBox(height: 6),
                              _buildRuleBullet('Không giới hạn số lượt giới thiệu và tổng giá trị tiền thưởng nhận được trong suốt thời gian diễn ra chương trình.'),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildStepItem(String step, String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: AppColors.primary.withOpacity(0.15),
          child: Text(step, style: const TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRuleBullet(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('• ', style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold)),
        Expanded(child: Text(text, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12, height: 1.35))),
      ],
    );
  }
}
