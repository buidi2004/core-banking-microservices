import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sen_hong_bank/core/theme/app_colors.dart';
import 'package:sen_hong_bank/core/theme/app_typography.dart';

class CustomPinNumpad extends StatelessWidget {
  final String pin;
  final int maxDigits;
  final ValueChanged<String> onPinChanged;
  final VoidCallback? onBiometricPressed;
  final bool showBiometric;

  const CustomPinNumpad({
    super.key,
    required this.pin,
    this.maxDigits = 6,
    required this.onPinChanged,
    this.onBiometricPressed,
    this.showBiometric = false,
  });

  void _onKeyPress(String val) {
    if (pin.length < maxDigits) {
      HapticFeedback.selectionClick();
      onPinChanged(pin + val);
    }
  }

  void _onBackspace() {
    if (pin.isNotEmpty) {
      HapticFeedback.selectionClick();
      onPinChanged(pin.substring(0, pin.length - 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // PIN dots indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(maxDigits, (index) {
            final isFilled = index < pin.length;
            return AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              margin: const EdgeInsets.symmetric(horizontal: 8),
              width: isFilled ? 18 : 14,
              height: isFilled ? 18 : 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isFilled ? AppColors.primary : Colors.transparent,
                border: Border.all(
                  color: isFilled ? AppColors.primary : AppColors.cardBorderDark,
                  width: 2,
                ),
                boxShadow: isFilled
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.5),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ]
                    : null,
              ),
            );
          }),
        ),
        const SizedBox(height: 36),

        // Numpad Grid
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              _buildRow(['1', '2', '3']),
              const SizedBox(height: 16),
              _buildRow(['4', '5', '6']),
              const SizedBox(height: 16),
              _buildRow(['7', '8', '9']),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  showBiometric
                      ? _buildSpecialButton(
                          icon: CupertinoIcons.viewfinder_circle_fill,
                          onPressed: onBiometricPressed,
                        )
                      : const SizedBox(width: 72, height: 72),
                  _buildNumberButton('0'),
                  _buildSpecialButton(
                    icon: CupertinoIcons.delete_left_fill,
                    onPressed: _onBackspace,
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRow(List<String> numbers) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: numbers.map((n) => _buildNumberButton(n)).toList(),
    );
  }

  Widget _buildNumberButton(String number) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: AppColors.cardDark,
        shape: const CircleBorder(
          side: BorderSide(color: AppColors.cardBorderDark, width: 1),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () => _onKeyPress(number),
          splashColor: AppColors.primary.withOpacity(0.3),
          child: Center(
            child: Text(
              number,
              style: AppTypography.displaySmall(color: AppColors.textPrimaryDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSpecialButton({required IconData icon, VoidCallback? onPressed}) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: Center(
            child: Icon(icon, color: AppColors.textPrimaryDark, size: 28),
          ),
        ),
      ),
    );
  }
}
