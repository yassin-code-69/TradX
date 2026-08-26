import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/notification_model.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

// Re-export dedicated screens for seamless backwards compatibility
export 'package:tradex/screens/help_support_screen.dart';
export 'package:tradex/screens/invite_earn_screen.dart';
export 'package:tradex/screens/kyc_screen.dart';
export 'package:tradex/screens/payment_methods_screen.dart';
export 'package:tradex/screens/security_screen.dart';
export 'package:tradex/screens/settings_screen.dart';
export 'package:tradex/screens/support_chat_screen.dart';
export 'package:tradex/screens/terms_policy_screen.dart';

/// 1. Personal Information Screen
class PersonalInformationScreen extends StatefulWidget {
  const PersonalInformationScreen({super.key});

  @override
  State<PersonalInformationScreen> createState() => _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  final AppState _appState = AppState();
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _fullNameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _countryController;
  late TextEditingController _usernameController;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    final user = _appState.currentUser;
    _fullNameController = TextEditingController(text: user.fullName);
    _emailController = TextEditingController(text: user.email);
    _phoneController = TextEditingController(text: user.phone);
    _countryController = TextEditingController(text: user.country);
    _usernameController = TextEditingController(text: user.username);
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _countryController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  void _saveProfile() {
    if (!_formKey.currentState!.validate()) return;

    _appState.updateProfile(
      fullName: _fullNameController.text.trim(),
      phone: _phoneController.text.trim(),
      email: _emailController.text.trim(),
    );

    setState(() => _isEditing = false);
    HapticFeedback.lightImpact();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.cardBgElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.greenAccent),
        ),
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.greenAccent, size: 20),
            const SizedBox(width: 10),
            Text(
              'Profile updated successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
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
          'Personal Information',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.close_rounded : Icons.edit_outlined, color: AppColors.goldPrimary),
            tooltip: _isEditing ? 'Cancel Edit' : 'Edit Profile',
            onPressed: () => setState(() => _isEditing = !_isEditing),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Identity Verification Status Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.greenBg,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.greenAccent.withValues(alpha: 0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.verified_user_rounded, color: AppColors.greenAccent, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Verified Account (Tier 2 VIP)',
                              style: GoogleFonts.inter(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'Your legal name is locked to match verified NID documents.',
                              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.greenLight),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                _buildFieldCard('Full Name', _fullNameController.text, _fullNameController, readOnly: true),
                const SizedBox(height: 12),
                _buildFieldCard('Username', '@${_usernameController.text}', _usernameController, readOnly: true),
                const SizedBox(height: 12),
                _buildFieldCard('Email Address', _emailController.text, _emailController, readOnly: !_isEditing),
                const SizedBox(height: 12),
                _buildFieldCard('Phone Number', _phoneController.text, _phoneController, readOnly: !_isEditing),
                const SizedBox(height: 12),
                _buildFieldCard('National ID / Passport', 'NID-9482938472', null, readOnly: true),
                const SizedBox(height: 12),
                _buildFieldCard('Country', 'Bangladesh', _countryController, readOnly: true),

                const SizedBox(height: 28),

                if (_isEditing) ...[
                  TradexButton(
                    text: 'SAVE CHANGES',
                    width: double.infinity,
                    onPressed: _saveProfile,
                  ),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFieldCard(String label, String value, TextEditingController? controller, {bool readOnly = false}) {
    if (_isEditing && !readOnly && controller != null) {
      return TradexTextField(
        controller: controller,
        label: label,
        prefixIcon: label.contains('Email') ? Icons.email_outlined : Icons.phone_outlined,
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
          ),
        ],
      ),
    );
  }
}

/// 2. Notifications Screen
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

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
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          TextButton(
            onPressed: () => appState.markAllNotificationsAsRead(),
            child: Text(
              'Mark Read',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.goldPrimary),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListenableBuilder(
          listenable: appState,
          builder: (context, _) {
            final notifications = appState.notifications;

            if (notifications.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.notifications_off_outlined, color: AppColors.textMuted, size: 54),
                    const SizedBox(height: 12),
                    Text(
                      'No Notifications Yet',
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Draw alerts, winning notices, and deposit updates will appear here.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              itemCount: notifications.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return _buildNotificationItem(notif, appState);
              },
            );
          },
        ),
      ),
    );
  }

  Widget _buildNotificationItem(NotificationModel notif, AppState appState) {
    Color iconColor;
    IconData icon;

    switch (notif.category) {
      case NotificationCategory.winnings:
        iconColor = AppColors.goldPrimary;
        icon = Icons.emoji_events_rounded;
        break;
      case NotificationCategory.draws:
        iconColor = AppColors.purpleAccent;
        icon = Icons.access_time_filled_rounded;
        break;
      case NotificationCategory.wallet:
        iconColor = AppColors.greenAccent;
        icon = Icons.account_balance_wallet_rounded;
        break;
      case NotificationCategory.promotions:
        iconColor = AppColors.orangeAccent;
        icon = Icons.card_giftcard_rounded;
        break;
      default:
        iconColor = AppColors.cyanAccent;
        icon = Icons.notifications_rounded;
    }

    return InkWell(
      onTap: () => appState.markNotificationAsRead(notif.id),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: notif.isRead ? AppColors.cardBg : AppColors.cardBgElevated,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: notif.isRead ? AppColors.cardBorder : AppColors.goldPrimary.withValues(alpha: 0.4),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          notif.title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: notif.isRead ? FontWeight.w600 : FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      Text(
                        notif.timeAgo,
                        style: GoogleFonts.inter(fontSize: 11, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    notif.message,
                    style: GoogleFonts.inter(
                      fontSize: 12.5,
                      color: AppColors.textSecondary,
                      height: 1.35,
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
}
