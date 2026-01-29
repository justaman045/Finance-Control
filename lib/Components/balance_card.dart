import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Models/transaction.dart';

import 'package:money_control/Screens/add_transaction.dart';
import 'package:money_control/Components/methods.dart';
import 'package:get/get.dart';
import 'package:money_control/Controllers/privacy_controller.dart';
import 'package:money_control/Controllers/currency_controller.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  final PrivacyController _privacyController = Get.find<PrivacyController>();
  Future<double> _calculateBalance(String uid) async {
    double balance = 0;

    final sentSnaps = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.email)
        .collection('transactions')
        .where('senderId', isEqualTo: uid)
        .get();

    for (final doc in sentSnaps.docs) {
      final txn = TransactionModel.fromMap(doc.id, doc.data());
      // Explicitly subtract absolute amount for sent transactions
      balance -= txn.amount.abs();
      balance -= txn.tax;
    }

    final receivedSnaps = await FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.email)
        .collection('transactions')
        .where('recipientId', isEqualTo: uid)
        .get();

    for (final doc in receivedSnaps.docs) {
      final txn = TransactionModel.fromMap(doc.id, doc.data());
      // Explicitly add absolute amount for received transactions
      balance += txn.amount.abs();
    }
    return balance;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    // Card Gradient
    final gradientColors = isDark
        ? [
            const Color(0xFF2E1A47), // Deep Violet
            const Color(0xFF4A148C).withValues(alpha: 0.8),
            const Color(0xFF0D47A1).withValues(alpha: 0.6), // Deep Blue
          ]
        : [
            const Color(0xFF4facfe), // Premium Blue
            const Color(0xFF00f2fe), // Cyan Accent
          ];

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      padding: EdgeInsets.fromLTRB(24.w, 24.h, 24.w, 24.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32.r),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? const Color(0xFF6200EA).withValues(alpha: 0.4)
                : const Color(0xFF00f2fe).withValues(alpha: 0.3),
            blurRadius: 30,
            offset: const Offset(0, 10),
            spreadRadius: -5,
          ),
        ],
        border: Border.all(color: Colors.white.withValues(alpha: 0.12), width: 1.5),
      ),
      child: Stack(
        children: [
          // Background Gradient Blob for "Mesh" feel
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    isDark
                        ? Colors.cyanAccent.withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CURRENT BALANCE',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 11.sp,
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 12.h),
              if (user != null)
                FutureBuilder<double>(
                  future: _calculateBalance(user.uid),
                  builder: (context, balanceSnapshot) {
                    if (balanceSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return _balanceShimmer(scheme);
                    }
                    if (balanceSnapshot.hasError || !balanceSnapshot.hasData) {
                      return _balanceLabel('--', scheme);
                    }
                    String formattedBalance =
                        '${CurrencyController.to.currencySymbol.value} ${balanceSnapshot.data!.toStringAsFixed(2)}';

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        ShaderMask(
                          shaderCallback: (bounds) => const LinearGradient(
                            colors: [Colors.white, Color(0xFFE0E0E0)],
                          ).createShader(bounds),
                          child: Obx(() {
                            final text = _privacyController.isPrivacyMode.value
                                ? "••••"
                                : formattedBalance;
                            return Text(
                              text,
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 32.sp,
                                color: Colors.white,
                                letterSpacing: -0.5,
                                shadows: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ],
                    );
                  },
                )
              else
                _balanceLabel('--', scheme),
              SizedBox(height: 24.h),
              Row(
                children: [
                  Expanded(
                    child: _glassActionButton(
                      label: "Send",
                      icon: Icons.north_east_rounded,
                      color: isDark
                          ? const Color(0xFF00E5FF)
                          : Colors
                                .white, // White icon on bright bg for light mode
                      iconColor: isDark
                          ? const Color(0xFF00E5FF)
                          : const Color(
                              0xFF2E1A47,
                            ), // Dark text/icon on light mode? No, card is Blue. White text suitable.
                      // Actually, on the Blue/Cyan gradient, White text/icon is best.
                      onTap: () =>
                          gotoPage(PaymentScreen(type: PaymentType.send)),
                    ),
                  ),
                  SizedBox(width: 16.w),
                  Expanded(
                    child: _glassActionButton(
                      label: "Receive",
                      icon: Icons.south_west_rounded,
                      color: isDark ? const Color(0xFFEA80FC) : Colors.white,
                      iconColor: isDark
                          ? const Color(0xFFEA80FC)
                          : Colors.white,
                      onTap: () =>
                          gotoPage(PaymentScreen(type: PaymentType.receive)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _glassActionButton({
    required String label,
    required IconData icon,
    required Color color,
    Color? iconColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 50.h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor ?? color, size: 18.sp),
            SizedBox(width: 8.w),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14.sp,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Keep helpers but ensure they return valid widgets for new style
  Widget _balanceLabel(String text, ColorScheme scheme) => Text(
    text,
    style: TextStyle(
      fontWeight: FontWeight.w800,
      fontSize: 32.sp,
      color: Colors.white,
    ),
  );

  Widget _balanceShimmer(ColorScheme scheme) => Container(
    width: 120.w,
    height: 36.h,
    decoration: BoxDecoration(
      color: scheme.onSurface.withValues(alpha: 0.16),
      borderRadius: BorderRadius.circular(12.r),
    ),
    margin: EdgeInsets.symmetric(vertical: 4.h),
  );
}
