import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/theme/app_colors.dart';

class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final bool isRead;

  const ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.isRead = true,
  });
}

class SupportChatScreen extends StatefulWidget {
  const SupportChatScreen({super.key});

  @override
  State<SupportChatScreen> createState() => _SupportChatScreenState();
}

class _SupportChatScreenState extends State<SupportChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAgentTyping = false;

  final List<ChatMessage> _messages = [
    ChatMessage(
      id: 'msg_1',
      text: 'Hello! 👋 Welcome to TRADEX 24/7 VIP Concierge Support. My name is Sarah. How can I assist you with your draws, wallet, or account today?',
      isUser: false,
      timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
  ];

  static const List<String> quickQueries = [
    'Where is my withdrawal?',
    'How do I verify KYC?',
    'Mega Draw prize rules',
    'Deposit not credited',
    'How to buy tickets?',
  ];

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? textToSend]) {
    final query = (textToSend ?? _messageController.text).trim();
    if (query.isEmpty) return;

    _messageController.clear();
    HapticFeedback.lightImpact();

    setState(() {
      _messages.add(
        ChatMessage(
          id: 'user_${DateTime.now().millisecondsSinceEpoch}',
          text: query,
          isUser: true,
          timestamp: DateTime.now(),
        ),
      );
      _isAgentTyping = true;
    });
    _scrollToBottom();

    // Generate intelligent simulated response
    Timer(const Duration(milliseconds: 1400), () {
      if (!mounted) return;

      final agentReply = _generateAgentReply(query);

      setState(() {
        _isAgentTyping = false;
        _messages.add(
          ChatMessage(
            id: 'agent_${DateTime.now().millisecondsSinceEpoch}',
            text: agentReply,
            isUser: false,
            timestamp: DateTime.now(),
          ),
        );
      });
      HapticFeedback.lightImpact();
      _scrollToBottom();
    });
  }

  String _generateAgentReply(String userText) {
    final lower = userText.toLowerCase();

    if (lower.contains('withdraw') || lower.contains('payout') || lower.contains('cash out')) {
      return 'Withdrawal requests via bKash, Nagad, and Rocket are processed within 15-30 minutes for KYC verified accounts. For bank BEFTN/NPSB transfers, it typically settles within 2-4 business hours.';
    } else if (lower.contains('deposit') || lower.contains('add money') || lower.contains('balance')) {
      return 'For deposits, please ensure you have submitted the exact TrxID (Transaction ID) from your bKash or Nagad app. Once submitted, our automated gateway verifies and credits your wallet within 60 seconds!';
    } else if (lower.contains('kyc') || lower.contains('nid') || lower.contains('verify') || lower.contains('document')) {
      return 'To verify your KYC, head to Profile > Identity Verification (KYC). You will need a photo of your Smart NID or Passport and a quick 3-second face liveness selfie. Verification takes 2-4 hours.';
    } else if (lower.contains('mega') || lower.contains('jackpot') || lower.contains('prize') || lower.contains('500000') || lower.contains('5,00,000')) {
      return 'The Mega Draw Jackpot is ৳ 5,00,000! Draws take place on the 1st of every month at 09:00 PM. Match all 7 digits to claim 1st prize, 2 digits for 2nd prize, or 1 digit for 3rd prize!';
    } else if (lower.contains('ticket') || lower.contains('buy') || lower.contains('how to')) {
      return 'You can buy tickets from the Home screen by selecting Hourly (৳20), Daily (৳60), or Mega Draw (৳100). Pick your lucky digits using the tactile keypad or tap "Quick Pick" for random lucky numbers!';
    } else if (lower.contains('refer') || lower.contains('invite') || lower.contains('friend')) {
      return 'Our Invite & Earn program rewards you with ৳ 100 instantly for every friend who joins using your code and plays their first draw. Plus, you get 5% lifetime winning commission!';
    } else {
      return 'Thank you for reaching out! I have noted your inquiry regarding "$userText". Our supervisor team is looking into this, and your account manager is standing by. Is there anything else I can clarify for you right now?';
    }
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
        title: Row(
          children: [
            Stack(
              children: [
                CircleAvatar(
                  radius: 19,
                  backgroundColor: AppColors.goldPrimary.withValues(alpha: 0.2),
                  child: const Text('👑', style: TextStyle(fontSize: 18)),
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: AppColors.greenAccent,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.background, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sarah (Tradex VIP Support)',
                    style: GoogleFonts.inter(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Online • Avg. reply < 1 min',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: AppColors.greenLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert_rounded, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Support Session ID: #TRX-SUP-8492')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Chat Messages List
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                itemCount: _messages.length,
                itemBuilder: (context, index) {
                  final msg = _messages[index];
                  return _buildMessageBubble(msg);
                },
              ),
            ),

            // Typing Indicator
            if (_isAgentTyping)
              Padding(
                padding: const EdgeInsets.only(left: 20, bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.support_agent_rounded, color: AppColors.goldPrimary, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Sarah is typing...',
                      style: GoogleFonts.inter(
                        fontSize: 11.5,
                        fontStyle: FontStyle.italic,
                        color: AppColors.goldLight,
                      ),
                    ),
                  ],
                ),
              ),

            // Quick Query Suggestion Pills
            Container(
              height: 38,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: quickQueries.length,
                separatorBuilder: (context, index) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final query = quickQueries[index];
                  return InkWell(
                    onTap: () => _sendMessage(query),
                    borderRadius: BorderRadius.circular(18),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.cardBgElevated,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.cardBorderHighlight),
                      ),
                      child: Center(
                        child: Text(
                          query,
                          style: GoogleFonts.inter(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.goldLight,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Message Input Field Box
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.cardBg,
                border: Border(top: BorderSide(color: AppColors.divider)),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.attach_file_rounded, color: AppColors.textSecondary),
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Simulated file attachment selected')),
                      );
                    },
                  ),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.cardBgElevated,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      child: TextField(
                        controller: _messageController,
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.white),
                        decoration: InputDecoration(
                          hintText: 'Type your message...',
                          hintStyle: GoogleFonts.inter(fontSize: 13, color: AppColors.textMuted),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                        ),
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppColors.goldGradientStart, AppColors.goldGradientEnd],
                      ),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFF0F111A), size: 20),
                      onPressed: () => _sendMessage(),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage msg) {
    final isUser = msg.isUser;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              radius: 14,
              backgroundColor: AppColors.cardBgElevated,
              child: const Icon(Icons.support_agent_rounded, color: AppColors.goldPrimary, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isUser
                    ? AppColors.goldPrimary.withValues(alpha: 0.9)
                    : AppColors.cardBgElevated,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: Radius.circular(isUser ? 16 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 16),
                ),
                border: Border.all(
                  color: isUser ? AppColors.goldDark : AppColors.cardBorder,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  Text(
                    msg.text,
                    style: GoogleFonts.inter(
                      fontSize: 13.5,
                      fontWeight: isUser ? FontWeight.w600 : FontWeight.w500,
                      color: isUser ? const Color(0xFF0F111A) : Colors.white,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(msg.timestamp),
                        style: GoogleFonts.inter(
                          fontSize: 9.5,
                          color: isUser ? const Color(0xFF332608) : AppColors.textMuted,
                        ),
                      ),
                      if (isUser) ...[
                        const SizedBox(width: 4),
                        const Icon(Icons.done_all_rounded, size: 12, color: Color(0xFF332608)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isUser) const SizedBox(width: 6),
        ],
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')} $period';
  }
}
