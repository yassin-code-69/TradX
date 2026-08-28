import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/screens/daily_draw_screen.dart';
import 'package:tradex/screens/hourly_draw_screen.dart';
import 'package:tradex/screens/mega_draw_info_screen.dart';
import 'package:tradex/screens/mega_draw_screen.dart';
import 'package:tradex/screens/payment_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/widgets/payment_logos.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('Payment Logos Tests', () {
    testWidgets('NagadLogo renders with text and badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NagadLogo(),
          ),
        ),
      );

      expect(find.text('নগদ'), findsOneWidget);
      expect(find.byType(NagadBadgeIcon), findsOneWidget);
    });

    testWidgets('BKashLogo renders with text and badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BKashLogo(),
          ),
        ),
      );

      expect(find.text('বিকাশ'), findsOneWidget);
      expect(find.byType(BKashBadgeIcon), findsOneWidget);
    });

    testWidgets('RocketLogo renders with text and badge', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: RocketLogo(),
          ),
        ),
      );

      expect(find.text('Rocket'), findsOneWidget);
      expect(find.byType(RocketBadgeIcon), findsOneWidget);
    });
  });

  group('PaymentScreen Tests', () {
    testWidgets('renders Order Summary, payment methods and pay button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: PaymentScreen(
            draw: DrawModel.sampleDraws[0], // Mega Draw
            selectedNumber: '1234567',
            ticketCount: 2,
            ticketPrice: 100,
          ),
        ),
      );

      // Order Summary validation
      expect(find.text('Order Summary'), findsOneWidget);
      expect(find.text('Draw Type'), findsOneWidget);
      expect(find.text('Mega Draw'), findsOneWidget);
      expect(find.text('1 2 3 4 5 6 7'), findsOneWidget);
      expect(find.text('Ticket Price (৳ 100 × 2)'), findsOneWidget);
      expect(find.text('৳ 200'), findsNWidgets(2)); // Ticket price and Total Amount
      expect(find.text('Total Tickets'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);

      // Payment methods
      expect(find.text('Select Payment Method'), findsOneWidget);
      expect(find.text('নগদ'), findsOneWidget);
      expect(find.text('বিকাশ'), findsOneWidget);
      expect(find.text('Rocket'), findsOneWidget);

      // Button and footnote
      expect(find.text('PAY ৳ 200'), findsOneWidget);
      expect(find.text('Secure Payment'), findsOneWidget);
    });

    testWidgets('allows switching payment method and completes purchase', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final initialTicketCount = AppState().purchasedTickets.length;

      await tester.pumpWidget(
        MaterialApp(
          home: PaymentScreen(
            draw: DrawModel.sampleDraws[0],
            selectedNumber: '7654321',
            ticketCount: 1,
            ticketPrice: 100,
          ),
        ),
      );

      // Tap on bKash
      await tester.tap(find.text('বিকাশ'));
      await tester.pump();

      // Tap PAY
      await tester.tap(find.text('PAY ৳ 100'));
      await tester.pump(); // Start processing
      await tester.pump(const Duration(milliseconds: 1000)); // Finish delay
      await tester.pumpAndSettle();

      // Should show success dialog
      expect(find.text('Ticket Purchased!'), findsOneWidget);
      expect(find.text('DONE'), findsOneWidget);

      // Check AppState updated
      expect(AppState().purchasedTickets.length, initialTicketCount + 1);

      // Tap DONE
      await tester.tap(find.text('DONE'));
      await tester.pumpAndSettle();
    });
  });

  group('MegaDrawScreen Tests', () {
    testWidgets('renders all UI elements and keypad interaction', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MegaDrawScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Mega Draw'), findsOneWidget);
      expect(find.text('MEGA DRAW JACKPOT'), findsOneWidget);
      expect(find.text('1st of Every Month • Guaranteed ৳ 5,00,000 Winner'), findsOneWidget);
      expect(find.text('01 Sep 2026 | 09:00 PM'), findsOneWidget);
      expect(find.text('SELECT 7 DIGIT COMBINATION'), findsOneWidget);
      expect(find.text('Ticket Price'), findsOneWidget);
      expect(find.text('৳ 100 / tkt'), findsOneWidget);
      expect(find.text('BUY TICKET • ৳ 100'), findsOneWidget);
      expect(find.text('View guaranteed prize tiers & rules'), findsOneWidget);

      // Quick Pick fills 7 digits
      await tester.tap(find.text('Quick Pick'));
      await tester.pump(const Duration(milliseconds: 100));

      // Total tickets increment
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('BUY TICKET • ৳ 200'), findsOneWidget);

      // Navigate to TicketPurchaseScreen
      await tester.tap(find.text('BUY TICKET • ৳ 200'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Review & Buy Ticket'), findsOneWidget);
    });
  });

  group('DailyDrawScreen Tests', () {
    testWidgets('renders Daily Draw with 3 digits and green style', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: DailyDrawScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Daily Draw'), findsOneWidget);
      expect(find.text('10:00 PM'), findsOneWidget);
      expect(find.text('৳ 50,000'), findsOneWidget);
      expect(find.text('SELECT 3 DIGIT NUMBER (000 - 999)'), findsOneWidget);
      expect(find.text('৳ 60 / tkt'), findsOneWidget);
      expect(find.text('BUY TICKET • ৳ 60'), findsOneWidget);
      expect(find.text('Today 10:00 PM  •  Watch Live Draw'), findsOneWidget);

      // Type 3 digits: 5, 8, 2
      await tester.tap(find.text('5'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('8'));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.tap(find.text('2'));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('5'), findsNWidgets(2)); // Keypad + slot
      expect(find.text('8'), findsNWidgets(2)); // Keypad + slot
      expect(find.text('2'), findsNWidgets(2)); // Keypad + slot

      // Navigate to TicketPurchaseScreen
      await tester.tap(find.text('BUY TICKET • ৳ 60'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Review & Buy Ticket'), findsOneWidget);
    });
  });

  group('HourlyDrawScreen Tests', () {
    testWidgets('renders Hourly Draw with countdown and magenta button', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: HourlyDrawScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Hourly Draw'), findsOneWidget);
      expect(find.text('Next Draw In'), findsOneWidget);
      expect(find.text('৳ 20,000'), findsOneWidget);
      expect(find.text('RAPID 3-DIGIT SELECTOR'), findsOneWidget);
      expect(find.text('৳ 20 / tkt'), findsOneWidget);
      expect(find.text('BUY TICKET • ৳ 20'), findsOneWidget);
      expect(find.text('Every Hour  •  Watch Live Stream'), findsOneWidget);

      // Quick Pick
      await tester.tap(find.text('Quick Pick'));
      await tester.pump(const Duration(milliseconds: 100));

      // Navigate to TicketPurchaseScreen
      await tester.tap(find.text('BUY TICKET • ৳ 20'));
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Review & Buy Ticket'), findsOneWidget);
      expect(find.text('Hourly Draw'), findsWidgets);
    });
  });

  group('MegaDrawInfoScreen Tests', () {
    testWidgets('renders key information and cards', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: MegaDrawInfoScreen(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

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
