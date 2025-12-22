// lib/Screens/ai_insights.dart

import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Models/transaction.dart';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  bool loading = true;
  String? error;

  double forecastTotal = 0;
  double currentMonthSpent = 0;
  double todaySpent = 0;

  /// ⚠️ UI USES THIS AS MONTHLY TARGET
  double usualMonthAvg = 0;

  double overshootPercent = 0;

  List<CategoryInsight> insights = [];
  Map<DateTime, double> dailySpending = {};

  final Set<String> fixedCategories = {
    "Rent",
    "EMI",
    "Insurance",
    "Subscription",
    "Electricity",
    "Internet",
  };

  @override
  void initState() {
    super.initState();
    _runInsights();
  }

  // ======================================================
  // ✅ FINAL, CORRECT AI LOGIC (UI UNCHANGED)
  // ======================================================
  Future<void> _runInsights() async {
    try {
      setState(() {
        loading = true;
        error = null;
      });

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        setState(() {
          loading = false;
          error = "User not authenticated";
        });
        return;
      }

      final uid = user.uid;
      final email = user.email!;

      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final daysPassed = max(1, now.day);
      final daysRemaining = max(0, daysInMonth - daysPassed);

      final threeMonthsBack =
      DateTime(now.year, now.month - 3, 1);

      final snap = await FirebaseFirestore.instance
          .collection("users")
          .doc(email)
          .collection("transactions")
          .where(
        "date",
        isGreaterThanOrEqualTo:
        Timestamp.fromDate(threeMonthsBack),
      )
          .get();

      final seenIds = <String>{};
      final allTx = snap.docs
          .where((d) => seenIds.add(d.id))
          .map((d) => TransactionModel.fromMap(d.id, d.data()))
          .where((tx) => tx.senderId == uid && tx.amount > 0)
          .toList();

      if (allTx.isEmpty) {
        setState(() {
          loading = false;
          error = "No transaction history found.";
        });
        return;
      }

      // ---------------- AGGREGATION ----------------
      List<double> monthTotals = [0, 0, 0, 0];
      Map<String, List<double>> categoryMonths = {};
      Map<DateTime, double> dailyDiscretionary = {};
      dailySpending.clear();

      double fixedSpent = 0;
      double discretionarySpent = 0;

      for (final tx in allTx) {
        final d = tx.date;
        final diffMonths =
            (now.year - d.year) * 12 + (now.month - d.month);

        if (diffMonths < 0 || diffMonths > 3) continue;

        final cat = tx.category ?? "Others";
        monthTotals[diffMonths] += tx.amount;

        categoryMonths.putIfAbsent(cat, () => [0, 0, 0, 0]);
        categoryMonths[cat]![diffMonths] += tx.amount;

        if (diffMonths == 0) {
          final dayKey = DateTime(d.year, d.month, d.day);
          dailySpending[dayKey] =
              (dailySpending[dayKey] ?? 0) + tx.amount;

          if (fixedCategories.contains(cat)) {
            fixedSpent += tx.amount;
          } else {
            discretionarySpent += tx.amount;
            dailyDiscretionary[dayKey] =
                (dailyDiscretionary[dayKey] ?? 0) + tx.amount;
          }
        }
      }

      // ---------------- HISTORICAL BASELINE ----------------
      currentMonthSpent = monthTotals[0];

      final historicalAvg =
      (monthTotals[1] > 0 && monthTotals[2] > 0)
          ? (monthTotals[1] * 0.7 +
          monthTotals[2] * 0.3)
          : (monthTotals[1] > 0
          ? monthTotals[1]
          : (monthTotals[2] > 0
          ? monthTotals[2]
          : currentMonthSpent));

      // ---------------- FORECAST ----------------
      final totalDiscretionary =
      dailyDiscretionary.values.fold(0.0, (a, b) => a + b);

      final avgDailyDiscretionary =
          totalDiscretionary / daysPassed;

      final futureDiscretionary =
          avgDailyDiscretionary *
              daysRemaining *
              (daysPassed > 20 ? 0.6 : 0.9);

      final predictedTotal =
          fixedSpent + discretionarySpent + futureDiscretionary;

      forecastTotal = max(currentMonthSpent, predictedTotal);

// 🔥 THIS IS THE KEY VALUE UI NEEDS
      final forecastRemaining =
      max(0, forecastTotal - currentMonthSpent);

      // ---------------- OVERSHOOT ----------------
      overshootPercent =
      (historicalAvg > 0 && forecastTotal > historicalAvg)
          ? ((forecastTotal - historicalAvg) /
          historicalAvg *
          100)
          .clamp(0, 999)
          : 0;

      // UI treats usualMonthAvg as TOTAL MONTH TARGET
      // So it MUST equal forecastTotal — no inflation
      usualMonthAvg = forecastTotal;



      todaySpent = dailySpending[
      DateTime(now.year, now.month, now.day)] ??
          0;

      // ---------------- CATEGORY INSIGHTS ----------------
      final List<CategoryInsight> localInsights = [];

      categoryMonths.forEach((cat, vals) {
        final current = vals[0];
        final lastMonth = vals[1];

        final expectedSoFar =
        lastMonth > 0 ? (lastMonth / 30) * daysPassed : 0;

        final trend =
        lastMonth > 0
            ? ((current - expectedSoFar) /
            lastMonth *
            100)
            .clamp(-99, 999)
            : 0;

        // ---- Category Forecast ----
        final catForecast =
            current +
                ((current / daysPassed) *
                    daysRemaining *
                    0.5);

        // ---- SMART BUDGET (FIXED) ----
        final base = lastMonth > 0 ? lastMonth : catForecast;

        final smartBudget = (base *
            (catForecast > base ? 1.1 : 0.9))
            .clamp(base * 0.85, base * 1.25);

        String msg;

        if (fixedCategories.contains(cat)) {
          msg = "🔒 $cat is a fixed expense. You're on track.";
        } else if (current > expectedSoFar * 1.4) {
          msg =
          "🚨 You’re spending faster than usual on $cat this month.";
        } else if (current < expectedSoFar * 0.7 &&
            current > 0) {
          msg =
          "✨ You’re managing $cat much better than previous months.";
        } else if (current == 0) {
          msg =
          "💤 No $cat expenses yet. A great month for your savings so far!";
        } else {
          msg =
          "⚖️ $cat spending is consistent with your historical pattern.";
        }

        localInsights.add(CategoryInsight(
          category: cat,
          currentSoFar: current,
          forecastMonthTotal: catForecast,
          prevMonthTotal: lastMonth,
          olderMonthTotal: vals[2],
          smartBudget: smartBudget,
          trendPercent: trend.toDouble(),
          message: msg,
        ));
      });

      localInsights.sort(
              (a, b) => b.currentSoFar.compareTo(a.currentSoFar));

      setState(() {
        insights = localInsights;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = "AI Analysis Error: $e";
      });
    }
  }

  // ===================== UI ==========================
  // ⬇️ EVERYTHING BELOW THIS LINE IS IDENTICAL TO YOUR ORIGINAL UI


  // ===================== UI ==========================

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "AI Insights",
          style: TextStyle(
            color: scheme.onBackground,
            fontWeight: FontWeight.w700,
            fontSize: 18.sp,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _runInsights,
            tooltip: "Recalculate insights",
          )
        ],
      ),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : error != null
            ? Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Text(
              error!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: scheme.error,
                fontSize: 15.sp,
              ),
            ),
          ),
        )
            : _buildContent(scheme),
      ),
    );
  }

  Widget _buildContent(ColorScheme scheme) {
    return AnimatedOpacity(
      duration: const Duration(milliseconds: 400),
      opacity: 1,
      child: SingleChildScrollView(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildForecastCard(scheme),
            SizedBox(height: 16.h),
            _buildDailyLimitCard(scheme),
            SizedBox(height: 16.h),
            _buildHeatmapCard(scheme),
            SizedBox(height: 20.h),
            Text(
              "🔮 Category Insights (This Month)",
              style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  color: scheme.onBackground),
            ),
            SizedBox(height: 10.h),
            ...insights.map((c) => _buildInsightCard(c, scheme)),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  // ---------------- Forecast Card --------------------

  Widget _buildForecastCard(ColorScheme scheme) {
    final total = forecastTotal;
    final spent = currentMonthSpent;
    final pct = total > 0 ? (spent / total).clamp(0.0, 1.0) : 0.0;
    final pctText =
    total > 0 ? ((spent / total) * 100).clamp(0, 999).toStringAsFixed(1) : "0";

    String warningText;
    Color warningColor;

    if (overshootPercent > 25) {
      warningText =
      "🚨 You’re overshooting by ~${overshootPercent.toStringAsFixed(1)}% compared to your usual month.";
      warningColor = Colors.redAccent;
    } else if (overshootPercent > 10) {
      warningText =
      "⚠ You might overshoot your usual spending by ~${overshootPercent.toStringAsFixed(1)}%.";
      warningColor = Colors.orange.shade700;
    } else {
      warningText = "✅ You’re broadly on track compared to your usual spending.";
      warningColor = Colors.green.shade700;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade400, Colors.deepPurple.shade700],
        ),
        borderRadius: BorderRadius.circular(20.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "This Month Forecast",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            "₹${total.toStringAsFixed(0)}",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            "Spent so far: ₹${spent.toStringAsFixed(0)} • $pctText% of forecast",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 12.5.sp,
            ),
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7.h,
              backgroundColor: Colors.white12,
              valueColor:
              AlwaysStoppedAnimation<Color>(Colors.greenAccent.shade200),
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            warningText,
            style: TextStyle(
              color: warningColor,
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // --------------- Daily Limit Card ------------------

  Widget _buildDailyLimitCard(ColorScheme scheme) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    final daysPassed = now.day;

    // If we want to stay around usualMonthAvg, what's per-day?
    final targetBudget = usualMonthAvg > 0 ? usualMonthAvg : forecastTotal;
    final dailyLimit =
    daysInMonth > 0 ? (targetBudget / daysInMonth) : targetBudget;

    final today = todaySpent;
    final remainingDays = max(1, daysInMonth - daysPassed);
    final remainingBudget = max(0, targetBudget - currentMonthSpent);
    final newDailyLimit =
    remainingDays > 0 ? remainingBudget / remainingDays : 0;

    String statusText;
    Color statusColor;

    if (today > dailyLimit * 1.4) {
      statusText =
      "Today you spent significantly above your suggested daily limit.";
      statusColor = Colors.redAccent;
    } else if (today > dailyLimit * 1.1) {
      statusText = "Today you slightly exceeded your suggested daily limit.";
      statusColor = Colors.orange.shade700;
    } else if (today == 0) {
      statusText = "No spending recorded yet today. Good opportunity to save.";
      statusColor = Colors.blueGrey;
    } else {
      statusText = "Nice! You're within today’s suggested daily spending.";
      statusColor = Colors.green.shade700;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: scheme.onBackground.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Daily Spend Guidance",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 6.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _limitTile(
                "Suggested daily limit",
                "₹${dailyLimit.toStringAsFixed(0)}",
                scheme.onSurface,
              ),
              _limitTile(
                "Today’s spending",
                "₹${today.toStringAsFixed(0)}",
                today > dailyLimit ? Colors.redAccent : Colors.green.shade700,
              ),
            ],
          ),
          SizedBox(height: 8.h),
          Text(
            "To stay near your usual month, try to keep next days around ₹${newDailyLimit.toStringAsFixed(0)}/day.",
            style: TextStyle(
              fontSize: 12.sp,
              color: scheme.onSurface.withOpacity(0.8),
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _limitTile(String label, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style:
          TextStyle(fontSize: 11.sp, color: Colors.grey.withOpacity(0.9)),
        ),
        SizedBox(height: 2.h),
        Text(
          value,
          style: TextStyle(
            fontSize: 15.sp,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }

  // ---------------- Calendar Heatmap -----------------

  Widget _buildHeatmapCard(ColorScheme scheme) {
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;

    if (dailySpending.isEmpty) {
      return Container(
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Text(
          "No spending recorded this month yet.\nAs you spend, this calendar will light up day by day.",
          style: TextStyle(
            color: scheme.onSurface.withOpacity(0.8),
            fontSize: 12.5.sp,
          ),
        ),
      );
    }

    final maxDaily = dailySpending.values.fold<double>(
        0, (prev, v) => v > prev ? v : prev);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: scheme.onBackground.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Monthly Spend Heatmap",
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w700,
              color: scheme.onSurface,
            ),
          ),
          SizedBox(height: 8.h),
          Wrap(
            spacing: 6.w,
            runSpacing: 7.h,
            children: List.generate(daysInMonth, (index) {
              final day = index + 1;
              final date = DateTime(now.year, now.month, day);
              final spent = dailySpending[date] ?? 0;

              double intensity =
              maxDaily > 0 ? (spent / maxDaily).clamp(0.0, 1.0) : 0.0;
              final bgColor = Color.lerp(
                scheme.surface,
                Colors.green.shade600,
                intensity,
              )!;

              final isToday =
                  date.year == now.year &&
                      date.month == now.month &&
                      date.day == now.day;

              return Tooltip(
                message: "Day $day: ₹${spent.toStringAsFixed(0)}",
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: 22.w,
                  height: 22.w,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(5.r),
                    border: isToday
                        ? Border.all(
                      color: Colors.blueAccent,
                      width: 1.5,
                    )
                        : null,
                  ),
                  child: Center(
                    child: Text(
                      "$day",
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: intensity > 0.5
                            ? Colors.white
                            : scheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          SizedBox(height: 8.h),
          Text(
            "Darker boxes indicate higher spending days.",
            style: TextStyle(
              fontSize: 11.sp,
              color: scheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Category Insight Card ------------

  Widget _buildInsightCard(CategoryInsight c, ColorScheme scheme) {
    final trendColor =
    c.trendPercent >= 0 ? Colors.redAccent : Colors.green.shade700;
    final trendIcon =
    c.trendPercent >= 0 ? Icons.arrow_upward : Icons.arrow_downward;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: EdgeInsets.only(bottom: 12.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: scheme.onBackground.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                c.category,
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w700,
                  color: scheme.onSurface,
                ),
              ),
              Row(
                children: [
                  Icon(trendIcon, color: trendColor, size: 18.sp),
                  SizedBox(width: 4.w),
                  Text(
                    "${c.trendPercent.toStringAsFixed(1)}%",
                    style: TextStyle(
                      color: trendColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12.5.sp,
                    ),
                  ),
                ],
              ),
            ],
          ),
          SizedBox(height: 6.h),
          Text(
            c.message,
            style: TextStyle(
              color: scheme.onSurface.withOpacity(0.9),
              fontSize: 12.5.sp,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 8.w,
            runSpacing: 6.h,
            children: [
              _chip(
                "Current month (so far): ₹${c.currentSoFar.toStringAsFixed(0)}",
                scheme,
                Colors.green.shade100,
                Colors.green.shade700,
              ),
              _chip(
                "Predicted month: ₹${c.forecastMonthTotal.toStringAsFixed(0)}",
                scheme,
                Colors.blue.shade100,
                Colors.blue.shade700,
              ),
              _chip(
                "Last month: ₹${c.prevMonthTotal.toStringAsFixed(0)}",
                scheme,
                Colors.orange.shade100,
                Colors.orange.shade900,
              ),
              _chip(
                "Smart budget: ₹${c.smartBudget.toStringAsFixed(0)}",
                scheme,
                Colors.purple.shade100,
                Colors.purple.shade700,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(
      String text,
      ColorScheme scheme,
      Color bg,
      Color fg,
      ) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11.5.sp,
          fontWeight: FontWeight.w600,
          color: fg,
        ),
      ),
    );
  }
}

// ================== Model ==================

class CategoryInsight {
  final String category;
  final double currentSoFar;
  final double forecastMonthTotal;
  final double prevMonthTotal;
  final double olderMonthTotal;
  final double smartBudget;
  final double trendPercent;
  final String message;

  CategoryInsight({
    required this.category,
    required this.currentSoFar,
    required this.forecastMonthTotal,
    required this.prevMonthTotal,
    required this.olderMonthTotal,
    required this.smartBudget,
    required this.trendPercent,
    required this.message,
  });
}
