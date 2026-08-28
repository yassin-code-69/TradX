import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/screens/auth/otp_verification_screen.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _inputController =
      TextEditingController(text: '01712345678');
  bool _isPhoneMode = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _inputController.dispose();
    super.dispose();
  }

  void _handleSendCode() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      _isLoading = true;
    });
    HapticFeedback.lightImpact();

    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    setState(() {
      _isLoading = false;
    });

    final target = _inputController.text.trim();
    final formattedTarget = _isPhoneMode
        ? (target.startsWith('+880') ? target : '+880 $target')
        : target;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OtpVerificationScreen(
          target: formattedTarget,
          isPhone: _isPhoneMode,
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
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Forgot Password',
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // Radiant Security Lock Hero Icon
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.goldPrimary.withValues(alpha: 0.12),
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.goldPrimary.withValues(alpha: 0.25),
                        blurRadius: 24,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.lock_reset_rounded,
                    size: 40,
                    color: AppColors.goldLight,
                  ),
                ),
                const SizedBox(height: 20),

                // Title & Subtitle
                Text(
                  'Recover Account',
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select your preferred recovery channel. We will send a 6-digit OTP code to verify your identity.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),

                // Recovery Channel Selector (Phone vs Email)
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildChannelTab(
                          label: 'Mobile (+880)',
                          icon: Icons.phone_android_rounded,
                          isSelected: _isPhoneMode,
                          onTap: () {
                            setState(() {
                              _isPhoneMode = true;
                              _inputController.text = '01712345678';
                            });
                          },
                        ),
                      ),
                      Expanded(
                        child: _buildChannelTab(
                          label: 'Email Address',
                          icon: Icons.email_outlined,
                          isSelected: !_isPhoneMode,
                          onTap: () {
                            setState(() {
                              _isPhoneMode = false;
                              _inputController.text = 'shekahmmed@email.com';
                            });
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Input Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isPhoneMode) ...[
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Registered Mobile Number',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  height: 50,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10),
                                  decoration: BoxDecoration(
                                    color: AppColors.cardBgElevated,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.cardBorder),
                                  ),
                                  alignment: Alignment.center,
                                  child: Row(
                                    children: [
                                      const Text('🇧🇩',
                                          style: TextStyle(fontSize: 16)),
                                      const SizedBox(width: 4),
                                      Text(
                                        '+880',
                                        style: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.cardBg,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                          color: AppColors.cardBorder),
                                    ),
                                    child: TextFormField(
                                      controller: _inputController,
                                      keyboardType: TextInputType.phone,
                                      style: GoogleFonts.inter(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.white,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: '17XXXXXXXX',
                                        hintStyle: GoogleFonts.inter(
                                          fontSize: 13.5,
                                          color: AppColors.textMuted,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                                horizontal: 14, vertical: 14),
                                      ),
                                      validator: (val) {
                                        if (val == null || val.trim().isEmpty) {
                                          return 'Please enter phone number';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ] else ...[
                        TradexTextField(
                          controller: _inputController,
                          label: 'Registered Email Address',
                          hint: 'user@domain.com',
                          prefixIcon: Icons.email_outlined,
                          keyboardType: TextInputType.emailAddress,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) {
                              return 'Please enter your email';
                            }
                            if (!val.contains('@')) {
                              return 'Invalid email address';
                            }
                            return null;
                          },
                        ),
                      ],
                      const SizedBox(height: 24),

                      TradexButton(
                        text: 'SEND VERIFICATION CODE',
                        icon: Icons.send_rounded,
                        onPressed: _handleSendCode,
                        isLoading: _isLoading,
                        height: 50,
                        variant: TradexButtonVariant.primaryGold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Security Note Card
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.cardBorder,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        size: 20,
                        color: AppColors.goldPrimary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Your account security is 256-bit encrypted. Never share OTP codes with anyone.',
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            color: AppColors.textSecondary,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Back to Login Link
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.arrow_back_rounded,
                        size: 16,
                        color: AppColors.goldPrimary,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Return to Login',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildChannelTab({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.goldPrimary.withValues(alpha: 0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            border: isSelected
                ? Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5))
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16,
                color: isSelected ? AppColors.goldLight : AppColors.textMuted,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected ? Colors.white : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
