import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';

class KycLevelScreen extends StatefulWidget {
  const KycLevelScreen({super.key});

  @override
  State<KycLevelScreen> createState() => _KycLevelScreenState();
}

class _KycLevelScreenState extends State<KycLevelScreen> {
  double _customDailyLimit = 0;
  double _usedToday = 0;
  double _maxDailyLimit = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLimits();
  }

  Future<void> _loadLimits() async {
    try {
      final data = await ProfileRemoteDataSource().getLimitStatus();
      if (!mounted) return;
      setState(() {
        _customDailyLimit = (data['dailyLimit'] as num?)?.toDouble() ?? 0;
        _maxDailyLimit = _customDailyLimit;
        _usedToday = (data['dailySpent'] as num?)?.toDouble() ?? 0;
        _loading = false;
      });
    } catch (error) {
      if (mounted) setState(() { _error = extractErrorMessage(error); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingToday = (_customDailyLimit - _usedToday).clamp(0.0, _customDailyLimit);
    final usagePercent = (_usedToday / _customDailyLimit).clamp(0.0, 1.0);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('Hạn Mức & Định Danh'),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Quy định NHNN',
            icon: const Icon(CupertinoIcons.info_circle),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Hạn mức tuân thủ Thông tư 17/2024/TT-NHNN và Quyết định 2345/QĐ-NHNN.')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text(_error!, style: const TextStyle(color: AppColors.error)))
                :
        ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 32),
          children: [
            // Current Utilization Gauge Card
            _buildLimitUtilizationCard(usagePercent, remainingToday),
            const SizedBox(height: 20),

            // Custom Limit Adjustment Slider
            _buildCustomLimitSliderCard(),
            const SizedBox(height: 20),

            // Regulatory Mandate Box (QĐ 2345/QĐ-NHNN)
            _buildQd2345Notice(),
            const SizedBox(height: 24),

            // Transaction Types Breakdown Matrix
            Text('Chi Tiết Hạn Mức Từng Loại Giao Dịch', style: AppTypography.titleMedium(color: AppColors.primaryDark)),
            const SizedBox(height: 12),
            _buildLimitBreakdownCard(),
            const SizedBox(height: 24),

            // KYC Tiers
            Text('Các Cấp Độ Định Danh Khách Hàng', style: AppTypography.titleMedium(color: AppColors.primaryDark)),
            const SizedBox(height: 12),

            _buildTierCard(
              tier: 1,
              title: 'Cấp 1: Cơ Bản (Đăng ký SĐT)',
              limit: '5.000.000 đ / ngày',
              desc: 'Tài khoản đăng ký bằng SĐT, chưa hoàn tất chụp CCCD gắn chip.',
              isCurrent: false,
              isCompleted: true,
              features: [
                'Chuyển tiền nội bộ Sen Hồng (tối đa 5tr/ngày)',
                'Nạp tiền vào tài khoản tối đa 5.000.000 đ/ngày',
                'Chưa thể rút tiền về tài khoản ngân hàng khác',
              ],
            ),
            const SizedBox(height: 16),

            _buildTierCard(
              tier: 2,
              title: 'Cấp 2: Tiêu Chuẩn (Đã eKYC CCCD Chip)',
              limit: '100.000.000 đ / ngày',
              desc: 'Đã đối soát C06 thành công và xác thực sinh trắc học khuôn mặt theo QĐ 2345.',
              isCurrent: true,
              isCompleted: true,
              features: [
                'Chuyển liên ngân hàng Napas 24/7 tới 100.000.000 đ/ngày',
                'Thanh toán hóa đơn điện/nước/viễn thông tự động không giới hạn',
                'Mở sổ tiết kiệm online lãi suất ưu đãi cao nhất',
                'Phát hành thẻ ghi nợ phi vật lý & thẻ quốc tế',
              ],
            ),
            const SizedBox(height: 16),

            _buildTierCard(
              tier: 3,
              title: 'Cấp 3: Nâng Cao (Smart OTP & Ký Số PKI)',
              limit: '500.000.000 đ / ngày',
              desc: 'Tích hợp chữ ký số cá nhân bảo mật cao và xác thực tài khoản ngân hàng chính chủ.',
              isCurrent: false,
              isCompleted: false,
              features: [
                'Hạn mức giao dịch mở rộng lên đến 500.000.000 đ/ngày',
                'Hạn mức tổng giao dịch tháng 2.000.000.000 đ',
                'Cấp hạn mức thẻ tín dụng và vay tiêu dùng tức thì đến 100tr',
                'Ký hợp đồng dịch vụ tài chính hoàn toàn online',
              ],
              onUpgrade: () => context.push('/profile/digital-signature'),
            ),
            const SizedBox(height: 16),

            // VIP Premier Tier
            _buildPremierVipBanner(),
            const SizedBox(height: 24),

            // Secondary Actions
            OutlinedButton.icon(
              onPressed: () => context.push('/profile/ekyc'),
              icon: const Icon(CupertinoIcons.camera_viewfinder, color: AppColors.primary),
              label: const Text('Cập nhật lại eKYC CCCD & Khuôn mặt'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.borderLight),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLimitUtilizationCard(double usagePercent, double remainingToday) {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('HẠN MỨC GIAO DỊCH HÔM NAY', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(letterSpacing: 0.5)),
                    const SizedBox(height: 4),
                    Text(CurrencyFormatter.formatVND(_customDailyLimit), style: const TextStyle(color: AppColors.primaryDark, fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('CẤP 2 - CHUẨN', style: TextStyle(color: AppColors.emeraldGreen, fontWeight: FontWeight.bold, fontSize: 11)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: usagePercent,
                backgroundColor: AppColors.dividerLight,
                valueColor: AlwaysStoppedAnimation<Color>(
                  usagePercent > 0.8 ? AppColors.error : AppColors.bottomBarCyan,
                ),
                minHeight: 10,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Đã dùng: ${CurrencyFormatter.formatVND(_usedToday)}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight)),
                Text('Còn lại: ${CurrencyFormatter.formatVND(remainingToday)}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.emeraldGreen)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomLimitSliderCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(CupertinoIcons.slider_horizontal_3, color: AppColors.bottomBarCyan, size: 20),
                const SizedBox(width: 8),
                Text('Tự Điều Chỉnh Hạn Mức An Toàn', style: AppTypography.titleSmall(color: AppColors.primaryDark)),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Bạn có thể chủ động giảm hạn mức giao dịch trong ngày để phòng chống rủi ro gian lận.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 12),
            Slider(
              value: _customDailyLimit,
              min: 10000000,
              max: _maxDailyLimit,
              divisions: 9,
              activeColor: AppColors.bottomBarCyan,
              inactiveColor: AppColors.dividerLight,
              label: CurrencyFormatter.formatVND(_customDailyLimit),
              onChanged: (val) => setState(() => _customDailyLimit = val),
            ),
            Center(
              child: Text(
                'Hạn mức thiết lập: ${CurrencyFormatter.formatVND(_customDailyLimit)} / ngày',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQd2345Notice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.infoBorder),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(CupertinoIcons.shield_fill, color: AppColors.infoText, size: 18),
              SizedBox(width: 8),
              Text(
                'Quy Định Bắt Buộc Sinh Trắc Học (QĐ 2345/QĐ-NHNN)',
                style: TextStyle(color: AppColors.infoText, fontWeight: FontWeight.bold, fontSize: 12.5),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            '• Chuyển tiền trên 10.000.000 đ/giao dịch: Bắt buộc quét khuôn mặt Face Match.\n'
            '• Tổng chuyển tiền trong ngày vượt quá 20.000.000 đ: Các giao dịch kế tiếp đều phải xác thực khuôn mặt.\n'
            '• Tài khoản của bạn ĐÃ SẴN SÀNG xác thực sinh trắc học qua chip CCCD.',
            style: TextStyle(fontSize: 11.5, color: AppColors.infoText, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildLimitBreakdownCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            _buildBreakdownRow('Chuyển tiền Napas 24/7', '20.000.000 đ', '100.000.000 đ'),
            const Divider(height: 20, color: AppColors.cardBorderLight),
            _buildBreakdownRow('Chuyển nội bộ Sen Hồng', '50.000.000 đ', '100.000.000 đ'),
            const Divider(height: 20, color: AppColors.cardBorderLight),
            _buildBreakdownRow('Thanh toán hóa đơn & QR', '20.000.000 đ', '50.000.000 đ'),
            const Divider(height: 20, color: AppColors.cardBorderLight),
            _buildBreakdownRow('Nạp / Rút tài khoản liên kết', '50.000.000 đ', '100.000.000 đ'),
          ],
        ),
      ),
    );
  }

  Widget _buildBreakdownRow(String title, String perTx, String perDay) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimaryLight)),
              const SizedBox(height: 2),
              Text('Tối đa/giao dịch: $perTx', style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            const Text('Hạn mức ngày', style: TextStyle(fontSize: 10, color: AppColors.textSecondaryLight)),
            Text(perDay, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryDark)),
          ],
        ),
      ],
    );
  }

  Widget _buildTierCard({
    required int tier,
    required String title,
    required String limit,
    required String desc,
    required bool isCurrent,
    required bool isCompleted,
    required List<String> features,
    VoidCallback? onUpgrade,
  }) {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: isCurrent ? Border.all(color: AppColors.emeraldGreen, width: 2) : null,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    title,
                    style: AppTypography.titleMedium(color: isCurrent ? AppColors.emeraldGreen : AppColors.textPrimaryLight),
                  ),
                ),
                if (isCurrent)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.emeraldGreen.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text('Hiện tại', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(limit, style: AppTypography.displaySmall(color: isCurrent ? AppColors.primary : AppColors.textPrimaryLight)),
            const SizedBox(height: 4),
            Text(desc, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
            const Divider(height: 24, color: AppColors.cardBorderLight),
            ...features.map((f) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          isCompleted ? CupertinoIcons.checkmark_alt_circle_fill : CupertinoIcons.circle,
                          size: 15,
                          color: isCompleted ? AppColors.emeraldGreen : AppColors.textMutedLight,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(f, style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12.5))),
                    ],
                  ),
                )),
            if (onUpgrade != null) ...[
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onUpgrade,
                  child: const Text('Nâng cấp lên Cấp 3 ngay'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPremierVipBanner() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [AppColors.textPrimaryLight, AppColors.cardDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.textPrimaryLight.withOpacity(0.25),
            blurRadius: 14,
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
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accentGold),
                ),
                child: const Text('SEN PREMIER BANKING', style: TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
              const Icon(CupertinoIcons.star_circle_fill, color: AppColors.accentGold, size: 24),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Hạn Mức Khách Hàng Ưu Tiên: 2.000.000.000 đ / ngày',
            style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Đặc quyền Giám đốc quan hệ khách hàng riêng (Private Banker), miễn 100% phí giao dịch quốc tế và phòng chờ thương gia sân bay Lotus Lounge.',
            style: TextStyle(color: Colors.white70, fontSize: 11.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.accentGold),
              foregroundColor: AppColors.accentGold,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Yêu cầu tư vấn Sen Premier Banking đã được tiếp nhận. Hotline VIP 1800 6886.')),
              );
            },
            child: const Text('Liên hệ chuyên viên Premier', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

