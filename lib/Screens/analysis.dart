import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
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
  List<CategoryInsight> categoryInsights = [];

  @override
  void initState() {
    super.initState();
    _runInsights();
  }

  // =====================================================
  // 🔥 MAIN AI INSIGHT ENGINE
  // =====================================================
  Future<void> _runInsights() async {
    setState(() {
      loading = true;
      error = null;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        loading = false;
        error = "Not logged in.";
      });
      return;
    }

    try {
      DateTime now = DateTime.now();

      // Last 3 months (Correct order: current, previous, older)
      final months = List.generate(
        3,
            (i) => DateTime(now.year, now.month - i, 1),
      );

      final monthRanges = List.generate(
        3,
            (i) => (
        start: months[i],
        end: DateTime(months[i].year, months[i].month + 1, 1)
            .subtract(const Duration(seconds: 1)),
        ),
      );

      Map<String, List<double>> categoryData = {};
      List<double> monthlyTotals = [];

      // =====================================================
      // 🔍 READ LAST 3 MONTHS OF TRANSACTIONS
      // =====================================================
      for (int i = 0; i < 3; i++) {
        var range = monthRanges[i];

        final snap = await FirebaseFirestore.instance
            .collection("users")
            .doc(user.email)
            .collection("transactions")
            .where("date", isGreaterThanOrEqualTo: Timestamp.fromDate(range.start))
            .where("date", isLessThanOrEqualTo: Timestamp.fromDate(range.end))
            .get();

        double total = 0;
        Map<String, double> localCat = {};

        for (var doc in snap.docs) {
          final tx = TransactionModel.fromMap(doc.id, doc.data());
          if (tx.senderId == user.uid && tx.amount > 0) {
            total += tx.amount;
            localCat[tx.category ?? "Others"] =
                (localCat[tx.category ?? "Others"] ?? 0) + tx.amount;
          }
        }

        monthlyTotals.add(total);

        localCat.forEach((cat, val) {
          categoryData.putIfAbsent(cat, () => [0.0, 0.0, 0.0]);
          categoryData[cat]![i] = val;
        });
      }

      // =====================================================
      // 🩹 FIX: BACKFILL MISSING MONTH VALUES
      // e.g., [500, 0, 0] → [500, 500, 500]
      // =====================================================
      categoryData.forEach((cat, vals) {
        for (int i = 1; i < 3; i++) {
          if (vals[i] == 0 && vals[i - 1] != 0) {
            vals[i] = vals[i - 1]; // copy last known value
          }
        }
      });

      // =====================================================
      // 🔮 FORECAST USING EXPONENTIAL SMOOTHING
      // =====================================================
      double w0 = 0.6, w1 = 0.3, w2 = 0.1;
      forecastTotal =
          (monthlyTotals[0] * w0 + monthlyTotals[1] * w1 + monthlyTotals[2] * w2)
              .clamp(0, double.infinity);

      // =====================================================
      // 🤖 CREATE CATEGORY AI INSIGHTS
      // =====================================================
      categoryInsights = categoryData.entries.map((e) {
        double c0 = e.value[0]; // current
        double c1 = e.value[1]; // previous
        double c2 = e.value[2]; // older

        // Trend across 3 months
        double slope = (c0 - c2) / 2;
        double trend = slope / (c1 == 0 ? 1 : c1);

        double base = c0 * 0.5 + c1 * 0.3 + c2 * 0.2;
        double smartBudget = base;

        String message = "";

        if (trend > 0.25) {
          smartBudget = base * 0.9;
          message =
          "📈 Your spending in ${e.key} is rising. Try reducing next month's budget by ~10%.";
        } else if (trend < -0.25) {
          smartBudget = base * 1.1;
          message =
          "📉 You're improving in ${e.key}! Spending is dropping. A little more flexibility (+10%) is fine.";
        } else {
          message =
          "⚖️ ${e.key} spending is stable. Maintain the current budget balance.";
        }

        return CategoryInsight(
          category: e.key,
          current: c0,
          prev: c1,
          older: c2,
          smartBudget: smartBudget,
          message: message,
        );
      }).toList();

      setState(() => loading = false);
    } catch (e) {
      setState(() {
        loading = false;
        error = "Failed to load insights: $e";
      });
    }
  }

  // =====================================================
  // UI
  // =====================================================
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "AI Insights & Suggestions",
          style: TextStyle(
              color: scheme.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp),
        ),
        centerTitle: true,
        leading: BackButton(color: scheme.onBackground),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(
        child: Text(error!,
            style: TextStyle(color: scheme.error)),
      )
          : SingleChildScrollView(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "💡 Forecast for Next Month",
              style: TextStyle(
                  fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 6.h),
            Text(
              "Expected Spend: ₹${forecastTotal.toStringAsFixed(0)}",
              style: TextStyle(
                  fontSize: 18.sp,
                  color: Colors.orange,
                  fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 20.h),

            Text(
              "🔮 Smart Budget Suggestions",
              style: TextStyle(
                  fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 8.h),

            ...categoryInsights.map(
                  (insight) => Card(
                margin: EdgeInsets.only(bottom: 12.h),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15.r)),
                elevation: 1,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                      vertical: 14.h, horizontal: 18.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(insight.category,
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15.sp)),
                      SizedBox(height: 4.h),

                      Text(
                        "Suggested Budget: ₹${insight.smartBudget.toStringAsFixed(0)}",
                        style: TextStyle(
                            color: Colors.blueAccent,
                            fontSize: 15.sp),
                      ),

                      SizedBox(height: 10.h),

                      Text(
                        insight.message,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.deepPurple,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      SizedBox(height: 10.h),

                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _insightTag(
                              "Current: ₹${insight.current.toStringAsFixed(0)}",
                              Colors.green.shade100,
                              Colors.green,
                            ),
                            SizedBox(width: 10.w),
                            _insightTag(
                              "Previous: ₹${insight.prev.toStringAsFixed(0)}",
                              Colors.amber.shade100,
                              Colors.amber.shade800,
                            ),
                            SizedBox(width: 10.w),
                            _insightTag(
                              "Older: ₹${insight.older.toStringAsFixed(0)}",
                              Colors.grey.shade200,
                              Colors.grey.shade700,
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _insightTag(String text, Color bg, Color fg) => Container(
    padding: EdgeInsets.symmetric(vertical: 3.h, horizontal: 7.w),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(7.r),
    ),
    child: Text(
      text,
      style: TextStyle(
          color: fg, fontSize: 12.sp, fontWeight: FontWeight.w500),
    ),
  );
}

// =====================================================
// CATEGORY MODEL
// =====================================================
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
