import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/screens/mega_draw_screen.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class MegaDrawInfoScreen extends StatefulWidget {
  const MegaDrawInfoScreen({super.key});

  @override
  State<MegaDrawInfoScreen> createState() => _MegaDrawInfoScreenState();
}

class _MegaDrawInfoScreenState extends State<MegaDrawInfoScreen> {
  int? _expandedFaqIndex;

  static const List<Map<String, String>> _faqItems = [
    {
      'question': 'How are Mega Draw winning numbers generated?',
      'answer':
          'All winning combinations are selected through cryptographically secure random number generators (RNG) that are certified by international gaming audit standards. Live video streams of the draw are broadcast on the 1st of every month at 09:00 PM.',
    },
    {
      'question': 'When are prizes credited to winners?',
      'answer':
          'Prizes up to ৳50,000 are credited instantly to your Tradex Wallet balance. Jackpot winners (৳5,00,000 & ৳1,00,000) are notified via SMS/App notification and can withdraw directly to their verified bKash, Nagad, or Bank account immediately.',
    },
    {
      'question': 'Can I buy multiple tickets with different numbers?',
      'answer':
          'Yes! You can purchase unlimited tickets per draw. You can pick your custom 7-digit lucky numbers or use the Quick Pick feature for automatic randomized entries.',
    },
    {
      'question': 'What happens if multiple people match the exact numbers?',
      'answer':
          'If multiple tickets match the exact Jackpot combination, the 1st Prize pool is evenly distributed among the winning ticket holders. 2nd, 3rd, and Consolation prizes have fixed guaranteed payouts.',
    },
    {
      'question': 'Are ticket sales restricted during draw times?',
      'answer':
          'Ticket sales close 15 minutes before the draw (08:45 PM on the 1st of each month) to finalize and freeze the cryptographic entry ledger.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final megaDraw = DrawModel.sampleDraws[0];

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
          'Mega Draw Rules & Prizes',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 1. Hero Card: How Mega Draw Works
                    _buildHowItWorksHero(),

                    const SizedBox(height: 20),

                    // 2. Complete Prize Tier Breakdown
                    _buildPrizeTiersSection(megaDraw.prizeTiers),

                    const SizedBox(height: 20),

                    // 3. Key Draw Information Matrix
                    _buildKeyInfoMatrix(),

                    const SizedBox(height: 20),

                    // 4. Security & Fairness Assurance Badge
                    _buildSecurityBadge(),

                    const SizedBox(height: 20),

                    // 5. Interactive FAQ Accordion
                    _buildFaqAccordion(),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),

            // Bottom CTA
            Container(
              padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
              decoration: BoxDecoration(
                color: AppColors.cardBgElevated,
                border: const Border(
                  top: BorderSide(color: AppColors.cardBorder),
                ),
              ),
              child: TradexButton(
                text: 'PLAY MEGA DRAW (৳ 100)',
                variant: TradexButtonVariant.primaryGold,
                icon: Icons.confirmation_number_outlined,
                height: 50,
                fontSize: 14.5,
                fontWeight: FontWeight.w800,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MegaDrawScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHowItWorksHero() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.35),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.1),
            blurRadius: 18,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'How Mega Draw Works?',
                  style: GoogleFonts.inter(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Select any 7-digit combination (0,000,000 to 9,999,999). Match numbers in the monthly live draw to win prizes up to ৳ 5,00,000.',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: AppColors.textSecondary,
                    height: 1.45,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          const _GlowingPurpleQuestionGraphic(),
        ],
      ),
    );
  }

  Widget _buildPrizeTiersSection(List<PrizeTier> prizeTiers) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'PRIZE TIER BREAKDOWN',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              'Total Pool: ৳ 6,25,000',
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.goldPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ...prizeTiers.map((tier) {
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: tier.badgeColor.withValues(alpha: 0.35),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: tier.badgeColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: tier.badgeColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.emoji_events_rounded,
                      color: tier.badgeColor,
                      size: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tier.tierName,
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        tier.matchRule,
                        style: GoogleFonts.inter(
                          fontSize: 11.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tier.prizeAmount,
                      style: GoogleFonts.poppins(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: tier.badgeColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      tier.winnerPercentageOrFixed,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        color: AppColors.textMuted,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildKeyInfoMatrix() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          _buildInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Draw Schedule',
            value: '1st of Every Month | 09:00 PM',
          ),
          const Divider(color: AppColors.divider, height: 18),
          _buildInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Ticket Sale Period',
            value: '2nd to 30th of Every Month',
          ),
          const Divider(color: AppColors.divider, height: 18),
          _buildInfoRow(
            icon: Icons.sell_outlined,
            label: 'Ticket Price',
            value: '৳ 100 per Ticket',
            valueColor: AppColors.goldLight,
          ),
          const Divider(color: AppColors.divider, height: 18),
          _buildInfoRow(
            icon: Icons.account_balance_wallet_outlined,
            label: 'Winnings Payout',
            value: 'Instant Wallet Credit',
            valueColor: AppColors.greenLight,
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.greenAccent.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_rounded,
            color: AppColors.greenLight,
            size: 26,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Provably Fair & Cryptographically Verified',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Seeds and hash algorithms are publicly auditable and transparent on every draw.',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqAccordion() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'FREQUENTLY ASKED QUESTIONS',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 12),
        ...List.generate(_faqItems.length, (index) {
          final item = _faqItems[index];
          final bool isExpanded = _expandedFaqIndex == index;

          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isExpanded ? AppColors.goldPrimary.withValues(alpha: 0.5) : AppColors.cardBorder,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _expandedFaqIndex = isExpanded ? null : index;
                  });
                },
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              item['question']!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isExpanded ? AppColors.goldLight : Colors.white,
                              ),
                            ),
                          ),
                          Icon(
                            isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: isExpanded ? AppColors.goldPrimary : AppColors.textSecondary,
                            size: 20,
                          ),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 10),
                        const Divider(color: AppColors.divider, height: 1),
                        const SizedBox(height: 10),
                        Text(
                          item['answer']!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: valueColor ?? Colors.white,
          ),
        ),
      ],
    );
  }
}

class _GlowingPurpleQuestionGraphic extends StatelessWidget {
  const _GlowingPurpleQuestionGraphic();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 54,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF9333EA).withValues(alpha: 0.5),
                  blurRadius: 18,
                  spreadRadius: 3,
                ),
              ],
            ),
          ),
          CustomPaint(
            size: const Size(36, 42),
            painter: _QuestionMarkPainter(),
          ),
        ],
      ),
    );
  }
}

class _QuestionMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Paint glowPaint = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE879F9),
          Color(0xFFC084FC),
          Color(0xFFA855F7),
          Color(0xFF7E22CE),
        ],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, w, h))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.0
      ..strokeCap = StrokeCap.round;

    final Path curvePath = Path();
    curvePath.moveTo(w * 0.28, h * 0.25);
    curvePath.cubicTo(
      w * 0.28, h * 0.05,
      w * 0.85, h * 0.05,
      w * 0.82, h * 0.32,
    );
    curvePath.cubicTo(
      w * 0.80, h * 0.48,
      w * 0.50, h * 0.52,
      w * 0.50, h * 0.68,
    );

    canvas.drawPath(curvePath, glowPaint);

    final Paint dotPaint = Paint()
      ..shader = const RadialGradient(
        colors: [
          Color(0xFFF5D0FE),
          Color(0xFFA855F7),
          Color(0xFF6B21A8),
        ],
      ).createShader(Rect.fromCircle(center: Offset(w * 0.50, h * 0.88), radius: 3.8))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(Offset(w * 0.50, h * 0.88), 3.8, dotPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
