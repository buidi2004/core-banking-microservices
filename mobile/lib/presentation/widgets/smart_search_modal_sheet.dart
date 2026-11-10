import 'dart:async';
import 'dart:ui' show FontFeature;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/core/utils/smart_transfer_parser.dart';
import 'package:sen_hong_bank/data/datasources/remote/beneficiary_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';

/// Hiển thị Modal Bottom Sheet Tìm kiếm 100% chuẩn giao diện mẫu
void showSmartSearchModalSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    useRootNavigator:
        true, // Đẩy lên Root Navigator để che phủ & ẩn hoàn toàn Bottom Bar mượt mà
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withOpacity(0.55),
    builder: (ctx) => const SmartSearchModalSheet(),
  );
}

class SmartSearchModalSheet extends StatefulWidget {
  final BeneficiaryRemoteDataSource? beneficiaryDataSource;
  final TransferRemoteDataSource? transferDataSource;

  const SmartSearchModalSheet({
    super.key,
    this.beneficiaryDataSource,
    this.transferDataSource,
  });

  @override
  State<SmartSearchModalSheet> createState() => _SmartSearchModalSheetState();
}

class _SmartSearchModalSheetState extends State<SmartSearchModalSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _query = '';
  bool _isAiProcessing = false;
  String _aiStatusMessage = 'SenAI đang xử lý...';

  // Tỷ lệ chiều cao của sheet: Mới vào 60% (0.60), gõ phím hoặc kéo lên 80% (0.80)
  double _sheetRatio = 0.60;

  // Danh bạ người thụ hưởng nạp theo yêu cầu (Lazy Loaded)
  List<Map<String, dynamic>> _beneficiaries = [];
  bool _hasLoadedBeneficiaries = false;

  // Tra cứu số tài khoản / SĐT thời gian thực
  Timer? _debounceLookup;
  bool _isLookingUpAccount = false;
  Map<String, dynamic>? _lookedUpAccount;

  final List<Map<String, dynamic>> _features = const [
    {
      'title': 'Rút tiền ATM',
      'sub': 'Rút tiền không cần thẻ tại cây ATM toàn quốc',
      'keywords': 'rut tien atm khong can the ngan hang ma qr',
      'icon': CupertinoIcons.money_dollar_circle_fill,
      'route': '/atm-withdrawal',
    },
    {
      'title': 'Mở tài khoản số đẹp',
      'sub': 'Tài khoản tứ quý, lộc phát, phong thủy, miễn phí 0đ',
      'keywords': 'mo tai khoan so dep tu quy loc phat stk vip',
      'icon': CupertinoIcons.sparkles,
      'route': '/lucky-account',
    },
    {
      'title': 'Chuyển tiền quốc tế',
      'sub': 'Chuyển tiền kiều hối, du học, công tác đa ngoại tệ',
      'keywords': 'chuyen tien quoc te swift kieu hoi du hoc usd jpy',
      'icon': CupertinoIcons.globe,
      'route': '/international-transfer',
    },
    {
      'title': 'Mua vé máy bay VNA',
      'sub': 'Vietnam Airlines, Vietjet Air, Bamboo Airways',
      'keywords': 'mua ve may bay vietnam airlines vna vietjet bamboo',
      'icon': CupertinoIcons.airplane,
      'route': '/flight-booking',
    },
    {
      'title': 'Bảo hiểm xã hội',
      'sub': 'Nộp BHXH, BHYT trực tuyến nhanh chóng',
      'keywords': 'bao hiem xa hoi bhxh bhyt bao hiem y te vssid',
      'icon': CupertinoIcons.shield_fill,
      'route': '/social-insurance',
    },
    {
      'title': 'Vua Xổ Số',
      'sub': 'Kết quả XSMB, XSMN, XSMT trực tiếp & dò số',
      'keywords': 'vua xo so ktxs xsmb xsmn xsmt do ve quay thu',
      'icon': CupertinoIcons.sparkles,
      'route': '/vua-xo-so',
    },
    {
      'title': 'Vé số Vietlott',
      'sub': 'Power 6/55, Mega 6/45, Keno chính hãng Vietlott SMS',
      'keywords': 've so vietlott mega 645 power 655 keno jackpot',
      'icon': CupertinoIcons.tickets_fill,
      'route': '/vietlott',
    },
    {
      'title': 'Data 4G / Nạp tiền',
      'sub': 'Gói Data ngày, tháng & Nạp tiền hoàn tiền 3.5%',
      'keywords': 'data 4g 5g nap tien dien thoai viettel vina mobi',
      'icon': CupertinoIcons.antenna_radiowaves_left_right,
      'route': '/data-topup',
    },
    {
      'title': 'Vé Máy Bay Số',
      'sub': 'Vé máy bay điện tử IATA, Check-in online',
      'keywords': 've may bay so dien tu boarding pass iata check in',
      'icon': CupertinoIcons.airplane,
      'route': '/digital-flight',
    },
    {
      'title': 'Vé máy bay iMedia',
      'sub': 'Đặt vé nội địa & quốc tế, bảo hiểm trễ chuyến',
      'keywords': 've may bay imedia travel quoc te noi dia',
      'icon': CupertinoIcons.paperplane_fill,
      'route': '/imedia-flight',
    },
    {
      'title': 'Data 4G / Thẻ Game',
      'sub': 'Garena, Zing, VTC chiết khấu tới 5%',
      'keywords':
          'the game nap game data garena lien quan free fire zing xu vtc',
      'icon': CupertinoIcons.gamecontroller_fill,
      'route': '/game-cards',
    },
    {
      'title': 'Vận Số & Phong Thủy',
      'sub': 'Ngày hoàng đạo, giờ tài lộc, số đẹp hợp mệnh',
      'keywords': 'van so phong thuy tu vi hoang dao tai loc que kinh dich',
      'icon': CupertinoIcons.sun_max_fill,
      'route': '/van-so',
    },
    {
      'title': 'Tất cả dịch vụ',
      'sub': 'Trung tâm tiện ích số Sen Hồng Bank',
      'keywords': 'tat ca dich vu tien ich mua sam giai tri',
      'icon': CupertinoIcons.square_grid_2x2_fill,
      'route': '/all-services',
    },
    {
      'title': 'Chuyển tiền Napas 24/7',
      'sub': 'Chuyển liên ngân hàng hoặc nội bộ tức thì',
      'keywords': 'chuyen tien napas 247 ibft ngan hang stk',
      'icon': CupertinoIcons.paperplane_fill,
      'route': '/transfer',
    },
    {
      'title': 'Nạp tiền điện thoại (Top-up)',
      'sub': 'Chiết khấu 3% Viettel, Vinaphone, Mobifone',
      'keywords': 'nap dien thoai topup the cao viettel vina mobi',
      'icon': CupertinoIcons.device_phone_portrait,
      'route': '/bills/phone-recharge',
    },
    {
      'title': 'Thanh toán tiền điện EVN',
      'sub': 'Tra cứu và nộp tiền điện toàn quốc',
      'keywords': 'tien dien evn hoa don dien luc',
      'icon': CupertinoIcons.bolt_fill,
      'route': '/bills/input?service=Tiền điện',
    },
    {
      'title': 'Thanh toán tiền nước sinh hoạt',
      'sub': 'Sawaco, Viwaco, Chợ Lớn, Nước ngầm',
      'keywords': 'tien nuoc hoa don sawaco viwaco',
      'icon': CupertinoIcons.drop_fill,
      'route': '/bills/input?service=Tiền nước',
    },
  ];

  final List<Map<String, String>> _suggestions = const [
    {'title': 'Rút tiền ATM', 'route': '/atm-withdrawal'},
    {'title': 'Mở tài khoản số đẹp', 'route': '/lucky-account'},
    {'title': 'Chuyển tiền quốc tế', 'route': '/international-transfer'},
    {'title': 'Mua vé máy bay VNA', 'route': '/flight-booking'},
    {'title': 'Bảo hiểm xã hội', 'route': '/social-insurance'},
  ];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChanged);
  }

  void _onFocusChanged() {
    // Khi người dùng bấm focus vào ô tìm kiếm -> tự động tăng lên 80% và giữ cố định
    if (_focusNode.hasFocus && _sheetRatio != 0.80) {
      setState(() {
        _sheetRatio = 0.80;
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChanged);
    _debounceLookup?.cancel();
    _focusNode.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  /// Nạp danh bạ người thụ hưởng theo cơ chế Lazy Load khi người dùng bắt đầu tìm kiếm
  Future<void> _ensureBeneficiariesLoaded() async {
    if (_hasLoadedBeneficiaries) return;
    _hasLoadedBeneficiaries = true;
    try {
      final ds = widget.beneficiaryDataSource ?? BeneficiaryRemoteDataSource();
      final items = await ds.getAll();
      if (!mounted) return;
      setState(() {
        _beneficiaries = items
            .map((item) => {
                  'name': (item['name'] ??
                          item['fullName'] ??
                          item['nickname'] ??
                          '')
                      .toString(),
                  'account':
                      (item['accountNumber'] ?? item['phoneNumber'] ?? '')
                          .toString(),
                  'bank': (item['bankCode'] ?? 'Ví Sen Hồng').toString(),
                  'phone': (item['phoneNumber'] ?? '').toString(),
                  'walletId':
                      (item['beneficiaryWalletId'] ?? item['walletId'] ?? '')
                          .toString(),
                })
            .where((b) =>
                (b['name'] as String).isNotEmpty ||
                (b['account'] as String).isNotEmpty)
            .toList();
      });
    } catch (_) {
      // Khi offline hoặc chạy trong widget test không có backend
    }
  }

  /// Xử lý khi thay đổi nội dung ô tìm kiếm: Tăng lên 80% và giữ cố định 80%
  void _onQueryChanged(String val) {
    setState(() {
      _query = val;
      _lookedUpAccount = null;
      // Khi người dùng gõ phím -> tăng lên 80% và giữ cố định 80%
      if (_sheetRatio != 0.80) {
        _sheetRatio = 0.80;
      }
    });

    _debounceLookup?.cancel();
    final trimmed = val.trim();
    if (trimmed.isEmpty) return;

    // Kích hoạt nạp danh bạ nếu chưa nạp
    _ensureBeneficiariesLoaded();

    final cleanDigits = trimmed.replaceAll(RegExp(r'[\s\.\-]'), '');
    final isPureDigits = RegExp(r'^\d+$').hasMatch(cleanDigits);

    // Chỉ khi là DÃY SỐ THUẦN TÚY (SĐT hoặc STK từ 8 số trở lên) mới kích hoạt tra cứu thời gian thực
    if (isPureDigits && cleanDigits.length >= 8) {
      _debounceLookup = Timer(const Duration(milliseconds: 300), () {
        _performAccountLookup(cleanDigits);
      });
    }
  }

  /// Tra cứu danh tính tài khoản từ backend theo thời gian thực
  Future<void> _performAccountLookup(String cleanDigits) async {
    if (!mounted) return;
    setState(() {
      _isLookingUpAccount = true;
    });

    try {
      final ds = widget.transferDataSource ?? TransferRemoteDataSource();
      final info = await ds.getRecipient(cleanDigits);
      if (!mounted) return;
      setState(() {
        _isLookingUpAccount = false;
        _lookedUpAccount = info;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isLookingUpAccount = false;
        _lookedUpAccount = null;
      });
    }
  }

  /// Điều hướng chuyển tiền tới tài khoản đích
  void _transferToAccount({
    required String recipientName,
    required String accountNumber,
    String? bankName,
    String? walletId,
  }) {
    HapticFeedback.selectionClick();
    Navigator.pop(context); // Đóng modal bottom sheet
    final uri = Uri(
      path: '/transfer/amount',
      queryParameters: {
        'recipient': recipientName,
        'phoneNumber': accountNumber,
        if (walletId != null && walletId.isNotEmpty) 'walletId': walletId,
      },
    );
    context.push(uri.toString());
  }

  /// Điều hướng sang màn chuyển tiền với STK nhập tay
  void _transferToUnknownAccount(String accountNumber) {
    HapticFeedback.selectionClick();
    Navigator.pop(context);
    context.push(
      '/transfer?recipient=$accountNumber&account=$accountNumber&query=$accountNumber',
    );
  }

  /// Lọc danh bạ người thụ hưởng theo từ khóa (tìm theo Tên, STK, SĐT hoặc Ngân hàng)
  List<Map<String, dynamic>> get _matchingBeneficiaries {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    final cleanDigits = q.replaceAll(RegExp(r'[\s\.\-]'), '');
    final isPureDigits = RegExp(r'^\d+$').hasMatch(cleanDigits);

    return _beneficiaries.where((b) {
      final name = (b['name'] ?? '').toString().toLowerCase();
      final acc = (b['account'] ?? '').toString().toLowerCase();
      final phone = (b['phone'] ?? '').toString().toLowerCase();
      final bank = (b['bank'] ?? '').toString().toLowerCase();

      if (isPureDigits && cleanDigits.length >= 4) {
        return acc.contains(cleanDigits) || phone.contains(cleanDigits);
      }
      return name.contains(q) || bank.contains(q);
    }).toList();
  }

  /// Xử lý bấm nút "Dán": Đọc bộ nhớ tạm và bóc tách thông minh qua SenAI
  Future<void> _handlePaste() async {
    HapticFeedback.lightImpact();
    try {
      final clipData = await Clipboard.getData(Clipboard.kTextPlain);
      final text = clipData?.text?.trim() ?? '';
      if (text.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bộ nhớ tạm rỗng'),
            behavior: SnackBarBehavior.floating,
            duration: Duration(seconds: 1),
          ),
        );
        return;
      }
      if (!mounted) return;

      _searchCtrl.text = text;
      _onQueryChanged(text);

      // Bóc tách giao dịch chuyển tiền bằng SenAI
      final parsed = SmartTransferParser.parse(text);
      if (parsed.hasTransferInfo) {
        await _handleParsedTransfer(parsed);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Không thể đọc nội dung đã sao chép'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  /// Chọn và xử lý ảnh từ Camera hoặc Thư viện ảnh (SenAI Image/QR Analysis)
  Future<void> _pickAndProcessImage(ImageSource source) async {
    HapticFeedback.lightImpact();
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return;
      if (!mounted) return;

      setState(() {
        _isAiProcessing = true;
        _aiStatusMessage = source == ImageSource.camera
            ? 'SenAI đang phân tích ảnh chụp...'
            : 'SenAI đang quét mã QR từ thư viện...';
      });

      final controller = MobileScannerController();
      BarcodeCapture? capture;
      try {
        capture = await controller.analyzeImage(file.path);
      } finally {
        await controller.dispose();
      }

      if (capture != null && capture.barcodes.isNotEmpty) {
        String? rawValue;
        for (final b in capture.barcodes) {
          if (b.rawValue != null && b.rawValue!.trim().isNotEmpty) {
            rawValue = b.rawValue!.trim();
            break;
          }
        }

        if (rawValue != null && rawValue.isNotEmpty) {
          final parsed = SmartTransferParser.parse(rawValue);
          if (mounted) {
            setState(() => _isAiProcessing = false);
          }
          await _handleParsedTransfer(parsed);
          return;
        }
      }

      if (!mounted) return;
      setState(() => _isAiProcessing = false);

      // Nếu không tìm thấy mã QR trong ảnh
      _showNoQrDialog(source);
    } catch (e) {
      if (mounted) {
        setState(() => _isAiProcessing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Lỗi xử lý ảnh: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  /// Thông báo khi ảnh không có mã QR
  void _showNoQrDialog(ImageSource source) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFFDF9),
        title: const Row(
          children: [
            Icon(CupertinoIcons.exclamationmark_circle,
                color: Color(0xFF8B6B43)),
            SizedBox(width: 8),
            Text(
              'Không tìm thấy mã QR',
              style: TextStyle(
                color: Color(0xFF3D2B1F),
                fontSize: 17,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: const Text(
          'SenAI không phát hiện được mã VietQR trong ảnh đã chọn. Vui lòng chọn ảnh rõ nét hơn hoặc mở máy quét camera trực tiếp.',
          style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Đóng', style: TextStyle(color: Color(0xFF8B6B43))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.pop(context);
              context.push('/scan-qr');
            },
            child: const Text('Mở máy quét trực tiếp'),
          ),
        ],
      ),
    );
  }

  /// Tra cứu danh tính và mở Sheet xác nhận chuyển tiền SenAI
  Future<void> _handleParsedTransfer(ParsedTransferData data) async {
    String? resolvedName = data.recipientName;

    if (data.accountNumber != null && data.accountNumber!.isNotEmpty) {
      try {
        final ds = widget.transferDataSource ?? TransferRemoteDataSource();
        final info = await ds.getRecipient(data.accountNumber!);
        final fullName = (info['fullName'] ?? info['maskedName'])?.toString();
        if (fullName != null && fullName.isNotEmpty) {
          resolvedName = fullName;
        }
      } catch (_) {}
    }

    final enrichedData = ParsedTransferData(
      accountNumber: data.accountNumber,
      bankName: data.bankName,
      bankBin: data.bankBin,
      recipientName: resolvedName,
      amount: data.amount,
      note: data.note,
      rawText: data.rawText,
      hasTransferInfo: true,
    );

    if (!mounted) return;
    _showAiTransferPreviewSheet(enrichedData);
  }

  /// Hiển thị BottomSheet xem trước thông tin chuyển tiền nhận diện bởi SenAI
  void _showAiTransferPreviewSheet(ParsedTransferData data) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetCtx) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFDF9),
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
                    color: const Color(0xFFD0C5B4),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2B44D6), Color(0xFF14B885)],
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(CupertinoIcons.sparkles,
                        color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SenAI phát hiện giao dịch',
                          style: TextStyle(
                            color: Color(0xFF3D2B1F),
                            fontSize: 16.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          'Tự động trích xuất thông tin chuyển khoản',
                          style: TextStyle(
                              color: Color(0xFF8B6B43), fontSize: 12.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),

              // Bảng tóm tắt thông tin giao dịch
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EFE6),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE8E2D8), width: 1),
                ),
                child: Column(
                  children: [
                    _buildPreviewRow(
                      'Người nhận',
                      data.recipientName ?? data.accountNumber ?? 'Người nhận',
                      isBold: true,
                    ),
                    if (data.accountNumber != null) ...[
                      const Divider(color: Color(0xFFE2D6C5), height: 16),
                      _buildPreviewRow('Số tài khoản/SĐT', data.accountNumber!),
                    ],
                    if (data.bankName != null) ...[
                      const Divider(color: Color(0xFFE2D6C5), height: 16),
                      _buildPreviewRow('Ngân hàng', data.bankName!),
                    ],
                    if (data.amount != null && data.amount! > 0) ...[
                      const Divider(color: Color(0xFFE2D6C5), height: 16),
                      _buildPreviewRow(
                        'Số tiền',
                        CurrencyFormatter.formatVND(data.amount!),
                        valueColor: const Color(0xFF14B885),
                        isBold: true,
                      ),
                    ],
                    if (data.note != null && data.note!.isNotEmpty) ...[
                      const Divider(color: Color(0xFFE2D6C5), height: 16),
                      _buildPreviewRow('Nội dung', data.note!),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 22),

              // Nút hành động
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        side: const BorderSide(color: Color(0xFF8B6B43)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () => Navigator.pop(sheetCtx),
                      child: const Text(
                        'Để sau',
                        style: TextStyle(
                          color: Color(0xFF3D2B1F),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF14B885),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.pop(sheetCtx);
                        Navigator.pop(context);
                        final uri = data.buildTransferUri();
                        context.push(uri.toString());
                      },
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(CupertinoIcons.paperplane_fill, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Chuyển tiền ngay',
                            style: TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPreviewRow(
    String label,
    String value, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF8B6B43), fontSize: 13),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? const Color(0xFF3D2B1F),
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  /// Lọc các dịch vụ theo từ khóa
  List<Map<String, dynamic>> get _searchResults {
    if (_query.trim().isEmpty) return const [];
    final terms = _query
        .toLowerCase()
        .trim()
        .split(RegExp(r'\s+'))
        .where((term) => term.isNotEmpty)
        .toList();
    final matches = _features.where((feature) {
      final searchable = [
        feature['title'],
        feature['sub'],
        feature['keywords'],
      ].join(' ').toLowerCase();
      return terms.every(searchable.contains);
    }).toList();
    matches.sort((a, b) {
      final aTitle = (a['title'] as String).toLowerCase();
      final bTitle = (b['title'] as String).toLowerCase();
      final aExact = aTitle == _query.trim().toLowerCase();
      final bExact = bTitle == _query.trim().toLowerCase();
      if (aExact != bExact) return aExact ? -1 : 1;
      final aStarts = aTitle.startsWith(terms.first);
      final bStarts = bTitle.startsWith(terms.first);
      if (aStarts != bStarts) return aStarts ? -1 : 1;
      return 0;
    });
    return matches;
  }

  /// Vùng thanh ngang tương tác kéo thả (Interactive Drag Handle Zone)
  /// Cho phép người dùng chạm và vuốt/kéo thả chuyển đổi giữa 60% và 80%
  Widget _buildInteractiveDragHandle(double screenHeight) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: (details) {
        // details.delta.dy > 0: ngón tay kéo xuống
        // details.delta.dy < 0: ngón tay kéo lên
        final deltaRatio = details.delta.dy / screenHeight;
        setState(() {
          _sheetRatio = (_sheetRatio - deltaRatio).clamp(0.48, 0.88);
        });
      },
      onVerticalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        double target;

        if (velocity < -250) {
          // Vuốt lên nhanh -> Snap lên 80%
          target = 0.80;
        } else if (velocity > 850 && _sheetRatio <= 0.62) {
          // Vuốt xuống rất mạnh từ vị trí 60% -> Đóng sheet
          Navigator.pop(context);
          return;
        } else if (velocity > 250) {
          // Vuốt xuống -> Snap về 60%
          target = 0.60;
        } else {
          // Dựa theo điểm ngưỡng: phân định 70% (0.70)
          target = _sheetRatio >= 0.70 ? 0.80 : 0.60;
        }

        if (target != _sheetRatio) {
          HapticFeedback.selectionClick();
        }
        setState(() {
          _sheetRatio = target;
        });
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        child: Container(
          width: 40,
          height: 4,
          decoration: BoxDecoration(
            color: const Color(0xFFD0C5B4),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    // Chiều cao được kiểm soát theo yêu cầu:
    // - Mới vào: 60% màn hình
    // - Khi gõ phím hoặc kéo thanh ngang lên: 80% màn hình và giữ cố định 80%
    // - Người dùng có thể kéo thả thanh ngang chuyển đổi giữa 60% và 80%
    final double targetHeight = screenHeight * _sheetRatio;

    return Material(
      color: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        height: targetHeight,
        padding: EdgeInsets.only(bottom: bottomInset),
        decoration: const BoxDecoration(
          color: Color(0xFFFFFDF9), // Trắng kem ấm chuẩn ảnh mẫu
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(30),
          ),
        ),
        child: Column(
          children: [
            // 1. Thanh kéo tương tác (Drag Handle) - Chạm kéo thả 60% hoặc 80%
            _buildInteractiveDragHandle(screenHeight),

            // 2. Ô tìm kiếm dạng Underline + Nút "Dán"
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      focusNode: _focusNode,
                      textInputAction: TextInputAction.search,
                      onChanged: _onQueryChanged,
                      onSubmitted: (val) {
                        // 1. Ưu tiên tài khoản tra cứu thành công
                        if (_lookedUpAccount != null) {
                          final name = _lookedUpAccount!['fullName']
                                  ?.toString() ??
                              val;
                          final phone = _lookedUpAccount!['phoneNumber']
                                  ?.toString() ??
                              val;
                          final walletId =
                              _lookedUpAccount!['walletId']?.toString();
                          _transferToAccount(
                            recipientName: name,
                            accountNumber: phone,
                            walletId: walletId,
                          );
                          return;
                        }

                        // 2. Ưu tiên danh bạ thụ hưởng khớp
                        if (_matchingBeneficiaries.isNotEmpty) {
                          final first = _matchingBeneficiaries.first;
                          _transferToAccount(
                            recipientName: first['name'] ?? val,
                            accountNumber: first['account'] ?? val,
                            bankName: first['bank'],
                            walletId: first['walletId'],
                          );
                          return;
                        }

                        // 3. Nếu là chuỗi số thuần túy từ 8 chữ số trở lên
                        final clean = val.replaceAll(RegExp(r'[\s\.\-]'), '');
                        if (RegExp(r'^\d{8,}$').hasMatch(clean)) {
                          _transferToUnknownAccount(clean);
                          return;
                        }

                        // 4. Ưu tiên dịch vụ khớp
                        final results = _searchResults;
                        if (results.isNotEmpty) {
                          Navigator.pop(context);
                          context.push(results.first['route'] as String);
                        }
                      },
                      style: const TextStyle(
                        color: Color(0xFF3D2B1F),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm',
                        hintStyle: const TextStyle(
                          color: Color(0xFF746E64),
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                        ),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        border: const UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFFE8E2D8), width: 1.2),
                        ),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFFE8E2D8), width: 1.2),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide:
                              BorderSide(color: Color(0xFF8B6B43), width: 1.5),
                        ),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                    CupertinoIcons.xmark_circle_fill,
                                    color: Color(0xFFA59E92),
                                    size: 18),
                                onPressed: () {
                                  _searchCtrl.clear();
                                  _onQueryChanged('');
                                },
                              )
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Nút "✨ Dán"
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handlePaste,
                      borderRadius: BorderRadius.circular(8),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minWidth: 44,
                          minHeight: 44,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                  colors: [
                                    Color(0xFF14B885),
                                    Color(0xFF06B6D4)
                                  ],
                                ).createShader(bounds),
                                child: const Icon(
                                  CupertinoIcons.sparkles,
                                  size: 14,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(width: 2),
                              const Icon(
                                CupertinoIcons.doc_on_clipboard,
                                size: 16,
                                color: Color(0xFF3D2B1F),
                              ),
                              const SizedBox(width: 4),
                              const Text(
                                'Dán',
                                style: TextStyle(
                                  color: Color(0xFF3D2B1F),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Hiển thị trạng thái xử lý AI nếu có
            if (_isAiProcessing)
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EFE6),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: const Color(0xFF14B885).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Color(0xFF14B885)),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _aiStatusMessage,
                        style: const TextStyle(
                          color: Color(0xFF3D2B1F),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // 3. Thân cuộn độc lập (Expanded)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                physics: const BouncingScrollPhysics(),
                child: _query.isNotEmpty
                    ? _buildSearchResultsList()
                    : _buildInitialSuggestionsBody(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Giao diện ban đầu khi mở app: Gọn gàng 100% chuẩn ảnh mẫu (Đã bỏ mục chuyển tiền gần đây)
  Widget _buildInitialSuggestionsBody() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Card trợ lý AI (SenAI Card) bọc RepaintBoundary chống giật lag repaint
        _buildAiCard(),
        const SizedBox(height: 22),

        // 2. Mục "Đề xuất"
        const Text(
          'Đề xuất',
          style: TextStyle(
            color: Color(0xFF3D2B1F),
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 14),

        // 3. Danh sách 5 Pill Stadium viền nâu mảnh chuẩn 100% ảnh mẫu 1
        ..._suggestions.map(
            (s) => _buildSuggestionPill(s['title']!, s['route']!)),
        const SizedBox(height: 24),
      ],
    );
  }

  /// Avatar người dùng hoặc logo ngân hàng
  Widget _buildBankOrContactAvatar({
    required String name,
    required String bank,
    double size = 44,
  }) {
    String? logoAsset;
    final b = bank.toUpperCase();
    if (b.contains('MB')) {
      logoAsset = 'assets/icons/bank_mb.png';
    } else if (b.contains('VCB') || b.contains('VIETCOM')) {
      logoAsset = 'assets/icons/bank_vcb.png';
    } else if (b.contains('TCB') || b.contains('TECHCOM')) {
      logoAsset = 'assets/icons/bank_tcb.png';
    } else if (b.contains('AGRI')) {
      logoAsset = 'assets/icons/bank_agri.png';
    }

    if (logoAsset != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(size * 0.32),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFE8E2D8), width: 0.8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(size * 0.32),
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Image.asset(
              logoAsset,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) =>
                  _buildFallbackInitialAvatar(name, size),
            ),
          ),
        ),
      );
    }

    return _buildFallbackInitialAvatar(name, size, isSenHong: b.contains('SEN'));
  }

  Widget _buildFallbackInitialAvatar(String name, double size,
      {bool isSenHong = false}) {
    final initials = _getInitials(name);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * 0.32),
        gradient: LinearGradient(
          colors: isSenHong
              ? [const Color(0xFF14B885), const Color(0xFF0F766E)]
              : [const Color(0xFF8B6B43), const Color(0xFF5A442A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 4,
            offset: const Offset(0, 1.5),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        initials,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.36,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  String _getInitials(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'SH';
    final parts =
        trimmed.split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts.last[0]}'.toUpperCase();
  }

  /// Card trợ lý AI viền Gradient mảnh chuyển màu
  Widget _buildAiCard() {
    return RepaintBoundary(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(1.2), // Độ dày viền gradient
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: const LinearGradient(
            colors: [
              Color(0xFF14B885), // Xanh lục
              Color(0xFF2B44D6), // Xanh hoàng gia
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Badge SenAI góc trên bên trái
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF2B44D6), Color(0xFF14B885)],
                  ),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(CupertinoIcons.sparkles, size: 11, color: Colors.white),
                    SizedBox(width: 4),
                    Text(
                      'SenAI',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Dòng text mô tả 2 dòng
              const Text(
                'Điền nhanh thông tin chuyển tiền từ văn bản hoặc ảnh mã VietQR',
                style: TextStyle(
                  color: Color(0xFF2D231A),
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 14),

              // 2 Nút bấm "Chụp ảnh" & "Tải ảnh"
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  _buildAiActionButton(
                    icon: CupertinoIcons.camera,
                    label: 'Chụp ảnh',
                    onTap: () => _pickAndProcessImage(ImageSource.camera),
                  ),
                  _buildAiActionButton(
                    icon: CupertinoIcons.photo,
                    label: 'Tải ảnh',
                    onTap: () => _pickAndProcessImage(ImageSource.gallery),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Nút bấm nền be nhạt bên trong Card AI
  Widget _buildAiActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF6EFE6), // Nền be nhạt chuẩn ảnh mẫu
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Icon(icon, size: 16, color: const Color(0xFF3D2B1F)),
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        width: 4,
                        height: 4,
                        decoration: const BoxDecoration(
                          color: Color(0xFF14B885),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    color: Color(0xFF3D2B1F),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pill đề xuất hình Oval/Stadium viền nâu mảnh
  Widget _buildSuggestionPill(String title, String route) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            HapticFeedback.selectionClick();
            Navigator.pop(context);
            context.push(route);
          },
          borderRadius: BorderRadius.circular(24),
          child: Container(
            constraints: const BoxConstraints(minHeight: 44),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: const Color(0xFF8B6B43), // Viền nâu đồng mảnh
                width: 1.2,
              ),
            ),
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF3D2B1F),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Danh sách kết quả tìm kiếm: chỉ gợi ý tài khoản / danh bạ / SĐT khi người dùng bắt đầu tìm kiếm
  Widget _buildSearchResultsList() {
    final cleanDigits = _query.replaceAll(RegExp(r'[\s\.\-]'), '');
    final isPureDigits = RegExp(r'^\d+$').hasMatch(cleanDigits);
    final isPotentialAccount = isPureDigits && cleanDigits.length >= 8;

    final matchingBeneficiaries = _matchingBeneficiaries;
    final results = _searchResults;

    final hasAnyResult = _lookedUpAccount != null ||
        _isLookingUpAccount ||
        matchingBeneficiaries.isNotEmpty ||
        results.isNotEmpty ||
        isPotentialAccount;

    if (!hasAnyResult) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 22, 0, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(CupertinoIcons.search,
                size: 28, color: Color(0xFFA59E92)),
            const SizedBox(height: 10),
            Text(
              'Chưa tìm thấy “$_query”',
              style: const TextStyle(
                color: Color(0xFF3D2B1F),
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.start,
            ),
            const SizedBox(height: 5),
            const Text(
              'Thử từ khóa khác hoặc chọn dịch vụ phổ biến:',
              style: TextStyle(color: Color(0xFF6F6A62), fontSize: 13),
            ),
            const SizedBox(height: 14),
            ..._suggestions.take(3).map(
                  (suggestion) => _buildSuggestionPill(
                    suggestion['title']!,
                    suggestion['route']!,
                  ),
                ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Khung đang tra cứu tài khoản thời gian thực
        if (_isLookingUpAccount)
          Container(
            margin: const EdgeInsets.only(top: 4, bottom: 12),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFF6EFE6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFE8E2D8)),
            ),
            child: Row(
              children: [
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF14B885),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Đang tra cứu số tài khoản "$cleanDigits"...',
                    style: const TextStyle(
                      color: Color(0xFF3D2B1F),
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),

        // 2. Thẻ tài khoản tìm thấy từ Backend (Realtime Lookup)
        if (_lookedUpAccount != null) ...[
          _buildLookedUpAccountCard(_lookedUpAccount!, cleanDigits),
          const SizedBox(height: 14),
        ],

        // 3. Danh sách người thụ hưởng trong danh bạ khớp từ khóa (Tên hoặc SĐT)
        if (matchingBeneficiaries.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Row(
              children: [
                const Icon(CupertinoIcons.person_badge_plus_fill,
                    size: 14, color: Color(0xFF14B885)),
                const SizedBox(width: 6),
                Text(
                  'Tài khoản thụ hưởng (${matchingBeneficiaries.length})',
                  style: const TextStyle(
                    color: Color(0xFF8B6B43),
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: matchingBeneficiaries.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Color(0xFFE8E2D8), height: 1),
            itemBuilder: (context, index) {
              final b = matchingBeneficiaries[index];
              final name = (b['name'] ?? 'Người nhận').toString();
              final acc = (b['account'] ?? b['phone'] ?? '').toString();
              final bank = (b['bank'] ?? 'Ví Sen Hồng').toString();
              final walletId = b['walletId']?.toString();

              return Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading:
                      _buildBankOrContactAvatar(name: name, bank: bank, size: 40),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF3D2B1F),
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '$acc • $bank',
                    style: const TextStyle(
                      color: Color(0xFF8B6B43),
                      fontSize: 12,
                      fontFeatures: [FontFeature.tabularFigures()],
                    ),
                  ),
                  trailing: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF14B885),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 6),
                      minimumSize: const Size(0, 34),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      _transferToAccount(
                        recipientName: name,
                        accountNumber: acc,
                        bankName: bank,
                        walletId: walletId,
                      );
                    },
                    child: const Text(
                      'Chuyển',
                      style:
                          TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 14),
        ],

        // 4. Nếu nhập dãy số thuần túy (>= 8 số) nhưng chưa có trong danh bạ -> Gợi ý chuyển tiền liên ngân hàng Napas 24/7
        if (isPotentialAccount &&
            _lookedUpAccount == null &&
            !_isLookingUpAccount &&
            matchingBeneficiaries.isEmpty) ...[
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _transferToUnknownAccount(cleanDigits),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF6EFE6),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                      color: const Color(0xFF14B885).withOpacity(0.5)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF14B885).withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(CupertinoIcons.paperplane_fill,
                          color: Color(0xFF14B885), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Chuyển tiền tới STK: $cleanDigits',
                            style: const TextStyle(
                              color: Color(0xFF3D2B1F),
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Chuyển khoản liên ngân hàng 24/7 qua Napas',
                            style: TextStyle(
                              color: Color(0xFF6F6A62),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(CupertinoIcons.chevron_right,
                        size: 14, color: Color(0xFF8B6B43)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
        ],

        // 5. Kết quả tìm kiếm Dịch vụ & Tính năng
        if (results.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.only(top: 4, bottom: 8),
            child: Text(
              '${results.length} dịch vụ phù hợp',
              style: const TextStyle(
                color: Color(0xFF8B6B43),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: results.length,
            separatorBuilder: (_, __) =>
                const Divider(color: Color(0xFFE8E2D8), height: 1),
            itemBuilder: (context, index) {
              final item = results[index];
              return Material(
                color: Colors.transparent,
                child: ListTile(
                  minTileHeight: 60,
                  contentPadding: const EdgeInsets.symmetric(vertical: 4),
                  leading: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6EFE6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item['icon'] as IconData,
                        color: const Color(0xFF3D2B1F), size: 18),
                  ),
                  title: Text(
                    item['title'] as String,
                    style: const TextStyle(
                      color: Color(0xFF3D2B1F),
                      fontWeight: FontWeight.w600,
                      fontSize: 14.5,
                    ),
                  ),
                  subtitle: Text(
                    item['sub'] as String,
                    style:
                        const TextStyle(color: Color(0xFF6F6A62), fontSize: 12),
                  ),
                  trailing: const Icon(CupertinoIcons.chevron_right,
                      size: 14, color: Color(0xFFA59E92)),
                  onTap: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                    context.push(item['route'] as String);
                  },
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  /// Thẻ tài khoản đã xác thực tra cứu từ backend
  Widget _buildLookedUpAccountCard(
      Map<String, dynamic> info, String cleanDigits) {
    final fullName =
        (info['fullName'] ?? info['maskedName'] ?? 'NGƯỜI DÙNG SEN HỒNG')
            .toString()
            .toUpperCase();
    final phone = (info['phoneNumber'] ?? cleanDigits).toString();
    final bankName = (info['bankName'] ?? 'Ví Sen Hồng').toString();
    final walletId = info['walletId']?.toString();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF6EFE6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF14B885), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  color: Color(0xFF14B885),
                  shape: BoxShape.circle,
                ),
                child: const Icon(CupertinoIcons.checkmark_alt,
                    size: 12, color: Colors.white),
              ),
              const SizedBox(width: 8),
              const Text(
                'Tài khoản tìm thấy (Đã xác thực)',
                style: TextStyle(
                  color: Color(0xFF14B885),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _buildBankOrContactAvatar(name: fullName, bank: bankName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fullName,
                      style: const TextStyle(
                        color: Color(0xFF3D2B1F),
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'STK: $phone • $bankName',
                      style: const TextStyle(
                        color: Color(0xFF8B6B43),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF14B885),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                _transferToAccount(
                  recipientName: fullName,
                  accountNumber: phone,
                  bankName: bankName,
                  walletId: walletId,
                );
              },
              icon: const Icon(CupertinoIcons.paperplane_fill, size: 14),
              label: const Text(
                'Chuyển tiền ngay tới tài khoản này',
                style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
