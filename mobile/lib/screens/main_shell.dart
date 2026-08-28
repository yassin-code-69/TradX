import 'package:flutter/material.dart';
import 'package:tradex/screens/home_screen.dart';
import 'package:tradex/screens/my_tickets_screen.dart';
import 'package:tradex/screens/profile_screen.dart';
import 'package:tradex/screens/results_screen.dart';
import 'package:tradex/screens/wallet_screen.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/widgets/custom_bottom_nav.dart';

class MainShell extends StatefulWidget {
  final int initialTab;

  const MainShell({super.key, this.initialTab = 0});

  static void switchTab(BuildContext context, int tabIndex) {
    final state = context.findAncestorStateOfType<_MainShellState>();
    if (state != null) {
      state._onTabSelected(tabIndex);
    } else {
      AppState().setTabIndex(tabIndex);
    }
  }

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    if (widget.initialTab != 0) {
      _appState.setTabIndex(widget.initialTab);
    }
  }

  void _onTabSelected(int index) {
    _appState.setTabIndex(index);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _appState,
      builder: (context, _) {
        final currentIndex = _appState.currentTabIndex;

        return Scaffold(
          body: IndexedStack(
            index: currentIndex,
            children: const [
              HomeScreen(),
              MyTicketsScreen(),
              ResultsScreen(),
              WalletScreen(),
              ProfileScreen(),
            ],
          ),
          bottomNavigationBar: CustomBottomNav(
            currentIndex: currentIndex,
            onTap: _onTabSelected,
          ),
        );
      },
    );
  }
}
