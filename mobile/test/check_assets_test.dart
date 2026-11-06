import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('load all images in banners', (tester) async {
    for (final name in [
      'assets/images/banners/vietnam_halong_bay.jpg',
      'assets/images/banners/vietnam_danang_golden_bridge.jpg',
      'assets/images/banners/vietnam_trang_an.jpg',
      'assets/images/banners/vietnam_phu_quoc.jpg',
      'assets/images/banners/real_stellar_banner.png',
    'assets/images/banners/real_promo_thailand.png',
    'assets/images/banners/real_featured_jcb_exact.png',
    'assets/images/banners/real_featured_visa_exact.png',
    'assets/images/banners/stellar_card_goddess.png',
      'assets/images/banners/stellar_card_heart.png',
      'assets/images/banners/stellar_card_heritage.png',
    ]) {
      final bytes = await rootBundle.load(name);
      expect(bytes.lengthInBytes, greaterThan(0));
    }
  });
}
