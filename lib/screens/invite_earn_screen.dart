import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/user_model.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class InvitedFriend {
  final String name;
  final String username;
  final String joinedDate;
  final String status;
  final Color statusColor;
  final double earnedAmount;

  const InvitedFriend({
    required this.name,
    required this.username,
    required this.joinedDate,
    required this.status,
    required this.statusColor,
    required this.earnedAmount,
  });
}

class InviteEarnScreen extends StatefulWidget {
  const InviteEarnScreen({super.key});

  @override
  State<InviteEarnScreen> createState() => _InviteEarnScreenState();
}

class _InviteEarnScreenState extends State<InviteEarnScreen> {
  final AppState _appState = AppState();
  int _selectedFilterIndex = 0; // 0 = All, 1 = Completed, 2 = Pending

  static const List<InvitedFriend> sampleFriends = [
    InvitedFriend(
      name: 'Rashedul Islam',
      username: '@rashed_dhaka',
      joinedDate: '23 Aug 2026',
      status: 'Active • ৳ 100 Earned',
      statusColor: AppColors.greenAccent,
      earnedAmount: 100.0,
    ),
    InvitedFriend(
      name: 'Tanvir Hossain',
      username: '@tanvir_pro',
      joinedDate: '20 Aug 2026',
      status: 'Mega Draw Winner • ৳ 150 Earned',
      statusColor: AppColors.goldPrimary,
      earnedAmount: 150.0,
    ),
    InvitedFriend(
      name: 'Farhan Ahmed',
      username: '@farhan_99',
      joinedDate: '18 Aug 2026',
      status: 'Active • ৳ 100 Earned',
      statusColor: AppColors.greenAccent,
      earnedAmount: 100.0,
    ),
    InvitedFriend(
      name: 'Nazmul Hasan',
      username: '@nazmul_ctg',
      joinedDate: '15 Aug 2026',
      status: 'Pending First Deposit',
      statusColor: AppColors.orangeAccent,
      earnedAmount: 0.0,
    ),
    InvitedFriend(
      name: 'Shakil Khan',
      username: '@shakil_k',
      joinedDate: '12 Aug 2026',
      status: 'Active • ৳ 100 Earned',
      statusColor: AppColors.greenAccent,
      earnedAmount: 100.0,
    ),
    InvitedFriend(
      name: 'Mahbubur Rahman',
      username: '@mahbub_2026',
      joinedDate: '08 Aug 2026',
      status: 'Pending KYC Verification',
      statusColor: AppColors.orangeAccent,
      earnedAmount: 0.0,
    ),
  ];

  void _copyReferralCode(String code) {
    Clipboard.setData(ClipboardData(text: code));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.cardBgElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.goldPrimary),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.goldPrimary, size: 20),
            const SizedBox(width: 10),
            Text(
              'Referral code "$code" copied!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(String code) {
    final shareUrl = 'https://tradex.com/join?ref=$code';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textMuted,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Share Invitation Link',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Invite your friends to TRADEX and both get ৳ 100 bonus instantly!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 20),

              // Social Share Options
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildShareOption(
                    icon: Icons.chat_rounded,
                    label: 'WhatsApp',
                    color: const Color(0xFF25D366),
                    onTap: () {
                      Navigator.pop(ctx);
                      _copyReferralCode(code);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.send_rounded,
                    label: 'Telegram',
                    color: const Color(0xFF0088CC),
                    onTap: () {
                      Navigator.pop(ctx);
                      _copyReferralCode(code);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.facebook_rounded,
                    label: 'Facebook',
                    color: const Color(0xFF1877F2),
                    onTap: () {
                      Navigator.pop(ctx);
                      _copyReferralCode(code);
                    },
                  ),
                  _buildShareOption(
                    icon: Icons.copy_rounded,
                    label: 'Copy Link',
                    color: AppColors.goldPrimary,
                    onTap: () {
                      Navigator.pop(ctx);
                      Clipboard.setData(ClipboardData(text: shareUrl));
                      HapticFeedback.lightImpact();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Referral link copied to clipboard!')),
                      );
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildShareOption({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color.withValues(alpha: 0.18),
                border: Border.all(color: color.withValues(alpha: 0.4)),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
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
          'Invite & Earn',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: _appState,
          builder: (context, _) {
            final user = _appState.currentUser;
            final referralCode = user.referralCode.isNotEmpty ? user.referralCode : 'TRADEX777';

            final filteredFriends = _selectedFilterIndex == 0
                ? sampleFriends
                : _selectedFilterIndex == 1
                    ? sampleFriends.where((f) => f.earnedAmount > 0).toList()
                    : sampleFriends.where((f) => f.earnedAmount == 0).toList();

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Hero Referral Golden Card
                  _buildHeroReferralCard(referralCode),

                  const SizedBox(height: 16),

                  // Referral Stats 3-Grid
                  _buildReferralStats(user),

                  const SizedBox(height: 20),

                  // VIP Tier Progress Bar
                  _buildTierProgressCard(user),

                  const SizedBox(height: 24),

                  // 3-Step "How It Works" Guide
                  _buildHowItWorksCard(),

                  const SizedBox(height: 24),

                  // Invited Friends List Section
                  _buildInvitedFriendsSection(filteredFriends),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeroReferralCard(String code) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2C1E05),
            Color(0xFF161A29),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.15),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldPrimary.withValues(alpha: 0.2),
                  border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
                ),
                child: const Icon(Icons.card_giftcard_rounded, color: AppColors.goldPrimary, size: 30),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Earn ৳ 100 per Friend!',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Instant wallet bonus + 5% commission on all draw wins!',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Code Pill Box
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'YOUR REFERRAL CODE',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textMuted,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      code,
                      style: GoogleFonts.inter(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColors.goldAccent,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.goldPrimary,
                    foregroundColor: const Color(0xFF0F111A),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(
                    'COPY',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  onPressed: () => _copyReferralCode(code),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Share Button
          TradexButton(
            text: 'SHARE INVITATION LINK',
            icon: Icons.share_rounded,
            width: double.infinity,
            variant: TradexButtonVariant.primaryGold,
            onPressed: () => _showShareSheet(code),
          ),
        ],
      ),
    );
  }

  Widget _buildReferralStats(UserModel user) {
    return Row(
      children: [
        Expanded(
          child: _buildStatTile(
            label: 'Friends Invited',
            value: '${user.referralCount}',
            icon: Icons.group_rounded,
            accentColor: AppColors.purpleAccent,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            label: 'Total Earned',
            value: '৳ ${user.referralEarnings.toStringAsFixed(0)}',
            icon: Icons.account_balance_wallet_rounded,
            accentColor: AppColors.goldPrimary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildStatTile(
            label: 'Pending Bonus',
            value: '৳ 250',
            icon: Icons.hourglass_bottom_rounded,
            accentColor: AppColors.greenAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: accentColor, size: 22),
          const SizedBox(height: 6),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 10.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTierProgressCard(UserModel user) {
    final int count = user.referralCount;
    final double progress = (count / 30).clamp(0.0, 1.0);

    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.military_tech_rounded, color: AppColors.goldPrimary, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    'VIP Referral Tier',
                    style: GoogleFonts.inter(fontSize: 14.5, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
              TradexStatusChip(
                label: 'GOLD TIER',
                color: AppColors.goldPrimary,
                icon: Icons.star_rounded,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.cardBorder,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldPrimary),
            ),
          ),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bronze (0)',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
              ),
              Text(
                'Silver (5)',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
              ),
              Text(
                'Gold (15)',
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.goldLight),
              ),
              Text(
                'Platinum VIP (30)',
                style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '🎉 Invite 12 more friends to unlock Platinum VIP tier with 7% lifetime draw commission & zero-fee withdrawals!',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorksCard() {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How It Works',
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
          ),
          const SizedBox(height: 14),
          _buildHowStep(
            number: '1',
            title: 'Share Code or Link',
            description: 'Send your unique TRADEX referral link to friends on WhatsApp or Telegram.',
          ),
          const SizedBox(height: 12),
          _buildHowStep(
            number: '2',
            title: 'Friend Registers & Plays',
            description: 'Your friend signs up and participates in any Hourly, Daily, or Mega draw.',
          ),
          const SizedBox(height: 12),
          _buildHowStep(
            number: '3',
            title: 'Both Earn ৳ 100 Instantly',
            description: '৳ 100 bonus balance is immediately credited to both your wallets.',
          ),
        ],
      ),
    );
  }

  Widget _buildHowStep({
    required String number,
    required String title,
    required String description,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.goldPrimary.withValues(alpha: 0.15),
            border: Border.all(color: AppColors.goldPrimary),
          ),
          child: Center(
            child: Text(
              number,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColors.goldPrimary,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvitedFriendsSection(List<InvitedFriend> friends) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Invited Friends (${friends.length})',
              style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            Row(
              children: [
                _buildFilterChip('All', 0),
                const SizedBox(width: 6),
                _buildFilterChip('Active', 1),
                const SizedBox(width: 6),
                _buildFilterChip('Pending', 2),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),

        if (friends.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                'No referrals found in this filter.',
                style: GoogleFonts.inter(color: AppColors.textMuted),
              ),
            ),
          )
        else
          ...friends.map((friend) => _buildFriendCard(friend)),
      ],
    );
  }

  Widget _buildFilterChip(String label, int index) {
    final isSelected = _selectedFilterIndex == index;

    return InkWell(
      onTap: () => setState(() => _selectedFilterIndex = index),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.goldPrimary : AppColors.cardBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.goldPrimary : AppColors.cardBorder),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.black : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _buildFriendCard(InvitedFriend friend) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.cardBgElevated,
            child: Text(
              friend.name.substring(0, 1),
              style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppColors.goldLight),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      friend.name,
                      style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                    ),
                    Text(
                      friend.joinedDate,
                      style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      friend.username,
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                    ),
                    Text(
                      friend.status,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: friend.statusColor,
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
}
