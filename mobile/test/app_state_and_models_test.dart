import 'package:flutter_test/flutter_test.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/draw_result.dart';
import 'package:tradex/models/kyc_model.dart';
import 'package:tradex/models/payment_method_model.dart';
import 'package:tradex/models/transaction_model.dart';
import 'package:tradex/state/app_state.dart';

void main() {
  group('AppState Business Logic & State Mutations Unit Tests', () {
    late AppState appState;

    setUp(() {
      appState = AppState();
    });

    test('Initial state contains default balances and user fixtures', () {
      expect(appState.availableBalance > 0, true);
      expect(appState.lockedBalance > 0, true);
      expect(appState.walletBalance > 0, true);
      expect(appState.isLoggedIn, true);
      expect(appState.currentUser.username, 'shek_vip');
      expect(appState.purchasedTickets.isNotEmpty, true);
      expect(appState.notifications.isNotEmpty, true);
      expect(appState.savedPaymentMethods.isNotEmpty, true);
      expect(appState.transactions.isNotEmpty, true);
    });

    test('Tab index switching works as expected', () {
      expect(appState.currentTabIndex, 0);
      appState.setTabIndex(2);
      expect(appState.currentTabIndex, 2);
      appState.setTabIndex(4);
      expect(appState.currentTabIndex, 4);
      appState.setTabIndex(0);
      expect(appState.currentTabIndex, 0);
    });

    test('buyTicket debits wallet, creates ticket, and logs transaction', () {
      final initialBalance = appState.availableBalance;
      final initialTicketsCount = appState.purchasedTickets.length;
      final initialTransactionsCount = appState.transactions.length;

      final megaDraw = DrawModel.sampleDraws.firstWhere((d) => d.type == DrawType.mega);
      final ticket = appState.buyTicket(
        draw: megaDraw,
        number: '1234567',
        count: 2,
        unitPrice: 100,
        paymentMethod: 'wallet',
      );

      expect(ticket, isNotNull);
      expect(ticket!.number, '1234567');
      expect(ticket.count, 2);
      expect(ticket.totalAmount, 200);
      expect(appState.availableBalance, initialBalance - 200);
      expect(appState.purchasedTickets.length, initialTicketsCount + 1);
      expect(appState.transactions.length, initialTransactionsCount + 1);
    });

    test('buyTicket fails if balance is insufficient', () {
      final megaDraw = DrawModel.sampleDraws.firstWhere((d) => d.type == DrawType.mega);
      final ticket = appState.buyTicket(
        draw: megaDraw,
        number: '1234567',
        count: 500,
        unitPrice: 100,
        paymentMethod: 'wallet',
      );

      expect(ticket, isNull);
    });

    test('addMoneyDepositRequest credits balance and creates transaction', () {
      final initialAvailable = appState.availableBalance;
      final initialTransactions = appState.transactions.length;

      final txId = appState.addMoneyDepositRequest(
        amount: 500,
        providerName: 'bKash',
        senderAccount: '01711223344',
        transactionId: 'TRX99887766',
      );

      expect(txId.isNotEmpty, true);
      expect(appState.availableBalance, initialAvailable + 500);
      expect(appState.transactions.length, initialTransactions + 1);
      expect(appState.transactions.first.type, TransactionType.deposit);
      expect(appState.transactions.first.amount, 500);
    });

    test('withdrawMoney debits balance, applies 1.5% fee calculation, and logs transaction', () {
      final initialAvailable = appState.availableBalance;
      final requestedAmount = 100.0;
      final expectedFee = 1.5; // 1.5% of 100

      final txId = appState.withdrawMoney(
        amount: requestedAmount,
        providerName: 'Nagad',
        receiverAccount: '01811223344',
      );

      expect(txId, isNotNull);
      expect(appState.availableBalance, initialAvailable - requestedAmount);

      final withdrawTx = appState.transactions.firstWhere((t) => t.type == TransactionType.withdraw);
      expect(withdrawTx.amount, requestedAmount);
      expect(withdrawTx.fee, expectedFee);
    });

    test('withdrawMoney rejects amount exceeding available balance', () {
      final txId = appState.withdrawMoney(
        amount: 500000.0,
        providerName: 'Nagad',
        receiverAccount: '01811223344',
      );

      expect(txId, isNull);
    });

    test('sendMoneyToUser transfers funds with zero fee to valid recipient', () {
      final initialAvailable = appState.availableBalance;
      final transferAmount = 50.0;

      final txId = appState.sendMoneyToUser(
        recipientIdentifier: 'tanvir_pro',
        recipientName: 'Tanvir Hossain',
        amount: transferAmount,
        note: 'Prize share',
      );

      expect(txId, isNotNull);
      expect(appState.availableBalance, initialAvailable - transferAmount);

      final transferTx = appState.transactions.firstWhere((t) => t.type == TransactionType.transferSent);
      expect(transferTx.amount, transferAmount);
      expect(transferTx.fee, 0.0);
      expect(transferTx.title.contains('Tanvir Hossain'), true);
    });

    test('sendMoneyToUser rejects excessive amount exceeding balance', () {
      final txId = appState.sendMoneyToUser(
        recipientIdentifier: 'tanvir_pro',
        recipientName: 'Tanvir Hossain',
        amount: 999999.0,
      );
      expect(txId, isNull);
    });

    test('Winning number checker calculates 1st, 2nd, 3rd prize and no match', () {
      final megaResult = DrawResult.latestResults.firstWhere((r) => r.drawId == 'mega');
      final winningStr = megaResult.joinedWinningNumber;

      // 1st prize exact match
      final result1 = appState.checkWinningNumber('mega', winningStr);
      expect(result1['isWinner'], true);
      expect(result1['tier'], '1st Prize (Jackpot)');
      expect(result1['prize'], '৳ 5,00,000');

      // 2nd prize match (last 2 digits)
      final last2Digits = winningStr.substring(winningStr.length - 2);
      final numWith2DigitsMatch = '00000$last2Digits';
      final result2 = appState.checkWinningNumber('mega', numWith2DigitsMatch);
      expect(result2['isWinner'], true);
      expect(result2['tier'], '2nd Prize');

      // 3rd prize match (last 1 digit)
      final last1Digit = winningStr.substring(winningStr.length - 1);
      final numWith1DigitMatch = '000000$last1Digit';
      final result3 = appState.checkWinningNumber('mega', numWith1DigitMatch);
      expect(result3['isWinner'], true);
      expect(result3['tier'], '3rd Prize');

      // No match
      final resultMismatch = appState.checkWinningNumber('mega', '9999999');
      expect(resultMismatch['isWinner'], false);
    });

    test('Payment methods CRUD operations', () {
      final initialCount = appState.savedPaymentMethods.length;

      final newMethod = const PaymentMethodModel(
        id: 'pm_test_bkash',
        provider: PaymentProvider.bkash,
        providerName: 'bKash',
        accountNumber: '01999887766',
        accountHolderName: 'Shek Business',
        accountType: 'Merchant',
      );

      appState.addSavedPaymentMethod(newMethod);
      expect(appState.savedPaymentMethods.length, initialCount + 1);

      appState.setDefaultPaymentMethod(newMethod.id);
      expect(appState.savedPaymentMethods.firstWhere((m) => m.id == newMethod.id).isDefault, true);

      appState.removeSavedPaymentMethod(newMethod.id);
      expect(appState.savedPaymentMethods.any((m) => m.id == newMethod.id), false);
    });

    test('KYC submission workflow updates status to pending', () {
      appState.submitKyc(
        documentType: DocumentType.nid,
        documentNumber: '19901234567890',
        fullName: 'Shek Ahmmed',
        dateOfBirth: '1995-04-12',
      );

      expect(appState.kyc.status, KycStatus.pending);
      expect(appState.kyc.isPending, true);
    });

    test('Notifications mark as read and mark all as read', () {
      final unreadCountBefore = appState.unreadNotificationsCount;
      if (unreadCountBefore > 0) {
        final unreadNotif = appState.notifications.firstWhere((n) => !n.isRead);
        appState.markNotificationAsRead(unreadNotif.id);
        expect(appState.notifications.firstWhere((n) => n.id == unreadNotif.id).isRead, true);
      }

      appState.markAllNotificationsAsRead();
      expect(appState.unreadNotificationsCount, 0);
    });

    test('Auth login, logout and profile updates', () {
      appState.updateProfile(
        fullName: 'Shek Test Ahmmed',
        phone: '+880 1711223344',
        email: 'shek.new@tradex.com',
      );
      expect(appState.currentUser.fullName, 'Shek Test Ahmmed');
      expect(appState.currentUser.email, 'shek.new@tradex.com');

      appState.logout();
      expect(appState.isLoggedIn, false);

      final loginSuccess = appState.login('01711223344', 'Password123');
      expect(loginSuccess, true);
      expect(appState.isLoggedIn, true);
    });
  });
}
