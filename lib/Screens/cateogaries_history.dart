import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/cateogary_initial_icon.dart';

import 'package:money_control/Screens/cateogary_history.dart';
import 'package:money_control/Controllers/currency_controller.dart';
import 'package:money_control/Components/empty_state.dart';

class CategoriesHistoryScreen extends StatefulWidget {
  const CategoriesHistoryScreen({super.key});

  @override
  State<CategoriesHistoryScreen> createState() =>
      _CategoriesHistoryScreenState();
}

class _CategoriesHistoryScreenState extends State<CategoriesHistoryScreen> {
  bool loading = true;
  String? error;
  List<_CategoryItem> categoryItems = [];
  Map<String, double> budgetMap = {};
  int selectedTab = 0;

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
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() {
      loading = true;
      error = null;
      categoryItems = [];
    });

    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      setState(() {
        error = "User not logged in.";
        loading = false;
      });
      return;
    }

    try {
      // Fetch categories
      final catSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('categories')
          .get();

      // Merge categories by name to remove duplicates
      final Map<String, _CategoryItem> categoryMap = {};
      for (var doc in catSnap.docs) {
        final data = doc.data();
        final name = data['name'] ?? doc.id;
        if (!categoryMap.containsKey(name)) {
          categoryMap[name] = _CategoryItem(
            id: doc.id,
            name: name,
            iconUrl: data['iconUrl'] as String?,
            total: 0,
          );
        }
      }
      final categories = categoryMap.values.toList();

      // Fetch budgets
      final budgetsSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('budgets')
          .get();

      Map<String, double> fetchedBudgets = {};
      for (var doc in budgetsSnap.docs) {
        fetchedBudgets[doc.id] =
            (doc.data()['amount'] as num?)?.toDouble() ?? 0;
      }

      // Fetch transactions
      final txSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.email)
          .collection('transactions')
          .where('date', isGreaterThanOrEqualTo: _startOfMonth)
          .where('date', isLessThanOrEqualTo: _endOfMonth)
          .get();

      Map<String, double> categoryTotalMap = {};

      for (var doc in txSnap.docs) {
        final tx = doc.data();
        final catVal = tx['category'];
        final amount = (tx['amount'] as num?)?.toDouble() ?? 0.0;

        // Normalize type
        String rawType = (tx['type'] as String?)?.toLowerCase() ?? '';

        // Define known types
        const incomeTypes = ['income', 'credit', 'receive', 'deposit'];
        const expenseTypes = [
          'expense',
          'debit',
          'send',
          'payment',
          'withdrawal',
        ];

        bool isIncome = incomeTypes.contains(rawType);
        bool isExpense = expenseTypes.contains(rawType);

        // Fallback inference if type is unknown or empty
        if (!isIncome && !isExpense) {
          final recipientId = tx['recipientId'] as String? ?? '';
          final userId = user.uid;
          if (recipientId == userId) {
            isIncome = true;
          } else {
            isExpense = true;
          }
        }

        // Only count expense transactions as negative and income as positive
        if ((selectedTab == 0 && isIncome) || (selectedTab == 1 && isExpense)) {
          if (catVal != null) {
            categoryTotalMap[catVal.toString()] =
                (categoryTotalMap[catVal.toString()] ?? 0.0) + amount.abs();
          }
        }
      }

      for (final cat in categories) {
        cat.total = (categoryTotalMap[cat.name] ?? 0.0);
      }

      categories.sort((a, b) => b.total.compareTo(a.total));

      setState(() {
        categoryItems = categories;
        budgetMap = fetchedBudgets;
        loading = false;
      });
    } catch (e) {
      setState(() {
        error = "Failed to load categories: $e";
        loading = false;
      });
    }
  }

  void _onTabChanged(int index) {
    if (index != selectedTab) {
      HapticFeedback.selectionClick();
      setState(() {
        selectedTab = index;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        flexibleSpace: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              color: const Color(0xFF1A1A2E).withValues(alpha: 0.8),
            ),
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(
          "Categories History",
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18.sp,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF1A1A2E), // Midnight Void Top
              const Color(
                0xFF16213E,
              ).withValues(alpha: 0.95), // Deep Blue Bottom
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: 100.h), // AppBar and Status Bar spacer
            // TABS
            Container(
              margin: EdgeInsets.symmetric(horizontal: 40.w),
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(30.r),
              ),
              child: Row(
                children: [
                  Expanded(child: _tabButton("Income", 0)),
                  Expanded(child: _tabButton("Expense", 1)),
                ],
              ),
            ),
            SizedBox(height: 20.h),

            // LIST
            Expanded(
              child: loading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF00E5FF),
                      ),
                    )
                  : error != null
                  ? Center(
                      child: Text(
                        error!,
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    )
                  : categoryItems.isEmpty
                  ? Center(
                      child: EmptyStateWidget(
                        title: "No Categories",
                        subtitle: "No transactions found for this category.",
                        icon: Icons.category_outlined,
                        color: Colors.white38,
                      ),
                    )
                  : ListView.builder(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 30.h),
                      itemCount: categoryItems.length,
                      itemBuilder: (context, index) {
                        final category = categoryItems[index];
                        final budget = budgetMap[category.name] ?? 0;
                        return _buildCategoryCard(category, budget)
                            .animate(delay: (index * 50).ms)
                            .fadeIn(duration: 400.ms)
                            .slideY(begin: 0.1, end: 0, curve: Curves.easeOut);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final isSelected = selectedTab == index;
    // Income = Green (index 0), Expense = Red (index 1)
    final activeColor = index == 0
        ? const Color(0xFF00E676)
        : const Color(0xFFFF1744);

    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected
              ? activeColor.withValues(alpha: 0.2)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(26.r),
          border: isSelected
              ? Border.all(color: activeColor.withValues(alpha: 0.5))
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? activeColor : Colors.white54,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryCard(_CategoryItem category, double budget) {
    // 0 = Income (Green), 1 = Expense (Red)
    final isExpense = selectedTab == 1;
    final primaryColor = isExpense
        ? const Color(0xFFFF1744)
        : const Color(0xFF00E676);

    // Dim items with 0 spend
    final isZero = category.total == 0;
    final opacity = isZero ? 0.3 : 1.0;

    return GestureDetector(
      onTap: () {
        Get.to(() => CategoryTransactionsScreen(categoryName: category.name));
      },
      child: Opacity(
        opacity: opacity,
        child: Container(
          margin: EdgeInsets.only(bottom: 12.h),
          padding: EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05), // Dark Glass
            borderRadius: BorderRadius.circular(24.r),
            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 46.r,
                height: 46.r,
                decoration: const BoxDecoration(color: Colors.transparent),
                child: category.iconUrl != null
                    ? CircleAvatar(
                        backgroundImage: NetworkImage(category.iconUrl!),
                        backgroundColor: primaryColor.withValues(alpha: 0.1),
                      )
                    : CategoryInitialsIcon(
                        categoryName: category.name,
                        size: 46.r,
                      ),
              ),
              SizedBox(width: 16.w),

              // Name & Progress
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (budget > 0 && isExpense) ...[
                      SizedBox(height: 6.h),
                      // Budget Progress Bar
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: (category.total / budget).clamp(0.0, 1.0),
                          backgroundColor: Colors.white10,
                          valueColor: AlwaysStoppedAnimation(
                            category.total > budget
                                ? Colors
                                      .redAccent // Over budget
                                : primaryColor, // Safe
                          ),
                          minHeight: 4.h,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              SizedBox(width: 12.w),

              // Amount
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${CurrencyController.to.currencySymbol.value} ${category.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 15.sp,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        BoxShadow(
                          color: primaryColor.withValues(alpha: 0.4),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  if (budget > 0 && isExpense)
                    Padding(
                      padding: EdgeInsets.only(top: 4.h),
                      child: Text(
                        'of ${CurrencyController.to.currencySymbol.value}${budget.toStringAsFixed(0)}',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 11.sp,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryItem {
  final String id;
  final String name;
  final String? iconUrl;
  double total;

  _CategoryItem({
    required this.id,
    required this.name,
    this.iconUrl,
    required this.total,
  });
}
