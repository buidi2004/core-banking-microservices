import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';
import 'package:sen_hong_bank/data/datasources/remote/card_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/profile_remote_datasource.dart';
import 'package:sen_hong_bank/data/datasources/remote/wallet_remote_datasource.dart';
import 'package:sen_hong_bank/presentation/widgets/feature_unavailable.dart';

class CardsScreen extends StatefulWidget {
  const CardsScreen({super.key});

  @override
  State<CardsScreen> createState() => _CardsScreenState();
}

class _CardsScreenState extends State<CardsScreen> {
  final PageController _cardPageCtrl = PageController(viewportFraction: 0.88);
  int _currentCardIdx = 0;
  bool _isExpanded = false;

  bool _showDetails = false;
  String _cardHolderName = 'BUI VAN DI';

  Map<String, dynamic> get _activeCard =>
      (_cards.isNotEmpty && _currentCardIdx < _cards.length)
          ? _cards[_currentCardIdx]
          : (_cards.isNotEmpty ? _cards[0] : {});

  bool get _isLocked {
    final status = _activeCard['status'] as String? ?? 'ACTIVE';
    return status == 'FROZEN' || status == 'LOCKED';
  }

  bool get _onlinePayment => _activeCard['onlinePayment'] != false;
  bool get _intlPayment => _activeCard['intlPayment'] != false;
  bool get _atmWithdraw => _activeCard['atmWithdraw'] != false;

  final List<Map<String, dynamic>> _cards = [
    {
      'id': 'card-master-hybrid-01',
      'type': 'credit',
      'title': 'Master Hybrid',
      'tier': 'HYBRID',
      'number': '5102 8888 9999 4821',
      'maskedNumber': '**** 4821',
      'maskedNumberSubtitle': 'HYBRID | **** 4821',
      'holder': 'BUI VAN DI',
      'expiry': '12/29',
      'cvv': '889',
      'limit': 100000000.0,
      'available': 0.0,
      'miniAsset': 'assets/icons/card_master_hybrid.png',
      'status': 'ACTIVE',
      'onlinePayment': true,
      'intlPayment': true,
      'atmWithdraw': true,
    },
    {
      'id': 'card-vetc-green-02',
      'type': 'debit',
      'title': 'VETC Be',
      'tier': 'VETC',
      'number': '9704 6868 2200 1928',
      'maskedNumber': '**** 1928',
      'maskedNumberSubtitle': 'VETC | **** 1928',
      'holder': 'BUI VAN DI',
      'expiry': '08/30',
      'cvv': '321',
      'limit': 20000000.0,
      'available': 0.0,
      'miniAsset': 'assets/icons/card_vetc_green.png',
      'status': 'ACTIVE',
      'onlinePayment': true,
      'intlPayment': false,
      'atmWithdraw': true,
    },
    {
      'id': 'card-visa-platinum-03',
      'type': 'credit',
      'title': 'SenBank Visa Signature',
      'tier': 'SIGNATURE',
      'number': '4288 9900 8899 6688',
      'maskedNumber': '**** 6688',
      'maskedNumberSubtitle': 'VISA | **** 6688',
      'holder': 'BUI VAN DI',
      'expiry': '12/29',
      'cvv': '888',
      'limit': 150000000.0,
      'available': 112500000.0,
      'miniAsset': 'assets/icons/card_visa_signature.png',
      'status': 'ACTIVE',
      'onlinePayment': true,
      'intlPayment': true,
      'atmWithdraw': true,
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadCards();
  }

  @override
  void dispose() {
    _cardPageCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCards() async {
    try {
      final backendCards = await CardRemoteDataSource().getCards();
      if (backendCards.isNotEmpty && mounted) {
        setState(() {
          for (int i = 0; i < backendCards.length; i++) {
            final c = backendCards[i];
            if (i < _cards.length) {
              _cards[i]['id'] = c['id'] ?? _cards[i]['id'];
              _cards[i]['number'] = c['number'] ?? _cards[i]['number'];
              if (c['limit'] != null) {
                _cards[i]['limit'] = (c['limit'] as num).toDouble();
              }
              if (c['available'] != null) {
                _cards[i]['available'] = (c['available'] as num).toDouble();
              }
              if (c['status'] != null) {
                _cards[i]['status'] = c['status'];
              }
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ProfileRemoteDataSource().getMe();
      final name = profile['fullName'] as String?;
      if (name != null && name.isNotEmpty && mounted) {
        setState(() {
          _cardHolderName = name.toUpperCase();
          for (final card in _cards) {
            card['holder'] = _cardHolderName;
          }
        });
      }

      final wallet = await WalletRemoteDataSource().getMyWallet();
      if (mounted) {
        setState(() {
          if (_cards.isNotEmpty) {
            if (wallet.balance > 0) {
              _cards[0]['available'] = wallet.balance;
            }
          }
        });
      }
    } catch (_) {}
  }

  Future<void> _toggleOnlinePayment() async {
    HapticFeedback.selectionClick();
    final cardId = _activeCard['id']?.toString();
    final newVal = !_onlinePayment;
    if (cardId != null) {
      try {
        await CardRemoteDataSource()
            .updateSettings(cardId, onlinePayment: newVal);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _activeCard['onlinePayment'] = newVal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newVal
            ? 'Đã bật tính năng thanh toán Online'
            : 'Đã tạm tắt tính năng thanh toán Online'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleIntlPayment() async {
    HapticFeedback.selectionClick();
    final cardId = _activeCard['id']?.toString();
    final newVal = !_intlPayment;
    if (cardId != null) {
      try {
        await CardRemoteDataSource()
            .updateSettings(cardId, intlPayment: newVal);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _activeCard['intlPayment'] = newVal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newVal
            ? 'Đã bật tính năng thanh toán Quốc tế'
            : 'Đã tắt tính năng thanh toán Quốc tế'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _toggleAtmWithdraw() async {
    HapticFeedback.selectionClick();
    final cardId = _activeCard['id']?.toString();
    final newVal = !_atmWithdraw;
    if (cardId != null) {
      try {
        await CardRemoteDataSource()
            .updateSettings(cardId, atmWithdraw: newVal);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi cập nhật: $e')),
        );
        return;
      }
    }
    if (!mounted) return;
    setState(() {
      _activeCard['atmWithdraw'] = newVal;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(newVal
            ? 'Đã bật tính năng rút tiền ATM'
            : 'Đã khóa tính năng rút tiền ATM'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _confirmToggleLockCard(bool willLock) async {
    HapticFeedback.mediumImpact();
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(
              willLock
                  ? CupertinoIcons.lock_shield_fill
                  : CupertinoIcons.lock_open_fill,
              color: willLock ? AppColors.error : AppColors.primary,
              size: 24,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                willLock ? 'Khóa Thẻ Tạm Thời' : 'Mở Khóa Thẻ',
                style: const TextStyle(
                  color: Color(0xFF1E293B),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
          ],
        ),
        content: Text(
          willLock
              ? 'Sau khi tạm khóa, toàn bộ các giao dịch thanh toán trực tuyến, quẹt thẻ POS và rút tiền ATM sẽ bị từ chối ngay lập tức để bảo vệ tài khoản của bạn.'
              : 'Bạn có chắc chắn muốn mở khóa lại thẻ này? Thẻ sẽ sẵn sàng cho tất cả các giao dịch thanh toán và rút tiền.',
          style: const TextStyle(color: Color(0xFF64748B), fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                const Text('Hủy', style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: willLock ? AppColors.error : AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(willLock ? 'Xác nhận khóa' : 'Xác nhận mở'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      HapticFeedback.mediumImpact();
      final cardId = _activeCard['id']?.toString();
      final newStatus = willLock ? 'FROZEN' : 'ACTIVE';
      if (cardId != null) {
        try {
          await CardRemoteDataSource().updateStatus(cardId, newStatus);
        } catch (e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật trạng thái thẻ: $e')),
          );
          return;
        }
      }
      if (!mounted) return;
      setState(() {
        _activeCard['status'] = newStatus;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: willLock ? AppColors.error : AppColors.success,
          content: Text(willLock
              ? 'Đã tạm khóa thẻ an toàn thành công!'
              : 'Đã mở khóa thẻ thành công! Thẻ đã sẵn sàng giao dịch.'),
        ),
      );
    }
  }

  void _showPhysicalCardModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
            24, 20, 24, MediaQuery.of(ctx).viewInsets.bottom + 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Expanded(
                  child: Text(
                    'Đăng Ký Phát Hành Thẻ Vật Lý',
                    style: TextStyle(
                      color: Color(0xFF1E293B),
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                    onPressed: () => Navigator.pop(ctx),
                    icon: const Icon(CupertinoIcons.xmark,
                        color: Color(0xFF64748B))),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Thẻ vật lý công nghệ dập nổi cao cấp tích hợp chip vi mạch EMV contactless sẽ được chuyển phát nhanh miễn phí tới địa chỉ của bạn.',
              style: TextStyle(color: Color(0xFF64748B), fontSize: 13),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFAF8F5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Column(
                children: [
                  Row(
                    children: [
                      Icon(CupertinoIcons.location_fill,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Địa chỉ nhận thẻ: P. Hàng Bạc, Q. Hoàn Kiếm, Hà Nội (Địa chỉ thường trú CCCD)',
                          style: TextStyle(
                              color: Color(0xFF1E293B),
                              fontSize: 13,
                              fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(CupertinoIcons.clock_fill,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                            'Thời gian giao dự kiến: 3 - 5 ngày làm việc',
                            style: TextStyle(
                                color: Color(0xFF64748B), fontSize: 13)),
                      ),
                    ],
                  ),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(CupertinoIcons.gift_fill,
                          color: AppColors.primary, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text('Phí phát hành & Giao hàng: MIỄN PHÍ 100%',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                showFeatureUnavailable(
                  context,
                  feature: 'Phát hành thẻ vật lý',
                  reason:
                      'Dịch vụ phát hành thẻ vật lý dập nổi đang trong giai đoạn triển khai cùng đối tác phát hành thẻ.',
                );
              },
              child: const Text('Xác nhận đăng ký phát hành',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardInfoModal() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final displayNum = _showDetails
              ? _activeCard['number'] as String
              : _activeCard['maskedNumber'] as String;
          final displayExpiry =
              _showDetails ? _activeCard['expiry'] as String : '••/••';
          final displayCvv =
              _showDetails ? _activeCard['cvv'] as String : '•••';

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Thông tin chi tiết thẻ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: const Icon(CupertinoIcons.xmark,
                          color: Color(0xFF64748B)),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tên chủ thẻ',
                              style: TextStyle(
                                  color: Color(0xFF64748B), fontSize: 13)),
                          Text(
                            _activeCard['holder'] ?? _cardHolderName,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Số thẻ',
                              style: TextStyle(
                                  color: Color(0xFF64748B), fontSize: 13)),
                          Row(
                            children: [
                              Text(
                                displayNum,
                                style: const TextStyle(
                                  color: Color(0xFF0F172A),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  fontFeatures: [FontFeature.tabularFigures()],
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: () {
                                  Clipboard.setData(ClipboardData(
                                      text: _activeCard['number']));
                                  HapticFeedback.lightImpact();
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Đã sao chép số thẻ'),
                                      duration: Duration(seconds: 1),
                                    ),
                                  );
                                },
                                child: const Icon(CupertinoIcons.doc_on_doc,
                                    size: 16, color: AppColors.primary),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Ngày hết hạn',
                              style: TextStyle(
                                  color: Color(0xFF64748B), fontSize: 13)),
                          Text(
                            displayExpiry,
                            style: const TextStyle(
                              color: Color(0xFF0F172A),
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20, color: Color(0xFFE2E8F0)),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Mã bảo mật CVV/CVC',
                              style: TextStyle(
                                  color: Color(0xFF64748B), fontSize: 13)),
                          Text(
                            displayCvv,
                            style: const TextStyle(
                              color: Color(0xFFDC2626),
                              fontWeight: FontWeight.w800,
                              fontSize: 15,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Hiển thị đầy đủ thông tin bảo mật',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                    CupertinoSwitch(
                      value: _showDetails,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() => _showDetails = val);
                        setModalState(() {});
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInstallmentModal() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEE2E2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(CupertinoIcons.gift_fill,
                      color: Color(0xFFDC2626), size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Chuyển Đổi Trả Góp 0% Lãi Suất',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                      Text(
                        'Ưu đãi dành riêng cho thẻ Master Hybrid',
                        style:
                            TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: const Row(
                children: [
                  Icon(CupertinoIcons.sparkles,
                      color: Color(0xFFDC2626), size: 18),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Tặng voucher giảm 2,5 TRIỆU đồng phí chuyển đổi kỳ hạn 3, 6, 9 và 12 tháng.',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF991B1B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Hiện chưa có giao dịch hợp lệ để chuyển đổi trả góp'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Text('Xem danh sách giao dịch trả góp',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardPaymentModal() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Thanh Toán Thẻ & Nạp Tiền',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Thanh toán dư nợ sao kê hoặc nạp tiền vào tài khoản thẻ ${_activeCard['title']}',
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE0F2FE),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.money_dollar_circle_fill,
                    color: AppColors.primary),
              ),
              title: const Text('Thanh toán dư nợ thẻ tín dụng',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Dư nợ hiện tại: 0 VND',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/transfer');
              },
            ),
            const Divider(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(CupertinoIcons.arrow_down_circle_fill,
                    color: Color(0xFF16A34A)),
              ),
              title: const Text('Nạp tiền vào tài khoản thẻ',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: const Text('Chuyển tiền từ ví chính sang thẻ',
                  style: TextStyle(fontSize: 12, color: Color(0xFF64748B))),
              trailing: const Icon(CupertinoIcons.chevron_forward, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                context.push('/deposit');
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showGooglePayModal() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/icons/action_card_gpay.png',
                    width: 38,
                    height: 38,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Thêm vào Google Wallet',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text(
              'Thanh toán 1 chạm Contactless NFC nhanh chóng, bảo mật tuyệt đối tại hàng triệu điểm chấp nhận thẻ trên toàn cầu mà không cần mang theo thẻ vật lý.',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1E293B),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Đã gửi yêu cầu tích hợp thẻ vào Google Wallet thành công!'),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.creditcard, size: 18),
                  SizedBox(width: 8),
                  Text('Thêm vào G Pay ngay',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardTermsModal() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Điều Khoản & Biểu Phí Thẻ',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              '• Miễn phí phát hành thẻ phi vật lý trên ứng dụng.\n• Miễn phí thường niên trọn đời cho thẻ Master Hybrid khi kích hoạt trong năm 2026.\n• Lãi suất 0% tối đa 45 ngày cho các giao dịch chi tiêu thẻ tín dụng.\n• Biểu phí rút tiền ATM nội mạng & ngoại mạng: Miễn phí.',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF475569), height: 1.6),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Đã hiểu',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRewardProgramModal() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Image.asset('assets/icons/card_reward_3d.png',
                    width: 44, height: 38),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Chi Tiêu Nhận Thưởng',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFF59E0B)),
              ),
              child: const Text(
                'ĐẶC QUYỀN: MIỄN PHÍ THƯỜNG NIÊN TRỌN ĐỜI',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFFB45309),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Tích lũy SenPoint với mỗi 1.000 VNĐ chi tiêu thẻ Master Hybrid. Đổi quà voucher ăn uống, vé máy bay, hoàn tiền mặt trực tiếp vào ví.',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFB45309),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                context.push('/promotions');
              },
              child: const Text('Khám phá quà tặng ngay',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showStellarGalleryModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Bộ Sưu Tập Thẻ & Stellar',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1E293B),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Bộ sưu tập độc bản tích hợp công nghệ dập nổi và chip vi mạch cao cấp: Thẻ chòm sao Virgo, Thẻ Trái Tim Át Cơ và Thẻ Tài Lộc Á Đông.',
              style: TextStyle(
                  fontSize: 13, color: Color(0xFF475569), height: 1.5),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5B61F4),
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                _showPhysicalCardModal();
              },
              child: const Text('Đăng ký phát hành ngay',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF8F5),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER (SENBANK LOGO / MASCOT / AI / BELL / MENU)
              _buildTopHeader(),

              // 2. TITLE ROW: Thẻ (2) (i) + Danh sách thẻ
              _buildTitleRow(),

              const SizedBox(height: 8),

              // 3. CARD CAROUSEL (PAGEVIEW SLIDER)
              _buildCardCarousel(),

              // 4. 4 ACTION ICONS ROW (Trả góp 0%, Thông tin thẻ, Thanh toán thẻ, Google Pay)
              _buildFourActionIcons(),

              const SizedBox(height: 6),

              // 5. CENTERED CHEVRON DOWN BUTTON
              _buildCenteredChevronButton(),

              // 6. EXPANDABLE CARD MANAGEMENT SECTION
              if (_isExpanded) _buildExpandedManagementSection(),

              const SizedBox(height: 12),

              // 7. BOTTOM REWARD BANNER (Chi tiêu nhận thưởng)
              _buildBottomRewardBanner(),

              const SizedBox(height: 18),

              // 8. BỘ SƯU TẬP THẺ & STELLAR (BANNER TÍM LỚN - TỪ ẢNH 2)
              _buildStellarCollectionBanner(),

              const SizedBox(height: 22),

              // 9. ƯU ĐÃI THẺ (DU LỊCH THÁI LAN HOÀN 1.000 THB - TỪ ẢNH 2)
              _buildCardPromotionsSection(),

              const SizedBox(height: 22),

              // 10. THẺ NỔI BẬT (JCB ULTIMATE & VISA SIGNATURE - TỪ ẢNH 2)
              _buildFeaturedCardsSection(),

              // 11. BOTTOM SPACING FOR LIQUID GLASS TAB BAR
              const SizedBox(height: 120),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo SENBANK (SenBank Lotus + SENBANK text)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/icons/senbank_lotus_isolated.png',
                width: 32,
                height: 32,
              ),
              const SizedBox(width: 8),
              const Text(
                'SENBANK',
                style: TextStyle(
                  color: Color(0xFF002D62),
                  fontWeight: FontWeight.w900,
                  fontSize: 22,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          // Top right actions: Mascot, AI, Bell, Menu
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Mascot Avatar
              GestureDetector(
                onTap: () {
                  HapticFeedback.selectionClick();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('SenBank Assistant: Xin chào Quý khách!'),
                      duration: Duration(seconds: 1),
                    ),
                  );
                },
                child: Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                      width: 1,
                    ),
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/icons/card_mascot_bee.png',
                      width: 34,
                      height: 34,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // AI Search Icon
              GestureDetector(
                onTap: () => context.push('/ai-assistant'),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF64748B),
                      width: 1.2,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'AI',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Notification Bell
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  size: 26,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(width: 12),
              // Menu Icon
              GestureDetector(
                onTap: () => context.push('/search'),
                child: const Icon(
                  Icons.menu_rounded,
                  size: 26,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTitleRow() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Thẻ (${_cards.length})',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E1E),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _showCardTermsModal,
                child: const Icon(
                  CupertinoIcons.info_circle,
                  size: 18,
                  color: Color(0xFF8D7B68),
                ),
              ),
            ],
          ),
          OutlinedButton(
            onPressed: () => context.push('/bank-cards'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              side: const BorderSide(color: Color(0xFF78716C), width: 1.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              backgroundColor: Colors.transparent,
            ),
            child: const Text(
              'Danh sách thẻ',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF292524),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCardCarousel() {
    return SizedBox(
      height: 130,
      child: PageView.builder(
        controller: _cardPageCtrl,
        itemCount: _cards.length,
        onPageChanged: (idx) {
          HapticFeedback.selectionClick();
          setState(() => _currentCardIdx = idx);
        },
        itemBuilder: (context, idx) {
          final card = _cards[idx];
          return Container(
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFEDE8E0), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: Row(
                children: [
                  // Left Recessed Container with Mini Card Artwork
                  Container(
                    width: 140,
                    color: const Color(0xFFEDE8E0),
                    alignment: Alignment.center,
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 5,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          card['miniAsset'] as String,
                          width: 102,
                          height: 66,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  // Right Container: Title, Mask, Balance
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            card['title'] as String,
                            style: const TextStyle(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1E1E1E),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            card['maskedNumberSubtitle'] as String,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF78716C),
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            CurrencyFormatter.formatVND(
                                card['available'] as double),
                            style: const TextStyle(
                              fontSize: 18.5,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E1E1E),
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFourActionIcons() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Trả góp 0%
          _buildActionItem(
            imagePath: 'assets/icons/action_card_installment.png',
            topLabel: 'Trả góp',
            bottomLabel: '0%',
            badge: '2,5 TRIỆU',
            onTap: _showInstallmentModal,
          ),
          // 2. Thông tin thẻ
          _buildActionItem(
            imagePath: 'assets/icons/action_card_info.png',
            topLabel: 'Thông tin',
            bottomLabel: 'thẻ',
            onTap: _showCardInfoModal,
          ),
          // 3. Thanh toán thẻ
          _buildActionItem(
            imagePath: 'assets/icons/action_card_pay.png',
            topLabel: 'Thanh toán',
            bottomLabel: 'thẻ',
            onTap: _showCardPaymentModal,
          ),
          // 4. Google Pay
          _buildActionItem(
            imagePath: 'assets/icons/action_card_gpay.png',
            topLabel: 'Google',
            bottomLabel: 'Pay',
            onTap: _showGooglePayModal,
          ),
        ],
      ),
    );
  }

  Widget _buildActionItem({
    required String imagePath,
    required String topLabel,
    required String bottomLabel,
    String? badge,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.topCenter,
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Image.asset(
                      imagePath,
                      width: 34,
                      height: 34,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                if (badge != null)
                  Positioned(
                    top: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 2),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFFE11D48), Color(0xFFEF4444)],
                        ),
                        borderRadius: BorderRadius.circular(5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFE11D48).withOpacity(0.3),
                            blurRadius: 4,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(CupertinoIcons.gift_fill,
                              size: 9, color: Colors.white),
                          const SizedBox(width: 2.5),
                          Text(
                            badge,
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 0.1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              topLabel,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF292524),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
            Text(
              bottomLabel,
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF292524),
                height: 1.2,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCenteredChevronButton() {
    return Center(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _isExpanded = !_isExpanded);
        },
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFEDE8E0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            _isExpanded
                ? CupertinoIcons.chevron_up
                : CupertinoIcons.chevron_down,
            size: 16,
            color: const Color(0xFF57534E),
          ),
        ),
      ),
    );
  }

  Widget _buildExpandedManagementSection() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFEDE8E0), width: 1),
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
          const Text(
            'Quản lý dịch vụ thẻ & Bảo mật',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _buildQuickToggleChip(
                icon: LucideIcons.shoppingBag,
                label: 'Online',
                isActive: _onlinePayment,
                onTap: _toggleOnlinePayment,
              ),
              const SizedBox(width: 8),
              _buildQuickToggleChip(
                icon: LucideIcons.globe,
                label: 'Quốc tế',
                isActive: _intlPayment,
                onTap: _toggleIntlPayment,
              ),
              const SizedBox(width: 8),
              _buildQuickToggleChip(
                icon: LucideIcons.banknote,
                label: 'Rút ATM',
                isActive: _atmWithdraw,
                onTap: _toggleAtmWithdraw,
              ),
            ],
          ),
          const SizedBox(height: 14),
          _buildCardOption(
            icon: _isLocked ? LucideIcons.lock : LucideIcons.shieldAlert,
            gradient: _isLocked
                ? const [Color(0xFFEF4444), Color(0xFFDC2626)]
                : const [Color(0xFFF59E0B), Color(0xFFD97706)],
            title: _isLocked ? 'Mở khóa thẻ' : 'Khóa thẻ tạm thời khẩn cấp',
            subtitle: _isLocked
                ? 'Thẻ đang bị tạm khóa giao dịch'
                : 'Bảo vệ an toàn khi nghi ngờ lộ thông tin',
            trailing: CupertinoSwitch(
              value: _isLocked,
              activeColor: AppColors.error,
              onChanged: (val) => _confirmToggleLockCard(val),
            ),
          ),
          _buildCardOption(
            icon: LucideIcons.keyRound,
            gradient: const [Color(0xFF10B981), Color(0xFF059669)],
            title: 'Đổi mã PIN thẻ ATM',
            subtitle: 'Đổi mã PIN 6 số rút tiền tại cây ATM',
            trailing: const Icon(CupertinoIcons.chevron_forward,
                color: Color(0xFF94A3B8), size: 16),
            onTap: () => context.push('/auth/set-pin'),
          ),
          _buildCardOption(
            icon: LucideIcons.slidersHorizontal,
            gradient: const [Color(0xFF06B6D4), Color(0xFF0891B2)],
            title: 'Cài đặt hạn mức thanh toán',
            subtitle: 'Hạn mức chi tiêu trực tuyến mỗi ngày',
            trailing: const Icon(CupertinoIcons.chevron_forward,
                color: Color(0xFF94A3B8), size: 16),
            onTap: () => context.push('/profile/kyc-level'),
          ),
          _buildCardOption(
            icon: LucideIcons.creditCard,
            gradient: const [Color(0xFF6366F1), Color(0xFF4F46E5)],
            title: 'Phát hành thẻ vật lý dập nổi',
            subtitle: 'Chuyển phát nhanh thẻ dập nổi tận nhà miễn phí',
            trailing: const Icon(CupertinoIcons.chevron_forward,
                color: Color(0xFF94A3B8), size: 16),
            onTap: _showPhysicalCardModal,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickToggleChip({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isActive
                ? AppColors.primary.withOpacity(0.08)
                : const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isActive
                  ? AppColors.primary.withOpacity(0.4)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: isActive ? AppColors.primary : const Color(0xFF64748B),
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive ? AppColors.primary : const Color(0xFF475569),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardOption({
    required IconData icon,
    required List<Color> gradient,
    required String title,
    required String subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: gradient,
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _buildBottomRewardBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GestureDetector(
        onTap: _showRewardProgramModal,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDE8E0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
              Image.asset(
                'assets/icons/card_reward_3d.png',
                width: 58,
                height: 48,
                fit: BoxFit.contain,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Chi tiêu nhận thưởng',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E1E1E),
                      ),
                    ),
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                            color: const Color(0xFFF59E0B), width: 0.8),
                      ),
                      child: const Text(
                        '+ MIỄN PHÍ THƯỜNG NIÊN',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFB45309),
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                CupertinoIcons.chevron_forward,
                size: 16,
                color: Color(0xFF78716C),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 8. BỘ SƯU TẬP THẺ & STELLAR (THIẾT KẾ VECTOR NATIVE SẮC NÉT 100%)
  Widget _buildStellarCollectionBanner() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            colors: [Color(0xFF5146E8), Color(0xFF7047E8), Color(0xFF8A3FFC)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF6246D9).withOpacity(0.22),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              Positioned(
                right: 70,
                top: -52,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.08),
                  ),
                ),
              ),
              Column(
                children: [
                  // Top Section: Title & Cards
                  Padding(
                    padding: const EdgeInsets.fromLTRB(18, 18, 14, 16),
                    child: Row(
                      children: [
                        // Left: Texts & Explore Button
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Bộ sưu tập',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                  letterSpacing: -0.2,
                                ),
                              ),
                              const SizedBox(height: 2),
                              const Text(
                                'Thẻ & Stellar',
                                style: TextStyle(
                                  fontSize: 21,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 14),
                              GestureDetector(
                                onTap: _showStellarGalleryModal,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 14, vertical: 7),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.12),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Khám phá',
                                        style: TextStyle(
                                          fontSize: 12.5,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF1E1E1E),
                                        ),
                                      ),
                                      SizedBox(width: 4),
                                      Icon(
                                        CupertinoIcons.chevron_forward,
                                        size: 13,
                                        color: Color(0xFF1E1E1E),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Right: 3 Vertical Mini Art Cards
                        Row(
                          children: [
                            // Card 1: Virgo Goddess
                            _buildStellarMiniCard(
                              gradient: const [
                                Color(0xFF1E1B4B),
                                Color(0xFF0F172A)
                              ],
                              title: 'VIRGO',
                              subtitle: 'SENBANK',
                              accentColor: const Color(0xFFFBBF24),
                              icon: CupertinoIcons.sparkles,
                            ),
                            const SizedBox(width: 6),
                            // Card 2: Ace of Hearts
                            _buildStellarMiniCard(
                              gradient: const [
                                Color(0xFF3B0764),
                                Color(0xFF18181B)
                              ],
                              title: 'ACE',
                              subtitle: 'SENBANK',
                              accentColor: const Color(0xFFEF4444),
                              icon: CupertinoIcons.heart_fill,
                            ),
                            const SizedBox(width: 6),
                            // Card 3: Asian Lucky Gold
                            _buildStellarMiniCard(
                              gradient: const [
                                Color(0xFFD97706),
                                Color(0xFFB45309)
                              ],
                              title: 'LUCKY',
                              subtitle: 'SENBANK',
                              accentColor: Colors.white,
                              icon: CupertinoIcons.star_fill,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Bottom Bar: Đã sở hữu thẻ vật lý? Định danh ngay
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      border: Border(
                        top: BorderSide(color: Colors.white.withOpacity(0.18)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Đã sở hữu thẻ vật lý?',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                        GestureDetector(
                          onTap: _showPhysicalCardModal,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4.5),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.85),
                                  width: 1),
                            ),
                            child: const Text(
                              'Định danh ngay',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStellarMiniCard({
    required List<Color> gradient,
    required String title,
    required String subtitle,
    required Color accentColor,
    required IconData icon,
  }) {
    return Container(
      width: 50,
      height: 78,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradient,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: accentColor.withOpacity(0.42), width: 0.8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 7,
                fontWeight: FontWeight.w800,
                color: accentColor,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Icon(icon, size: 20, color: accentColor),
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 6,
                fontWeight: FontWeight.bold,
                color: Colors.white70,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 9. ƯU ĐÃI THẺ (DU LỊCH THÁI LAN HOÀN 1.000 THB - TỪ ẢNH 2)
  Widget _buildCardPromotionsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Ưu đãi thẻ',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF262626),
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/promotions'),
                child: const Text(
                  'Tất cả',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF57534E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 128,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Banner 1: Thái Lan
              GestureDetector(
                onTap: () => context.push('/promotions'),
                child: Container(
                  width: 320,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/banners/clean_thailand_banner.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Banner 2: Visa du lịch
              GestureDetector(
                onTap: () => context.push('/promotions'),
                child: Container(
                  width: 240,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.asset(
                      'assets/images/banners/vietnam_halong_bay.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 10. THẺ NỔI BẬT (JCB ULTIMATE & VISA SIGNATURE - TỪ ẢNH 2)
  Widget _buildFeaturedCardsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Thẻ nổi bật',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF262626),
                  letterSpacing: -0.3,
                ),
              ),
              GestureDetector(
                onTap: () => context.push('/bank-cards'),
                child: const Text(
                  'Tất cả',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF57534E),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 195,
          child: ListView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              // Thẻ 1: JCB Ultimate Cổng Torii
              _buildFeaturedCardItem(
                imagePath: 'assets/images/banners/clean_jcb_banner.png',
                title:
                    'Thẻ tín dụng cao cấp cho mọi\nchi tiêu gia đình JCB Ultimate',
                onTap: _showPhysicalCardModal,
              ),
              const SizedBox(width: 14),
              // Thẻ 2: Visa Signature Hoàn tiền
              _buildFeaturedCardItem(
                imagePath: 'assets/images/banners/clean_visa_banner.png',
                title: 'Thẻ tín dụng Visa Signature\nHoàn tiền mọi lĩnh vực',
                onTap: _showPhysicalCardModal,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturedCardItem({
    required String imagePath,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: SizedBox(
        width: 220,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 220,
              height: 128,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: Color(0xFF262626),
                height: 1.3,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
