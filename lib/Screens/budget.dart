import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'package:money_control/Components/bottom_nav_bar.dart';
import 'package:money_control/Components/cateogary_initial_icon.dart';
import 'package:money_control/Controllers/currency_controller.dart';

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
    return DateTime(
      now.year,
      now.month + 1,
      1,
    ).subtract(const Duration(seconds: 1));
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

        if (category != null) {
          // Robust Fix: Sum absolute values.
          // Assumes all categorized transactions in this context are spending (or refunds treated as activity).
          // Handles positive/negative stored expenses consistent with new approach.
          spendMap[category] = (spendMap[category] ?? 0) + amount.abs();
        }
      }

      List<_BudgetCategoryItem> items = [];

      for (var doc in catSnap.docs) {
        final catName = doc['name'] ?? doc.id;
        final budgetAmount = budgetsMap[catName] ?? 0;
        final spendAmount = spendMap[catName] ?? 0;

        var controller = _controllers[catName];
        controller ??= TextEditingController(
          text: budgetAmount.toStringAsFixed(2),
        );
        _controllers[catName] = controller;

        items.add(
          _BudgetCategoryItem(
            categoryName: catName,
            budget: budgetAmount,
            spent: spendAmount,
            controller: controller,
          ),
        );
      }

      setState(() {
        categoryBudgets = items;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to load budgets: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Budget saved for $categoryName"),
            backgroundColor: Colors.green,
          ),
        );
      }
      await _fetchBudgetsAndSpends();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to save budget: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final gradientColors = isDark
        ? [
            const Color(0xFF1A1A2E), // Midnight Void
            const Color(0xFF16213E).withValues(alpha: 0.95),
          ]
        : [const Color(0xFFF5F7FA), const Color(0xFFC3CFE2)]; // Premium Light

    final textColor = isDark ? Colors.white : const Color(0xFF1A1A2E);
    final secondaryTextColor = isDark
        ? Colors.white.withValues(alpha: 0.6)
        : const Color(0xFF1A1A2E).withValues(alpha: 0.6);

    final cardColor = isDark
        ? Colors.white.withValues(alpha: 0.05)
        : Colors.white.withValues(alpha: 0.6);

    final borderColor = isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.white.withValues(alpha: 0.4);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          title: Text(
            "Category Budgets",
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18.sp,
            ),
          ),
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: textColor, size: 20.sp),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: loading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF00E5FF)),
              )
            : Padding(
                padding: EdgeInsets.fromLTRB(20.w, 10.h, 20.w, 20.h),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: categoryBudgets.length,
                  separatorBuilder: (_, __) => SizedBox(height: 16.h),
                  itemBuilder: (context, index) {
                    final item = categoryBudgets[index];
                    final progress = item.budget > 0
                        ? (item.spent / item.budget).clamp(0.0, 1.0)
                        : 0.0;

                    // Color logic: Green if <80%, Turn Yellow/Red as it fills
                    final progressColor = progress > 0.9
                        ? const Color(0xFFFF4081) // Neon Pink/Red
                        : (progress > 0.7
                              ? Colors.orangeAccent
                              : const Color(0xFF00E5FF)); // Cyan

                    return Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20.r),
                        border: Border.all(color: borderColor),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(
                              alpha: isDark ? 0.2 : 0.05,
                            ),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: EdgeInsets.all(8.w),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? Colors.white.withValues(alpha: 0.08)
                                      : Colors.white.withValues(alpha: 0.4),
                                  shape: BoxShape.circle,
                                ),
                                child: CategoryInitialsIcon(
                                  categoryName: item.categoryName,
                                  size: 32.r,
                                ),
                              ),
                              SizedBox(width: 12.w),
                              Expanded(
                                child: Text(
                                  item.categoryName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16.sp,
                                    color: textColor,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              Text(
                                "${CurrencyController.to.currencySymbol.value}${item.spent.toStringAsFixed(0)} / ${item.budget.toStringAsFixed(0)}",
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 16.h),

                          /// PROGRESS BAR
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4.h),
                            child: LinearProgressIndicator(
                              value: progress.toDouble(),
                              color: progressColor,
                              backgroundColor: isDark
                                  ? Colors.white.withValues(alpha: 0.1)
                                  : Colors.black.withValues(alpha: 0.05),
                              minHeight: 6.h,
                            ),
                          ),

                          SizedBox(height: 16.h),

                          /// INPUT + SAVE
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 44.h,
                                  decoration: BoxDecoration(
                                    color: isDark
                                        ? Colors.black.withValues(alpha: 0.2)
                                        : Colors.grey.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(12.r),
                                    border: Border.all(
                                      color: isDark
                                          ? Colors.white.withValues(alpha: 0.1)
                                          : Colors.black.withValues(
                                              alpha: 0.05,
                                            ),
                                    ),
                                  ),
                                  child: TextFormField(
                                    controller: item.controller,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 14.sp,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Set Limit',
                                      hintStyle: TextStyle(
                                        color: secondaryTextColor.withValues(
                                          alpha: 0.4,
                                        ),
                                      ),
                                      border: InputBorder.none,
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 14.w,
                                        vertical:
                                            0, // Centers text vertically in 44h container
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(width: 12.w),
                              InkWell(
                                onTap: () {
                                  final amount =
                                      double.tryParse(item.controller.text) ??
                                      0;
                                  _saveBudget(item.categoryName, amount);
                                },
                                child: Container(
                                  height: 44.h,
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 20.w,
                                  ),
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    gradient: const LinearGradient(
                                      colors: [
                                        Color(0xFF6C63FF),
                                        Color(0xFF00E5FF),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(12.r),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(
                                          0xFF6C63FF,
                                        ).withValues(alpha: 0.4),
                                        blurRadius: 8,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    "Update",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.sp,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
        bottomNavigationBar: const BottomNavBar(currentIndex: 3),
      ),
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
