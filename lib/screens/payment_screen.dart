import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/ticket_model.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/payment_logos.dart';

class PaymentScreen extends StatefulWidget {
  final DrawModel draw;
  final String selectedNumber;
  final int ticketCount;
  final int ticketPrice;

  const PaymentScreen({
    super.key,
    required this.draw,
    required this.selectedNumber,
    required this.ticketCount,
    required this.ticketPrice,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'nagad'; // Default to Nagad as shown in mockup
  bool _isProcessing = false;
  final AppState _appState = AppState();

  @override
  Widget build(BuildContext context) {
    final int totalAmount = widget.ticketPrice * widget.ticketCount;
    final String formattedNumber = widget.selectedNumber.split('').join(' ');

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
          'Payment',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Order Summary Card
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Order Summary',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF8B5CF6).withValues(alpha: 0.35),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _buildSummaryRow('Draw Type', widget.draw.title),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Selected Number', formattedNumber, isMonospace: true),
                    const SizedBox(height: 12),
                    _buildSummaryRow(
                      'Ticket Price (৳ ${widget.ticketPrice} × ${widget.ticketCount})',
                      '৳ $totalAmount',
                    ),
                    const SizedBox(height: 12),
                    _buildSummaryRow('Total Tickets', '${widget.ticketCount}'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 14),
                      child: Divider(color: AppColors.divider, height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Amount',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '৳ $totalAmount',
                          style: GoogleFonts.inter(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Select Payment Method Header
              Text(
                'Select Payment Method',
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),

              const SizedBox(height: 14),

              // Method 1: Nagad
              _buildPaymentMethodTile(
                id: 'nagad',
                child: const NagadLogo(
                  iconSize: 30,
                  fontSize: 16,
                  textColor: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // Method 2: bKash
              _buildPaymentMethodTile(
                id: 'bkash',
                child: const BKashLogo(
                  iconSize: 30,
                  fontSize: 16,
                  textColor: Colors.white,
                ),
              ),

              const SizedBox(height: 12),

              // Method 3: Rocket
              _buildPaymentMethodTile(
                id: 'rocket',
                child: const RocketLogo(
                  iconSize: 30,
                  fontSize: 15.5,
                  textColor: Colors.white,
                ),
              ),

              const SizedBox(height: 36),

              // Pay Button (Purple / Violet Gradient)
              Container(
                width: double.infinity,
                height: 52,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF8B5CF6), // Bright Purple
                      Color(0xFF6D28D9), // Deep Purple
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF7C3AED).withValues(alpha: 0.45),
                      blurRadius: 14,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isProcessing ? null : () => _processPayment(totalAmount),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'PAY ৳ $totalAmount',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              // Secure Payment Footnote
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_outline_rounded, color: AppColors.textMuted, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Secure Payment',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodTile({
    required String id,
    required Widget child,
  }) {
    final bool isSelected = _selectedMethod == id;

    return GestureDetector(
      onTap: () => setState(() => _selectedMethod = id),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.purpleAccent : AppColors.cardBorder,
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Expanded(child: child),
            // Custom Radio Button
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected ? const Color(0xFF7C3AED) : Colors.transparent,
                border: Border.all(
                  color: isSelected ? const Color(0xFF7C3AED) : AppColors.textMuted,
                  width: 1.8,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      size: 14,
                      color: Colors.white,
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isMonospace = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: isMonospace ? 14.5 : 13.5,
            fontWeight: isMonospace ? FontWeight.w700 : FontWeight.w600,
            color: Colors.white,
            letterSpacing: isMonospace ? 1.5 : 0,
          ),
        ),
      ],
    );
  }

  Future<void> _processPayment(int totalAmount) async {
    setState(() => _isProcessing = true);

    await Future.delayed(const Duration(milliseconds: 900));

    final TicketModel? purchasedTicket = _appState.buyTicket(
      draw: widget.draw,
      number: widget.selectedNumber,
      count: widget.ticketCount,
      unitPrice: widget.ticketPrice,
      paymentMethod: _selectedMethod,
    );

    if (!mounted) return;
    setState(() => _isProcessing = false);

    if (purchasedTicket != null) {
      _showSuccessDialog(totalAmount);
    }
  }

  void _showSuccessDialog(int totalAmount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 10),
            Container(
              width: 68,
              height: 68,
              decoration: BoxDecoration(
                color: AppColors.greenBg,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.greenAccent, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.greenAccent.withValues(alpha: 0.3),
                    blurRadius: 16,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded, color: AppColors.greenLight, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              'Ticket Purchased!',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Your ticket for ${widget.draw.title} has been confirmed.\nTicket Number: ${widget.selectedNumber.split('').join(' ')}',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.goldPrimary,
                  foregroundColor: Colors.black87,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 3,
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                },
                child: Text(
                  'DONE',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
