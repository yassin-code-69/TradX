import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex/screens/home_screen.dart';
import 'package:tradex/screens/profile_screen.dart';
import 'package:tradex/screens/wallet_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_theme.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    );
  }

  group('Wallet, Profile & Home Screen Tests', () {
    testWidgets('HomeScreen renders all essential components', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(const HomeScreen()));
      await tester.pumpAndSettle();

      // App bar & subtitle
      expect(find.text('TRADEX'), findsOneWidget);
      expect(find.text('PLAY · WIN · REPEAT'), findsOneWidget);

      // Balance Card
      expect(find.text('Wallet Balance'), findsWidgets);

      // Choose Your Draw
      expect(find.text('CHOOSE YOUR DRAW'), findsOneWidget);
      expect(find.text('Mega Draw'), findsWidgets);
      expect(find.text('Daily Draw'), findsWidgets);
      expect(find.text('Hourly Draw'), findsWidgets);
      expect(find.text('HOT'), findsOneWidget);

      // Latest Results
      expect(find.text('LATEST RESULTS'), findsOneWidget);
      expect(find.text('See All'), findsOneWidget);
      expect(find.textContaining('09:00 PM'), findsWidgets);
    });

    testWidgets('WalletScreen renders balance, action buttons and transactions', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(const WalletScreen()));
      await tester.pumpAndSettle();

      // Total balance
      expect(find.text('TOTAL BALANCE'), findsOneWidget);
      expect(find.text('2,540.50'), findsOneWidget);

      // Buttons
      expect(find.text('ADD MONEY'), findsOneWidget);
      expect(find.text('WITHDRAW'), findsOneWidget);

      // Transaction History
      expect(find.text('Recent Transactions'), findsOneWidget);
      expect(find.text('View All'), findsOneWidget);
      expect(find.text('Financial Breakdown'), findsOneWidget);
    });

    testWidgets('ProfileScreen renders user profile and all 7 menu items', (tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      // User details
      expect(find.text('Shek Ahmmed'), findsOneWidget);
      expect(find.text('shekahmmed@email.com'), findsOneWidget);
      expect(find.text('✓ VERIFIED'), findsWidgets);

      // 7 Menu items
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Invite & Earn'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);

      // Logout button
      expect(find.text('LOGOUT'), findsOneWidget);
    });

    test('AppState reactive transactions and operations', () {
      final state = AppState();
      final initialBalance = state.walletBalance;

      state.addMoney(500, 'TestNagad');
      expect(state.walletBalance, initialBalance + 500);
      expect(state.transactions.first.title, contains('Add Money'));

      final success = state.withdraw(200, 'TestBkash');
      expect(success, true);
      expect(state.walletBalance, initialBalance + 300);
    });
  });
}
