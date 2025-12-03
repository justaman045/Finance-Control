import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Models/transaction.dart';
import 'dart:math';

class AIInsightsScreen extends StatefulWidget {
  const AIInsightsScreen({super.key});

  @override
  State<AIInsightsScreen> createState() => _AIInsightsScreenState();
}

class _AIInsightsScreenState extends State<AIInsightsScreen> {
  bool loading = true;
  String? error;

  double forecastTotal = 0;
  List<CategoryInsight> categoryInsights = [];

  @override
  void initState() {
    super.initState();
    _runInsights();
  }

  Future<void> _runInsights() async {
    setState(() {
      loading = true;
      error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        loading = false;
        error = "You are not logged in";
      });
      return;
    }

    try {
      DateTime now = DateTime.now();

      /// LAST 3 MONTH PERIODS
      final months = List.generate(3, (i) {
        return DateTime(now.year, now.month - i, 1);
      });

      final monthRanges = months.map((m) {
        return (
        start: m,
        end: DateTime(m.year, m.month + 1, 1)
            .subtract(const Duration(seconds: 1))
        );
      }).toList();

      Map<String, List<double>> categoryData = {};
      List<double> monthlyTotals = [];

      ///
      /// READ SPENDING
      ///
      for (int i = 0; i < 3; i++) {
        var range = monthRanges[i];
        double total = 0;
        Map<String, double> localCategories = {};

        final snap = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.email)
            .collection("transactions")
            .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
            .where("date", isLessThanOrEqualTo: Timestamp.fromDate(range.end))
            .get();

        for (var doc in snap.docs) {
          final tx = TransactionModel.fromMap(doc.id, doc.data());

          if (tx.senderId == user.uid && tx.amount > 0) {
            total += tx.amount;
            localCategories[tx.category ?? "Others"] =
                (localCategories[tx.category ?? "Others"] ?? 0) + tx.amount;
          }
        }

        monthlyTotals.add(total);

        /// fill category monthly data
        localCategories.forEach((cat, value) {
          categoryData.putIfAbsent(cat, () => [0.0, 0.0, 0.0]);
          categoryData[cat]![i] = value;
        });
      }

      /// fix missing values
      categoryData.forEach((cat, vals) {
        for (int i = 1; i < 3; i++) {
          if (vals[i] == 0 && vals[i - 1] != 0) vals[i] = vals[i - 1];
        }
      });

      ///
      /// FORECASTING
      ///
      forecastTotal = _forecast(monthlyTotals);

      ///
      /// AI CATEGORY INSIGHTS
      ///
      List<CategoryInsight> insights = [];

      categoryData.forEach((cat, values) {
        double c0 = values[0];
        double c1 = values[1];
        double c2 = values[2];

        /// linear slope (trend)
        double slope = (c0 - c2) / 2;
        double trendPercent = (slope / max(1, c1));

        /// anomaly detection
        bool spiked = (c0 > (c1 * 1.35));

        /// smart budget
        double baseBudget = (c0 * 0.6 + c1 * 0.3 + c2 * 0.1);

        String message = "";
        if (spiked) {
          message =
          "🚨 Sudden spike detected in $cat spending. You spent more than 35% compared to last month.";
        } else if (trendPercent > 0.2) {
          message =
          "📈 Your spending in $cat is rising. Reducing next month’s budget by ~15% is recommended.";
        } else if (trendPercent < -0.25) {
          message =
          "📉 You're improving in $cat! Spending is dropping. You can safely increase budget by 10%.";
        } else {
          message =
          "⚖️ Your $cat spending is stable. Keep maintaining your current habits.";
        }

        insights.add(CategoryInsight(
          category: cat,
          current: c0,
          prev: c1,
          older: c2,
          smartBudget: baseBudget,
          message: message,
        ));
      });

      insights.sort((a, b) => b.current.compareTo(a.current));

      setState(() {
        categoryInsights = insights;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
        error = "AI error: $e";
      });
    }
  }

  /// Weighted exponential forecast with seasonal adjustment
  double _forecast(List<double> values) {
    if (values.isEmpty) return 0;
    if (values.length == 1) return values.first;

    double w0 = 0.6, w1 = 0.3, w2 = 0.1;
    double forecast =
    (values[0] * w0 + values[1] * w1 + values[2] * w2).clamp(0, double.infinity);

    return forecast;
  }

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
              fontSize: 18.sp),
        ),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
          child: Text(
            error!,
            style: TextStyle(color: scheme.error),
          ))
          : _buildContent(scheme),
      bottomNavigationBar: const BottomNavBar(currentIndex: 2),
    );
  }

  Widget _buildContent(ColorScheme scheme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(14.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("💡 Forecast for Next Month",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 4.h),
          Text(
            "Expected Spend: ₹${forecastTotal.toStringAsFixed(0)}",
            style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.orange),
          ),

          SizedBox(height: 18.h),
          Text("🔮 Smart Budget Suggestions",
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold)),
          SizedBox(height: 12.h),

          ...categoryInsights.map((insight) => _buildInsightCard(insight)),
        ],
      ),
    );
  }

  Widget _buildInsightCard(CategoryInsight insight) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14.r)),
      elevation: 2,
      margin: EdgeInsets.only(bottom: 12.h),
      child: Padding(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(insight.category,
                style:
                TextStyle(fontSize: 15.sp, fontWeight: FontWeight.w700)),
            SizedBox(height: 4.h),

            Text("Suggested Budget: ₹${insight.smartBudget.toStringAsFixed(0)}",
                style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.blue.shade700,
                    fontWeight: FontWeight.w600)),

            SizedBox(height: 10.h),
            Text(insight.message,
                style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.deepPurple,
                    fontWeight: FontWeight.w500)),

            SizedBox(height: 12.h),
            _spendingTags(insight),
          ],
        ),
      ),
    );
  }

  Widget _spendingTags(CategoryInsight i) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _tag("Current: ₹${i.current.toStringAsFixed(0)}",
              Colors.green.shade100, Colors.green),
          SizedBox(width: 10.w),
          _tag("Previous: ₹${i.prev.toStringAsFixed(0)}",
              Colors.orange.shade100, Colors.orange.shade900),
          SizedBox(width: 10.w),
          _tag("Older: ₹${i.older.toStringAsFixed(0)}",
              Colors.grey.shade200, Colors.grey.shade700),
        ],
      ),
    );
  }

  Widget _tag(String text, Color bg, Color fg) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 7.w),
      decoration:
      BoxDecoration(color: bg, borderRadius: BorderRadius.circular(7.r)),
      child: Text(text,
          style: TextStyle(
              color: fg, fontSize: 12.sp, fontWeight: FontWeight.w500)),
    );
  }
}

class CategoryInsight {
  final String category;
  final double current;
  final double prev;
  final double older;
  final double smartBudget;
  final String message;

  CategoryInsight({
    required this.category,
    required this.current,
    required this.prev,
    required this.older,
    required this.smartBudget,
    required this.message,
  });
}
