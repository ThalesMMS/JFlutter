import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jflutter/core/services/simulation_highlight_service.dart';
import 'package:jflutter/l10n/app_localizations.dart';
import 'package:jflutter/presentation/pages/help_page.dart';
import 'package:jflutter/presentation/providers/home_navigation_provider.dart';
import 'package:jflutter/presentation/pages/home_page.dart';
import 'package:jflutter/presentation/pages/settings_page.dart';
import 'package:jflutter/presentation/widgets/mobile_navigation.dart';
import 'package:jflutter/presentation/widgets/desktop_navigation.dart';
import 'package:jflutter/injection/dependency_injection.dart';

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

class _RecordingNavigatorObserver extends NavigatorObserver {
  final List<Route<dynamic>> pushedRoutes = [];

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute != null) {
      pushedRoutes.add(route);
    }
    super.didPush(route, previousRoute);
  }
}

Future<void> _pumpHomePage(
  WidgetTester tester, {
  required _TestHomeNavigationNotifier navigationNotifier,
  required _TestSimulationHighlightService highlightService,
  Size size = const Size(430, 932),
  List<NavigatorObserver> navigatorObservers = const [],
}) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        homeNavigationProvider.overrideWith((ref) {
          return navigationNotifier;
        }),
        canvasHighlightServiceProvider.overrideWithValue(highlightService),
      ],
      child: MaterialApp(
        home: const HomePage(),
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        navigatorObservers: navigatorObservers,
      ),
    ),
  );

  await tester.pumpAndSettle();
}

void _triggerEnabledAppBarAction(WidgetTester tester, IconData icon) {
  final appBarActionFinder = find.descendant(
    of: find.byType(AppBar),
    matching: find.widgetWithIcon(IconButton, icon),
  );
  final button = tester
      .widgetList<IconButton>(appBarActionFinder)
      .firstWhere((candidate) => candidate.onPressed != null);
  button.onPressed!.call();
}

void _expectSinglePushTo<T>(
  _RecordingNavigatorObserver observer,
) {
  expect(observer.pushedRoutes, hasLength(1));
  final route = observer.pushedRoutes.single;
  expect(route, isA<MaterialPageRoute<dynamic>>());
  final page = (route as MaterialPageRoute<dynamic>)
      .builder(observer.navigator!.context);
  expect(page, isA<T>());
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    await setupDependencyInjection();
  });

  tearDownAll(() async {
    await resetDependencies();
  });

  group('HomePage', () {
    testWidgets(
      'renders mobile navigation with dynamic titles and actions below 1024 width',
      (tester) async {
        final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(1);
        final highlightService = _TestSimulationHighlightService();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: const Size(800, 1280),
        );

        expect(find.byType(MobileNavigation), findsOneWidget);
        expect(find.byType(DesktopNavigation), findsNothing);
        expect(find.text('Grammar'), findsWidgets);
        expect(find.text('Context-Free Grammars'), findsOneWidget);
        expect(find.text('Pumping'), findsNothing);
        expect(find.byIcon(Icons.help_outline), findsWidgets);
        expect(find.byIcon(Icons.settings), findsWidgets);

        expect(highlightService.clearCallCount, 0);
      },
    );

    testWidgets(
      'renders desktop navigation rail with tooltips at 1024 width or above',
      (tester) async {
        final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
        final highlightService = _TestSimulationHighlightService();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: const Size(1280, 900),
        );

        expect(find.byType(MobileNavigation), findsNothing);
        expect(find.byType(DesktopNavigation), findsOneWidget);
        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.text('FSA'), findsWidgets);
        expect(find.text('Pumping'), findsNothing);
        expect(
          find.byTooltip('Finite State Automata'),
          findsWidgets,
        );
        expect(find.byIcon(Icons.help_outline), findsWidgets);
        expect(find.byIcon(Icons.settings), findsWidgets);

        expect(highlightService.clearCallCount, 0);
      },
    );

    testWidgets('updates page view and provider when tapping navigation', (
      tester,
    ) async {
      final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(1);
      final highlightService = _TestSimulationHighlightService();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
      );

      final navigationFinder = find.byType(MobileNavigation);

      await tester.tap(
        find.descendant(of: navigationFinder, matching: find.text('Regex')),
      );
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.page, closeTo(4, 0.001));
      expect(navigationNotifier.receivedIndices.contains(4), isTrue);
      expect(find.text('Regex'), findsWidgets);
      expect(find.text('Regular Expressions'), findsOneWidget);

      await tester.tap(
        find.descendant(of: navigationFinder, matching: find.text('PDA')),
      );
      await tester.pumpAndSettle();

      expect(pageView.controller?.page, closeTo(2, 0.001));
      expect(navigationNotifier.receivedIndices.contains(2), isTrue);
      expect(find.text('PDA'), findsWidgets);
      expect(find.text('Pushdown Automata'), findsOneWidget);
    });

    testWidgets('updates page view via navigation rail on desktop layout', (
      tester,
    ) async {
      final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
      final highlightService = _TestSimulationHighlightService();

      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await _pumpHomePage(
        tester,
        navigationNotifier: navigationNotifier,
        highlightService: highlightService,
        size: const Size(1400, 1080),
      );

      expect(find.byType(DesktopNavigation), findsOneWidget);

      await tester.tap(find.byTooltip('Regular Expressions').first);
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(find.byType(PageView));
      expect(pageView.controller?.page, closeTo(4, 0.001));
      expect(navigationNotifier.receivedIndices.contains(4), isTrue);
      expect(find.text('Regex'), findsWidgets);
      expect(find.text('Regular Expressions'), findsWidgets);
    });

    for (final scenario in [
      ('mobile', const Size(430, 932)),
      ('desktop', const Size(1400, 1080)),
    ]) {
      testWidgets('pushes HelpPage from app bar on ${scenario.$1} layout', (
        tester,
      ) async {
        final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
        final highlightService = _TestSimulationHighlightService();
        final observer = _RecordingNavigatorObserver();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: scenario.$2,
          navigatorObservers: [observer],
        );

        _triggerEnabledAppBarAction(tester, Icons.help_outline);
        await tester.pumpAndSettle();

        _expectSinglePushTo<HelpPage>(observer);
      });

      testWidgets('pushes SettingsPage from app bar on ${scenario.$1} layout', (
        tester,
      ) async {
        final navigationNotifier = _TestHomeNavigationNotifier()..setIndex(0);
        final highlightService = _TestSimulationHighlightService();
        final observer = _RecordingNavigatorObserver();

        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
        });

        await _pumpHomePage(
          tester,
          navigationNotifier: navigationNotifier,
          highlightService: highlightService,
          size: scenario.$2,
          navigatorObservers: [observer],
        );

        _triggerEnabledAppBarAction(tester, Icons.settings);
        await tester.pumpAndSettle();

        _expectSinglePushTo<SettingsPage>(observer);
      });
    }
  });
}
