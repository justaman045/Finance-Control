// --- imports ---
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:money_control/Components/colors.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Services/export_service.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

// -------------------------------

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  late final String uid;
  late final String? email;

  bool _loading = true;
  List<TransactionModel> _all = [];

  // ---- PERIOD SELECTION ----
  String _period = "This Month";

  final List<String> _periodOptions = [
    "Last Month",
    "This Month",
    "Last 3 Months",
    "Last 6 Months",
    "This Year",
    "Last Year",
    "All Time",
  ];

  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    uid = user?.uid ?? "";
    email = user?.email;

    _loadTx();
  }

  // ---------------- FIRESTORE LOAD ------------------

  Future<void> _loadTx() async {
    if (email == null) return;

    setState(() => _loading = true);

    try {
      final snap = await FirebaseFirestore.instance
          .collection('users')
          .doc(email)
          .collection('transactions')
          .orderBy('date', descending: false)
          .get();

      _all = snap.docs
          .map((e) => TransactionModel.fromMap(e.id, e.data()))
          .toList();
    } catch (_) {
      _all = [];
    }

    setState(() => _loading = false);
  }

  // ---------------- DATE RANGES ---------------------

  DateTimeRange _getDateRange() {
    final now = DateTime.now();

    switch (_period) {
      case "Last Month":
        final prev = DateTime(now.year, now.month - 1, 1);
        return DateTimeRange(
          start: prev,
          end: DateTime(prev.year, prev.month + 1, 1),
        );

      case "This Month":
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 1),
        );

      case "Last 3 Months":
        return DateTimeRange(
          start: DateTime(now.year, now.month - 2, 1),
          end: DateTime(now.year, now.month + 1, 1),
        );

      case "Last 6 Months":
        return DateTimeRange(
          start: DateTime(now.year, now.month - 5, 1),
          end: DateTime(now.year, now.month + 1, 1),
        );

      case "This Year":
        return DateTimeRange(
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year + 1, 1, 1),
        );

      case "Last Year":
        return DateTimeRange(
          start: DateTime(now.year - 1, 1, 1),
          end: DateTime(now.year, 1, 1),
        );

      case "All Time":
        return DateTimeRange(
          start: DateTime(2000),
          end: DateTime(2100),
        );

      default:
        return DateTimeRange(
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 1),
        );
    }
  }

  // --------------- FILTERED TRANSACTIONS ----------------

  List<TransactionModel> get _filtered {
    final range = _getDateRange();
    return _all.where((tx) {
      final inRange =
          tx.date.compareTo(range.start) >= 0 &&
              tx.date.compareTo(range.end) < 0;
      final catMatch =
          _categoryFilter == null || tx.category == _categoryFilter;
      return inRange && catMatch;
    }).toList();
  }

  // ---------------- QUICK OVERVIEW AGGREGATION ----------------

  // Daily totals
  (double income, double expense) get _todayTotals {
    final today = DateTime.now();
    final filtered = _all.where((tx) =>
    tx.date.year == today.year &&
        tx.date.month == today.month &&
        tx.date.day == today.day);

    double i = 0, e = 0;
    for (var tx in filtered) {
      if (tx.recipientId == uid) i += tx.amount;
      if (tx.senderId == uid) e += tx.amount + tx.tax;
    }
    return (i, e);
  }

  // Weekly totals
  (double income, double expense) get _thisWeekTotals {
    final now = DateTime.now();
    final weekStart = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: now.weekday - 1)); // Monday start
    final weekEnd = weekStart.add(const Duration(days: 7));

    final filtered = _all.where(
            (tx) => !tx.date.isBefore(weekStart) && tx.date.isBefore(weekEnd));

    double i = 0, e = 0;
    for (var tx in filtered) {
      if (tx.recipientId == uid) i += tx.amount;
      if (tx.senderId == uid) e += tx.amount + tx.tax;
    }
    return (i, e);
  }

  // Monthly totals
  (double income, double expense) get _thisMonthTotals {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month, 1);
    final end = DateTime(now.year, now.month + 1, 1);

    final filtered = _all.where((tx) =>
    tx.date.compareTo(start) >= 0 && tx.date.compareTo(end) < 0);

    double i = 0, e = 0;
    for (var tx in filtered) {
      if (tx.recipientId == uid) i += tx.amount;
      if (tx.senderId == uid) e += tx.amount + tx.tax;
    }
    return (i, e);
  }

  // --------------- AGGREGATION ------------------------

  double get totalIncome {
    return _filtered.fold(0, (sum, tx) {
      if (tx.recipientId == uid) return sum + tx.amount;
      return sum;
    });
  }

  double get totalExpense {
    return _filtered.fold(0, (sum, tx) {
      if (tx.senderId == uid) return sum + tx.amount + tx.tax;
      return sum;
    });
  }

  double get netBalance => totalIncome - totalExpense;

  // Spending by category
  Map<String, double> get spendingByCategory {
    final Map<String, double> map = {};
    for (var tx
    in _filtered.where((t) => t.senderId == uid || t.recipientId == uid)) {
      map[tx.category ?? "Other"] =
          (map[tx.category ?? "Other"] ?? 0) + tx.amount + tx.tax;
    }
    return map;
  }

  // Monthly trend
  List<_MonthPoint> get _monthlyTrend {
    final map = <String, _MonthPoint>{};
    for (var tx in _filtered) {
      final key = "${tx.date.year}-${tx.date.month.toString().padLeft(2, '0')}";
      map.putIfAbsent(
        key,
            () => _MonthPoint(
          label: "${_monthAbbr(tx.date.month)} ${tx.date.year}",
        ),
      );

      if (tx.recipientId == uid) map[key]!.income += tx.amount;
      if (tx.senderId == uid) map[key]!.expense += (tx.amount + tx.tax);
    }

    final keys = map.keys.toList()..sort((a, b) => a.compareTo(b));

    return keys.map((k) => map[k]!).toList();
  }

  String _monthAbbr(int m) {
    const list = [
      "Jan",
      "Feb",
      "Mar",
      "Apr",
      "May",
      "Jun",
      "Jul",
      "Aug",
      "Sep",
      "Oct",
      "Nov",
      "Dec"
    ];
    return list[m - 1];
  }

  // ---------------- EXPORT --------------------------

  Future<void> _exportCsv() async =>
      ExportService.exportTransactionsCSV(_filtered);

  Future<void> _exportPdf() async =>
      ExportService.exportAnalyticsPDF(
        filtered: _filtered,
        totalIncome: totalIncome,
        totalExpense: totalExpense,
        netBalance: netBalance,
        periodLabel: _period,
      );

  // ================================================================
  // UI
  // ================================================================

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            isLight ? kLightGradientTop : kDarkGradientTop,
            isLight ? kLightGradientBottom : kDarkGradientBottom
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text("Analytics & Reports"),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          actions: [
            PopupMenuButton(
              icon: const Icon(Icons.download),
              onSelected: (v) => v == "csv" ? _exportCsv() : _exportPdf(),
              itemBuilder: (ctx) => const [
                PopupMenuItem(value: "csv", child: Text("Export CSV")),
                PopupMenuItem(value: "pdf", child: Text("Export PDF")),
              ],
            ),
          ],
        ),
        backgroundColor: Colors.transparent,
        bottomNavigationBar: const BottomNavBar(currentIndex: 1),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(scheme),
      ),
    );
  }

  Widget _buildBody(ColorScheme scheme) {
    final categories = spendingByCategory.keys.toList();

    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 16.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ------------ FILTER CARD ------------------
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(16.r),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Filters",
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurface,
                  ),
                ),
                SizedBox(height: 8.h),
                Row(
                  children: [
                    Expanded(
                      child: _dropdown<String>(
                        scheme,
                        label: "Period",
                        value: _period,
                        items: _periodOptions,
                        onChanged: (v) => setState(() => _period = v),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _dropdown<String?>(
                        scheme,
                        label: "Category",
                        value: _categoryFilter,
                        items: [null, ...categories],
                        format: (v) => v ?? "All Categories",
                        onChanged: (v) => setState(() => _categoryFilter = v),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          SizedBox(height: 14.h),

          // ------------ QUICK OVERVIEW (histograms) ------------------
          _quickOverviewCard(scheme),

          SizedBox(height: 14.h),

          // -------- Summary Cards ----------
          Text(
            "Summary",
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Row(
            children: [
              _summary(scheme, "Income", totalIncome, Colors.green),
              SizedBox(width: 8.w),
              _summary(scheme, "Expenses", totalExpense, Colors.red),
              SizedBox(width: 8.w),
              _summary(scheme, "Net", netBalance,
                  netBalance >= 0 ? Colors.green : Colors.red),
            ],
          ),

          SizedBox(height: 16.h),

          // ------------- TREND CHART -------------------
          _buildTrendChart(scheme),

          SizedBox(height: 16.h),

          // ------------- PIE CHART -------------------
          _buildPieChart(scheme),
        ],
      ),
    );
  }

  // ---------- QUICK OVERVIEW CARD UI (histogram style) -----------

  Widget _quickOverviewCard(ColorScheme scheme) {
    final (dIncome, dExpense) = _todayTotals;
    final (wIncome, wExpense) = _thisWeekTotals;
    final (mIncome, mExpense) = _thisMonthTotals;

    final maxVal = [
      dIncome,
      dExpense,
      wIncome,
      wExpense,
      mIncome,
      mExpense,
    ].fold<double>(0, (p, e) => e > p ? e : p);

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Quick Overview",
            style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: scheme.onSurface),
          ),
          SizedBox(height: 12.h),

          _quickHistogramRow("Today", dIncome, dExpense, maxVal, scheme),
          SizedBox(height: 12.h),

          _quickHistogramRow("This Week", wIncome, wExpense, maxVal, scheme),
          SizedBox(height: 12.h),

          _quickHistogramRow("This Month", mIncome, mExpense, maxVal, scheme),
        ],
      ),
    );
  }

  Widget _quickHistogramRow(
      String label,
      double inc,
      double exp,
      double maxVal,
      ColorScheme scheme,
      ) {
    final safeMax = maxVal <= 0 ? 1 : maxVal;
    final incRatio = inc / safeMax;
    final expRatio = exp / safeMax;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // header row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: scheme.onSurface.withOpacity(0.9),
              ),
            ),
            Text(
              "+₹${inc.toStringAsFixed(0)} / -₹${exp.toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: 11.sp,
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),
          ],
        ),
        SizedBox(height: 6.h),

        // bar row
        LayoutBuilder(
          builder: (context, constraints) {
            final totalWidth = constraints.maxWidth;
            final barMaxWidth = totalWidth; // full width bars stacked

            return Column(
              children: [
                // income bar
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 6.h,
                    width: barMaxWidth * incRatio,
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                // expense bar
                Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    height: 6.h,
                    width: barMaxWidth * expRatio,
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.8),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  // ---------- Reusable dropdown with label -----------

  Widget _dropdown<T>(
      ColorScheme scheme, {
        required String label,
        required T value,
        required List<T> items,
        required Function(T) onChanged,
        String Function(T)? format,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: scheme.onSurface.withOpacity(0.7),
          ),
        ),
        SizedBox(height: 4.h),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w),
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: DropdownButton<T>(
            value: value,
            isExpanded: true,
            underline: const SizedBox(),
            items: items
                .map(
                  (e) => DropdownMenuItem(
                value: e,
                child: Text(
                  format?.call(e) ?? e.toString(),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
                .toList(),
            onChanged: (v) => onChanged(v as T),
          ),
        ),
      ],
    );
  }

  Widget _summary(
      ColorScheme scheme, String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.all(12.w),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(14.r),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: scheme.onSurface.withOpacity(0.7),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              "₹${amount.toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w700,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= TREND CHART ===================

  Widget _buildTrendChart(ColorScheme scheme) {
    final data = _monthlyTrend;
    if (data.isEmpty) {
      return _emptyCard(scheme, "Not enough data for trend.");
    }

    // If only 1 month -> show bar chart comparison instead of weird 2 dots
    if (data.length == 1) {
      return _buildSingleMonthComparisonCard(scheme, data.first);
    }

    final maxY = data.fold<double>(
      0,
          (v, e) => [v, e.income, e.expense].reduce((a, b) => a > b ? a : b),
    );

    return Container(
      height: 260.h,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Income vs Expense (Monthly)",
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),

          // legend
          Row(
            children: [
              _legendDot(Colors.green),
              Text(
                " Income  ",
                style: TextStyle(fontSize: 11.sp),
              ),
              _legendDot(Colors.red),
              Text(
                " Expense",
                style: TextStyle(fontSize: 11.sp),
              ),
            ],
          ),

          SizedBox(height: 10.h),

          Expanded(
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY <= 0 ? 1 : maxY * 1.2,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= data.length) {
                          return const SizedBox();
                        }
                        return Text(
                          data[i].label.split(' ').first,
                          style: TextStyle(fontSize: 10.sp),
                        );
                      },
                    ),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles:
                    SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                lineBarsData: [
                  // Income
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < data.length; i++)
                        FlSpot(i.toDouble(), data[i].income),
                    ],
                    color: Colors.green,
                    isCurved: true,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                  // Expense
                  LineChartBarData(
                    spots: [
                      for (int i = 0; i < data.length; i++)
                        FlSpot(i.toDouble(), data[i].expense),
                    ],
                    color: Colors.red,
                    isCurved: true,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSingleMonthComparisonCard(
      ColorScheme scheme, _MonthPoint point) {
    final maxY =
    [point.income, point.expense].reduce((a, b) => a > b ? a : b);
    final safeMax = maxY <= 0 ? 1.0 : maxY;

    return Container(
      height: 240.h,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Income vs Expense (${point.label})",
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            "Detailed bar comparison for this period.",
            style: TextStyle(
              fontSize: 11.sp,
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: safeMax * 1.2,
                gridData: FlGridData(show: true),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles:
                    SideTitles(showTitles: true, reservedSize: 40),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, meta) {
                        switch (v.toInt()) {
                          case 0:
                            return Text(
                              "Income",
                              style: TextStyle(fontSize: 11.sp),
                            );
                          case 1:
                            return Text(
                              "Expense",
                              style: TextStyle(fontSize: 11.sp),
                            );
                          default:
                            return const SizedBox();
                        }
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: point.income,
                        color: Colors.green,
                        width: 28.w,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: point.expense,
                        color: Colors.red,
                        width: 28.w,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color c) => Container(
    width: 10,
    height: 10,
    margin: EdgeInsets.only(right: 4.w),
    decoration: BoxDecoration(
      color: c,
      borderRadius: BorderRadius.circular(50),
    ),
  );

  // ================= PIE CHART ===================

  Widget _buildPieChart(ColorScheme scheme) {
    final data = spendingByCategory;
    if (data.isEmpty) {
      return _emptyCard(scheme, "No expenses in this period.");
    }

    final total = data.values.fold(0.0, (s, v) => s + v);
    final entries = data.entries.toList();

    return Container(
      height: 260.h,
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Spending by Category",
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Expanded(
            child: Row(
              children: [
                Expanded(
                  flex: 4,
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 30.r,
                      sections: [
                        for (int i = 0; i < entries.length; i++)
                          PieChartSectionData(
                            value: entries[i].value,
                            title:
                            "${(entries[i].value / total * 100).toStringAsFixed(1)}%",
                            titleStyle: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.white,
                            ),
                            color: Colors
                                .primaries[i % Colors.primaries.length],
                            radius: 50.r,
                          ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  flex: 6,
                  child: ListView.builder(
                    itemCount: entries.length,
                    itemBuilder: (_, i) {
                      final e = entries[i];
                      final color =
                      Colors.primaries[i % Colors.primaries.length];

                      return Padding(
                        padding: EdgeInsets.only(bottom: 8.h),
                        child: Row(
                          children: [
                            Container(
                              width: 10.w,
                              height: 10.w,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Text(
                                e.key,
                                style: TextStyle(fontSize: 12.sp),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(
                              "₹${e.value.toStringAsFixed(0)}",
                              style: TextStyle(
                                fontSize: 12.sp,
                                color:
                                scheme.onSurface.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(ColorScheme scheme, String text) {
    return Container(
      height: 200.h,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Center(
        child: Text(
          text,
          style: TextStyle(color: scheme.onSurface.withOpacity(0.7)),
        ),
      ),
    );
  }
}

// --- Model for chart ---
class _MonthPoint {
  String label;
  double income;
  double expense;

  _MonthPoint({
    required this.label,
    this.income = 0,
    this.expense = 0,
  });
}
