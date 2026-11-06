import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_carousel_widget/flutter_carousel_widget.dart';
import 'package:sen_hong_bank/presentation/widgets/curved_promo_banner.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CurvedPromoBanner Carousel Configuration Tests', () {
    testWidgets('renders FlutterCarousel with responsive ad banner options',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurvedPromoBanner(
              onRegisterTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find FlutterCarousel widget
      final carouselFinder = find.byType(FlutterCarousel);
      expect(carouselFinder, findsOneWidget);

      final FlutterCarousel carousel =
          tester.widget<FlutterCarousel>(carouselFinder);

      // Verify options match exactly the screenshot specification:
      // Wide cards keep the campaign photo, offer and CTA readable.
      expect(carousel.viewportFraction, equals(0.86));

      // 2. Infinite = true
      expect(carousel.infinite, isTrue);

      // 3. Pad ends = true
      expect(carousel.padEnds, isTrue);

      // 4. Flush edges = false (aligned center)
      expect(carousel.edgeAlignment, equals(CarouselEdgeAlignment.center));

      // Keep neighboring cards close to the same scale for legible artwork.
      expect(carousel.effect, isA<EnlargeEffect>());
      final enlargeEffect = carousel.effect as EnlargeEffect;
      expect(enlargeEffect.factor, closeTo(0.08, 0.001));

      // 6. Indicator is CircularSlideIndicator (overlay, not below)
      expect(carousel.indicator, isNotNull);
      expect(carousel.indicator!.painter, isA<CircularSlideIndicator>());
      expect(carousel.indicator!.placement,
          equals(CarouselIndicatorPlacement.overlay));

      // 7. Autoplay is active
      expect(carousel.autoPlay, isNotNull);
      expect(carousel.autoPlay!.interval, equals(const Duration(seconds: 4)));
      expect(find.byType(BackdropFilter), findsNothing);
    });

    testWidgets('renders diagonal slanted banner variant correctly',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CurvedPromoBanner(
              isDiagonalSlanted: true,
              onRegisterTap: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CurvedPromoBanner), findsOneWidget);
    });
  });
}
