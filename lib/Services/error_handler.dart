import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/colors.dart';

class ErrorHandler {
  static void showError(String message, {String title = "Error"}) {
    // Prevent duplicate snackbars or spam
    if (Get.isSnackbarOpen) return;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.error,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      icon: const Icon(Icons.error_outline, color: Colors.white),
      duration: const Duration(seconds: 3),
      isDismissible: true,
      dismissDirection: DismissDirection.horizontal,
      forwardAnimationCurve: Curves.easeOutBack,
    );
  }

  static void showSuccess(String message, {String title = "Success"}) {
    if (Get.isSnackbarOpen) return;

    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: AppColors.success,
      colorText: Colors.white,
      margin: const EdgeInsets.all(16),
      borderRadius: 16,
      icon: const Icon(Icons.check_circle_outline, color: Colors.white),
      duration: const Duration(seconds: 2),
    );
  }

  static void showNetworkError() {
    showError("Please check your internet connection.", title: "Network Error");
  }

  static void showSomethingWentWrong() {
    showError("Something went wrong. Please try again.", title: "Oops!");
  }
}
