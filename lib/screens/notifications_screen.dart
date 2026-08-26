import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/notification_model.dart';
import 'package:tradex/screens/main_shell.dart';
import 'package:tradex/state/app_state.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  NotificationCategory _selectedCategory = NotificationCategory.all;
  final AppState _appState = AppState();

  void _onNotificationTap(NotificationModel notif) {
    HapticFeedback.selectionClick();
    if (!notif.isRead) {
      _appState.markNotificationAsRead(notif.id);
    }

    // Handle deep-link routes based on category
    switch (notif.category) {
      case NotificationCategory.winnings:
      case NotificationCategory.draws:
        MainShell.switchTab(context, 2); // Results Tab
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
      case NotificationCategory.wallet:
        MainShell.switchTab(context, 3); // Wallet Tab
        Navigator.popUntil(context, (route) => route.isFirst);
        break;
      case NotificationCategory.promotions:
      case NotificationCategory.system:
      case NotificationCategory.all:
        // Already marked read
        break;
    }
  }

  void _markAllAsRead() {
    HapticFeedback.mediumImpact();
    _appState.markAllNotificationsAsRead();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('All notifications marked as read'),
        backgroundColor: AppColors.cardBgElevated,
        duration: Duration(seconds: 1),
      ),
    );
  }

  List<NotificationModel> _getFilteredList(List<NotificationModel> all) {
    if (_selectedCategory == NotificationCategory.all) {
      return all;
    }
    return all.where((n) => n.category == _selectedCategory).toList();
  }

  @override
  Widget build(BuildContext context) {
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
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          ListenableBuilder(
            listenable: _appState,
            builder: (context, _) {
              final unread = _appState.unreadNotificationsCount;
              if (unread == 0) return const SizedBox.shrink();

              return TextButton(
                onPressed: _markAllAsRead,
                child: Text(
                  'Mark all read',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.goldLight,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Horizontal Category Tabs Bar
            SizedBox(
              height: 42,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildTab(NotificationCategory.all, 'All'),
                  const SizedBox(width: 8),
                  _buildTab(NotificationCategory.draws, 'Draws'),
                  const SizedBox(width: 8),
                  _buildTab(NotificationCategory.winnings, 'Winnings'),
                  const SizedBox(width: 8),
                  _buildTab(NotificationCategory.wallet, 'Wallet'),
                  const SizedBox(width: 8),
                  _buildTab(NotificationCategory.promotions, 'Promos'),
                  const SizedBox(width: 8),
                  _buildTab(NotificationCategory.system, 'System'),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 2. Notifications List
            Expanded(
              child: ListenableBuilder(
                listenable: _appState,
                builder: (context, _) {
                  final allList = _appState.notifications;
                  final filtered = _getFilteredList(allList);

                  if (filtered.isEmpty) {
                    return TradexEmptyState(
                      icon: Icons.notifications_off_outlined,
                      title: 'No Notifications',
                      message: _selectedCategory == NotificationCategory.all
                          ? 'You are all caught up! No notifications to display.'
                          : 'No notifications in this category yet.',
                      iconColor: AppColors.goldPrimary,
                    );
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    separatorBuilder: (ctx, i) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final notif = filtered[index];
                      return GestureDetector(
                        onTap: () => _onNotificationTap(notif),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: notif.isRead ? AppColors.cardBg : AppColors.cardBgElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: notif.isRead
                                  ? AppColors.cardBorder
                                  : notif.iconColor.withValues(alpha: 0.4),
                              width: notif.isRead ? 1.0 : 1.3,
                            ),
                            boxShadow: notif.isRead
                                ? null
                                : [
                                    BoxShadow(
                                      color: notif.iconColor.withValues(alpha: 0.12),
                                      blurRadius: 10,
                                      offset: const Offset(0, 3),
                                    ),
                                  ],
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Category Icon
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: notif.iconBg,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: notif.iconColor.withValues(alpha: 0.4),
                                    width: 1,
                                  ),
                                ),
                                child: Icon(notif.icon, color: notif.iconColor, size: 20),
                              ),
                              const SizedBox(width: 12),

                              // Content Body
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            notif.title,
                                            style: GoogleFonts.inter(
                                              fontSize: 13.5,
                                              fontWeight:
                                                  notif.isRead ? FontWeight.w600 : FontWeight.w800,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          notif.timeAgo,
                                          style: GoogleFonts.inter(
                                            fontSize: 11,
                                            color: AppColors.textMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      notif.message,
                                      style: GoogleFonts.inter(
                                        fontSize: 12.5,
                                        color: notif.isRead
                                            ? AppColors.textSecondary
                                            : const Color(0xFFD1D5DB),
                                        height: 1.4,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Unread Glowing Dot
                              if (!notif.isRead) ...[
                                const SizedBox(width: 8),
                                Container(
                                  width: 8,
                                  height: 8,
                                  margin: const EdgeInsets.only(top: 4),
                                  decoration: BoxDecoration(
                                    color: notif.iconColor,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: notif.iconColor.withValues(alpha: 0.8),
                                        blurRadius: 6,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(NotificationCategory category, String label) {
    final isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedCategory = category);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6D28D9) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.purpleLight : AppColors.cardBorder,
            width: isSelected ? 1.2 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
