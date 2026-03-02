import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:money_control/Controllers/transaction_controller.dart';

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
      final TransactionController txController = Get.find();

      // Wait for transactions to be loaded if they aren't yet
      if (txController.isLoading.value) {
        await Future.delayed(const Duration(milliseconds: 500));
        // Simple retry/wait mechanism or we could listen.
        // But usually Home loads first.
      }

      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(
        now.year,
        now.month + 1,
        1,
      ).subtract(const Duration(seconds: 1));
      final daysInMonth = DateTime(
        now.year,
        now.month + 1,
        0,
      ).day; // Correct last day

      final allTx = txController.transactions;

      // Filter Current Month
      final monthlyTx = allTx.where((tx) {
        return tx.date.isAfter(
              startOfMonth.subtract(const Duration(seconds: 1)),
            ) &&
            tx.date.isBefore(endOfMonth.add(const Duration(seconds: 1)));
      });

      Map<String, double> dailyIncome = {};
      Map<String, double> dailyExpense = {};

      for (var tx in monthlyTx) {
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

      final historyTx = allTx.where((tx) {
        return tx.date.isAfter(
              startOfHistory.subtract(const Duration(seconds: 1)),
            ) &&
            tx.date.isBefore(startOfMonth);
      });

      double historicalIncomeSum = 0;
      double historicalExpenseSum = 0;

      for (var tx in historyTx) {
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

      if (historyTx.isNotEmpty) {
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
