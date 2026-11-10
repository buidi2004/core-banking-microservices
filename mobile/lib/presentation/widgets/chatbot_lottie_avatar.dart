import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

/// Reusable animated Chatbot avatar powered by Lottie JSON.
/// Falls back to static PNG [fallbackAsset] if the animation fails to load.
class ChatbotLottieAvatar extends StatelessWidget {
  final double size;
  final bool repeat;
  final bool animate;
  final BoxFit fit;
  final String assetPath;
  final String fallbackAsset;

  const ChatbotLottieAvatar({
    super.key,
    this.size = 40.0,
    this.repeat = true,
    this.animate = true,
    this.fit = BoxFit.contain,
    this.assetPath = 'assets/icons/chatbot_hello.json',
    this.fallbackAsset = 'assets/icons/ai_assistant_ghost.png',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Lottie.asset(
        assetPath,
        width: size,
        height: size,
        fit: fit,
        repeat: repeat,
        animate: animate,
        errorBuilder: (context, error, stackTrace) {
          return Image.asset(
            fallbackAsset,
            width: size,
            height: size,
            fit: fit,
          );
        },
      ),
    );
  }
}
