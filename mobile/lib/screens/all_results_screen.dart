import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:tradex/models/draw_model.dart';
import 'package:tradex/models/draw_result.dart';
import 'package:tradex/theme/app_colors.dart';
import 'package:tradex/widgets/tradex_widgets.dart';

enum AllResultsFilter {
  all,
  mega,
  daily,
  hourly,
}

class AllResultsScreen extends StatefulWidget {
  const AllResultsScreen({super.key});

  @override
  State<AllResultsScreen> createState() => _AllResultsScreenState();
}

class _AllResultsScreenState extends State<AllResultsScreen> {
  AllResultsFilter _selectedFilter = AllResultsFilter.all;
  final TextEditingController _searchController = TextEditingController();
  DateTime? _selectedDateFilter;
  String _searchQuery = '';
  final Set<String> _expandedResultIds = {};

  static final List<DrawResult> _archiveResults = [
    DrawResult(
      id: 'res_mega_42',
      drawId: 'mega',
      title: 'Mega Draw #42 (August Edition)',
      date: '01 Aug 2026 | 09:00 PM',
      drawDateTime: DateTime(2026, 8, 1, 21, 0),
      winningNumbers: ['1', '2', '3', '4', '5', '6', '7'],
      type: DrawType.mega,
      accentColor: AppColors.goldPrimary,
      totalPrizeDistributed: '৳ 6,25,000',
      totalWinnersCount: 189,
      jackpotWinnerName: 'Shek Ahmmed (017***678)',
    ),
    DrawResult(
      id: 'res_daily_311',
      drawId: 'daily',
      title: 'Daily Draw #311',
      date: '25 Aug 2026 | 10:00 PM',
      drawDateTime: DateTime(2026, 8, 25, 22, 0),
      winningNumbers: ['5', '6', '7'],
      type: DrawType.daily,
      accentColor: AppColors.greenAccent,
      totalPrizeDistributed: '৳ 52,750',
      totalWinnersCount: 64,
      jackpotWinnerName: 'Tanvir_Boss (019***991)',
    ),
    DrawResult(
      id: 'res_hourly_1049',
      drawId: 'hourly',
      title: 'Hourly Draw #1049',
      date: '26 Aug 2026 | 09:00 PM',
      drawDateTime: DateTime(2026, 8, 26, 21, 0),
      winningNumbers: ['1', '7', '3'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
      totalPrizeDistributed: '৳ 21,100',
      totalWinnersCount: 28,
      jackpotWinnerName: 'Rahim_99 (017***382)',
    ),
    DrawResult(
      id: 'res_hourly_1048',
      drawId: 'hourly',
      title: 'Hourly Draw #1048',
      date: '26 Aug 2026 | 08:00 PM',
      drawDateTime: DateTime(2026, 8, 26, 20, 0),
      winningNumbers: ['9', '0', '4'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
      totalPrizeDistributed: '৳ 20,400',
      totalWinnersCount: 19,
      jackpotWinnerName: 'Fahim_Dhaka (018***442)',
    ),
    DrawResult(
      id: 'res_hourly_1047',
      drawId: 'hourly',
      title: 'Hourly Draw #1047',
      date: '26 Aug 2026 | 07:00 PM',
      drawDateTime: DateTime(2026, 8, 26, 19, 0),
      winningNumbers: ['4', '8', '2'],
      type: DrawType.hourly,
      accentColor: AppColors.purpleAccent,
      totalPrizeDistributed: '৳ 20,800',
      totalWinnersCount: 22,
      jackpotWinnerName: 'Mim_Khulna (013***887)',
    ),
    DrawResult(
      id: 'res_daily_310',
      drawId: 'daily',
      title: 'Daily Draw #310',
      date: '24 Aug 2026 | 10:00 PM',
      drawDateTime: DateTime(2026, 8, 24, 22, 0),
      winningNumbers: ['3', '8', '2'],
      type: DrawType.daily,
      accentColor: AppColors.greenAccent,
      totalPrizeDistributed: '৳ 51,500',
      totalWinnersCount: 52,
      jackpotWinnerName: 'Mamun_Chy (016***112)',
    ),
    DrawResult(
      id: 'res_mega_41',
      drawId: 'mega',
      title: 'Mega Draw #41 (July Edition)',
      date: '01 Jul 2026 | 09:00 PM',
      drawDateTime: DateTime(2026, 7, 1, 21, 0),
      winningNumbers: ['7', '5', '9', '0', '3', '1', '8'],
      type: DrawType.mega,
      accentColor: AppColors.goldPrimary,
      totalPrizeDistributed: '৳ 6,00,000',
      totalWinnersCount: 172,
      jackpotWinnerName: 'Jaber_Pro (017***990)',
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _pickDateFilter() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateFilter ?? now,
      firstDate: DateTime(2025, 1, 1),
      lastDate: DateTime(2027, 12, 31),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.goldPrimary,
              onPrimary: Colors.black,
              surface: AppColors.cardBgElevated,
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateFilter = picked;
      });
      HapticFeedback.selectionClick();
    }
  }

  void _clearDateFilter() {
    setState(() {
      _selectedDateFilter = null;
    });
    HapticFeedback.selectionClick();
  }

  void _toggleExpanded(String id) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_expandedResultIds.contains(id)) {
        _expandedResultIds.remove(id);
      } else {
        _expandedResultIds.add(id);
      }
    });
  }

  List<DrawResult> get _filteredResults {
    return _archiveResults.where((r) {
      // 1. Draw Type filter
      if (_selectedFilter == AllResultsFilter.mega && r.type != DrawType.mega) return false;
      if (_selectedFilter == AllResultsFilter.daily && r.type != DrawType.daily) return false;
      if (_selectedFilter == AllResultsFilter.hourly && r.type != DrawType.hourly) return false;

      // 2. Date filter
      if (_selectedDateFilter != null) {
        final rDate = r.effectiveDrawDateTime;
        if (rDate.year != _selectedDateFilter!.year ||
            rDate.month != _selectedDateFilter!.month ||
            rDate.day != _selectedDateFilter!.day) {
          return false;
        }
      }

      // 3. Search Query filter
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final inTitle = r.title.toLowerCase().contains(query);
        final inNumber = r.joinedWinningNumber.contains(query);
        final inWinner = r.jackpotWinnerName.toLowerCase().contains(query);
        return inTitle || inNumber || inWinner;
      }

      return true;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final results = _filteredResults;

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
          'Draw Archive',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _selectedDateFilter != null ? Icons.event_available_rounded : Icons.calendar_month_rounded,
              color: _selectedDateFilter != null ? AppColors.goldLight : Colors.white,
              size: 22,
            ),
            onPressed: _pickDateFilter,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 1. Search Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 8),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (val) => setState(() => _searchQuery = val.trim()),
                  style: GoogleFonts.inter(fontSize: 13.5, color: Colors.white),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    hintText: 'Search by draw edition or winning digits...',
                    hintStyle: GoogleFonts.inter(fontSize: 12.5, color: AppColors.textMuted),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),

            // 2. Filter Tabs & Date Filter Chip
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildFilterTab(AllResultsFilter.all, 'All Draws'),
                          const SizedBox(width: 6),
                          _buildFilterTab(AllResultsFilter.mega, 'Mega Draws'),
                          const SizedBox(width: 6),
                          _buildFilterTab(AllResultsFilter.daily, 'Daily Draws'),
                          const SizedBox(width: 6),
                          _buildFilterTab(AllResultsFilter.hourly, 'Hourly Draws'),
                        ],
                      ),
                    ),
                  ),
                  if (_selectedDateFilter != null) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: _clearDateFilter,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.goldPrimary),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_selectedDateFilter!.day}/${_selectedDateFilter!.month}',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: AppColors.goldLight,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.close_rounded, size: 14, color: AppColors.goldLight),
                          ],
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 12),

            // 3. Results Archive List
            Expanded(
              child: results.isEmpty
                  ? TradexEmptyState(
                      icon: Icons.history_rounded,
                      title: 'No Results Found',
                      message: 'No draw results matched your current filters.',
                      iconColor: AppColors.purpleLight,
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      itemCount: results.length,
                      separatorBuilder: (ctx, i) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final result = results[index];
                        final isExpanded = _expandedResultIds.contains(result.id);

                        return _buildArchiveResultCard(result, isExpanded);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArchiveResultCard(DrawResult result, bool isExpanded) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isExpanded ? result.accentColor.withValues(alpha: 0.6) : AppColors.cardBorder,
          width: isExpanded ? 1.4 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header Row
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _toggleExpanded(result.id),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          _buildTypeBadge(result.type),
                          const SizedBox(width: 8),
                          Text(
                            result.title,
                            style: GoogleFonts.inter(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      Icon(
                        isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    result.date,
                    style: GoogleFonts.inter(
                      fontSize: 11.5,
                      color: AppColors.textSecondary,
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Winning Numbers Row
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: result.winningNumbers.map((digit) {
                      return Container(
                        width: result.winningNumbers.length > 4 ? 30 : 36,
                        height: result.winningNumbers.length > 4 ? 30 : 36,
                        decoration: BoxDecoration(
                          color: result.accentColor.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: result.accentColor.withValues(alpha: 0.6),
                            width: 1.2,
                          ),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          digit,
                          style: GoogleFonts.poppins(
                            fontSize: result.winningNumbers.length > 4 ? 13 : 15,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),

          // Expandable Details Section
          if (isExpanded) ...[
            const Divider(color: AppColors.divider, height: 1),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.backgroundSecondary,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
              ),
              child: Column(
                children: [
                  _buildDetailRow('Total Prize Distributed', result.totalPrizeDistributed, result.accentColor),
                  const SizedBox(height: 8),
                  _buildDetailRow('Total Winners Count', '${result.totalWinnersCount} Winners', Colors.white),
                  const SizedBox(height: 8),
                  _buildDetailRow('Jackpot Winner', result.jackpotWinnerName, AppColors.goldLight),
                  const SizedBox(height: 12),
                  TradexButton(
                    text: 'VERIFY DRAW ON BLOCKCHAIN / RNG',
                    variant: TradexButtonVariant.glass,
                    height: 38,
                    fontSize: 11.5,
                    icon: Icons.verified_outlined,
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('RNG Seed & SHA-256 Hash verified authentic ✓'),
                          backgroundColor: AppColors.greenDark,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, Color valueColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(fontSize: 12, color: AppColors.textSecondary),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildTypeBadge(DrawType type) {
    Color color;
    String label;

    switch (type) {
      case DrawType.mega:
        color = AppColors.goldPrimary;
        label = 'MEGA';
        break;
      case DrawType.daily:
        color = AppColors.greenAccent;
        label = 'DAILY';
        break;
      case DrawType.hourly:
        color = AppColors.purpleAccent;
        label = 'HOURLY';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }

  Widget _buildFilterTab(AllResultsFilter filter, String label) {
    final isSelected = _selectedFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedFilter = filter);
        HapticFeedback.selectionClick();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6D28D9) : AppColors.cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? AppColors.purpleLight : AppColors.cardBorder,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11.5,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
