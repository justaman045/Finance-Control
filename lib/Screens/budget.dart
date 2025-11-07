import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/cateogary_initial_icon.dart';

class CategoryBudgetScreen extends StatefulWidget {
  const CategoryBudgetScreen({super.key});

  @override
  State<CategoryBudgetScreen> createState() => _CategoryBudgetScreenState();
}

class _CategoryBudgetScreenState extends State<CategoryBudgetScreen> {
  bool loading = true;
  List<_BudgetCategoryItem> categoryBudgets = [];
  final Map<String, TextEditingController> _controllers = {};

  DateTime get _startOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  DateTime get _endOfMonth {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
  }

  @override
  void initState() {
    super.initState();
    _fetchBudgetsAndSpends();
  }

  @override
  void dispose() {
    for (var ctrl in _controllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  Future<void> _fetchBudgetsAndSpends() async {
    setState(() {
      loading = true;
      categoryBudgets = [];
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() {
        loading = false;
      });
      return;
    }

    try {
      final catSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('categories')
          .get();

      final budgetsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('budgets')
          .get();

      Map<String, double> budgetsMap = {};
      for (var doc in budgetsSnap.docs) {
        final data = doc.data();
        budgetsMap[doc.id] = (data['amount'] as num?)?.toDouble() ?? 0;
      }

      final txSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: _startOfMonth)
          .where('date', isLessThanOrEqualTo: _endOfMonth)
          .get();

      Map<String, double> spendMap = {};
      for (var doc in txSnap.docs) {
        final tx = doc.data();
        final category = tx['category'] as String?;
        final amountRaw = tx['amount'];
        double amount = 0;
        if (amountRaw is int) {
          amount = amountRaw.toDouble();
        } else if (amountRaw is double) {
          amount = amountRaw;
        } else if (amountRaw is String) {
          amount = double.tryParse(amountRaw) ?? 0;
        }

        if (category != null && amount < 0) {
          spendMap[category] = (spendMap[category] ?? 0) + (-amount);
        }
      }

      List<_BudgetCategoryItem> items = [];

      for (var doc in catSnap.docs) {
        final catName = doc['name'] ?? doc.id;
        final budgetAmount = budgetsMap[catName] ?? 0;
        final spendAmount = spendMap[catName] ?? 0;

        var controller = _controllers[catName];
        controller ??= TextEditingController(text: budgetAmount.toStringAsFixed(2));
        _controllers[catName] = controller;

        items.add(_BudgetCategoryItem(
          categoryName: catName,
          budget: budgetAmount,
          spent: spendAmount,
          controller: controller,
        ));
      }

      setState(() {
        categoryBudgets = items;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      Get.snackbar("Error", "Failed to load budgets: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  Future<void> _saveBudget(String categoryName, double amount) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('budgets')
          .doc(categoryName)
          .set({'amount': amount});
      Get.snackbar("Success", "Budget saved for $categoryName",
          backgroundColor: Colors.green, colorText: Colors.white);
      await _fetchBudgetsAndSpends();
    } catch (e) {
      Get.snackbar("Error", "Failed to save budget: $e",
          backgroundColor: Colors.red, colorText: Colors.white);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          "Category Budgets",
          style: TextStyle(
            color: scheme.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: scheme.onBackground, size: 20.sp),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: scheme.background,
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: EdgeInsets.all(12.w),
        child: ListView.separated(
          itemCount: categoryBudgets.length,
          separatorBuilder: (_, __) =>
              Divider(color: scheme.onSurface.withOpacity(0.1)),
          itemBuilder: (context, index) {
            final item = categoryBudgets[index];
            final progress = item.budget > 0
                ? (item.spent / item.budget).clamp(0, 1)
                : 0.0;

            // Instead of ListTile, use a custom row+column layout for flexibility:
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4.h),
              child: Container(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(14.r),
                ),
                padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 10.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CategoryInitialsIcon(
                      categoryName: item.categoryName,
                      size: 38.r,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(item.categoryName,
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16.sp,
                              )),
                          SizedBox(height: 6.h),
                          LinearProgressIndicator(
                            value: progress.toDouble(),
                            color: progress < 0.8 ? Colors.green : Colors.red,
                            backgroundColor: scheme.surfaceVariant,
                            minHeight: 8.h,
                          ),
                          SizedBox(height: 4.h),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Spent: ₹${item.spent.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 13.sp, color: scheme.onSurfaceVariant),
                              ),
                              Text(
                                'Budget: ₹${item.budget.toStringAsFixed(2)}',
                                style: TextStyle(fontSize: 13.sp, color: scheme.onSurfaceVariant),
                              ),
                            ],
                          ),
                          SizedBox(height: 10.h),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: item.controller,
                                  keyboardType: TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    hintText: 'Set Budget',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12.r),
                                    ),
                                    contentPadding: EdgeInsets.symmetric(
                                        vertical: 10.h, horizontal: 10.w),
                                    isDense: true,
                                  ),
                                ),
                              ),
                              SizedBox(width: 8.w),
                              SizedBox(
                                height: 41.h,
                                child: ElevatedButton(
                                  onPressed: () {
                                    final amount = double.tryParse(item.controller.text) ?? 0;
                                    _saveBudget(item.categoryName, amount);
                                  },
                                  child: const Text("Save"),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: BottomNavBar(currentIndex: 2),
    );
  }
}

class _BudgetCategoryItem {
  final String categoryName;
  final TextEditingController controller;
  double budget;
  double spent;

  _BudgetCategoryItem({
    required this.categoryName,
    required this.budget,
    required this.spent,
    required this.controller,
  });
}
