import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

import 'package:money_control/Components/methods.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Components/tx_tile.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/section_title.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Screens/analysis.dart';
import 'package:money_control/Screens/transaction_history.dart';
import 'package:money_control/Screens/analysis.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int tabIndex = 0; // 0 = income, 1 = expenses
  String statsPeriod = 'Weekly';
  int chartPage = 0;
  int? activeBarIndex;
  Key _streamKey = UniqueKey();

  final Map<String, List<String>> periodLabels = {
    'Daily': ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'],
    'Weekly': List.generate(12, (i) => 'W${i + 1}'),
    'Monthly': [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ],
  };

  int get periodCount => statsPeriod == 'Daily' ? 7 : 12;

  Future<void> _refreshData() async {
    setState(() {
      _streamKey = UniqueKey();
      activeBarIndex = null;
      chartPage = 0;
    });
    await Future.delayed(const Duration(milliseconds: 600));
  }

  // Simple model for period ranges (start–end)
  List<PeriodRange> _generatePeriods() {
    final now = DateTime.now();
    final year = now.year;
    final month = now.month;

    if (statsPeriod == 'Daily') {
      // Mon → Sun of current week
      final monday = now.subtract(Duration(days: now.weekday - 1));
      return List.generate(7, (i) {
        final start = DateTime(monday.year, monday.month, monday.day + i);
        final end = start.add(const Duration(days: 1));
        return PeriodRange(start, end);
      });
    }

    if (statsPeriod == 'Weekly') {
      final List<PeriodRange> periods = [];

      // First day of selected month
      final startOfMonth = DateTime(year, month, 1);
      final nextMonth = DateTime(year, month + 1, 1);
      final endOfMonth = nextMonth;

      DateTime weekStart = startOfMonth;

      while (weekStart.isBefore(endOfMonth)) {
        final weekEnd =
        weekStart.add(const Duration(days: 7)).isBefore(endOfMonth)
            ? weekStart.add(const Duration(days: 7))
            : endOfMonth;

        periods.add(PeriodRange(weekStart, weekEnd));
        weekStart = weekEnd;
      }

      return periods;
    }

    // Monthly view (unchanged)
    return List.generate(12, (i) {
      final start = DateTime(year, i + 1, 1);
      final end = DateTime(year, i + 2, 1);
      return PeriodRange(start, end);
    });
  }


  List<double> _generateBarData(
      List<TransactionModel> txs,
      List<PeriodRange> periods,
      String userId,
      ) {
    final result = List<double>.filled(periods.length, 0.0);

    for (final tx in txs) {
      final t = tx.date;

      for (int i = 0; i < periods.length; i++) {
        final p = periods[i];
        if (!t.isBefore(p.start) && t.isBefore(p.end)) {
          if (tabIndex == 0 && tx.recipientId == userId) {
            // income
            result[i] += tx.amount;
          } else if (tabIndex == 1 && tx.senderId == userId) {
            // expense
            result[i] += tx.amount;
          }
          break;
        }
      }
    }
    return result;
  }

  List<TransactionModel> _filterTxsForBar(
      List<TransactionModel> all,
      List<PeriodRange> periods,
      int barIndex,
      String userId,
      ) {
    final p = periods[barIndex];
    return all.where((tx) {
      final t = tx.date;
      final inPeriod = !t.isBefore(p.start) && t.isBefore(p.end);

      if (!inPeriod) return false;

      if (tabIndex == 0) {
        return tx.recipientId == userId;
      } else {
        return tx.senderId == userId;
      }
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool isLight = scheme.brightness == Brightness.light;

    final gradientTop = isLight ? kLightGradientTop : kDarkGradientTop;
    final gradientBottom = isLight ? kLightGradientBottom : kDarkGradientBottom;

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: Text(
            "You are not logged in",
            style: TextStyle(color: scheme.error),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [gradientTop, gradientBottom],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          toolbarHeight: 62.h,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: scheme.onBackground),
            onPressed: () => Navigator.pop(context),
          ),
          centerTitle: true,
          title: Text(
            "Analysis",
            style: TextStyle(
              color: scheme.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.analytics_outlined),
              onPressed: () => Get.to(
                    () => const AIInsightsScreen(),
                curve: curve,
                transition: transition,
                duration: duration,
              ),
            ),
          ],
        ),
        body: SafeArea(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            child: StreamBuilder<QuerySnapshot>(
              key: _streamKey,
              stream: FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.email)
                  .collection('transactions')
                  .orderBy('createdAt')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                final userId = user.uid;

                final txs = docs
                    .map(
                      (d) => TransactionModel.fromMap(
                    d.id,
                    d.data() as Map<String, dynamic>,
                  ),
                )
                    .where(
                      (tx) =>
                  tx.senderId == userId || tx.recipientId == userId,
                )
                    .toList();

                final periods = _generatePeriods();
                final barData = _generateBarData(txs, periods, userId);

                final totalPeriods = periods.length;
                final visibleBars = statsPeriod == 'Daily' ? 7 : 6;
                final maxPage =
                    (totalPeriods / visibleBars).ceil() - 1;

                final startIdx = chartPage * visibleBars;
                final endIdx =
                (startIdx + visibleBars).clamp(0, totalPeriods);

                final labels = periodLabels[statsPeriod]!;
                final chartLabels = labels.sublist(startIdx, endIdx);
                final chartSlice = barData.sublist(startIdx, endIdx);

                final List<TransactionModel> shownTxs;
                if (activeBarIndex != null) {
                  final barIndex = startIdx + activeBarIndex!;
                  shownTxs =
                      _filterTxsForBar(txs, periods, barIndex, userId);
                } else {
                  shownTxs = txs;
                }

                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    tabIndex = 0;
                                    activeBarIndex = null;
                                  }),
                                  child: _tabBtn(
                                    "Income",
                                    tabIndex == 0,
                                    scheme,
                                    isLight,
                                  ),
                                ),
                              ),
                              SizedBox(width: 10.w),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => setState(() {
                                    tabIndex = 1;
                                    activeBarIndex = null;
                                  }),
                                  child: _tabBtn(
                                    "Expenses",
                                    tabIndex == 1,
                                    scheme,
                                    isLight,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),
                          _AnalyticsStatsCard(
                            period: statsPeriod,
                            onPeriodChanged: (v) {
                              if (v != null) {
                                setState(() {
                                  statsPeriod = v;
                                  chartPage = 0;
                                  activeBarIndex = null;
                                });
                              }
                            },
                            chartLabels: chartLabels,
                            chartData: chartSlice,
                            tabIndex: tabIndex,
                            activeBarIndex: activeBarIndex,
                            onBarTap: (idx) => setState(() {
                              activeBarIndex =
                              idx == activeBarIndex ? null : idx;
                            }),
                            onLeft: chartPage > 0
                                ? () => setState(() {
                              chartPage--;
                              activeBarIndex = null;
                            })
                                : null,
                            onRight: chartPage < maxPage
                                ? () => setState(() {
                              chartPage++;
                              activeBarIndex = null;
                            })
                                : null,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding:
                        EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 18),
                            SectionTitle(
                              title: 'Recent Payment',
                              onTap: () =>
                                  gotoPage(TransactionHistoryScreen()),
                            ),
                            SizedBox(height: 12),
                            ...shownTxs.reversed.map(
                                  (tx) => TxTile(
                                tx: tx,
                                received: tx.recipientId == userId,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
        bottomNavigationBar: BottomNavBar(currentIndex: 1),
      ),
    );
  }

  Widget _tabBtn(
      String label,
      bool selected,
      ColorScheme scheme,
      bool isLight,
      ) =>
      Container(
        height: 40.h,
        decoration: BoxDecoration(
          color: selected ? scheme.primary : scheme.surface,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: selected
                ? scheme.primary
                : (isLight ? kLightBorder : kDarkBorder),
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? scheme.onPrimary : scheme.onSurface,
              fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              fontSize: 15.sp,
            ),
          ),
        ),
      );
}

/// Simple range model instead of Dart records (works on all versions)
class PeriodRange {
  final DateTime start;
  final DateTime end;

  PeriodRange(this.start, this.end);
}

class _AnalyticsStatsCard extends StatelessWidget {
  final String period;
  final ValueChanged<String?> onPeriodChanged;
  final List<String> chartLabels;
  final List<double> chartData;
  final VoidCallback? onLeft;
  final VoidCallback? onRight;
  final int tabIndex;
  final Function(int)? onBarTap;
  final int? activeBarIndex;

  const _AnalyticsStatsCard({
    required this.period,
    required this.onPeriodChanged,
    required this.chartLabels,
    required this.chartData,
    this.onLeft,
    this.onRight,
    required this.tabIndex,
    this.onBarTap,
    this.activeBarIndex,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bool isLight = scheme.brightness == Brightness.light;

    final maxValue = chartData.isNotEmpty
        ? chartData.reduce((a, b) => a > b ? a : b)
        : 0.0;

    return Container(
      height: 205.h,
      width: double.infinity,
      padding: EdgeInsets.all(18.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(19.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top row
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tabIndex == 0
                        ? "Income Statistics"
                        : "Expense Statistics",
                    style: TextStyle(
                      color:
                      isLight ? kLightTextSecondary : kDarkTextSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "₹ ${chartData.fold(0.0, (a, b) => a + b).toStringAsFixed(2)}",
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 18.sp,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Container(
                padding:
                EdgeInsets.symmetric(horizontal: 11.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isLight ? kLightBackground : kDarkBackground,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: DropdownButton<String>(
                  underline: const SizedBox(),
                  dropdownColor: scheme.surface,
                  value: period,
                  onChanged: onPeriodChanged,
                  style: TextStyle(
                    color: scheme.onSurface,
                    fontSize: 12.5.sp,
                  ),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 17.sp,
                    color:
                    isLight ? kLightTextSecondary : kDarkTextSecondary,
                  ),
                  items: ['Daily', 'Weekly', 'Monthly']
                      .map(
                        (v) => DropdownMenuItem<String>(
                      value: v,
                      child: Text(v),
                    ),
                  )
                      .toList(),
                ),
              ),
              if (onLeft != null)
                IconButton(
                  icon: Icon(Icons.chevron_left, size: 22.sp),
                  onPressed: onLeft,
                ),
              if (onRight != null)
                IconButton(
                  icon: Icon(Icons.chevron_right, size: 22.sp),
                  onPressed: onRight,
                ),
            ],
          ),
          SizedBox(height: 19.h),
          // Bar chart
          SizedBox(
            height: 72.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(chartData.length, (idx) {
                final value = chartData[idx];
                final heightFactor =
                maxValue == 0 ? 0.0 : value / maxValue;

                return Expanded(
                  child: GestureDetector(
                    onTap: onBarTap != null ? () => onBarTap!(idx) : null,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: EdgeInsets.symmetric(horizontal: 4.w),
                      height: (heightFactor * 70).h,
                      decoration: BoxDecoration(
                        color: (activeBarIndex ?? -1) == idx
                            ? scheme.primary
                            : (isLight
                            ? kLightBorder
                            : kDarkDivider),
                        borderRadius: BorderRadius.circular(6.r),
                        border: Border.all(
                          color: (activeBarIndex ?? -1) == idx
                              ? scheme.primary
                              : Colors.transparent,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          SizedBox(height: 12.h),
          // Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: chartLabels
                .map(
                  (txt) => Text(
                txt,
                style: TextStyle(
                  color: isLight
                      ? kLightTextSecondary
                      : kDarkTextSecondary,
                  fontSize: 11.sp,
                ),
              ),
            )
                .toList(),
          ),
        ],
      ),
    );
  }
}
