import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/screens/auth/login_screen.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  // Real-time strength criteria
  bool get _hasMinLength => _newPasswordController.text.length >= 8;
  bool get _hasUppercase =>
      _newPasswordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasNumber =>
      _newPasswordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar =>
      _newPasswordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  int get _strengthScore {
    int score = 0;
    if (_hasMinLength) score++;
    if (_hasUppercase) score++;
    if (_hasNumber) score++;
    if (_hasSpecialChar) score++;
    return score;
  }

  String get _strengthLabel {
    final score = _strengthScore;
    if (score <= 1) return 'Weak';
    if (score <= 3) return 'Medium';
    return 'Strong';
  }

  Color get _strengthColor {
    final score = _strengthScore;
    if (score <= 1) return AppColors.redAccent;
    if (score <= 3) return AppColors.goldPrimary;
    return AppColors.greenAccent;
  }

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    if (_strengthScore < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.redBg,
          content: Text('Please choose a stronger password to continue.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    _showSuccessDialog();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.cardBgElevated,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.goldPrimary.withValues(alpha: 0.4),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Success Badge
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.greenAccent.withValues(alpha: 0.15),
                    border: Border.all(
                      color: AppColors.greenAccent,
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.greenAccent.withValues(alpha: 0.3),
                        blurRadius: 18,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 40,
                    color: AppColors.greenLight,
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Password Updated!',
                  style: GoogleFonts.poppins(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),

                Text(
                  'Your TRADEX account password has been reset successfully. Please log in with your new credentials.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                TradexButton(
                  text: 'PROCEED TO LOGIN',
                  icon: Icons.login_rounded,
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  height: 48,
                  variant: TradexButtonVariant.primaryGold,
                ),
              ],
            ),
          ),
        );
      },
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Create New Password',
          style: GoogleFonts.inter(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 10),

                // Lock reset hero badge
                Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldPrimary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldPrimary.withValues(alpha: 0.2),
                        blurRadius: 20,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.security_rounded,
                    size: 38,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(height: 18),

                Text(
                  'Set Secure Password',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Must be at least 8 characters and include numbers or symbols for account security.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Form Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // New Password Field
                      TradexTextField(
                        controller: _newPasswordController,
                        label: 'New Password',
                        hint: 'Enter strong password',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscureNew,
                        onChanged: (_) => setState(() {}),
                        suffix: IconButton(
                          icon: Icon(
                            _obscureNew
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureNew = !_obscureNew;
                            });
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter new password';
                          }
                          if (val.length < 8) {
                            return 'Password must be at least 8 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Real-time Strength Meter Bar
                      if (_newPasswordController.text.isNotEmpty) ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Password Strength',
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            Text(
                              _strengthLabel,
                              style: GoogleFonts.inter(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: _strengthColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: List.generate(4, (index) {
                            final bool filled = index < _strengthScore;
                            return Expanded(
                              child: Container(
                                height: 4,
                                margin: const EdgeInsets.symmetric(horizontal: 2),
                                decoration: BoxDecoration(
                                  color: filled
                                      ? _strengthColor
                                      : AppColors.cardBorder,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            );
                          }),
                        ),
                        const SizedBox(height: 14),

                        // Requirement checklist chips
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildCheckRow('At least 8 characters', _hasMinLength),
                            _buildCheckRow('One uppercase letter (A-Z)', _hasUppercase),
                            _buildCheckRow('One number (0-9)', _hasNumber),
                            _buildCheckRow('One special character (!@#\$%)', _hasSpecialChar),
                          ],
                        ),
                        const SizedBox(height: 14),
                      ],

                      // Confirm Password Field
                      TradexTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm New Password',
                        hint: 'Re-enter new password',
                        prefixIcon: Icons.lock_reset_rounded,
                        obscureText: _obscureConfirm,
                        onChanged: (_) => setState(() {}),
                        suffix: IconButton(
                          icon: Icon(
                            _obscureConfirm
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscureConfirm = !_obscureConfirm;
                            });
                          },
                        ),
                        validator: (val) {
                          if (val != _newPasswordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),

                      // Reset Password Submit Button
                      TradexButton(
                        text: 'RESET PASSWORD',
                        icon: Icons.check_circle_outline_rounded,
                        onPressed: _handleResetPassword,
                        isLoading: _isLoading,
                        height: 50,
                        variant: TradexButtonVariant.primaryGold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Return to Login Link
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false,
                    );
                  },
                  child: Text(
                    'Cancel & Return to Login',
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckRow(String label, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
            size: 14,
            color: isMet ? AppColors.greenAccent : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.5,
              color: isMet ? Colors.white : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
