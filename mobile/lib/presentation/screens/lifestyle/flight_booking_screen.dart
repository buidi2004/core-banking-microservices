import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:sen_hong_bank/core/utils/currency_formatter.dart';

/// Màn hình Đặt mua vé máy bay Vietnam Airlines & Đối tác (Vietjet, Bamboo)
class FlightBookingScreen extends StatefulWidget {
  const FlightBookingScreen({super.key});

  @override
  State<FlightBookingScreen> createState() => _FlightBookingScreenState();
}

class _FlightBookingScreenState extends State<FlightBookingScreen> {
  String _fromAirportCode = 'SGN';
  String _fromCity = 'TP. Hồ Chí Minh';
  String _toAirportCode = 'HAN';
  String _toCity = 'Hà Nội';

  DateTime _departureDate = DateTime.now().add(const Duration(days: 3));
  int _passengers = 1;
  int _selectedAirlineFilter = 0; // 0: Tất cả, 1: Vietnam Airlines, 2: Vietjet, 3: Bamboo

  final List<Map<String, dynamic>> _flights = const [
    {
      'airline': 'Vietnam Airlines',
      'logo': '🇻🇳',
      'flightNo': 'VN-242',
      'departTime': '06:00',
      'arriveTime': '08:15',
      'duration': '2h 15m',
      'price': 1450000,
      'class': 'Phổ thông Tiêu chuẩn',
      'baggage': '23kg ký gửi + 12kg xách tay',
    },
    {
      'airline': 'Vietnam Airlines',
      'logo': '🇻🇳',
      'flightNo': 'VN-7216',
      'departTime': '09:30',
      'arriveTime': '11:45',
      'duration': '2h 15m',
      'price': 1890000,
      'class': 'Bông Sen Vàng Eco',
      'baggage': '23kg ký gửi + 12kg xách tay',
    },
    {
      'airline': 'Bamboo Airways',
      'logo': '🎋',
      'flightNo': 'QH-204',
      'departTime': '11:15',
      'arriveTime': '13:25',
      'duration': '2h 10m',
      'price': 1320000,
      'class': 'Bamboo Economy',
      'baggage': '20kg ký gửi + 7kg xách tay',
    },
    {
      'airline': 'Vietjet Air',
      'logo': '✈️',
      'flightNo': 'VJ-182',
      'departTime': '14:20',
      'arriveTime': '16:30',
      'duration': '2h 10m',
      'price': 980000,
      'class': 'Eco Tiết kiệm',
      'baggage': '7kg xách tay',
    },
    {
      'airline': 'Vietnam Airlines',
      'logo': '🇻🇳',
      'flightNo': 'VN-280',
      'departTime': '18:00',
      'arriveTime': '20:15',
      'duration': '2h 15m',
      'price': 2250000,
      'class': 'Thương gia (Business)',
      'baggage': '32kg ký gửi + Phòng chờ VIP',
    },
  ];

  void _swapAirports() {
    HapticFeedback.selectionClick();
    setState(() {
      final tmpCode = _fromAirportCode;
      final tmpCity = _fromCity;
      _fromAirportCode = _toAirportCode;
      _fromCity = _toCity;
      _toAirportCode = tmpCode;
      _toCity = tmpCity;
    });
  }

  void _bookFlight(Map<String, dynamic> flight) {
    HapticFeedback.mediumImpact();
    final price = (flight['price'] as int) * _passengers;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
        decoration: const BoxDecoration(
          color: Colors.white,
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
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                const Icon(CupertinoIcons.airplane, color: Color(0xFF1E3A8A), size: 22),
                const SizedBox(width: 8),
                Text(
                  'Đặt vé ${flight['airline']} (${flight['flightNo']})',
                  style: const TextStyle(
                    color: Color(0xFF0F172A),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: [
                  _confirmRow('Chặng bay', '$_fromCity ($_fromAirportCode) ➔ $_toCity ($_toAirportCode)', isBold: true),
                  const Divider(height: 16),
                  _confirmRow('Giờ bay', '${flight['departTime']} - ${flight['arriveTime']} (${flight['duration']})'),
                  const Divider(height: 16),
                  _confirmRow('Hạng vé', flight['class'] as String),
                  const Divider(height: 16),
                  _confirmRow('Hành lý', flight['baggage'] as String),
                  const Divider(height: 16),
                  _confirmRow('Số hành khách', '$_passengers người lớn'),
                  const Divider(height: 16),
                  _confirmRow('Tổng tiền thanh toán', CurrencyFormatter.formatVND(price), isBold: true, color: const Color(0xFF14B885)),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF14B885),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  context.pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Đặt vé chuyến bay ${flight['flightNo']} thành công! Vé điện tử đã gửi qua hòm thư.'),
                      backgroundColor: const Color(0xFF14B885),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                child: const Text('Thanh toán vé qua Ví Sen Hồng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _confirmRow(String label, String value, {bool isBold = false, Color? color}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Color(0xFF64748B), fontSize: 13)),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: color ?? const Color(0xFF0F172A),
              fontSize: 13.5,
              fontWeight: isBold ? FontWeight.w700 : FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  List<Map<String, dynamic>> get _filteredFlights {
    if (_selectedAirlineFilter == 1) {
      return _flights.where((f) => (f['airline'] as String).contains('Vietnam Airlines')).toList();
    } else if (_selectedAirlineFilter == 2) {
      return _flights.where((f) => (f['airline'] as String).contains('Vietjet')).toList();
    } else if (_selectedAirlineFilter == 3) {
      return _flights.where((f) => (f['airline'] as String).contains('Bamboo')).toList();
    }
    return _flights;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Vé máy bay VNA & Đối tác',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontSize: 17.5,
            fontWeight: FontWeight.w700,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_back, color: Color(0xFF1E293B)),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          // Khung tìm kiếm chặng bay
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              children: [
                // Chọn điểm đi & điểm đến với nút đảo chiều ⇄
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Điểm khởi hành', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
                          const SizedBox(height: 2),
                          Text(
                            _fromAirportCode,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Text(_fromCity, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(CupertinoIcons.arrow_right_arrow_left, size: 16, color: Color(0xFF2563EB)),
                      ),
                      onPressed: _swapAirports,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text('Điểm đến', style: TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5)),
                          const SizedBox(height: 2),
                          Text(
                            _toAirportCode,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                          ),
                          Text(_toCity, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),

                // Chọn ngày bay & số hành khách
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(CupertinoIcons.calendar, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          '${_departureDate.day}/${_departureDate.month}/${_departureDate.year}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(CupertinoIcons.person_2, size: 16, color: Color(0xFF64748B)),
                        const SizedBox(width: 6),
                        Text(
                          '$_passengers Hành khách',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Color(0xFF0F172A)),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Bộ lọc Hãng hàng không
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildAirlineChip(0, 'Tất cả các hãng'),
                const SizedBox(width: 8),
                _buildAirlineChip(1, '🇻🇳 Vietnam Airlines'),
                const SizedBox(width: 8),
                _buildAirlineChip(2, '✈️ Vietjet Air'),
                const SizedBox(width: 8),
                _buildAirlineChip(3, '🎋 Bamboo Airways'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Danh sách các chuyến bay khả dụng
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
              physics: const BouncingScrollPhysics(),
              itemCount: _filteredFlights.length,
              itemBuilder: (ctx, idx) {
                final f = _filteredFlights[idx];
                final price = f['price'] as int;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(f['logo'] as String, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 6),
                              Text(
                                '${f['airline']} (${f['flightNo']})',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13.5,
                                  color: Color(0xFF0F172A),
                                ),
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              f['class'] as String,
                              style: const TextStyle(fontSize: 11, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                f['departTime'] as String,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              Text(_fromAirportCode, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                          Column(
                            children: [
                              Text(f['duration'] as String, style: const TextStyle(fontSize: 11.5, color: Color(0xFF94A3B8))),
                              const SizedBox(height: 2),
                              const SizedBox(
                                width: 80,
                                child: Divider(color: Color(0xFFCBD5E1), thickness: 1.2),
                              ),
                              const Text('Bay thẳng', style: TextStyle(fontSize: 10.5, color: Color(0xFF14B885), fontWeight: FontWeight.w600)),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                f['arriveTime'] as String,
                                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF0F172A)),
                              ),
                              Text(_toAirportCode, style: const TextStyle(fontSize: 12, color: Color(0xFF64748B))),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            CurrencyFormatter.formatVND(price),
                            style: const TextStyle(
                              color: Color(0xFF0F766E),
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              fontFeatures: [FontFeature.tabularFigures()],
                            ),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F172A),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              elevation: 0,
                            ),
                            onPressed: () => _bookFlight(f),
                            child: const Text('Chọn vé', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAirlineChip(int index, String label) {
    final isSelected = _selectedAirlineFilter == index;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        HapticFeedback.selectionClick();
        setState(() => _selectedAirlineFilter = index);
      },
      selectedColor: const Color(0xFF1E3A8A),
      backgroundColor: Colors.white,
      side: BorderSide(
        color: isSelected ? const Color(0xFF1E3A8A) : const Color(0xFFE2E8F0),
      ),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : const Color(0xFF475569),
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
        fontSize: 12.5,
      ),
    );
  }
}
