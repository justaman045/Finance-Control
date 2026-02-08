import 'package:get/get.dart';
import 'package:money_control/Models/cateogary.dart';
import 'package:money_control/Models/transaction.dart';
import 'package:money_control/Repositories/transaction_repository.dart';
import 'package:money_control/Services/budget_service.dart';
import 'package:money_control/Services/local_backup_service.dart';
import 'package:money_control/Services/offline_queue.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:money_control/Services/error_handler.dart';
import 'package:money_control/Controllers/subscription_controller.dart';
import 'package:money_control/Screens/subscription_screen.dart';

class TransactionController extends GetxController {
  final TransactionRepository _repository = TransactionRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final SubscriptionController _subscriptionController = Get.find();

  // State
  var transactions = <TransactionModel>[].obs;
  var categories = <CategoryModel>[].obs;
  var isLoading = false.obs;
  var isSaving = false.obs;

  // Sorted categories by usage
  var sortedCategoryNames = <String>[].obs;

  @override
  void onInit() {
    super.onInit();
    bindTransactions();
    bindCategories();
    // fetchSortedCategories(); // This might need to be reactive or called on change

    // Listen to changes in categories/transactions to update sorted list
    ever(categories, (_) => fetchSortedCategories());
    ever(transactions, (_) => fetchSortedCategories());
  }

  void bindTransactions() {
    transactions.bindStream(_repository.getTransactionsStream());
  }

  void bindCategories() {
    categories.bindStream(_repository.getCategoriesStream());
  }

  Future<void> fetchSortedCategories() async {
    // This now relies on the repository fetching fresh data internally
    // OR we can optimize it to use the local lists.
    // For now, let's keep using the repository method but note it does a fetch.
    sortedCategoryNames.value = await _repository
        .fetchCategoriesSortedByUsage();
  }

  // ——————————————————————————————————————
  //  Actions
  // ——————————————————————————————————————

  Future<bool> addCategory(String name) async {
    // 1. Check PRO Limit (Categories)
    if (!_subscriptionController.isPro && categories.length >= 10) {
      Get.to(() => const SubscriptionScreen());
      return false;
    }

    if (name.isEmpty) {
      ErrorHandler.showError("Category name cannot be empty");
      return false;
    }

    if (categories.any((c) => c.name.toLowerCase() == name.toLowerCase())) {
      ErrorHandler.showError("Category already exists");
      return false;
    }

    try {
      final doc = await _repository.addCategory(name);
      categories.add(CategoryModel(id: doc.id, name: name));
      sortedCategoryNames.add(name); // Ensure it appears in QuickSend
      return true;
    } catch (e) {
      _handleFirestoreError(e, "Failed to add category");
      return false;
    }
  }

  Future<bool> deleteCategory(CategoryModel category) async {
    if (categories.length <= 1) {
      ErrorHandler.showError("At least one category must exist.");
      return false;
    }

    try {
      await _repository.deleteCategory(category.id);
      categories.removeWhere((c) => c.id == category.id);
      return true;
    } catch (e) {
      _handleFirestoreError(e, "Failed to delete category");
      return false;
    }
  }

  Future<bool> saveTransaction({
    required double amount,
    required String name,
    required String note,
    required String category,
    required DateTime date,
    required String type, // 'send' or 'receive'
    required String currency,
  }) async {
    if (isSaving.value) return false;
    isSaving.value = true;

    // 2. Check PRO Limit (Transactions)
    if (!_subscriptionController.isPro) {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final txCount = transactions
          .where((t) => t.date.isAfter(startOfMonth))
          .length;

      if (txCount >= 150) {
        Get.to(() => const SubscriptionScreen());
        isSaving.value = false;
        return false;
      }
    }

    final user = _auth.currentUser;
    if (user == null) {
      isSaving.value = false;
      return false;
    }

    if (amount <= 0) {
      ErrorHandler.showError("Enter a valid amount");
      isSaving.value = false;
      return false;
    }
    if (name.isEmpty) {
      ErrorHandler.showError("Enter a valid name");
      isSaving.value = false;
      return false;
    }

    final isSend = type == 'send';
    final finalAmount = isSend ? -amount : amount;

    final tx = TransactionModel(
      id: "",
      senderId: isSend ? user.uid : "",
      recipientId: isSend ? "" : user.uid,
      recipientName: name,
      amount: finalAmount,
      currency: currency,
      tax: 0.0,
      note: note,
      category: category,
      date: date,
      status: "success",
      createdAt: Timestamp.now(),
    );

    try {
      // 1. Attempt Firestore write with timeout
      await _repository.addTransaction(tx).timeout(const Duration(seconds: 5));
    } on TimeoutException catch (e) {
      print("Firebase error: $e");
      // 2. Offline Queue Fallback
      await OfflineQueueService.savePending(tx.toMap());
      ErrorHandler.showSuccess(
        "Saved locally. Will sync later.",
        title: "Offline",
      );
    } catch (e) {
      _handleFirestoreError(e, "Failed to save transaction");
      isSaving.value = false;
      return false;
    }

    // 3. Local Backup
    if (user.email != null) {
      LocalBackupService.backupUserTransactions(user.email!);
    }

    // 4. Budget Check (Side Effect)
    if (isSend && user.email != null) {
      BudgetService.checkBudgetExceeded(
        userId: user.email!,
        category: category,
        newAmount: amount, // Positive amount for budget check
      );
    }

    // 5. Update cached sorted categories
    // (Optional: could just re-fetch or optimistically update)
    fetchSortedCategories();

    isSaving.value = false;
    return true;
  }

  Future<bool> deleteTransaction(TransactionModel tx) async {
    final user = _auth.currentUser;
    if (user == null) return false;

    try {
      await _repository
          .deleteTransaction(tx.id)
          .timeout(const Duration(seconds: 5));

      // Local Backup
      if (user.email != null) {
        LocalBackupService.backupUserTransactions(user.email!);
      }
      return true;
    } on TimeoutException {
      // Offline fallback
      final deleteJson = {
        "operation": "delete",
        "transactionId": tx.id,
        "user": user.email,
      };
      await OfflineQueueService.savePending(deleteJson);

      // Optimistic update
      transactions.removeWhere((t) => t.id == tx.id);

      ErrorHandler.showSuccess("Delete queued (Offline)", title: "Offline");
      return true;
    } catch (e) {
      _handleFirestoreError(e, "Failed to delete transaction");
      return false;
    }
  }

  void _handleFirestoreError(dynamic e, String defaultMessage) {
    if (e is FirebaseException) {
      switch (e.code) {
        case 'permission-denied':
          ErrorHandler.showError(
            "You don't have permission to perform this action.",
          );
          break;
        case 'unavailable':
          ErrorHandler.showNetworkError();
          break;
        case 'not-found':
          ErrorHandler.showError("The requested item was not found.");
          break;
        default:
          ErrorHandler.showError("$defaultMessage: ${e.message}");
      }
    } else {
      ErrorHandler.showError("$defaultMessage. Please try again.");
      print("Error: $e");
    }
  }
}
