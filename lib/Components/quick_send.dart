import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Components/cateogary_initial_icon.dart';
import 'package:money_control/Components/methods.dart';
import 'package:money_control/Components/quick_sender.dart';
import 'package:money_control/Models/quicksend.dart';
import 'package:money_control/Screens/add_transaction.dart';

class QuickSendRow extends StatefulWidget {
  final Color? cardColor;
  final Color? textColor;

  const QuickSendRow({super.key, this.cardColor, this.textColor});

  @override
  State<QuickSendRow> createState() => _QuickSendRowState();
}

class _QuickSendRowState extends State<QuickSendRow> {
  List<QuickSendContactModel> categories = [];
  bool loading = true;
  String? error;

  @override
  void initState() {
    super.initState();
    _loadCategoriesSortedByUsage();
  }

  Future<List<String>> fetchCategoriesSortedByUsage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final txRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.email) // or user.uid
        .collection('transactions');

    try {
      final snapshot = await txRef.get();

      Map<String, int> categoryCounts = {};
      for (var doc in snapshot.docs) {
        final category = doc['category'] as String?;
        if (category != null && category.isNotEmpty) {
          categoryCounts[category] = (categoryCounts[category] ?? 0) + 1;
        }
      }

      final sortedCategories = categoryCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      return sortedCategories.map((e) => e.key).toList();
    } catch (e) {
      debugPrint('Error fetching categories sorted by usage: $e');
      return [];
    }
  }

  Future<void> _loadCategoriesSortedByUsage() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      final categoryNames = await fetchCategoriesSortedByUsage();

      if (!mounted) return;

      // Limit categories to top 3 only
      final limitedCategoryNames = categoryNames.take(3).toList();

      setState(() {
        categories = limitedCategoryNames.map((name) {
          return QuickSendContactModel(
            id: name, // Using name as id since no unique ID here
            name: name,
            avatarUrl: null, // No avatar image for categories
          );
        }).toList();
        loading = false;
        error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        categories = [];
        loading = false;
        error = "Failed to load categories";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final Color containerColor = widget.cardColor ?? scheme.surface;

    if (loading) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: containerColor,
          borderRadius: BorderRadius.circular(18.r),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: List.generate(
            3,
                (i) => Container(
              height: 50.h,
              width: 50.h,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Text(
          error!,
          style: TextStyle(color: scheme.error, fontSize: 13.sp),
        ),
      );
    }

    if (categories.isEmpty) {
      return Center(
        child: Text(
          "No categories found",
          style: TextStyle(
            color: scheme.onSurface.withOpacity(0.6),
            fontSize: 13.sp,
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: 12.h),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Builder(builder: (context) {
        if (categories.length == 1) {
          return Row(
            children: [
              Expanded(
                child: Center(
                  child: QuickSender(
                    asset: CategoryInitialsIcon(categoryName: categories.first.name, size: 40),
                    name: categories.first.name,
                    textColor: widget.textColor ?? scheme.onSurface,
                    onTap: () {
                      gotoPage(PaymentScreen(
                        type: PaymentType.send,
                        cateogary: categories.first.name,
                      ));
                    },
                  ),
                ),
              ),
            ],
          );
        } else {
          return Row(
            children: categories.map((category) {
              return Expanded(
                child: Center(
                  child: QuickSender(
                    asset: CategoryInitialsIcon(categoryName: category.name, size: 40.r),
                    name: category.name,
                    textColor: widget.textColor ?? scheme.onSurface,
                    onTap: () {
                      gotoPage(PaymentScreen(
                        type: PaymentType.send,
                        cateogary: category.name,
                      ));
                    },
                  ),
                ),
              );
            }).toList(),
          );
        }
      }),
    );
  }
}
