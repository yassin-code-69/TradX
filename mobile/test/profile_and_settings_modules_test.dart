import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tradex/screens/help_support_screen.dart';
import 'package:tradex/screens/invite_earn_screen.dart';
import 'package:tradex/screens/kyc_screen.dart';
import 'package:tradex/screens/payment_methods_screen.dart';
import 'package:tradex/screens/profile_screen.dart';
import 'package:tradex/screens/security_screen.dart';
import 'package:tradex/screens/settings_screen.dart';
import 'package:tradex/screens/terms_policy_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_theme.dart';

void main() {
  Widget wrapWidget(Widget child) {
    return MaterialApp(
      theme: AppTheme.darkTheme,
      home: child,
    );
  }

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    AppState().updateProfile(
      fullName: 'Shek Ahmmed',
      phone: '+880 1712-345678',
      email: 'shekahmmed@email.com',
    );
  });

  group('TRADEX Profile & Sub-Modules Test Suite', () {
    testWidgets('ProfileScreen renders hero card, quick stats, and all menu sections', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      // User details
      expect(find.text('Shek Ahmmed'), findsOneWidget);
      expect(find.text('shekahmmed@email.com'), findsOneWidget);
      expect(find.text('+880 1XXXXXXXXX'), findsOneWidget);
      expect(find.textContaining('VERIF'), findsWidgets);

      // Quick Stats
      expect(find.text('Draws Played'), findsOneWidget);
      expect(find.text('Total Won'), findsOneWidget);
      expect(find.text('Active Tickets'), findsOneWidget);
      expect(find.text('Referrals'), findsOneWidget);

      // Menu items
      expect(find.text('Personal Information'), findsOneWidget);
      expect(find.text('Identity Verification (KYC)'), findsOneWidget);
      expect(find.text('Invite & Earn'), findsOneWidget);
      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('Security'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('Terms & Policies'), findsOneWidget);
      expect(find.text('LOGOUT'), findsOneWidget);

      // Tap Logout and check dialog
      await tester.tap(find.text('LOGOUT'));
      await tester.pumpAndSettle();
      expect(find.text('Confirm Logout'), findsOneWidget);
      expect(find.text('CANCEL'), findsOneWidget);

      // Dismiss dialog
      await tester.tap(find.text('CANCEL'));
      await tester.pumpAndSettle();
    });

    testWidgets('KycScreen multi-step verification and status tracking', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(const KycScreen(forceStartVerification: true)));
      await tester.pumpAndSettle();

      // Step 1: Personal Info
      expect(find.text('Step 1: Personal Information'), findsOneWidget);
      expect(find.text('Legal Full Name (as on ID)'), findsOneWidget);
      expect(find.text('CONTINUE'), findsOneWidget);

      // Advance to Step 2
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      expect(find.text('Step 2: Choose Document Type'), findsOneWidget);
      expect(find.text('National Identity Card (NID)'), findsOneWidget);
      expect(find.text('International Passport'), findsOneWidget);
      expect(find.text('Driving License'), findsOneWidget);

      // Advance to Step 3
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      expect(find.text('Step 3: Upload Document Photos'), findsOneWidget);
      expect(find.text('Front Side of ID'), findsOneWidget);

      // Simulate front upload
      await tester.tap(find.text('Tap to Capture / Choose Photo').first);
      await tester.pump();

      // Simulate back upload
      await tester.tap(find.text('Tap to Capture / Choose Photo').first);
      await tester.pump();

      // Advance to Step 4
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      expect(find.text('Step 4: Selfie Liveness Check'), findsOneWidget);
      expect(find.text('CAPTURE LIVE SELFIE'), findsOneWidget);

      // Capture selfie
      await tester.tap(find.text('CAPTURE LIVE SELFIE'));
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pumpAndSettle();
      expect(find.text('RETAKE SELFIE'), findsOneWidget);

      // Advance to Step 5
      await tester.tap(find.text('CONTINUE'));
      await tester.pumpAndSettle();
      expect(find.text('Step 5: Review & Submit'), findsOneWidget);
      expect(find.text('Identity Summary'), findsOneWidget);
      expect(find.text('SUBMIT KYC'), findsOneWidget);
    });

    testWidgets('InviteEarnScreen renders code, copy action, tier bar and friend list', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(const InviteEarnScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Earn ৳ 100 per Friend!'), findsOneWidget);
      expect(find.text('TRADEX777'), findsOneWidget);
      expect(find.text('COPY'), findsOneWidget);
      expect(find.text('SHARE INVITATION LINK'), findsOneWidget);
      expect(find.text('Friends Invited'), findsOneWidget);
      expect(find.text('Total Earned'), findsOneWidget);
      expect(find.text('VIP Referral Tier'), findsOneWidget);
      expect(find.text('How It Works'), findsOneWidget);

      // Tap Copy
      await tester.tap(find.text('COPY'));
      await tester.pump();
    });

    testWidgets('PaymentMethodsScreen lists saved methods and opens Add Method sheet', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(const PaymentMethodsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Payment Methods'), findsOneWidget);
      expect(find.text('ADD NEW PAYMENT METHOD'), findsOneWidget);

      // Open Add Method Sheet
      await tester.tap(find.text('ADD NEW PAYMENT METHOD'));
      await tester.pumpAndSettle();

      expect(find.text('Add Payment Method'), findsOneWidget);
      expect(find.text('Account Holder Name'), findsOneWidget);
      expect(find.text('SAVE PAYMENT METHOD'), findsOneWidget);
    });

    testWidgets('SecurityScreen renders 2FA, biometrics, PIN setup and session logout', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(const SecurityScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Security & 2FA'), findsOneWidget);
      expect(find.text('Two-Factor Authentication (2FA)'), findsOneWidget);
      expect(find.text('Biometric Unlock'), findsOneWidget);
      expect(find.text('App Security PIN'), findsOneWidget);
      expect(find.text('CHANGE PASSWORD'), findsOneWidget);
      expect(find.text('UPDATE PASSWORD'), findsOneWidget);

      // Open PIN setup modal
      await tester.tap(find.text('App Security PIN'));
      await tester.pumpAndSettle();

      expect(find.text('Setup App Security PIN'), findsOneWidget);
    });

    testWidgets('HelpSupportScreen and SupportChatScreen interactive flows', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(const HelpSupportScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Help & Support'), findsOneWidget);
      expect(find.text('24/7 VIP Live Chat'), findsOneWidget);
      expect(find.text('START LIVE CHAT'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Telegram'), findsOneWidget);

      // Open Live Chat
      await tester.tap(find.text('START LIVE CHAT'));
      await tester.pumpAndSettle();

      expect(find.text('Sarah (Tradex VIP Support)'), findsOneWidget);
      expect(find.text('Where is my withdrawal?'), findsOneWidget);

      // Tap query pill
      await tester.tap(find.text('Where is my withdrawal?'));
      await tester.pump(const Duration(milliseconds: 2000));
      await tester.pumpAndSettle();
    });

    testWidgets('SettingsScreen language, sound, and cache clear flows', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(const SettingsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('App Settings'), findsOneWidget);
      expect(find.text('English'), findsOneWidget);
      expect(find.text('বাংলা'), findsOneWidget);
      expect(find.text('Sound Effects'), findsOneWidget);
      expect(find.text('Haptic Feedback'), findsOneWidget);
      expect(find.text('Clear App Cache'), findsOneWidget);
      expect(find.text('CLEAR'), findsOneWidget);

      // Switch language to Bengali
      await tester.tap(find.text('বাংলা'));
      await tester.pumpAndSettle();
      expect(AppState().selectedLanguage, 'বাংলা');

      // Clear cache
      await tester.tap(find.text('CLEAR'));
      await tester.pumpAndSettle();
      expect(find.text('Clear Temporary Cache'), findsOneWidget);
      await tester.tap(find.text('CLEAR NOW'));
      await tester.pumpAndSettle();
    });

    testWidgets('TermsPolicyScreen displays all 4 tabs and legal sections', (tester) async {
      tester.view.physicalSize = const Size(800, 1600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(wrapWidget(const TermsPolicyScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Terms & Legal Policy'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Draw & Fair Play Rules'), findsOneWidget);
      expect(find.text('Responsible Gaming'), findsOneWidget);

      // Switch to Privacy Policy
      await tester.tap(find.text('Privacy Policy'));
      await tester.pumpAndSettle();
      expect(find.text('1. Information We Collect'), findsOneWidget);

      // Switch to Draw & Fair Play Rules
      await tester.tap(find.text('Draw & Fair Play Rules'));
      await tester.pumpAndSettle();
      expect(find.text('1. Certified Hardware Random Number Generation (RNG)'), findsOneWidget);

      // Switch to Responsible Gaming
      await tester.tap(find.text('Responsible Gaming'));
      await tester.pumpAndSettle();
      expect(find.text('1. Strict 18+ Age Requirement'), findsOneWidget);
    });
  });
}
