import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/screens/auth/login_screen.dart';
import 'package:tradex/screens/auth/register_screen.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<OnboardingItem> _slides = [
    const OnboardingItem(
      badge: 'MEGA LOTTERY JACKPOT',
      badgeColor: AppColors.goldPrimary,
      title: 'Win Mega Jackpots\nUp to ৳5,00,000',
      description:
          'Experience high-stakes thrill with Bangladesh’s premier transparent lottery. Choose your 7 lucky numbers or quick-pick to win life-changing cash prizes every week.',
      featurePills: ['৳5,00,000 1st Prize', '৳100 Ticket Entry', '7-Digit Draws'],
      gradientColors: [Color(0xFF2A1F08), Color(0xFF141005)],
      accentColor: AppColors.goldPrimary,
      iconData: Icons.emoji_events_rounded,
      secondaryIcon: Icons.auto_awesome_rounded,
    ),
    const OnboardingItem(
      badge: 'INSTANT CASH TRANSFERS',
      badgeColor: AppColors.bkash,
      title: 'Instant Payouts via\nbKash & Nagad',
      description:
          'Seamless integration with your favorite mobile wallets. Enjoy zero transaction fees, instant deposits, and express withdrawals in under 60 seconds.',
      featurePills: ['< 60s Withdrawals', 'bKash & Nagad Direct', 'Zero Fee Payouts'],
      gradientColors: [Color(0xFF2A0F1E), Color(0xFF120810)],
      accentColor: Color(0xFFE2136E),
      iconData: Icons.flash_on_rounded,
      secondaryIcon: Icons.account_balance_wallet_rounded,
    ),
    const OnboardingItem(
      badge: 'PROVABLY FAIR GAMING',
      badgeColor: AppColors.purpleAccent,
      title: 'Realtime Live Draws\n& 24/7 Community',
      description:
          'Watch winning lottery numbers reveal live with certified RNG transparency. Join thousands of active Bangladeshi winners and climb the VIP Leaderboard.',
      featurePills: ['Realtime Live Studio', 'Certified Fair RNG', '24/7 VIP Support'],
      gradientColors: [Color(0xFF1D1030), Color(0xFF0C0715)],
      accentColor: AppColors.purpleAccent,
      iconData: Icons.stream_rounded,
      secondaryIcon: Icons.groups_rounded,
    ),
  ];

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
    HapticFeedback.selectionClick();
  }

  void _goToNext() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _navigateToLogin();
    }
  }

  void _navigateToLogin() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 400),
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginScreen(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
      ),
    );
  }

  void _navigateToRegister() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const RegisterScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar / Skip Button
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Small Brand Pill
                  Row(
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.goldPrimary.withValues(alpha: 0.15),
                          border: Border.all(
                            color: AppColors.goldPrimary.withValues(alpha: 0.4),
                            width: 1,
                          ),
                        ),
                        child: const Icon(
                          Icons.military_tech_rounded,
                          color: AppColors.goldPrimary,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'TRADEX',
                        style: GoogleFonts.poppins(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2.5,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),

                  // Skip Button
                  if (_currentPage < _slides.length - 1)
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _navigateToLogin,
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Skip',
                                style: GoogleFonts.inter(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: AppColors.textSecondary,
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  else
                    const SizedBox(height: 32),
                ],
              ),
            ),

            // PageView Content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return _buildSlide(slide, size);
                },
              ),
            ),

            // Bottom Navigation & Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Smooth Animated Page Indicators
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final bool isSelected = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: isSelected ? 28 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _slides[_currentPage].accentColor
                              : AppColors.cardBorderHighlight,
                          borderRadius: BorderRadius.circular(4),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: _slides[_currentPage]
                                        .accentColor
                                        .withValues(alpha: 0.45),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                              : null,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),

                  // Actions for Slide 0/1 vs Slide 2
                  if (_currentPage < _slides.length - 1) ...[
                    TradexButton(
                      text: 'CONTINUE',
                      icon: Icons.arrow_forward_rounded,
                      onPressed: _goToNext,
                      height: 52,
                      fontSize: 14.5,
                      variant: TradexButtonVariant.primaryGold,
                    ),
                  ] else ...[
                    // Slide 3: Get Started (Login) & Create Account
                    TradexButton(
                      text: 'GET STARTED / SIGN IN',
                      icon: Icons.login_rounded,
                      onPressed: _navigateToLogin,
                      height: 52,
                      fontSize: 14.5,
                      variant: TradexButtonVariant.primaryGold,
                    ),
                    const SizedBox(height: 12),
                    TradexButton(
                      text: 'CREATE NEW ACCOUNT',
                      icon: Icons.person_add_outlined,
                      onPressed: _navigateToRegister,
                      height: 48,
                      fontSize: 13.5,
                      variant: TradexButtonVariant.outline,
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSlide(OnboardingItem slide, Size size) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 10),

          // Central Visual Glass Art Card
          Container(
            width: double.infinity,
            height: size.height * 0.36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: slide.gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: slide.accentColor.withValues(alpha: 0.3),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: slide.accentColor.withValues(alpha: 0.15),
                  blurRadius: 28,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Ambient background rings
                Container(
                  width: 180,
                  height: 180,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: slide.accentColor.withValues(alpha: 0.1),
                      width: 30,
                    ),
                  ),
                ),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: slide.accentColor.withValues(alpha: 0.15),
                  ),
                ),

                // Main Hero Icon with Glow
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.backgroundSecondary,
                        border: Border.all(
                          color: slide.accentColor.withValues(alpha: 0.6),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: slide.accentColor.withValues(alpha: 0.35),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        slide.iconData,
                        size: 50,
                        color: slide.accentColor,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Decorative Sub-badge inside card
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: slide.accentColor.withValues(alpha: 0.4),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            slide.secondaryIcon,
                            size: 13,
                            color: slide.accentColor,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            slide.badge,
                            style: GoogleFonts.inter(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 28),

          // Title
          Text(
            slide.title,
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.25,
            ),
          ),
          const SizedBox(height: 12),

          // Description
          Text(
            slide.description,
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w400,
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),

          // Feature Highlight Pills
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: slide.featurePills.map((pillText) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.cardBgElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.cardBorder,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 12,
                      color: slide.accentColor,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      pillText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class OnboardingItem {
  final String badge;
  final Color badgeColor;
  final String title;
  final String description;
  final List<String> featurePills;
  final List<Color> gradientColors;
  final Color accentColor;
  final IconData iconData;
  final IconData secondaryIcon;

  const OnboardingItem({
    required this.badge,
    required this.badgeColor,
    required this.title,
    required this.description,
    required this.featurePills,
    required this.gradientColors,
    required this.accentColor,
    required this.iconData,
    required this.secondaryIcon,
  });
}
