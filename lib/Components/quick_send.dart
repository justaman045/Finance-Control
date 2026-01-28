import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Components/cateogary_initial_icon.dart';
import 'package:money_control/Components/methods.dart';

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
    if (user == null) return [];

    final txRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.email)
        .collection('transactions');

    try {
      final snapshot = await txRef.get();
      Map<String, int> categoryCounts = {};

      for (var doc in snapshot.docs) {
        final data = doc.data();

        // Safe category reading
        final category = data.containsKey('category')
            ? data['category'] as String?
            : null;

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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final containerColor = isDark
        ? scheme.surface.withOpacity(0.6)
        : Colors.white.withOpacity(0.8);

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
                color: isDark
                    ? Colors.grey.withOpacity(0.2)
                    : Colors.grey.withOpacity(0.1),
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
      padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
      decoration: BoxDecoration(
        color: containerColor,
        borderRadius: BorderRadius.circular(24.r),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : Colors.grey.withOpacity(0.1),
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
      ),
      child: Builder(
        builder: (context) {
          if (categories.length == 1) {
            return Row(
              children: [
                Expanded(
                  child: Center(
                    child: _neonQuickSender(
                      asset: CategoryInitialsIcon(
                        categoryName: categories.first.name,
                        size: 40,
                      ),
                      name: categories.first.name,
                      color: const Color(0xFF00E5FF), // Neon Cyan
                      isDark: isDark,
                      onTap: () {
                        gotoPage(
                          PaymentScreen(
                            type: PaymentType.send,
                            cateogary: categories.first.name,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          } else {
            // Assign neon colors cyclically
            final colors = [
              const Color(0xFF00E5FF), // Cyan
              const Color(0xFFEA80FC), // Purple
              const Color(0xFFFF4081), // Pink
              const Color(0xFFFDD835), // Yellow
            ];

            return Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: categories.asMap().entries.map((entry) {
                final index = entry.key;
                final category = entry.value;
                final color = colors[index % colors.length];

                return _neonQuickSender(
                  asset: CategoryInitialsIcon(
                    categoryName: category.name,
                    size: 40.r,
                  ),
                  name: category.name,
                  color: color,
                  isDark: isDark,
                  onTap: () {
                    gotoPage(
                      PaymentScreen(
                        type: PaymentType.send,
                        cateogary: category.name,
                      ),
                    );
                  },
                );
              }).toList(),
            );
          }
        },
      ),
    );
  }

  Widget _neonQuickSender({
    required Widget asset,
    required String name,
    required Color color,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.5), width: 2),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.2),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: asset,
          ),
          SizedBox(height: 8.h),
          SizedBox(
            width: 70.w,
            child: Text(
              name,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
