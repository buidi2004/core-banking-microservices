import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends State<NotificationSettingsScreen> {
  bool _isLoading = true;

  // Channels
  bool _pushOttEnabled = true;
  bool _smsEnabled = false;
  bool _emailEnabled = true;

  // Sound & Haptics
  bool _tingTingSound = true;
  bool _vibrationEnabled = true;

  // Types
  bool _balanceChangeNotif = true;
  bool _billReminderNotif = true;
  bool _securityAlertNotif = true; // Luôn bật
  bool _promoRewardNotif = true;
  bool _savingsMaturityNotif = true;

  // Threshold (VNĐ)
  double _minAmountThreshold = 0; // 0 = tất cả giao dịch

  // DND Mode
  bool _dndNightEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushOttEnabled = prefs.getBool('notif_push_ott') ?? true;
      _smsEnabled = prefs.getBool('notif_sms') ?? false;
      _emailEnabled = prefs.getBool('notif_email') ?? true;
      _tingTingSound = prefs.getBool('notif_sound_tingting') ?? true;
      _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
      _balanceChangeNotif = prefs.getBool('notif_balance_change') ?? true;
      _billReminderNotif = prefs.getBool('notif_bill_reminder') ?? true;
      _securityAlertNotif = true;
      _promoRewardNotif = prefs.getBool('notif_promo_reward') ?? true;
      _savingsMaturityNotif = prefs.getBool('notif_savings_maturity') ?? true;
      _minAmountThreshold = prefs.getDouble('notif_min_threshold') ?? 0;
      _dndNightEnabled = prefs.getBool('notif_dnd_night') ?? true;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    HapticFeedback.mediumImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notif_push_ott', _pushOttEnabled);
    await prefs.setBool('notif_sms', _smsEnabled);
    await prefs.setBool('notif_email', _emailEnabled);
    await prefs.setBool('notif_sound_tingting', _tingTingSound);
    await prefs.setBool('notif_vibration', _vibrationEnabled);
    await prefs.setBool('notif_balance_change', _balanceChangeNotif);
    await prefs.setBool('notif_bill_reminder', _billReminderNotif);
    await prefs.setBool('notif_promo_reward', _promoRewardNotif);
    await prefs.setBool('notif_savings_maturity', _savingsMaturityNotif);
    await prefs.setDouble('notif_min_threshold', _minAmountThreshold);
    await prefs.setBool('notif_dnd_night', _dndNightEnabled);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(
                CupertinoIcons.checkmark_alt_circle_fill,
                color: AppColors.emeraldGreen,
                size: 22,
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Cấu hình thông báo đã được lưu thành công!',
                  style: TextStyle(color: Colors.white, fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.primaryDark,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: AppColors.bottomBarCyan.withValues(alpha: 0.3),
            ),
          ),
        ),
      );
    }
  }

  void _testTingTingSound() {
    HapticFeedback.heavyImpact();
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(
              CupertinoIcons.speaker_2_fill,
              color: AppColors.bottomBarCyan,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Ting Ting! Bạn vừa nhận được tiền từ SenBank',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        duration: const Duration(milliseconds: 1600),
        backgroundColor: const Color(0xFF0C2440),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(
            color: AppColors.bottomBarCyan.withValues(alpha: 0.3),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF030B17),
      body: Stack(
        children: [
          // Background ambient gradient
          Positioned(
            top: -120,
            right: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 100,
            left: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bottomBarCyan.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(context),
                Expanded(
                  child: _isLoading
                      ? const Center(
                          child: CupertinoActivityIndicator(
                            color: AppColors.bottomBarCyan,
                            radius: 16,
                          ),
                        )
                      : ListView(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                          children: [
                            _buildInfoBanner(),
                            const SizedBox(height: 20),
                            _buildSectionHeader('KÊNH NHẬN THÔNG BÁO'),
                            const SizedBox(height: 10),
                            _buildChannelsCard(),
                            const SizedBox(height: 24),
                            _buildSectionHeader('ÂM THANH & RUNG HIỆU ỨNG'),
                            const SizedBox(height: 10),
                            _buildSoundCard(),
                            const SizedBox(height: 24),
                            _buildSectionHeader('LOẠI NỘI DUNG NHẬN TIN'),
                            const SizedBox(height: 10),
                            _buildTypesCard(),
                            const SizedBox(height: 24),
                            _buildSectionHeader('NGƯỠNG GIAO DỊCH THÔNG BÁO'),
                            const SizedBox(height: 10),
                            _buildThresholdCard(),
                            const SizedBox(height: 24),
                            _buildSectionHeader('CHẾ ĐỘ YÊN LẶNG BAN ĐÊM'),
                            const SizedBox(height: 10),
                            _buildDndCard(),
                            const SizedBox(height: 36),
                            _buildSaveButton(),
                            const SizedBox(height: 40),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF030B17).withValues(alpha: 0.7),
        border: Border(
          bottom: BorderSide(
            color: Colors.white.withValues(alpha: 0.08),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              context.pop();
            },
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
              ),
              child: const Icon(
                CupertinoIcons.chevron_left,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cài đặt thông báo',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 20,
                  ),
                ),
                Text(
                  'Tùy chỉnh nhận tin OTT, SMS & Âm thanh',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.emeraldGreen.withValues(alpha: 0.4),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  CupertinoIcons.shield_fill,
                  color: AppColors.emeraldGreen,
                  size: 13,
                ),
                SizedBox(width: 5),
                Text(
                  '24/7',
                  style: TextStyle(
                    color: AppColors.emeraldGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            AppColors.primaryDark.withValues(alpha: 0.6),
            const Color(0xFF0F2B48).withValues(alpha: 0.8),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.bottomBarCyan.withValues(alpha: 0.25),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.bottomBarCyan.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              CupertinoIcons.bell_fill,
              color: AppColors.bottomBarCyan,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Thông báo OTT Siêu Tốc',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Nhận thông báo biến động số dư và mã giao dịch ngay tức thì qua internet hoàn toàn MIỄN PHÍ thay vì sử dụng SMS Banking.',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                    height: 1.35,
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        title,
        style: const TextStyle(
          color: AppColors.bottomBarCyan,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.1,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildChannelsCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSwitchTile(
              icon: CupertinoIcons.chat_bubble_2_fill,
              iconColor: AppColors.bottomBarCyan,
              title: 'Thông báo trong App (OTT Push)',
              subtitle: 'Miễn phí 100%, bảo mật cao, tốc độ dưới 1 giây',
              value: _pushOttEnabled,
              onChanged: (val) {
                setState(() => _pushOttEnabled = val);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: CupertinoIcons.phone_fill,
              iconColor: AppColors.accentGold,
              title: 'SMS Banking',
              subtitle: 'Phí dịch vụ viễn thông 11.000đ/tháng/số điện thoại',
              value: _smsEnabled,
              onChanged: (val) {
                setState(() => _smsEnabled = val);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: CupertinoIcons.mail_solid,
              iconColor: const Color(0xFF38BDF8),
              title: 'Báo cáo sao kê qua Email',
              subtitle: 'Gửi sao kê điện tử có chữ ký số vào ngày 01 hàng tháng',
              value: _emailEnabled,
              onChanged: (val) {
                setState(() => _emailEnabled = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoundCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.music_note,
                    color: AppColors.emeraldGreen,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Chuông "Ting Ting" độc quyền',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        'Âm báo nhận tiền vui tai đặc trưng SenBank',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.55),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoSwitch(
                  value: _tingTingSound,
                  activeTrackColor: AppColors.emeraldGreen,
                  onChanged: (val) {
                    setState(() => _tingTingSound = val);
                  },
                ),
              ],
            ),
            if (_tingTingSound) ...[
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _testTingTingSound,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.emeraldGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.emeraldGreen.withValues(alpha: 0.3),
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        CupertinoIcons.play_arrow_solid,
                        color: AppColors.emeraldGreen,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Nghe thử âm báo Ting Ting',
                        style: TextStyle(
                          color: AppColors.emeraldGreen,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
            _buildDivider(),
            _buildSwitchTile(
              icon: CupertinoIcons.waveform,
              iconColor: const Color(0xFFA855F7),
              title: 'Rung phản hồi xúc giác',
              subtitle: 'Haptic feedback khi có biến động số dư',
              value: _vibrationEnabled,
              onChanged: (val) {
                setState(() => _vibrationEnabled = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTypesCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSwitchTile(
              icon: CupertinoIcons.money_dollar_circle_fill,
              iconColor: AppColors.emeraldGreen,
              title: 'Biến động số dư tài khoản',
              subtitle: 'Tiền vào, chuyển khoản, thanh toán QR, nạp/rút tiền',
              value: _balanceChangeNotif,
              onChanged: (val) {
                setState(() => _balanceChangeNotif = val);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: CupertinoIcons.doc_text_fill,
              iconColor: AppColors.bottomBarCyan,
              title: 'Nhắc hẹn hóa đơn điện & nước',
              subtitle: 'Thông báo trước 3 ngày khi có hóa đơn sinh hoạt mới',
              value: _billReminderNotif,
              onChanged: (val) {
                setState(() => _billReminderNotif = val);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: CupertinoIcons.shield_lefthalf_fill,
              iconColor: Colors.redAccent,
              title: 'Cảnh báo bảo mật hệ thống',
              subtitle: 'Đăng nhập thiết bị lạ, đổi mật khẩu (Bắt buộc bật)',
              value: _securityAlertNotif,
              onChanged: null, // Không cho phép tắt
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: CupertinoIcons.tag_fill,
              iconColor: AppColors.accentGold,
              title: 'Ưu đãi & Điểm thưởng SenClub',
              subtitle: 'Voucher hoàn tiền 20%, quà sinh nhật thành viên',
              value: _promoRewardNotif,
              onChanged: (val) {
                setState(() => _promoRewardNotif = val);
              },
            ),
            _buildDivider(),
            _buildSwitchTile(
              icon: CupertinoIcons.archivebox_fill,
              iconColor: const Color(0xFFF472B6),
              title: 'Đáo hạn sổ tiết kiệm & Khoản vay',
              subtitle: 'Nhắc tái tục hoặc thanh toán kỳ hạn đến hạn',
              value: _savingsMaturityNotif,
              onChanged: (val) {
                setState(() => _savingsMaturityNotif = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThresholdCard() {
    String thresholdText;
    if (_minAmountThreshold == 0) {
      thresholdText = 'Tất cả giao dịch (từ 1 VNĐ)';
    } else {
      thresholdText =
          'Từ ${_minAmountThreshold.toInt().toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} VNĐ';
    }

    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    CupertinoIcons.slider_horizontal_3,
                    color: AppColors.bottomBarCyan,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ngưỡng số tiền thông báo',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        thresholdText,
                        style: const TextStyle(
                          color: AppColors.bottomBarCyan,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: AppColors.bottomBarCyan,
                inactiveTrackColor: Colors.white.withValues(alpha: 0.12),
                thumbColor: Colors.white,
                overlayColor: AppColors.bottomBarCyan.withValues(alpha: 0.2),
                trackHeight: 4,
              ),
              child: Slider(
                value: _minAmountThreshold,
                min: 0,
                max: 50000,
                divisions: 5,
                onChanged: (val) {
                  setState(() => _minAmountThreshold = val);
                },
              ),
            ),
            Text(
              'Các giao dịch nhỏ lẻ dưới ngưỡng đã chọn sẽ chỉ lưu vào lịch sử ví mà không gửi chuông làm phiền.',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.55),
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDndCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildSwitchTile(
              icon: CupertinoIcons.moon_fill,
              iconColor: const Color(0xFF818CF8),
              title: 'Chế độ Ban Đêm (22:00 - 07:00)',
              subtitle:
                  'Tắt chuông các tin khuyến mại, chỉ phát âm thanh khi có cảnh báo bảo mật.',
              value: _dndNightEnabled,
              onChanged: (val) {
                setState(() => _dndNightEnabled = val);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool>? onChanged,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.55),
                  height: 1.25,
                  fontSize: 11.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        CupertinoSwitch(
          value: value,
          activeTrackColor: AppColors.bottomBarCyan,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Divider(
        color: Colors.white.withValues(alpha: 0.08),
        height: 1,
      ),
    );
  }

  Widget _buildSaveButton() {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          elevation: 6,
        ),
        onPressed: _saveSettings,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              CupertinoIcons.checkmark_seal_fill,
              color: Colors.white,
              size: 20,
            ),
            SizedBox(width: 10),
            Text(
              'Lưu cấu hình thông báo',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
