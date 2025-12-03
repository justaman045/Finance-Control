import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money_control/Screens/analysis.dart';

import 'package:money_control/Screens/homescreen.dart';
import 'package:money_control/Screens/analytics.dart';
import 'package:money_control/Screens/settings.dart';
import 'package:money_control/Screens/transaction_details.dart';

Curve curve = Curves.easeOutCubic;
Transition transition = Transition.cupertino;
Duration duration = const Duration(milliseconds: 250);

void gotoScreen(int index, int currentIndex) {
  if (index == currentIndex) return;

  switch (index) {
    case 0:
      Get.offAll(() => const BankingHomeScreen(),
          curve: curve, transition: transition, duration: duration);
      break;

    case 1:
      Get.offAll(() => const AnalyticsScreen(),
          curve: curve, transition: transition, duration: duration);
      break;

    case 2:
      Get.offAll(() => const AIInsightsScreen(),
          curve: curve, transition: transition, duration: duration);
      break;

    case 3:
      Get.offAll(() => const SettingsScreen(),
          curve: curve, transition: transition, duration: duration);
      break;
  }
}

void gotoPage(Widget page) {
  Get.to(() => page,
      curve: curve, transition: transition, duration: duration);
}

void goBack() {
  if (Get.key.currentContext != null &&
      Navigator.canPop(Get.key.currentContext!)) {
    Navigator.pop(Get.key.currentContext!);
  } else {
    Get.back();
  }
}

TransactionResultType getTransactionTypeFromStatus(String? status) { switch (status?.toLowerCase()) { case 'success': case 'completed': case 'paid': return TransactionResultType.success; case 'pending': case 'in_progress': case 'processing': return TransactionResultType.inProgress; case 'failed': case 'declined': case 'cancelled': return TransactionResultType.failed; default: return TransactionResultType.inProgress; } }
