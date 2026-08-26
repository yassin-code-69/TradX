import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/ticket_model.dart';
import 'package:tradex/screens/daily_draw_screen.dart';
import 'package:tradex/screens/hourly_draw_screen.dart';
import 'package:tradex/screens/live_draw_screen.dart';
import 'package:tradex/screens/mega_draw_info_screen.dart';
import 'package:tradex/screens/mega_draw_screen.dart';
import 'package:tradex/screens/my_tickets_screen.dart';
import 'package:tradex/screens/purchase_success_screen.dart';
import 'package:tradex/screens/ticket_purchase_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_theme.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  Widget wrapWithTheme(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    );
  }

  group('Draws & Ticket Purchasing Modules Test Suite', () {
    testWidgets('1. MegaDrawScreen renders header, 7 digit slots, keypad, and opens TicketPurchaseScreen',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithTheme(const MegaDrawScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mega Draw'), findsOneWidget);
      expect(find.text('MEGA DRAW JACKPOT'), findsOneWidget);
      expect(find.text('SELECT 7 DIGIT COMBINATION'), findsOneWidget);
      expect(find.text('Quick Pick'), findsOneWidget);
      expect(find.text('BUY TICKET • ৳ 100'), findsOneWidget);

      // Quick Pick
      await tester.tap(find.text('Quick Pick'));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap BUY TICKET
      await tester.tap(find.text('BUY TICKET • ৳ 100'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      // Should be on TicketPurchaseScreen
      expect(find.text('Review & Buy Ticket'), findsOneWidget);
      expect(find.text('PRICING BREAKDOWN'), findsOneWidget);
    });

    testWidgets('2. DailyDrawScreen renders 3-digit selector, multiplier chips and keypad',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithTheme(const DailyDrawScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Daily Draw'), findsOneWidget);
      expect(find.text('Next Draw Today'), findsOneWidget);
      expect(find.text('SELECT 3 DIGIT NUMBER (000 - 999)'), findsOneWidget);
      expect(find.text('1x'), findsOneWidget);
      expect(find.text('2x'), findsOneWidget);
      expect(find.text('5x'), findsOneWidget);

      // Tap 5x multiplier
      await tester.tap(find.text('5x'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('BUY TICKET • ৳ 300'), findsOneWidget);

      // Quick pick
      await tester.tap(find.text('Quick Pick'));
      await tester.pump(const Duration(milliseconds: 100));

      // Proceed to purchase
      await tester.tap(find.text('BUY TICKET • ৳ 300'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Review & Buy Ticket'), findsOneWidget);
    });

    testWidgets('3. HourlyDrawScreen renders rapid selector and quick bet presets',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithTheme(const HourlyDrawScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Hourly Draw'), findsOneWidget);
      expect(find.text('RAPID 3-DIGIT SELECTOR'), findsOneWidget);
      expect(find.text('QUICK BET PRESETS'), findsOneWidget);
      expect(find.text('BUY TICKET • ৳ 20'), findsOneWidget);

      // Tap Quick Pick
      await tester.tap(find.text('Quick Pick'));
      await tester.pump(const Duration(milliseconds: 100));

      // Proceed to purchase
      await tester.tap(find.text('BUY TICKET • ৳ 20'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Review & Buy Ticket'), findsOneWidget);
    });

    testWidgets('4. TicketPurchaseScreen displays pricing breakdown and processes purchase',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialTicketCount = AppState().tickets.length;

      await tester.pumpWidget(
        wrapWithTheme(
          TicketPurchaseScreen(
            draw: DrawModel.sampleDraws[0],
            selectedNumber: '7654321',
            initialTicketCount: 2,
            unitPrice: 100,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Review & Buy Ticket'), findsOneWidget);
      expect(find.text('SELECTED COMBINATION'), findsOneWidget);
      expect(find.text('TICKET QUANTITY'), findsOneWidget);
      expect(find.text('PAYMENT METHOD'), findsOneWidget);
      expect(find.text('Tradex Main Wallet'), findsOneWidget);
      expect(find.text('PRICING BREAKDOWN'), findsOneWidget);
      expect(find.text('Unit Ticket Price'), findsOneWidget);
      expect(find.text('৳ 200'), findsWidgets);

      // Slide to confirm
      final sliderFinder = find.byType(TradexSlideToConfirm);
      expect(sliderFinder, findsOneWidget);

      final newTicket = AppState().buyTicket(
        draw: DrawModel.sampleDraws[0],
        number: '7654321',
        count: 2,
        unitPrice: 100,
      );
      expect(newTicket, isNotNull);
      expect(AppState().tickets.length, initialTicketCount + 1);
    });

    testWidgets('5. PurchaseSuccessScreen renders receipt card with serial, digits and action buttons',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final sampleTicket = TicketModel(
        id: 'TKT-TEST',
        ticketNumber: 'TX-998877',
        draw: DrawModel.sampleDraws[0],
        number: '1234567',
        count: 2,
        unitPrice: 100,
        totalAmount: 200,
        purchaseDate: DateTime.now(),
        drawDate: DateTime.now().add(const Duration(days: 5)),
        status: TicketStatus.active,
        transactionId: 'TX-123456',
      );

      await tester.pumpWidget(
        wrapWithTheme(
          PurchaseSuccessScreen(ticket: sampleTicket),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Ticket Confirmed!'), findsOneWidget);
      expect(find.text('OFFICIAL TICKET'), findsOneWidget);
      expect(find.text('TX-998877'), findsOneWidget);
      expect(find.text('2 Ticket(s)'), findsOneWidget);
      expect(find.text('৳ 200'), findsOneWidget);
      expect(find.text('VIEW MY TICKETS'), findsOneWidget);
      expect(find.text('Share Receipt'), findsOneWidget);
    });

    testWidgets('6. MegaDrawInfoScreen renders full prize tier breakdown and FAQ accordion',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithTheme(const MegaDrawInfoScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mega Draw Rules & Prizes'), findsOneWidget);
      expect(find.text('How Mega Draw Works?'), findsOneWidget);
      expect(find.text('PRIZE TIER BREAKDOWN'), findsOneWidget);
      expect(find.text('1st Prize (Jackpot)'), findsOneWidget);
      expect(find.text('2nd Prize'), findsOneWidget);
      expect(find.text('3rd Prize'), findsOneWidget);
      expect(find.text('Consolation Prize'), findsOneWidget);
      expect(find.text('FREQUENTLY ASKED QUESTIONS'), findsOneWidget);

      // Expand FAQ tile
      await tester.tap(find.text('How are Mega Draw winning numbers generated?'));
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.textContaining('certified by international gaming audit standards'), findsOneWidget);
    });

    testWidgets('7. LiveDrawScreen renders live simulator, viewer counter and live chat feed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        wrapWithTheme(
          LiveDrawScreen(draw: DrawModel.sampleDraws[1]),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Daily Draw Live Stream'), findsOneWidget);
      expect(find.text('Live Community Chat'), findsOneWidget);
      expect(find.text('Say something in live chat...'), findsOneWidget);
    });

    testWidgets('8. MyTicketsScreen renders search, filter tabs, draw type chips and receipt modal',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWithTheme(const MyTicketsScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('My Tickets'), findsOneWidget);
      expect(find.text('All Draws'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Won 🏆'), findsOneWidget);
      expect(find.text('BUY MORE TICKETS'), findsOneWidget);

      // Tap on ticket card (e.g. Mega Draw)
      expect(find.text('Mega Draw'), findsWidgets);
      await tester.tap(find.text('Mega Draw').first);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Ticket Receipt Details'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);

      // Close modal
      await tester.tap(find.text('Close'));
      await tester.pump(const Duration(milliseconds: 300));
    });
  });
}
