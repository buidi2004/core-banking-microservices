import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:sen_hong_bank/core/constants/app_constants.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/smart_transfer_parser.dart';
import 'package:sen_hong_bank/data/datasources/remote/beneficiary_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/transfer_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/app_bar_seam_fade.dart';

/// Màn hình Siêu Chuyển Tiền SenBank
/// Bố cục và tính năng 100% chuẩn giao diện mẫu:
/// - 5 ô tính năng vuông bo góc: Số tài khoản, Số điện thoại, Số thẻ, Mẫu chuyển, Quốc tế
/// - Hộp Siêu trợ lý SenAI với Chụp ảnh, Tải ảnh, Dán thông minh
/// - 2 thẻ phân nhánh: Gần đây (+8 logo) & Ví điện tử đối tác (+3)
/// - Money Chat danh bạ giao dịch gần đây
class ChooseRecipientScreen extends StatefulWidget {
  final String? initialQuery;
  const ChooseRecipientScreen({super.key, this.initialQuery});

  @override
  State<ChooseRecipientScreen> createState() => _ChooseRecipientScreenState();
}

class _ChooseRecipientScreenState extends State<ChooseRecipientScreen> {
  late final TextEditingController _searchController;
  int _selectedServiceMode =
      0; // 0: Số TK, 1: SĐT, 2: Số thẻ, 3: Mẫu chuyển, 4: Quốc tế

  Timer? _debounceTimer;
  bool _isLookingUp = false;
  Map<String, dynamic>? _lookedUpRecipient;
  String? _lookupError;

  List<Map<String, String>> _beneficiaries = [];

  String _myPhoneNumber = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.initialQuery ?? '');
    _loadMyPhone();
    _loadBeneficiaries();
    _searchController.addListener(_onSearchChanged);
    if (widget.initialQuery != null && widget.initialQuery!.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onSearchChanged();
      });
    }
  }

  Future<void> _loadMyPhone() async {
    try {
      const storage = FlutterSecureStorage();
      final phone = await storage.read(key: AppConstants.keyPhoneNumber);
      if (phone != null && mounted) {
        setState(
            () => _myPhoneNumber = phone.replaceAll(RegExp(r'[\s\.\-]'), ''));
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadBeneficiaries() async {
    try {
      final items = await BeneficiaryRemoteDataSource().getAll();
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
                  'walletId': (item['walletId'] ?? '').toString(),
                })
            .toList();
      });
    } catch (_) {}
  }

  void _onSearchChanged() {
    final text = _searchController.text.trim();
    _debounceTimer?.cancel();
    if (text.isEmpty) {
      if (mounted) {
        setState(() {
          _isLookingUp = false;
          _lookedUpRecipient = null;
          _lookupError = null;
        });
      }
      return;
    }

    final clean = text.replaceAll(RegExp(r'[\s\.\-]'), '');
    if (clean.length >= 8) {
      _debounceTimer = Timer(const Duration(milliseconds: 350), () {
        _lookupRecipient(clean);
      });
    } else {
      if (_lookedUpRecipient != null || _lookupError != null) {
        setState(() {
          _lookedUpRecipient = null;
          _lookupError = null;
        });
      }
    }
  }

  Future<void> _lookupRecipient(String query) async {
    final clean = query.trim().replaceAll(RegExp(r'[\s\.\-]'), '');
    if (clean.isEmpty) return;

    final phoneClean = clean.startsWith('+84')
        ? '0${clean.substring(3)}'
        : (clean.startsWith('84') && clean.length == 11)
            ? '0${clean.substring(2)}'
            : clean;

    if (_myPhoneNumber.isNotEmpty && phoneClean == _myPhoneNumber) {
      setState(() {
        _isLookingUp = false;
        _lookedUpRecipient = null;
        _lookupError = 'Không thể chuyển tiền vào chính tài khoản của bạn';
      });
      return;
    }

    setState(() {
      _isLookingUp = true;
      _lookupError = null;
    });

    try {
      final info = await TransferRemoteDataSource().getRecipient(clean);
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _lookedUpRecipient = info;
        _lookupError = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _lookedUpRecipient = null;
        _lookupError = 'Không tìm thấy tài khoản SenBank với SĐT/STK này';
      });
    }
  }

  void _continueToAmount() async {
    final text = _searchController.text.trim();
    final clean = text.replaceAll(RegExp(r'[\s\.\-]'), '');
    if (clean.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('Vui lòng nhập SĐT, mã ví hoặc số tài khoản người nhận')),
      );
      return;
    }

    if (_lookedUpRecipient != null) {
      _navigateToAmount(
        recipient: _lookedUpRecipient!['fullName']?.toString() ?? text,
        phone: _lookedUpRecipient!['phoneNumber']?.toString() ?? text,
        walletId: _lookedUpRecipient!['walletId']?.toString() ?? '',
      );
      return;
    }

    setState(() => _isLookingUp = true);
    try {
      final info = await TransferRemoteDataSource().getRecipient(text);
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _lookedUpRecipient = info;
      });
      _navigateToAmount(
        recipient: info['fullName']?.toString() ?? text,
        phone: info['phoneNumber']?.toString() ?? text,
        walletId: info['walletId']?.toString() ?? '',
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLookingUp = false;
        _lookupError = 'Không tìm thấy tài khoản SenBank với SĐT/STK này';
      });
      _navigateToAmount(recipient: text);
    }
  }

  void _navigateToAmount(
      {required String recipient,
      String? phone,
      String? walletId,
      String? amount,
      String? note}) {
    final uri = Uri(
      path: '/transfer/amount',
      queryParameters: {
        'recipient': recipient,
        if (phone != null && phone.isNotEmpty) 'phoneNumber': phone,
        if (walletId != null && walletId.isNotEmpty) 'walletId': walletId,
        if (amount != null && amount.isNotEmpty) 'amount': amount,
        if (note != null && note.isNotEmpty) 'note': note,
      },
    );
    try {
      context.push(uri.toString());
    } catch (_) {
      Navigator.of(context).pushNamed(uri.toString());
    }
  }

  Future<void> _pasteFromClipboard() async {
    HapticFeedback.selectionClick();
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    final text = data?.text?.trim() ?? '';
    if (text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bộ nhớ tạm đang trống')),
      );
      return;
    }
    _searchController.text = text;
    final parsed = SmartTransferParser.parse(text);
    if (parsed.hasTransferInfo && parsed.accountNumber != null) {
      final cleanAccount = parsed.accountNumber!.replaceAll(RegExp(r'\s+'), '');
      _lookupRecipient(cleanAccount);
      if (parsed.amount != null && parsed.amount! > 0) {
        _navigateToAmount(
          recipient: parsed.recipientName ?? cleanAccount,
          phone: cleanAccount,
          amount: parsed.amount!.toInt().toString(),
          note: parsed.note,
        );
      }
    } else {
      _lookupRecipient(text);
    }
  }

  Future<void> _scanFromImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final XFile? file = await picker.pickImage(
        source: source,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 85,
      );
      if (file == null) return;

      setState(() => _isLookingUp = true);
      final controller = MobileScannerController();
      final BarcodeCapture? capture = await controller.analyzeImage(file.path);

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
          setState(() => _isLookingUp = false);
          if (parsed.accountNumber != null) {
            _searchController.text = parsed.accountNumber!;
            _lookupRecipient(parsed.accountNumber!);
            if (parsed.amount != null && parsed.amount! > 0) {
              _navigateToAmount(
                recipient: parsed.recipientName ?? parsed.accountNumber!,
                phone: parsed.accountNumber!,
                amount: parsed.amount!.toInt().toString(),
                note: parsed.note,
              );
            }
          } else {
            _searchController.text = rawValue;
            _lookupRecipient(rawValue);
          }
          return;
        }
      }
      setState(() => _isLookingUp = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Không tìm thấy mã QR trong ảnh được chọn')),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isLookingUp = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi quét ảnh: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        flexibleSpace: const AppBarSeamFade(),
        leading: IconButton(
          tooltip: 'Quay lại',
          icon: const Icon(CupertinoIcons.chevron_left,
              color: AppColors.brandNavy, size: 24),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go('/home');
            }
          },
        ),
        actions: [
          IconButton(
            tooltip: 'Thông báo',
            icon: const Icon(CupertinoIcons.bell,
                color: AppColors.brandNavy, size: 22),
            onPressed: () => context.push('/notifications'),
          ),
          IconButton(
            tooltip: 'Trang chủ',
            icon: const Icon(CupertinoIcons.house,
                color: AppColors.brandNavy, size: 22),
            onPressed: () => context.go('/home'),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            await _loadBeneficiaries();
            await _loadMyPhone();
          },
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
                parent: BouncingScrollPhysics()),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Tiêu đề lớn "Siêu chuyển tiền"
                const Text(
                  'Siêu chuyển tiền',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brandNavy,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 18),

                // 2. Cụm 5 icon tròn tính năng chuyển tiền
                _buildCircularServiceModesRow(),
                const SizedBox(height: 18),

                // 3. Khung Siêu trợ lý chuyển tiền SenAI
                _buildAiSmartTransferCard(),
                const SizedBox(height: 14),

                // Realtime Recipient Card nếu tìm thấy người nhận
                if (_isLookingUp) _buildLookingUpIndicator(),
                if (_lookedUpRecipient != null) _buildRecipientVerifiedCard(),
                if (_lookupError != null) _buildLookupErrorCard(),
                if (_lookedUpRecipient != null ||
                    _lookupError != null ||
                    _isLookingUp)
                  const SizedBox(height: 14),

                // 4. Hai thẻ phân nhánh: Gần đây & Ví điện tử đối tác
                _buildSplitShortcutsRow(),
                const SizedBox(height: 22),

                // 5. Mục Money Chat & danh bạ giao dịch gần đây
                _buildMoneyChatSection(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ===========================================================================
  // WIDGETS CON THEO CHUẨN GIAO DIỆN MẪU
  // ===========================================================================

  /// Cụm 5 ô vuông bo góc (rounded tile): Số tài khoản, Số điện thoại, Số thẻ, Mẫu chuyển, Quốc tế
  Widget _buildCircularServiceModesRow() {
    final modes = [
      {
        'title': 'Số\ntài khoản',
        'asset': 'assets/icons/mode_account.png',
        'index': 0,
      },
      {
        'title': 'Số\nđiện thoại',
        'asset': 'assets/icons/mode_phone.png',
        'index': 1,
      },
      {
        'title': 'Số thẻ',
        'asset': 'assets/icons/mode_card.png',
        'index': 2,
      },
      {
        'title': 'Mẫu\nchuyển',
        'asset': 'assets/icons/mode_template.png',
        'index': 3,
      },
      {
        'title': 'Thẻ &\nquốc tế',
        'asset': 'assets/icons/mode_international.png',
        'index': 4,
      },
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: modes.map((m) {
        final idx = m['index'] as int;
        final isSelected = _selectedServiceMode == idx;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: InkWell(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _selectedServiceMode = idx);
                if (idx == 3) {
                  context.push('/beneficiaries');
                } else if (idx == 4) {
                  context.push('/international-transfer');
                }
              },
              borderRadius: BorderRadius.circular(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      color: Colors.white,
                      border: Border.all(
                        color: isSelected
                            ? AppColors.brandBlue
                            : AppColors.brandBlue.withOpacity(0.12),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: isSelected
                              ? AppColors.brandBlue.withOpacity(0.20)
                              : Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(13),
                    child: Center(
                      child: Image.asset(
                        m['asset'] as String,
                        fit: BoxFit.contain,
                        color: isSelected
                            ? AppColors.brandBlue
                            : AppColors.brandNavy,
                      ),
                    ),
                  ),
                  const SizedBox(height: 7),
                  SizedBox(
                    height: 32,
                    child: Text(
                      m['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight:
                            isSelected ? FontWeight.w800 : FontWeight.w600,
                        color: isSelected
                            ? AppColors.primaryDark
                            : AppColors.brandNavy,
                        height: 1.25,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  /// Khung SenAI: Nhập thông tin chuyển tiền + Chụp ảnh / Tải ảnh / Dán
  Widget _buildAiSmartTransferCard() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00E5FF),
            Color(0xFF00E676),
            Color(0xFF2979FF),
            Color(0xFF0066CC),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandBlue.withOpacity(0.08),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(1.3),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16.7),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top row: SenAI badge + nút quét VietQR
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0066CC), Color(0xFF0284C7)],
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.sparkles,
                            color: Colors.white, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'SenAI',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(11),
                      color: const Color(0xFFF1EFEA),
                    ),
                    child: IconButton(
                      tooltip: 'Quét mã VietQR',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: const Icon(
                        CupertinoIcons.qrcode_viewfinder,
                        color: AppColors.brandNavy,
                        size: 20,
                      ),
                      onPressed: () => context.push('/scan-qr'),
                    ),
                  ),
                ],
              ),
            ),

            // Input field nhập, dán thông tin chuyển tiền
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: TextField(
                controller: _searchController,
                keyboardType: _selectedServiceMode == 0
                    ? TextInputType.number
                    : _selectedServiceMode == 1
                        ? TextInputType.phone
                        : TextInputType.text,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.brandNavy,
                ),
                decoration: InputDecoration(
                  hintText: _selectedServiceMode == 0
                      ? 'Nhập, dán thông tin chuyển tiền'
                      : _selectedServiceMode == 1
                          ? 'Nhập số điện thoại ví Sen Hồng'
                          : _selectedServiceMode == 2
                              ? 'Nhập số thẻ ngân hàng (16-19 số)'
                              : 'Nhập, dán thông tin chuyển tiền',
                  hintStyle: TextStyle(
                    color: AppColors.textMutedLight.withOpacity(0.9),
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onSubmitted: (_) => _continueToAmount(),
              ),
            ),

            const Divider(height: 1, color: Color(0xFFEEF2F6)),

            // 3 Nút tương tác AI: Chụp ảnh | Tải ảnh | Dán
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: () => _scanFromImage(ImageSource.camera),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: const [
                                Icon(CupertinoIcons.camera,
                                    size: 16, color: AppColors.brandNavy),
                                Positioned(
                                  top: -4,
                                  right: -5,
                                  child: Icon(CupertinoIcons.sparkles,
                                      size: 10, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                                child: Text(
                              'Chụp ảnh',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandNavy,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                      height: 16, width: 1, color: const Color(0xFFE2E8F0)),
                  Expanded(
                    child: InkWell(
                      onTap: () => _scanFromImage(ImageSource.gallery),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: const [
                                Icon(CupertinoIcons.photo,
                                    size: 16, color: AppColors.brandNavy),
                                Positioned(
                                  top: -4,
                                  right: -5,
                                  child: Icon(CupertinoIcons.sparkles,
                                      size: 10, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                                child: Text(
                              'Tải ảnh',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandNavy,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Container(
                      height: 16, width: 1, color: const Color(0xFFE2E8F0)),
                  Expanded(
                    child: InkWell(
                      onTap: _pasteFromClipboard,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              clipBehavior: Clip.none,
                              children: const [
                                Icon(CupertinoIcons.doc_on_clipboard,
                                    size: 16, color: AppColors.brandNavy),
                                Positioned(
                                  top: -4,
                                  right: -5,
                                  child: Icon(CupertinoIcons.sparkles,
                                      size: 10, color: Color(0xFF0284C7)),
                                ),
                              ],
                            ),
                            const SizedBox(width: 6),
                            const Flexible(
                                child: Text(
                              'Dán',
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandNavy,
                              ),
                              overflow: TextOverflow.ellipsis,
                            )),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Hai thẻ phân nhánh song song: Gần đây (+8 logo) & Ví điện tử đối tác (+3)
  Widget _buildSplitShortcutsRow() {
    return Row(
      children: [
        // Thẻ trái: Gần đây >
        Expanded(
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              context.push('/beneficiaries');
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.brandBlue.withOpacity(0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Text(
                        'Gần đây',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: AppColors.brandNavy,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(CupertinoIcons.chevron_forward,
                          size: 12, color: AppColors.brandNavy),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildBankMiniBadge('TCB'),
                      const SizedBox(width: 5),
                      _buildBankMiniBadge('AGRI'),
                      const SizedBox(width: 5),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1EFEA),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: const Center(
                          child: Text(
                            '+8',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandNavy,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        // Thẻ phải: Ví điện tử & đối tác >
        Expanded(
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Chuyển tiền liên ví điện tử & đối tác sẵn sàng 24/7')),
              );
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.brandBlue.withOpacity(0.12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Ví điện tử & đối tác',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.brandNavy,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(CupertinoIcons.chevron_forward,
                          size: 12, color: AppColors.brandNavy),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildBankMiniBadge('VTL'),
                      const SizedBox(width: 5),
                      _buildBankMiniBadge('ZALO'),
                      const SizedBox(width: 5),
                      _buildBankMiniBadge('MOMO'),
                      const SizedBox(width: 5),
                      Container(
                        width: 26,
                        height: 26,
                        decoration: const BoxDecoration(
                          color: Color(0xFFF1EFEA),
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                        ),
                        child: const Center(
                          child: Text(
                            '+3',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brandNavy,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Mục Money Chat với danh sách danh bạ người nhận
  Widget _buildMoneyChatSection() {
    final contacts = _beneficiaries
        .map((b) => {
              'name': (b['name'] ?? '').toUpperCase(),
              'account': b['account'] ?? b['phone'] ?? '',
              'subtitle':
                  '${b['account'] ?? b['phone']} | ${b['bank'] ?? 'Ví Sen Hồng'}',
              'date': '',
              'bank': b['bank'] ?? 'Sen Hồng',
            })
        .where((contact) =>
            (contact['name'] ?? '').isNotEmpty &&
            (contact['account'] ?? '').isNotEmpty)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Expanded(
                child: Text(
              'Money Chat',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.brandNavy,
              ),
              overflow: TextOverflow.ellipsis,
            )),
            Row(
              children: [
                IconButton(
                  tooltip: 'Tìm kiếm danh bạ',
                  icon: const Icon(CupertinoIcons.search,
                      size: 20, color: AppColors.brandNavy),
                  onPressed: () {
                    HapticFeedback.selectionClick();
                    context.push('/beneficiaries');
                  },
                ),
                InkWell(
                  onTap: () {
                    HapticFeedback.selectionClick();
                    context.push('/beneficiaries');
                  },
                  borderRadius: BorderRadius.circular(18),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                    decoration: BoxDecoration(
                      color: AppColors.brandNavy,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.plus,
                            size: 13, color: Colors.white),
                        SizedBox(width: 4),
                        Text(
                          'Chat mới',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        if (contacts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.76),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.brandBlue.withOpacity(0.08)),
            ),
            child: const Row(
              children: [
                Icon(CupertinoIcons.person_crop_circle,
                    size: 22, color: AppColors.textMutedLight),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Chưa có người nhận gần đây',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondaryLight,
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          ...contacts.take(8).map((contact) {
            final name = contact['name'] ?? '';
            final subtitle = contact['subtitle'] ?? '';
            final date = contact['date'] ?? '';
            final bank = contact['bank'] ?? 'Sen Hồng';
            final account = contact['account'] ?? '';

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(14),
                border:
                    Border.all(color: AppColors.brandBlue.withOpacity(0.08)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 6,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Material(
                type: MaterialType.transparency,
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    _searchController.text = account;
                    _lookupRecipient(account);
                    _navigateToAmount(
                      recipient: name,
                      phone: account,
                    );
                  },
                  leading: _buildContactAvatar(name, bank),
                  title: Text(
                    name,
                    style: const TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brandNavy,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  subtitle: Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: date.isNotEmpty
                      ? Text(
                          date,
                          style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textMutedLight,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : const Icon(
                          CupertinoIcons.chevron_forward,
                          size: 14,
                          color: AppColors.textMutedLight,
                        ),
                ),
              ),
            );
          }),
        const SizedBox(height: 120),
      ],
    );
  }

  /// Avatar người dùng hoặc logo ngân hàng chuẩn ảnh chân thật 100%
  Widget _buildContactAvatar(String name, String bank) {
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 5,
              offset: const Offset(0, 1.5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: Image.asset(
            logoAsset,
            width: 44,
            height: 44,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white,
        border: Border.all(
            color: AppColors.brandBlue.withOpacity(0.15), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: _buildBankMiniBadge(bank),
      ),
    );
  }

  /// Huy hiệu logo ngân hàng / ví điện tử chuẩn hình ảnh nhận diện thực tế
  Widget _buildBankMiniBadge(String bankCode) {
    String? assetPath;
    switch (bankCode.toUpperCase()) {
      case 'TCB':
      case 'TECHCOMBANK':
        assetPath = 'assets/icons/bank_tcb.png';
        break;
      case 'AGRI':
      case 'AGRIBANK':
        assetPath = 'assets/icons/bank_agri.png';
        break;
      case 'MB':
      case 'MBBANK':
        assetPath = 'assets/icons/bank_mb.png';
        break;
      case 'VCB':
      case 'VIETCOMBANK':
        assetPath = 'assets/icons/bank_vcb.png';
        break;
      case 'VTL':
      case 'VIETTEL':
      case 'VIETTELMONEY':
        assetPath = 'assets/icons/wallet_viettel.png';
        break;
      case 'ZALO':
      case 'ZALOPAY':
        assetPath = 'assets/icons/wallet_zalopay.png';
        break;
      case 'MOMO':
        assetPath = 'assets/icons/wallet_momo.png';
        break;
    }

    if (assetPath != null) {
      return Container(
        width: 26,
        height: 26,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.asset(
            assetPath,
            width: 26,
            height: 26,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: AppColors.brandNavy,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandNavy.withOpacity(0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Text(
          bankCode.length > 3 ? bankCode.substring(0, 3) : bankCode,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 7.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildLookingUpIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Row(
        children: [
          SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.primaryDark)),
          SizedBox(width: 10),
          Text(
            'SenAI đang tự động nhận diện tên chủ tài khoản...',
            style: TextStyle(
                fontSize: 12,
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildRecipientVerifiedCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.emeraldGreen.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppColors.emeraldGreen.withOpacity(0.3), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.emeraldGreen.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: AppColors.emeraldGreen.withOpacity(0.15),
            ),
            child: const Icon(CupertinoIcons.checkmark_seal_fill,
                color: AppColors.successTextLight, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (_lookedUpRecipient!['fullName'] ??
                          _lookedUpRecipient!['maskedName'] ??
                          '')
                      .toString()
                      .toUpperCase(),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: AppColors.successTextLight,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'SĐT/STK: ${_lookedUpRecipient!['phoneNumber'] ?? ''} • Ví Sen Hồng',
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textSecondaryLight),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: _continueToAmount,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Chuyển ngay',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Widget _buildLookupErrorCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          const Icon(CupertinoIcons.info_circle_fill,
              color: AppColors.errorText, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _lookupError!,
              style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.errorText,
                  fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
