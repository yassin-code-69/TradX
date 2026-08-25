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
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    );
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
      await tester.pumpWidget(
        createTestWidget(const MainShell()),
      );
      await tester.pumpAndSettle();

      // Home tab by default
      expect(find.text('CHOOSE YOUR DRAW'), findsOneWidget);

      // Tap on Tickets tab in bottom navigation
      await tester.tap(find.descendant(of: find.byType(CustomBottomNav), matching: find.text('Tickets')));
      await tester.pumpAndSettle();
      expect(find.text('My Tickets'), findsOneWidget);

      // Tap on Results tab
      await tester.tap(find.descendant(of: find.byType(CustomBottomNav), matching: find.text('Results')));
      await tester.pumpAndSettle();
      expect(find.text('VIEW ALL RESULTS'), findsOneWidget);

      // Tap on Wallet tab
      await tester.tap(find.descendant(of: find.byType(CustomBottomNav), matching: find.text('Wallet')));
      await tester.pumpAndSettle();
      expect(find.text('Wallet Summary'), findsOneWidget);

      // Tap on Profile tab
      await tester.tap(find.descendant(of: find.byType(CustomBottomNav), matching: find.text('Profile')));
      await tester.pumpAndSettle();
      expect(find.text('Personal Information'), findsOneWidget);
    });
  });

  group('MyTicketsScreen Tests', () {
    testWidgets('renders filter tabs and ticket cards', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const MyTicketsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Tickets'), findsOneWidget);
      expect(find.text('Hourly'), findsOneWidget);
      expect(find.text('Daily'), findsOneWidget);
      expect(find.text('Mega'), findsOneWidget);
      expect(find.text('BUY MORE TICKETS'), findsOneWidget);

      // Filter to Daily
      await tester.tap(find.text('Daily'));
      await tester.pumpAndSettle();
      expect(find.text('Daily Draw'), findsWidgets);

      // Filter to Hourly
      await tester.tap(find.text('Hourly'));
      await tester.pumpAndSettle();
      expect(find.text('Hourly Draw'), findsWidgets);
    });
  });

  group('ResultsScreen Tests', () {
    testWidgets('renders results filter pills and view all button', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const ResultsScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Results'), findsOneWidget);
      expect(find.text('Hourly Results'), findsOneWidget);
      expect(find.text('Daily Results'), findsOneWidget);
      expect(find.text('Mega Results'), findsOneWidget);
      expect(find.text('VIEW ALL RESULTS'), findsOneWidget);
    });
  });

  group('MegaDrawInfoScreen Tests', () {
    testWidgets('renders info banner, key information rows and promo card', (tester) async {
      await tester.pumpWidget(
        createTestWidget(const MegaDrawInfoScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Mega Draw Info'), findsOneWidget);
      expect(find.text('How Mega Draw Works?'), findsOneWidget);
      expect(find.text('Key Information'), findsOneWidget);
      expect(find.text('Draw Date'), findsOneWidget);
      expect(find.text('1st of Every Month'), findsOneWidget);
      expect(find.text('Ticket Sale Period'), findsOneWidget);
      expect(find.text('2nd - 30th of Every Month'), findsOneWidget);
      expect(find.text('Draw Time'), findsOneWidget);
      expect(find.text('09:00 PM'), findsOneWidget);
      expect(find.text('Prize'), findsOneWidget);
      expect(find.text('৳ 5,00,000'), findsOneWidget);
      expect(find.text('Winners'), findsOneWidget);
      expect(find.text('1 Winner'), findsOneWidget);
      expect(find.text('Ticket Price'), findsOneWidget);
      expect(find.text('৳ 100 per Ticket'), findsOneWidget);
      expect(find.text('More tickets, more chances!'), findsOneWidget);
    });
  });
}
