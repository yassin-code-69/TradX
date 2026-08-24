import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/custom_crown.dart';
import 'package:tradex/widgets/user_avatar.dart';

class AppDrawer extends StatelessWidget {
  final Function(String route) onNavigate;

  const AppDrawer({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final appState = AppState();

    return Drawer(
      backgroundColor: AppColors.backgroundSecondary,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const UserAvatar(size: 52),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Shek Ahmmed',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const CustomCrown(width: 14, height: 9),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'shekahmmed@email.com',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
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
                              fontWeight: FontWeight.w700,
                              color: AppColors.greenLight,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Navigation Items
            Expanded(
              child: ListenableBuilder(
                listenable: appState,
                builder: (context, _) {
                  return ListView(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    children: [
                      _buildDrawerItem(
                        icon: Icons.home_rounded,
                        title: 'Home',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('home');
                        },
                        selected: true,
                      ),
                      _buildDrawerItem(
                        icon: Icons.account_balance_wallet_rounded,
                        title: 'Wallet',
                        subtitle: '৳ ${appState.formattedBalance}',
                        badgeColor: AppColors.purpleLight,
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('wallet');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.add_circle_outline_rounded,
                        title: 'Add Money',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('add_money');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.payments_outlined,
                        title: 'Withdraw',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('withdraw');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.history_rounded,
                        title: 'Transaction History',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('history');
                        },
                      ),
                      const Divider(color: AppColors.divider, height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                        child: Text(
                          'DRAWS & LOTTERY',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      _buildDrawerItem(
                        icon: Icons.emoji_events_rounded,
                        title: 'Mega Draw',
                        subtitle: 'Prize ৳ 5,00,000',
                        badgeColor: AppColors.goldPrimary,
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('mega_draw');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.confirmation_number_rounded,
                        title: 'Daily Draw',
                        subtitle: 'Prize ৳ 50,000',
                        badgeColor: AppColors.greenAccent,
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('daily_draw');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.access_time_filled_rounded,
                        title: 'Hourly Draw',
                        subtitle: 'Prize ৳ 20,000',
                        badgeColor: AppColors.purpleAccent,
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('hourly_draw');
                        },
                      ),
                      _buildDrawerItem(
                        icon: Icons.leaderboard_rounded,
                        title: 'All Results',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('results');
                        },
                      ),
                      const Divider(color: AppColors.divider, height: 24),
                      _buildDrawerItem(
                        icon: Icons.person_outline_rounded,
                        title: 'Profile Settings',
                        onTap: () {
                          Navigator.pop(context);
                          onNavigate('profile');
                        },
                      ),
                    ],
                  );
                },
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: AppColors.divider, width: 1),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TRADEX v1.0.0',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.textMuted,
                    ),
                  ),
                  Text(
                    'PLAY • WIN • REPEAT',
                    style: GoogleFonts.inter(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.goldDark,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    String? subtitle,
    Color? badgeColor,
    required VoidCallback onTap,
    bool selected = false,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        color: selected ? AppColors.goldPrimary : AppColors.textSecondary,
        size: 22,
      ),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          color: selected ? Colors.white : AppColors.textPrimary,
        ),
      ),
      subtitle: subtitle != null
          ? Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: badgeColor ?? AppColors.textSecondary,
              ),
            )
          : null,
      dense: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      tileColor: selected ? AppColors.cardBg : Colors.transparent,
      onTap: onTap,
    );
  }
}
