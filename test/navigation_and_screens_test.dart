import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex/screens/main_shell.dart';
import 'package:tradex/screens/mega_draw_info_screen.dart';
import 'package:tradex/screens/my_tickets_screen.dart';
import 'package:tradex/screens/results_screen.dart';
import 'package:tradex/theme/app_theme.dart';
import 'package:tradex/widgets/custom_bottom_nav.dart';

void main() {
  Widget createTestWidget(Widget child) {
    return MaterialApp(theme: AppTheme.darkTheme, home: child);
  }

  group('CustomBottomNav Tests', () {
    testWidgets('renders all 5 nav items', (tester) async {
      int tappedIndex = -1;
      await tester.pumpWidget(
        createTestWidget(
          Scaffold(
            bottomNavigationBar: CustomBottomNav(
              currentIndex: 0,
              onTap: (index) => tappedIndex = index,
            ),
          ),
        ),
      );

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Tickets'), findsOneWidget);
      expect(find.text('Results'), findsOneWidget);
      expect(find.text('Wallet'), findsOneWidget);
      expect(find.text('Profile'), findsOneWidget);

      // Tap on Tickets
      await tester.tap(find.text('Tickets'));
      expect(tappedIndex, 1);

      // Tap on Results
      await tester.tap(find.text('Results'));
      expect(tappedIndex, 2);
    });
  });

  group('MainShell Tests', () {
    testWidgets('renders MainShell and switches tabs', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const MainShell()));
      await tester.pumpAndSettle();

      // Home tab by default
      expect(find.text('CHOOSE YOUR DRAW'), findsOneWidget);

      // Tap on Tickets tab in bottom navigation
      await tester.tap(
        find.descendant(
          of: find.byType(CustomBottomNav),
          matching: find.text('Tickets'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('My Tickets'), findsOneWidget);

      // Tap on Results tab
      await tester.tap(
        find.descendant(
          of: find.byType(CustomBottomNav),
          matching: find.text('Results'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Draw Results'), findsOneWidget);

      // Tap on Wallet tab
      await tester.tap(
        find.descendant(
          of: find.byType(CustomBottomNav),
          matching: find.text('Wallet'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Financial Breakdown'), findsOneWidget);

      // Tap on Profile tab
      await tester.tap(
        find.descendant(
          of: find.byType(CustomBottomNav),
          matching: find.text('Profile'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Personal Information'), findsOneWidget);
    });
  });

  group('MyTicketsScreen Tests', () {
    testWidgets('renders filter tabs and ticket cards', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const MyTicketsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('My Tickets'), findsOneWidget);
      expect(find.text('All Draws'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Won 🏆'), findsOneWidget);
      expect(find.text('BUY MORE TICKETS'), findsOneWidget);
    });
  });

  group('ResultsScreen Tests', () {
    testWidgets('renders results filter pills and view all button', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const ResultsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Draw Results'), findsOneWidget);
      expect(find.text('Hourly Draw'), findsWidgets);
      expect(find.text('Daily Draw'), findsWidgets);
      expect(find.text('Mega Draw'), findsWidgets);
      expect(find.text('VIEW ALL HISTORICAL DRAW RESULTS'), findsOneWidget);
    });
  });

  group('MegaDrawInfoScreen Tests', () {
    testWidgets('renders info banner, key information rows and promo card', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestWidget(const MegaDrawInfoScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mega Draw Rules & Prizes'), findsOneWidget);
      expect(find.text('How Mega Draw Works?'), findsOneWidget);
      expect(find.text('PRIZE TIER BREAKDOWN'), findsOneWidget);
      expect(find.text('Draw Schedule'), findsOneWidget);
      expect(find.text('Ticket Sale Period'), findsOneWidget);
      expect(find.text('Ticket Price'), findsOneWidget);
      expect(find.text('৳ 100 per Ticket'), findsOneWidget);
    });
  });
}
