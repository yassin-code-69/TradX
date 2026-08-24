import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/draw_result.dart';
import 'package:tradex/screens/add_money_screen.dart';
import 'package:tradex/screens/all_results_screen.dart';
import 'package:tradex/screens/daily_draw_screen.dart';
import 'package:tradex/screens/hourly_draw_screen.dart';
import 'package:tradex/screens/mega_draw_screen.dart';
import 'package:tradex/screens/profile_screen.dart';
import 'package:tradex/screens/transaction_history_screen.dart';
import 'package:tradex/screens/wallet_screen.dart';
import 'package:tradex/screens/withdraw_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/app_drawer.dart';
import 'package:tradex/widgets/draw_card_widget.dart';
import 'package:tradex/widgets/latest_result_widget.dart';
import 'package:tradex/widgets/tradex_app_bar.dart';
import 'package:tradex/widgets/wallet_balance_card.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final AppState _appState = AppState();

  void _handleDrawerNavigation(String route) {
    switch (route) {
      case 'home':
        break;
      case 'wallet':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WalletScreen()));
        break;
      case 'add_money':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AddMoneyScreen()));
        break;
      case 'withdraw':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const WithdrawScreen()));
        break;
      case 'history':
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TransactionHistoryScreen()),
        );
        break;
      case 'mega_draw':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const MegaDrawScreen()));
        break;
      case 'daily_draw':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const DailyDrawScreen()));
        break;
      case 'hourly_draw':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const HourlyDrawScreen()));
        break;
      case 'results':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const AllResultsScreen()));
        break;
      case 'profile':
        Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
        break;
    }
  }

  void _onDrawCardTap(DrawModel draw) {
    switch (draw.type) {
      case DrawType.mega:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const MegaDrawScreen()),
        );
        break;
      case DrawType.daily:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DailyDrawScreen()),
        );
        break;
      case DrawType.hourly:
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const HourlyDrawScreen()),
        );
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: AppColors.background,
      appBar: TradexAppBar(
        onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        onNotificationTap: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notifications: 2 new draw winners announced!'),
              backgroundColor: AppColors.cardBgElevated,
            ),
          );
        },
      ),
      drawer: AppDrawer(onNavigate: _handleDrawerNavigation),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.goldPrimary,
          backgroundColor: AppColors.cardBgElevated,
          onRefresh: () async {
            await Future.delayed(const Duration(milliseconds: 600));
            if (mounted) setState(() {});
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Wallet Balance Card (Reactive to AppState)
                ListenableBuilder(
                  listenable: _appState,
                  builder: (context, _) {
                    return WalletBalanceCard(
                      balance: _appState.formattedBalance,
                      onCardTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const WalletScreen()),
                        );
                      },
                      onAddTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AddMoneyScreen()),
                        );
                      },
                    );
                  },
                ),

                const SizedBox(height: 22),

                // 2. CHOOSE YOUR DRAW Section Header
                Text(
                  'CHOOSE YOUR DRAW',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF7E8597),
                    letterSpacing: 0.9,
                  ),
                ),

                const SizedBox(height: 10),

                // 3. Draw Cards (Mega Draw, Daily Draw, Hourly Draw)
                ...DrawModel.sampleDraws.map(
                  (draw) => DrawCardWidget(
                    draw: draw,
                    onTap: () => _onDrawCardTap(draw),
                  ),
                ),

                const SizedBox(height: 14),

                // 4. LATEST RESULT Section
                LatestResultsSection(
                  results: DrawResult.latestResults,
                  onSeeAllTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AllResultsScreen()),
                    );
                  },
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
