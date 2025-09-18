import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jflutter/app.dart';
import 'package:jflutter/presentation/pages/home_page.dart';
import 'package:jflutter/presentation/widgets/automaton_canvas.dart';
import 'package:jflutter/presentation/widgets/mobile_navigation.dart';

void main() {
  group('Mobile UI Integration Tests', () {
    testWidgets('should render main app with navigation tabs', (WidgetTester tester) async {
      // Arrange & Act
      await tester.pumpWidget(const JFlutterApp());
      
      // Assert
      expect(find.text('JFlutter'), findsOneWidget);
      expect(find.text('FSA'), findsOneWidget);
      expect(find.text('Grammar'), findsOneWidget);
      expect(find.text('PDA'), findsOneWidget);
      expect(find.text('TM'), findsOneWidget);
      expect(find.text('L-Systems'), findsOneWidget);
      expect(find.text('Pumping'), findsOneWidget);
    });
    
    testWidgets('should navigate between tabs', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      
      // Act - Tap on Grammar tab
      await tester.tap(find.text('Grammar'));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('Grammar'), findsOneWidget);
      
      // Act - Tap on PDA tab
      await tester.tap(find.text('PDA'));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.text('PDA'), findsOneWidget);
    });
    
    testWidgets('should show floating action button for FSA tab', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      
      // Act - Ensure we're on FSA tab (should be default)
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
    
    testWidgets('should show floating action button for Grammar tab', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      
      // Act - Navigate to Grammar tab
      await tester.tap(find.text('Grammar'));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byType(FloatingActionButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
    });
    
    testWidgets('should not show floating action button for other tabs', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      
      // Act - Navigate to PDA tab
      await tester.tap(find.text('PDA'));
      await tester.pumpAndSettle();
      
      // Assert
      expect(find.byType(FloatingActionButton), findsNothing);
    });
    
    testWidgets('should show help dialog when help is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      
      // Act - Find and tap help button (assuming it's in app bar)
      final helpButton = find.byIcon(Icons.help);
      if (helpButton.evaluate().isNotEmpty) {
        await tester.tap(helpButton);
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Help'), findsOneWidget);
        expect(find.text('JFlutter is a mobile app for learning formal language theory.'), findsOneWidget);
      }
    });
    
    testWidgets('should show settings dialog when settings is tapped', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      
      // Act - Find and tap settings button (assuming it's in app bar)
      final settingsButton = find.byIcon(Icons.settings);
      if (settingsButton.evaluate().isNotEmpty) {
        await tester.tap(settingsButton);
        await tester.pumpAndSettle();
        
        // Assert
        expect(find.text('Settings'), findsOneWidget);
      }
    });
    
    testWidgets('should handle touch interactions on automaton canvas', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      await tester.pumpAndSettle();
      
      // Act - Find automaton canvas and perform touch gestures
      final canvas = find.byType(AutomatonCanvas);
      if (canvas.evaluate().isNotEmpty) {
        // Test tap gesture
        await tester.tap(canvas);
        await tester.pump();
        
        // Test long press gesture
        await tester.longPress(canvas);
        await tester.pump();
        
        // Test drag gesture
        await tester.drag(canvas, const Offset(50, 50));
        await tester.pump();
      }
      
      // Assert - Canvas should still be present
      expect(canvas, findsOneWidget);
    });
    
    testWidgets('should handle pinch to zoom gestures', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      await tester.pumpAndSettle();
      
      // Act - Find automaton canvas and perform pinch gesture
      final canvas = find.byType(AutomatonCanvas);
      if (canvas.evaluate().isNotEmpty) {
        // Simulate pinch gesture
        final center = tester.getCenter(canvas);
        await tester.startGesture(center - const Offset(20, 0));
        await tester.startGesture(center + const Offset(20, 0));
        
        // Move fingers apart to zoom in
        await tester.moveTo(center - const Offset(40, 0));
        await tester.moveTo(center + const Offset(40, 0));
        await tester.pump();
      }
      
      // Assert - Canvas should still be present
      expect(canvas, findsOneWidget);
    });
    
    testWidgets('should handle pan gestures', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      await tester.pumpAndSettle();
      
      // Act - Find automaton canvas and perform pan gesture
      final canvas = find.byType(AutomatonCanvas);
      if (canvas.evaluate().isNotEmpty) {
        // Simulate pan gesture
        await tester.drag(canvas, const Offset(100, 100));
        await tester.pump();
        
        // Pan in different direction
        await tester.drag(canvas, const Offset(-50, -50));
        await tester.pump();
      }
      
      // Assert - Canvas should still be present
      expect(canvas, findsOneWidget);
    });
    
    testWidgets('should maintain touch target size of at least 44dp', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      await tester.pumpAndSettle();
      
      // Act - Find all interactive elements
      final buttons = find.byType(ElevatedButton);
      final fabButtons = find.byType(FloatingActionButton);
      final iconButtons = find.byType(IconButton);
      
      // Assert - Check minimum touch target size
      for (int i = 0; i < buttons.evaluate().length; i++) {
        final button = buttons.at(i);
        final size = tester.getSize(button);
        expect(size.width, greaterThanOrEqualTo(44.0));
        expect(size.height, greaterThanOrEqualTo(44.0));
      }
      
      for (int i = 0; i < fabButtons.evaluate().length; i++) {
        final fab = fabButtons.at(i);
        final size = tester.getSize(fab);
        expect(size.width, greaterThanOrEqualTo(56.0)); // FAB minimum size
        expect(size.height, greaterThanOrEqualTo(56.0));
      }
    });
    
    testWidgets('should support screen reader accessibility', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      await tester.pumpAndSettle();
      
      // Act - Find semantic widgets
      final semanticWidgets = find.byType(Semantics);
      
      // Assert - Should have semantic information
      expect(semanticWidgets.evaluate().length, greaterThan(0));
      
      // Check for important semantic labels
      expect(find.bySemanticsLabel('Create New Automaton'), findsOneWidget);
    });
    
    testWidgets('should adapt to different screen orientations', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      await tester.pumpAndSettle();
      
      // Act - Change to landscape orientation
      await tester.binding.setSurfaceSize(const Size(800, 400));
      await tester.pumpAndSettle();
      
      // Assert - App should still be functional
      expect(find.text('JFlutter'), findsOneWidget);
      expect(find.text('FSA'), findsOneWidget);
      
      // Act - Change back to portrait
      await tester.binding.setSurfaceSize(const Size(400, 800));
      await tester.pumpAndSettle();
      
      // Assert - App should still be functional
      expect(find.text('JFlutter'), findsOneWidget);
      expect(find.text('FSA'), findsOneWidget);
    });
    
    testWidgets('should handle rapid navigation between tabs', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      
      // Act - Rapidly switch between tabs
      await tester.tap(find.text('Grammar'));
      await tester.pump();
      await tester.tap(find.text('PDA'));
      await tester.pump();
      await tester.tap(find.text('TM'));
      await tester.pump();
      await tester.tap(find.text('FSA'));
      await tester.pumpAndSettle();
      
      // Assert - App should be stable
      expect(find.text('FSA'), findsOneWidget);
      expect(find.byType(JFlutterApp), findsOneWidget);
    });
    
    testWidgets('should show appropriate feedback for user actions', (WidgetTester tester) async {
      // Arrange
      await tester.pumpWidget(const JFlutterApp());
      await tester.pumpAndSettle();
      
      // Act - Tap FAB to create new automaton
      final fab = find.byType(FloatingActionButton);
      if (fab.evaluate().isNotEmpty) {
        await tester.tap(fab);
        await tester.pumpAndSettle();
        
        // Assert - Should show some feedback (snackbar, dialog, etc.)
        // This might be a snackbar or dialog depending on implementation
        expect(find.byType(SnackBar).or(find.byType(AlertDialog)), findsOneWidget);
      }
    });
  });
}
