import 'package:flutter/animation.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:money_control/Screens/analytics.dart';
import 'package:money_control/Screens/homescreen.dart';
import 'package:money_control/Screens/settings.dart';
import 'package:money_control/Screens/transaction_details.dart';

Curve curve = Curves.easeOutCubic;
Transition transition = Transition.cupertino;
Duration duration = const Duration(milliseconds: 300);


void gotoScreen(int index, int currentInd) {
  switch (index) {
    case 0:
      index == currentInd ? null : Get.offAll(() => const BankingHomeScreen(), curve: curve, transition: transition, duration: duration);
      break;
    case 1:
      index == currentInd ? null : Get.to(() => const AnalyticsScreen(), curve: curve, transition: transition, duration: duration);
      break;
    case 2:
      index == currentInd ? null : Get.to(() => const SettingsScreen(), curve: curve, transition: transition, duration: duration);
      break;
  }
}

void gotoPage(Widget page){
  debugPrint("gotoPage");
  Get.to(() => page, curve: curve, transition: transition, duration: duration);
  debugPrint(Get.previousRoute);
}

void goBack(){
  Get.back();
}

TransactionResultType getTransactionTypeFromStatus(String? status) {
  switch (status?.toLowerCase()) {
    case 'success':
    case 'completed':
    case 'paid':
      return TransactionResultType.success;
    case 'pending':
    case 'in_progress':
    case 'processing':
      return TransactionResultType.inProgress;
    case 'failed':
    case 'declined':
    case 'cancelled':
      return TransactionResultType.failed;
    default:
      return TransactionResultType.inProgress;
  }
}
