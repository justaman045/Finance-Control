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

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});
  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int tabIndex = 0;
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

  DateTime weekStart(DateTime date) =>
      date.subtract(Duration(days: date.weekday - 1));

  Future<void> _refreshData() async {
    setState(() {
      _streamKey = UniqueKey();
      activeBarIndex = null;
      chartPage = 0;
    });
    await Future.delayed(const Duration(seconds: 1));
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
            icon: Icon(
              Icons.arrow_back_ios,
              color: scheme.onBackground,
              size: 22.sp,
            ),
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
              onPressed: () => Get.to(
                () => AIInsightsScreen(),
                curve: curve,
                transition: transition,
                duration: duration,
              ),
              icon: Icon(Icons.analytics_outlined),
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
                      (doc) => TransactionModel.fromMap(
                        doc.id,
                        doc.data() as Map<String, dynamic>,
                      ),
                    )
                    .where(
                      (txn) =>
                          txn.senderId == userId || txn.recipientId == userId,
                    )
                    .toList();

                List<double> dataPoints = List.filled(periodCount, 0.0);
                final now = DateTime.now();
                List<DateTime> periodStarts = [];
                List<DateTime> periodEnds = [];

                if (statsPeriod == 'Daily') {
                  final today = now.subtract(Duration(days: now.weekday % 7));
                  for (int i = 0; i < 7; i++) {
                    periodStarts.add(
                      DateTime(today.year, today.month, today.day + i),
                    );
                    periodEnds.add(
                      DateTime(today.year, today.month, today.day + i + 1),
                    );
                  }
                } else if (statsPeriod == 'Weekly') {
                  DateTime firstOfYear = DateTime(now.year, 1, 1);
                  DateTime firstWeekStart = weekStart(firstOfYear);
                  for (int i = 0; i < periodCount; i++) {
                    final s = firstWeekStart.add(Duration(days: i * 7));
                    periodStarts.add(s);
                    periodEnds.add(s.add(const Duration(days: 7)));
                  }
                } else if (statsPeriod == 'Monthly') {
                  final currentYear = now.year;
                  for (int i = 0; i < 12; i++) {
                    periodStarts.add(DateTime(currentYear, i + 1, 1));
                    periodEnds.add(DateTime(currentYear, i + 2, 1));
                  }
                }

                for (var tx in txs) {
                  final time = tx.date;
                  int idx = 0;
                  for (int i = 0; i < periodEnds.length; i++) {
                    if (!time.isBefore(periodStarts[i]) &&
                        time.isBefore(periodEnds[i])) {
                      idx = i;
                      break;
                    }
                  }
                  if (idx >= 0 && idx < dataPoints.length) {
                    if (tabIndex == 0 && tx.recipientId == userId) {
                      dataPoints[idx] += tx.amount;
                    } else if (tabIndex == 1 && tx.senderId == userId) {
                      dataPoints[idx] += tx.amount;
                    }
                  }
                }

                int visibleBars = statsPeriod == 'Daily' ? 7 : 6;
                int maxPage = (dataPoints.length / visibleBars).ceil() - 1;
                int startIdx = chartPage * visibleBars;
                int endIdx = (startIdx + visibleBars).clamp(
                  0,
                  dataPoints.length,
                );
                List<String> labels = periodLabels[statsPeriod]!;
                final barLabels = labels.sublist(startIdx, endIdx);
                final barData = dataPoints.sublist(startIdx, endIdx);

                List<TransactionModel> filteredTxs = txs;
                if (activeBarIndex != null) {
                  final periodIdx = startIdx + activeBarIndex!;
                  filteredTxs = txs.where((tx) {
                    final time = tx.date;
                    final inPeriod =
                        !time.isBefore(periodStarts[periodIdx]) &&
                        time.isBefore(periodEnds[periodIdx]);
                    if (tabIndex == 0) {
                      return inPeriod && tx.recipientId == userId;
                    } else {
                      return inPeriod && tx.senderId == userId;
                    }
                  }).toList();
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
                                  activeBarIndex = null;
                                  chartPage = 0;
                                });
                              }
                            },
                            chartLabels: barLabels,
                            chartData: barData,
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
                            tabIndex: tabIndex,
                            onBarTap: (idx) => setState(() {
                              activeBarIndex = idx == activeBarIndex
                                  ? null
                                  : idx;
                            }),
                            activeBarIndex: activeBarIndex,
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 16.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 18),
                            SectionTitle(
                              title: 'Recent Payment',
                              onTap: () => gotoPage(TransactionHistoryScreen()),
                            ),
                            SizedBox(height: 12),
                            ...(activeBarIndex != null ? filteredTxs : txs)
                                .reversed
                                .map(
                                  (tx) => TxTile(
                                    tx: tx,
                                    received: tx.recipientId == userId,
                                  ),
                                )
                                .toList(),
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
  ) => Container(
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
      padding: EdgeInsets.all(18.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tabIndex == 0 ? "Income Statistics" : "Expense Statistics",
                    style: TextStyle(
                      color: isLight ? kLightTextSecondary : kDarkTextSecondary,
                      fontSize: 13.sp,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    "₹ ${chartData.fold(0, (a, b) => (a + b).toInt()).toStringAsFixed(2)}",
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
                padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 3.h),
                decoration: BoxDecoration(
                  color: isLight ? kLightBackground : kDarkBackground,
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: DropdownButton<String>(
                  underline: const SizedBox(),
                  dropdownColor: scheme.surface,
                  value: period,
                  onChanged: onPeriodChanged,
                  style: TextStyle(color: scheme.onSurface, fontSize: 12.5.sp),
                  icon: Icon(
                    Icons.keyboard_arrow_down,
                    size: 17.sp,
                    color: isLight ? kLightTextSecondary : kDarkTextSecondary,
                  ),
                  items: ['Daily', 'Weekly', 'Monthly']
                      .map(
                        (v) =>
                            DropdownMenuItem<String>(value: v, child: Text(v)),
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
          SizedBox(
            height: 72.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(
                chartData.length,
                (idx) => GestureDetector(
                  onTap: onBarTap != null ? () => onBarTap!(idx) : null,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 15.w,
                    height:
                        (maxValue == 0 ? 0.0 : chartData[idx] / maxValue * 70)
                            .h,
                    decoration: BoxDecoration(
                      color: idx == chartData.indexOf(maxValue)
                          ? (isLight ? kLightPrimary : kDarkPrimary)
                          : (isLight ? kLightBorder : kDarkDivider),
                      borderRadius: BorderRadius.circular(6.r),
                      border: Border.all(
                        color: (activeBarIndex ?? -1) == idx
                            ? scheme.primary
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: chartLabels
                .map(
                  (txt) => Text(
                    txt,
                    style: TextStyle(
                      color: isLight ? kLightTextSecondary : kDarkTextSecondary,
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
