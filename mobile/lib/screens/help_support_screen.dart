import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/screens/support_chat_screen.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class FaqItem {
  final String question;
  final String answer;
  final String category;

  const FaqItem({
    required this.question,
    required this.answer,
    required this.category,
  });
}

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Draws',
    'Wallet & Deposit',
    'Withdrawals',
    'KYC & Verification',
    'Referral Program',
  ];

  final List<FaqItem> _allFaqs = const [
    FaqItem(
      category: 'Draws',
      question: 'How do I pick numbers and participate in draws?',
      answer: 'Choose your desired draw from the Home screen (Hourly, Daily, or Mega Draw). Use the interactive on-screen keypad to select your numbers or tap "Quick Pick" for randomized lucky numbers. Confirm your ticket with your wallet balance or mobile financial service.',
    ),
    FaqItem(
      category: 'Draws',
      question: 'When and how are draw results calculated and announced?',
      answer: 'Hourly Draw results are published at the top of every hour. Daily Draw results are announced every night at 10:00 PM. Mega Draw Jackpots take place on the 1st of every month at 09:00 PM. All numbers are generated using certified hardware RNG systems.',
    ),
    FaqItem(
      category: 'Wallet & Deposit',
      question: 'How do I add money (deposit) to my TRADEX wallet?',
      answer: 'Go to Wallet > Add Money. Select your payment provider (Nagad, bKash, Rocket, or Bank Transfer). Follow the on-screen instructions to transfer funds to our verified official agent number, then paste the Transaction ID (TrxID) and confirm.',
    ),
    FaqItem(
      category: 'Withdrawals',
      question: 'How long does a withdrawal take to process?',
      answer: 'Withdrawals to bKash, Nagad, and Rocket are typically completed within 15 to 30 minutes for KYC-verified users. Bank transfers take 2-4 business hours depending on the banking clearance network.',
    ),
    FaqItem(
      category: 'Withdrawals',
      question: 'Is there any fee or minimum amount for withdrawals?',
      answer: 'The minimum withdrawal is ৳ 100. Standard MFS cash-out fee is 1.5% as per telecom and gateway standards. VIP Platinum tier users enjoy zero withdrawal fees!',
    ),
    FaqItem(
      category: 'KYC & Verification',
      question: 'Why is KYC required and how long does it take?',
      answer: 'KYC (Know Your Customer) compliance is mandatory under digital asset regulations to prevent fraud and ensure winnings reach legitimate account holders. Submitting your Smart NID / Passport and face selfie takes less than 2 minutes and is reviewed in 2-4 hours.',
    ),
    FaqItem(
      category: 'Referral Program',
      question: 'How does the Invite & Earn referral bonus work?',
      answer: 'Share your unique referral code (e.g. TRADEX777) with friends. When they register and purchase their first draw ticket, both you and your friend receive an instant ৳ 100 bonus in your wallets.',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showSubmitTicketSheet() {
    final formKey = GlobalKey<FormState>();
    final subjectController = TextEditingController();
    final descriptionController = TextEditingController();
    String selectedCategory = 'Deposit Issue';
    String selectedPriority = 'Medium';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBgElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 20,
              right: 20,
              top: 20,
            ),
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.textMuted,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Submit Support Ticket',
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Our technical team will review your case and reply within 2 hours.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 18),

                    // Issue Category
                    Text(
                      'Issue Category',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: selectedCategory,
                          dropdownColor: AppColors.cardBgElevated,
                          isExpanded: true,
                          style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                          items: ['Deposit Issue', 'Withdrawal Delay', 'Ticket Issue', 'KYC Problem', 'Account / Security', 'Other']
                              .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                              .toList(),
                          onChanged: (val) {
                            if (val != null) setModalState(() => selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    TradexTextField(
                      controller: subjectController,
                      label: 'Subject',
                      hint: 'Brief summary of issue',
                      prefixIcon: Icons.title_rounded,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter subject' : null,
                    ),
                    const SizedBox(height: 14),

                    TradexTextField(
                      controller: descriptionController,
                      label: 'Detailed Description',
                      hint: 'Include transaction IDs, draw numbers, or error details...',
                      prefixIcon: Icons.description_outlined,
                      maxLines: 4,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Please enter description' : null,
                    ),
                    const SizedBox(height: 14),

                    // Priority Selector
                    Text(
                      'Priority',
                      style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: ['Low', 'Medium', 'Urgent'].map((priority) {
                        final isSelected = selectedPriority == priority;
                        return Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 3),
                            child: InkWell(
                              onTap: () => setModalState(() => selectedPriority = priority),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.goldPrimary.withValues(alpha: 0.15) : AppColors.cardBg,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: isSelected ? AppColors.goldPrimary : AppColors.cardBorder,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    priority,
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                      color: isSelected ? AppColors.goldLight : AppColors.textSecondary,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),

                    TradexButton(
                      text: 'SUBMIT TICKET',
                      width: double.infinity,
                      onPressed: () {
                        if (!formKey.currentState!.validate()) return;
                        Navigator.pop(ctx);
                        final ticketNum = 'TRX-TKT-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
                        ScaffoldMessenger.of(this.context).showSnackBar(
                          SnackBar(
                            backgroundColor: AppColors.cardBgElevated,
                            content: Text('Ticket #$ticketNum submitted! You will receive updates via notification.'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final search = _searchController.text.toLowerCase().trim();

    final filteredFaqs = _allFaqs.where((faq) {
      final matchesCat = _selectedCategory == 'All' || faq.category == _selectedCategory;
      final matchesSearch = search.isEmpty ||
          faq.question.toLowerCase().contains(search) ||
          faq.answer.toLowerCase().contains(search);
      return matchesCat && matchesSearch;
    }).toList();

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
          'Help & Support',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Live Chat Hero Banner
              _buildLiveChatHeroBanner(),

              const SizedBox(height: 20),

              // 2. Direct Channels 4-Grid Cards
              _buildContactChannelsGrid(),

              const SizedBox(height: 24),

              // 3. Search FAQ Bar
              Container(
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Search answers, draws, wallet, KYC...',
                    hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.goldPrimary, size: 22),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, color: AppColors.textSecondary, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Category Filter Pills
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _categories.length,
                  separatorBuilder: (ctx, i) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final cat = _categories[index];
                    final isSelected = _selectedCategory == cat;
                    return InkWell(
                      onTap: () => setState(() => _selectedCategory = cat),
                      borderRadius: BorderRadius.circular(18),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppColors.goldPrimary : AppColors.cardBg,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: isSelected ? AppColors.goldPrimary : AppColors.cardBorder,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            cat,
                            style: GoogleFonts.inter(
                              fontSize: 11.5,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isSelected ? Colors.black : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 20),

              // FAQ Accordion List
              Text(
                'Frequently Asked Questions (${filteredFaqs.length})',
                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
              ),
              const SizedBox(height: 10),

              if (filteredFaqs.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: Text(
                      'No matching answers found. Try a different keyword or start Live Chat.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textSecondary),
                    ),
                  ),
                )
              else
                ...filteredFaqs.map((faq) => _buildFaqTile(faq)),

              const SizedBox(height: 24),

              // Submit Ticket CTA Card
              GlassCard(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.purpleAccent.withValues(alpha: 0.2),
                      ),
                      child: const Icon(Icons.confirmation_num_outlined, color: AppColors.purpleAccent, size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Still have an issue?',
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: Colors.white),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Open a support ticket with attachments',
                            style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textSecondary),
                          ),
                        ],
                      ),
                    ),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purpleAccent,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: _showSubmitTicketSheet,
                      child: Text(
                        'TICKET',
                        style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveChatHeroBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF2C1E05),
            Color(0xFF161A29),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: AppColors.goldPrimary.withValues(alpha: 0.15),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.goldPrimary.withValues(alpha: 0.2),
                ),
                child: const Icon(Icons.support_agent_rounded, color: AppColors.goldPrimary, size: 32),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          '24/7 VIP Live Chat',
                          style: GoogleFonts.inter(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.greenAccent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Instant real-time support for deposits, draws & payouts.',
                      style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          TradexButton(
            text: 'START LIVE CHAT',
            icon: Icons.chat_rounded,
            width: double.infinity,
            variant: TradexButtonVariant.primaryGold,
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportChatScreen()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactChannelsGrid() {
    return Row(
      children: [
        Expanded(
          child: _buildChannelCard(
            icon: Icons.chat_bubble_rounded,
            title: 'WhatsApp',
            subtitle: '+880 1800-TRX',
            color: const Color(0xFF25D366),
            onTap: () {
              Clipboard.setData(const ClipboardData(text: '+8801800872339'));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('WhatsApp number copied!')),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildChannelCard(
            icon: Icons.send_rounded,
            title: 'Telegram',
            subtitle: '@TradexSupport',
            color: const Color(0xFF0088CC),
            onTap: () {
              Clipboard.setData(const ClipboardData(text: '@TradexSupport'));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Telegram handle copied!')),
              );
            },
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildChannelCard(
            icon: Icons.email_rounded,
            title: 'Email',
            subtitle: 'support@tradex',
            color: AppColors.goldPrimary,
            onTap: () {
              Clipboard.setData(const ClipboardData(text: 'support@tradex.com'));
              HapticFeedback.lightImpact();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support email copied!')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildChannelCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cardBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 6),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(fontSize: 10, color: AppColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqTile(FaqItem faq) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.cardBorder),
      ),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 14),
          iconColor: AppColors.goldPrimary,
          collapsedIconColor: AppColors.textSecondary,
          title: Text(
            faq.question,
            style: GoogleFonts.inter(
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          children: [
            Text(
              faq.answer,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
