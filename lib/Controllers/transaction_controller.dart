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

class TransactionController extends GetxController {
  final TransactionRepository _repository = TransactionRepository();
  final FirebaseAuth _auth = FirebaseAuth.instance;

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
    loadCategories();
    fetchSortedCategories();
  }

  void bindTransactions() {
    transactions.bindStream(_repository.getTransactionsStream());
  }

  Future<void> loadCategories() async {
    try {
      categories.value = await _repository.fetchCategories();
    } catch (e) {
      print("Error loading categories: $e");
    }
  }

  Future<void> fetchSortedCategories() async {
    sortedCategoryNames.value = await _repository
        .fetchCategoriesSortedByUsage();
  }

  // ——————————————————————————————————————
  //  Actions
  // ——————————————————————————————————————

  Future<bool> addCategory(String name) async {
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
      return true;
    } catch (e) {
      ErrorHandler.showSomethingWentWrong();
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
      ErrorHandler.showSomethingWentWrong();
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
      ErrorHandler.showSomethingWentWrong();
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
      ErrorHandler.showSomethingWentWrong();
      return false;
    }
  }
}
