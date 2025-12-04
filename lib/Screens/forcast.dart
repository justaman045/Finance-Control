import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Models/transaction.dart';

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

  static const int movingAvgDays = 7;

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
      final endOfMonth =
      DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
      final daysInMonth = endOfMonth.day;

      // FETCH month transactions
      final snapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfMonth))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfMonth))
          .get();

      Map<String, double> dailyIncome = {};
      Map<String, double> dailyExpense = {};

      for (var doc in snapshot.docs) {
        final tx = TransactionModel.fromMap(
          doc.id,
          doc.data(),
        );

        final txDateStr = DateFormat('yyyy-MM-dd').format(tx.date);

        if (tx.recipientId == user.uid && tx.amount > 0) {
          dailyIncome[txDateStr] = (dailyIncome[txDateStr] ?? 0) + tx.amount.abs();
        } else if (tx.senderId == user.uid && tx.amount > 0) {
          dailyExpense[txDateStr] = (dailyExpense[txDateStr] ?? 0) + tx.amount.abs();
        }
      }

      // SUM totals till today
      incomeSoFar = dailyIncome.values.fold(0, (a, b) => a + b);
      expenseSoFar = dailyExpense.values.fold(0, (a, b) => a + b);

      // --- COMPUTE 7-DAY MOVING AVERAGE ----
      List<String> lastDates = _lastNDates(movingAvgDays, now);

      double income7 = 0, expense7 = 0;
      int incomeDays = 0, expenseDays = 0;

      for (String d in lastDates) {
        if (dailyIncome.containsKey(d)) {
          income7 += dailyIncome[d]!;
          incomeDays++;
        }
        if (dailyExpense.containsKey(d)) {
          expense7 += dailyExpense[d]!;
          expenseDays++;
        }
      }

      double avgIncome = incomeDays == 0 ? 0 : income7 / incomeDays;
      double avgExpense = expenseDays == 0 ? 0 : expense7 / expenseDays;

      int daysSoFar = now.day;
      int daysLeft = daysInMonth - daysSoFar;

      // FORECAST (moving-average based)
      forecastIncome = (avgIncome * daysLeft).clamp(0, double.infinity);
      forecastExpense = (avgExpense * daysLeft).clamp(0, double.infinity);

      setState(() => loading = false);
    } catch (e) {
      debugPrint("Forecast error: $e");
      setState(() => loading = false);
    }
  }

  // Last N days including today
  List<String> _lastNDates(int n, DateTime today) {
    List<String> dates = [];
    for (int i = n - 1; i >= 0; i--) {
      final d = today.subtract(Duration(days: i));
      dates.add(DateFormat('yyyy-MM-dd').format(d));
    }
    return dates;
  }

  String _formatIndianCurrency(double amount) {
    final formatter =
    NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 2);
    return formatter.format(amount);
  }

  String _monthName(int monthNum) {
    const months = [
      "January","February","March","April","May","June",
      "July","August","September","October","November","December"
    ];
    return months[monthNum - 1];
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isLight = scheme.brightness == Brightness.light;
    final gradientTop = isLight ? kLightGradientTop : kDarkGradientTop;
    final gradientBottom = isLight ? kLightGradientBottom : kDarkGradientBottom;

    DateTime now = DateTime.now();
    String currentMonthYear = "${_monthName(now.month)} ${now.year}";

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
          centerTitle: true,
          elevation: 0,
          title: Text(
            "Monthly Forecast",
            style: TextStyle(
              color: scheme.onBackground,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: scheme.onBackground),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SafeArea(
          child: loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
            padding: EdgeInsets.symmetric(horizontal: 18.w, vertical: 20.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  currentMonthYear,
                  style: TextStyle(
                    fontSize: 22.sp,
                    fontWeight: FontWeight.bold,
                    color: scheme.onBackground,
                  ),
                ),
                SizedBox(height: 20.h),

                // ------ Income Cards ------
                _ForecastCard(
                  label: "Income So Far",
                  amount: incomeSoFar,
                  color: Colors.green,
                  formattedAmount: _formatIndianCurrency(incomeSoFar),
                ),
                SizedBox(height: 12.h),
                _ForecastCard(
                  label: "Forecasted Income",
                  amount: forecastIncome,
                  color: Colors.green.shade300,
                  formattedAmount: _formatIndianCurrency(forecastIncome),
                ),

                SizedBox(height: 20.h),

                // ------ Expense Cards ------
                _ForecastCard(
                  label: "Expenses So Far",
                  amount: expenseSoFar,
                  color: Colors.red,
                  formattedAmount: _formatIndianCurrency(expenseSoFar),
                ),
                SizedBox(height: 12.h),
                _ForecastCard(
                  label: "Forecasted Expenses",
                  amount: forecastExpense,
                  color: Colors.red.shade300,
                  formattedAmount: _formatIndianCurrency(forecastExpense),
                ),

                const Spacer(),

                Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      minimumSize: Size(double.infinity, 52.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30.r),
                      ),
                    ),
                    child: Text(
                      "Back",
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ForecastCard extends StatelessWidget {
  final String label;
  final double amount;
  final Color color;
  final String formattedAmount;

  const _ForecastCard({
    required this.label,
    required this.amount,
    required this.color,
    required this.formattedAmount,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 22.h, horizontal: 24.w),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: scheme.onBackground.withOpacity(0.07),
            blurRadius: 18.r,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            formattedAmount,
            style: TextStyle(
              fontSize: 19.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
