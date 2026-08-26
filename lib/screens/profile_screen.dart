import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/kyc_model.dart';
import 'package:tradex/screens/profile_sub_screens.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/custom_crown.dart';
import 'package:tradex/widgets/user_avatar.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: const BorderSide(color: Color(0xFF7F1D1D), width: 1.2),
        ),
        title: Row(
          children: [
            const Icon(Icons.logout_rounded, color: AppColors.redAccent, size: 24),
            const SizedBox(width: 10),
            Text(
              'Confirm Logout',
              style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to log out of TRADEX? You will need to sign in again to purchase tickets and claim draw winnings.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'CANCEL',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              AppState().logout();
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  backgroundColor: AppColors.cardBgElevated,
                  content: Text('Logged out successfully'),
                ),
              );
            },
            child: Text(
              'LOGOUT',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

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
              appState.setTabIndex(0);
            }
          },
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            tooltip: 'App Settings',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final user = appState.currentUser;
            final kyc = appState.kyc;
            final purchasedTickets = appState.purchasedTickets;
            final activeTickets = purchasedTickets.where((t) => t.status.name == 'active').length;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // 1. User Profile Hero Card
                  _buildProfileHeroCard(context, user, kyc),

                  const SizedBox(height: 16),

                  // 2. Quick Stats 4-Grid Row
                  _buildQuickStatsRow(appState, activeTickets, user),

                  const SizedBox(height: 20),

                  // 3. Menu Group: Account & Identity
                  _buildMenuSectionHeader('ACCOUNT & VERIFICATION'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.person_outline_rounded,
                          title: 'Personal Information',
                          subtitle: 'Legal name, contact and country details',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PersonalInformationScreen()),
                            );
                          },
                        ),
                        const Divider(color: AppColors.divider, height: 1),
                        _buildMenuItem(
                          icon: Icons.verified_user_outlined,
                          title: 'Identity Verification (KYC)',
                          subtitle: 'Smart NID, Passport & Liveness check',
                          badgeText: kyc.isVerified ? 'VERIFIED' : (kyc.isPending ? 'PENDING' : 'UNVERIFIED'),
                          badgeColor: kyc.statusColor,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const KycScreen()),
                            );
                          },
                        ),
                        const Divider(color: AppColors.divider, height: 1),
                        _buildMenuItem(
                          icon: Icons.card_giftcard_rounded,
                          title: 'Invite & Earn',
                          subtitle: 'Earn ৳100 + 5% draw bonus per friend',
                          badgeText: '৳100 BONUS',
                          badgeColor: AppColors.goldPrimary,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const InviteEarnScreen()),
                            );
                          },
                        ),
                        const Divider(color: AppColors.divider, height: 1),
                        _buildMenuItem(
                          icon: Icons.credit_card_outlined,
                          title: 'Payment Methods',
                          subtitle: 'bKash, Nagad, Rocket & Bank accounts',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const PaymentMethodsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 4. Menu Group: Security & App Settings
                  _buildMenuSectionHeader('SECURITY & PREFERENCES'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.shield_outlined,
                          title: 'Security',
                          subtitle: '2FA, Biometric Unlock, PIN & Sessions',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SecurityScreen()),
                            );
                          },
                        ),
                        const Divider(color: AppColors.divider, height: 1),
                        _buildMenuItem(
                          icon: Icons.notifications_none_rounded,
                          title: 'Notifications',
                          subtitle: 'Draw reminders, winning alerts & updates',
                          badgeText: appState.unreadNotificationsCount > 0
                              ? '${appState.unreadNotificationsCount} NEW'
                              : null,
                          badgeColor: AppColors.purpleAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                            );
                          },
                        ),
                        const Divider(color: AppColors.divider, height: 1),
                        _buildMenuItem(
                          icon: Icons.settings_outlined,
                          title: 'Settings',
                          subtitle: 'Language, sound effects & cache management',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SettingsScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // 5. Menu Group: Support & Legal
                  _buildMenuSectionHeader('SUPPORT & LEGAL'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Column(
                      children: [
                        _buildMenuItem(
                          icon: Icons.help_outline_rounded,
                          title: 'Help & Support',
                          subtitle: '24/7 Live Chat, FAQs & Helpline',
                          badgeText: '24/7 LIVE',
                          badgeColor: AppColors.greenAccent,
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const HelpSupportScreen()),
                            );
                          },
                        ),
                        const Divider(color: AppColors.divider, height: 1),
                        _buildMenuItem(
                          icon: Icons.description_outlined,
                          title: 'Terms & Policies',
                          subtitle: 'Terms of Service, Privacy & Fair Play',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const TermsPolicyScreen()),
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // 6. Logout Button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFEF4444),
                        side: const BorderSide(color: Color(0xFF7F1D1D), width: 1.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text(
                        'LOGOUT',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.0,
                        ),
                      ),
                      onPressed: () => _showLogoutDialog(context),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // App Version Footer
                  Text(
                    'TRADEX v1.0.4 • PLAY · WIN · REPEAT',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMuted,
                      letterSpacing: 0.8,
                    ),
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileHeroCard(BuildContext context, user, KycModel kyc) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF161B2B),
            Color(0xFF0F121C),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.35), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar with Crown Ring
              Stack(
                alignment: Alignment.topRight,
                children: [
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.goldPrimary, width: 2),
                    ),
                    child: const UserAvatar(size: 64),
                  ),
                  Positioned(
                    top: -2,
                    right: -2,
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Color(0xFF0F121C),
                        shape: BoxShape.circle,
                      ),
                      child: const CustomCrown(width: 14, height: 10),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),

              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            user.fullName,
                            style: GoogleFonts.inter(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.goldPrimary.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.4)),
                          ),
                          child: Text(
                            user.tier,
                            style: GoogleFonts.inter(
                              fontSize: 9.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '+880 1XXXXXXXXX',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        _buildKycBadge(kyc),
                        const SizedBox(width: 8),
                        Text(
                          '@${user.username}',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldAccent,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStatsRow(AppState appState, int activeTickets, user) {
    return Row(
      children: [
        Expanded(
          child: _buildQuickStatTile(
            label: 'Draws Played',
            value: '24',
            icon: Icons.confirmation_number_rounded,
            color: AppColors.purpleAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickStatTile(
            label: 'Total Won',
            value: '৳ ${appState.winningAmount.toStringAsFixed(0)}',
            icon: Icons.emoji_events_rounded,
            color: AppColors.goldPrimary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickStatTile(
            label: 'Active Tickets',
            value: '$activeTickets',
            icon: Icons.access_time_filled_rounded,
            color: AppColors.greenAccent,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildQuickStatTile(
            label: 'Referrals',
            value: '${user.referralCount}',
            icon: Icons.group_rounded,
            color: AppColors.cyanAccent,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickStatTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            label,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSectionHeader(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.textMuted,
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? badgeWidget,
    String? badgeText,
    Color? badgeColor,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.goldPrimary.withValues(alpha: 0.1),
        highlightColor: Colors.white.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBgElevated,
                ),
                child: Icon(icon, color: AppColors.goldPrimary, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            title,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        if (badgeWidget != null) ...[
                          const SizedBox(width: 8),
                          badgeWidget,
                        ] else if (badgeText != null) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: (badgeColor ?? AppColors.goldPrimary).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(
                                color: (badgeColor ?? AppColors.goldPrimary).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              badgeText,
                              style: GoogleFonts.inter(
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                                color: badgeColor ?? AppColors.goldLight,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKycBadge(KycModel kyc) {
    if (kyc.isVerified) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.greenBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.greenAccent.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          '✓ VERIFIED',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.greenLight,
          ),
        ),
      );
    } else if (kyc.isPending) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: const Color(0xFF2C220E),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.goldPrimary.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          '⏳ PENDING',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.goldLight,
          ),
        ),
      );
    } else {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: AppColors.redBg,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: AppColors.redAccent.withValues(alpha: 0.5),
          ),
        ),
        child: Text(
          '✕ UNVERIFIED',
          style: GoogleFonts.inter(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: AppColors.redAccent,
          ),
        ),
      );
    }
  }
}
