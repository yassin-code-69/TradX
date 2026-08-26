import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/theme/app_colors.dart';

/// 1. REUSABLE TRADEX BUTTONS
enum TradexButtonVariant {
  primaryGold,
  secondaryPurple,
  secondaryGreen,
  dangerRed,
  outline,
  glass,
}

class TradexButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final TradexButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final double height;
  final double? width;
  final double fontSize;
  final FontWeight fontWeight;
  final BorderRadius? borderRadius;

  const TradexButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.variant = TradexButtonVariant.primaryGold,
    this.isLoading = false,
    this.icon,
    this.height = 48,
    this.width,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w700,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? BorderRadius.circular(12);

    Decoration decoration;
    Color textColor;

    switch (variant) {
      case TradexButtonVariant.primaryGold:
        decoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppColors.goldGradientStart, AppColors.goldGradientEnd],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.goldPrimary.withValues(alpha: 0.35),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        );
        textColor = const Color(0xFF0F111A);
        break;

      case TradexButtonVariant.secondaryPurple:
        decoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF9333EA), Color(0xFF6B21A8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.purpleDark.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
        textColor = Colors.white;
        break;

      case TradexButtonVariant.secondaryGreen:
        decoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF10B981), Color(0xFF047857)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.greenDark.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
        textColor = Colors.white;
        break;

      case TradexButtonVariant.dangerRed:
        decoration = BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFEF4444), Color(0xFFB91C1C)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: radius,
          boxShadow: [
            BoxShadow(
              color: AppColors.redAccent.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        );
        textColor = Colors.white;
        break;

      case TradexButtonVariant.outline:
        decoration = BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: radius,
          border: Border.all(color: AppColors.cardBorderHighlight, width: 1.2),
        );
        textColor = Colors.white;
        break;

      case TradexButtonVariant.glass:
        decoration = BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: radius,
          border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
        );
        textColor = Colors.white;
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: radius,
          onTap: isLoading ? null : onPressed,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Center(
              child: isLoading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(textColor),
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) ...[
                          Icon(icon, size: fontSize + 4, color: textColor),
                          const SizedBox(width: 8),
                        ],
                      Flexible(
                        child: Text(
                          text,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: fontSize,
                            fontWeight: fontWeight,
                            color: textColor,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                    ],
                  ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 2. REUSABLE GLASS / ELEVATED CARD
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderRadius;
  final VoidCallback? onTap;
  final List<BoxShadow>? boxShadow;

  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin,
    this.backgroundColor,
    this.borderColor,
    this.borderRadius = 16,
    this.onTap,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.cardBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.cardBorder,
          width: 1.1,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(borderRadius),
          onTap: onTap,
          child: Padding(
            padding: padding,
            child: child,
          ),
        ),
      ),
    );
  }
}

/// 3. REUSABLE TRADEX TEXT FORM FIELD
class TradexTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final int maxLines;
  final bool readOnly;
  final VoidCallback? onTap;

  const TradexTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.onChanged,
    this.maxLines = 1,
    this.readOnly = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: GoogleFonts.inter(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
        ],
        Container(
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.cardBorder),
          ),
          child: TextFormField(
            controller: controller,
            obscureText: obscureText,
            keyboardType: keyboardType,
            validator: validator,
            onChanged: onChanged,
            maxLines: maxLines,
            readOnly: readOnly,
            onTap: onTap,
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: GoogleFonts.inter(
                fontSize: 13.5,
                color: AppColors.textMuted,
              ),
              prefixIcon: prefixIcon != null
                  ? Icon(prefixIcon, color: AppColors.textSecondary, size: 20)
                  : null,
              suffixIcon: suffix,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            ),
          ),
        ),
      ],
    );
  }
}

/// 4. REUSABLE STATUS BADGE / CHIP
class TradexStatusChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final double fontSize;

  const TradexStatusChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.fontSize = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3.5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. REUSABLE DIGIT NUMBER PILL
class DigitPill extends StatelessWidget {
  final String digit;
  final Color accentColor;
  final double size;
  final bool isGlowing;
  final bool isSelected;

  const DigitPill({
    super.key,
    required this.digit,
    this.accentColor = AppColors.goldPrimary,
    this.size = 38,
    this.isGlowing = false,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasDigit = digit.isNotEmpty;

    return Container(
      width: size,
      height: size + 4,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isSelected
            ? accentColor.withValues(alpha: 0.2)
            : hasDigit
                ? AppColors.cardBgElevated
                : AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: hasDigit ? accentColor : AppColors.cardBorder,
          width: hasDigit ? 1.5 : 1,
        ),
        boxShadow: hasDigit && isGlowing
            ? [
                BoxShadow(
                  color: accentColor.withValues(alpha: 0.4),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Text(
        hasDigit ? digit : '-',
        style: GoogleFonts.poppins(
          fontSize: size * 0.48,
          fontWeight: FontWeight.w800,
          color: hasDigit ? (isSelected ? accentColor : Colors.white) : AppColors.textMuted,
        ),
      ),
    );
  }
}

/// 6. REUSABLE COUNTDOWN TIMER WIDGET
class CountdownTimerWidget extends StatefulWidget {
  final DateTime targetDateTime;
  final Color accentColor;
  final VoidCallback? onTimerFinished;

  const CountdownTimerWidget({
    super.key,
    required this.targetDateTime,
    this.accentColor = AppColors.goldPrimary,
    this.onTimerFinished,
  });

  @override
  State<CountdownTimerWidget> createState() => _CountdownTimerWidgetState();
}

class _CountdownTimerWidgetState extends State<CountdownTimerWidget> {
  late Timer _timer;
  late Duration _remainingTime;

  @override
  void initState() {
    super.initState();
    _updateRemainingTime();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _updateRemainingTime();
        });
      }
    });
  }

  void _updateRemainingTime() {
    final now = DateTime.now();
    if (widget.targetDateTime.isAfter(now)) {
      _remainingTime = widget.targetDateTime.difference(now);
    } else {
      _remainingTime = Duration.zero;
      widget.onTimerFinished?.call();
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final days = _remainingTime.inDays;
    final hours = _remainingTime.inHours % 24;
    final minutes = _remainingTime.inMinutes % 60;
    final seconds = _remainingTime.inSeconds % 60;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (days > 0) ...[
          _buildTimeBox(days.toString().padLeft(2, '0'), 'DAYS'),
          _buildColon(),
        ],
        _buildTimeBox(hours.toString().padLeft(2, '0'), 'HRS'),
        _buildColon(),
        _buildTimeBox(minutes.toString().padLeft(2, '0'), 'MIN'),
        _buildColon(),
        _buildTimeBox(seconds.toString().padLeft(2, '0'), 'SEC'),
      ],
    );
  }

  Widget _buildTimeBox(String value, String label) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFF0F131E),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: widget.accentColor.withValues(alpha: 0.5), width: 1),
          ),
          child: Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: widget.accentColor,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w600,
            color: AppColors.textMuted,
          ),
        ),
      ],
    );
  }

  Widget _buildColon() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        ':',
        style: GoogleFonts.inter(
          fontSize: 14,
          fontWeight: FontWeight.w900,
          color: widget.accentColor,
        ),
      ),
    );
  }
}

/// 7. REUSABLE DIGITAL RECEIPT CARD
class TradexReceiptCard extends StatelessWidget {
  final String title;
  final String status;
  final Color statusColor;
  final String amount;
  final String idLabel;
  final String idValue;
  final List<MapEntry<String, String>> details;
  final VoidCallback? onCopyId;
  final VoidCallback? onShare;

  const TradexReceiptCard({
    super.key,
    required this.title,
    required this.status,
    required this.statusColor,
    required this.amount,
    required this.idLabel,
    required this.idValue,
    required this.details,
    this.onCopyId,
    this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.cardBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Column(
              children: [
                TradexStatusChip(label: status, color: statusColor),
                const SizedBox(height: 10),
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  amount,
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),

          // Perforated Divider
          Row(
            children: [
              Container(
                width: 14,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  ),
                ),
              ),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final dashCount = (constraints.constrainWidth() / 10).floor();
                    return Flex(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      direction: Axis.horizontal,
                      children: List.generate(dashCount, (_) {
                        return const SizedBox(
                          width: 5,
                          height: 1.5,
                          child: DecoratedBox(
                            decoration: BoxDecoration(color: AppColors.cardBorder),
                          ),
                        );
                      }),
                    );
                  },
                ),
              ),
              Container(
                width: 14,
                height: 24,
                decoration: const BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ],
          ),

          // Details List
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              children: [
                // Copyable ID Row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.backgroundSecondary,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            idLabel,
                            style: GoogleFonts.inter(fontSize: 10.5, color: AppColors.textMuted),
                          ),
                          Text(
                            idValue,
                            style: GoogleFonts.poppins(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.goldPrimary,
                            ),
                          ),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.copy_rounded, size: 18, color: AppColors.textSecondary),
                        onPressed: onCopyId ??
                            () {
                              Clipboard.setData(ClipboardData(text: idValue));
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$idLabel copied!')),
                              );
                            },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),

                ...details.map((item) => Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.key,
                            style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                          ),
                          Text(
                            item.value,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    )),

                if (onShare != null) ...[
                  const SizedBox(height: 16),
                  TradexButton(
                    text: 'Share Receipt',
                    variant: TradexButtonVariant.glass,
                    icon: Icons.share_rounded,
                    height: 40,
                    fontSize: 12.5,
                    onPressed: onShare,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 8. REUSABLE SLIDE TO CONFIRM WIDGET
class TradexSlideToConfirm extends StatefulWidget {
  final String label;
  final VoidCallback onConfirmed;
  final Color sliderColor;

  const TradexSlideToConfirm({
    super.key,
    required this.label,
    required this.onConfirmed,
    this.sliderColor = AppColors.goldPrimary,
  });

  @override
  State<TradexSlideToConfirm> createState() => _TradexSlideToConfirmState();
}

class _TradexSlideToConfirmState extends State<TradexSlideToConfirm> {
  double _dragPosition = 0.0;
  bool _confirmed = false;

  @override
  Widget build(BuildContext context) {
    const double height = 54.0;
    const double thumbSize = 46.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final double maxDrag = constraints.maxWidth - thumbSize - 8;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.cardBg,
            borderRadius: BorderRadius.circular(27),
            border: Border.all(color: AppColors.cardBorderHighlight, width: 1.2),
          ),
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              // Shimmer / Text in center
              Center(
                child: Text(
                  _confirmed ? 'CONFIRMED ✓' : widget.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: _confirmed ? AppColors.greenLight : AppColors.textSecondary,
                  ),
                ),
              ),

              // Draggable Thumb
              Positioned(
                left: 4 + _dragPosition,
                child: GestureDetector(
                  onHorizontalDragUpdate: (details) {
                    if (_confirmed) return;
                    setState(() {
                      _dragPosition += details.delta.dx;
                      if (_dragPosition < 0) _dragPosition = 0;
                      if (_dragPosition > maxDrag) _dragPosition = maxDrag;
                    });
                  },
                  onHorizontalDragEnd: (details) {
                    if (_dragPosition >= maxDrag * 0.85) {
                      setState(() {
                        _dragPosition = maxDrag;
                        _confirmed = true;
                      });
                      HapticFeedback.heavyImpact();
                      widget.onConfirmed();
                    } else {
                      setState(() {
                        _dragPosition = 0;
                      });
                    }
                  },
                  child: Container(
                    width: thumbSize,
                    height: thumbSize,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [widget.sliderColor, widget.sliderColor.withValues(alpha: 0.8)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: widget.sliderColor.withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Colors.black,
                      size: 20,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// 9. REUSABLE EMPTY STATE WIDGET
class TradexEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? buttonText;
  final VoidCallback? onButtonPressed;
  final Color iconColor;

  const TradexEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.buttonText,
    this.onButtonPressed,
    this.iconColor = AppColors.goldPrimary,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: iconColor.withValues(alpha: 0.25), width: 1.5),
              ),
              child: Icon(icon, size: 38, color: iconColor),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            if (buttonText != null && onButtonPressed != null) ...[
              const SizedBox(height: 20),
              TradexButton(
                text: buttonText!,
                onPressed: onButtonPressed,
                height: 42,
                fontSize: 13,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
