import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';
import 'package:sen_hong_bank/data/datasources/remote/bill_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/api_response.dart';
import 'package:sen_hong_bank/presentation/widgets/app_alerts.dart';

class BillInputScreen extends StatefulWidget {
  final String? serviceType;
  const BillInputScreen({super.key, this.serviceType});

  @override
  State<BillInputScreen> createState() => _BillInputScreenState();
}

class _BillInputScreenState extends State<BillInputScreen> {
  final TextEditingController _customerCodeCtrl = TextEditingController();
  int _selectedProviderIdx = 0;
  bool _isLoading = false;

  final List<Map<String, String>> _providers = const [
    {'name': 'EVN Hà Nội', 'area': 'Miền Bắc', 'code': 'EVNHN'},
    {'name': 'EVN TP.HCM', 'area': 'Miền Nam', 'code': 'EVNHCM'},
    {'name': 'EVN Miền Trung', 'area': 'Miền Trung', 'code': 'EVNCPC'},
    {'name': 'Nước Chợ Lớn (Sawaco)', 'area': 'TP.HCM', 'code': 'WATER_CHOLON'},
    {'name': 'Nước Viwaco', 'area': 'Hà Nội', 'code': 'WATER_VIWACO'},
    {'name': 'VNPT Telecom', 'area': 'Toàn quốc', 'code': 'INTERNET_VNPT'},
    {'name': 'FPT Telecom', 'area': 'Toàn quốc', 'code': 'INTERNET_FPT'},
  ];

  final List<Map<String, String>> _savedCustomerCodes = [];

  Future<void> _handleLookup() async {
    final code = _customerCodeCtrl.text.trim();
    if (code.isEmpty) {
      AppAlerts.showWarning(
        context,
        'Vui lòng nhập mã khách hàng hoặc mã danh bộ',
        title: 'Thiếu mã khách hàng',
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final provider = _providers[_selectedProviderIdx]['name']!;
      final bill = await BillRemoteDataSource().lookup(
        type: widget.serviceType ?? 'ELECTRICITY',
        customerCode: code,
      );
      if (!mounted) return;
      context.push('/bills/confirm?service=${Uri.encodeComponent(widget.serviceType ?? "Hóa đơn")}&provider=${Uri.encodeComponent(provider)}&code=$code&billId=${bill['billId'] ?? bill['id']}&amount=${bill['amount'] ?? 0}');
    } catch (error) {
      if (mounted) {
        AppAlerts.showError(
          context,
          extractErrorMessage(error),
          title: 'Tra cứu không thành công',
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  IconData _getProviderIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('evn') || lower.contains('điện')) return CupertinoIcons.bolt_fill;
    if (lower.contains('nước') || lower.contains('sawaco') || lower.contains('viwaco')) return CupertinoIcons.drop_fill;
    if (lower.contains('telecom') || lower.contains('vnpt') || lower.contains('fpt')) return CupertinoIcons.wifi;
    return CupertinoIcons.building_2_fill;
  }

  @override
  Widget build(BuildContext context) {
    final service = widget.serviceType ?? 'Hóa đơn dịch vụ';

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text('Tra Cứu: $service'),
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
              Text('Chọn nhà cung cấp dịch vụ', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 10),

              // Provider Selector
              GlassCard(
                quality: GlassQuality.minimal,
                child: Column(
                  children: List.generate(_providers.length, (idx) {
                    final p = _providers[idx];
                    final isSelected = _selectedProviderIdx == idx;
                    final isLast = idx == _providers.length - 1;
                    return Column(
                      children: [
                        Material(
                          type: MaterialType.transparency,
                          child: ListTile(
                            onTap: () => setState(() => _selectedProviderIdx = idx),
                            leading: CircleAvatar(
                              backgroundColor: AppColors.primary.withOpacity(0.12),
                              child: Icon(_getProviderIcon(p['name']!), color: AppColors.primaryDark, size: 18),
                            ),
                            title: Text(p['name']!, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                            subtitle: Text(p['area']!, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                            trailing: isSelected
                                ? const Icon(CupertinoIcons.checkmark_circle_fill, color: AppColors.emeraldGreen)
                                : const Icon(CupertinoIcons.circle, color: AppColors.textMutedLight),
                          ),
                        ),
                        if (!isLast) const Divider(height: 1, indent: 56, color: AppColors.cardBorderLight),
                      ],
                    );
                  }),
                ),
              ),
              const SizedBox(height: 24),

              // Customer Code Input Card
              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mã khách hàng / Mã danh bộ', style: AppTypography.titleMedium(color: AppColors.textPrimaryLight)),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _customerCodeCtrl,
                        style: const TextStyle(color: AppColors.textPrimaryLight, fontSize: 16, fontWeight: FontWeight.bold),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          prefixIcon: const Icon(CupertinoIcons.barcode_viewfinder, color: AppColors.primary),
                          suffixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_customerCodeCtrl.text.isNotEmpty)
                                IconButton(
                                  icon: const Icon(CupertinoIcons.clear_circled_solid, color: AppColors.textMutedLight, size: 18),
                                  onPressed: () {
                                    HapticFeedback.selectionClick();
                                    setState(() => _customerCodeCtrl.clear());
                                  },
                                ),
                              IconButton(
                                icon: const Icon(CupertinoIcons.qrcode_viewfinder, color: AppColors.primaryDark),
                                tooltip: 'Quét mã trên giấy báo cước',
                                onPressed: () => context.push('/scan-qr'),
                              ),
                            ],
                          ),
                          hintText: 'Ví dụ: PE0100023456',
                          hintStyle: const TextStyle(color: AppColors.textMutedLight),
                          filled: true,
                          fillColor: AppColors.surfaceLight,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.borderLight)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(CupertinoIcons.lightbulb_fill, color: AppColors.accentGold, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Bấm icon mã QR bên phải để quét nhanh mã trên giấy báo cước hoặc tin nhắn SMS.',
                              style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLookup,
                          child: _isLoading
                              ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Tra cứu nợ cước kỳ này'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Auto-Debit Promo Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary, AppColors.bottomBarCyan],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.bottomBarGlow.withOpacity(0.25),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(CupertinoIcons.arrow_2_circlepath_circle_fill, color: Colors.white, size: 26),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TRÍCH NỢ TỰ ĐỘNG (AUTO-DEBIT)',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13, letterSpacing: 0.5),
                          ),
                          SizedBox(height: 3),
                          Text(
                            'Tự động trừ tiền khi có hóa đơn mới, không bao giờ lo cắt điện/nước.',
                            style: TextStyle(color: Colors.white70, fontSize: 11, height: 1.3),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Saved Customer Codes Chips
              if (_savedCustomerCodes.isNotEmpty) ...[
                Text('Mã khách hàng đã lưu', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
                const SizedBox(height: 10),
                ..._savedCustomerCodes.map((saved) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: GlassCard(
                      quality: GlassQuality.minimal,
                      child: Material(
                        type: MaterialType.transparency,
                        child: ListTile(
                          onTap: () {
                            setState(() {
                              _customerCodeCtrl.text = saved['code']!;
                              final pIdx = _providers.indexWhere((p) => p['name'] == saved['provider']);
                              if (pIdx != -1) _selectedProviderIdx = pIdx;
                            });
                          },
                          leading: CircleAvatar(
                            backgroundColor: AppColors.primary.withOpacity(0.12),
                            child: const Icon(CupertinoIcons.bookmark_fill, color: AppColors.primaryDark, size: 16),
                          ),
                          title: Text(saved['label']!, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold)),
                          subtitle: Text('${saved['provider']} • ${saved['code']}', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11)),
                          trailing: const Icon(CupertinoIcons.chevron_forward, color: AppColors.textMutedLight, size: 16),
                        ),
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 24),
              ],

              // Guide on where to find Customer Code
              Text('Hướng dẫn tìm mã khách hàng', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 10),

              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildGuideRow(
                        title: 'Tiền điện EVN:',
                        desc: 'Mã bắt đầu bằng chữ P (Ví dụ: PE01... hoặc PA02...), thường in đậm ở mục "Mã KH" trên hóa đơn tiền điện.',
                      ),
                      const Divider(height: 16, color: AppColors.cardBorderLight),
                      _buildGuideRow(
                        title: 'Tiền nước sinh hoạt:',
                        desc: 'Mã danh bộ gồm 9-11 chữ số (Ví dụ: 123456789), in tại góc trái phía trên giấy báo tiền nước.',
                      ),
                      const Divider(height: 16, color: AppColors.cardBorderLight),
                      _buildGuideRow(
                        title: 'Internet & Truyền hình:',
                        desc: 'Mã hợp đồng in trên tin nhắn thông báo cước hàng tháng của nhà mạng (VNPT, FPT, Viettel).',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // FAQ Section
              Text('Câu hỏi thường gặp (FAQ)', style: AppTypography.titleLarge(color: AppColors.textPrimaryLight)),
              const SizedBox(height: 10),

              GlassCard(
                quality: GlassQuality.minimal,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildFaqItem(
                        q: 'Khi nào tiền cước tháng mới được cập nhật?',
                        a: 'Dữ liệu tiền điện EVN cập nhật từ ngày 5 đến 10, nước sinh hoạt từ ngày 1 đến 5, cước viễn thông internet từ ngày 1 hàng tháng.',
                      ),
                      const Divider(height: 16, color: AppColors.cardBorderLight),
                      _buildFaqItem(
                        q: 'Có thể lấy hóa đơn VAT điện tử cho doanh nghiệp không?',
                        a: 'Có, tại bước xác nhận thanh toán, bạn chỉ cần chọn tab "Xuất hóa đơn VAT" và điền mã số thuế, tên công ty để nhận e-Invoice hợp lệ.',
                      ),
                      const Divider(height: 16, color: AppColors.cardBorderLight),
                      _buildFaqItem(
                        q: 'Thanh toán có bị mất phí xử lý dịch vụ không?',
                        a: 'Toàn bộ giao dịch thanh toán hóa đơn điện lực, nước, internet trên SenBank đều được miễn 100% phí xử lý.',
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Support Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(CupertinoIcons.question_circle, color: AppColors.primary, size: 16),
                  const SizedBox(width: 6),
                  Text('Cần hỗ trợ tra cước? ', style: AppTypography.bodySmall(color: AppColors.textSecondaryLight)),
                  InkWell(
                    onTap: () => context.push('/support/live-chat'),
                    child: const Text(
                      'Chat với CSKH 24/7',
                      style: TextStyle(color: AppColors.primaryDark, fontWeight: FontWeight.bold, fontSize: 12),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem({required String q, required String a}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(CupertinoIcons.chat_bubble_2_fill, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(q, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 3),
              Text(a, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11.5, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGuideRow({required String title, required String desc}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(CupertinoIcons.info_circle_fill, color: AppColors.primary, size: 18),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.titleSmall(color: AppColors.textPrimaryLight).copyWith(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 2),
              Text(desc, style: AppTypography.bodySmall(color: AppColors.textSecondaryLight).copyWith(fontSize: 11, height: 1.35)),
            ],
          ),
        ),
      ],
    );
  }
}
