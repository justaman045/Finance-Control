import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:money_control/Components/colors.dart';
import 'package:money_control/Components/glass_container.dart';

import 'package:money_control/Screens/add_transaction.dart';
import 'package:money_control/Components/methods.dart';
import 'package:get/get.dart';
import 'package:money_control/Controllers/privacy_controller.dart';
import 'package:money_control/Controllers/currency_controller.dart';
import 'package:money_control/Controllers/transaction_controller.dart';

class BalanceCard extends StatefulWidget {
  const BalanceCard({super.key});

  @override
  State<BalanceCard> createState() => _BalanceCardState();
}

class _BalanceCardState extends State<BalanceCard> {
  final PrivacyController _privacyController = Get.find<PrivacyController>();
  final TransactionController _transactionController =
      Get.find<TransactionController>();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = FirebaseAuth.instance.currentUser;

    // Use AppColors.primary/secondary for a premium look, or keep the specific card gradient
    // Let's align with the app's theme but make it pop
    final gradientColors = isDark
        ? [AppColors.primary, const Color(0xFF4A148C)]
        : [AppColors.primary, AppColors.secondary];

    return Container(
      margin: EdgeInsets.symmetric(vertical: 8.h),
      child: GlassContainer(
        padding: EdgeInsets.zero,
        borderRadius: BorderRadius.circular(32.r),
        // Overriding GlassContainer default color/gradient to have the strong card brand color
        // But keeping the glass border effect
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: gradientColors,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(32.r),
          ),
          child: Stack(
            children: [
              // Background Gradient Blob for "Mesh" feel - refined
              Positioned(
                right: -60,
                top: -60,
                child: Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),
              // Second Blob (Bottom Left)
              Positioned(
                left: -60,
                bottom: -60,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.1),
                        Colors.transparent,
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: EdgeInsets.all(
                  24.r,
                ), // Restore padding inside the custom container
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Balance',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(height: 12.h),
                    if (user != null)
                      Obx(() {
                        if (_transactionController.isLoading.value) {
                          return _balanceShimmer(Theme.of(context).colorScheme);
                        }
                        return GestureDetector(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            _privacyController.togglePrivacy();
                          },
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              ShaderMask(
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      colors: [Colors.white, Color(0xFFE0E0E0)],
                                    ).createShader(bounds),
                                child: Obx(() {
                                  if (_privacyController.isPrivacyMode.value) {
                                    return Text(
                                      "••••",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 36.sp,
                                        color: Colors.white,
                                        letterSpacing: -1.0,
                                        shadows: [
                                          BoxShadow(
                                            color: Colors.black.withValues(
                                              alpha: 0.1,
                                            ),
                                            blurRadius: 10,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                    );
                                  } else {
                                    return TweenAnimationBuilder<double>(
                                      tween: Tween<double>(
                                        begin: 0,
                                        end:
                                            _transactionController.totalBalance,
                                      ),
                                      duration: const Duration(
                                        milliseconds: 1500,
                                      ),
                                      curve: Curves.easeOutExpo,
                                      builder: (context, value, child) {
                                        return Text(
                                          '${CurrencyController.to.currencySymbol.value} ${value.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 36.sp,
                                            color: Colors.white,
                                            letterSpacing: -1.0,
                                            shadows: [
                                              BoxShadow(
                                                color: Colors.black.withValues(
                                                  alpha: 0.1,
                                                ),
                                                blurRadius: 10,
                                                offset: const Offset(0, 4),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    );
                                  }
                                }),
                              ),
                              SizedBox(width: 12.w),
                              Obx(
                                () => Icon(
                                  _privacyController.isPrivacyMode.value
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: Colors.white.withValues(alpha: 0.5),
                                  size: 20.sp,
                                ),
                              ),
                            ],
                          ),
                        );
                      })
                    else
                      _balanceLabel('--', Theme.of(context).colorScheme),
                    SizedBox(height: 24.h),
                    Row(
                      children: [
                        Expanded(
                          child: _glassActionButton(
                            label: "Send",
                            icon: Icons.north_east_rounded,
                            color: Colors.white,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              gotoPage(PaymentScreen(type: PaymentType.send));
                            },
                          ),
                        ),
                        SizedBox(width: 16.w),
                        Expanded(
                          child: _glassActionButton(
                            label: "Receive",
                            icon: Icons.south_west_rounded,
                            color: Colors.white,
                            onTap: () {
                              HapticFeedback.lightImpact();
                              gotoPage(
                                PaymentScreen(type: PaymentType.receive),
                              );
                            },
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
      ),
    );
  }

  Widget _glassActionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 54.h,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(18.r),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18.sp),
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
      fontWeight: FontWeight.bold,
      fontSize: 36.sp,
      color: Colors.white,
      letterSpacing: -1.0,
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
