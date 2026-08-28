import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/ticket_model.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class PurchaseSuccessScreen extends StatefulWidget {
  final TicketModel ticket;

  const PurchaseSuccessScreen({
    super.key,
    required this.ticket,
  });

  @override
  State<PurchaseSuccessScreen> createState() => _PurchaseSuccessScreenState();
}

class _PurchaseSuccessScreenState extends State<PurchaseSuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _checkAnimController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _checkAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _checkAnimController,
      curve: Curves.elasticOut,
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _checkAnimController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
      ),
    );

    _checkAnimController.forward();
    HapticFeedback.heavyImpact();
  }

  @override
  void dispose() {
    _checkAnimController.dispose();
    super.dispose();
  }

  void _onViewMyTickets() {
    HapticFeedback.selectionClick();
    // Switch to tab index 1 (My Tickets) and pop to root shell
    AppState().setTabIndex(1);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onPlayAnotherDraw() {
    HapticFeedback.selectionClick();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _onShareReceipt() {
    HapticFeedback.selectionClick();
    Clipboard.setData(
      ClipboardData(
        text: '🎟️ TRADEX Ticket Confirmed!\n'
            'Draw: ${widget.ticket.draw.title}\n'
            'Number: ${widget.ticket.number}\n'
            'Tickets: ${widget.ticket.count}\n'
            'Amount: ৳${widget.ticket.totalAmount}\n'
            'Ticket ID: ${widget.ticket.ticketNumber}\n'
            'Draw Date: ${widget.ticket.draw.scheduleInfo}\n'
            'Verify at: https://tradex.com/verify/${widget.ticket.ticketNumber}',
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.cardBgElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.goldPrimary, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Ticket receipt copied to clipboard for sharing!',
                style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ticket = widget.ticket;
    final digits = ticket.number.split('');
    final formattedTime =
        '${ticket.purchaseDate.day.toString().padLeft(2, '0')}/${ticket.purchaseDate.month.toString().padLeft(2, '0')}/${ticket.purchaseDate.year} '
        '${ticket.purchaseDate.hour > 12 ? ticket.purchaseDate.hour - 12 : (ticket.purchaseDate.hour == 0 ? 12 : ticket.purchaseDate.hour)}:'
        '${ticket.purchaseDate.minute.toString().padLeft(2, '0')} ${ticket.purchaseDate.hour >= 12 ? 'PM' : 'AM'}';

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onViewMyTickets();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          automaticallyImplyLeading: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              onPressed: _onViewMyTickets,
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. Animated Checkmark with Glowing Aura
                AnimatedBuilder(
                  animation: _checkAnimController,
                  builder: (context, child) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Radiant Gold/Green Aura
                        Container(
                          width: 86 * _scaleAnimation.value,
                          height: 86 * _scaleAnimation.value,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: ticket.draw.accentColor.withValues(
                                  alpha: 0.45 * _glowAnimation.value,
                                ),
                                blurRadius: 36,
                                spreadRadius: 8,
                              ),
                            ],
                          ),
                        ),
                        // Inner Circle Icon
                        Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  ticket.draw.accentColor,
                                  ticket.draw.accentColor.withValues(alpha: 0.75),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.4),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_rounded,
                                color: Color(0xFF0F111A),
                                size: 42,
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),

                const SizedBox(height: 16),

                // 2. Congratulations Header
                Text(
                  'Ticket Confirmed!',
                  style: GoogleFonts.inter(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Your lucky entry has been registered successfully.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),

                const SizedBox(height: 22),

                // 3. Bespoke Artisanal Receipt Card
                _buildArtisanalReceiptCard(
                  ticket: ticket,
                  digits: digits,
                  formattedTime: formattedTime,
                ),

                const SizedBox(height: 24),

                // 4. Action Buttons
                TradexButton(
                  text: 'VIEW MY TICKETS',
                  variant: TradexButtonVariant.primaryGold,
                  icon: Icons.confirmation_number_outlined,
                  height: 52,
                  fontSize: 14.5,
                  onPressed: _onViewMyTickets,
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TradexButton(
                        text: 'Share Receipt',
                        variant: TradexButtonVariant.outline,
                        icon: Icons.share_outlined,
                        height: 46,
                        fontSize: 13,
                        onPressed: _onShareReceipt,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TradexButton(
                        text: 'Play Another',
                        variant: TradexButtonVariant.glass,
                        icon: Icons.replay_rounded,
                        height: 46,
                        fontSize: 13,
                        onPressed: _onPlayAnotherDraw,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArtisanalReceiptCard({
    required TicketModel ticket,
    required List<String> digits,
    required String formattedTime,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.45),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Upper Receipt Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: ticket.draw.accentColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: ticket.draw.accentColor.withValues(alpha: 0.3),
                            ),
                          ),
                          child: Icon(
                            Icons.emoji_events_rounded,
                            color: ticket.draw.accentColor,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          ticket.draw.title,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    TradexStatusChip(
                      label: 'OFFICIAL TICKET',
                      color: ticket.draw.accentColor,
                      fontSize: 9.5,
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Selected Numbers Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: ticket.draw.accentColor.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'SELECTED LUCKY NUMBER',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        alignment: WrapAlignment.center,
                        children: digits.map((d) {
                          return Container(
                            width: digits.length > 5 ? 32 : 42,
                            height: digits.length > 5 ? 38 : 48,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.cardBgElevated,
                                  ticket.draw.accentColor.withValues(alpha: 0.15),
                                ],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: ticket.draw.accentColor,
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: ticket.draw.accentColor.withValues(alpha: 0.3),
                                  blurRadius: 6,
                                ),
                              ],
                            ),
                            child: Text(
                              d,
                              style: GoogleFonts.poppins(
                                fontSize: digits.length > 5 ? 16 : 22,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Perforated Divider
          Row(
            children: [
              Container(
                width: 14,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(13),
                    bottomRight: Radius.circular(13),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dashCount = (constraints.constrainWidth() / 10).floor();
                    return Flex(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      direction: Axis.horizontal,
                      children: List.generate(dashCount, (_) {
                        return const SizedBox(
                          width: 5,
                          height: 1.5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: AppColors.cardBorder),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              Container(
                width: 14,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(13),
                    bottomLeft: Radius.circular(13),
                  ),
                ),
              ),
            ],
          ),

          // Lower Receipt Details
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            child: Column(
              children: [
                // Serial Number Copy Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SERIAL NUMBER',
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textMuted,
                              letterSpacing: 0.5,
                            ),
                          ),
                          Text(
                            ticket.ticketNumber,
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.copy_rounded,
                          size: 18,
                          color: AppColors.textSecondary,
                        ),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: ticket.ticketNumber));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Serial number copied!'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 14),

                _buildReceiptRow('Quantity', '${ticket.count} Ticket(s)'),
                _buildReceiptRow('Unit Price', '৳ ${ticket.unitPrice}'),
                _buildReceiptRow('Total Paid', '৳ ${ticket.totalAmount}', isHighlight: true),
                _buildReceiptRow('Draw Schedule', ticket.draw.scheduleInfo),
                _buildReceiptRow('Purchased At', formattedTime),

                const SizedBox(height: 14),
                const Divider(color: AppColors.divider, height: 1),
                const SizedBox(height: 12),

                // Barcode / Hash Simulation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SECURITY HASH',
                          style: GoogleFonts.inter(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'SHA-256: 9f8a...3e41 [VERIFIED]',
                          style: GoogleFonts.poppins(
                            fontSize: 10,
                            color: AppColors.greenLight,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        14,
                        (i) => Container(
                          margin: const EdgeInsets.only(left: 2),
                          width: (i % 3 == 0) ? 3 : 1.5,
                          height: 22,
                          color: AppColors.textSecondary.withValues(alpha: 0.6),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReceiptRow(String label, String value, {bool isHighlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: isHighlight ? 14 : 12.5,
              fontWeight: isHighlight ? FontWeight.w800 : FontWeight.w600,
              color: isHighlight ? AppColors.goldLight : Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
