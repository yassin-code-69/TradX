import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class SessionInfo {
  final String device;
  final String location;
  final String lastActive;
  final String ip;
  final bool isCurrent;
  final IconData icon;

  const SessionInfo({
    required this.device,
    required this.location,
    required this.lastActive,
    required this.ip,
    required this.isCurrent,
    required this.icon,
  });
}

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final AppState _appState = AppState();

  // Password Form
  final _passwordFormKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isUpdatingPassword = false;

  // Active Sessions
  List<SessionInfo> _sessions = [
    const SessionInfo(
      device: 'Samsung Galaxy S24 Ultra',
      location: 'Dhaka, Bangladesh',
      lastActive: 'Active Now',
      ip: '103.112.22.45',
      isCurrent: true,
      icon: Icons.phone_android_rounded,
    ),
    const SessionInfo(
      device: 'Chrome on macOS (Sonoma)',
      location: 'Chittagong, Bangladesh',
      lastActive: '2 hours ago',
      ip: '103.112.22.89',
      isCurrent: false,
      icon: Icons.laptop_mac_rounded,
    ),
    const SessionInfo(
      device: 'iPhone 15 Pro Max',
      location: 'Sylhet, Bangladesh',
      lastActive: 'Yesterday | 08:30 PM',
      ip: '118.179.44.12',
      isCurrent: false,
      icon: Icons.phone_iphone_rounded,
    ),
  ];

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Password Strength Score
  int get _passwordStrengthScore {
    final text = _newPasswordController.text;
    if (text.isEmpty) return 0;
    int score = 0;
    if (text.length >= 8) score++;
    if (text.contains(RegExp(r'[A-Z]'))) score++;
    if (text.contains(RegExp(r'[0-9]'))) score++;
    if (text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) score++;
    return score;
  }

  Color get _passwordStrengthColor {
    switch (_passwordStrengthScore) {
      case 1:
        return AppColors.redAccent;
      case 2:
        return AppColors.orangeAccent;
      case 3:
        return AppColors.goldPrimary;
      case 4:
        return AppColors.greenAccent;
      default:
        return AppColors.cardBorder;
    }
  }

  String get _passwordStrengthText {
    switch (_passwordStrengthScore) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong & Secure';
      default:
        return '';
    }
  }

  Future<void> _updatePassword() async {
    if (!_passwordFormKey.currentState!.validate()) return;

    setState(() => _isUpdatingPassword = true);
    HapticFeedback.mediumImpact();

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;
    setState(() {
      _isUpdatingPassword = false;
      _currentPasswordController.clear();
      _newPasswordController.clear();
      _confirmPasswordController.clear();
    });

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
              'Password updated successfully!',
              style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  void _showPinSetupModal() {
    String enteredPin = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
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
                    'Setup App Security PIN',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Enter a 4-digit PIN for instant transaction approvals and withdrawals.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 24),

                  // PIN Digit Dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(4, (index) {
                      final isFilled = index < enteredPin.length;
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 10),
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isFilled ? AppColors.goldPrimary : Colors.transparent,
                          border: Border.all(
                            color: isFilled ? AppColors.goldPrimary : AppColors.cardBorderHighlight,
                            width: 2,
                          ),
                          boxShadow: isFilled
                              ? [
                                  BoxShadow(
                                    color: AppColors.goldPrimary.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),

                  // Numeric Keypad Simulation
                  Column(
                    children: [
                      _buildPinRow(['1', '2', '3'], enteredPin, (val) {
                        if (enteredPin.length < 4) {
                          setModalState(() => enteredPin += val);
                          HapticFeedback.lightImpact();
                          if (enteredPin.length == 4) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('4-Digit Security PIN saved successfully!')),
                            );
                          }
                        }
                      }),
                      const SizedBox(height: 12),
                      _buildPinRow(['4', '5', '6'], enteredPin, (val) {
                        if (enteredPin.length < 4) {
                          setModalState(() => enteredPin += val);
                          HapticFeedback.lightImpact();
                          if (enteredPin.length == 4) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('4-Digit Security PIN saved successfully!')),
                            );
                          }
                        }
                      }),
                      const SizedBox(height: 12),
                      _buildPinRow(['7', '8', '9'], enteredPin, (val) {
                        if (enteredPin.length < 4) {
                          setModalState(() => enteredPin += val);
                          HapticFeedback.lightImpact();
                          if (enteredPin.length == 4) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('4-Digit Security PIN saved successfully!')),
                            );
                          }
                        }
                      }),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          const SizedBox(width: 64, height: 50),
                          _buildPinButton('0', () {
                            if (enteredPin.length < 4) {
                              setModalState(() => enteredPin += '0');
                              HapticFeedback.lightImpact();
                              if (enteredPin.length == 4) {
                                Navigator.pop(ctx);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('4-Digit Security PIN saved successfully!')),
                                );
                              }
                            }
                          }),
                          InkWell(
                            onTap: () {
                              if (enteredPin.isNotEmpty) {
                                setModalState(() => enteredPin = enteredPin.substring(0, enteredPin.length - 1));
                                HapticFeedback.selectionClick();
                              }
                            },
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              width: 64,
                              height: 50,
                              decoration: BoxDecoration(
                                color: AppColors.cardBg,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.cardBorder),
                              ),
                              child: const Center(
                                child: Icon(Icons.backspace_outlined, color: Colors.white, size: 20),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPinRow(List<String> digits, String currentPin, Function(String) onDigit) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: digits.map((d) => _buildPinButton(d, () => onDigit(d))).toList(),
    );
  }

  Widget _buildPinButton(String digit, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: 64,
        height: 50,
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Center(
          child: Text(
            digit,
            style: GoogleFonts.inter(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  void _logoutOtherSessions() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBgElevated,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.cardBorder),
        ),
        title: Text(
          'Log Out Other Sessions',
          style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white),
        ),
        content: Text(
          'This will revoke all active access tokens except your current device session.',
          style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('CANCEL', style: GoogleFonts.inter(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.redAccent,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              Navigator.pop(ctx);
              setState(() {
                _sessions = _sessions.where((s) => s.isCurrent).toList();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('All other sessions terminated successfully')),
              );
            },
            child: Text('LOG OUT OTHERS', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: Colors.white)),
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
          'Security & 2FA',
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

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Two-Factor Authentication & Biometrics Card
                  Text(
                    'AUTHENTICATION & ACCESS',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),

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
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.goldPrimary.withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.shield_rounded, color: AppColors.goldPrimary, size: 22),
                            ),
                            title: Text(
                              'Two-Factor Authentication (2FA)',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            subtitle: Text(
                              'Requires 6-digit SMS / Email OTP for logins and withdrawal requests',
                              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                            value: user.twoFactorEnabled,
                            activeThumbColor: AppColors.goldPrimary,
                            onChanged: (val) {
                              _appState.updateSecuritySettings(twoFactor: val);
                              HapticFeedback.lightImpact();
                            },
                          ),
                          const Divider(color: AppColors.divider, height: 1),
                          SwitchListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            secondary: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.purpleAccent.withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.fingerprint_rounded, color: AppColors.purpleAccent, size: 22),
                            ),
                            title: Text(
                              'Biometric Unlock',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            subtitle: Text(
                              'Use Fingerprint / Face ID for fast login and payment confirmation',
                              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                            value: user.biometricsEnabled,
                            activeThumbColor: AppColors.goldPrimary,
                            onChanged: (val) {
                              _appState.updateSecuritySettings(biometrics: val);
                              HapticFeedback.lightImpact();
                            },
                          ),
                          const Divider(color: AppColors.divider, height: 1),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppColors.greenAccent.withValues(alpha: 0.15),
                              ),
                              child: const Icon(Icons.pin_rounded, color: AppColors.greenAccent, size: 22),
                            ),
                            title: Text(
                              'App Security PIN',
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                            ),
                            subtitle: Text(
                              'Setup 4-digit PIN for instant draw purchases and payouts',
                              style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                            onTap: _showPinSetupModal,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 2. Change Password Form Card
                  Text(
                    'CHANGE PASSWORD',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textMuted,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 8),

                  GlassCard(
                    child: Form(
                      key: _passwordFormKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Current Password
                          TradexTextField(
                            controller: _currentPasswordController,
                            label: 'Current Password',
                            hint: '••••••••',
                            obscureText: _obscureCurrent,
                            prefixIcon: Icons.lock_outline_rounded,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                            ),
                            validator: (v) => v == null || v.isEmpty ? 'Enter your current password' : null,
                          ),
                          const SizedBox(height: 14),

                          // New Password
                          TradexTextField(
                            controller: _newPasswordController,
                            label: 'New Password',
                            hint: '••••••••',
                            obscureText: _obscureNew,
                            prefixIcon: Icons.lock_reset_rounded,
                            onChanged: (_) => setState(() {}),
                            suffix: IconButton(
                              icon: Icon(
                                _obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureNew = !_obscureNew),
                            ),
                            validator: (v) {
                              if (v == null || v.length < 8) return 'Password must be at least 8 characters';
                              return null;
                            },
                          ),

                          if (_newPasswordController.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: _passwordStrengthScore / 4,
                                      minHeight: 5,
                                      backgroundColor: AppColors.cardBorder,
                                      valueColor: AlwaysStoppedAnimation<Color>(_passwordStrengthColor),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _passwordStrengthText,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: _passwordStrengthColor,
                                  ),
                                ),
                              ],
                            ),
                          ],

                          const SizedBox(height: 14),

                          // Confirm New Password
                          TradexTextField(
                            controller: _confirmPasswordController,
                            label: 'Confirm New Password',
                            hint: '••••••••',
                            obscureText: _obscureConfirm,
                            prefixIcon: Icons.lock_reset_rounded,
                            suffix: IconButton(
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                            validator: (v) {
                              if (v != _newPasswordController.text) return 'Passwords do not match';
                              return null;
                            },
                          ),
                          const SizedBox(height: 18),

                          TradexButton(
                            text: 'UPDATE PASSWORD',
                            isLoading: _isUpdatingPassword,
                            width: double.infinity,
                            onPressed: _updatePassword,
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 3. Active Sessions Card
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'ACTIVE LOGIN SESSIONS (${_sessions.length})',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMuted,
                          letterSpacing: 1.0,
                        ),
                      ),
                      if (_sessions.length > 1)
                        TextButton(
                          onPressed: _logoutOtherSessions,
                          child: Text(
                            'Log Out Others',
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: AppColors.redAccent,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.cardBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.cardBorder),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _sessions.length,
                        separatorBuilder: (context, index) => const Divider(color: AppColors.divider, height: 1),
                        itemBuilder: (context, index) {
                        final s = _sessions[index];
                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: s.isCurrent
                                  ? AppColors.greenAccent.withValues(alpha: 0.15)
                                  : AppColors.cardBgElevated,
                            ),
                            child: Icon(
                              s.icon,
                              color: s.isCurrent ? AppColors.greenAccent : AppColors.textSecondary,
                              size: 22,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                s.device,
                                style: GoogleFonts.inter(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              if (s.isCurrent) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: AppColors.greenBg,
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(color: AppColors.greenAccent.withValues(alpha: 0.5)),
                                  ),
                                  child: Text(
                                    'THIS DEVICE',
                                    style: GoogleFonts.inter(
                                      fontSize: 8.5,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.greenLight,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            '${s.location} • IP: ${s.ip}\n${s.lastActive}',
                            style: GoogleFonts.inter(fontSize: 11, color: AppColors.textSecondary, height: 1.3),
                          ),
                          isThreeLine: true,
                        );
                      },
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
}
