import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ambarket_mobile/features/home/presentation/screens/home_screen.dart';
import 'package:ambarket_mobile/features/home/presentation/widgets/home_search_header.dart';
import 'package:ambarket_mobile/features/home/presentation/widgets/home_hero_carousel.dart';
import 'package:ambarket_mobile/features/home/presentation/widgets/home_quick_actions.dart';
import 'package:ambarket_mobile/features/home/presentation/widgets/home_category_strip.dart';
import 'package:ambarket_mobile/features/home/presentation/widgets/home_promo_banner.dart';
import 'package:ambarket_mobile/features/home/presentation/widgets/home_product_section.dart';
import 'package:ambarket_mobile/features/marketplace/presentation/providers/marketplace_provider.dart';

void main() {
  group('Home Screen Tests', () {
    testWidgets('Renders all discovery mode sections when search is empty', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            searchQueryProvider.overrideWith(() => SearchQueryNotifier()), // Query is empty
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      // Trigger frame
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(HomeSearchHeader, skipOffstage: false), findsOneWidget);
      expect(find.byType(HomeHeroCarousel, skipOffstage: false), findsOneWidget);
      expect(find.byType(HomeQuickActions, skipOffstage: false), findsOneWidget);
      expect(find.byType(HomeCategoryStrip, skipOffstage: false), findsOneWidget);
      expect(find.byType(HomePromoBanner, skipOffstage: false), findsOneWidget);
      expect(find.byType(HomeProductSection, skipOffstage: false), findsWidgets); // Multiple product sections
    });

    testWidgets('Renders search mode when query is not empty', (WidgetTester tester) async {
      final mockNotifier = SearchQueryNotifier()..updateQuery('laptop');
      
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // search query not empty
            searchQueryProvider.overrideWith(() => mockNotifier),
          ],
          child: const MaterialApp(
            home: HomeScreen(),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Should find search header
      expect(find.byType(HomeSearchHeader, skipOffstage: false), findsOneWidget);
      
      // Should NOT find discovery sections
      expect(find.byType(HomeHeroCarousel, skipOffstage: false), findsNothing);
      expect(find.byType(HomeQuickActions, skipOffstage: false), findsNothing);
      expect(find.byType(HomeCategoryStrip, skipOffstage: false), findsNothing);
      expect(find.byType(HomePromoBanner, skipOffstage: false), findsNothing);
      expect(find.byType(HomeProductSection, skipOffstage: false), findsNothing);
    });
  });
}
