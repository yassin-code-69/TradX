import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/screens/auth/forgot_password_screen.dart';
import 'package:tradex/screens/auth/register_screen.dart';
import 'package:tradex/screens/main_shell_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/custom_crown.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _identifierController =
      TextEditingController(text: '01712345678');
  final TextEditingController _passwordController =
      TextEditingController(text: 'Password123!');

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    setState(() {
      _isLoading = true;
    });
    HapticFeedback.lightImpact();

    // Simulated network authentication
    await Future.delayed(const Duration(milliseconds: 900));

    if (!mounted) return;

    final appState = AppState();
    final success = appState.login(
      _identifierController.text.trim(),
      _passwordController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.cardBgElevated,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: const BorderSide(color: AppColors.goldPrimary, width: 1),
          ),
          content: Row(
            children: [
              const Icon(Icons.check_circle_rounded,
                  color: AppColors.goldPrimary, size: 20),
              const SizedBox(width: 10),
              Text(
                'Welcome back to TRADEX!',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainShellScreen()),
        (route) => false,
      );
    }
  }

  void _quickFill(String identifier, String password) {
    setState(() {
      _identifierController.text = identifier;
      _passwordController.text = password;
    });
    HapticFeedback.selectionClick();
  }

  void _handleBiometrics() async {
    HapticFeedback.heavyImpact();
    setState(() {
      _isLoading = true;
    });
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;
    AppState().login('biometric_user', 'biometric_auth');
    setState(() {
      _isLoading = false;
    });
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const MainShellScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 12),

                // Brand Crest & Glow
                Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.goldPrimary.withValues(alpha: 0.35),
                            blurRadius: 28,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const CustomCrown(
                      width: 44,
                      height: 24,
                      color: AppColors.goldPrimary,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Header Titles
                Text(
                  'Welcome to TRADEX',
                  style: GoogleFonts.poppins(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Sign in to access your lottery wallet & live draws',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Quick Demo Login Selection Chips
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardBgElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.25),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.bolt_rounded,
                            size: 16,
                            color: AppColors.goldLight,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'QUICK DEMO ACCOUNTS',
                            style: GoogleFonts.inter(
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDemoChip(
                              label: 'VIP Platinum',
                              sub: 'Shek Ahmmed',
                              onTap: () => _quickFill(
                                'shekahmmed@email.com',
                                'Password123!',
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDemoChip(
                              label: 'Active Player',
                              sub: '+880 1712...',
                              onTap: () => _quickFill(
                                '01712345678',
                                'tradex2026',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Main Form Card
                GlassCard(
                  padding: const EdgeInsets.all(20),
                  borderRadius: 18,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Identifier input (Phone or Email)
                      TradexTextField(
                        controller: _identifierController,
                        label: 'Email or Mobile Number',
                        hint: '017XXXXXXXX or user@domain.com',
                        prefixIcon: Icons.phone_android_rounded,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.trim().isEmpty) {
                            return 'Please enter your email or phone';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password input
                      TradexTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: '••••••••',
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_off_outlined
                                : Icons.visibility_outlined,
                            color: AppColors.textSecondary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _obscurePassword = !_obscurePassword;
                            });
                          },
                        ),
                        validator: (val) {
                          if (val == null || val.isEmpty) {
                            return 'Please enter your password';
                          }
                          if (val.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 14),

                      // Remember Me & Forgot Password Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _rememberMe = !_rememberMe;
                              });
                            },
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: Checkbox(
                                    value: _rememberMe,
                                    activeColor: AppColors.goldPrimary,
                                    checkColor: Colors.black,
                                    side: const BorderSide(
                                      color: AppColors.cardBorderHighlight,
                                      width: 1.5,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    onChanged: (val) {
                                      setState(() {
                                        _rememberMe = val ?? true;
                                      });
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Remember me',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot Password?',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.goldLight,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),

                      // Login Button
                      TradexButton(
                        text: 'LOGIN TO ACCOUNT',
                        icon: Icons.login_rounded,
                        onPressed: _handleLogin,
                        isLoading: _isLoading,
                        height: 50,
                        variant: TradexButtonVariant.primaryGold,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Biometric Login Option
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppColors.divider)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      child: Text(
                        'OR QUICK ACCESS',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.0,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const Expanded(child: Divider(color: AppColors.divider)),
                  ],
                ),
                const SizedBox(height: 14),

                // Biometric Fingerprint Button
                Center(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _handleBiometrics,
                      borderRadius: BorderRadius.circular(30),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.cardBg,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: AppColors.cardBorderHighlight,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.fingerprint_rounded,
                              size: 24,
                              color: AppColors.goldPrimary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Biometric Face ID / Fingerprint',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 28),

                // Register Link Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.inter(
                        fontSize: 13.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const RegisterScreen(),
                          ),
                        );
                      },
                      child: Text(
                        'Sign Up Free',
                        style: GoogleFonts.inter(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.goldPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDemoChip({
    required String label,
    required String sub,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppColors.goldLight,
                ),
              ),
              Text(
                sub,
                style: GoogleFonts.inter(
                  fontSize: 9.5,
                  color: AppColors.textMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
