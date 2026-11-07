import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Nền shader "Mesh drift" Obsidian chuyển động mượt mà. Đặt phía sau nội dung bằng Stack.
class ShaderBackground extends StatefulWidget {
  const ShaderBackground({super.key, this.child});

  final Widget? child;

  @override
  State<ShaderBackground> createState() => _ShaderBackgroundState();
}

class _ShaderBackgroundState extends State<ShaderBackground>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  ui.FragmentProgram? _program;
  late final Ticker _ticker;
  double _seconds = 0;
  bool _lifecycleResumed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ticker = createTicker((elapsed) {
      if (mounted) {
        setState(() => _seconds = elapsed.inMicroseconds / 1e6);
      }
    })..start();

    ui.FragmentProgram.fromAsset('shaders/mesh_drift.frag').then((p) {
      if (mounted) setState(() => _program = p);
    }).catchError((_) {
      // Graceful fallback cho môi trường test hoặc thiết bị chưa nạp shader
    });
  }

  // Tạm dừng khi app vào nền để tiết kiệm pin/GPU
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _lifecycleResumed = true;
      if (!_ticker.isActive) _ticker.start();
    } else {
      _lifecycleResumed = false;
      if (_ticker.isActive) _ticker.stop();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context).clamp(1.0, 2.0);
    final isKeyboardOpen = MediaQuery.viewInsetsOf(context).bottom > 0;

    // Tự động tạm dừng animation khi bàn phím mở để tối ưu 100% GPU cho việc gõ tin nhắn
    if (isKeyboardOpen && _ticker.isActive) {
      _ticker.stop();
    } else if (!isKeyboardOpen && !_ticker.isActive && _lifecycleResumed) {
      _ticker.start();
    }

    return RepaintBoundary(
      child: CustomPaint(
        painter: _ShaderPainter(_program, _seconds * 0.73, dpr),
        child: widget.child ?? const SizedBox.expand(),
      ),
    );
  }
}

class _ShaderPainter extends CustomPainter {
  _ShaderPainter(this.program, this.time, this.dpr);

  final ui.FragmentProgram? program;
  final double time;
  final double dpr;

  @override
  void paint(Canvas canvas, Size size) {
    final p = program;
    if (p == null) {
      // Fallback nền Obsidian Full Black khi chưa load shader
      canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF000000),
              Color(0xFF050508),
              Color(0xFF0C0D12),
            ],
          ).createShader(Offset.zero & size),
      );
      return;
    }
    final fullDpr = ui.PlatformDispatcher.instance.views.first.devicePixelRatio;
    final shader = p.fragmentShader()
      ..setFloat(0, size.width * fullDpr)
      ..setFloat(1, size.height * fullDpr)
      ..setFloat(2, time);
    canvas.drawRect(Offset.zero & size, Paint()..shader = shader);
  }

  @override
  bool shouldRepaint(covariant _ShaderPainter old) => old.time != time;
}
