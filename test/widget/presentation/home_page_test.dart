import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jflutter/core/services/simulation_highlight_service.dart';
import 'package:jflutter/presentation/providers/home_navigation_provider.dart';
import 'package:jflutter/presentation/pages/home_page.dart';
import 'package:jflutter/presentation/widgets/mobile_navigation.dart';
import 'package:jflutter/presentation/widgets/desktop_navigation.dart';

class _TestHomeNavigationNotifier extends HomeNavigationNotifier {
  final List<int> receivedIndices = [];

  @override
  void setIndex(int index) {
    receivedIndices.add(index);
    super.setIndex(index);
  }
}

class _TestSimulationHighlightService extends SimulationHighlightService {
  int clearCallCount = 0;

  @override
  void clear() {
    clearCallCount++;
    super.clear();
  }
}

Future<void> _pumpHomePage(
  WidgetTester tester, {
  required _TestHomeNavigationNotifier navigationNotifier,
  required _TestSimulationHighlightService highlightService,
  Size size = const Size(430, 932),
}) async {
  final binding = tester.binding;
  binding.window.physicalSizeTestValue = size;
  binding.window.devicePixelRatioTestValue = 1.0;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeNavigationProvider.overrideWith((ref) {
          ref.onDispose(navigationNotifier.dispose);
          return navigationNotifier;
        }),
        canvasHighlightServiceProvider.overrideWithValue(highlightService),
      ],
      child: const MaterialApp(
        home: HomePage(),
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HomePage', () {
    testWidgets(
      'renders mobile navigation with dynamic titles and actions below 1024 width',
      (tester) async {
        final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(1);
        final highlightService = _TestSimulationHighlightService();

        addTearDown(() {
          tester.binding.window.clearPhysicalSizeTestValue();
          tester.binding.window.clearDevicePixelRatioTestValue();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: const Size(800, 1280),
        );

        addTearDown(navigationNotifier.dispose);

        expect(find.byType(MobileNavigation), findsOneWidget);
        expect(find.byType(DesktopNavigation), findsNothing);
        expect(find.text('Grammar'), findsWidgets);
        expect(find.text('Context-Free Grammars'), findsOneWidget);
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);

        expect(highlightService.clearCallCount, 0);
      },
    );

    testWidgets(
      'renders desktop navigation rail with tooltips at 1024 width or above',
      (tester) async {
        final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
        final highlightService = _TestSimulationHighlightService();

        addTearDown(() {
          tester.binding.window.clearPhysicalSizeTestValue();
          tester.binding.window.clearDevicePixelRatioTestValue();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: const Size(1280, 900),
        );

        addTearDown(navigationNotifier.dispose);

        expect(find.byType(MobileNavigation), findsNothing);
        expect(find.byType(DesktopNavigation), findsOneWidget);
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.text('FSA'), findsWidgets);
        expect(find.widgetWithText(Tooltip, 'Finite State Automata'), findsWidgets);
        expect(find.byIcon(Icons.help_outline), findsOneWidget);
        expect(find.byIcon(Icons.settings), findsOneWidget);

        expect(highlightService.clearCallCount, 0);
      },
    );

    testWidgets('updates page view and provider when tapping navigation',
        (tester) async {
      final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(1);
      final highlightService = _TestSimulationHighlightService();

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
      );

      addTearDown(navigationNotifier.dispose);

      final navigationFinder = find.byType(MobileNavigation);

      await tester.tap(find.descendant(
        of: navigationFinder,
        matching: find.text('Regex'),
      ));
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.page, closeTo(4, 0.001));
      expect(navigationNotifier.receivedIndices.contains(4), isTrue);
      expect(find.text('Regex'), findsWidgets);
      expect(find.text('Regular Expressions'), findsOneWidget);

      await tester.tap(find.descendant(
        of: navigationFinder,
        matching: find.text('PDA'),
      ));
      await tester.pumpAndSettle();

      expect(pageView.controller?.page, closeTo(2, 0.001));
      expect(navigationNotifier.receivedIndices.contains(2), isTrue);
      expect(find.text('PDA'), findsWidgets);
      expect(find.text('Pushdown Automata'), findsOneWidget);
    });

    testWidgets('updates page view via navigation rail on desktop layout',
        (tester) async {
      final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
      final highlightService = _TestSimulationHighlightService();

      addTearDown(() {
        tester.binding.window.clearPhysicalSizeTestValue();
        tester.binding.window.clearDevicePixelRatioTestValue();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
        size: const Size(1400, 900),
      );

      addTearDown(navigationNotifier.dispose);

      expect(find.byType(DesktopNavigation), findsOneWidget);

      await tester.tap(find.byTooltip('Regular Expressions').first);
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.page, closeTo(4, 0.001));
      expect(navigationNotifier.receivedIndices.contains(4), isTrue);
      expect(find.text('Regex'), findsWidgets);
      expect(find.text('Regular Expressions'), findsWidgets);
    });
  });
}
