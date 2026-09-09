import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:tradex/screens/auth/reset_password_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String target;
  final bool isPhone;

  const OtpVerificationScreen({
    super.key,
    this.target = '',
    this.isPhone = false,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  static const int _otpLength = 6;
  final List<TextEditingController> _controllers =
      List.generate(_otpLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes =
      List.generate(_otpLength, (_) => FocusNode());

  int _resendCountdown = 59;
  Timer? _timer;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _startTimer();

    // Auto-focus first digit field
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNodes[0].requestFocus();
      }
    });
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _resendCountdown = 59;
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        if (mounted) {
          setState(() {
            _resendCountdown--;
          });
        }
      } else {
        timer.cancel();
      }
    });
  }

  String get _currentOtp =>
      _controllers.map((c) => c.text).join();

  void _onDigitChanged(int index, String value) {
    if (value.isNotEmpty) {
      // If user pasted multi-digit text
      if (value.length > 1) {
        _handlePastedOtp(value);
        return;
      }

      if (index < _otpLength - 1) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        if (_currentOtp.length == _otpLength) {
          _handleVerify();
        }
      }
    }
  }

  void _handlePastedOtp(String raw) {
    final cleanDigits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    for (int i = 0; i < _otpLength; i++) {
      if (i < cleanDigits.length) {
        _controllers[i].text = cleanDigits[i];
      }
    }
    if (cleanDigits.length >= _otpLength) {
      _focusNodes[_otpLength - 1].unfocus();
      _handleVerify();
    } else {
      _focusNodes[cleanDigits.length].requestFocus();
    }
  }

  void _handleResendCode() async {
    if (_resendCountdown > 0) return;

    HapticFeedback.lightImpact();
    for (var c in _controllers) {
      c.clear();
    }
    _focusNodes[0].requestFocus();
    _startTimer();

    try {
      final appState = AppState();
      await appState.sendPasswordReset(widget.target);

      if (!mounted) return;

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
              const Icon(Icons.mark_email_read_rounded,
                  color: AppColors.goldPrimary, size: 20),
              const SizedBox(width: 10),
              Text(
                'A new 6-digit code has been sent!',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redBg,
          behavior: SnackBarBehavior.floating,
          content: Text(
            e.message,
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redBg,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Failed to resend code: $e',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    }
  }

  void _handleVerify() async {
    final otp = _currentOtp;
    if (otp.length < _otpLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.redBg,
          content: Text('Please enter the full 6-digit OTP code.'),
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });
    HapticFeedback.mediumImpact();

    try {
      final appState = AppState();
      final success = await appState.verifyOtp(
        email: widget.target,
        token: otp,
      );

      if (!mounted) return;

      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ResetPasswordScreen()),
        );
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redBg,
          behavior: SnackBarBehavior.floating,
          content: Text(
            e.message,
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.redBg,
          behavior: SnackBarBehavior.floating,
          content: Text(
            'Verification error: $e',
            style: GoogleFonts.inter(color: Colors.white),
          ),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (var c in _controllers) {
      c.dispose();
    }
    for (var f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
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
          'OTP Verification',
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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Shield verification icon with golden halo
              Container(
                width: 78,
                height: 78,
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
                    ),
                  ],
                ),
                child: Icon(
                  widget.isPhone
                      ? Icons.sms_outlined
                      : Icons.mark_email_read_outlined,
                  size: 38,
                  color: AppColors.goldLight,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'Enter 6-Digit Code',
                style: GoogleFonts.poppins(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 6),

              // Subtitle with target
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Code sent to ',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    widget.target,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Glass Card containing 6-digit boxes
              GlassCard(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 24),
                borderRadius: 18,
                child: Column(
                  children: [
                    // 6 OTP Box Inputs
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(_otpLength, (index) {
                        return _buildDigitBox(index);
                      }),
                    ),
                    const SizedBox(height: 24),

                    // Countdown & Resend Button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_resendCountdown > 0) ...[
                          const Icon(Icons.timer_outlined,
                              size: 16, color: AppColors.textMuted),
                          const SizedBox(width: 6),
                          Text(
                            'Resend code in ',
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            '00:${_resendCountdown.toString().padLeft(2, '0')}',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldLight,
                            ),
                          ),
                        ] else ...[
                          Text(
                            "Didn't receive the code? ",
                            style: GoogleFonts.inter(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          GestureDetector(
                            onTap: _handleResendCode,
                            child: Text(
                              'Resend Code',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.goldPrimary,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 22),

                    // Verify Button
                    TradexButton(
                      text: 'VERIFY & CONTINUE',
                      icon: Icons.verified_rounded,
                      onPressed: _handleVerify,
                      isLoading: _isLoading,
                      height: 50,
                      variant: TradexButtonVariant.primaryGold,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Change phone / email option
              GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Text(
                  'Wrong number or email? Change',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDigitBox(int index) {
    final controller = _controllers[index];
    final focusNode = _focusNodes[index];
    final bool hasValue = controller.text.isNotEmpty;

    return Focus(
      onKeyEvent: (node, event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.backspace) {
          if (controller.text.isEmpty && index > 0) {
            _focusNodes[index - 1].requestFocus();
            _controllers[index - 1].clear();
            return KeyEventResult.handled;
          }
        }
        return KeyEventResult.ignored;
      },
      child: Container(
        width: 46,
        height: 54,
        decoration: BoxDecoration(
          color: focusNode.hasFocus
              ? AppColors.cardBgElevated
              : (hasValue ? AppColors.cardBgElevated : AppColors.cardBg),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: focusNode.hasFocus
                ? AppColors.goldPrimary
                : (hasValue
                    ? AppColors.goldPrimary.withValues(alpha: 0.6)
                    : AppColors.cardBorder),
            width: focusNode.hasFocus ? 1.8 : 1.2,
          ),
          boxShadow: focusNode.hasFocus
              ? [
                  BoxShadow(
                    color: AppColors.goldPrimary.withValues(alpha: 0.35),
                    blurRadius: 10,
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          textAlign: TextAlign.center,
          inputFormatters: [
            LengthLimitingTextInputFormatter(1),
            FilteringTextInputFormatter.digitsOnly,
          ],
          style: GoogleFonts.poppins(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
          decoration: const InputDecoration(
            border: InputBorder.none,
            contentPadding: EdgeInsets.zero,
          ),
          onChanged: (val) => _onDigitChanged(index, val),
        ),
      ),
    );
  }
}
