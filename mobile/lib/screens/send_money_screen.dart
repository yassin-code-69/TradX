import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class SendMoneyScreen extends StatefulWidget {
  final String? initialRecipient;

  const SendMoneyScreen({super.key, this.initialRecipient});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  final TextEditingController _recipientController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();
  final AppState _appState = AppState();

  final List<int> _presetAmounts = [100, 500, 1000, 2000];

  // Mock list of registered users for real-time recipient lookup
  final List<Map<String, dynamic>> _registeredUsers = [
    {
      'username': 'shakib_75',
      'name': 'Shakib Al Hasan',
      'phone': '01711-223344',
      'avatar': '👑',
      'isVerified': true,
      'tier': 'VIP Gold',
    },
    {
      'username': 'tanvir_boss',
      'name': 'Tanvir Ahmed',
      'phone': '01988-776655',
      'avatar': '⭐',
      'isVerified': true,
      'tier': 'VIP Platinum',
    },
    {
      'username': 'fahim_dhaka',
      'name': 'Fahim Rahman',
      'phone': '01855-443322',
      'avatar': '🚀',
      'isVerified': true,
      'tier': 'Standard Member',
    },
    {
      'username': 'rashed_dhaka',
      'name': 'Rashed Khan',
      'phone': '01622-334455',
      'avatar': '🎯',
      'isVerified': true,
      'tier': 'VIP Gold',
    },
    {
      'username': 'shek_vip',
      'name': 'Shek Ahmmed',
      'phone': '01712-345678',
      'avatar': '💎',
      'isVerified': true,
      'tier': 'VIP Platinum',
    },
  ];

  Map<String, dynamic>? _selectedRecipient;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialRecipient != null && widget.initialRecipient!.isNotEmpty) {
      _recipientController.text = widget.initialRecipient!;
      _lookupRecipient(widget.initialRecipient!);
    } else {
      // Default to first contact for immediate delightful preview
      _selectRecipient(_registeredUsers.first);
    }
  }

  @override
  void dispose() {
    _recipientController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _lookupRecipient(String query) {
    final cleanQuery = query.trim().replaceAll('@', '').toLowerCase();
    if (cleanQuery.isEmpty) {
      setState(() => _selectedRecipient = null);
      return;
    }

    final match = _registeredUsers.firstWhere(
      (u) =>
          u['username'].toString().toLowerCase().contains(cleanQuery) ||
          u['phone'].toString().replaceAll('-', '').contains(cleanQuery) ||
          u['name'].toString().toLowerCase().contains(cleanQuery),
      orElse: () => {
        'username': cleanQuery,
        'name': '$cleanQuery (User)',
        'phone': '017**-******',
        'avatar': '👤',
        'isVerified': false,
        'tier': 'TRADEX User',
      },
    );

    setState(() {
      _selectedRecipient = match;
    });
  }

  void _selectRecipient(Map<String, dynamic> user) {
    setState(() {
      _selectedRecipient = user;
      _recipientController.text = '@${user['username']}';
    });
    HapticFeedback.selectionClick();
  }

  double get _enteredAmount {
    return double.tryParse(_amountController.text.trim()) ?? 0.0;
  }

  bool get _isAmountValid {
    final amt = _enteredAmount;
    return amt > 0 && amt <= _appState.availableBalance;
  }

  void _handleTransfer() async {
    final amount = _enteredAmount;
    if (_selectedRecipient == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a valid recipient'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an amount greater than ৳ 0'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    if (amount > _appState.availableBalance) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insufficient available balance for this transfer'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);
    await Future.delayed(const Duration(milliseconds: 900));

    final recipientUsername = _selectedRecipient!['username'].toString();
    final recipientFullName = _selectedRecipient!['name'].toString();
    final note = _noteController.text.trim();

    final txId = _appState.sendMoneyToUser(
      recipientIdentifier: recipientUsername,
      recipientName: recipientFullName,
      amount: amount,
      note: note.isNotEmpty ? note : null,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (txId != null) {
      HapticFeedback.heavyImpact();
      _showSuccessReceiptModal(
        txId: txId,
        recipient: _selectedRecipient!,
        amount: amount,
        note: note,
      );
    }
  }

  void _showSuccessReceiptModal({
    required String txId,
    required Map<String, dynamic> recipient,
    required double amount,
    required String note,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      isDismissible: false,
      enableDrag: false,
      builder: (ctx) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border(
              top: BorderSide(color: AppColors.cardBorderHighlight, width: 1.5),
            ),
          ),
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).padding.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pull Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),

              // Success Icon with Radiant Aura
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.greenAccent.withValues(alpha: 0.15),
                  border: Border.all(
                    color: AppColors.greenAccent.withValues(alpha: 0.5),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.greenAccent.withValues(alpha: 0.35),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: AppColors.greenLight,
                  size: 36,
                ),
              ),
              const SizedBox(height: 12),

              Text(
                'Transfer Successful!',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Funds instantly transferred to recipient wallet',
                style: GoogleFonts.inter(
                  fontSize: 12.5,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Tradex Digital Receipt Card
              TradexReceiptCard(
                title: 'Money Sent To @${recipient['username']}',
                status: 'COMPLETED',
                statusColor: AppColors.greenLight,
                amount: '৳ ${amount.toStringAsFixed(2)}',
                idLabel: 'TRANSACTION ID',
                idValue: txId,
                details: [
                  MapEntry('Recipient Name', recipient['name'].toString()),
                  MapEntry('Recipient Phone', recipient['phone'].toString()),
                  MapEntry('Platform Transfer Fee', '৳ 0.00 (Free)'),
                  if (note.isNotEmpty) MapEntry('Note', note),
                  MapEntry('Date & Time', 'Just now'),
                ],
                onCopyId: () {
                  Clipboard.setData(ClipboardData(text: txId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Transaction ID copied to clipboard!'),
                      backgroundColor: AppColors.greenDark,
                    ),
                  );
                },
                onShare: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Receipt shared with recipient!'),
                      backgroundColor: AppColors.cardBgElevated,
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // Back to Wallet Button
              TradexButton(
                text: 'DONE / BACK TO WALLET',
                variant: TradexButtonVariant.primaryGold,
                height: 50,
                onPressed: () {
                  Navigator.pop(ctx); // close modal
                  Navigator.pop(context); // close send money screen
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Send Money',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.cardBgElevated,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.cardBorderHighlight),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, size: 14, color: AppColors.cyanAccent),
                const SizedBox(width: 4),
                Text(
                  '0% Fee',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.cyanAccent,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Balance Summary Card (Reactive)
              ListenableBuilder(
                listenable: _appState,
                builder: (context, _) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0F1E2E), Color(0xFF09121B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.cyanAccent.withValues(alpha: 0.35),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyanAccent.withValues(alpha: 0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  'Available Balance',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: const BoxDecoration(
                                    color: AppColors.greenLight,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '৳ ${_appState.formattedAvailableBalance}',
                              style: GoogleFonts.poppins(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Locked: ৳ ${_appState.formattedLockedBalance}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.goldAccent,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Total: ৳ ${_appState.formattedBalance}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              // 2. Recipient Search & Input Section
              Text(
                'Recipient Details',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Search Text Field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorderHighlight),
                ),
                child: TextField(
                  controller: _recipientController,
                  onChanged: _lookupRecipient,
                  style: GoogleFonts.inter(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.alternate_email_rounded,
                      color: AppColors.cyanAccent,
                      size: 20,
                    ),
                    suffixIcon: _recipientController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _recipientController.clear();
                              _lookupRecipient('');
                            },
                          )
                        : null,
                    hintText: 'Enter username or phone (e.g. shakib_75)',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Quick Contact Chips
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _registeredUsers.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final user = _registeredUsers[index];
                    final isSelected = _selectedRecipient?['username'] == user['username'];

                    return GestureDetector(
                      onTap: () => _selectRecipient(user),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.cyanAccent.withValues(alpha: 0.2)
                              : AppColors.cardBgElevated,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? AppColors.cyanAccent : AppColors.cardBorder,
                            width: isSelected ? 1.4 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(user['avatar'].toString(), style: const TextStyle(fontSize: 14)),
                            const SizedBox(width: 6),
                            Text(
                              '@${user['username']}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? AppColors.cyanAccent : AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 16),

              // 3. Verified Recipient Preview Card
              if (_selectedRecipient != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.greenAccent.withValues(alpha: 0.4),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: const Color(0xFF132332),
                          border: Border.all(
                            color: AppColors.cyanAccent.withValues(alpha: 0.6),
                            width: 1.5,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          _selectedRecipient!['avatar'].toString(),
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  _selectedRecipient!['name'].toString(),
                                  style: GoogleFonts.inter(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                if (_selectedRecipient!['isVerified'] == true)
                                  const Icon(
                                    Icons.verified_rounded,
                                    color: AppColors.greenLight,
                                    size: 16,
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${_selectedRecipient!['username']} · ${_selectedRecipient!['phone']}',
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.greenBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: AppColors.greenAccent.withValues(alpha: 0.5),
                          ),
                        ),
                        child: Text(
                          'VERIFIED',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.greenLight,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // 4. Amount Input Section
              Text(
                'Transfer Amount',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: _enteredAmount > _appState.availableBalance
                        ? AppColors.redAccent
                        : AppColors.cardBorderHighlight,
                    width: 1.2,
                  ),
                ),
                child: TextField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged: (val) => setState(() {}),
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: Padding(
                      padding: const EdgeInsets.only(left: 16, right: 8),
                      child: Text(
                        '৳',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: AppColors.cyanAccent,
                        ),
                      ),
                    ),
                    prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                    hintText: '0.00',
                    hintStyle: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                    ),
                    suffixIcon: _amountController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                            onPressed: () {
                              _amountController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              // Inline Balance Warning
              if (_enteredAmount > _appState.availableBalance) ...[
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.error_outline_rounded, color: AppColors.redAccent, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Amount exceeds available balance of ৳ ${_appState.formattedAvailableBalance}',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.redAccent,
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: 12),

              // Quick Amount Preset Chips
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ..._presetAmounts.map((amt) {
                    final isSelected = _enteredAmount == amt.toDouble();
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          _amountController.text = amt.toString();
                          setState(() {});
                          HapticFeedback.selectionClick();
                        },
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 3),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.cyanAccent.withValues(alpha: 0.25)
                                : AppColors.cardBg,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected ? AppColors.cyanAccent : AppColors.cardBorder,
                              width: isSelected ? 1.4 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '৳ $amt',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? Colors.white : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        _amountController.text = _appState.availableBalance.toStringAsFixed(0);
                        setState(() {});
                        HapticFeedback.selectionClick();
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 3),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cardBorder),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          'MAX',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // 5. Transfer Note Field
              Text(
                'Note / Reference (Optional)',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textSecondary,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 8),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: _noteController,
                  style: GoogleFonts.inter(
                    fontSize: 13.5,
                    color: Colors.white,
                  ),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(
                      Icons.chat_bubble_outline_rounded,
                      color: AppColors.textSecondary,
                      size: 18,
                    ),
                    hintText: 'e.g. For Mega Draw Ticket pool',
                    hintStyle: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textMuted,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 6. Transfer Summary Breakdown
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBgElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: [
                    _buildSummaryRow(
                      'Transfer Amount',
                      '৳ ${_enteredAmount > 0 ? _enteredAmount.toStringAsFixed(2) : "0.00"}',
                      Colors.white,
                    ),
                    const Divider(color: AppColors.divider, height: 16),
                    _buildSummaryRow(
                      'Platform Fee',
                      '৳ 0.00 (0% Free)',
                      AppColors.greenLight,
                    ),
                    const Divider(color: AppColors.divider, height: 16),
                    _buildSummaryRow(
                      'Total Debited',
                      '৳ ${_enteredAmount > 0 ? _enteredAmount.toStringAsFixed(2) : "0.00"}',
                      AppColors.goldPrimary,
                      isBold: true,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // 7. Slide to Confirm / Action Button
              if (_isProcessing) ...[
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(color: AppColors.cyanAccent),
                  ),
                ),
              ] else if (_isAmountValid && _selectedRecipient != null) ...[
                TradexSlideToConfirm(
                  label: 'SLIDE TO SEND MONEY',
                  sliderColor: AppColors.cyanAccent,
                  onConfirmed: _handleTransfer,
                ),
              ] else ...[
                TradexButton(
                  text: 'ENTER VALID AMOUNT & RECIPIENT',
                  variant: TradexButtonVariant.outline,
                  height: 52,
                  onPressed: null,
                ),
              ],

              const SizedBox(height: 20),

              // Security Trust Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    '256-bit Encrypted Peer-to-Peer Transfer',
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, Color valueColor, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isBold ? 14.5 : 13.5,
            fontWeight: isBold ? FontWeight.w800 : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
