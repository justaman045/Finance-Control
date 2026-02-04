import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:money_control/Models/transaction.dart';

class AnalyticsController extends GetxController {
  final RxBool isLoading = true.obs;
  final RxDouble incomeSoFar = 0.0.obs;
  final RxDouble expenseSoFar = 0.0.obs;
  final RxDouble forecastIncome = 0.0.obs;
  final RxDouble forecastExpense = 0.0.obs;

  @override
  void onInit() {
    super.onInit();
    loadMonthTransactions();
  }

  Future<void> loadMonthTransactions() async {
    isLoading.value = true;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      isLoading.value = false;
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
      incomeSoFar.value = dailyIncome.values.fold(0, (a, b) => a + b);
      expenseSoFar.value = dailyExpense.values.fold(0, (a, b) => a + b);

      // --- HISTORY FETCH (Last 3 Months) ---
      final startOfHistory = DateTime(now.year, now.month - 3, 1);

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
      final safeHistoryDays = daysInHistory > 0 ? daysInHistory : 1;

      final double historicalDailyIncome =
          historicalIncomeSum / safeHistoryDays;
      final double historicalDailyExpense =
          historicalExpenseSum / safeHistoryDays;

      // 2. Calculate Current Month Daily Avg (So Far)
      int daysPassed = now.day;
      if (daysPassed < 1) daysPassed = 1;

      final double currentDailyIncome = incomeSoFar.value / daysPassed;
      final double currentDailyExpense = expenseSoFar.value / daysPassed;

      // 3. Blend Logic
      double projectedDailyIncome;
      double projectedDailyExpense;

      if (historySnap.docs.isNotEmpty) {
        // We have history. Blend 50/50.
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

      forecastIncome.value = (projectedDailyIncome * daysLeft).clamp(
        0,
        double.infinity,
      );
      forecastExpense.value = (projectedDailyExpense * daysLeft).clamp(
        0,
        double.infinity,
      );

      isLoading.value = false;
    } catch (e) {
      debugPrint("Forecast error: $e");
      isLoading.value = false;
    }
  }
}
