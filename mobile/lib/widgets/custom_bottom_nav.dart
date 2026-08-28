import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const Color activeColor = Color(0xFFFFC107);
  static const Color inactiveColor = Color(0xFF5A6275);
  static const Color navBackground = Color(0xFF0D101A);
  static const Color topBorderColor = Color(0xFF1B2234);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: navBackground,
        border: Border(
          top: BorderSide(color: topBorderColor, width: 1.0),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                index: 0,
                label: 'Home',
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
              ),
              _buildNavItem(
                index: 1,
                label: 'Tickets',
                icon: Icons.confirmation_number_outlined,
                activeIcon: Icons.confirmation_number_rounded,
              ),
              _buildNavItem(
                index: 2,
                label: 'Results',
                icon: Icons.military_tech_outlined,
                activeIcon: Icons.military_tech_rounded,
              ),
              _buildNavItem(
                index: 3,
                label: 'Wallet',
                icon: Icons.account_balance_wallet_outlined,
                activeIcon: Icons.account_balance_wallet_rounded,
              ),
              _buildNavItem(
                index: 4,
                label: 'Profile',
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required String label,
    required IconData icon,
    required IconData activeIcon,
  }) {
    final bool isSelected = currentIndex == index;
    final Color itemColor = isSelected ? activeColor : inactiveColor;

    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onTap(index),
          splashColor: activeColor.withValues(alpha: 0.1),
          highlightColor: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                child: Icon(
                  isSelected ? activeIcon : icon,
                  color: itemColor,
                  size: 23,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 10.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: itemColor,
                  letterSpacing: 0.2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
