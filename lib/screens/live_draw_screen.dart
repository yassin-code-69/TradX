import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class LiveDrawScreen extends StatefulWidget {
  final DrawModel draw;

  const LiveDrawScreen({super.key, required this.draw});

  @override
  State<LiveDrawScreen> createState() => _LiveDrawScreenState();
}

class _LiveDrawScreenState extends State<LiveDrawScreen>
    with TickerProviderStateMixin {
  late AnimationController _ballSpinController;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  final List<String> _rollingDigits = [];
  final List<bool> _digitRevealed = [];
  bool _isDrawing = true;
  bool _hasAnnouncedWinner = false;
  Timer? _rollTimer;
  Timer? _chatTimer;
  Timer? _revealTimer;
  int _viewers = 1428;
  final math.Random _rnd = math.Random();

  final List<Map<String, String>> _liveMessages = [
    {'user': 'Tanvir_Boss', 'msg': 'All in on 7 today! Inshallah 🔥', 'color': '#FFD54F'},
    {'user': 'Shakib_75', 'msg': 'Good luck to all Tradex members! 🚀', 'color': '#34D399'},
    {'user': 'Anis_Chy', 'msg': 'Need this ৳50,000 jackpot for Eid shopping 🤞', 'color': '#C084FC'},
    {'user': 'Rafiq_Dhaka', 'msg': 'Draw is 100% fair and transparent 💯', 'color': '#38BDF8'},
  ];

  final List<Map<String, String>> _incomingChatPool = [
    {'user': 'Mahi_07', 'msg': 'Come on 9 9 9! 🍀', 'color': '#F59E0B'},
    {'user': 'Sultana_K', 'msg': 'Bismillah, hoping for a 1st prize win!', 'color': '#10B981'},
    {'user': 'Kamrul_99', 'msg': 'Watching live from Sylhet 🔴', 'color': '#A855F7'},
    {'user': 'Zubair_X', 'msg': 'Tradex payouts are super fast! 💸', 'color': '#00D2FF'},
    {'user': 'Nasir_Uddin', 'msg': 'Let’s goooo jackpot! 🎉', 'color': '#EC4899'},
    {'user': 'Farhan_R', 'msg': '2nd number matched already! 🔥', 'color': '#FBBF24'},
  ];

  final ScrollController _chatScrollController = ScrollController();
  final TextEditingController _chatInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _ballSpinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.15).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    for (int i = 0; i < widget.draw.totalDigits; i++) {
      _rollingDigits.add(_rnd.nextInt(10).toString());
      _digitRevealed.add(false);
    }

    // High frequency rolling animation
    _rollTimer = Timer.periodic(const Duration(milliseconds: 70), (timer) {
      if (_isDrawing && mounted) {
        setState(() {
          for (int i = 0; i < _rollingDigits.length; i++) {
            if (!_digitRevealed[i]) {
              _rollingDigits[i] = _rnd.nextInt(10).toString();
            }
          }
          if (_rnd.nextBool()) {
            _viewers += _rnd.nextInt(5) - 2;
          }
        });
      }
    });

    // Sequential digit locks
    int currentDigitToLock = 0;
    _revealTimer = Timer.periodic(const Duration(milliseconds: 1400), (timer) {
      if (currentDigitToLock < widget.draw.totalDigits && mounted) {
        setState(() {
          _digitRevealed[currentDigitToLock] = true;
          HapticFeedback.heavyImpact();
        });
        currentDigitToLock++;
      } else {
        timer.cancel();
        if (mounted) {
          setState(() {
            _isDrawing = false;
            _ballSpinController.stop();
          });
          _triggerWinnerAnnouncement();
        }
      }
    });

    // Incoming Live Chat comments stream
    _chatTimer = Timer.periodic(const Duration(milliseconds: 2500), (timer) {
      if (mounted && _incomingChatPool.isNotEmpty) {
        final nextMsg = _incomingChatPool[_rnd.nextInt(_incomingChatPool.length)];
        setState(() {
          _liveMessages.add(nextMsg);
        });
        Future.delayed(const Duration(milliseconds: 100), () {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
            );
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _ballSpinController.dispose();
    _pulseController.dispose();
    _rollTimer?.cancel();
    _revealTimer?.cancel();
    _chatTimer?.cancel();
    _chatScrollController.dispose();
    _chatInputController.dispose();
    super.dispose();
  }

  void _triggerWinnerAnnouncement() {
    if (_hasAnnouncedWinner) return;
    _hasAnnouncedWinner = true;
    HapticFeedback.heavyImpact();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (ctx) => _buildWinnerAnnouncementDialog(ctx),
      );
    });
  }

  void _sendUserComment(String text) {
    if (text.trim().isEmpty) return;
    setState(() {
      _liveMessages.add({
        'user': 'You',
        'msg': text.trim(),
        'color': '#FFD54F',
      });
    });
    _chatInputController.clear();
    HapticFeedback.selectionClick();
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final draw = widget.draw;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundSecondary,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.redAccent,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '${draw.title} Live Stream',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          Row(
            children: [
              const Icon(Icons.visibility_outlined, color: AppColors.textSecondary, size: 16),
              const SizedBox(width: 4),
              Text(
                '$_viewers',
                style: GoogleFonts.poppins(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 14),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Live Arena Simulator Stage (Machine + Revealed Numbers)
            _buildLiveArenaStage(draw),

            const SizedBox(height: 8),

            // 2. Live Community Chat Title Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.forum_outlined, size: 16, color: AppColors.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        'Live Community Chat',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  TradexStatusChip(
                    label: _isDrawing ? 'DRAWING IN PROGRESS' : 'DRAW COMPLETED',
                    color: _isDrawing ? AppColors.goldPrimary : AppColors.greenAccent,
                    fontSize: 9,
                  ),
                ],
              ),
            ),

            // 3. Live Chat Feed Container
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: ListView.builder(
                  controller: _chatScrollController,
                  itemCount: _liveMessages.length,
                  itemBuilder: (context, index) {
                    final msg = _liveMessages[index];
                    final Color userColor = Color(
                      int.parse(msg['color']!.replaceAll('#', '0xFF')),
                    );

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '${msg['user']}: ',
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: userColor,
                              ),
                            ),
                            TextSpan(
                              text: msg['msg'],
                              style: GoogleFonts.inter(
                                fontSize: 12.5,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // 4. Quick Emoji Reactions & Chat Input
            _buildChatInputBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveArenaStage(DrawModel draw) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      decoration: BoxDecoration(
        color: AppColors.cardBgElevated,
        border: const Border(
          bottom: BorderSide(color: AppColors.cardBorder),
        ),
        boxShadow: [
          BoxShadow(
            color: draw.accentColor.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Spinning Lottery Ball Sphere Animation
          Stack(
            alignment: Alignment.center,
            children: [
              // Radiant Background Glow
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Container(
                    width: 100 * _pulseAnimation.value,
                    height: 100 * _pulseAnimation.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: draw.accentColor.withValues(alpha: 0.35),
                          blurRadius: 36,
                          spreadRadius: 6,
                        ),
                      ],
                    ),
                  );
                },
              ),

              // Glass Lottery Sphere Chamber
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.cardBgElevated,
                      draw.accentColor.withValues(alpha: 0.3),
                      const Color(0xFF0F121E),
                    ],
                    center: const Alignment(-0.3, -0.3),
                  ),
                  border: Border.all(
                    color: draw.accentColor.withValues(alpha: 0.7),
                    width: 2,
                  ),
                ),
                child: RotationTransition(
                  turns: _ballSpinController,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      _buildFloatingBall(Offset(-16, -12), '7', AppColors.goldPrimary),
                      _buildFloatingBall(Offset(18, -14), '3', AppColors.greenAccent),
                      _buildFloatingBall(Offset(-12, 18), '5', AppColors.purpleAccent),
                      _buildFloatingBall(Offset(14, 16), '9', AppColors.cyanAccent),
                      _buildFloatingBall(Offset(0, 0), '1', Colors.white),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          Text(
            _isDrawing ? 'ROLLING OFFICIAL WINNING NUMBERS...' : '🎉 OFFICIAL WINNING COMBINATION 🎉',
            style: GoogleFonts.inter(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: _isDrawing ? AppColors.goldLight : AppColors.greenLight,
              letterSpacing: 1.0,
            ),
          ),

          const SizedBox(height: 12),

          // Numbers Reveal Row
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: List.generate(draw.totalDigits, (index) {
              final digit = _rollingDigits[index];
              final isLocked = _digitRevealed[index];

              return Container(
                width: draw.totalDigits > 4 ? 38 : 54,
                height: draw.totalDigits > 4 ? 46 : 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLocked
                        ? [
                            AppColors.greenBg,
                            AppColors.greenDark.withValues(alpha: 0.4),
                          ]
                        : [
                            AppColors.cardBg,
                            draw.accentColor.withValues(alpha: 0.2),
                          ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isLocked ? AppColors.greenLight : draw.accentColor,
                    width: isLocked ? 2 : 1.5,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isLocked ? AppColors.greenAccent : draw.accentColor)
                          .withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                alignment: Alignment.center,
                child: Text(
                  digit,
                  style: GoogleFonts.poppins(
                    fontSize: draw.totalDigits > 4 ? 20 : 28,
                    fontWeight: FontWeight.w900,
                    color: isLocked ? AppColors.greenLight : Colors.white,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildFloatingBall(Offset offset, String digit, Color color) {
    return Transform.translate(
      offset: offset,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.6),
              blurRadius: 6,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          digit,
          style: GoogleFonts.poppins(
            fontSize: 10.5,
            fontWeight: FontWeight.w900,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildChatInputBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        border: const Border(
          top: BorderSide(color: AppColors.cardBorder),
        ),
      ),
      child: Column(
        children: [
          // Quick Reaction Pills
          Row(
            children: ['🔥', '🎉', '🤞', '💰', '🚀', '❤️'].map((emoji) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: GestureDetector(
                    onTap: () => _sendUserComment(emoji),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.cardBg,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.cardBorder),
                      ),
                      alignment: Alignment.center,
                      child: Text(emoji, style: const TextStyle(fontSize: 15)),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),

          // Message Input Field
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.cardBg,
                    borderRadius: BorderRadius.circular(21),
                    border: Border.all(color: AppColors.cardBorder),
                  ),
                  child: TextField(
                    controller: _chatInputController,
                    onSubmitted: _sendUserComment,
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Say something in live chat...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.goldGradientStart, AppColors.goldGradientEnd],
                  ),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.send_rounded, size: 18, color: Colors.black),
                  onPressed: () => _sendUserComment(_chatInputController.text),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWinnerAnnouncementDialog(BuildContext ctx) {
    final winningCombo = _rollingDigits.join('');

    return Dialog(
      backgroundColor: AppColors.cardBgElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.goldPrimary, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColors.goldPrimary.withValues(alpha: 0.15),
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.goldPrimary),
              ),
              child: const Icon(
                Icons.emoji_events_rounded,
                color: AppColors.goldPrimary,
                size: 36,
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'Draw Completed!',
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Official Winning Combination for ${widget.draw.title}:',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 12.5,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 14),

            // Combination Banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.goldPrimary.withValues(alpha: 0.5)),
              ),
              child: Text(
                winningCombo,
                style: GoogleFonts.poppins(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  color: AppColors.goldLight,
                  letterSpacing: 4.0,
                ),
              ),
            ),

            const SizedBox(height: 14),
            Text(
              'Jackpot Prize: ${widget.draw.prize}',
              style: GoogleFonts.inter(
                fontSize: 13.5,
                fontWeight: FontWeight.w700,
                color: AppColors.greenLight,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'All winnings credited automatically to user wallets.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),

            const SizedBox(height: 20),
            TradexButton(
              text: 'CONTINUE',
              variant: TradexButtonVariant.primaryGold,
              height: 46,
              onPressed: () {
                Navigator.pop(ctx);
              },
            ),
          ],
        ),
      ),
    );
  }
}
