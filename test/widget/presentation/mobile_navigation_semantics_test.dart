import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/presentation/widgets/mobile_navigation.dart';

void main() {
  testWidgets('navigation item exposes description semantics and selection state', (tester) async {
    final semantics = SemanticsTester(tester);
    addTearDown(semantics.dispose);

    const items = [
      NavigationItem(
        label: 'Home',
        icon: Icons.home,
        description: 'Navigate to the home dashboard',
      ),
      NavigationItem(
        label: 'Settings',
        icon: Icons.settings,
        description: 'Open configuration settings',
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: MobileNavigation(
            currentIndex: 1,
            onTap: (_) {},
            items: items,
          ),
        ),
      ),
    );

    await tester.pump();

    final nodes = semantics.nodesWith(
      hint: items[1].description,
    );

    expect(nodes, hasLength(1));

    final node = nodes.single;
    expect(node.hasFlag(SemanticsFlag.isSelected), isTrue);
    expect(node.hasAction(SemanticsAction.tap), isTrue);
  });
}
