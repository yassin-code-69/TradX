import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final AppState _appState = AppState();
  double _cacheSizeMB = 42.8;

  void _clearCache() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          'Clear Temporary Cache',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          'This will clear ${_cacheSizeMB.toStringAsFixed(1)} MB of temporary lottery images, draw logs, and cached asset previews. Your account data remains secure.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.goldPrimary,
              foregroundColor: const Color(0xFF0F111A),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              final freed = _cacheSizeMB;
              setState(() => _cacheSizeMB = 0.0);
              HapticFeedback.mediumImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  backgroundColor: AppColors.cardBgElevated,
                  behavior: SnackBarBehavior.floating,
                  content: Row(
                    children: [
                      const Icon(Icons.cleaning_services_rounded, color: AppColors.greenAccent, size: 20),
                      const SizedBox(width: 10),
                      Text(
                        'Cache cleared (${freed.toStringAsFixed(1)} MB freed)',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ],
                  ),
                ),
              );
            },
            child: Text('CLEAR NOW', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  void _showChangelogModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.cardBgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.textMuted,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'What\'s New in TRADEX',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.goldPrimary),
                    ),
                    child: Text(
                      'v1.0.4',
                      style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.goldLight),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _buildChangelogItem('👑 Multi-Tier VIP Referral Program with up to 7% lifetime draw commission'),
              _buildChangelogItem('⚡ Instant bKash & Nagad withdrawal gateway with sub-second approvals'),
              _buildChangelogItem('🛡️ Complete 5-Step Identity Verification (KYC) with automated liveness detection'),
              _buildChangelogItem('🎯 Provably Fair RNG Winning Number Checker tool for all previous draws'),
              _buildChangelogItem('💬 24/7 Live Concierge Chat Support directly integrated inside the app'),
              const SizedBox(height: 20),
              TradexButton(
                text: 'CLOSE',
                width: double.infinity,
                variant: TradexButtonVariant.outline,
                onPressed: () => Navigator.pop(ctx),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChangelogItem(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.goldPrimary, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textPrimary, height: 1.35),
            ),
          ),
        ],
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
          'App Settings',
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
            final isBengali = _appState.selectedLanguage == 'বাংলা';

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Language Selection Card
                  _buildSectionHeader('LANGUAGE / ভাষা'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          _buildLanguageTile('English', 'English (US)', !isBengali, () {
                            _appState.setLanguage('English');
                            HapticFeedback.lightImpact();
                          }),
                          const Divider(color: AppColors.divider, height: 1),
                          _buildLanguageTile('বাংলা', 'Bengali (Bangladesh)', isBengali, () {
                            _appState.setLanguage('বাংলা');
                            HapticFeedback.lightImpact();
                          }),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Audio & Micro-Interactions
                  _buildSectionHeader('AUDIO & TACTILE FEEDBACK'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            secondary: const Icon(Icons.volume_up_rounded, color: AppColors.goldPrimary),
                            title: Text(
                              'Sound Effects',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            subtitle: Text(
                              'Play audio on keypad tap, ticket buy & win reveals',
                              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                            value: _appState.soundEnabled,
                            activeThumbColor: AppColors.goldPrimary,
                            onChanged: (val) {
                              _appState.toggleSound(val);
                              HapticFeedback.lightImpact();
                            },
                          ),
                          const Divider(color: AppColors.divider, height: 1),
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            secondary: const Icon(Icons.vibration_rounded, color: AppColors.purpleAccent),
                            title: Text(
                              'Haptic Feedback',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            subtitle: Text(
                              'Tactile vibrations on keypress and number selections',
                              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                            value: _appState.hapticsEnabled,
                            activeThumbColor: AppColors.goldPrimary,
                            onChanged: (val) {
                              _appState.toggleHaptics(val);
                              if (val) HapticFeedback.mediumImpact();
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Notification Preferences
                  _buildSectionHeader('NOTIFICATION PREFERENCES'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            title: Text(
                              'Draw Reminders',
                              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            subtitle: Text(
                              'Alerts 15 mins before Hourly & Daily draws close',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            value: _appState.drawRemindersEnabled,
                            activeThumbColor: AppColors.goldPrimary,
                            onChanged: (val) => _appState.toggleDrawReminders(val),
                          ),
                          const Divider(color: AppColors.divider, height: 1),
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            title: Text(
                              'Winning Alerts',
                              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            subtitle: Text(
                              'Instant notification when your ticket wins any prize tier',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            value: _appState.winningAlertsEnabled,
                            activeThumbColor: AppColors.goldPrimary,
                            onChanged: (val) => _appState.toggleWinningAlerts(val),
                          ),
                          const Divider(color: AppColors.divider, height: 1),
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            title: Text(
                              'Wallet & Payout Alerts',
                              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            subtitle: Text(
                              'Deposit confirmation and withdrawal status updates',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            value: _appState.walletAlertsEnabled,
                            activeThumbColor: AppColors.goldPrimary,
                            onChanged: (val) => _appState.toggleWalletAlerts(val),
                          ),
                          const Divider(color: AppColors.divider, height: 1),
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            title: Text(
                              'Promotions & Bonus Offers',
                              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            subtitle: Text(
                              'Exclusive cashback, referral bonus and deposit boosts',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            value: _appState.promotionsEnabled,
                            activeThumbColor: AppColors.goldPrimary,
                            onChanged: (val) => _appState.togglePromotions(val),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 4. Storage & Cache
                  _buildSectionHeader('STORAGE & PERFORMANCE'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                        leading: const Icon(Icons.delete_sweep_rounded, color: AppColors.goldPrimary),
                        title: Text(
                          'Clear App Cache',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                        ),
                        subtitle: Text(
                          _cacheSizeMB > 0 ? '${_cacheSizeMB.toStringAsFixed(1)} MB temporary storage' : 'Cache is empty',
                          style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                        ),
                        trailing: Text(
                          'CLEAR',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            color: _cacheSizeMB > 0 ? AppColors.goldLight : AppColors.textMuted,
                          ),
                        ),
                        onTap: _cacheSizeMB > 0 ? _clearCache : null,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 5. App Info & Version
                  _buildSectionHeader('ABOUT & SYSTEM'),
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: Column(
                        children: [
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: const Icon(Icons.info_outline_rounded, color: AppColors.cyanAccent),
                            title: Text(
                              'Version & Build',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            subtitle: Text('TRADEX v1.0.4 (Build 2026.08)', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.greenBg,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.greenAccent.withValues(alpha: 0.5)),
                              ),
                              child: Text(
                                'LATEST',
                                style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w800, color: AppColors.greenLight),
                              ),
                            ),
                          ),
                          const Divider(color: AppColors.divider, height: 1),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: const Icon(Icons.history_edu_rounded, color: AppColors.goldPrimary),
                            title: Text(
                              'View Changelog',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            subtitle: Text('See what was added in recent updates', style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary)),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                            onTap: _showChangelogModal,
                          ),
                          const Divider(color: AppColors.divider, height: 1),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: const Icon(Icons.system_update_rounded, color: AppColors.greenAccent),
                            title: Text(
                              'Check for Updates',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                            onTap: () {
                              HapticFeedback.lightImpact();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('You are on the latest version of TRADEX!')),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.textMuted,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildLanguageTile(String title, String subtitle, bool isSelected, VoidCallback onTap) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
      onTap: onTap,
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          color: isSelected ? AppColors.goldLight : Colors.white,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
      ),
      trailing: isSelected
          ? const Icon(Icons.check_circle_rounded, color: AppColors.goldPrimary, size: 20)
          : const Icon(Icons.circle_outlined, color: AppColors.cardBorderHighlight, size: 20),
    );
  }
}
