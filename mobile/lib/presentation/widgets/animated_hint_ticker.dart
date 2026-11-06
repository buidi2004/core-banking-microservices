import 'dart:async';
import 'package:flutter/material.dart';

/// Widget văn bản xoay vòng mượt mà với hiệu ứng trượt dọc (Vertical Slide) kết hợp mờ dần (Fade).
/// Thường dùng cho placeholder thanh tìm kiếm thông minh trong ứng dụng ngân hàng.
class AnimatedHintTicker extends StatefulWidget {
  final List<String> hints;
  final Duration interval;
  final Duration animationDuration;
  final TextStyle? textStyle;
  final ValueChanged<int>? onIndexChanged;

  const AnimatedHintTicker({
    super.key,
    required this.hints,
    this.interval = const Duration(milliseconds: 3500),
    this.animationDuration = const Duration(milliseconds: 350),
    this.textStyle,
    this.onIndexChanged,
  });

  @override
  State<AnimatedHintTicker> createState() => AnimatedHintTickerState();
}

class AnimatedHintTickerState extends State<AnimatedHintTicker> {
  int _currentIndex = 0;
  Timer? _timer;

  int get currentIndex => _currentIndex;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    if (widget.hints.length <= 1) return;
    _timer?.cancel();
    _timer = Timer.periodic(widget.interval, (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % widget.hints.length;
      });
      widget.onIndexChanged?.call(_currentIndex);
    });
  }

  @override
  void didUpdateWidget(covariant AnimatedHintTicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.hints != widget.hints || oldWidget.interval != widget.interval) {
      _startTimer();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.hints.isEmpty) return const SizedBox.shrink();

    final currentText = widget.hints[_currentIndex];

    return ClipRect(
      child: AnimatedSwitcher(
        duration: widget.animationDuration,
        layoutBuilder: (currentChild, previousChildren) {
          return Stack(
            alignment: Alignment.centerLeft,
            children: <Widget>[
              ...previousChildren,
              if (currentChild != null) currentChild,
            ],
          );
        },
        transitionBuilder: (child, animation) {
          final isCurrent = child.key == ValueKey<int>(_currentIndex);
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: isCurrent
                  ? Tween<Offset>(
                      begin: const Offset(0.0, 0.6),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutCubic,
                    ))
                  : Tween<Offset>(
                      begin: const Offset(0.0, -0.6),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeInCubic,
                    )),
              child: child,
            ),
          );
        },
        child: Text(
          currentText,
          key: ValueKey<int>(_currentIndex),
          style: widget.textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
