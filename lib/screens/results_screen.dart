import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/draw_result.dart';
import 'package:tradex/screens/all_results_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class ResultsScreen extends StatefulWidget {
  final DrawType initialDrawType;

  const ResultsScreen({super.key, this.initialDrawType = DrawType.mega});

  @override
  State<ResultsScreen> createState() => _ResultsScreenState();
}

class _ResultsScreenState extends State<ResultsScreen> {
  late DrawType _selectedType;
  final TextEditingController _checkerNumberController = TextEditingController();
  DrawType _checkerSelectedDrawType = DrawType.mega;
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialDrawType;
  }

  @override
  void dispose() {
    _checkerNumberController.dispose();
    super.dispose();
  }

  DrawResult get _currentLatestResult {
    final drawIdStr = _selectedType == DrawType.mega
        ? 'mega'
        : _selectedType == DrawType.daily
            ? 'daily'
            : 'hourly';

    return DrawResult.latestResults.firstWhere(
      (r) => r.drawId == drawIdStr,
      orElse: () => DrawResult.latestResults.first,
    );
  }

  DrawModel get _currentDrawModel {
    return DrawModel.sampleDraws.firstWhere(
      (d) => d.type == _selectedType,
      orElse: () => DrawModel.sampleDraws.first,
    );
  }

  void _handleWinningCheck() {
    final number = _checkerNumberController.text.trim();
    if (number.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your ticket number to check'),
          backgroundColor: AppColors.redAccent,
        ),
      );
      return;
    }

    HapticFeedback.mediumImpact();

    final drawIdStr = _checkerSelectedDrawType == DrawType.mega
        ? 'mega'
        : _checkerSelectedDrawType == DrawType.daily
            ? 'daily'
            : 'hourly';

    final checkResult = _appState.checkWinningNumber(drawIdStr, number);

    _showWinningCheckModal(checkResult, number);
  }

  void _showWinningCheckModal(Map<String, dynamic> result, String inputNumber) {
    final bool isWinner = result['isWinner'] == true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
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
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),

              // Winning Icon or Consolation Icon
              Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isWinner
                      ? AppColors.goldPrimary.withValues(alpha: 0.18)
                      : Colors.white.withValues(alpha: 0.08),
                  border: Border.all(
                    color: isWinner
                        ? AppColors.goldPrimary.withValues(alpha: 0.6)
                        : AppColors.cardBorderHighlight,
                    width: 2,
                  ),
                  boxShadow: isWinner
                      ? [
                          BoxShadow(
                            color: AppColors.goldPrimary.withValues(alpha: 0.4),
                            blurRadius: 24,
                            spreadRadius: 2,
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  isWinner ? Icons.emoji_events_rounded : Icons.sentiment_neutral_rounded,
                  color: isWinner ? AppColors.goldLight : AppColors.textSecondary,
                  size: 38,
                ),
              ),
              const SizedBox(height: 14),

              Text(
                isWinner ? '🎉 CONGRATULATIONS! 🎉' : 'No Winning Match',
                style: GoogleFonts.poppins(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isWinner ? AppColors.goldLight : Colors.white,
                ),
              ),
              const SizedBox(height: 4),

              Text(
                isWinner
                    ? 'Your number matched in ${result['drawTitle']}!'
                    : 'Ticket #$inputNumber was not drawn in recent draws.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 18),

              // Details Glass Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isWinner
                        ? AppColors.goldPrimary.withValues(alpha: 0.4)
                        : AppColors.cardBorder,
                  ),
                ),
                child: Column(
                  children: [
                    if (isWinner) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Prize Tier', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                          TradexStatusChip(
                            label: result['tier'] ?? 'Winner',
                            color: AppColors.goldPrimary,
                            fontSize: 11,
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.divider, height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Prize Payout', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                          Text(
                            result['prize'] ?? '৳ 0',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.divider, height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Match Type', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                          Text(
                            result['match'] ?? 'Exact Match',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.greenLight,
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Checked Number', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                          Text(
                            inputNumber,
                            style: GoogleFonts.poppins(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                        ],
                      ),
                      const Divider(color: AppColors.divider, height: 18),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Latest Winning Number', style: GoogleFonts.inter(color: AppColors.textSecondary, fontSize: 13)),
                          Text(
                            result['winningNumber'] ?? '---',
                            style: GoogleFonts.poppins(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldAccent,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 20),

              TradexButton(
                text: isWinner ? 'CLAIM PRIZE / VIEW WALLET' : 'TRY LUCKY QUICK PICK',
                variant: isWinner ? TradexButtonVariant.primaryGold : TradexButtonVariant.outline,
                height: 50,
                onPressed: () {
                  Navigator.pop(ctx);
                  if (isWinner) {
                    _appState.setTabIndex(3); // Wallet
                  }
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
    final result = _currentLatestResult;
    final drawModel = _currentDrawModel;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              _appState.setTabIndex(0);
            }
          },
        ),
        title: Text(
          'Draw Results',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined, color: Colors.white, size: 22),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AllResultsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Draw Type Filter Pills
              Row(
                children: [
                  _buildTabPill('Mega Draw', DrawType.mega, AppColors.goldPrimary),
                  const SizedBox(width: 8),
                  _buildTabPill('Daily Draw', DrawType.daily, AppColors.greenAccent),
                  const SizedBox(width: 8),
                  _buildTabPill('Hourly Draw', DrawType.hourly, AppColors.purpleAccent),
                ],
              ),

              const SizedBox(height: 18),

              // 2. Latest Hero Draw Result Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      result.accentColor.withValues(alpha: 0.18),
                      AppColors.cardBgElevated,
                      AppColors.cardBg,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: result.accentColor.withValues(alpha: 0.5),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: result.accentColor.withValues(alpha: 0.18),
                      blurRadius: 20,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with Status Chip
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              result.title,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              result.date,
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        TradexStatusChip(
                          label: 'OFFICIAL RESULT',
                          color: result.accentColor,
                          fontSize: 9.5,
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // Winning Number Balls
                    Center(
                      child: Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        alignment: WrapAlignment.center,
                        children: result.winningNumbers.map((digit) {
                          return _buildGlowingNumberBall(digit, result.accentColor);
                        }).toList(),
                      ),
                    ),

                    const SizedBox(height: 22),

                    // Stats Banner (Prize Pool & Winners)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: result.accentColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem('PRIZE DISTRIBUTED', result.totalPrizeDistributed, result.accentColor),
                          Container(width: 1, height: 28, color: AppColors.cardBorder),
                          _buildStatItem('WINNERS', '${result.totalWinnersCount} Winners', Colors.white),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Jackpot Winner Tag
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.star_rounded, color: AppColors.goldPrimary, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Jackpot Winner: ${result.jackpotWinnerName}',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 3. Winning Number Checker Tool
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.cardBorderHighlight, width: 1.2),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppColors.purpleAccent.withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.search_rounded, color: AppColors.purpleLight, size: 18),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Check Your Lucky Number',
                          style: GoogleFonts.inter(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Input your ticket digits to check against recent winning results instantly.',
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 14),

                    // Mini draw selector
                    Row(
                      children: [
                        _buildCheckerMiniTab('Mega (7 Digits)', DrawType.mega),
                        const SizedBox(width: 6),
                        _buildCheckerMiniTab('Daily (3 Digits)', DrawType.daily),
                        const SizedBox(width: 6),
                        _buildCheckerMiniTab('Hourly (3 Digits)', DrawType.hourly),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Number Input Field & Button Row
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 46,
                            decoration: BoxDecoration(
                              color: AppColors.backgroundSecondary,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: AppColors.cardBorder),
                            ),
                            child: TextField(
                              controller: _checkerNumberController,
                              keyboardType: TextInputType.number,
                              maxLength: _checkerSelectedDrawType == DrawType.mega ? 7 : 3,
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 2.0,
                                color: Colors.white,
                              ),
                              decoration: InputDecoration(
                                counterText: '',
                                hintText: _checkerSelectedDrawType == DrawType.mega ? '1234567' : '123',
                                hintStyle: GoogleFonts.poppins(
                                  fontSize: 14,
                                  color: AppColors.textMuted,
                                  letterSpacing: 2.0,
                                ),
                                prefixIcon: const Icon(Icons.confirmation_number_outlined, size: 18, color: AppColors.textMuted),
                                border: InputBorder.none,
                                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.goldPrimary,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(horizontal: 18),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                            ),
                            onPressed: _handleWinningCheck,
                            child: Text(
                              'CHECK',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 22),

              // 4. Prize Tier Breakdown Table
              Text(
                'Prize Tier Structure',
                style: GoogleFonts.inter(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),

              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: Column(
                  children: drawModel.prizeTiers.map((tier) {
                    final isFirst = drawModel.prizeTiers.first == tier;
                    final isLast = drawModel.prizeTiers.last == tier;

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                      decoration: BoxDecoration(
                        border: isLast ? null : const Border(bottom: BorderSide(color: AppColors.divider)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: tier.badgeColor,
                              shape: BoxShape.circle,
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
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isFirst ? AppColors.goldLight : Colors.white,
                                  ),
                                ),
                                Text(
                                  tier.matchRule,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            tier.prizeAmount,
                            style: GoogleFonts.poppins(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: tier.badgeColor,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 24),

              // 5. Button to Historical Archive Screen
              TradexButton(
                text: 'VIEW ALL HISTORICAL DRAW RESULTS',
                icon: Icons.history_rounded,
                variant: TradexButtonVariant.secondaryPurple,
                height: 50,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AllResultsScreen()),
                  );
                },
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowingNumberBall(String digit, Color color) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            color,
            color.withValues(alpha: 0.6),
            const Color(0xFF0F131E),
          ],
          radius: 0.85,
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.5),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Text(
        digit,
        style: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w900,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTabPill(String label, DrawType type, Color color) {
    final bool isSelected = _selectedType == type;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedType = type;
          });
          HapticFeedback.selectionClick();
        },
        child: Container(
          height: 40,
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.25) : AppColors.cardBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isSelected ? color : AppColors.cardBorder,
              width: isSelected ? 1.4 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckerMiniTab(String label, DrawType type) {
    final bool isSelected = _checkerSelectedDrawType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _checkerSelectedDrawType = type;
            _checkerNumberController.clear();
          });
          HapticFeedback.selectionClick();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.purpleButton : AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isSelected ? AppColors.purpleLight : AppColors.cardBorder,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
