import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Hiệu ứng "tia sáng" chạy quanh viền của một widget (port từ border-beam của React).
class BorderBeam extends StatefulWidget {
  const BorderBeam({
    super.key,
    required this.child,
    this.borderRadius = 20,
    this.strokeWidth = 1.5,
    this.duration = const Duration(seconds: 3),
    this.beamLength = 0.28, // phần chu vi được phủ sáng (0..1)
    this.glowSigma = 8,
    this.glowOpacity = 0.55,
    this.colors = const [
      Color(0xFF7C5CFF),
      Color(0xFF3BB2FF),
      Color(0xFFFF6BCB),
    ],
    this.baseBorderColor = const Color(0x142C2F36),
  });

  final Widget child;
  final double borderRadius;
  final double strokeWidth;
  final Duration duration;
  final double beamLength;
  final double glowSigma;
  final double glowOpacity;
  final List<Color> colors;
  final Color baseBorderColor;

  @override
  State<BorderBeam> createState() => _BorderBeamState();
}

class _BorderBeamState extends State<BorderBeam>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: widget.duration)..repeat();

  @override
  void didUpdateWidget(covariant BorderBeam oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.duration != widget.duration) {
      _controller
        ..duration = widget.duration
        ..repeat();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: CustomPaint(
        foregroundPainter: _BeamPainter(
          animation: _controller,
          radius: widget.borderRadius,
          strokeWidth: widget.strokeWidth,
          beamLength: widget.beamLength,
          glowSigma: widget.glowSigma,
          glowOpacity: widget.glowOpacity,
          colors: widget.colors,
          baseBorderColor: widget.baseBorderColor,
        ),
        child: widget.child,
      ),
    );
  }
}

class _BeamPainter extends CustomPainter {
  _BeamPainter({
    required this.animation,
    required this.radius,
    required this.strokeWidth,
    required this.beamLength,
    required this.glowSigma,
    required this.glowOpacity,
    required this.colors,
    required this.baseBorderColor,
  }) : super(repaint: animation);

  final Animation<double> animation;
  final double radius;
  final double strokeWidth;
  final double beamLength;
  final double glowSigma;
  final double glowOpacity;
  final List<Color> colors;
  final Color baseBorderColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect.deflate(strokeWidth / 2),
      Radius.circular(radius),
    );

    // Viền nền mờ
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..color = baseBorderColor,
    );

    // Gradient quét: trong suốt -> các màu -> trong suốt
    final n = colors.length;
    final gradientColors = <Color>[
      Colors.transparent,
      ...colors,
      Colors.transparent,
      Colors.transparent,
    ];
    final stops = <double>[
      0.0,
      for (var i = 0; i < n; i++) beamLength * (i + 1) / (n + 1),
      beamLength,
      1.0,
    ];

    final shader = SweepGradient(
      colors: gradientColors,
      stops: stops,
      transform: GradientRotation(animation.value * 2 * math.pi),
    ).createShader(rect);

    // Glow (mờ, phía sau)
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth * 2.5
        ..shader = shader
        ..color = Colors.white.withValues(alpha: glowOpacity)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, glowSigma),
    );

    // Tia sáng chính
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..shader = shader,
    );
  }

  @override
  bool shouldRepaint(covariant _BeamPainter old) =>
      old.radius != radius ||
      old.strokeWidth != strokeWidth ||
      old.beamLength != beamLength ||
      old.glowSigma != glowSigma ||
      old.glowOpacity != glowOpacity ||
      old.colors != colors ||
      old.baseBorderColor != baseBorderColor;
}

