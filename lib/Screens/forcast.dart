import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';

import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Controllers/currency_controller.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  bool loading = true;
  double incomeSoFar = 0;
  double expenseSoFar = 0;
  double forecastIncome = 0;
  double forecastExpense = 0;

  @override
  void initState() {
    super.initState();
    _loadMonthTransactions();
  }

  Future<void> _loadMonthTransactions() async {
    setState(() => loading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => loading = false);
      return;
    }

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(
        now.year,
        now.month + 1,
        1,
      ).subtract(const Duration(seconds: 1));
      final daysInMonth = endOfMonth.day;

      // FETCH month transactions
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth),
          )
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      Map<String, double> dailyIncome = {};
      Map<String, double> dailyExpense = {};

      for (var doc in snapshot.docs) {
        final tx = TransactionModel.fromMap(doc.id, doc.data());

        final txDateStr = DateFormat('yyyy-MM-dd').format(tx.date);

        if (tx.recipientId == user.uid) {
          dailyIncome[txDateStr] =
              (dailyIncome[txDateStr] ?? 0) + tx.amount.abs();
        } else if (tx.senderId == user.uid) {
          dailyExpense[txDateStr] =
              (dailyExpense[txDateStr] ?? 0) + tx.amount.abs();
        }
      }

      // SUM totals till today
      incomeSoFar = dailyIncome.values.fold(0, (a, b) => a + b);
      expenseSoFar = dailyExpense.values.fold(0, (a, b) => a + b);

      // --- HISTORY FETCH (Last 3 Months) ---
      final startOfHistory = DateTime(now.year, now.month - 3, 1);
      // Ensure we don't go before account creation? Firestore handles empty queries fine.

      final historySnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where(
            'date',
            isGreaterThanOrEqualTo: Timestamp.fromDate(startOfHistory),
          )
          .where('date', isLessThan: Timestamp.fromDate(startOfMonth))
          .get();

      double historicalIncomeSum = 0;
      double historicalExpenseSum = 0;

      for (var doc in historySnap.docs) {
        final tx = TransactionModel.fromMap(doc.id, doc.data());
        if (tx.recipientId == user.uid) {
          historicalIncomeSum += tx.amount.abs();
        } else if (tx.senderId == user.uid) {
          historicalExpenseSum += tx.amount.abs();
        }
      }

      // --- LOGIC: Weighted Forecast ---
      // 1. Calculate Historical Daily Avg
      final daysInHistory = startOfMonth.difference(startOfHistory).inDays;
      // Safety check
      final safeHistoryDays = daysInHistory > 0 ? daysInHistory : 1;

      final double historicalDailyIncome =
          historicalIncomeSum / safeHistoryDays;
      final double historicalDailyExpense =
          historicalExpenseSum / safeHistoryDays;

      // 2. Calculate Current Month Daily Avg (So Far)
      int daysPassed = now.day;
      if (daysPassed < 1) daysPassed = 1;

      final double currentDailyIncome = incomeSoFar / daysPassed;
      final double currentDailyExpense = expenseSoFar / daysPassed;

      // 3. Blend Logic
      // If we have history, use it heavily for the "Remaining" days projection.
      // If we don't (new user), rely on current month pacing.
      // Let's use a 70% Historical / 30% Current blend for the projection,
      // OR mostly historical if available to avoid "Rent Spike" issues.

      double projectedDailyIncome;
      double projectedDailyExpense;

      if (historySnap.docs.isNotEmpty) {
        // We have history. Trust it more for the rest of the month.
        // But maybe the user got a raise? Let's blend 50/50.
        projectedDailyIncome = (historicalDailyIncome + currentDailyIncome) / 2;
        projectedDailyExpense =
            (historicalDailyExpense + currentDailyExpense) / 2;
      } else {
        // No history, purely current pacing
        projectedDailyIncome = currentDailyIncome;
        projectedDailyExpense = currentDailyExpense;
      }

      // 4. Final Projection
      final int daysLeft = daysInMonth - daysPassed;

      forecastIncome = (projectedDailyIncome * daysLeft).clamp(
        0,
        double.infinity,
      );
      forecastExpense = (projectedDailyExpense * daysLeft).clamp(
        0,
        double.infinity,
      );

      setState(() => loading = false);
    } catch (e) {
      debugPrint("Forecast error: $e");
      setState(() => loading = false);
    }
  }

  String _formatIndianCurrency(double amount) {
    final formatter = NumberFormat.currency(
      locale: 'en_IN',
      symbol: CurrencyController.to.currencySymbol.value,
      decimalDigits: 2,
    );
    return formatter.format(amount);
  }

  String _monthName(int monthNum) {
    const months = [
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December",
    ];
    return months[monthNum - 1];
  }

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    String currentMonthYear = "${_monthName(now.month)} ${now.year}";

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          "Monthly Forecast",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E), // Midnight Void Top
              const Color(0xFF16213E).withValues(alpha: 0.95), // Deep Blue Bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: loading
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
                )
              : SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20.w,
                    vertical: 20.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        currentMonthYear,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 1.2,
                        ),
                      ),
                      SizedBox(height: 30.h),

                      // ------ Income Section ------
                      _sectionHeader("INCOME", const Color(0xFF00E676)),
                      SizedBox(height: 16.h),
                      _ForecastCard(
                        label: "Income So Far",
                        amount: incomeSoFar,
                        color: const Color(0xFF00E676),
                        formattedAmount: _formatIndianCurrency(incomeSoFar),
                        icon: Icons.download_rounded,
                        isForecast: false,
                      ),
                      SizedBox(height: 12.h),
                      _ForecastCard(
                        label: "Projected Remaining",
                        amount: forecastIncome,
                        color: const Color(0xFF69F0AE),
                        formattedAmount: _formatIndianCurrency(forecastIncome),
                        icon: Icons.trending_up_rounded,
                        isForecast: true,
                      ),

                      SizedBox(height: 40.h),

                      // ------ Expense Section ------
                      _sectionHeader("EXPENSES", const Color(0xFFFF1744)),
                      SizedBox(height: 16.h),
                      _ForecastCard(
                        label: "Expenses So Far",
                        amount: expenseSoFar,
                        color: const Color(0xFFFF1744),
                        formattedAmount: _formatIndianCurrency(expenseSoFar),
                        icon: Icons.upload_rounded,
                        isForecast: false,
                      ),
                      SizedBox(height: 12.h),
                      _ForecastCard(
                        label: "Projected Remaining",
                        amount: forecastExpense,
                        color: const Color(0xFFFF5252),
                        formattedAmount: _formatIndianCurrency(forecastExpense),
                        icon: Icons.trending_down_rounded,
                        isForecast: true,
                      ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, Color color) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 16,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Text(
          title,
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            letterSpacing: 2,
          ),
        ),
        SizedBox(width: 8.w),
        Expanded(child: Container(height: 1, color: color.withValues(alpha: 0.2))),
      ],
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String formattedAmount;
  final IconData icon;
  final bool isForecast;

  const _ForecastCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.formattedAmount,
    required this.icon,
    required this.isForecast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 20.w),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05), // Dark Glass
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isForecast
              ? color.withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          width: isForecast ? 1.5 : 1,
        ),
        boxShadow: isForecast
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: -5,
                ),
              ]
            : [],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 20.sp),
              ),
              SizedBox(width: 16.w),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ],
          ),
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Always white text for premium feel
              shadows: [
                BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
