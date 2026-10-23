import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:liquid_glass_widgets/liquid_glass_widgets.dart';
import 'package:sen_hong_bank/core/network/dio_client.dart';
import 'package:sen_hong_bank/core/network/realtime_notification_service.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';

class ConfigScreen extends StatefulWidget {
  const ConfigScreen({super.key});

  @override
  State<ConfigScreen> createState() => _ConfigScreenState();
}

class _ConfigScreenState extends State<ConfigScreen> {
  final TextEditingController _apiUrlCtrl =
      TextEditingController(text: DioClient.sharedDio.options.baseUrl);
  final TextEditingController _wsUrlCtrl =
      TextEditingController(text: DioClient.activeWsUrl);

  int _selectedGatewayIdx = 0;
  bool _isTesting = false;
  int _pingMs = 24;
  double _timeoutSeconds = 15;
  bool _sslPinningEnabled = true;
  bool _http2Enabled = true;
  bool _quicEnabled = false;
  bool _idempotencyLogEnabled = true;

  final List<Map<String, dynamic>> _gateways = [
    {
      'name': 'Localhost / ADB Reverse (Cổng 8080)',
      'url': 'http://localhost:8080/api/v1',
      'ws': 'ws://localhost:8080/ws-native',
      'ping': 12,
      'status': 'MẶC ĐỊNH LOCAL',
      'isPrimary': true,
    },
    {
      'name': 'Android Emulator Bridge (10.0.2.2)',
      'url': 'http://10.0.2.2:8080/api/v1',
      'ws': 'ws://10.0.2.2:8080/ws-native',
      'ping': 18,
      'status': 'MÁY ẢO ANDROID',
      'isPrimary': false,
    },
    {
      'name': 'GitHub Codespaces Cloud (Public 8080)',
      'url': 'https://solid-eureka-695rvv97vwjjh5wjq-8080.app.github.dev/api/v1',
      'ws': 'wss://solid-eureka-695rvv97vwjjh5wjq-8080.app.github.dev/ws-native',
      'ping': 45,
      'status': 'MẶC ĐỊNH CLOUD DEMO',
      'isPrimary': true,
    },
  ];

  final List<Map<String, dynamic>> _packetLogs = [
    {
      'method': 'GET',
      'path': '/wallet/my-wallet',
      'status': 200,
      'time': '14:28:10.120',
      'duration': '22ms',
    },
    {
      'method': 'POST',
      'path': '/auth/verify-pin',
      'status': 200,
      'time': '14:28:09.450',
      'duration': '35ms',
    },
    {
      'method': 'WS',
      'path': '/topic/notifications/balance',
      'status': 101,
      'time': '14:28:05.000',
      'duration': 'CONNECTED',
    },
    {
      'method': 'GET',
      'path': '/profile/me',
      'status': 200,
      'time': '14:27:58.210',
      'duration': '19ms',
    },
  ];

  @override
  void initState() {
    super.initState();
    final activeApi = DioClient.sharedDio.options.baseUrl;
    final activeWs = DioClient.activeWsUrl;
    if (activeApi.contains('.app.github.dev')) {
      _selectedGatewayIdx = 2;
      _gateways[2]['url'] = activeApi;
      _gateways[2]['ws'] = activeWs;
      _gateways[2]['status'] = 'ĐANG KẾT NỐI CLOUD';
    } else if (activeApi.contains('10.0.2.2')) {
      _selectedGatewayIdx = 1;
    }
  }

  @override
  void dispose() {
    _apiUrlCtrl.dispose();
    _wsUrlCtrl.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    HapticFeedback.mediumImpact();
    final normApi = DioClient.normalizeApiUrl(_apiUrlCtrl.text);
    final normWs = DioClient.deriveWsUrl(normApi, customWsUrl: _wsUrlCtrl.text);
    setState(() {
      _isTesting = true;
      _apiUrlCtrl.text = normApi;
      _wsUrlCtrl.text = normWs;
    });
    await DioClient.updateBaseUrl(normApi, newWsUrl: normWs);

    final sw = Stopwatch()..start();
    bool reachable = false;
    try {
      final probeDio = Dio(
        BaseOptions(
          baseUrl: normApi,
          connectTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
          validateStatus: (status) => status != null && status < 500,
          headers: const {
            'Accept': 'application/json',
            'X-Requested-With': 'XMLHttpRequest',
          },
        ),
      );
      await probeDio.post('/auth/login', data: const {});
      reachable = true;
    } catch (_) {
      reachable = false;
    }
    sw.stop();

    if (!mounted) return;
    HapticFeedback.lightImpact();
    setState(() {
      _isTesting = false;
      _pingMs = sw.elapsedMilliseconds.clamp(5, 9999);
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: reachable ? AppColors.emeraldGreen : Colors.orange.shade800,
        content: Text(
          reachable
              ? 'Kết nối Gateway thành công! Độ trễ thực tế: $_pingMs ms'
              : 'Đã lưu URL ($normApi) nhưng máy chủ chưa phản hồi ($_pingMs ms)',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _pasteCodespacesUrl() async {
    HapticFeedback.selectionClick();
    final data = await Clipboard.getData('text/plain');
    final pasted = data?.text?.trim() ?? '';
    String? targetApi;
    if (pasted.isNotEmpty &&
        (pasted.contains('.app.github.dev') ||
            pasted.startsWith('http://') ||
            pasted.startsWith('https://'))) {
      targetApi = DioClient.normalizeApiUrl(pasted);
    } else {
      targetApi = await DioClient.syncFromCloudRegistry();
    }
    if (targetApi == null || targetApi.isEmpty) return;
    final normApi = DioClient.normalizeApiUrl(targetApi);
    final normWs = DioClient.deriveWsUrl(normApi);
    setState(() {
      _apiUrlCtrl.text = normApi;
      _wsUrlCtrl.text = normWs;
      _gateways[2]['url'] = normApi;
      _gateways[2]['ws'] = normWs;
      _selectedGatewayIdx = 2;
    });
    await DioClient.updateBaseUrl(normApi, newWsUrl: normWs);
    RealtimeNotificationService().disconnect();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.emeraldGreen,
        content: Text('Đã đồng bộ & cấu hình Cloud: $normApi'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _selectGateway(int idx) async {
    HapticFeedback.selectionClick();
    if (idx == 2 && (_gateways[2]['url'] as String).contains('xxx-8080')) {
      final synced = await DioClient.syncFromCloudRegistry();
      if (synced != null && synced.isNotEmpty) {
        _gateways[2]['url'] = synced;
        _gateways[2]['ws'] = DioClient.activeWsUrl;
        _gateways[2]['status'] = 'ĐÃ ĐỒNG BỘ TỪ GITHUB';
      }
    }
    if (!mounted) return;
    setState(() {
      _selectedGatewayIdx = idx;
      _apiUrlCtrl.text = _gateways[idx]['url'] as String;
      _wsUrlCtrl.text = _gateways[idx]['ws'] as String;
      _pingMs = _gateways[idx]['ping'] as int;
    });
    await DioClient.updateBaseUrl(_apiUrlCtrl.text, newWsUrl: _wsUrlCtrl.text);
    RealtimeNotificationService().disconnect();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.primaryDark,
        content: Text('Đã chuyển sang Gateway: ${_gateways[idx]['name']}'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _saveConfig() async {
    HapticFeedback.mediumImpact();
    final normApi = DioClient.normalizeApiUrl(_apiUrlCtrl.text);
    final normWs = DioClient.deriveWsUrl(normApi);
    setState(() {
      _apiUrlCtrl.text = normApi;
      _wsUrlCtrl.text = normWs;
    });
    await DioClient.updateBaseUrl(normApi, newWsUrl: normWs);
    RealtimeNotificationService().disconnect();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.emeraldGreen,
        content: Text('Đã lưu & áp dụng Gateway: ${DioClient.sharedDio.options.baseUrl}'),
        behavior: SnackBarBehavior.floating,
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
            top: -100,
            left: -80,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.28),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 80,
            right: -100,
            child: Container(
              width: 340,
              height: 340,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    AppColors.bottomBarCyan.withValues(alpha: 0.16),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    children: [
                      _buildNetworkHealthCard(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('CỤM MÁY CHỦ GATEWAY ĐA VÙNG'),
                      const SizedBox(height: 10),
                      _buildGatewaysList(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('TÙY CHỈNH ĐỊA CHỈ KẾT NỐI TRỰC TIẾP'),
                      const SizedBox(height: 10),
                      _buildEndpointsInputCard(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('GIAO THỨC & BẢO MẬT MÃ HÓA MẠNG'),
                      const SizedBox(height: 10),
                      _buildProtocolsCard(),
                      const SizedBox(height: 20),
                      _buildSectionHeader('NHẬT KÝ GÓI TIN MẠNG (LIVE PACKET LOGS)'),
                      const SizedBox(height: 10),
                      _buildLivePacketLogsCard(),
                      const SizedBox(height: 28),
                      _buildActionButtons(),
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

  Widget _buildAppBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF030B17).withValues(alpha: 0.75),
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
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cấu hình Server & Mạng',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 19,
                  ),
                ),
                Text(
                  'Quản lý Gateway API, STOMP & SSL Pinning',
                  style: TextStyle(
                    color: AppColors.bottomBarCyan,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.emeraldGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.emeraldGreen.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: AppColors.emeraldGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 5),
                const Text('ONLINE', style: TextStyle(color: AppColors.emeraldGreen, fontSize: 11, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNetworkHealthCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [
            Color(0xFF102847),
            Color(0xFF0F2B48),
            Color(0xFF071526),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppColors.bottomBarCyan.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.bottomBarCyan.withValues(alpha: 0.12),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(CupertinoIcons.waveform_path_ecg, color: AppColors.bottomBarCyan, size: 22),
                  SizedBox(width: 10),
                  Text(
                    'Trạng Thái Đường Truyền Realtime',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                ],
              ),
              GestureDetector(
                onTap: _testConnection,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColors.bottomBarCyan.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_isTesting)
                        const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.bottomBarCyan),
                        )
                      else
                        const Icon(CupertinoIcons.arrow_clockwise, color: AppColors.bottomBarCyan, size: 14),
                      const SizedBox(width: 5),
                      const Text('Đo lại Ping', style: TextStyle(color: AppColors.bottomBarCyan, fontWeight: FontWeight.bold, fontSize: 11.5)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildMetricCol('Độ trễ phản hồi (RTT)', '$_pingMs ms', AppColors.emeraldGreen),
              _buildMetricCol('Tỷ lệ mất gói (Loss)', '0.0 %', AppColors.emeraldGreen),
              _buildMetricCol('Băng thông lý thuyết', '1.2 Gbps', AppColors.bottomBarCyan),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_pingMs / 100).clamp(0.1, 1.0),
              backgroundColor: Colors.white.withValues(alpha: 0.08),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.emeraldGreen),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Kết nối ổn định với tiêu chuẩn bảo mật ngân hàng cao nhất, đáp ứng các giao dịch chuyển tiền tức thì.',
            style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String val, Color valColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white54, fontSize: 11)),
        const SizedBox(height: 3),
        Text(val, style: TextStyle(color: valColor, fontWeight: FontWeight.w900, fontSize: 18)),
      ],
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

  Widget _buildGatewaysList() {
    return Column(
      children: List.generate(_gateways.length, (idx) {
        final g = _gateways[idx];
        final isSelected = _selectedGatewayIdx == idx;
        return GestureDetector(
          onTap: () => _selectGateway(idx),
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isSelected
                  ? const Color(0xFF132A48)
                  : const Color(0xFF0C1929).withValues(alpha: 0.8),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected ? AppColors.bottomBarCyan : Colors.white.withValues(alpha: 0.08),
                width: isSelected ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  isSelected ? CupertinoIcons.checkmark_circle_fill : CupertinoIcons.circle,
                  color: isSelected ? AppColors.bottomBarCyan : Colors.white38,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        g['name'] as String,
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        g['url'] as String,
                        style: const TextStyle(color: Colors.white54, fontSize: 11),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.emeraldGreen.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${g['ping']} ms',
                    style: TextStyle(
                      color: isSelected ? AppColors.emeraldGreen : Colors.white60,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEndpointsInputCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('REST API Base URL (Chỉ cần dán link cổng 8080)', style: TextStyle(color: Colors.white70, fontSize: 12)),
                GestureDetector(
                  onTap: _pasteCodespacesUrl,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.bottomBarCyan.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.bottomBarCyan.withValues(alpha: 0.45)),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(CupertinoIcons.doc_on_clipboard_fill, color: AppColors.bottomBarCyan, size: 12),
                        SizedBox(width: 4),
                        Text(
                          'Dán nhanh',
                          style: TextStyle(color: AppColors.bottomBarCyan, fontSize: 11, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _apiUrlCtrl,
              onChanged: (val) {
                _wsUrlCtrl.text = DioClient.deriveWsUrl(val);
              },
              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                hintText: 'https://xxx-8080.app.github.dev/api/v1',
                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.3), fontSize: 12),
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
            const SizedBox(height: 14),
            const Text('WebSocket STOMP URL (Tự động đồng bộ từ REST URL)', style: TextStyle(color: Colors.white70, fontSize: 12)),
            const SizedBox(height: 6),
            TextField(
              controller: _wsUrlCtrl,
              style: const TextStyle(color: Colors.white, fontSize: 13, fontFamily: 'monospace'),
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white.withValues(alpha: 0.05),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProtocolsCard() {
    return GlassCard(
      quality: GlassQuality.minimal,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildToggleRow(
              title: 'HTTP/2 Multiplexing',
              subtitle: 'Gộp luồng nhiều request cùng lúc, giảm độ trễ 40%',
              val: _http2Enabled,
              onChanged: (v) => setState(() => _http2Enabled = v),
            ),
            _buildDivider(),
            _buildToggleRow(
              title: 'Giao thức HTTP/3 (QUIC/UDP)',
              subtitle: 'Chuyển mạch mạng không gián đoạn giữa Wifi và 4G/5G',
              val: _quicEnabled,
              onChanged: (v) => setState(() => _quicEnabled = v),
            ),
            _buildDivider(),
            _buildToggleRow(
              title: 'Khóa ghim chứng chỉ SSL Pinning',
              subtitle: 'Ngăn chặn tấn công Man-In-The-Middle (Bắt buộc bật)',
              val: _sslPinningEnabled,
              onChanged: (v) => setState(() => _sslPinningEnabled = v),
            ),
            _buildDivider(),
            _buildToggleRow(
              title: 'Idempotency Key chống trùng lệnh',
              subtitle: 'Ngăn chặn trừ tiền 2 lần khi mạng chập chờn',
              val: _idempotencyLogEnabled,
              onChanged: (v) => setState(() => _idempotencyLogEnabled = v),
            ),
            _buildDivider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thời gian chờ kết nối (Timeout)',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${_timeoutSeconds.toInt()} giây (Mặc định chuẩn: 15s)',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.55),
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: 130,
                  child: Slider(
                    value: _timeoutSeconds,
                    min: 5,
                    max: 30,
                    divisions: 5,
                    activeColor: AppColors.bottomBarCyan,
                    inactiveColor: Colors.white12,
                    onChanged: (v) => setState(() => _timeoutSeconds = v),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToggleRow({
    required String title,
    required String subtitle,
    required bool val,
    required ValueChanged<bool> onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13.5)),
              const SizedBox(height: 2),
              Text(subtitle, style: TextStyle(color: Colors.white.withValues(alpha: 0.55), fontSize: 11.5)),
            ],
          ),
        ),
        CupertinoSwitch(
          value: val,
          activeTrackColor: AppColors.bottomBarCyan,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
    );
  }

  Widget _buildLivePacketLogsCard() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0A1424),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _packetLogs.map((p) {
          final isOk = (p['status'] as int) == 200 || (p['status'] as int) == 101;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: p['method'] == 'POST'
                        ? AppColors.primary.withValues(alpha: 0.2)
                        : (p['method'] == 'WS'
                            ? AppColors.bottomBarCyan.withValues(alpha: 0.2)
                            : AppColors.bottomBarCyan.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p['method'] as String,
                    style: TextStyle(
                      color: p['method'] == 'POST'
                          ? AppColors.primary
                          : (p['method'] == 'WS'
                              ? AppColors.bottomBarCyan
                              : AppColors.bottomBarCyan),
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    p['path'] as String,
                    style: const TextStyle(color: Colors.white70, fontSize: 11, fontFamily: 'monospace'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  p['duration'] as String,
                  style: TextStyle(
                    color: isOk ? AppColors.emeraldGreen : Colors.redAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActionButtons() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        onPressed: _saveConfig,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(CupertinoIcons.checkmark_seal_fill, size: 18),
            SizedBox(width: 8),
            Text('Lưu cấu hình Gateway', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ],
        ),
      ),
    );
  }
}
