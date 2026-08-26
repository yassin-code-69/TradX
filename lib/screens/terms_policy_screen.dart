import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/theme/app_colors.dart';

class TermsPolicyScreen extends StatefulWidget {
  final int initialTabIndex;

  const TermsPolicyScreen({
    super.key,
    this.initialTabIndex = 0,
  });

  @override
  State<TermsPolicyScreen> createState() => _TermsPolicyScreenState();
}

class _TermsPolicyScreenState extends State<TermsPolicyScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 4,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 3),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.cardBgElevated,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Terms & Legal Policy',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.goldPrimary,
          indicatorWeight: 3,
          labelColor: AppColors.goldLight,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500),
          tabs: const [
            Tab(text: 'Terms of Service'),
            Tab(text: 'Privacy Policy'),
            Tab(text: 'Draw & Fair Play Rules'),
            Tab(text: 'Responsible Gaming'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildTermsOfServiceTab(),
            _buildPrivacyPolicyTab(),
            _buildDrawRulesTab(),
            _buildResponsibleGamingTab(),
          ],
        ),
      ),
    );
  }

  // 1. Terms of Service
  Widget _buildTermsOfServiceTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildSectionTitle('1. Acceptance of Terms'),
        _buildParagraph(
          'By accessing and using the TRADEX platform, mobile application, and related services, you agree to be bound by these Terms of Service. If you do not agree to these terms, please do not register or use the platform.',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('2. User Eligibility & Account Security'),
        _buildParagraph(
          'Users must be at least 18 years of age and legally competent to participate in digital entertainment and skill-based prediction draws. Each participant is permitted only ONE registered account. Multi-accounting, automated script betting, or credential sharing is strictly prohibited.',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('3. Ticket Purchases & Draw Participation'),
        _buildParagraph(
          'All ticket purchases made via wallet balance or supported Mobile Financial Services (bKash, Nagad, Rocket) are final and non-refundable once confirmed. Tickets cannot be altered after entry into the scheduled draw pool.',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('4. Prize Distribution & Withdrawals'),
        _buildParagraph(
          'Prize winnings are automatically credited to the winner\'s TRADEX wallet following official draw verification. Withdrawals are processed to verified Bangladeshi MFS numbers and bank accounts held in the user\'s registered legal name.',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('5. Limitation of Liability'),
        _buildParagraph(
          'TRADEX shall not be held liable for network latency, telecommunication disruptions, device malfunctions, or banking gateway delays outside the company\'s direct infrastructural control.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // 2. Privacy Policy
  Widget _buildPrivacyPolicyTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildSectionTitle('1. Information We Collect'),
        _buildParagraph(
          'We collect information you provide directly during registration and identity verification, including full name, phone number, email address, national identity documentation (NID/Passport), and device identifier logs.',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('2. How We Protect Your Data'),
        _buildParagraph(
          'All sensitive identification data and financial transaction logs are encrypted in transit and at rest using AES-256 and TLS 1.3 standards. Identity documents submitted for KYC are stored in restricted compliance silos.',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('3. Payment Data Security'),
        _buildParagraph(
          'TRADEX does not store your private mobile financial PINs or bank login passwords. MFS payment transactions are validated via tokenized official API endpoints and secure TrxID reconciliation.',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('4. Third-Party Disclosures'),
        _buildParagraph(
          'We do not sell, rent, or trade your personal data to third parties. We may disclose information only when required by applicable government regulatory laws or law enforcement compliance subpoenas.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // 3. Draw & Fair Play Rules
  Widget _buildDrawRulesTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        _buildSectionTitle('1. Certified Hardware Random Number Generation (RNG)'),
        _buildParagraph(
          'All TRADEX winning numbers are produced using NIST SP 800-90A certified cryptographically secure hardware RNG algorithms. Results cannot be predicted, influenced, or manipulated by any internal or external party.',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('2. Official Draw Schedule'),
        _buildBulletPoint('Hourly Draw: Occurs every 60 minutes, 24/7 (Prize pool up to ৳ 20,000)'),
        _buildBulletPoint('Daily Draw: Occurs nightly at 10:00 PM (Prize pool up to ৳ 50,000)'),
        _buildBulletPoint('Mega Draw: Occurs on the 1st of every month at 09:00 PM (Prize pool ৳ 5,00,000)'),
        const SizedBox(height: 16),
        _buildSectionTitle('3. Winning Match Formula & Prize Tiers'),
        _buildParagraph(
          'Prizes are awarded based on exact match and digit ending matches from right to left:\n• 1st Prize (Jackpot): 100% Exact Number Match\n• 2nd Prize: Match Last 2 Digits\n• 3rd Prize: Match Last 1 Digit\nMultiple winning tickets receive proportional prize pool distribution.',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('4. Unclaimed Prize Policy'),
        _buildParagraph(
          'Winnings are credited automatically without expiration. Users have up to 365 calendar days to withdraw credited wallet prize balances.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // 4. Responsible Gaming
  Widget _buildResponsibleGamingTab() {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.cardBgElevated,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.4)),
          ),
          child: Row(
            children: [
              const Icon(Icons.favorite_rounded, color: AppColors.goldPrimary, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'TRADEX promotes entertaining, responsible, and transparent gaming for all adult players.',
                  style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _buildSectionTitle('1. Strict 18+ Age Requirement'),
        _buildParagraph(
          'Minors under 18 years old are strictly prohibited from participating. Accounts suspected of underage play will be permanently suspended with funds frozen pending legal review.',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('2. Play Within Your Means'),
        _buildParagraph(
          'Lottery and draw participation should be viewed purely as entertainment, never as a guaranteed income source. Never wager money essential for daily living expenses, rent, or necessities.',
        ),
        const SizedBox(height: 16),
        _buildSectionTitle('3. Self-Exclusion & Deposit Limits'),
        _buildParagraph(
          'Users can request temporary cooling-off periods (24 hours to 30 days) or permanent self-exclusion at any time by contacting support@tradex.com or reaching out on 24/7 Live Chat.',
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 14.5,
          fontWeight: FontWeight.w700,
          color: AppColors.goldLight,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 13,
        color: AppColors.textSecondary,
        height: 1.45,
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.goldPrimary, fontSize: 14)),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.inter(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }
}
