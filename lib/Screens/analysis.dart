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
  Map<String, double> suggestedBudgets = {};
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
        error = "Not logged in.";
      });
      return;
    }

    try {
      final now = DateTime.now();

      final List<DateTime> monthStarts =
      List.generate(3, (i) => DateTime(now.year, now.month - i, 1));
      final List<DateTime> monthEnds = List.generate(
          3,
              (i) =>
              DateTime(now.year, now.month - i + 1, 1)
                  .subtract(const Duration(seconds: 1)));

      Map<String, List<double>> categoryExpenses = {};
      Map<String, List<double>> categoryIncomes = {};
      List<double> totalExpenses = [];
      List<double> totalIncomes = [];
      List<int> txnCountsPerMonth = [];

      for (int i = 0; i < 3; i++) {
        final start = monthStarts[i];
        final end = monthEnds[i];
        final txSnap = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.email)
            .collection('transactions')
            .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(start))
            .where('date', isLessThanOrEqualTo: Timestamp.fromDate(end))
            .get();

        Map<String, double> catExp = {};
        Map<String, double> catInc = {};
        double totalExp = 0;
        double totalInc = 0;

        for (var doc in txSnap.docs) {
          final tx = TransactionModel.fromMap(doc.id, doc.data());

          if (tx.senderId == user.uid && tx.amount > 0) {
            final cat = tx.category ?? 'Others';
            catExp[cat] = (catExp[cat] ?? 0) + tx.amount;
            totalExp += tx.amount;
          } else if (tx.recipientId == user.uid && tx.amount > 0) {
            final cat = tx.category ?? 'Others';
            catInc[cat] = (catInc[cat] ?? 0) + tx.amount;
            totalInc += tx.amount;
          }
        }

        txnCountsPerMonth.add(txSnap.docs.length);

        totalExpenses.add(totalExp);
        totalIncomes.add(totalInc);

        catExp.forEach((key, value) {
          categoryExpenses.putIfAbsent(key, () => List.filled(3, 0));
          categoryExpenses[key]![i] = value;
        });
        catInc.forEach((key, value) {
          categoryIncomes.putIfAbsent(key, () => List.filled(3, 0));
          categoryIncomes[key]![i] = value;
        });
      }

      double totalTxns = txnCountsPerMonth.fold(0, (a, b) => a + b).toDouble();
      List<double> weights =
      txnCountsPerMonth.map((c) => c / totalTxns).toList();

      double weightedExpense = 0;
      double weightedIncome = 0;
      for (int i = 0; i < 3; i++) {
        weightedExpense += totalExpenses[i] * weights[i];
        weightedIncome += totalIncomes[i] * weights[i];
      }

      double expenseTrend = (totalExpenses[0] - totalExpenses[1]) /
          (totalExpenses[1] != 0 ? totalExpenses[1] : 1);
      //TODO: Remove usage warning
      // double incomeTrend = (totalIncomes[0] - totalIncomes[1]) /
      //     (totalIncomes[1] != 0 ? totalIncomes[1] : 1);

      double trendFactorExp = 1 + expenseTrend.clamp(-0.2, 0.2);
      //TODO: Remove usage warning
      // double trendFactorInc = 1 + incomeTrend.clamp(-0.2, 0.2);

      forecastTotal = (weightedExpense * trendFactorExp).clamp(0, double.infinity);

      suggestedBudgets.clear();

      categoryExpenses.forEach((cat, vals) {
        double weightedVal = 0;
        for (int i = 0; i < 3; i++) {
          double val = vals[i] * weights[i];
          weightedVal += val;
        }
        weightedVal *= trendFactorExp;
        if (weightedVal > 0) suggestedBudgets[cat] = weightedVal;
      });

      categoryInsights = categoryExpenses.entries
          .map((e) => CategoryInsight(
        category: e.key,
        current: e.value[0],
        prev: e.value[1],
        older: e.value[2],
        smartBudget: suggestedBudgets[e.key] ?? 0,
      ))
          .toList();

      setState(() {
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Failed to analyze: $e";
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text("AI Insights & Suggestions",
            style: TextStyle(
                color: scheme.onBackground,
                fontWeight: FontWeight.bold,
                fontSize: 18.sp)),
        centerTitle: true,
        leading: BackButton(color: scheme.onBackground),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? Center(child: Text(error!, style: TextStyle(color: scheme.error)))
          : SingleChildScrollView(
        padding: EdgeInsets.all(14.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("💡 AI Forecast (Next Month's spend)",
                style: TextStyle(
                    fontSize: 16.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 6.h),
            Text("Expected spend: ₹${forecastTotal.toStringAsFixed(0)}",
                style: TextStyle(
                    fontSize: 18.sp,
                    color: Colors.orange,
                    fontWeight: FontWeight.bold)),
            SizedBox(height: 14.h),
            Text("🔮 Smart Budget Suggestions",
                style: TextStyle(
                    fontSize: 16.sp, fontWeight: FontWeight.w600)),
            SizedBox(height: 8.h),
            ...categoryInsights.map((insight) => Card(
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
                            fontSize: 15.sp)),
                    SizedBox(height: 2.h),
                    Row(
                      children: [
                        _insightTag(
                            "Current: ₹${insight.current.toStringAsFixed(0)}",
                            Colors.green.shade100,
                            Colors.green),
                        SizedBox(width: 10.w),
                        _insightTag(
                            "Prev: ₹${insight.prev.toStringAsFixed(0)}",
                            Colors.amber.shade600,
                            Colors.amber.shade50),
                        SizedBox(width: 10.w),
                        _insightTag(
                            "Older: ₹${insight.older.toStringAsFixed(0)}",
                            Colors.grey.shade200,
                            Colors.grey),
                      ],
                    )
                  ],
                ),
              ),
            ))
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
    child: Text(text,
        style: TextStyle(
            color: fg, fontSize: 12.sp, fontWeight: FontWeight.w500)),
  );
}

class CategoryInsight {
  final String category;
  final double current;
  final double prev;
  final double older;
  final double smartBudget;

  CategoryInsight({
    required this.category,
    required this.current,
    required this.prev,
    required this.older,
    required this.smartBudget,
  });
}
