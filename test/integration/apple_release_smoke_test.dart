import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:jflutter/app.dart';
import 'package:jflutter/injection/dependency_injection.dart';
import 'package:jflutter/presentation/widgets/desktop_navigation.dart';
import 'package:jflutter/presentation/widgets/mobile_navigation.dart';

Future<void> _pumpReleaseApp(
  WidgetTester tester, {
  required Size size,
}) async {
  await resetDependencies();
  SharedPreferences.setMockInitialValues(const {});
  await setupDependencyInjection();

  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    const ProviderScope(
      child: JFlutterApp(),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump(const Duration(milliseconds: 500));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() async {
    await resetDependencies();
  });

  testWidgets('iOS smoke: app launches and opens release support screens', (
    tester,
  ) async {
    await _pumpReleaseApp(tester, size: const Size(430, 932));

    expect(find.byType(MobileNavigation), findsOneWidget);
    expect(find.text('FSA'), findsWidgets);

    await tester.tap(find.text('Regex').last);
    await tester.pumpAndSettle();
    expect(find.text('Regular Expressions'), findsWidgets);

    final settingsButton = tester
        .widgetList<IconButton>(find.widgetWithIcon(IconButton, Icons.settings))
        .firstWhere((button) => button.onPressed != null);
    final helpButton = tester
        .widgetList<IconButton>(
          find.widgetWithIcon(IconButton, Icons.help_outline),
        )
        .firstWhere((button) => button.onPressed != null);

    settingsButton.onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('settings_save_button')), findsOneWidget);

    await tester.pageBack();
    await tester.pumpAndSettle();

    helpButton.onPressed!.call();
    await tester.pumpAndSettle();
    expect(find.text('Help & Documentation'), findsOneWidget);
  },
      variant:
          const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.iOS}));

  testWidgets('macOS smoke: desktop home shows core panels and routes', (
    tester,
  ) async {
    await _pumpReleaseApp(tester, size: const Size(1440, 900));

    expect(find.byType(DesktopNavigation), findsOneWidget);
    expect(find.text('Algorithms'), findsOneWidget);
    expect(find.text('Simulation'), findsOneWidget);

    await tester.tap(find.byTooltip('Regular Expressions').first);
    await tester.pumpAndSettle();
    expect(find.text('Regular Expressions'), findsWidgets);
  },
      variant:
          const TargetPlatformVariant(<TargetPlatform>{TargetPlatform.macOS}));
}
