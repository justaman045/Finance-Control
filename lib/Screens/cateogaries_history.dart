import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import 'package:money_control/Components/cateogary_initial_icon.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Screens/cateogary_history.dart';

class CategoriesHistoryScreen extends StatefulWidget {
  const CategoriesHistoryScreen({super.key});

  @override
  State<CategoriesHistoryScreen> createState() => _CategoriesHistoryScreenState();
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
    return DateTime(now.year, now.month + 1, 1).subtract(const Duration(seconds: 1));
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
        fetchedBudgets[doc.id] = (doc.data()['amount'] as num?)?.toDouble() ?? 0;
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

        String type = (tx['type'] as String?)?.toLowerCase() ?? '';
        if (type.isEmpty) {
          //TODO: Remove usage warning
          // final senderId = tx['senderId'] as String? ?? '';
          final recipientId = tx['recipientId'] as String? ?? '';
          final userId = user.uid;
          type = (recipientId == userId) ? 'income' : 'expense';
        }

        // Only count expense transactions as negative and income as positive
        if ((selectedTab == 0 && type == 'income') ||
            (selectedTab == 1 && type == 'expense')) {
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
      setState(() {
        selectedTab = index;
      });
      _fetchData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          "Categories History",
          style: TextStyle(
            color: scheme.onBackground,
            fontWeight: FontWeight.bold,
            fontSize: 17.sp,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: scheme.onBackground, size: 19.sp),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      body: Column(
        children: [
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _tabButton("Income", 0),
              SizedBox(width: 20.w),
              _tabButton("Expense", 1),
            ],
          ),
          SizedBox(height: 10.h),
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                ? Center(child: Text(error!, style: TextStyle(color: scheme.error)))
                : categoryItems.isEmpty
                ? Center(
              child: Text(
                "No categories found.",
                style: TextStyle(
                  color: scheme.onSurface.withOpacity(0.6),
                  fontSize: 14.sp,
                ),
                textAlign: TextAlign.center,
              ),
            )
                : ListView.separated(
              padding: EdgeInsets.all(12.w),
              itemCount: categoryItems.length,
              separatorBuilder: (_, __) =>
                  Divider(color: scheme.onSurface.withOpacity(0.1), height: 1),
              itemBuilder: (context, index) {
                final category = categoryItems[index];
                final budget = budgetMap[category.name] ?? 0;
                Widget trailing = Text(
                  '₹ ${category.total.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: selectedTab == 0 ? Colors.green : scheme.error,
                    fontWeight: FontWeight.bold,
                    fontSize: 15.sp,
                  ),
                );

                if (budget > 0) {
                  double percent = (category.total / budget * 100).clamp(0, 999).toDouble();
                  trailing = Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹ ${category.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          color: selectedTab == 0 ? Colors.green : scheme.error,
                          fontWeight: FontWeight.bold,
                          fontSize: 15.sp,
                        ),
                      ),
                      SizedBox(height: 3.h),
                      SizedBox(
                        width: 60.w,
                        child: LinearProgressIndicator(
                          value: (category.total / budget).clamp(0,1),
                          backgroundColor: scheme.surfaceVariant,
                          color: selectedTab == 0 ? Colors.green : scheme.error,
                          minHeight: 7,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        '${percent.toStringAsFixed(1)}%',
                        style: TextStyle(
                          color: Colors.grey,
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  );
                }
                return ListTile(
                  contentPadding: EdgeInsets.symmetric(vertical: 8.h, horizontal: 12.w),
                  leading: category.iconUrl != null
                      ? CircleAvatar(backgroundImage: NetworkImage(category.iconUrl!))
                      : CategoryInitialsIcon(categoryName: category.name, size: 40.r),
                  title: Text(
                    category.name,
                    style: TextStyle(
                      color: scheme.onSurface,
                      fontWeight: FontWeight.w600,
                      fontSize: 15.sp,
                    ),
                  ),
                  trailing: trailing,
                  onTap: () {
                    Get.to(() => CategoryTransactionsScreen(
                      categoryName: category.name,
                    ), curve: curve, transition: transition, duration: duration);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabButton(String text, int index) {
    final isSelected = selectedTab == index;
    final scheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => _onTabChanged(index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isSelected ? scheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? scheme.primary : scheme.onSurface.withOpacity(0.4),
            width: 1.5,
          ),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? scheme.onPrimary : scheme.onSurface,
            fontSize: 14.sp,
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
