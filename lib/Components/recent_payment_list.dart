import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:money_control/Components/tx_tile.dart';
import 'package:get/get.dart';
import 'package:money_control/Controllers/transaction_controller.dart';
import 'package:money_control/Components/empty_state.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:money_control/Components/colors.dart';
import 'package:money_control/Components/glass_container.dart';
import 'package:money_control/Components/shimmer_loading.dart'; // Ensure transparency of loading state

class RecentPaymentList extends StatelessWidget {
  final Color? cardColor;
  final Color? textColor;
  final Color? receivedColor;
  final Color? sentColor;

  const RecentPaymentList({
    super.key,
    this.cardColor,
    this.textColor,
    this.receivedColor,
    this.sentColor,
  });

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final user = FirebaseAuth.instance.currentUser;
      final scheme = Theme.of(context).colorScheme;

      if (user == null) {
        return Center(
          child: Text("Not logged in", style: TextStyle(color: scheme.error)),
        );
      }

      final controller = Get.find<TransactionController>();

      if (controller.isLoading.value) {
        return const Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.0),
          child: TransactionListShimmer(),
        );
      }

      if (controller.transactions.isEmpty) {
        return const EmptyStateWidget(
          title: "No Transactions",
          subtitle: "You haven't made any transactions yet.",
          icon: Icons.receipt_long_outlined,
        );
      }

      // Filter for this user and take top 8
      final recentTxs = controller.transactions
          .where(
            (txn) => txn.senderId == user.uid || txn.recipientId == user.uid,
          )
          .take(8)
          .toList();

      if (recentTxs.isEmpty) {
        return const EmptyStateWidget(
          title: "No Transactions",
          subtitle: "You haven't made any transactions yet.",
          icon: Icons.receipt_long_outlined,
        );
      }

      final isDark = Theme.of(context).brightness == Brightness.dark;
      // Define colors using AppColors if possible or keep theme logic for text
      final txTextColor = isDark ? Colors.white : Colors.black87;

      return GlassContainer(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        borderRadius: BorderRadius.circular(24.r),
        child: Column(
          children: recentTxs.asMap().entries.map((entry) {
            final index = entry.key;
            final tx = entry.value;
            final bool received = tx.recipientId == user.uid;

            return TxTile(
                  tx: tx,
                  received: received,
                  textColor: txTextColor,
                  receivedColor: AppColors.success,
                  sentColor: AppColors.error,
                )
                .animate(delay: (index * 50).ms)
                .fadeIn(duration: 300.ms, curve: Curves.easeOut)
                .slideY(
                  begin: 0.2,
                  end: 0,
                  duration: 300.ms,
                  curve: Curves.easeOut,
                );
          }).toList(),
        ),
      );
    });
  }
}
